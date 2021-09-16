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

	/** @deprecated */
	Disconnect(): void;

	/** @deprecated */
	Destroy(): void;
}

/**
 * Batched yield-safe signal implementation by stravant
 *
 * @see https://gist.github.com/stravant/b75a322e0919d60dde8a0316d1f09d2f
 */
declare class EventEmitter<T extends any[] = []> {
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
	static wrap<F extends Callback>(
		this: void,
		event: RBXScriptSignal<F>,
		janitor?: Janitor,
	): EventEmitter<Parameters<F>>;

	/**
	 * Registers a handler for events emitted by this instance.
	 */
	subscribe(handler: (...params: T) => void): Subscription;

	/**
	 * Registers a handler that disconnects immediately after an emission.
	 */
	subscribeOnce(handler: (...params: T) => void): Subscription;

	/**
	 * Return the result of `Promise.fromEvent(emitter, predicate)`.
	 */
	promisify(predicate?: (...params: T) => boolean): Promise<T[0]>;

	/**
	 * Return a promise that resolves with `emitter.subscribeOnce`.
	 */
	once(): Promise<T[0]>;

	/**
	 * `EventEmitter.emit(...)` implemented by running the handler functions on the
	 * coRunnerThread, and any time the resulting thread yielded without returning
	 * to us, that means that it yielded to the Roblox scheduler and has been taken
	 * over by Roblox scheduling, meaning we have to make a new coroutine runner.
	 */
	emit(...params: T): void;

	/**
	 * Blocks the current thread until the event fires. Returns the result as a LuaTuple.
	 */
	wait(): LuaTuple<T>;

	/**
	 * Disconnect all handlers.
	 */
	unsubscribeAll(): void;

	/**
	 * Unsubscribes all handlers from the event, and cancels any event wrapping.
	 */
	destroy(): void;

	/** @deprecated */
	Connect(handler: (...params: T) => void): Subscription;

	/** @deprecated */
	Wait(): LuaTuple<T>;

	/** @deprecated */
	Destroy(): void;
}

export = EventEmitter;
