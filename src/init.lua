--------------------------------------------------------------------------------
--               Batched Yield-Safe Signal Implementation                     --
-- This is a Signal class which has effectively identical behavior to a       --
-- normal RBXScriptSignal, with the only difference being a couple extra      --
-- stack frames at the bottom of the stack trace when an error is thrown.     --
-- This implementation caches runner coroutines, so the ability to yield in   --
-- the signal handlers comes at minimal extra cost over a naive signal        --
-- implementation that either always or never spawns a thread.                --
--                                                                            --
-- API:                                                                       --
--   local Signal = require(THIS MODULE)                                      --
--   local sig = Signal.new()                                                 --
--   local connection = sig:Connect(function(arg1, arg2, ...) ... end)        --
--   sig:Fire(arg1, arg2, ...)                                                --
--   connection:Disconnect()                                                  --
--   sig:DisconnectAll()                                                      --
--   local arg1, arg2, ... = sig:Wait()                                       --
--                                                                            --
-- Licence:                                                                   --
--   Licenced under the MIT licence.                                          --
--                                                                            --
-- Authors:                                                                   --
--   stravant - July 31st, 2021 - Created the file.                           --
--   littensy - August 2nd, 2021 - Literally only renamed it                  --
--------------------------------------------------------------------------------

-- The currently idle thread to run the next handler on
local freeRunnerThread = nil

-- Promise library
local Promise = require(script.Promise)

-- Function which acquires the currently idle handler runner thread, runs the
-- function fn on it, and then releases the thread, returning it to being the
-- currently idle one.
-- If there was a currently idle runner thread already, that's okay, that old
-- one will just get thrown and eventually GCed.
local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
end

-- Coroutine runner that we create coroutines of. The coroutine can be 
-- repeatedly resumed with functions to run followed by the argument to run
-- them with.
local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

-- Connection class
local Subscription = {}
Subscription.__index = Subscription

function Subscription.new(signal, fn)
	return setmetatable({
		closed = false,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Subscription)
end

function Subscription:unsubscribe()
	assert(not self.closed, "Can't disconnect a connection twice.", 2)
	self.closed = true

	-- Unhook the node, but DON'T clear it. That way any fire calls that are
	-- currently sitting on this node will be able to iterate forwards off of
	-- it, but any subsequent fire calls will not hit it, and it will be GCed
	-- when no more fire calls are sitting on it.
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

Subscription.Disconnect = Subscription.unsubscribe
Subscription.Destroy = Subscription.unsubscribe

-- Make Connection strict
setmetatable(Subscription, {
	__index = function(tb, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

-- Signal class
local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new(janitor)
	local self = setmetatable({
		_handlerListHead = false,
		_proxyHandler = nil,
	}, EventEmitter)
	if janitor then
		janitor:Add(self)
	end
	return self
end

function EventEmitter.wrap(rbxScriptSignal, janitor)
	assert(typeof(rbxScriptSignal) == "RBXScriptSignal", "Argument #1 to EventEmitter.wrap must be a RBXScriptSignal; got " .. typeof(rbxScriptSignal))
	local emitter = EventEmitter.new(janitor)
	emitter._proxyHandler = rbxScriptSignal:Connect(function(...)
		emitter:emit(...)
	end)
	return emitter
end

function EventEmitter:subscribe(fn)
	local subscription = Subscription.new(self, fn)
	if self._handlerListHead then
		subscription._next = self._handlerListHead
		self._handlerListHead = subscription
	else
		self._handlerListHead = subscription
	end
	return subscription
end

function EventEmitter:subscribeOnce(fn)
	local cn;
	cn = self:subscribe(function (...)
		cn:unsubscribe()
		fn(...)
	end)
	return cn
end

function EventEmitter:promisify(predicate)
	return Promise.fromEvent(self, predicate)
end

function EventEmitter:once()
	return Promise.new(function (resolve)
		local cn;
		cn = self:subscribe(function (...)
			cn:unsubscribe()
			resolve(...)
		end)
	end)
end

-- Disconnect all handlers. Since we use a linked list it suffices to clear the
-- reference to the head handler.
function EventEmitter:unsubscribeAll()
	self._handlerListHead = false
end

function EventEmitter:destroy()
	self:unsubscribeAll();
	local proxyHandler = rawget(self, "_proxyHandler")
	if proxyHandler then
		proxyHandler:Disconnect()
	end
end

-- Signal:Fire(...) implemented by running the handler functions on the
-- coRunnerThread, and any time the resulting thread yielded without returning
-- to us, that means that it yielded to the Roblox scheduler and has been taken
-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
function EventEmitter:emit(...)
	local item = self._handlerListHead
	while item do
		if not item.closed then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end

-- Implement Signal:Wait() in terms of a temporary connection using
-- a Signal:Connect() which disconnects itself.
function EventEmitter:wait()
	local waitingCoroutine = coroutine.running()
	local cn;
	cn = self:subscribe(function(...)
		cn:unsubscribe()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

EventEmitter.Connect = EventEmitter.subscribe
EventEmitter.Destroy = EventEmitter.destroy
EventEmitter.Wait = EventEmitter.wait

-- Make signal strict
setmetatable(EventEmitter, {
	__index = function(tb, key)
		error(("Attempt to get EventEmitter::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set EventEmitter::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

return EventEmitter
