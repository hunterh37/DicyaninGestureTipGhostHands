import RealityKit
import UIKit

/// Configuration for a ghost-hand gesture tip: a translucent holographic hand
/// demonstrating a motion (twist, pull, push, swipe) around a target entity,
/// with a glowing direction arrow and floating labels. Auto-fades after
/// `duration` seconds or when `dismissWhen` fires.
public struct GestureTipConfig {
    /// How the ghost hand demonstrates the gesture.
    public enum Motion {
        /// Rotate around `axis` between 0 and `angle` radians (grip twist, dial turn).
        case twist(axis: SIMD3<Float>, angle: Float)
        /// Translate back and forth by `offset` metres (pull, push, swipe).
        case slide(offset: SIMD3<Float>)
    }

    public var title: String
    public var subtitle: String?
    /// Primary glow color for the arrow and title.
    public var tint: UIColor
    /// Ghost hand fill color.
    public var handTint: UIColor
    /// Seconds before the tip auto-fades. 5 is a good quick-tip default.
    public var duration: Float
    public var fadeTime: Float
    /// Seconds for one demonstrate-and-release loop of the motion.
    public var loopPeriod: Float
    public var motion: Motion
    /// Radius of the direction arc around the motion axis. 0 hides the arrow.
    public var arcRadius: Float
    /// Local offset of the arc center from the tip root.
    public var arcOffset: SIMD3<Float>
    /// Height of the floating label above the tip root.
    public var labelHeight: Float
    /// Uniform scale applied to the ghost hand.
    public var handScale: Float
    /// When non-nil, the tip is shown once: `GhostHandGestureTip.alreadySeen` /
    /// `markSeen` persist against this UserDefaults key. Marked automatically on dismiss.
    public var persistenceKey: String?

    public init(
        title: String,
        subtitle: String? = nil,
        tint: UIColor = UIColor(red: 0.30, green: 0.95, blue: 1.0, alpha: 1),
        handTint: UIColor = UIColor(red: 0.55, green: 0.95, blue: 1.0, alpha: 1),
        duration: Float = 5,
        fadeTime: Float = 0.5,
        loopPeriod: Float = 1.4,
        motion: Motion = .twist(axis: SIMD3<Float>(1, 0, 0), angle: 0.9),
        arcRadius: Float = 0.062,
        arcOffset: SIMD3<Float> = SIMD3<Float>(0.085, 0, 0),
        labelHeight: Float = 0.13,
        handScale: Float = 1,
        persistenceKey: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.handTint = handTint
        self.duration = duration
        self.fadeTime = fadeTime
        self.loopPeriod = loopPeriod
        self.motion = motion
        self.arcRadius = arcRadius
        self.arcOffset = arcOffset
        self.labelHeight = labelHeight
        self.handScale = handScale
        self.persistenceKey = persistenceKey
    }
}
