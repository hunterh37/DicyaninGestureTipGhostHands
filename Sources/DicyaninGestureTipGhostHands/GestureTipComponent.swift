import RealityKit

/// Runtime state for an active gesture tip. Set by `GhostHandGestureTip.build`;
/// driven every frame by `GestureTipSystem`.
public struct GestureTipComponent: Component {
    public var elapsed: Float = 0
    public var fading: Bool = false
    public var fadeElapsed: Float = 0

    public var duration: Float
    public var fadeTime: Float
    public var loopPeriod: Float
    public var twistAxis: SIMD3<Float>
    public var twistAngle: Float
    public var slideOffset: SIMD3<Float>
    public var labelHeight: Float
    public var persistenceKey: String?
    /// Polled each frame on the main actor; returning true dismisses the tip early
    /// (for example, the player performed the gesture themselves).
    public var dismissWhen: (@MainActor () -> Bool)?

    public init(config: GestureTipConfig, dismissWhen: (@MainActor () -> Bool)? = nil) {
        duration = config.duration
        fadeTime = config.fadeTime
        loopPeriod = config.loopPeriod
        switch config.motion {
        case .twist(let axis, let angle):
            twistAxis = axis
            twistAngle = angle
            slideOffset = .zero
        case .slide(let offset):
            twistAxis = SIMD3<Float>(1, 0, 0)
            twistAngle = 0
            slideOffset = offset
        }
        labelHeight = config.labelHeight
        persistenceKey = config.persistenceKey
    }
}
