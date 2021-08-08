import type { Janitor } from "@rbxts/janitor";

/**
 * Connection class
 */
declare class Subscription {
	/**
	 * Whether the handler has been unregistered.
	 */
	closed: boolean;
	/**
	 * Removes the handler from the event.
	 */
	unsubscribe(): void;
}

type RBXScriptSignalCallback<T> = T extends RBXScriptSignal<infer F> ? F : never;

/**
 * Batched yield-safe signal implementation by stravant
 *
 * @see https://gist.github.com/stravant/b75a322e0919d60dde8a0316d1f09d2f
 */
declare class EventEmitter<T extends unknown[] = []> {
	/**
	 * @param janitor - Optional Janitor object to add the emitter to.
	 */
	constructor(janitor?: Janitor);
	/**
	 * Creates an emitter that fires when the given Roblox signal is fired.
	 *
	 * @param event - The event to wrap.
	 * @param janitor - Optional Janitor object to add the emitter to.
	 */
	static wrap<T extends RBXScriptSignal>(
		event: T,
		janitor?: Janitor,
	): EventEmitter<Parameters<RBXScriptSignalCallback<T>>>;
	/**
	 * Registers a handler for events emitted by this instance.
	 */
	subscribe(handler: (...params: T) => void): Subscription;
	/**
	 * Registers a handler, but disconnects it immediately after the first emit.
	 */
	subscribeOnce(handler: (...params: T) => void): Subscription;
	/**
	 * `EventEmitter.emit(...)` implemented by running the handler functions on the
	 * coRunnerThread, and any time the resulting thread yielded without returning
	 * to us, that means that it yielded to the Roblox scheduler and has been taken
	 * over by Roblox scheduling, meaning we have to make a new coroutine runner.
	 */
	emit(...params: T): void;
	/**
	 * Implement `EventEmitter.wait()` in terms of a temporary connection using
	 * `EventEmitter.subscribeOnce()` which disconnects itself. Blocks the current thread.
	 */
	wait(): LuaTuple<T>;
	/**
	 * Disconnect all handlers. Since we use a linked list it suffices to clear the
	 * reference to the head handler.
	 */
	disconnectAll(): void;
	/**
	 * Disconnects all handlers and the event proxy if it exists.
	 */
	dispose(): void;
}

export = EventEmitter;
