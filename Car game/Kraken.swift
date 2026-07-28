//
//  Kraken.swift
//  Car game — Moto Hill Rider
//
//  The water monster: a giant kraken swimming after the rider, mantle and one
//  huge eye above the swell, tentacles arcing out of the water ahead of it.
//  Catch a tentacle and you're dragged under to the beak.
//

import SpriteKit

final class Kraken: ChaseMonster {

    override var bannerText:  String { "THE KRAKEN SURFACES…" }
    override var warningText: String { "KRAKEN CLOSING IN!" }
    override var devourText:  String { "DRAGGED UNDER!" }

    // MARK: Parts
    private let H: CGFloat              // screen height, the scale unit
    private var mantleNode: SKNode!
    private var eyePupil: SKShapeNode!
    /// One continuous tapered ribbon per tentacle; its path is rebuilt every
    /// frame along an animated spine so it curls like a real limb.
    private struct Tentacle {
        let shape: SKShapeNode
        let suckers: [SKShapeNode]
        let dx:    CGFloat   // anchor offset from the mantle center
        let reach: CGFloat   // how far the tip stretches (+ = toward the rider)
        let arc:   CGFloat   // how high it rises out of the water
        let po:    CGFloat   // phase offset so they don't move in lockstep
        let baseR: CGFloat   // root half-thickness
    }
    private var tentacles: [Tentacle] = []
    private let suckerSpots: [CGFloat] = [0.35, 0.5, 0.65, 0.8]
    private var spray: SKEmitterNode!

    // MARK: Palette — deep-sea purple hide, pale suckers, storm-yellow eye
    private let hide     = SKColor(red: 0.36, green: 0.20, blue: 0.44, alpha: 1)
    private let hideDark = SKColor(red: 0.22, green: 0.10, blue: 0.28, alpha: 1)
    private let hidePale = SKColor(red: 0.55, green: 0.35, blue: 0.62, alpha: 1)
    private let sucker   = SKColor(red: 0.85, green: 0.75, blue: 0.88, alpha: 1)
    private let eyeGold  = SKColor(red: 0.95, green: 0.85, blue: 0.30, alpha: 1)
    private let inkDark  = SKColor(red: 0.15, green: 0.08, blue: 0.05, alpha: 1)

    // MARK: - Init
    init(screenHeight: CGFloat, startX: CGFloat) {
        self.H = screenHeight
        super.init(startX: startX)
        buildTentacles()
        buildMantle()
        spray = makeDustEmitter(color: SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1),
                                rangeX: H * 0.30)
        spray.particleSpeed = 180
        spray.particleAlpha = 0.6
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Animation
    override func onDevour() {
        mantleNode.run(.sequence([.scale(to: 1.12, duration: 0.10),
                                  .scale(to: 1.00, duration: 0.30)]))
    }

