//
//  DreadWyrm.swift
//  Car game — Moto Hill Rider
//
//  The desert monster: a colossal bio-mechanical sandworm that crawls along
//  the dunes gaping maw first, and swallows the bike whole when it catches
//  it — then its very long body streams past the screen.
//

import SpriteKit

final class DreadWyrm: ChaseMonster {

    override var bannerText:  String { "THE DREAD-WYRM STIRS…" }
    override var warningText: String { "WYRM CLOSING IN!" }
    override var devourText:  String { "DEVOURED!" }

    // MARK: Parts
    private let bodyR: CGFloat          // main tube radius
    private let headR: CGFloat
    private let segSpacing: CGFloat
    private var bodySegs: [(node: SKNode, r: CGFloat)] = []
    private var headNode:  SKNode!
    private var jawTop:    SKShapeNode!
    private var jawBottom: SKShapeNode!
    /// A ring of teeth that gyrates around the gullet ellipse.
    private struct ToothRing {
        let nodes: [SKShapeNode]
        let center: CGPoint
        let rx, ry: CGFloat
        let spin: CGFloat    // orbit speed vs phase; sign sets direction
    }
    private var toothRings: [ToothRing] = []
    private var eyeNode: SKShapeNode!
    private var dust: SKEmitterNode!

    // MARK: Palette — organic rust flesh fused with gunmetal machinery
    private let flesh     = SKColor(red: 0.48, green: 0.26, blue: 0.18, alpha: 1)
    private let fleshDark = SKColor(red: 0.30, green: 0.15, blue: 0.10, alpha: 1)
    private let belly     = SKColor(red: 0.78, green: 0.58, blue: 0.38, alpha: 1)
    private let metal     = SKColor(red: 0.36, green: 0.38, blue: 0.43, alpha: 1)
    private let metalDark = SKColor(red: 0.22, green: 0.23, blue: 0.27, alpha: 1)
    private let glow      = SKColor(red: 1.00, green: 0.45, blue: 0.12, alpha: 1)
    private let eyeRed    = SKColor(red: 1.00, green: 0.16, blue: 0.10, alpha: 1)
    private let teeth     = SKColor(red: 0.88, green: 0.84, blue: 0.72, alpha: 1)
    private let mawDark   = SKColor(red: 0.10, green: 0.03, blue: 0.03, alpha: 1)

