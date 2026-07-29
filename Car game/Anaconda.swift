//
//  Anaconda.swift
//  Car game — Moto Hill Rider
//
//  The jungle monster: a monstrous anaconda as big as the Dread-wyrm but
//  nothing like it to look at — a single continuous serpent body slithering
//  in traveling humps, olive hide with dark blotches and a cream belly, and
//  a proper side-profile snake head: hinged jaw, curved fangs, slit-pupil
//  eye, forked tongue tasting the air. Pure muscle, no machinery.
//

import SpriteKit

final class Anaconda: ChaseMonster {

    override var bannerText:  String { "THE ANACONDA UNCOILS…" }
    override var warningText: String { "ANACONDA CLOSING IN!" }
    override var devourText:  String { "SWALLOWED WHOLE!" }

    // MARK: Parts
    private let H: CGFloat              // screen height, the scale unit
    private let bodyLen: CGFloat        // spine length behind the head
    private let headScale: CGFloat = 1.9   // head geometry is built at 1x, then scaled up
    private var bodyShape:  SKShapeNode!
    private var bellyShape: SKShapeNode!
    private var blotches: [SKShapeNode] = []
    private let blotchSpots: [CGFloat] = [0.04, 0.09, 0.15, 0.21, 0.27, 0.33,
                                          0.39, 0.45, 0.51, 0.57, 0.63, 0.70]
    private var headNode: SKNode!
    private var jawNode:  SKNode!
    private var tongueNode: SKNode!
    private var eyePupil: SKShapeNode!
    private var litter: SKEmitterNode!

    // MARK: Palette — river-green hide, swamp-dark blotches, cream underbelly
    private let olive      = SKColor(red: 0.33, green: 0.43, blue: 0.18, alpha: 1)
    private let oliveDark  = SKColor(red: 0.18, green: 0.26, blue: 0.10, alpha: 1)
    private let blotchInk  = SKColor(red: 0.11, green: 0.17, blue: 0.07, alpha: 1)
    private let cream      = SKColor(red: 0.86, green: 0.82, blue: 0.60, alpha: 1)
    private let fang       = SKColor(red: 0.94, green: 0.92, blue: 0.84, alpha: 1)
    private let tongueRed  = SKColor(red: 0.85, green: 0.15, blue: 0.10, alpha: 1)
    private let eyeYellow  = SKColor(red: 0.92, green: 0.85, blue: 0.30, alpha: 1)
    private let mouthDark  = SKColor(red: 0.22, green: 0.08, blue: 0.06, alpha: 1)

