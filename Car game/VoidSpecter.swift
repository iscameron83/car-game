//
//  VoidSpecter.swift
//  Car game — Moto Hill Rider
//
//  The space monster: a floating specter with a body of churning smoke, four
//  segmented mechanical arms, and a long eyeless skull with a silver grin.
//  It never touches the regolith — it drifts above it, trailing vapor, and
//  reaches out with its front claws when it closes on the rider.
//

import SpriteKit

final class VoidSpecter: ChaseMonster {

    override var bannerText:  String { "THE VOID-SPECTER MANIFESTS…" }
    override var warningText: String { "SPECTER CLOSING IN!" }
    override var devourText:  String { "TAKEN!" }

    // MARK: Parts
    private let H: CGFloat              // screen height, the scale unit
    private var bodyNode: SKNode!       // smoke wisps + chest core
    private var headNode: SKNode!
    private var coreNode: SKShapeNode!
    private var wisps: [SKShapeNode] = []
    /// Shoulder-anchored two-segment arms; front pair reaches for the rider.
    private struct Arm {
        let root:  SKNode       // at the shoulder; rotates whole arm
        let elbow: SKNode       // mid-joint; rotates the forearm
        let baseA: CGFloat      // resting shoulder angle
        let po:    CGFloat      // phase offset
    }
    private var arms: [Arm] = []
    private var vapor: SKEmitterNode!

