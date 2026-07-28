//
//  GraveMaw.swift
//  Car game — Moto Hill Rider
//
//  The mountain monster: a giant bear with a bone skull for a face and tank
//  treads where its legs should be. It grinds up the hills after the rider,
//  jaw chomping, exhaust stacks smoking, treads spraying dirt.
//

import SpriteKit

final class GraveMaw: ChaseMonster {

    override var bannerText:  String { "THE GRAVE-MAW RUMBLES…" }
    override var warningText: String { "GRAVE-MAW CLOSING IN!" }
    override var devourText:  String { "MAULED!" }

    // MARK: Parts
    private let H: CGFloat              // screen height, the scale unit
    private let treadW: CGFloat
    private let treadH: CGFloat
    private var treadFront: SKNode!
    private var treadRear:  SKNode!
    private var wheels:     [SKShapeNode] = []
    private var lugsBottom: [SKShapeNode] = []
    private var lugsTop:    [SKShapeNode] = []
    private var bodyNode:   SKNode!
    private var armNode:    SKNode!
    private var jawNode:    SKNode!
    private var eyeNode:    SKShapeNode!
    private var dust:  SKEmitterNode!
    private var smoke: SKEmitterNode!
    /// Where the jaws are, in bodyNode coordinates.
    private var mouthLocal: CGPoint = .zero

