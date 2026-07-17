# DicyaninGestureTipGhostHands

Ghost-hand gesture tutorial overlays for visionOS. Shows a translucent animated hand performing a gesture (twist, slide, arc) with a floating label, looping until the user performs the action. Supports show-once persistence so returning users are not re-taught.

## Requirements

- visionOS 2.0+
- Swift 6

## Installation

```swift
.package(url: "https://github.com/hunterh37/DicyaninGestureTipGhostHands", from: "1.0.0")
```

## Usage

Register the system once:

```swift
import DicyaninGestureTipGhostHands

GestureTipSystem.registerSystem()
```

Build a tip and attach it near the object you want the user to interact with:

```swift
let config = GestureTipConfig(
    title: "Twist to open",
    subtitle: "Pinch and rotate",
    motion: .twist,          // .twist, .slide, .arc
    duration: 6,             // seconds before auto-dismiss
    persistenceKey: "jar-twist-tip"  // show once, ever
)

if let tip = GhostHandGestureTip.buildIfNeeded(config: config) {
    targetEntity.addChild(tip)
}
```

`buildIfNeeded` returns nil if the `persistenceKey` was already completed. Use `build(config:)` to always create one.

## Dismissal

- Auto-fades after `duration`.
- Dismiss programmatically via a `dismissWhen` closure on the component (e.g. when your gesture recognizer fires).
- `GhostHandGestureTip.resetSeen("jar-twist-tip")` clears persistence for testing.

## Configuration

`GestureTipConfig` exposes tint colors, hand scale, loop period, fade time, arc radius/offset, and label height.

## License

MIT