    // MARK: Palette — void smoke, chrome bone, cold cyan light
    private let smoke     = SKColor(red: 0.14, green: 0.15, blue: 0.20, alpha: 1)
    private let smokeEdge = SKColor(red: 0.30, green: 0.32, blue: 0.42, alpha: 1)
    private let shell     = SKColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1)
    private let shellHi   = SKColor(red: 0.38, green: 0.44, blue: 0.56, alpha: 1)
    private let metal     = SKColor(red: 0.36, green: 0.38, blue: 0.43, alpha: 1)
    private let metalDark = SKColor(red: 0.22, green: 0.23, blue: 0.27, alpha: 1)
    private let chrome    = SKColor(red: 0.85, green: 0.88, blue: 0.92, alpha: 1)
    private let glowCyan  = SKColor(red: 0.35, green: 0.90, blue: 1.00, alpha: 1)

    // MARK: - Init
    init(screenHeight: CGFloat, startX: CGFloat) {
        self.H = screenHeight
        super.init(startX: startX)
        buildBody()
        buildArms()
        buildHead()
        vapor = makeDustEmitter(color: SKColor(red: 0.25, green: 0.27, blue: 0.35, alpha: 1),
                                rangeX: H * 0.18)
        vapor.particleSpeed = 45
        vapor.particleLifetime = 1.2
        vapor.emissionAngle = -.pi / 2         // smoke sinks off the wisp tail
        vapor.emissionAngleRange = .pi * 0.5
        vapor.particleAlpha = 0.35
        vapor.particleScaleSpeed = 0.6
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Animation
    override func onDevour() {
        headNode.run(.sequence([.scale(to: 1.15, duration: 0.10),
                                .scale(to: 1.00, duration: 0.30)]))
    }

    override func layout(groundY: (CGFloat) -> CGFloat) {
        // The whole specter floats well above the terrain, swaying
        let bx = catchX - H * 0.28 + sin(phase * 0.9) * H * 0.02
        let by = groundY(catchX - H * 0.28) + H * 0.52
               + sin(phase * 1.1) * H * 0.035
        bodyNode.position = CGPoint(x: bx, y: by)
        bodyNode.zRotation = 0.05 * sin(phase * 0.8)

        // Smoke wisps churn: each layer breathes and sways on its own beat
        for (i, w) in wisps.enumerated() {
            let k = CGFloat(i)
            w.xScale = 1 + 0.06 * sin(phase * 1.4 + k * 1.1)
            w.yScale = 1 + 0.08 * sin(phase * 1.7 + k * 0.8)
            w.zRotation = 0.06 * sin(phase * 1.2 + k * 1.6)
        }
        coreNode.alpha = 0.55 + 0.45 * sin(phase * 2.1)

        // Arms flex; the front pair strains toward the rider
        for arm in arms {
            arm.root.zRotation  = arm.baseA + sin(phase * 1.5 + arm.po) * 0.16
            arm.elbow.zRotation = 0.35 + sin(phase * 1.8 + arm.po) * 0.22
        }

        // The skull leads, hungry
        headNode.position = CGPoint(x: bx + H * 0.10, y: by + H * 0.30)
        headNode.zRotation = -0.08 + 0.05 * sin(phase * 1.3)
        mouthCenter = CGPoint(x: bx + H * 0.22, y: by + H * 0.24)

        // Vapor bleeds off the wisp tail
        vapor.position = CGPoint(x: bx - H * 0.06, y: by - H * 0.30)
        if vapor.targetNode == nil, let sc = scene { vapor.targetNode = sc }
        vapor.particleBirthRate = isChasing ? 90 : 35
    }

    // MARK: - Smoke body
    private func buildBody() {
        bodyNode = SKNode()
        bodyNode.zPosition = 0.5
        addChild(bodyNode)

        // Layered translucent wisps: teardrop shapes tapering into the tail
        let layers: [(w: CGFloat, h: CGFloat, dx: CGFloat, dy: CGFloat, a: CGFloat)] = [
            (0.46, 0.72, 0,           -H * 0.04, 0.55),
            (0.36, 0.60, -H * 0.03,   0,         0.70),
            (0.27, 0.48,  H * 0.02,   H * 0.04,  0.90),
        ]
        for l in layers {
            let p = CGMutablePath()
            let w = H * l.w, h = H * l.h
            p.move(to: CGPoint(x: 0, y: h * 0.5))
            p.addQuadCurve(to: CGPoint(x: 0, y: -h * 0.5),
                           control: CGPoint(x: w * 0.72, y: 0))
            p.addQuadCurve(to: CGPoint(x: -w * 0.16, y: -h * 0.78),
                           control: CGPoint(x: -w * 0.30, y: -h * 0.55))
            p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.5),
                           control: CGPoint(x: -w * 0.72, y: 0))
            p.closeSubpath()
            let wisp = SKShapeNode(path: p)
            wisp.fillColor = smoke.withAlphaComponent(l.a)
            wisp.strokeColor = smokeEdge.withAlphaComponent(l.a * 0.6)
            wisp.lineWidth = 2
            wisp.position = CGPoint(x: l.dx, y: l.dy)
            bodyNode.addChild(wisp)
            wisps.append(wisp)
        }

        // Cold reactor core burning in the chest
        let coreRing = SKShapeNode(circleOfRadius: H * 0.045)
        coreRing.fillColor = metalDark; coreRing.strokeColor = metal; coreRing.lineWidth = 2
        coreRing.position = CGPoint(x: H * 0.03, y: H * 0.10)
        bodyNode.addChild(coreRing)
        coreNode = SKShapeNode(circleOfRadius: H * 0.028)
        coreNode.fillColor = glowCyan; coreNode.strokeColor = .clear
        coreNode.glowWidth = H * 0.03
        coreNode.position = coreRing.position
        bodyNode.addChild(coreNode)
    }

    // MARK: - Mechanical arms
    private func buildArms() {
        // (shoulder offset, resting angle, phase offset, z, reach scale)
        let params: [(sx: CGFloat, sy: CGFloat, baseA: CGFloat, po: CGFloat,
                      z: CGFloat, scale: CGFloat)] = [
            ( H * 0.10,  H * 0.16, -0.45, 0.0, 0.8,  1.00),  // front high, reaching
            ( H * 0.08,  H * 0.02, -0.15, 1.2, 0.75, 0.92),  // front low
            (-H * 0.06,  H * 0.18,  2.60, 2.1, 0.3,  0.88),  // rear high, raised back
            (-H * 0.08,  H * 0.04,  3.30, 3.0, 0.25, 0.80),  // rear low
        ]
        for p in params {
            let root = SKNode()
            root.position = CGPoint(x: p.sx, y: p.sy)
            root.zPosition = p.z
            bodyNode.addChild(root)

            let upperLen = H * 0.17 * p.scale
            let shoulder = SKShapeNode(circleOfRadius: H * 0.030 * p.scale)
            shoulder.fillColor = metal; shoulder.strokeColor = metalDark; shoulder.lineWidth = 2
            root.addChild(shoulder)
            let upper = SKShapeNode(rect: CGRect(x: 0, y: -H * 0.022,
                                                 width: upperLen, height: H * 0.044),
                                    cornerRadius: H * 0.02)
            upper.fillColor = metal; upper.strokeColor = metalDark; upper.lineWidth = 2
            root.addChild(upper)
            // Cyan seam down the upper segment
            let seam = SKShapeNode(rect: CGRect(x: upperLen * 0.15, y: -H * 0.006,
                                                width: upperLen * 0.6, height: H * 0.012),
                                   cornerRadius: H * 0.006)
            seam.fillColor = glowCyan; seam.strokeColor = .clear; seam.alpha = 0.7
            root.addChild(seam)

            let elbow = SKNode()
            elbow.position = CGPoint(x: upperLen, y: 0)
            root.addChild(elbow)
            let joint = SKShapeNode(circleOfRadius: H * 0.022 * p.scale)
            joint.fillColor = metalDark; joint.strokeColor = .clear
            elbow.addChild(joint)
            let foreLen = H * 0.15 * p.scale
            let fore = SKShapeNode(rect: CGRect(x: 0, y: -H * 0.016,
                                                width: foreLen, height: H * 0.032),
                                   cornerRadius: H * 0.014)
            fore.fillColor = metal; fore.strokeColor = metalDark; fore.lineWidth = 2
            elbow.addChild(fore)
            // Three chrome claw fingers
            for k in 0..<3 {
                let cp = CGMutablePath()
                cp.move(to: .zero)
                cp.addLine(to: CGPoint(x: H * 0.010, y: H * 0.008))
                cp.addLine(to: CGPoint(x: H * 0.045, y: -H * 0.012))
                cp.closeSubpath()
                let claw = SKShapeNode(path: cp)
                claw.fillColor = chrome; claw.strokeColor = metalDark; claw.lineWidth = 1
                claw.position = CGPoint(x: foreLen, y: 0)
                claw.zRotation = -0.4 + CGFloat(k) * 0.4
                elbow.addChild(claw)
            }
            arms.append(Arm(root: root, elbow: elbow, baseA: p.baseA, po: p.po))
        }
    }

    // MARK: - Head (long eyeless skull, silver grin)
    private func buildHead() {
        headNode = SKNode()
        headNode.zPosition = 0.9
        addChild(headNode)

        // Elongated dome sweeping far back — smooth, glossy, no eyes
        let dome = CGMutablePath()
        dome.move(to: CGPoint(x: H * 0.11, y: -H * 0.015))
        dome.addQuadCurve(to: CGPoint(x: H * 0.02, y: H * 0.065),
                          control: CGPoint(x: H * 0.115, y: H * 0.055))
        dome.addQuadCurve(to: CGPoint(x: -H * 0.30, y: H * 0.015),
                          control: CGPoint(x: -H * 0.13, y: H * 0.065))
        dome.addQuadCurve(to: CGPoint(x: -H * 0.05, y: -H * 0.020),
                          control: CGPoint(x: -H * 0.18, y: -H * 0.010))
        dome.closeSubpath()
        let domeNode = SKShapeNode(path: dome)
        domeNode.fillColor = shell
        domeNode.strokeColor = shellHi; domeNode.lineWidth = 2
        headNode.addChild(domeNode)
        // Glossy highlight streak along the crown
        let gloss = CGMutablePath()
        gloss.move(to: CGPoint(x: H * 0.05, y: H * 0.040))
        gloss.addQuadCurve(to: CGPoint(x: -H * 0.22, y: H * 0.030),
                           control: CGPoint(x: -H * 0.08, y: H * 0.058))
        let glossNode = SKShapeNode(path: gloss)
        glossNode.strokeColor = shellHi.withAlphaComponent(0.7)
        glossNode.lineWidth = 3; glossNode.lineCap = .round
        glossNode.fillColor = .clear
        headNode.addChild(glossNode)

        // Underslung jaw with the chrome grin
        let jaw = SKShapeNode(rect: CGRect(x: -H * 0.02, y: -H * 0.052,
                                           width: H * 0.13, height: H * 0.038),
                              cornerRadius: H * 0.014)
        jaw.fillColor = shell; jaw.strokeColor = shellHi; jaw.lineWidth = 1.5
        headNode.addChild(jaw)
        for k in 0..<6 {
            let tooth = SKShapeNode(rect: CGRect(x: 0, y: 0,
                                                 width: H * 0.013, height: H * 0.016),
                                    cornerRadius: H * 0.004)
            tooth.fillColor = chrome; tooth.strokeColor = .clear
            tooth.position = CGPoint(x: -H * 0.005 + CGFloat(k) * H * 0.019,
                                     y: -H * 0.036)
            headNode.addChild(tooth)
        }
        // A hint of the inner jaw glinting deeper in
        let inner = SKShapeNode(rect: CGRect(x: H * 0.035, y: -H * 0.030,
                                             width: H * 0.030, height: H * 0.010),
                                cornerRadius: H * 0.004)
        inner.fillColor = chrome.withAlphaComponent(0.5); inner.strokeColor = .clear
        headNode.addChild(inner)

        // Ribbed metal collar where skull meets smoke
        for k in 0..<3 {
            let rib = SKShapeNode(rect: CGRect(x: -H * 0.015, y: -H * 0.030,
                                               width: H * 0.012, height: H * 0.060),
                                  cornerRadius: H * 0.005)
            rib.fillColor = metal; rib.strokeColor = metalDark; rib.lineWidth = 1
            rib.position = CGPoint(x: -H * 0.10 - CGFloat(k) * H * 0.022, y: -H * 0.030)
            rib.zRotation = 0.25
            headNode.addChild(rib)
        }
    }
}