    // MARK: - Init
    /// The wyrm scales off the screen height: the gaping head is roughly 80%
    /// of the vertical space, the body tube a bit slimmer and VERY long.
    init(screenHeight: CGFloat, startX: CGFloat) {
        self.bodyR = screenHeight * 0.34
        self.headR = screenHeight * 0.42
        self.segSpacing = screenHeight * 0.34 * 0.85
        super.init(startX: startX)
        buildBody()
        buildHead()
        dust = makeDustEmitter(color: SKColor(red: 0.85, green: 0.70, blue: 0.45, alpha: 1),
                               rangeX: bodyR * 1.4)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Animation
    override func onDevour() {
        headNode.run(.sequence([.scale(to: 1.12, duration: 0.10),
                                .scale(to: 1.00, duration: 0.30)]))
    }

    override func layout(groundY: (CGFloat) -> CGFloat) {
        // Head: front rim of the maw sits at catchX, gaping toward the rider
        let headCX = catchX - headR * 0.55
        let headCY = groundY(catchX) + headR * 0.62 + sin(phase * 1.2) * headR * 0.03
        headNode.position = CGPoint(x: headCX, y: headCY)
        mouthCenter = CGPoint(x: catchX - headR * 0.25, y: headCY)

        // Body: traveling wave down a tube that follows the dunes
        for (i, seg) in bodySegs.enumerated() {
            let x = headCX - headR * 0.4 - segSpacing * CGFloat(i + 1)
            let damp = min(1, CGFloat(i) / 3 + 0.3)      // neck moves less than tail
            let wave = sin(phase - CGFloat(i) * 0.55) * bodyR * 0.14 * damp
            seg.node.position = CGPoint(x: x, y: groundY(x) + seg.r * 0.72 + wave)
        }

        // Jaws chew the air, the sensor eye pulses
        let gape = 0.20 + 0.10 * sin(phase * 1.5)
        jawTop.zRotation    =  gape
        jawBottom.zRotation = -gape
        eyeNode.alpha = 0.65 + 0.35 * sin(phase * 2.1)

        // Teeth gyrate around the gullet, rings grinding in opposite directions
        for ring in toothRings {
            let n = CGFloat(ring.nodes.count)
            for (i, tooth) in ring.nodes.enumerated() {
                let a = CGFloat(i) / n * 2 * .pi + phase * ring.spin
                let pos = CGPoint(x: ring.center.x + cos(a) * ring.rx,
                                  y: ring.center.y + sin(a) * ring.ry)
                tooth.position = pos
                tooth.zRotation = atan2(ring.center.y - pos.y,
                                        ring.center.x - pos.x) + .pi / 2
                tooth.setScale(1 + 0.10 * sin(phase * 2 + CGFloat(i)))
            }
        }

        // Sand plume where the maw plows the dune
        dust.position = CGPoint(x: catchX - bodyR * 0.5, y: groundY(catchX) + 12)
        if dust.targetNode == nil, let sc = scene { dust.targetNode = sc }
        dust.particleBirthRate = isChasing ? 180 : 30
    }

    // MARK: - Body
    private func buildBody() {
        let count = 26
        for i in 0..<count {
            // Full girth for most of the length, tapering over the last stretch
            let tailT = max(0, CGFloat(i - 17)) / CGFloat(count - 18)
            let r = bodyR * (1 - 0.65 * tailT)
            let seg = makeSegment(r: r, mech: i % 3 == 1, detailed: i < 18)
            seg.zPosition = 0.8 - CGFloat(i) * 0.02      // recede toward the tail
            addChild(seg)
            bodySegs.append((seg, r))
        }
    }

    private func makeSegment(r: CGFloat, mech: Bool, detailed: Bool) -> SKNode {
        let seg = SKNode()
        let body = SKShapeNode(circleOfRadius: r)
        body.fillColor = flesh; body.strokeColor = fleshDark; body.lineWidth = 2.5
        seg.addChild(body)
        guard detailed else { return seg }   // plain tail rings

        if mech {
            // Bolted armor ring grafted around the flesh
            let plate = SKShapeNode(rect: CGRect(x: -r * 0.30, y: -r * 0.95,
                                                 width: r * 0.62, height: r * 1.9),
                                    cornerRadius: r * 0.2)
            plate.fillColor = metal; plate.strokeColor = metalDark; plate.lineWidth = 2
            seg.addChild(plate)
            for k in -1...1 {
                let rivet = SKShapeNode(circleOfRadius: r * 0.06)
                rivet.fillColor = SKColor(white: 0.85, alpha: 0.9)
                rivet.strokeColor = .clear
                rivet.position = CGPoint(x: 0, y: CGFloat(k) * r * 0.55)
                plate.addChild(rivet)
            }
            // Molten seam glowing where metal meets meat
            let seam = SKShapeNode(rect: CGRect(x: r * 0.38, y: -r * 0.70,
                                                width: r * 0.10, height: r * 1.4),
                                   cornerRadius: r * 0.05)
            seam.fillColor = glow; seam.strokeColor = .clear; seam.alpha = 0.85
            seg.addChild(seam)
        } else {
            // Organic ridge line down the flank
            let p = CGMutablePath()
            p.move(to: CGPoint(x: r * 0.15, y: -r * 0.72))
            p.addQuadCurve(to: CGPoint(x: r * 0.15, y: r * 0.72),
                           control: CGPoint(x: r * 0.42, y: 0))
            let arc = SKShapeNode(path: p)
            arc.strokeColor = fleshDark; arc.lineWidth = 2.5; arc.fillColor = .clear
            seg.addChild(arc)
            // Bioluminescent nodule on the ridge back
            let dot = SKShapeNode(circleOfRadius: r * 0.09)
            dot.fillColor = glow; dot.strokeColor = .clear
            dot.position = CGPoint(x: -r * 0.05, y: r * 0.72)
            seg.addChild(dot)
        }
        return seg
    }

    // MARK: - Head (side profile, maw gaping toward +x)
    private func buildHead() {
        headNode = SKNode()
        headNode.zPosition = 0.9
        addChild(headNode)
        let r = headR

        // Armored neck band where the head meets the body
        let neck = SKShapeNode(rect: CGRect(x: -r * 1.00, y: -r * 0.80,
                                            width: r * 0.38, height: r * 1.6),
                               cornerRadius: r * 0.15)
        neck.fillColor = metal; neck.strokeColor = metalDark; neck.lineWidth = 2
        neck.zPosition = 0.05
        headNode.addChild(neck)

        // Back dome of the skull
        let dome = SKShapeNode(circleOfRadius: r)
        dome.fillColor = flesh; dome.strokeColor = fleshDark; dome.lineWidth = 3
        dome.zPosition = 0.1
        headNode.addChild(dome)

        // Armor plating over the crown, with bolts along the back rim
        let crown = SKShapeNode(rect: CGRect(x: -r * 0.85, y: r * 0.35,
                                             width: r * 1.25, height: r * 0.5),
                                cornerRadius: r * 0.2)
        crown.fillColor = metal; crown.strokeColor = metalDark; crown.lineWidth = 2
        crown.zRotation = 0.18
        crown.zPosition = 0.15
        headNode.addChild(crown)
        for i in 0..<5 {
            let a = CGFloat.pi * 0.6 + CGFloat(i) / 4 * .pi * 0.8   // back arc
            let bolt = SKShapeNode(circleOfRadius: r * 0.05)
            bolt.fillColor = SKColor(white: 0.85, alpha: 0.9); bolt.strokeColor = .clear
            bolt.position = CGPoint(x: cos(a) * r * 0.88, y: sin(a) * r * 0.88)
            bolt.zPosition = 0.2
            headNode.addChild(bolt)
        }

        // Fleshy lip ring around the opening…
        let lip = SKShapeNode(ellipseOf: CGSize(width: r * 0.9, height: r * 1.55))
        lip.fillColor = belly; lip.strokeColor = fleshDark; lip.lineWidth = 3
        lip.position = CGPoint(x: r * 0.55, y: 0)
        lip.zPosition = 0.25
        headNode.addChild(lip)

        // …and the black gullet gaping inside it
        let gullet = SKShapeNode(ellipseOf: CGSize(width: r * 0.62, height: r * 1.25))
        gullet.fillColor = mawDark; gullet.strokeColor = .clear
        gullet.position = CGPoint(x: r * 0.60, y: 0)
        gullet.zPosition = 0.3
        headNode.addChild(gullet)

        // Teeth around the gullet rim, tips pointing into the throat
        addToothRing(center: CGPoint(x: r * 0.60, y: 0),
                     rx: r * 0.28, ry: r * 0.58, count: 12,
                     len: r * 0.16, z: 0.4, spin: 0.5)
        // A deeper, darker ring grinding the other way
        addToothRing(center: CGPoint(x: r * 0.56, y: 0),
                     rx: r * 0.16, ry: r * 0.34, count: 8,
                     len: r * 0.11, z: 0.35, spin: -0.8, dim: true)

        // Hinged armored jaws that chew the air, top and bottom
        jawTop = makeJaw(r: r, up: true)
        jawTop.position = CGPoint(x: r * 0.10, y: r * 0.80)
        jawTop.zPosition = 0.5
        headNode.addChild(jawTop)
        jawBottom = makeJaw(r: r, up: false)
        jawBottom.position = CGPoint(x: r * 0.10, y: -r * 0.80)
        jawBottom.zPosition = 0.5
        headNode.addChild(jawBottom)

        // Sensor eye in an armored pod on the crest
        let pod = SKShapeNode(rect: CGRect(x: -r * 0.26, y: -r * 0.14,
                                           width: r * 0.52, height: r * 0.32),
                              cornerRadius: r * 0.1)
        pod.fillColor = metalDark; pod.strokeColor = .clear
        pod.position = CGPoint(x: -r * 0.15, y: r * 0.95)
        pod.zPosition = 0.6
        headNode.addChild(pod)
        eyeNode = SKShapeNode(circleOfRadius: r * 0.11)
        eyeNode.fillColor = eyeRed; eyeNode.strokeColor = .clear
        eyeNode.glowWidth = r * 0.08
        eyeNode.position = CGPoint(x: -r * 0.15, y: r * 0.97)
        eyeNode.zPosition = 0.65
        headNode.addChild(eyeNode)
    }

    /// Triangular teeth placed around an ellipse, tips aimed at its center.
    /// Registered as a ring so layout() can gyrate them around the gullet.
    private func addToothRing(center: CGPoint, rx: CGFloat, ry: CGFloat,
                              count: Int, len: CGFloat, z: CGFloat,
                              spin: CGFloat, dim: Bool = false) {
        var nodes: [SKShapeNode] = []
        for _ in 0..<count {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -len * 0.28, y: 0))
            p.addLine(to: CGPoint(x: len * 0.28, y: 0))
            p.addLine(to: CGPoint(x: 0, y: -len))
            p.closeSubpath()
            let tooth = SKShapeNode(path: p)
            tooth.fillColor = dim ? teeth.withAlphaComponent(0.55) : teeth
            tooth.strokeColor = SKColor(red: 0.35, green: 0.30, blue: 0.24, alpha: 1)
            tooth.lineWidth = 1
            tooth.zPosition = z
            headNode.addChild(tooth)
            nodes.append(tooth)
        }
        // Positions and rotations are set every frame by layout()
        toothRings.append(ToothRing(nodes: nodes, center: center,
                                    rx: rx, ry: ry, spin: spin))
    }

    /// Armored jaw wedge; hinged at its node position so zRotation opens it.
    private func makeJaw(r: CGFloat, up: Bool) -> SKShapeNode {
        let s: CGFloat = up ? 1 : -1
        let p = CGMutablePath()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: r * 0.85, y: -s * r * 0.10))
        p.addLine(to: CGPoint(x: r * 0.15, y: s * r * 0.28))
        p.closeSubpath()
        let jaw = SKShapeNode(path: p)
        jaw.fillColor = metal; jaw.strokeColor = metalDark; jaw.lineWidth = 2
        return jaw
    }
}