    // MARK: - Init
    init(screenHeight: CGFloat, startX: CGFloat) {
        self.H = screenHeight
        self.bodyLen = screenHeight * 8.2      // longer than the wyrm, and it shows
        super.init(startX: startX)
        buildBody()
        buildHead()
        litter = makeDustEmitter(color: SKColor(red: 0.30, green: 0.36, blue: 0.16, alpha: 1),
                                 rangeX: H * 0.5)
        litter.particleSpeed = 110
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Animation
    override func onDevour() {
        headNode.run(.sequence([.scale(to: headScale * 1.15, duration: 0.10),
                                .scale(to: headScale, duration: 0.30)]))
    }

    /// Half-thickness along the body: slim behind the skull, thickest through
    /// the mid-coils, tapering to a whip tail. The mid-coils nearly fill the
    /// vertical space, same class as the Dread-wyrm.
    private func bodyR(_ u: CGFloat) -> CGFloat {
        let base  = H * 0.30
        let bulge = 1 + 0.25 * sin(u * .pi)
        let neck  = 0.62 + 0.38 * min(1, u / 0.08)
        let taper = u < 0.55 ? 1 : max(0.05, 1 - (u - 0.55) / 0.45)
        return base * bulge * neck * taper
    }

    override func layout(groundY: (CGFloat) -> CGFloat) {
        // Spine: head end at the front, traveling humps rolling toward the tail
        let headAnchorX = catchX - H * 0.70    // jaw hinge; snout tip is the catch line
        let N = 36
        var spine: [CGPoint] = []
        for s in 0...N {
            let u = CGFloat(s) / CGFloat(N)
            let x = headAnchorX - bodyLen * u
            let hump = sin(phase * 1.9 - u * 8.5) * H * 0.075 * (0.2 + 0.8 * u)
            spine.append(CGPoint(x: x, y: groundY(x) + bodyR(u) * 0.85 + hump))
        }
        bodyShape.path = Self.ribbonPath(spine: spine) { u in self.bodyR(u) }

        // Cream belly: a thick stroke along the underside of the front half
        let belly = CGMutablePath()
        for s in 0...Int(CGFloat(N) * 0.62) {
            let u = CGFloat(s) / CGFloat(N)
            let p = spine[s]
            let pt = CGPoint(x: p.x, y: p.y - bodyR(u) * 0.55)
            if s == 0 { belly.move(to: pt) } else { belly.addLine(to: pt) }
        }
        bellyShape.path = belly

        // Blotches ride the back of the spine
        for (k, b) in blotches.enumerated() {
            let u = blotchSpots[k]
            let f = u * CGFloat(N)
            let i = Int(f), fr = f - CGFloat(i)
            let a = spine[i], bpt = spine[min(i + 1, N)]
            b.position = CGPoint(x: a.x + (bpt.x - a.x) * fr,
                                 y: a.y + (bpt.y - a.y) * fr + bodyR(u) * 0.35)
            b.zRotation = atan2(bpt.y - a.y, bpt.x - a.x)
        }

        // Head rides the first spine point, aimed along the neck
        let neckDir = atan2(spine[0].y - spine[1].y, spine[0].x - spine[1].x)
        headNode.position = CGPoint(x: spine[0].x, y: spine[0].y + H * 0.04)
        headNode.zRotation = neckDir + 0.04 * sin(phase * 1.4)

        // Jaw gapes, tongue flicks in bursts, pupil narrows
        jawNode.zRotation = -(0.18 + 0.14 * (0.5 + 0.5 * sin(phase * 1.6)))
        let flick = max(0, sin(phase * 2.7))
        tongueNode.xScale = 0.15 + 1.1 * flick * flick * flick
        eyePupil.xScale = 0.7 + 0.3 * sin(phase * 1.9)

        mouthCenter = headNode.convert(CGPoint(x: H * 0.18, y: -H * 0.02), to: self)

        // Leaf litter sprayed where the body plows the jungle floor
        litter.position = CGPoint(x: catchX - H * 0.8, y: groundY(catchX - H * 0.8) + 10)
        if litter.targetNode == nil, let sc = scene { litter.targetNode = sc }
        litter.particleBirthRate = isChasing ? 160 : 25
    }

    // MARK: - Body
    private func buildBody() {
        bodyShape = SKShapeNode()
        bodyShape.fillColor = olive
        bodyShape.strokeColor = oliveDark
        bodyShape.lineWidth = 3
        bodyShape.lineJoin = .round
        bodyShape.zPosition = 0.5
        addChild(bodyShape)

        bellyShape = SKShapeNode()
        bellyShape.strokeColor = cream.withAlphaComponent(0.85)
        bellyShape.lineWidth = H * 0.09
        bellyShape.lineCap = .round
        bellyShape.fillColor = .clear
        bellyShape.zPosition = 0.55
        addChild(bellyShape)

        // Big irregular saddle blotches down the back
        for k in 0..<blotchSpots.count {
            let u = blotchSpots[k]
            let r = bodyR(u)
            let b = SKShapeNode(ellipseOf: CGSize(width: r * (k % 2 == 0 ? 1.05 : 0.85),
                                                  height: r * 0.60))
            b.fillColor = blotchInk.withAlphaComponent(0.85)
            b.strokeColor = oliveDark; b.lineWidth = 1.5
            b.zPosition = 0.6
            addChild(b)
            blotches.append(b)
        }
    }

    // MARK: - Head (side profile, facing +x)
    private func buildHead() {
        headNode = SKNode()
        headNode.zPosition = 0.9
        headNode.setScale(headScale)      // geometry below is 1x; scale does the rest
        addChild(headNode)

        // Skull: rounded wedge with a long snout
        let skull = CGMutablePath()
        skull.move(to: CGPoint(x: H * 0.40, y: 0))                       // snout tip
        skull.addQuadCurve(to: CGPoint(x: H * 0.10, y: H * 0.105),       // crown
                           control: CGPoint(x: H * 0.33, y: H * 0.095))
        skull.addQuadCurve(to: CGPoint(x: -H * 0.16, y: H * 0.06),
                           control: CGPoint(x: -H * 0.05, y: H * 0.115))
        skull.addLine(to: CGPoint(x: -H * 0.16, y: -H * 0.025))
        skull.addQuadCurve(to: CGPoint(x: H * 0.40, y: 0),               // mouth line
                           control: CGPoint(x: H * 0.16, y: -H * 0.045))
        skull.closeSubpath()
        let skullNode = SKShapeNode(path: skull)
        skullNode.fillColor = olive; skullNode.strokeColor = oliveDark
        skullNode.lineWidth = 2.5
        headNode.addChild(skullNode)

        // Head scale pattern: a couple of arc strokes over the crown
        for (cx, cy, cr) in [(H * 0.12, H * 0.05, H * 0.05),
                             (-H * 0.02, H * 0.055, H * 0.045)] {
            let arc = SKShapeNode(path: {
                let p = CGMutablePath()
                p.addArc(center: CGPoint(x: cx, y: cy), radius: cr,
                         startAngle: 0.4, endAngle: 2.2, clockwise: false)
                return p
            }())
            arc.strokeColor = oliveDark.withAlphaComponent(0.6)
            arc.lineWidth = 1.5; arc.fillColor = .clear
            headNode.addChild(arc)
        }

        // The dark of the open mouth behind the jaws
        let gape = SKShapeNode(ellipseOf: CGSize(width: H * 0.16, height: H * 0.07))
        gape.fillColor = mouthDark; gape.strokeColor = .clear
        gape.position = CGPoint(x: H * 0.14, y: -H * 0.03)
        headNode.addChild(gape)

        // Curved fangs off the upper jaw
        for fx in [H * 0.33, H * 0.27] {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: fx, y: -H * 0.012))
            p.addQuadCurve(to: CGPoint(x: fx - H * 0.020, y: -H * 0.052),
                           control: CGPoint(x: fx + H * 0.008, y: -H * 0.040))
            p.addQuadCurve(to: CGPoint(x: fx - H * 0.026, y: -H * 0.012),
                           control: CGPoint(x: fx - H * 0.020, y: -H * 0.030))
            p.closeSubpath()
            let f = SKShapeNode(path: p)
            f.fillColor = fang; f.strokeColor = oliveDark; f.lineWidth = 1
            f.zPosition = 0.2
            headNode.addChild(f)
        }

