import RealityKit
import UIKit

/// Builds immersive ghost-hand gesture tips: a translucent holographic hand
/// demonstrating a motion on an entity (twist a grip, pull a lever, swipe a
/// surface), with a glowing direction arrow and floating labels. Attach the
/// returned entity to the target's parent at the spot the hand should grab.
///
///     let tip = GhostHandGestureTip.build(
///         config: GestureTipConfig(
///             title: "TWIST TO ACCELERATE",
///             subtitle: "Pull the right grip back",
///             persistenceKey: "throttleTipSeen"
///         ),
///         dismissWhen: { throttle > 0.2 }
///     )
///     handlebars.addChild(tip)
@MainActor
public enum GhostHandGestureTip {
    public nonisolated static let rootName = "ghostHandGestureTip"
    public nonisolated static let handName = "ghostHand"
    public nonisolated static let arrowName = "gestureArrow"
    public nonisolated static let labelName = "gestureLabel"

    /// True if a tip with this persistence key already completed once.
    public static func alreadySeen(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    public static func markSeen(_ key: String) {
        UserDefaults.standard.set(true, forKey: key)
    }

    public static func resetSeen(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Assembles a tip entity and registers the component and system (once).
    /// Returns nil if the config has a persistence key that was already seen.
    public static func buildIfNeeded(
        config: GestureTipConfig,
        dismissWhen: (@MainActor () -> Bool)? = nil
    ) -> Entity? {
        if let key = config.persistenceKey, alreadySeen(key) { return nil }
        return build(config: config, dismissWhen: dismissWhen)
    }

    public static func build(
        config: GestureTipConfig,
        dismissWhen: (@MainActor () -> Bool)? = nil
    ) -> Entity {
        GestureTipComponent.registerComponent()
        GestureTipSystem.registerSystem()

        let root = Entity()
        root.name = rootName
        root.components.set(GestureTipComponent(config: config, dismissWhen: dismissWhen))
        root.components.set(OpacityComponent(opacity: 1))

        root.addChild(buildGhostHand(config))
        if config.arcRadius > 0 {
            root.addChild(buildArrow(config))
        }
        root.addChild(buildLabel(config))
        return root
    }

    // MARK: - Materials

    private static func ghostMaterial(_ color: UIColor, alpha: Float) -> UnlitMaterial {
        var m = UnlitMaterial(color: color)
        m.blending = .transparent(opacity: .init(floatLiteral: alpha))
        return m
    }

    // MARK: - Ghost hand

    /// Translucent holographic hand: palm shell, four curled fingers, and a thumb.
    /// Built to wrap a roughly grip-sized cylinder; scale via `config.handScale`.
    private static func buildGhostHand(_ config: GestureTipConfig) -> Entity {
        let hand = Entity()
        hand.name = handName
        hand.scale = SIMD3<Float>(repeating: config.handScale)
        let mat = ghostMaterial(config.handTint, alpha: 0.32)

        let palm = ModelEntity(mesh: .generateSphere(radius: 0.045), materials: [mat])
        palm.scale = SIMD3<Float>(1.4, 0.75, 1.0)
        palm.position = SIMD3<Float>(0, 0.028, 0.030)
        hand.addChild(palm)

        for i in 0..<4 {
            let finger = ModelEntity(mesh: .generateCylinder(height: 0.065, radius: 0.0085),
                                     materials: [mat])
            finger.orientation = simd_quatf(angle: 1.15, axis: SIMD3<Float>(1, 0, 0))
            finger.position = SIMD3<Float>(-0.033 + Float(i) * 0.022, 0.032, -0.012)
            hand.addChild(finger)
        }

        let thumb = ModelEntity(mesh: .generateCylinder(height: 0.055, radius: 0.009),
                                materials: [mat])
        thumb.orientation = simd_quatf(angle: 0.9, axis: SIMD3<Float>(0, 0, 1))
        thumb.position = SIMD3<Float>(-0.055, 0.005, 0.028)
        hand.addChild(thumb)

        return hand
    }

    // MARK: - Direction arrow

    /// For twist motions: a glowing arc sweeping around the twist axis, capped
    /// with a cone arrowhead. For slide motions: a straight glowing arrow along
    /// the slide direction.
    private static func buildArrow(_ config: GestureTipConfig) -> Entity {
        let arrow = Entity()
        arrow.name = arrowName
        let mat = ghostMaterial(config.tint, alpha: 0.9)

        switch config.motion {
        case .twist:
            let radius = config.arcRadius
            let startAngle: Float = 0.35
            let endAngle: Float = 2.35
            let segments = 12
            for i in 0..<segments {
                let a = startAngle + (endAngle - startAngle) * Float(i) / Float(segments - 1)
                let seg = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.008, 0.006, 0.020),
                                                         cornerRadius: 0.003),
                                      materials: [mat])
                seg.position = config.arcOffset + SIMD3<Float>(0, radius * cos(a), radius * sin(a))
                seg.orientation = simd_quatf(angle: a, axis: SIMD3<Float>(-1, 0, 0))
                arrow.addChild(seg)
            }
            let tip = ModelEntity(mesh: .generateCone(height: 0.030, radius: 0.014),
                                  materials: [mat])
            let tipAngle = endAngle + 0.22
            tip.position = config.arcOffset
                + SIMD3<Float>(0, radius * cos(tipAngle), radius * sin(tipAngle))
            tip.orientation = simd_quatf(angle: tipAngle + .pi, axis: SIMD3<Float>(-1, 0, 0))
            arrow.addChild(tip)

        case .slide(let offset):
            let length = simd_length(offset)
            guard length > 0 else { break }
            let dir = offset / length
            let shaft = ModelEntity(mesh: .generateCylinder(height: length, radius: 0.005),
                                    materials: [mat])
            let rot = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: dir)
            shaft.orientation = rot
            shaft.position = config.arcOffset + dir * (length / 2)
            arrow.addChild(shaft)
            let tip = ModelEntity(mesh: .generateCone(height: 0.030, radius: 0.014),
                                  materials: [mat])
            tip.orientation = rot
            tip.position = config.arcOffset + dir * (length + 0.015)
            arrow.addChild(tip)
        }

        return arrow
    }

    // MARK: - Labels

    private static func buildLabel(_ config: GestureTipConfig) -> Entity {
        let label = Entity()
        label.name = labelName
        label.position = SIMD3<Float>(0, config.labelHeight, 0)

        let titleMesh = MeshResource.generateText(
            config.title,
            extrusionDepth: 0.002,
            font: .systemFont(ofSize: 0.024, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let title = ModelEntity(mesh: titleMesh, materials: [ghostMaterial(config.tint, alpha: 0.9)])
        let bounds = title.visualBounds(relativeTo: nil)
        title.position = SIMD3<Float>(-bounds.extents.x / 2, 0, 0)
        label.addChild(title)

        if let subtitle = config.subtitle {
            let subMesh = MeshResource.generateText(
                subtitle,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: 0.014, weight: .medium),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            let sub = ModelEntity(mesh: subMesh,
                                  materials: [ghostMaterial(config.handTint, alpha: 0.85)])
            let subBounds = sub.visualBounds(relativeTo: nil)
            sub.position = SIMD3<Float>(-subBounds.extents.x / 2, -0.028, 0)
            label.addChild(sub)
        }

        return label
    }
}
