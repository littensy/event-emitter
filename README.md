# @rbxts/task-event-emitter

Event emitter for roblox-ts using [stravant's GoodSignal class](https://devforum.roblox.com/t/lua-signal-class-comparison-optimal-goodsignal-class/1387063).

## Installation

```
npm i @rbxts/task-event-emitter
```

## Usage

Create an EventEmitter with an array of parameters:

```ts
const emitter = new EventEmitter<[player: Player]>(janitor);
```

Or, wrap an RBXScriptSignal:

```ts
const onChildAdded = EventEmitter.wrap(object.ChildAdded, janitor);
```

## Example

```ts
import EventEmitter from "@rbxts/task-event-emitter";

const onChange = new EventEmitter<[property: string]>();

onChange.subscribe((property) => print(`Property ${property} changed!`));

onChange.emit("Name");
```

```ts
import EventEmitter from "@rbxts/task-event-emitter";

const emitter = new EventEmitter();

const subscription = emitter.subscribe(() => {});

if (!subscription.closed) {
	subscription.unsubscribe();
}
```