        // Slit-pupil eye under a brow ridge
        let eye = SKShapeNode(circleOfRadius: H * 0.030)
        eye.fillColor = eyeYellow; eye.strokeColor = oliveDark; eye.lineWidth = 2
        eye.position = CGPoint(x: H * 0.15, y: H * 0.045)
        headNode.addChild(eye)
        eyePupil = SKShapeNode(ellipseOf: CGSize(width: H * 0.011, height: H * 0.042))
        eyePupil.fillColor = SKColor(white: 0.05, alpha: 1); eyePupil.strokeColor = .clear
        eyePupil.position = eye.position
        headNode.addChild(eyePupil)
        let brow = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: H * 0.10, y: H * 0.085))
            p.addQuadCurve(to: CGPoint(x: H * 0.21, y: H * 0.075),
                           control: CGPoint(x: H * 0.16, y: H * 0.095))
            return p
        }())
        brow.strokeColor = oliveDark; brow.lineWidth = 2.5
        brow.lineCap = .round; brow.fillColor = .clear
        headNode.addChild(brow)

        // Nostril
        let nostril = SKShapeNode(ellipseOf: CGSize(width: H * 0.014, height: H * 0.010))
        nostril.fillColor = oliveDark; nostril.strokeColor = .clear
        nostril.position = CGPoint(x: H * 0.34, y: H * 0.030)
        headNode.addChild(nostril)

        // Forked tongue, anchored at the snout so it flicks forward
        tongueNode = SKNode()
        tongueNode.position = CGPoint(x: H * 0.40, y: -H * 0.012)
        tongueNode.zPosition = 0.1
        let tp = CGMutablePath()
        tp.move(to: .zero)
        tp.addLine(to: CGPoint(x: H * 0.075, y: -H * 0.004))
        tp.move(to: CGPoint(x: H * 0.075, y: -H * 0.004))
        tp.addLine(to: CGPoint(x: H * 0.105, y: H * 0.010))
        tp.move(to: CGPoint(x: H * 0.075, y: -H * 0.004))
        tp.addLine(to: CGPoint(x: H * 0.100, y: -H * 0.022))
        let tongue = SKShapeNode(path: tp)
        tongue.strokeColor = tongueRed; tongue.lineWidth = 3
        tongue.lineCap = .round; tongue.fillColor = .clear
        tongueNode.addChild(tongue)
        headNode.addChild(tongueNode)

        // Hinged lower jaw with small back-teeth
        jawNode = SKNode()
        jawNode.position = CGPoint(x: -H * 0.10, y: -H * 0.03)
        jawNode.zPosition = 0.15
        headNode.addChild(jawNode)
        let jawPath = CGMutablePath()
        jawPath.move(to: .zero)
        jawPath.addLine(to: CGPoint(x: H * 0.44, y: -H * 0.020))
        jawPath.addQuadCurve(to: CGPoint(x: H * 0.02, y: -H * 0.060),
                             control: CGPoint(x: H * 0.22, y: -H * 0.065))
        jawPath.closeSubpath()
        let jaw = SKShapeNode(path: jawPath)
        jaw.fillColor = SKColor(red: 0.26, green: 0.34, blue: 0.14, alpha: 1)
        jaw.strokeColor = oliveDark; jaw.lineWidth = 2
        jawNode.addChild(jaw)
        for fx in [H * 0.36, H * 0.30] {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: fx, y: -H * 0.024))
            p.addLine(to: CGPoint(x: fx - H * 0.014, y: -H * 0.024))
            p.addLine(to: CGPoint(x: fx - H * 0.004, y: H * 0.002))
            p.closeSubpath()
            let f = SKShapeNode(path: p)
            f.fillColor = fang; f.strokeColor = .clear
            jawNode.addChild(f)
        }
    }
}
