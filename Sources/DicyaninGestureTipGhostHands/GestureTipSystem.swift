import Foundation
import RealityKit

/// Animates every active `GestureTipComponent`: loops the ghost-hand motion,
/// pulses the arrow, bobs the label, and fades the tip out on timeout or when
/// its `dismissWhen` condition fires. Registered automatically by
/// `GhostHandGestureTip.build`.
public struct GestureTipSystem: System {
    static let query = EntityQuery(where: .has(GestureTipComponent.self))

    public init(scene: RealityKit.Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)

        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var tip = entity.components[GestureTipComponent.self] else { continue }
            tip.elapsed += dt

            if !tip.fading,
               tip.elapsed >= tip.duration || tip.dismissWhen?() == true {
                tip.fading = true
                if let key = tip.persistenceKey {
                    UserDefaults.standard.set(true, forKey: key)
                }
            }

            if tip.fading {
                tip.fadeElapsed += dt
                let f = tip.fadeElapsed / max(tip.fadeTime, 0.001)
                if f >= 1 {
                    entity.removeFromParent()
                    continue
                }
                entity.components.set(OpacityComponent(opacity: 1 - f))
            }

            animate(entity, tip: tip)
            entity.components.set(tip)
        }
    }

    /// Demonstrate for the first 60 percent of the loop with an ease in-out,
    /// then snap-release, mimicking how a real hand performs and resets a gesture.
    private func animate(_ root: Entity, tip: GestureTipComponent) {
        let phase = (tip.elapsed / tip.loopPeriod).truncatingRemainder(dividingBy: 1)
        let t: Float
        if phase < 0.6 {
            let p = phase / 0.6
            t = (1 - cos(p * .pi)) / 2
        } else {
            let p = (phase - 0.6) / 0.4
            t = 1 - p * p
        }

        if let hand = root.findEntity(named: GhostHandGestureTip.handName) {
            if tip.twistAngle != 0 {
                hand.orientation = simd_quatf(angle: -t * tip.twistAngle, axis: tip.twistAxis)
            }
            if tip.slideOffset != .zero {
                hand.position = tip.slideOffset * t
            }
        }
        if let arrow = root.findEntity(named: GhostHandGestureTip.arrowName) {
            arrow.scale = SIMD3<Float>(repeating: 1 + 0.07 * sin(tip.elapsed * 5))
        }
        if let label = root.findEntity(named: GhostHandGestureTip.labelName) {
            label.position.y = tip.labelHeight + 0.006 * sin(tip.elapsed * 2.2)
        }
    }
}