    override func layout(groundY: (CGFloat) -> CGFloat) {
        // Mantle rides the swell behind the reaching tentacles
        let mx = catchX - H * 0.60
        let surf = groundY(mx)
        let bob = sin(phase * 1.1) * H * 0.03
        mantleNode.position = CGPoint(x: mx, y: surf + H * 0.16 + bob)
        mantleNode.zRotation = 0.06 * sin(phase * 0.8)

        // Slit pupil narrows and widens like it's sizing you up
        eyePupil.xScale = 0.75 + 0.25 * sin(phase * 1.7)

        // Tentacles arc out of the water, each on its own rhythm
        for t in tentacles {
            let ax = mx + t.dx
            let N = 10
            var spine: [CGPoint] = []
            for s in 0...N {
                let u = CGFloat(s) / CGFloat(N)
                let x = ax + t.reach * u
                      + sin(phase * 1.2 + t.po + u * 2.0) * H * 0.02 * u
                let y = surf - H * 0.10
                      + sin(u * .pi) * t.arc
                      + sin(phase * 1.6 + t.po + u * 2.8) * H * 0.05 * u
                spine.append(CGPoint(x: x, y: y))
            }
            t.shape.path = Self.ribbonPath(spine: spine) { u in
                self.tentacleR(u: u, baseR: t.baseR)
            }
            // Suckers ride the underside of the spine
            for (k, dot) in t.suckers.enumerated() {
                let u = suckerSpots[k]
                let f = u * CGFloat(N)
                let i = Int(f), fr = f - CGFloat(i)
                let a = spine[i], b = spine[min(i + 1, N)]
                let p = CGPoint(x: a.x + (b.x - a.x) * fr, y: a.y + (b.y - a.y) * fr)
                let len = max(1, hypot(b.x - a.x, b.y - a.y))
                let nx = (b.y - a.y) / len, ny = -(b.x - a.x) / len
                let r = tentacleR(u: u, baseR: t.baseR)
                dot.position = CGPoint(x: p.x + nx * r * 0.55, y: p.y + ny * r * 0.55)
            }
        }

        // Dragged under: down to the beak, just beneath the surface
        mouthCenter = CGPoint(x: mx + H * 0.30, y: surf - H * 0.05)

        // Spray where the lead tentacle rips through the surface
        spray.position = CGPoint(x: catchX - H * 0.05, y: surf + 6)
        if spray.targetNode == nil, let sc = scene { spray.targetNode = sc }
        spray.particleBirthRate = isChasing ? 160 : 30
    }

