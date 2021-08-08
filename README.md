# @rbxts/task-event-emitter

Event emitter for roblox-ts using [stravant's GoodSignal class](https://devforum.roblox.com/t/lua-signal-class-comparison-optimal-goodsignal-class/1387063).

## Installation

```
npm i @rbxts/task-event-emitter
```

## Usage

Create an EventEmitter with an array of parameters:

```ts
const emitter = new EventEmitter<[player: Player, something: string]>(janitor);
```

Or, wrap an RBXScriptSignal:

```ts
const onChildAdded = EventEmitter.wrap(object.ChildAdded);
```

## Example

```ts
import EventEmitter from "@rbxts/task-event-emitter";

const onChange = new EventEmitter<[property: string]>(this.janitor);

onChange.subscribe((property) => print(`Property ${name} changed!`));

onChange.emit("Name");

onChange.dispose();
```

```ts
import EventEmitter from "@rbxts/task-event-emitter";

const emitter = new EventEmitter(this.janitor);

const subscription = emitter.subscribe(() => {});

if (!subscription.closed) {
	subscription.unsubscribe();
}
```