    // MARK: Palette — matted fur, bleached bone, gunmetal running gear
    private let fur       = SKColor(red: 0.42, green: 0.30, blue: 0.20, alpha: 1)
    private let furDark   = SKColor(red: 0.26, green: 0.18, blue: 0.11, alpha: 1)
    private let bone      = SKColor(red: 0.92, green: 0.90, blue: 0.84, alpha: 1)
    private let boneDark  = SKColor(red: 0.62, green: 0.58, blue: 0.50, alpha: 1)
    private let socket    = SKColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 1)
    private let metal     = SKColor(red: 0.36, green: 0.38, blue: 0.43, alpha: 1)
    private let metalDark = SKColor(red: 0.22, green: 0.23, blue: 0.27, alpha: 1)
    private let glow      = SKColor(red: 1.00, green: 0.45, blue: 0.12, alpha: 1)
    private let eyeRed    = SKColor(red: 1.00, green: 0.16, blue: 0.10, alpha: 1)

    // MARK: - Init
    init(screenHeight: CGFloat, startX: CGFloat) {
        self.H = screenHeight
        self.treadW = screenHeight * 0.46
        self.treadH = screenHeight * 0.15
        super.init(startX: startX)
        treadRear  = makeTread()
        treadRear.zPosition = 0.85
        addChild(treadRear)
        treadFront = makeTread()
        treadFront.zPosition = 0.86
        addChild(treadFront)
        buildBody()
        dust  = makeDustEmitter(color: SKColor(red: 0.45, green: 0.36, blue: 0.26, alpha: 1),
                                rangeX: treadW * 0.8)
        smoke = makeDustEmitter(color: SKColor(white: 0.45, alpha: 1), rangeX: H * 0.02)
        smoke.particleSpeed = 60
        smoke.particleLifetime = 1.1
        smoke.particleScaleSpeed = 0.8
        smoke.particleAlpha = 0.35
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Animation
    override func onDevour() {
        // Rear up and slam the jaws over the meal
        bodyNode.run(.sequence([.scale(to: 1.10, duration: 0.10),
                                .scale(to: 1.00, duration: 0.30)]))
    }

    override func layout(groundY: (CGFloat) -> CGFloat) {
        // Treads ride the terrain independently; the body spans them
        let ftX = catchX - H * 0.34
        let rtX = catchX - H * 0.82
        let ftY = groundY(ftX) + treadH * 0.42
        let rtY = groundY(rtX) + treadH * 0.42
        treadFront.position = CGPoint(x: ftX, y: ftY)
        treadRear.position  = CGPoint(x: rtX, y: rtY)
        let slope = atan2(ftY - rtY, ftX - rtX)
        treadFront.zRotation = slope
        treadRear.zRotation  = slope

        let rock = sin(phase * 1.3) * 0.025
        bodyNode.position = CGPoint(x: (ftX + rtX) / 2,
                                    y: (ftY + rtY) / 2 + H * 0.26
                                       + sin(phase * 1.3 + 0.7) * H * 0.012)
        bodyNode.zRotation = slope + rock

        // Chomping jaw, pulsing socket-light, swinging claw arm
        jawNode.zRotation = -(0.12 + 0.14 * (0.5 + 0.5 * sin(phase * 1.8)))
        eyeNode.alpha = 0.65 + 0.35 * sin(phase * 2.1)
        armNode.zRotation = -0.15 + sin(phase * 1.5) * 0.12

        // Running gear: wheels spin, lugs scroll around the track
        let spin = phase * 3
        for w in wheels { w.zRotation = -spin }
        let L = treadW - treadH               // straight section length
        let s = L / CGFloat(lugsBottom.count / 2)
        func lugX(_ j: Int, _ dir: CGFloat) -> CGFloat {
            let raw = (CGFloat(j) * s + dir * spin * treadH * 0.5)
                .truncatingRemainder(dividingBy: L)
            return -L / 2 + (raw < 0 ? raw + L : raw)
        }
        // Ground side runs backward relative to the hull, top side forward
        for (j, lug) in lugsBottom.enumerated() { lug.position.x = lugX(j, -1) }
        for (j, lug) in lugsTop.enumerated()    { lug.position.x = lugX(j,  1) }

        mouthCenter = bodyNode.convert(mouthLocal, to: self)

        // Dirt behind the treads, diesel smoke above the stacks
        dust.position = CGPoint(x: rtX - treadW * 0.2, y: groundY(rtX) + 10)
        if dust.targetNode == nil, let sc = scene {
            dust.targetNode = sc
            smoke.targetNode = sc
        }
        dust.particleBirthRate = isChasing ? 150 : 15
        smoke.position = bodyNode.convert(CGPoint(x: -H * 0.32, y: H * 0.30), to: self)
        smoke.particleBirthRate = isChasing ? 55 : 22
    }

    // MARK: - Running gear
    private func makeTread() -> SKNode {
        let tread = SKNode()
        let hull = SKShapeNode(rect: CGRect(x: -treadW / 2, y: -treadH / 2,
                                            width: treadW, height: treadH),
                               cornerRadius: treadH / 2)
        hull.fillColor = metalDark
        hull.strokeColor = SKColor(white: 0.08, alpha: 1); hull.lineWidth = 3
        tread.addChild(hull)

        // Road wheels
        for wx in [-treadW * 0.28, 0, treadW * 0.28] {
            let wheel = SKShapeNode(circleOfRadius: treadH * 0.32)
            wheel.fillColor = metal; wheel.strokeColor = SKColor(white: 0.08, alpha: 1)
            wheel.lineWidth = 2
            wheel.position = CGPoint(x: wx, y: 0)
            let hub = SKShapeNode(circleOfRadius: treadH * 0.10)
            hub.fillColor = metalDark; hub.strokeColor = .clear
            wheel.addChild(hub)
            // Spoke dot so the spin reads
            let spoke = SKShapeNode(circleOfRadius: treadH * 0.06)
            spoke.fillColor = SKColor(white: 0.75, alpha: 0.9); spoke.strokeColor = .clear
            spoke.position = CGPoint(x: treadH * 0.20, y: 0)
            wheel.addChild(spoke)
            tread.addChild(wheel)
            wheels.append(wheel)
        }

        // Track lugs along the top and bottom runs; layout() scrolls them
        for row in 0..<2 {
            let y = (row == 0 ? -1 : 1) * treadH * 0.52
            for _ in 0..<6 {
                let lug = SKShapeNode(rect: CGRect(x: -treadH * 0.07, y: -treadH * 0.06,
                                                   width: treadH * 0.14, height: treadH * 0.12),
                                      cornerRadius: 2)
                lug.fillColor = metalDark
                lug.strokeColor = SKColor(white: 0.08, alpha: 1); lug.lineWidth = 1.5
                lug.position = CGPoint(x: 0, y: y)
                tread.addChild(lug)
                if row == 0 { lugsBottom.append(lug) } else { lugsTop.append(lug) }
            }
        }
        return tread
    }

    // MARK: - Body, arm, skull
    private func buildBody() {
        bodyNode = SKNode()
        bodyNode.zPosition = 0.5
        addChild(bodyNode)

        // Armored chassis skirt bolting the bear to its running gear
        let skirt = SKShapeNode(rect: CGRect(x: -H * 0.40, y: -H * 0.26,
                                             width: H * 0.78, height: H * 0.14),
                                cornerRadius: H * 0.03)
        skirt.fillColor = metal; skirt.strokeColor = metalDark; skirt.lineWidth = 2.5
        bodyNode.addChild(skirt)
        for k in 0..<4 {
            let rivet = SKShapeNode(circleOfRadius: H * 0.012)
            rivet.fillColor = SKColor(white: 0.85, alpha: 0.9); rivet.strokeColor = .clear
            rivet.position = CGPoint(x: -H * 0.32 + CGFloat(k) * H * 0.20, y: -H * 0.19)
            bodyNode.addChild(rivet)
        }
        // Molten seam where the fur meets the machine
        let seam = SKShapeNode(rect: CGRect(x: -H * 0.34, y: -H * 0.13,
                                            width: H * 0.62, height: H * 0.02),
                               cornerRadius: H * 0.01)
        seam.fillColor = glow; seam.strokeColor = .clear; seam.alpha = 0.85
        bodyNode.addChild(seam)

        // The great furry mass, shoulder hump highest
        let torso = SKShapeNode(ellipseOf: CGSize(width: H * 0.80, height: H * 0.52))
        torso.fillColor = fur; torso.strokeColor = furDark; torso.lineWidth = 3
        torso.position = CGPoint(x: -H * 0.02, y: H * 0.06)
        bodyNode.addChild(torso)
        let hump = SKShapeNode(ellipseOf: CGSize(width: H * 0.42, height: H * 0.34))
        hump.fillColor = fur; hump.strokeColor = furDark; hump.lineWidth = 3
        hump.position = CGPoint(x: -H * 0.18, y: H * 0.24)
        bodyNode.addChild(hump)
        // Shaggy fur strokes
        for (fx, fy, rot) in [(-H * 0.30, -H * 0.04, 0.5), (-H * 0.05, -H * 0.08, 0.2),
                              (H * 0.18, -H * 0.02, -0.3)] {
            let p = CGMutablePath()
            p.move(to: .zero)
            p.addQuadCurve(to: CGPoint(x: 0, y: -H * 0.07),
                           control: CGPoint(x: H * 0.03, y: -H * 0.035))
            let tuft = SKShapeNode(path: p)
            tuft.strokeColor = furDark; tuft.lineWidth = 2.5; tuft.fillColor = .clear
            tuft.position = CGPoint(x: fx, y: fy)
            tuft.zRotation = CGFloat(rot)
            bodyNode.addChild(tuft)
        }

        // Exhaust stacks on the shoulder, ember-tipped
        for (i, ex) in [-H * 0.34, -H * 0.28].enumerated() {
            let pipe = SKShapeNode(rect: CGRect(x: -H * 0.020, y: 0,
                                                width: H * 0.04, height: H * 0.14 - CGFloat(i) * H * 0.03),
                                   cornerRadius: H * 0.008)
            pipe.fillColor = metalDark; pipe.strokeColor = SKColor(white: 0.08, alpha: 1)
            pipe.lineWidth = 2
            pipe.position = CGPoint(x: ex, y: H * 0.18)
            pipe.zRotation = 0.12
            bodyNode.addChild(pipe)
        }

        buildArm()
        buildSkullHead()
    }

    private func buildArm() {
        // Hinged at the shoulder so it swings mid-swipe
        armNode = SKNode()
        armNode.position = CGPoint(x: H * 0.16, y: H * 0.10)
        armNode.zPosition = 0.75
        bodyNode.addChild(armNode)

        let limb = SKShapeNode(rect: CGRect(x: -H * 0.05, y: -H * 0.30,
                                            width: H * 0.10, height: H * 0.32),
                               cornerRadius: H * 0.05)
        limb.fillColor = fur; limb.strokeColor = furDark; limb.lineWidth = 3
        limb.zRotation = -0.35
        armNode.addChild(limb)
        let paw = SKShapeNode(circleOfRadius: H * 0.065)
        paw.fillColor = furDark; paw.strokeColor = .clear
        paw.position = CGPoint(x: H * 0.10, y: -H * 0.27)
        armNode.addChild(paw)
        // Bone claws raking forward
        for k in 0..<3 {
            let p = CGMutablePath()
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: H * 0.015, y: H * 0.012))
            p.addLine(to: CGPoint(x: H * 0.065, y: -H * 0.020))
            p.closeSubpath()
            let claw = SKShapeNode(path: p)
            claw.fillColor = bone; claw.strokeColor = boneDark; claw.lineWidth = 1.5
            claw.position = CGPoint(x: H * 0.14, y: -H * 0.24 - CGFloat(k) * H * 0.030)
            claw.zRotation = -0.25 - CGFloat(k) * 0.18
            armNode.addChild(claw)
        }
    }

    private func buildSkullHead() {
        let head = SKNode()
        head.position = CGPoint(x: H * 0.34, y: H * 0.22)
        head.zPosition = 0.9
        bodyNode.addChild(head)

        // Furry head and round ears behind the mask
        let dome = SKShapeNode(circleOfRadius: H * 0.145)
        dome.fillColor = fur; dome.strokeColor = furDark; dome.lineWidth = 3
        dome.position = CGPoint(x: -H * 0.03, y: 0)
        head.addChild(dome)
        for ex in [-H * 0.10, H * 0.015] {
            let ear = SKShapeNode(circleOfRadius: H * 0.042)
            ear.fillColor = fur; ear.strokeColor = furDark; ear.lineWidth = 2.5
            ear.position = CGPoint(x: ex, y: H * 0.145)
            head.addChild(ear)
            let inner = SKShapeNode(circleOfRadius: H * 0.020)
            inner.fillColor = furDark; inner.strokeColor = .clear
            inner.position = ear.position
            head.addChild(inner)
        }

        // The skull mask: cranium and muzzle in bleached bone
        let cranium = SKShapeNode(ellipseOf: CGSize(width: H * 0.24, height: H * 0.20))
        cranium.fillColor = bone; cranium.strokeColor = boneDark; cranium.lineWidth = 2.5
        cranium.position = CGPoint(x: H * 0.02, y: H * 0.01)
        head.addChild(cranium)
        let muzzle = SKShapeNode(rect: CGRect(x: 0, y: -H * 0.065,
                                              width: H * 0.19, height: H * 0.105),
                                 cornerRadius: H * 0.03)
        muzzle.fillColor = bone; muzzle.strokeColor = boneDark; muzzle.lineWidth = 2.5
        muzzle.position = CGPoint(x: H * 0.06, y: -H * 0.030)
        head.addChild(muzzle)

        // Bolts pinning the mask to the flesh, one seam glowing
        for (bx, by) in [(-H * 0.075, H * 0.065), (-H * 0.085, -H * 0.02)] {
            let bolt = SKShapeNode(circleOfRadius: H * 0.011)
            bolt.fillColor = SKColor(white: 0.85, alpha: 0.9); bolt.strokeColor = .clear
            bolt.position = CGPoint(x: bx, y: by)
            head.addChild(bolt)
        }
        let seamDot = SKShapeNode(circleOfRadius: H * 0.012)
        seamDot.fillColor = glow; seamDot.strokeColor = .clear
        seamDot.position = CGPoint(x: -H * 0.045, y: H * 0.09)
        head.addChild(seamDot)

        // Empty socket with a burning red core
        let socketNode = SKShapeNode(circleOfRadius: H * 0.034)
        socketNode.fillColor = socket; socketNode.strokeColor = .clear
        socketNode.position = CGPoint(x: H * 0.055, y: H * 0.045)
        head.addChild(socketNode)
        eyeNode = SKShapeNode(circleOfRadius: H * 0.013)
        eyeNode.fillColor = eyeRed; eyeNode.strokeColor = .clear
        eyeNode.glowWidth = H * 0.010
        eyeNode.position = socketNode.position
        head.addChild(eyeNode)

        // Nasal hollow
        let nasal = SKShapeNode(ellipseOf: CGSize(width: H * 0.030, height: H * 0.022))
        nasal.fillColor = socket; nasal.strokeColor = .clear
        nasal.position = CGPoint(x: H * 0.225, y: H * 0.005)
        head.addChild(nasal)

        // Upper fangs hanging from the muzzle
        for k in 0..<4 {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -H * 0.008, y: 0))
            p.addLine(to: CGPoint(x: H * 0.008, y: 0))
            p.addLine(to: CGPoint(x: 0, y: -H * 0.028))
            p.closeSubpath()
            let fang = SKShapeNode(path: p)
            fang.fillColor = bone; fang.strokeColor = boneDark; fang.lineWidth = 1
            fang.position = CGPoint(x: H * 0.09 + CGFloat(k) * H * 0.038, y: -H * 0.082)
            head.addChild(fang)
        }

        // Lower jaw, hinged at the back so layout() can chomp it
        jawNode = SKNode()
        jawNode.position = CGPoint(x: H * 0.045, y: -H * 0.095)
        head.addChild(jawNode)
        let jawBone = SKShapeNode(rect: CGRect(x: 0, y: -H * 0.038,
                                               width: H * 0.185, height: H * 0.042),
                                  cornerRadius: H * 0.015)
        jawBone.fillColor = bone; jawBone.strokeColor = boneDark; jawBone.lineWidth = 2
        jawNode.addChild(jawBone)
        for k in 0..<3 {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -H * 0.007, y: 0))
            p.addLine(to: CGPoint(x: H * 0.007, y: 0))
            p.addLine(to: CGPoint(x: 0, y: H * 0.024))
            p.closeSubpath()
            let tooth = SKShapeNode(path: p)
            tooth.fillColor = bone; tooth.strokeColor = boneDark; tooth.lineWidth = 1
            tooth.position = CGPoint(x: H * 0.05 + CGFloat(k) * H * 0.045, y: H * 0.002)
            jawNode.addChild(tooth)
        }

        // The bite point, in body coordinates (head sits inside bodyNode)
        mouthLocal = CGPoint(x: H * 0.34 + H * 0.14, y: H * 0.22 - H * 0.06)
    }
}