    // MARK: - Tentacles
    private func buildTentacles() {
        // (dx, reach, arc, phase offset, z, front-side?)
        let params: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, Bool)] = [
            ( H * 0.15,  H * 0.50, H * 0.34, 0.0, 0.95, true),   // the lead — its tip is the catch line
            ( H * 0.05,  H * 0.32, H * 0.46, 1.3, 0.90, true),
            ( 0,         H * 0.16, H * 0.55, 2.2, 0.35, false),
            (-H * 0.10, -H * 0.24, H * 0.46, 3.1, 0.90, true),
            (-H * 0.18, -H * 0.50, H * 0.34, 4.0, 0.35, false),
            (-H * 0.05,  H * 0.05, H * 0.60, 5.0, 0.30, false),
        ]
        for (dx, reach, arc, po, z, front) in params {
            let baseR = H * 0.055
            let shape = SKShapeNode()
            shape.fillColor = front ? hide : hideDark
            shape.strokeColor = hideDark
            shape.lineWidth = 2.5
            shape.lineJoin = .round
            shape.zPosition = z
            addChild(shape)
            // Pale suckers down the front tentacles; layout() positions them
            var suckers: [SKShapeNode] = []
            if front {
                for u in suckerSpots {
                    let dot = SKShapeNode(circleOfRadius: tentacleR(u: u, baseR: baseR) * 0.45)
                    dot.fillColor = sucker; dot.strokeColor = .clear
                    dot.zPosition = z + 0.01
                    addChild(dot)
                    suckers.append(dot)
                }
            }
            tentacles.append(Tentacle(shape: shape, suckers: suckers,
                                      dx: dx, reach: reach, arc: arc, po: po,
                                      baseR: baseR))
        }
    }

    /// Half-thickness of a tentacle at parameter u (0 root → 1 tip).
    private func tentacleR(u: CGFloat, baseR: CGFloat) -> CGFloat {
        baseR * (1 - 0.88 * u) + H * 0.004
    }

    /// Filled outline around a spine polyline: offset each spine point along
    /// its normal by the local radius, out one side and back the other.
    private static func ribbonPath(spine: [CGPoint],
                                   radius: (CGFloat) -> CGFloat) -> CGPath {
        let n = spine.count
        var left: [CGPoint] = [], right: [CGPoint] = []
        for i in 0..<n {
            let u = CGFloat(i) / CGFloat(n - 1)
            let prev = spine[max(0, i - 1)], next = spine[min(n - 1, i + 1)]
            var dx = next.x - prev.x, dy = next.y - prev.y
            let len = max(0.001, hypot(dx, dy)); dx /= len; dy /= len
            let r = radius(u)
            left.append(CGPoint(x: spine[i].x - dy * r, y: spine[i].y + dx * r))
            right.append(CGPoint(x: spine[i].x + dy * r, y: spine[i].y - dx * r))
        }
        let p = CGMutablePath()
        p.move(to: left[0])
        for pt in left.dropFirst() { p.addLine(to: pt) }
        for pt in right.reversed() { p.addLine(to: pt) }
        p.closeSubpath()
        return p
    }

    // MARK: - Mantle
    private func buildMantle() {
        mantleNode = SKNode()
        mantleNode.zPosition = 0.6
        addChild(mantleNode)

        // Swept crown trailing behind the dome
        let crown = CGMutablePath()
        crown.move(to: CGPoint(x: -H * 0.10, y: H * 0.28))
        crown.addQuadCurve(to: CGPoint(x: -H * 0.52, y: H * 0.46),
                           control: CGPoint(x: -H * 0.30, y: H * 0.46))
        crown.addQuadCurve(to: CGPoint(x: -H * 0.24, y: H * 0.10),
                           control: CGPoint(x: -H * 0.38, y: H * 0.22))
        crown.closeSubpath()
        let crownNode = SKShapeNode(path: crown)
        crownNode.fillColor = hide; crownNode.strokeColor = hideDark; crownNode.lineWidth = 3
        mantleNode.addChild(crownNode)

        // The dome itself
        let dome = SKShapeNode(ellipseOf: CGSize(width: H * 0.62, height: H * 0.70))
        dome.fillColor = hide; dome.strokeColor = hideDark; dome.lineWidth = 3
        mantleNode.addChild(dome)

        // Mottled spots
        for (sx, sy, sr) in [(-H * 0.14, H * 0.18, H * 0.045),
                             (-H * 0.02, H * 0.28, H * 0.030),
                             (-H * 0.18, H * 0.02, H * 0.030)] {
            let spot = SKShapeNode(circleOfRadius: sr)
            spot.fillColor = hidePale; spot.strokeColor = .clear
            spot.position = CGPoint(x: sx, y: sy)
            mantleNode.addChild(spot)
        }

        // One huge storm-lantern eye with a vertical slit
        let sclera = SKShapeNode(circleOfRadius: H * 0.10)
        sclera.fillColor = eyeGold; sclera.strokeColor = hideDark; sclera.lineWidth = 3
        sclera.glowWidth = H * 0.02
        sclera.position = CGPoint(x: H * 0.13, y: H * 0.05)
        mantleNode.addChild(sclera)
        eyePupil = SKShapeNode(ellipseOf: CGSize(width: H * 0.035, height: H * 0.115))
        eyePupil.fillColor = SKColor(white: 0.05, alpha: 1); eyePupil.strokeColor = .clear
        eyePupil.position = sclera.position
        mantleNode.addChild(eyePupil)
        let glint = SKShapeNode(circleOfRadius: H * 0.014)
        glint.fillColor = SKColor(white: 0.95, alpha: 0.9); glint.strokeColor = .clear
        glint.position = CGPoint(x: sclera.position.x + H * 0.025,
                                 y: sclera.position.y + H * 0.035)
        mantleNode.addChild(glint)

        // The beak, waiting at the waterline
        let beak = CGMutablePath()
        beak.move(to: CGPoint(x: H * 0.18, y: -H * 0.26))
        beak.addLine(to: CGPoint(x: H * 0.34, y: -H * 0.32))
        beak.addLine(to: CGPoint(x: H * 0.20, y: -H * 0.38))
        beak.closeSubpath()
        let beakNode = SKShapeNode(path: beak)
        beakNode.fillColor = inkDark; beakNode.strokeColor = .clear
        mantleNode.addChild(beakNode)
    }
}
