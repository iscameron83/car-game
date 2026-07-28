	//
//  GameScene.swift
//  Car game — Moto Hill Rider
//

import SpriteKit
import UIKit

private enum Z {
    static let bgSky:   CGFloat = 0
    static let bgHills: CGFloat = 1
    static let terrain: CGFloat = 3
    static let bike:    CGFloat = 4
    static let hud:     CGFloat = 10
}

private struct PC {
    static let ground: UInt32 = 1 << 0
    static let wheel:  UInt32 = 1 << 1
    static let chassis: UInt32 = 1 << 2
    static let ragdoll: UInt32 = 1 << 3
}

enum GameLevel: CaseIterable { case mountain, desert, water, space, jungle }
enum GameVehicle: CaseIterable { case classic, hover, jetski, buggy, fanboat }

/// Which vehicles make sense on which level.
func allowedVehicles(for level: GameLevel) -> [GameVehicle] {
    switch level {
    case .mountain, .desert, .jungle:
        return [.classic, .hover, .buggy, .fanboat]
    case .water:
        return [.hover, .jetski, .fanboat]
    case .space:
        return [.classic, .hover, .buggy]   // a fan has no air to push out here
    }
}

/// All level-specific colors in one place.
private struct LevelTheme {
    let skyTop, skyBottom: SKColor
    let farTop, farBottom, midTop, midBottom, nearTop, nearBottom: SKColor
    let vegFar, vegNear: SKColor
    let surface, lip, dirt, speckle, stone, tuft: SKColor
    let cloudAlpha: ClosedRange<CGFloat>

    static let mountain = LevelTheme(
        skyTop:    SKColor(red: 0.28, green: 0.57, blue: 0.92, alpha: 1),
        skyBottom: SKColor(red: 0.68, green: 0.86, blue: 0.97, alpha: 1),
        farTop:    SKColor(red: 0.55, green: 0.74, blue: 0.60, alpha: 1),
        farBottom: SKColor(red: 0.74, green: 0.87, blue: 0.82, alpha: 1),
        midTop:    SKColor(red: 0.50, green: 0.75, blue: 0.36, alpha: 1),
        midBottom: SKColor(red: 0.67, green: 0.85, blue: 0.55, alpha: 1),
        nearTop:   SKColor(red: 0.33, green: 0.60, blue: 0.24, alpha: 1),
        nearBottom: SKColor(red: 0.46, green: 0.71, blue: 0.36, alpha: 1),
        vegFar:    SKColor(red: 0.25, green: 0.48, blue: 0.25, alpha: 1),
        vegNear:   SKColor(red: 0.15, green: 0.38, blue: 0.16, alpha: 1),
        surface:   SKColor(red: 0.46, green: 0.70, blue: 0.26, alpha: 1),
        lip:       SKColor(red: 0.56, green: 0.80, blue: 0.33, alpha: 1),
        dirt:      SKColor(red: 0.58, green: 0.42, blue: 0.23, alpha: 1),
        speckle:   SKColor(red: 0.44, green: 0.30, blue: 0.15, alpha: 0.55),
        stone:     SKColor(red: 0.52, green: 0.49, blue: 0.45, alpha: 0.9),
        tuft:      SKColor(red: 0.33, green: 0.56, blue: 0.16, alpha: 1),
        cloudAlpha: 0.70...0.95)

    static let desert = LevelTheme(
        skyTop:    SKColor(red: 0.30, green: 0.55, blue: 0.88, alpha: 1),
        skyBottom: SKColor(red: 0.98, green: 0.88, blue: 0.70, alpha: 1),
        farTop:    SKColor(red: 0.72, green: 0.57, blue: 0.52, alpha: 1),
        farBottom: SKColor(red: 0.90, green: 0.79, blue: 0.72, alpha: 1),
        midTop:    SKColor(red: 0.82, green: 0.62, blue: 0.42, alpha: 1),
        midBottom: SKColor(red: 0.93, green: 0.79, blue: 0.60, alpha: 1),
        nearTop:   SKColor(red: 0.72, green: 0.45, blue: 0.28, alpha: 1),
        nearBottom: SKColor(red: 0.84, green: 0.60, blue: 0.40, alpha: 1),
        vegFar:    SKColor(red: 0.42, green: 0.55, blue: 0.33, alpha: 1),
        vegNear:   SKColor(red: 0.30, green: 0.47, blue: 0.26, alpha: 1),
        surface:   SKColor(red: 0.91, green: 0.77, blue: 0.48, alpha: 1),
        lip:       SKColor(red: 0.97, green: 0.87, blue: 0.60, alpha: 1),
        dirt:      SKColor(red: 0.72, green: 0.51, blue: 0.30, alpha: 1),
        speckle:   SKColor(red: 0.58, green: 0.39, blue: 0.20, alpha: 0.55),
        stone:     SKColor(red: 0.62, green: 0.50, blue: 0.40, alpha: 0.9),
        tuft:      SKColor(red: 0.60, green: 0.50, blue: 0.24, alpha: 1),
        cloudAlpha: 0.35...0.60)

    static let water = LevelTheme(
        skyTop:    SKColor(red: 0.20, green: 0.55, blue: 0.90, alpha: 1),
        skyBottom: SKColor(red: 0.75, green: 0.92, blue: 0.97, alpha: 1),
        farTop:    SKColor(red: 0.45, green: 0.70, blue: 0.72, alpha: 1),
        farBottom: SKColor(red: 0.70, green: 0.88, blue: 0.88, alpha: 1),
        midTop:    SKColor(red: 0.30, green: 0.62, blue: 0.72, alpha: 1),
        midBottom: SKColor(red: 0.55, green: 0.82, blue: 0.85, alpha: 1),
        nearTop:   SKColor(red: 0.18, green: 0.52, blue: 0.68, alpha: 1),
        nearBottom: SKColor(red: 0.38, green: 0.70, blue: 0.80, alpha: 1),
        vegFar:    SKColor(red: 0.85, green: 0.30, blue: 0.22, alpha: 1),   // buoy red
        vegNear:   SKColor(red: 0.80, green: 0.20, blue: 0.14, alpha: 1),
        surface:   SKColor(red: 0.30, green: 0.72, blue: 0.85, alpha: 1),
        lip:       SKColor(red: 0.95, green: 0.98, blue: 1.00, alpha: 1),   // foam
        dirt:      SKColor(red: 0.09, green: 0.33, blue: 0.58, alpha: 1),   // deep water
        speckle:   SKColor(red: 0.75, green: 0.90, blue: 0.98, alpha: 0.4),
        stone:     SKColor(red: 0.78, green: 0.92, blue: 0.98, alpha: 0.5), // bubbles
        tuft:      SKColor(red: 0.92, green: 0.97, blue: 1.00, alpha: 1),   // spray wisps
        cloudAlpha: 0.50...0.80)

    static let space = LevelTheme(
        skyTop:    SKColor(red: 0.01, green: 0.01, blue: 0.05, alpha: 1),
        skyBottom: SKColor(red: 0.09, green: 0.09, blue: 0.18, alpha: 1),
        farTop:    SKColor(red: 0.36, green: 0.36, blue: 0.42, alpha: 1),
        farBottom: SKColor(red: 0.52, green: 0.52, blue: 0.58, alpha: 1),
        midTop:    SKColor(red: 0.44, green: 0.44, blue: 0.50, alpha: 1),
        midBottom: SKColor(red: 0.60, green: 0.60, blue: 0.66, alpha: 1),
        nearTop:   SKColor(red: 0.38, green: 0.38, blue: 0.43, alpha: 1),
        nearBottom: SKColor(red: 0.52, green: 0.52, blue: 0.57, alpha: 1),
        vegFar:    SKColor(red: 0.42, green: 0.42, blue: 0.47, alpha: 1),   // boulders
        vegNear:   SKColor(red: 0.30, green: 0.30, blue: 0.35, alpha: 1),
        surface:   SKColor(red: 0.70, green: 0.69, blue: 0.66, alpha: 1),   // moon rock
        lip:       SKColor(red: 0.82, green: 0.81, blue: 0.78, alpha: 1),
        dirt:      SKColor(red: 0.44, green: 0.43, blue: 0.41, alpha: 1),
        speckle:   SKColor(red: 0.30, green: 0.29, blue: 0.28, alpha: 0.55),
        stone:     SKColor(red: 0.58, green: 0.57, blue: 0.55, alpha: 0.9),
        tuft:      SKColor(red: 0.52, green: 0.51, blue: 0.49, alpha: 1),   // rock shards
        cloudAlpha: 0.0...0.01)   // no clouds in a vacuum

    static let jungle = LevelTheme(
        skyTop:    SKColor(red: 0.35, green: 0.62, blue: 0.80, alpha: 1),
        skyBottom: SKColor(red: 0.80, green: 0.90, blue: 0.78, alpha: 1),   // humid haze
        farTop:    SKColor(red: 0.35, green: 0.55, blue: 0.42, alpha: 1),
        farBottom: SKColor(red: 0.60, green: 0.78, blue: 0.62, alpha: 1),
        midTop:    SKColor(red: 0.20, green: 0.46, blue: 0.26, alpha: 1),
        midBottom: SKColor(red: 0.42, green: 0.66, blue: 0.42, alpha: 1),
        nearTop:   SKColor(red: 0.10, green: 0.35, blue: 0.16, alpha: 1),
        nearBottom: SKColor(red: 0.24, green: 0.50, blue: 0.26, alpha: 1),
        vegFar:    SKColor(red: 0.16, green: 0.40, blue: 0.20, alpha: 1),
        vegNear:   SKColor(red: 0.08, green: 0.28, blue: 0.12, alpha: 1),
        surface:   SKColor(red: 0.28, green: 0.52, blue: 0.20, alpha: 1),
        lip:       SKColor(red: 0.40, green: 0.64, blue: 0.28, alpha: 1),
        dirt:      SKColor(red: 0.38, green: 0.26, blue: 0.14, alpha: 1),   // wet earth
        speckle:   SKColor(red: 0.26, green: 0.17, blue: 0.09, alpha: 0.55),
        stone:     SKColor(red: 0.45, green: 0.40, blue: 0.32, alpha: 0.9),
        tuft:      SKColor(red: 0.20, green: 0.50, blue: 0.14, alpha: 1),
        cloudAlpha: 0.60...0.85)   // low mist
}

/// Handling character per vehicle.
private struct VehicleSpec {
    let accelScale: CGFloat   // engine strength multiplier
    let brakeGrip:  CGFloat   // per-frame velocity retention while braking
    let damping:    CGFloat   // linear damping (coasting resistance)

    static let classic = VehicleSpec(accelScale: 1.0,  brakeGrip: 0.88,  damping: 0.30)
    // Hover: glides like it's on ice — weak brakes, barely any rolling drag
    static let hover   = VehicleSpec(accelScale: 0.85, brakeGrip: 0.965, damping: 0.08)
    // Jetski: planes on water — decent drag when off throttle, mid brakes
    static let jetski  = VehicleSpec(accelScale: 0.9,  brakeGrip: 0.93,  damping: 0.45)
    // Buggy: punchy engine, four fat tires that really bite when you brake
    static let buggy   = VehicleSpec(accelScale: 1.15, brakeGrip: 0.84,  damping: 0.35)
    // Fan boat: prop thrust and NO wheel brakes — reversing the fan barely slows it
    static let fanboat = VehicleSpec(accelScale: 0.95, brakeGrip: 0.975, damping: 0.18)
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Config
    let level:   GameLevel
    let vehicle: GameVehicle
    private var theme: LevelTheme {
        switch level {
        case .mountain: return .mountain
        case .desert:   return .desert
        case .water:    return .water
        case .space:    return .space
        case .jungle:   return .jungle
        }
    }
    private var spec: VehicleSpec {
        switch vehicle {
        case .classic: return .classic
        case .hover:   return .hover
        case .jetski:  return .jetski
        case .buggy:   return .buggy
        case .fanboat: return .fanboat
        }
    }
    /// True when this vehicle rides ON the water via buoyancy instead of
    /// solid ground collision (jetski always; fan boat on the water level).
    private var floating: Bool {
        level == .water && (vehicle == .jetski || vehicle == .fanboat)
    }

    init(size: CGSize, level: GameLevel, vehicle: GameVehicle) {
        self.level = level
        self.vehicle = vehicle
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Terrain
    private var terrainPoints: [CGPoint] = []
    private var generatedUpTo: CGFloat   = 0
    private let segLen: CGFloat          = 35
    private var terrainNodes: [SKNode]   = []
    // Water: scheduled wave features (ramp up the back, steep launch face)
    private var waterWaves: [(x0: CGFloat, len: CGFloat, h: CGFloat)] = []
    private var nextWaveX: CGFloat = 1800
    // Space: scheduled craters (raised rims around a bowl = natural jumps)
    private var craters: [(x0: CGFloat, len: CGFloat, rimH: CGFloat, depth: CGFloat)] = []
    private var nextCraterX: CGFloat = 1500

    // MARK: Bike
    // One heavy chassis physics body that rides on two wheel contact points.
    // allowsRotation = false means it CAN'T flip no matter what.
    // Wheel visuals spin independently based on velocity.
    private var bikeNode:       SKNode!      // the physics body
    private var rearWheelVis:   SKNode!      // visual only, spins
    private var frontWheelVis:  SKNode!      // visual only, spins
    private var chassisVis:     SKNode!      // visual only
    private var riderNode:      SKNode!

    private let rearR:    CGFloat = 22
    private let frontR:   CGFloat = 20
    private let wheelbase: CGFloat = 86
    // MARK: Parallax background
    // Each layer is a child of the camera; its content scrolls at a fraction
    // of camera speed and wraps every L points (content is 3 copies wide).
    private struct BGLayer {
        let content:   SKNode
        let container: SKNode
        let f:     CGFloat   // horizontal parallax factor (0 = glued to camera)
        let fy:    CGFloat   // vertical parallax factor
        let L:     CGFloat   // wrap period
        let drift: CGFloat   // constant scroll speed (clouds), pt/s
    }
    private var bgLayers: [BGLayer] = []
    private var camYRef: CGFloat        = 0
    private var sceneTime: TimeInterval = 0

    private var wheelSpin: CGFloat = 0       // accumulated visual spin angle
    private var wheeliePitch: CGFloat = 0    // visual-only nose-up lift (radians)
    private var suspOffset: CGFloat = 0      // visual suspension: chassis dip (pts)
    private var suspVel:    CGFloat = 0
    private var sprayEmitter: SKEmitterNode? // watercraft wake spray
    private var fanBlades: SKNode?           // fan boat prop, spins with throttle

    // MARK: Haptics (no effect in the simulator — device only)
    private let landingHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let crashHaptic   = UIImpactFeedbackGenerator(style: .heavy)
    private var chassisSlope: CGFloat = 0    // smoothed terrain slope for chassis art
    private var wasGrounded             = true  // for detecting the crest-launch moment

    // MARK: Controls
    private(set) var gasActive   = false
    private(set) var brakeActive = false

    // MARK: HUD
    private var camNode:     SKCameraNode!
    private var screenNode:  SKNode!         // camera child holding all screen-fixed content
    private var camScale:    CGFloat = 1     // 1 = normal, >1 = zoomed out
    private var distLabel:   SKLabelNode!
    private var pointsLabel: SKLabelNode!
    private var speedLabel:  SKLabelNode!

    // MARK: Scoring
    private var flipCount = 0
    private var flipProgress: CGFloat = 0   // accumulated airborne rotation
    private var lastZRot: CGFloat     = 0
    private var groundedFrames        = 0

    // MARK: State
    private var fuel: CGFloat          = 1.0
    private var rpm:  CGFloat          = 0
    private var startX: CGFloat        = 0
    private var lastTime: TimeInterval = 0
    private(set) var crashed           = false
    private var crashTime: TimeInterval = 0
    private var ragdollNodes: [SKNode]  = []
    private weak var ragdollTorso: SKNode?

    // MARK: Monster
    private var monster: ChaseMonster?
    private var monsterWarning: SKLabelNode?
    private var crashCause = "WIPEOUT!"

    /// Set by GameViewController; called when the player restarts after a crash.
    var onRestartRequested: (() -> Void)?
    /// Called with the final score once the wipeout screen appears.
    var onCrashed: ((Int) -> Void)?

    // MARK: - Public API
    func setGas(_ on: Bool) {
        if crashed { if on { maybeRestart() }; return }
        gasActive = on
        BikeAudio.shared.setThrottle(on)
    }
    func setBrake(_ on: Bool) {
        if crashed { if on { maybeRestart() }; return }
        brakeActive = on
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if crashed { maybeRestart() }
    }

    private func maybeRestart() {
        // Let the ragdoll fly and the wipeout screen land before restarting
        guard sceneTime - crashTime > 2.0 else { return }
        onRestartRequested?()
    }

    private func crash(swallowed: Bool = false) {
        guard !crashed else { return }
        crashed = true
        crashTime = sceneTime
        gasActive = false; brakeActive = false
        BikeAudio.shared.setThrottle(false)
        BikeAudio.shared.playImpact(intensity: 1.0)

        // Big double-hit: heavy thud, then the system "error" rumble
        crashHaptic.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        if swallowed { swallowBike() } else { buildRagdoll() }

        // Give the ragdoll a good stretch of glory before the overlay drops
        run(.sequence([.wait(forDuration: 1.6), .run { [weak self] in
            guard let self else { return }
            self.showCrashOverlay()
            self.onCrashed?(self.totalPoints())
        }]))
    }

    /// The monster takes bike and rider whole: freeze physics and pull the
    /// whole thing into its mouth while it shrinks away.
    private func swallowBike() {
        guard let monster, let pb = bikeNode.physicsBody else { return }
        pb.velocity = .zero
        pb.angularVelocity = 0
        pb.isDynamic = false      // actions drive it now; update loop stays alive
        let move = SKAction.move(to: monster.mouthCenter, duration: 0.35)
        move.timingMode = .easeIn
        bikeNode.run(.sequence([.group([move,
                                        .scale(to: 0.2, duration: 0.35),
                                        .rotate(byAngle: 0.5, duration: 0.35)]),
                                .fadeOut(withDuration: 0.10)]))
    }

    /// Throw the rider off the bike as a jointed ragdoll.
    private func buildRagdoll() {
        guard let pb = bikeNode.physicsBody else { return }
        riderNode.isHidden = true

        let jacket = SKColor(red: 0.82, green: 0.20, blue: 0.14, alpha: 1)
        let pants  = SKColor(red: 0.20, green: 0.22, blue: 0.30, alpha: 1)
        let helmet = SKColor(red: 0.88, green: 0.12, blue: 0.12, alpha: 1)
        let vel    = pb.velocity

        func launch(_ node: SKShapeNode, body: SKPhysicsBody, at p: CGPoint, mass: CGFloat) {
            node.position = p
            node.zPosition = Z.bike + 0.4   // behind the water-front overlay
            body.mass = mass
            body.friction = 0.5
            body.restitution = 0.35
            body.linearDamping = 0.2
            body.angularDamping = 0.3               // low = floppy windmilling
            body.categoryBitMask    = PC.ragdoll
            body.collisionBitMask   = PC.ground     // tumbles on terrain, ignores the bike
            body.contactTestBitMask = 0
            body.velocity = CGVector(dx: vel.dx * CGFloat.random(in: 0.80...1.05),
                                     dy: max(vel.dy, 0) + CGFloat.random(in: 200...320))
            body.angularVelocity = CGFloat.random(in: -9...9)
            node.physicsBody = body
            addChild(node)
            ragdollNodes.append(node)
        }

        let base = chassisVis.convert(CGPoint(x: -13, y: 20), to: self)

        let torso = SKShapeNode(rect: CGRect(x: -9, y: -20, width: 18, height: 40), cornerRadius: 6)
        torso.fillColor = jacket
        torso.strokeColor = SKColor(red: 0.55, green: 0.10, blue: 0.06, alpha: 1); torso.lineWidth = 1.5
        launch(torso, body: SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 40)),
               at: base, mass: 1.4)
        ragdollTorso = torso

        let head = SKShapeNode(circleOfRadius: 13)
        head.fillColor = helmet
        head.strokeColor = SKColor(red: 0.50, green: 0.04, blue: 0.04, alpha: 1); head.lineWidth = 1.5
        let stripe = SKShapeNode(rect: CGRect(x: -2.5, y: -11, width: 5, height: 22), cornerRadius: 2.5)
        stripe.fillColor = SKColor(white: 0.95, alpha: 1); stripe.strokeColor = .clear
        stripe.zRotation = 0.9
        head.addChild(stripe)
        launch(head, body: SKPhysicsBody(circleOfRadius: 13),
               at: CGPoint(x: base.x + 3, y: base.y + 32), mass: 0.6)

        let legSize = CGSize(width: 9, height: 26)
        let nearLeg = SKShapeNode(rect: CGRect(x: -4.5, y: -13, width: 9, height: 26), cornerRadius: 4.5)
        nearLeg.fillColor = pants; nearLeg.strokeColor = .clear
        launch(nearLeg, body: SKPhysicsBody(rectangleOf: legSize),
               at: CGPoint(x: base.x + 4, y: base.y - 30), mass: 0.5)

        let farLeg = SKShapeNode(rect: CGRect(x: -4.5, y: -13, width: 9, height: 26), cornerRadius: 4.5)
        farLeg.fillColor = SKColor(red: 0.13, green: 0.14, blue: 0.20, alpha: 1); farLeg.strokeColor = .clear
        launch(farLeg, body: SKPhysicsBody(rectangleOf: legSize),
               at: CGPoint(x: base.x - 4, y: base.y - 30), mass: 0.5)

        let arm = SKShapeNode(rect: CGRect(x: -3.5, y: -13, width: 7, height: 26), cornerRadius: 3.5)
        arm.fillColor = jacket; arm.strokeColor = .clear
        launch(arm, body: SKPhysicsBody(rectangleOf: CGSize(width: 7, height: 26)),
               at: CGPoint(x: base.x + 10, y: base.y + 8), mass: 0.4)

        // Pin the parts together with limited joints so it flails, not detaches
        func pin(_ a: SKNode, _ b: SKNode, anchor: CGPoint, limit: CGFloat) {
            guard let ba = a.physicsBody, let bb = b.physicsBody else { return }
            let j = SKPhysicsJointPin.joint(withBodyA: ba, bodyB: bb, anchor: anchor)
            j.shouldEnableLimits = true
            j.lowerAngleLimit = -limit
            j.upperAngleLimit =  limit
            physicsWorld.add(j)
        }
        pin(torso, head,    anchor: CGPoint(x: base.x + 1, y: base.y + 20), limit: 0.9)
        pin(torso, nearLeg, anchor: CGPoint(x: base.x + 4, y: base.y - 18), limit: 1.7)
        pin(torso, farLeg,  anchor: CGPoint(x: base.x - 4, y: base.y - 18), limit: 1.7)
        pin(torso, arm,     anchor: CGPoint(x: base.x + 7, y: base.y + 15), limit: 2.3)
    }

    private func showFlipBonus() {
        let l = hudLabel("FLIP +10", sz: 26, bold: true)
        l.fontColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        l.position  = CGPoint(x: 0, y: 70)
        l.zPosition = Z.hud
        l.setScale(0.4)
        screenNode.addChild(l)
        let pop = SKAction.group([.scale(to: 1.0, duration: 0.15)])
        pop.timingMode = .easeOut
        l.run(.sequence([pop, .wait(forDuration: 0.6),
                         .group([.fadeOut(withDuration: 0.3),
                                 .moveBy(x: 0, y: 30, duration: 0.3)]),
                         .removeFromParent()]))
    }

    private func totalPoints() -> Int {
        let dist = max(0, bikeNode.position.x - startX) / 35
        return Int(dist / 10) + flipCount * 10
    }

    private func showCrashOverlay() {
        let dim = SKShapeNode(rect: CGRect(x: -size.width / 2, y: -size.height / 2,
                                           width: size.width, height: size.height))
        dim.fillColor = SKColor(white: 0, alpha: 0.35); dim.strokeColor = .clear
        dim.zPosition = Z.hud + 1
        screenNode.addChild(dim)

        let cx = -size.width * 0.22           // crash stats on the left…

        let big = hudLabel(crashCause, sz: 44, bold: true)
        big.fontColor = SKColor(red: 1, green: 0.35, blue: 0.25, alpha: 1)
        big.position = CGPoint(x: cx, y: 48); big.zPosition = Z.hud + 2
        screenNode.addChild(big)

        let pts = hudLabel("\(totalPoints()) pts", sz: 32, bold: true)
        pts.fontColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        pts.position = CGPoint(x: cx, y: 4); pts.zPosition = Z.hud + 2
        screenNode.addChild(pts)

        let dist = max(0, bikeNode.position.x - startX) / 35
        let sub = hudLabel(String(format: "%.0f m  ·  %d flips", dist, flipCount),
                           sz: 18, bold: false)
        sub.position = CGPoint(x: cx, y: -28); sub.zPosition = Z.hud + 2
        screenNode.addChild(sub)

        let tap = hudLabel("Tap to restart", sz: 16, bold: false)
        tap.position = CGPoint(x: cx, y: -58); tap.zPosition = Z.hud + 2
        tap.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.6),
                                          .fadeAlpha(to: 1.0, duration: 0.6)])))
        screenNode.addChild(tap)
    }

    /// …and the leaderboard on the right. Called by the VC after name entry.
    func displayHighScores(highlightName: String? = nil, highlightScore: Int? = nil) {
        guard crashed else { return }   // leaderboard belongs to the wipeout screen only
        let entries = HighScoreStore.load()
        guard !entries.isEmpty else { return }
        let sx = size.width * 0.24

        let title = hudLabel("TOP RIDERS", sz: 18, bold: true)
        title.fontColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        title.position = CGPoint(x: sx, y: 56); title.zPosition = Z.hud + 2
        screenNode.addChild(title)

        for (i, e) in entries.enumerated() {
            let row = hudLabel("\(i + 1).  \(e.name)   \(e.score)", sz: 16, bold: true)
            let isNew = e.name == highlightName && e.score == highlightScore
            row.fontColor = isNew ? SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
                                  : SKColor(white: 0.92, alpha: 1)
            row.position = CGPoint(x: sx, y: 28 - CGFloat(i) * 26)
            row.zPosition = Z.hud + 2
            screenNode.addChild(row)
        }
    }

    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.42, green: 0.75, blue: 0.95, alpha: 1)
        // -11 m/s² (SpriteKit meters = 150pt): heavy enough to feel weighty,
        // light enough that crests give a satisfying launch.
        // Saturn runs lighter — long floaty hangs off every crater rim.
        physicsWorld.gravity = CGVector(dx: 0, dy: level == .space ? -6.5 : -11)
        physicsWorld.contactDelegate = self

        setupCamera()
        setupBackground()
        buildTerrain(to: size.width * 5)
        setupBike()
        setupHUD()
        setupMonster()

        startX = bikeNode.position.x
        snapCamera()

        // Warm up the Taptic Engine so the first haptic isn't late
        landingHaptic.prepare()
        crashHaptic.prepare()
    }

    private func setupCamera() {
        camNode = SKCameraNode()
        addChild(camNode)
        camera = camNode
        // Everything screen-fixed (HUD, sky, parallax) lives here; it counter-
        // scales against the camera zoom so it stays constant on screen.
        screenNode = SKNode()
        camNode.addChild(screenNode)
    }

    private func snapCamera() {
        camNode.position = CGPoint(x: bikeNode.position.x + size.width * 0.15,
                                   y: bikeNode.position.y + 130)
    }

    // MARK: Background
    /// 1×256 vertical gradient texture (top color → bottom color).
    private func gradientTexture(top: SKColor, bottom: SKColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 256))
        let img = renderer.image { ctx in
            let grad = CGGradient(colorsSpace: nil,
                                  colors: [top.cgColor, bottom.cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(grad, start: .zero,
                                             end: CGPoint(x: 0, y: 256), options: [])
        }
        return SKTexture(image: img)
    }

    /// Creates a camera-attached parallax layer. Content added to the returned
    /// node should span [0, L) horizontally; it gets wrapped as the camera moves.
    private func addBGLayer(f: CGFloat, fy: CGFloat, L: CGFloat,
                            z: CGFloat, drift: CGFloat = 0) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -camYRef)
        container.zPosition = z
        screenNode.addChild(container)
        let content = SKNode()
        container.addChild(content)
        bgLayers.append(BGLayer(content: content, container: container,
                                f: f, fy: fy, L: L, drift: drift))
        return content
    }

    /// Adds three copies of a content builder's output at -L, 0, +L so the
    /// layer tiles seamlessly when it wraps.
    private func tile(_ node: SKNode, into layer: SKNode, L: CGFloat) {
        for k in -1...1 {
            let c = node.copy() as! SKNode
            c.position.x = CGFloat(k) * L
            layer.addChild(c)
        }
    }

    private func setupBackground() {
        // Reference camera height (bike spawn + camera offset) so layers sit
        // exactly where they would in world space at the start.
        camYRef = size.height * 0.28 + rearR + 4 + 130
        backgroundColor = theme.skyBottom

        // Sky: glued to the camera — can never run out or show seams
        let sky = SKSpriteNode(texture: gradientTexture(
            top: theme.skyTop, bottom: theme.skyBottom))
        sky.size = CGSize(width: size.width * 1.1, height: size.height * 1.5)
        sky.zPosition = Z.bgSky
        screenNode.addChild(sky)

        if level == .space {
            // No clouds in a vacuum — stars and the rings overhead instead
            setupSpaceBackdrop()
        } else {
            // Clouds: texture sprites, slow constant drift + tiny parallax
            let cloudL: CGFloat = 2400
            let cloudLayer = addBGLayer(f: 0.06, fy: 0.03, L: cloudL,
                                        z: Z.bgSky + 0.5, drift: 7)
            let ctex = cloudTexture()
            let cloudSet = SKNode()
            for i in 0..<4 {
                let s = SKSpriteNode(texture: ctex)
                s.position = CGPoint(x: CGFloat(i) * cloudL / 4 + CGFloat.random(in: 0...(cloudL / 8)),
                                     y: size.height * CGFloat.random(in: 0.62...0.95))
                s.setScale(CGFloat.random(in: 0.55...1.05))
                s.alpha = CGFloat.random(in: theme.cloudAlpha)
                cloudSet.addChild(s)
            }
            tile(cloudSet, into: cloudLayer, L: cloudL)
        }

        // Mountain bands back-to-front: hazier + lighter = further away.
        // Sine-based bands are inherently periodic, so build them 3L wide directly.
        let farL: CGFloat = 2800
        let farLayer = addBGLayer(f: 0.12, fy: 0.06, L: farL, z: Z.bgHills)
        farLayer.addChild(hillBand(yBase: size.height * 0.38, amp: 95, period: 1400,
            top: theme.farTop, bottom: theme.farBottom, from: -farL, to: farL * 2))

        let midL: CGFloat = 1600
        let midLayer = addBGLayer(f: 0.22, fy: 0.12, L: midL, z: Z.bgHills + 0.3)
        midLayer.addChild(hillBand(yBase: size.height * 0.31, amp: 70, period: 800,
            top: theme.midTop, bottom: theme.midBottom, from: -midL, to: midL * 2))

        let ftL: CGFloat = 1800
        let ftLayer = addBGLayer(f: 0.32, fy: 0.18, L: ftL, z: Z.bgHills + 0.45)
        tile(vegetationRow(yBase: size.height * 0.245, width: ftL, scale: 0.8,
                           color: theme.vegFar),
             into: ftLayer, L: ftL)

        let nearL: CGFloat = 1440
        let nearLayer = addBGLayer(f: 0.45, fy: 0.25, L: nearL, z: Z.bgHills + 0.6)
        nearLayer.addChild(hillBand(yBase: size.height * 0.21, amp: 45, period: 480,
            top: theme.nearTop, bottom: theme.nearBottom, from: -nearL, to: nearL * 2))

        let ntL: CGFloat = 1600
        let ntLayer = addBGLayer(f: 0.60, fy: 0.32, L: ntL, z: Z.bgHills + 0.8)
        tile(vegetationRow(yBase: size.height * 0.165, width: ntL, scale: 1.15,
                           color: theme.vegNear),
             into: ntLayer, L: ntL)
    }

    private func vegetationRow(yBase: CGFloat, width: CGFloat, scale: CGFloat,
                               color: SKColor) -> SKNode {
        switch level {
        case .mountain: return treeRow(yBase: yBase, width: width, scale: scale, foliage: color)
        case .desert:   return cactusRow(yBase: yBase, width: width, scale: scale, body: color)
        case .water:    return buoyRow(yBase: yBase, width: width, scale: scale, body: color)
        case .space:    return boulderRow(yBase: yBase, width: width, scale: scale, body: color)
        case .jungle:   return canopyRow(yBase: yBase, width: width, scale: scale, foliage: color)
        }
    }

    /// Stars glued to the camera plus the rings arcing across the sky —
    /// you're standing ON the ringed planet, so they tower overhead.
    private func setupSpaceBackdrop() {
        // Starfield: one batched path of tiny dots
        let stars = CGMutablePath()
        for _ in 0..<70 {
            let r = CGFloat.random(in: 0.8...2.2)
            let x = CGFloat.random(in: -size.width * 0.6 ... size.width * 0.6)
            let y = CGFloat.random(in: -size.height * 0.2 ... size.height * 0.75)
            stars.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        let starNode = SKShapeNode(path: stars)
        starNode.fillColor = SKColor(white: 0.95, alpha: 0.9)
        starNode.strokeColor = .clear
        starNode.zPosition = Z.bgSky + 0.2
        screenNode.addChild(starNode)

        // The rings: vast concentric ellipse strokes rising from the horizon.
        // Centered far below the screen so only their top arcs are visible.
        let ringCenter = CGPoint(x: size.width * 0.1, y: -size.height * 2.6)
        let ringSpecs: [(rx: CGFloat, ry: CGFloat, w: CGFloat, a: CGFloat)] = [
            (size.width * 1.30, size.height * 3.15, 30, 0.30),
            (size.width * 1.38, size.height * 3.32, 16, 0.45),
            (size.width * 1.46, size.height * 3.48, 22, 0.25),
            (size.width * 1.54, size.height * 3.62, 10, 0.40),
        ]
        for spec in ringSpecs {
            let ring = SKShapeNode(ellipseOf: CGSize(width: spec.rx * 2, height: spec.ry * 2))
            ring.position = ringCenter
            ring.strokeColor = SKColor(red: 0.88, green: 0.82, blue: 0.66, alpha: spec.a)
            ring.lineWidth = spec.w
            ring.fillColor = .clear
            ring.zRotation = 0.10          // gentle tilt across the sky
            ring.zPosition = Z.bgSky + 0.3
            screenNode.addChild(ring)
        }
        // A distant moon
        let moon = SKShapeNode(circleOfRadius: 14)
        moon.fillColor = SKColor(red: 0.80, green: 0.78, blue: 0.72, alpha: 0.9)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: size.width * 0.30, y: size.height * 0.30)
        moon.zPosition = Z.bgSky + 0.25
        screenNode.addChild(moon)
    }

    /// Scattered lumpy boulders on the regolith horizon.
    private func boulderRow(yBase: CGFloat, width: CGFloat, scale: CGFloat,
                            body: SKColor) -> SKNode {
        let row = SKNode()
        let path = CGMutablePath()
        var x = CGFloat.random(in: 60...300)
        while x < width - 40 {
            let s = scale * CGFloat.random(in: 0.7...1.3)
            let y = yBase + CGFloat.random(in: -4...4)
            // Lumpy silhouette: a fat base ellipse with a smaller one offset on top
            path.addEllipse(in: CGRect(x: x - 14 * s, y: y, width: 28 * s, height: 14 * s))
            path.addEllipse(in: CGRect(x: x - 7 * s, y: y + 6 * s, width: 15 * s, height: 10 * s))
            x += CGFloat.random(in: 260...640)
        }
        let n = SKShapeNode(path: path)
        n.fillColor = body; n.strokeColor = .clear
        row.addChild(n)
        return row
    }

    /// Broadleaf jungle canopy: trunks with stacked leaf blobs, dense spacing.
    private func canopyRow(yBase: CGFloat, width: CGFloat, scale: CGFloat,
                           foliage: SKColor) -> SKNode {
        let row = SKNode()
        let leafPath  = CGMutablePath()
        let trunkPath = CGMutablePath()
        var x = CGFloat.random(in: 20...120)
        while x < width - 30 {
            let s = scale * CGFloat.random(in: 0.75...1.35)
            let y = yBase + CGFloat.random(in: -6...6)
            let h: CGFloat = 30 * s
            trunkPath.addRect(CGRect(x: x - 2.5 * s, y: y - 6 * s, width: 5 * s, height: h * 0.6))
            // Rounded canopy: three overlapping blobs
            leafPath.addEllipse(in: CGRect(x: x - 16 * s, y: y + h * 0.30,
                                           width: 32 * s, height: 20 * s))
            leafPath.addEllipse(in: CGRect(x: x - 11 * s, y: y + h * 0.55,
                                           width: 22 * s, height: 16 * s))
            leafPath.addEllipse(in: CGRect(x: x - 8 * s, y: y + h * 0.15,
                                           width: 26 * s, height: 15 * s))
            x += CGFloat.random(in: 90...260)      // jungle is DENSE
        }
        let trunks = SKShapeNode(path: trunkPath)
        trunks.fillColor = SKColor(red: 0.30, green: 0.20, blue: 0.11, alpha: 1)
        trunks.strokeColor = .clear
        row.addChild(trunks)
        let leaves = SKShapeNode(path: leafPath)
        leaves.fillColor = foliage; leaves.strokeColor = .clear
        row.addChild(leaves)
        return row
    }

    /// Sparse red-and-white buoys bobbing on the horizon.
    private func buoyRow(yBase: CGFloat, width: CGFloat, scale: CGFloat,
                         body: SKColor) -> SKNode {
        let row = SKNode()
        let whitePath = CGMutablePath()
        let redPath   = CGMutablePath()
        var x = CGFloat.random(in: 100...400)
        while x < width - 60 {
            let r = 8 * scale * CGFloat.random(in: 0.8...1.2)
            let y = yBase + CGFloat.random(in: -4...4)
            whitePath.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            // red top cap
            redPath.move(to: CGPoint(x: x - r, y: y))
            redPath.addArc(center: CGPoint(x: x, y: y), radius: r,
                           startAngle: .pi, endAngle: 0, clockwise: true)
            redPath.closeSubpath()
            // little mast tip
            redPath.addRect(CGRect(x: x - 1.2 * scale, y: y + r, width: 2.4 * scale, height: 6 * scale))
            x += CGFloat.random(in: 420...900)
        }
        let white = SKShapeNode(path: whitePath)
        white.fillColor = SKColor(white: 0.96, alpha: 1); white.strokeColor = .clear
        row.addChild(white)
        let red = SKShapeNode(path: redPath)
        red.fillColor = body; red.strokeColor = .clear
        row.addChild(red)
        return row
    }

    /// Saguaro cacti: tall trunk + two arms, batched into one shape node.
    private func cactusRow(yBase: CGFloat, width: CGFloat, scale: CGFloat,
                           body: SKColor) -> SKNode {
        let row = SKNode()
        let path = CGMutablePath()
        var x = CGFloat.random(in: 40...260)
        while x < width - 40 {
            let s = scale * CGFloat.random(in: 0.7...1.25)
            let y = yBase + CGFloat.random(in: -5...5)
            let h = 40 * s
            // trunk
            path.addRoundedRect(in: CGRect(x: x - 4 * s, y: y, width: 8 * s, height: h),
                                cornerWidth: 4 * s, cornerHeight: 4 * s)
            // left arm: out + up
            path.addRoundedRect(in: CGRect(x: x - 13 * s, y: y + h * 0.35,
                                           width: 10 * s, height: 4.5 * s),
                                cornerWidth: 2 * s, cornerHeight: 2 * s)
            path.addRoundedRect(in: CGRect(x: x - 13 * s, y: y + h * 0.35,
                                           width: 4.5 * s, height: h * 0.35),
                                cornerWidth: 2 * s, cornerHeight: 2 * s)
            // right arm, a bit higher
            path.addRoundedRect(in: CGRect(x: x + 3 * s, y: y + h * 0.55,
                                           width: 10 * s, height: 4.5 * s),
                                cornerWidth: 2 * s, cornerHeight: 2 * s)
            path.addRoundedRect(in: CGRect(x: x + 8.5 * s, y: y + h * 0.55,
                                           width: 4.5 * s, height: h * 0.30),
                                cornerWidth: 2 * s, cornerHeight: 2 * s)
            x += CGFloat.random(in: 200...560)
        }
        let n = SKShapeNode(path: path)
        n.fillColor = body; n.strokeColor = .clear
        row.addChild(n)
        return row
    }

    private func hillBand(yBase: CGFloat, amp: CGFloat, period: CGFloat,
                          top: SKColor, bottom: SKColor,
                          from: CGFloat, to: CGFloat) -> SKShapeNode {
        var pts = [CGPoint]()
        let n = max(2, Int((to - from) / 20))
        for i in 0...n {
            let x = from + (to - from) * CGFloat(i) / CGFloat(n)
            pts.append(CGPoint(x: x, y: yBase + amp * sin(x / period * .pi * 2)))
        }
        pts.append(CGPoint(x: to, y: -300)); pts.append(CGPoint(x: from, y: -300))
        let path = CGMutablePath(); path.addLines(between: pts); path.closeSubpath()
        let s = SKShapeNode(path: path)
        s.fillColor   = .white                       // white so fillTexture shows true
        s.fillTexture = gradientTexture(top: top, bottom: bottom)
        s.strokeColor = .clear
        return s
    }

    /// A row of simple pine trees batched into two shape nodes (foliage + trunks).
    private func treeRow(yBase: CGFloat, width: CGFloat, scale: CGFloat,
                         foliage: SKColor) -> SKNode {
        let row = SKNode()
        let leafPath  = CGMutablePath()
        let trunkPath = CGMutablePath()
        var x = CGFloat.random(in: 30...150)
        while x < width - 30 {
            let s = scale * CGFloat.random(in: 0.75...1.3)
            let y = yBase + CGFloat.random(in: -6...6)
            let w: CGFloat = 13 * s
            let h: CGFloat = 36 * s
            trunkPath.addRect(CGRect(x: x - 2 * s, y: y - 7 * s, width: 4 * s, height: 11 * s))
            // two stacked triangles
            leafPath.move(to: CGPoint(x: x - w, y: y))
            leafPath.addLine(to: CGPoint(x: x + w, y: y))
            leafPath.addLine(to: CGPoint(x: x, y: y + h * 0.62))
            leafPath.closeSubpath()
            leafPath.move(to: CGPoint(x: x - w * 0.78, y: y + h * 0.33))
            leafPath.addLine(to: CGPoint(x: x + w * 0.78, y: y + h * 0.33))
            leafPath.addLine(to: CGPoint(x: x, y: y + h))
            leafPath.closeSubpath()
            x += CGFloat.random(in: 130...420)
        }
        let trunks = SKShapeNode(path: trunkPath)
        trunks.fillColor = SKColor(red: 0.38, green: 0.26, blue: 0.15, alpha: 1)
        trunks.strokeColor = .clear
        row.addChild(trunks)
        let leaves = SKShapeNode(path: leafPath)
        leaves.fillColor = foliage; leaves.strokeColor = .clear
        row.addChild(leaves)
        return row
    }

    /// Cloud blob rendered once into a texture (rasterizing merges the circles
    /// properly — shape-node paths XOR overlapping fills).
    private func cloudTexture() -> SKTexture {
        let sz = CGSize(width: 160, height: 96)
        let renderer = UIGraphicsImageRenderer(size: sz)
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            for (dx, dy, r): (CGFloat, CGFloat, CGFloat) in
                [(0,0,34),(30,6,24),(-30,6,22),(52,-4,17),(-52,-4,16)] {
                ctx.cgContext.fillEllipse(in: CGRect(x: 80 + dx - r, y: 46 - dy - r,
                                                     width: r * 2, height: r * 2))
            }
        }
        return SKTexture(image: img)
    }

    // MARK: Terrain
    private func buildTerrain(to maxX: CGFloat) {
        // Flat runway at the start so you can build speed before the hills
        let runwayEnd: CGFloat = 900
        if terrainPoints.isEmpty {
            terrainPoints = [
                CGPoint(x: -200, y: size.height * 0.28),
                CGPoint(x:    0, y: size.height * 0.28),
                CGPoint(x:  450, y: size.height * 0.28),
                CGPoint(x: runwayEnd, y: size.height * 0.28),
            ]
            generatedUpTo = runwayEnd
        }
        // Water: schedule wave features ahead of the generation front.
        // Size distribution matures with distance: all small at first, big
        // ones mixing in, then the occasional whopper.
        if level == .water {
            while nextWaveX < maxX + 900 {
                let p = ((nextWaveX - 1800) / 20000).clamped(to: 0...1)
                let wSmall = 1.00 - 0.55 * p
                let wBig   = 0.05 + 0.40 * p
                let wWhop  = 0.15 * p
                let roll = CGFloat.random(in: 0...(wSmall + wBig + wWhop))
                let h: CGFloat, len: CGFloat
                if roll < wSmall {
                    h = .random(in: 30...55);   len = .random(in: 320...440)
                } else if roll < wSmall + wBig {
                    h = .random(in: 70...110);  len = .random(in: 450...620)
                } else {                        // the whopper
                    h = .random(in: 130...180); len = .random(in: 650...900)
                }
                waterWaves.append((x0: nextWaveX, len: len, h: h))
                nextWaveX += len + CGFloat.random(in: 500...1100)
            }
        }
        // Space: schedule craters ahead of the generation front
        if level == .space {
            while nextCraterX < maxX + 900 {
                let len = CGFloat.random(in: 420...780)
                craters.append((x0: nextCraterX, len: len,
                                rimH: .random(in: 26...48),
                                depth: .random(in: 40...95)))
                nextCraterX += len + CGFloat.random(in: 400...900)
            }
        }

        while generatedUpTo < maxX {
            let last = terrainPoints.last!
            let gx = generatedUpTo + segLen
            // Hills fade in gradually over the first stretch past the runway
            let ramp = ((generatedUpTo - runwayEnd) / 1500).clamped(to: 0...1)
            var ny = last.y
            switch level {
            case .mountain:                       // rolling hills, gentler chop
                ny += CGFloat.random(in: -4...4) * ramp
                ny += sin(generatedUpTo / 430) * 24 * ramp
                ny += sin(generatedUpTo / 170) * 8 * ramp
                ny = ny.clamped(to: size.height * 0.12 ... size.height * 0.50)
            case .desert:                         // long sweeping dunes = big jumps
                ny += CGFloat.random(in: -5...5) * ramp
                ny += sin(generatedUpTo / 540) * 30 * ramp
                ny += sin(generatedUpTo / 200) * 9 * ramp
                ny = ny.clamped(to: size.height * 0.12 ... size.height * 0.50)
            case .jungle:                         // choppy root-tangled floor
                ny += CGFloat.random(in: -6...6) * ramp
                ny += sin(generatedUpTo / 380) * 22 * ramp
                ny += sin(generatedUpTo / 140) * 10 * ramp
                ny = ny.clamped(to: size.height * 0.12 ... size.height * 0.50)
            case .space:
                // Absolute height: gentle regolith swells + scheduled craters.
                // Each crater is a bowl between two raised rims — dive in,
                // launch off the far rim, hang forever in the low gravity.
                var y = size.height * 0.28
                y += (sin(gx / 520) * 22 + sin(gx / 190) * 7) * ramp
                for c in craters where gx >= c.x0 && gx <= c.x0 + c.len {
                    let t = (gx - c.x0) / c.len
                    let rims = exp(-pow((t - 0.10) / 0.07, 2))
                             + exp(-pow((t - 0.90) / 0.07, 2))
                    y += c.rimH * rims * ramp
                    if t > 0.16 && t < 0.84 {
                        let u = (t - 0.16) / 0.68
                        y -= c.depth * sin(u * .pi) * ramp
                    }
                }
                ny = y.clamped(to: size.height * 0.08 ... size.height * 0.60)
            case .water:
                // Absolute height: smooth swell humps + scheduled wave jumps.
                // (No clamp-flattening — crests stay rounded.)
                var y = size.height * 0.28
                y += (sin(gx / 640) * 26 + sin(gx / 270) * 9) * ramp
                for w in waterWaves where gx >= w.x0 && gx <= w.x0 + w.len {
                    let t = (gx - w.x0) / w.len
                    let rise: CGFloat
                    if t < 0.32 {
                        let u = t / 0.32                    // steep face curling up — the kicker
                        rise = pow(u, 1.6)
                    } else {
                        let u = (t - 0.32) / 0.68           // long smooth back = landing ramp
                        rise = 1 - (3 * u * u - 2 * u * u * u)
                    }
                    y += w.h * rise * ramp
                }
                // High ceiling — whopper crests must never clamp-flatten
                ny = y.clamped(to: size.height * 0.10 ... size.height * 0.88)
            }
            terrainPoints.append(CGPoint(x: gx, y: ny))
            generatedUpTo += segLen
        }
        // Drop points far behind the camera so the mesh rebuild stays cheap
        let keepFrom = generatedUpTo - size.width * 8
        if terrainPoints.first!.x < keepFrom {
            terrainPoints = Array(terrainPoints.drop { $0.x < keepFrom })
            waterWaves.removeAll { $0.x0 + $0.len < keepFrom }
            craters.removeAll { $0.x0 + $0.len < keepFrom }
        }
        rebuildTerrainMesh()
    }

    // MARK: Terrain textures
    // Placeholder art generated in code. To use real assets later, replace
    // these with SKTexture(imageNamed:) — everything else stays the same.
    // dirtTex must tile seamlessly; edgeTex tiles horizontally as a strip.
    private lazy var dirtTex: SKTexture = makeDirtTexture()
    private lazy var edgeTex: SKTexture = makeEdgeTexture()

    private func darker(_ c: SKColor, _ f: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: min(1, r * f), green: min(1, g * f),
                       blue: min(1, b * f), alpha: a)
    }

    /// 256×256 tiling dirt: base color with soft blotches and dark specks.
    /// Features stay away from the edges so the tile repeats seamlessly.
    private func makeDirtTexture() -> SKTexture {
        let S: CGFloat = 256
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: S, height: S))
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            // Water: lighter base — the translucent front overlay adds the
            // depth back, so the combined tone matches the theme color.
            (level == .water ? darker(theme.dirt, 1.35) : theme.dirt).setFill()
            c.fill(CGRect(x: 0, y: 0, width: S, height: S))
            // Draw every feature 9× (wrapped ±S) so the tile is truly seamless —
            // features may cross edges and reappear on the opposite side.
            func wrapped(_ rect: CGRect) {
                for dx in [-S, 0, S] { for dy in [-S, 0, S] {
                    c.fillEllipse(in: rect.offsetBy(dx: dx, dy: dy))
                }}
            }
            if level == .water {
                for _ in 0..<22 {                               // horizontal shimmer bands
                    let r = CGFloat.random(in: 8...26)
                    let x = CGFloat.random(in: 0...S), y = CGFloat.random(in: 0...S)
                    let tint: UIColor = Bool.random() ? .white : .black
                    c.setFillColor(tint.withAlphaComponent(CGFloat.random(in: 0.03...0.07)).cgColor)
                    wrapped(CGRect(x: x - r * 1.6, y: y - r * 0.35,
                                   width: r * 3.2, height: r * 0.7))
                }
            } else {
                for _ in 0..<20 {                               // soft tonal blotches
                    let r = CGFloat.random(in: 10...28)
                    let x = CGFloat.random(in: 0...S), y = CGFloat.random(in: 0...S)
                    let tint: UIColor = Bool.random() ? .black : .white
                    c.setFillColor(tint.withAlphaComponent(CGFloat.random(in: 0.02...0.05)).cgColor)
                    wrapped(CGRect(x: x - r, y: y - r, width: r * 2, height: r * 1.3))
                }
                for _ in 0..<70 {                               // specks & pebbles
                    let r = CGFloat.random(in: 1.2...3.2)
                    let x = CGFloat.random(in: 0...S), y = CGFloat.random(in: 0...S)
                    c.setFillColor(UIColor.black.withAlphaComponent(CGFloat.random(in: 0.08...0.18)).cgColor)
                    wrapped(CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                }
            }
        }
        return SKTexture(image: img)
    }

    /// 128×30 horizontally-tiling surface strip: dark crust at the bottom,
    /// surface band, bright wavy lip, and (mountain) grass blades on top.
    private func makeEdgeTexture() -> SKTexture {
        let W: CGFloat = 128, H: CGFloat = 30
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: W, height: H))
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            darker(theme.dirt, 0.72).setFill()                  // crust
            c.fill(CGRect(x: 0, y: 20, width: W, height: 10))
            theme.surface.setFill()                             // surface band
            c.fill(CGRect(x: 0, y: 10, width: W, height: 12))

            // Wavy lip (whole sine periods so the strip tiles)
            let lip = CGMutablePath()
            lip.move(to: CGPoint(x: 0, y: 14))
            for i in 0...32 {
                let x = W * CGFloat(i) / 32
                lip.addLine(to: CGPoint(x: x, y: 8 + sin(x / W * .pi * 4) * 1.6))
            }
            lip.addLine(to: CGPoint(x: W, y: 14)); lip.closeSubpath()
            c.addPath(lip)
            theme.lip.setFill(); c.fillPath()

            switch level {
            case .mountain:                                     // grass blades poking up
                c.setStrokeColor(theme.tuft.cgColor)
                c.setLineWidth(1.8)
                c.setLineCap(.round)
                var x: CGFloat = 4
                while x < W - 4 {
                    let h = CGFloat.random(in: 3...7)
                    c.move(to: CGPoint(x: x, y: 10))
                    c.addLine(to: CGPoint(x: x + CGFloat.random(in: -1.5...1.5), y: 9 - h))
                    c.strokePath()
                    x += CGFloat.random(in: 5...11)
                }
            case .desert:                                       // scattered pebbles
                c.setFillColor(darker(theme.surface, 0.8).cgColor)
                var x: CGFloat = 6
                while x < W - 6 {
                    let r = CGFloat.random(in: 1.0...2.2)
                    c.fillEllipse(in: CGRect(x: x, y: CGFloat.random(in: 12...19),
                                             width: r * 2, height: r * 1.5))
                    x += CGFloat.random(in: 9...20)
                }
            case .water:                                        // foam bubbles on the lip
                c.setFillColor(UIColor.white.withAlphaComponent(0.85).cgColor)
                var x: CGFloat = 4
                while x < W - 4 {
                    let r = CGFloat.random(in: 1.2...2.8)
                    c.fillEllipse(in: CGRect(x: x, y: CGFloat.random(in: 4...10),
                                             width: r * 2, height: r * 2))
                    x += CGFloat.random(in: 6...14)
                }
            case .space:                                        // micro-crater pocks
                c.setFillColor(darker(theme.surface, 0.72).cgColor)
                var x: CGFloat = 6
                while x < W - 6 {
                    let r = CGFloat.random(in: 1.2...2.6)
                    c.fillEllipse(in: CGRect(x: x, y: CGFloat.random(in: 11...19),
                                             width: r * 2, height: r * 1.2))
                    x += CGFloat.random(in: 10...24)
                }
            case .jungle:                                       // thick grass thatch
                c.setStrokeColor(theme.tuft.cgColor)
                c.setLineWidth(1.8)
                c.setLineCap(.round)
                var x: CGFloat = 3
                while x < W - 3 {
                    let h = CGFloat.random(in: 4...9)
                    c.move(to: CGPoint(x: x, y: 10))
                    c.addLine(to: CGPoint(x: x + CGFloat.random(in: -2...2), y: 9 - h))
                    c.strokePath()
                    x += CGFloat.random(in: 3...8)
                }
            }
        }
        return SKTexture(image: img)
    }

    /// Deterministic pseudo-random in 0..<1 seeded by x — decorations stay
    /// put across mesh rebuilds instead of reshuffling.
    private func trand(_ x: CGFloat, _ salt: CGFloat) -> CGFloat {
        abs(sin(x * 0.12898 + salt * 78.233) * 43758.5453)
            .truncatingRemainder(dividingBy: 1)
    }

    private func rebuildTerrainMesh() {
        for n in terrainNodes { n.removeFromParent() }
        terrainNodes.removeAll()
        guard terrainPoints.count > 1 else { return }

        func addNode(_ path: CGPath, fill: SKColor, stroke: SKColor = .clear,
                     width: CGFloat = 0, z: CGFloat) -> SKShapeNode {
            let n = SKShapeNode(path: path)
            n.fillColor = fill; n.strokeColor = stroke; n.lineWidth = width
            n.zPosition = z
            addChild(n); terrainNodes.append(n)
            return n
        }

        let minX = terrainPoints.first!.x
        let maxX = terrainPoints.last!.x

        // --- Ground: tiling dirt clipped to the silhouette, in 512pt chunks ---
        // One giant crop mask exceeds the renderer's mask buffer and glitches
        // in and out; small chunks rasterize reliably. Tiles are world-aligned
        // so the pattern is seamless across chunks and stable across rebuilds.
        let tile: CGFloat = 256
        let chunkW: CGFloat = 512
        var cx = minX
        while cx < maxX {
            let cx2 = min(cx + chunkW, maxX)
            var pts: [CGPoint] = [CGPoint(x: cx, y: heightAt(x: cx))]
            for p in terrainPoints where p.x > cx && p.x < cx2 { pts.append(p) }
            pts.append(CGPoint(x: cx2, y: heightAt(x: cx2)))
            pts.append(CGPoint(x: cx2, y: -300)); pts.append(CGPoint(x: cx, y: -300))
            let mp = CGMutablePath(); mp.addLines(between: pts); mp.closeSubpath()

            let mask = SKShapeNode(path: mp)
            mask.fillColor = .white; mask.strokeColor = .clear
            let crop = SKCropNode()
            crop.maskNode = mask
            crop.zPosition = Z.terrain - 0.2
            var tx = floor(cx / tile) * tile
            while tx < cx2 {
                var ty: CGFloat = -300
                while ty < size.height * 0.55 {
                    let t = SKSpriteNode(texture: dirtTex)
                    t.anchorPoint = .zero
                    t.size = CGSize(width: tile, height: tile)
                    t.position = CGPoint(x: tx, y: ty)
                    crop.addChild(t)
                    ty += tile
                }
                tx += tile
            }
            addChild(crop); terrainNodes.append(crop)
            cx = cx2
        }

        // Physics: edge chain along the surface on an invisible node
        let physNode = SKNode()
        let pb = SKPhysicsBody(edgeChainFrom: terrainPoints.asPath())
        pb.friction         = 0.85
        pb.restitution      = 0.02
        pb.categoryBitMask    = PC.ground
        pb.collisionBitMask   = PC.chassis | PC.ragdoll
        pb.contactTestBitMask = PC.chassis
        physNode.physicsBody = pb
        addChild(physNode); terrainNodes.append(physNode)

        // --- Surface ribbon: textured strip hugging the terrain curve ---
        // Texture is mapped by WORLD x (128pt per repeat), so the pattern
        // flows continuously across segments instead of restarting each one.
        let ribbon = SKNode()
        ribbon.zPosition = Z.terrain + 0.05
        let texPeriod: CGFloat = 128
        func pmod(_ x: CGFloat, _ m: CGFloat) -> CGFloat {
            let r = x.truncatingRemainder(dividingBy: m); return r < 0 ? r + m : r
        }
        for i in 0..<terrainPoints.count - 1 {
            let a = terrainPoints[i], b = terrainPoints[i + 1]
            let xSpan = b.x - a.x
            guard xSpan > 0 else { continue }
            let ang = atan2(b.y - a.y, xSpan)
            let arcPerX = hypot(xSpan, b.y - a.y) / xSpan
            var wx = a.x
            while wx < b.x - 0.5 {
                let u = pmod(wx, texPeriod) / texPeriod
                let pieceX = min(b.x - wx, (1 - u) * texPeriod)
                if pieceX < 2 { wx += pieceX; continue }   // skip sliver at wrap
                let sub = SKTexture(rect: CGRect(x: u, y: 0,
                                                 width: pieceX / texPeriod, height: 1),
                                    in: edgeTex)
                let sp = SKSpriteNode(texture: sub)
                sp.size = CGSize(width: pieceX * arcPerX + 1.5, height: 30)
                sp.zRotation = ang
                let mx = wx + pieceX / 2
                let my = a.y + (mx - a.x) / xSpan * (b.y - a.y)
                // strip center sits 6pt below the surface: crust below, blades above
                sp.position = CGPoint(x: mx + sin(ang) * 6, y: my - cos(ang) * 6)
                ribbon.addChild(sp)
                wx += pieceX
            }
        }
        addChild(ribbon); terrainNodes.append(ribbon)

        // --- Water front: translucent layer IN FRONT of the vehicle ---
        // Anything below the surface line renders behind this, so the jetski
        // (and ragdoll) visually dip INTO the water instead of floating on top.
        if level == .water {
            var front = terrainPoints
            front.append(CGPoint(x: maxX, y: -300))
            front.append(CGPoint(x: minX, y: -300))
            let fp = CGMutablePath(); fp.addLines(between: front); fp.closeSubpath()
            let overlay = SKShapeNode(path: fp)
            overlay.fillColor = darker(theme.dirt, 0.9).withAlphaComponent(0.5)
            overlay.strokeColor = .clear
            overlay.zPosition = Z.bike + 0.55
            addChild(overlay); terrainNodes.append(overlay)
        }

        // --- Buried stones: occasional gray lumps ---
        let stonePath = CGMutablePath()
        for i in stride(from: 0, to: terrainPoints.count - 1, by: 4) {
            let a = terrainPoints[i]
            guard trand(a.x, 11) > 0.45 else { continue }
            let px    = a.x + trand(a.x, 12) * segLen * 3
            let depth = 26 + trand(a.x, 13) * 45
            let w     = 8 + trand(a.x, 14) * 8
            stonePath.addEllipse(in: CGRect(x: px - w/2, y: a.y - depth - w * 0.35,
                                            width: w, height: w * 0.7))
        }
        _ = addNode(stonePath, fill: theme.stone, z: Z.terrain - 0.1)

        // --- Grass tufts: little blade fans poking above the surface ---
        let tuftPath = CGMutablePath()
        for i in 0..<terrainPoints.count - 1 {
            let a = terrainPoints[i]
            guard trand(a.x, 21) > 0.42 else { continue }
            let bx = a.x + trand(a.x, 22) * segLen
            let by = heightAt(x: bx) - 1
            let h  = 6 + trand(a.x, 23) * 5
            for (dx, dy): (CGFloat, CGFloat) in [(-3.5, h * 0.75), (0, h), (3.5, h * 0.75)] {
                tuftPath.move(to: CGPoint(x: bx, y: by))
                tuftPath.addQuadCurve(to: CGPoint(x: bx + dx, y: by + dy),
                                      control: CGPoint(x: bx + dx * 0.2, y: by + dy * 0.6))
            }
        }
        _ = addNode(tuftPath, fill: .clear,
                    stroke: theme.tuft, width: 2, z: Z.terrain + 0.1)
    }

    // MARK: Bike setup
    private func setupBike() {
        let sy: CGFloat = size.height * 0.28 + rearR + 4
        let sx: CGFloat = 180

        // One physics body spanning both wheel contact points.
        // allowsRotation = false — it CANNOT flip, ever.
        bikeNode = SKNode()
        bikeNode.position = CGPoint(x: sx, y: sy)

        // Use two circle sub-bodies at wheel positions to get realistic terrain contact
        let rearBody  = SKPhysicsBody(circleOfRadius: rearR,
                                      center: CGPoint(x: -wheelbase/2, y: 0))
        let frontBody = SKPhysicsBody(circleOfRadius: frontR,
                                      center: CGPoint(x:  wheelbase/2, y: 0))
        let compound = SKPhysicsBody(bodies: [rearBody, frontBody])
        compound.mass               = 8.0
        // ZERO friction: the rigid "wheels" don't spin, so any friction at all
        // lets static friction pin the bike to the ground (gravity here is a
        // huge 4500 pt/s², so even μ=0.1 out-muscles the engine). The bike
        // "slides" on frictionless wheels; code supplies drive, brake, and
        // coasting resistance (linearDamping) instead.
        compound.friction           = 0.0
        compound.restitution        = 0.02
        compound.linearDamping      = spec.damping
        compound.angularDamping     = 0.8
        compound.allowsRotation     = true
        compound.categoryBitMask    = PC.chassis
        // Watercraft float via buoyancy forces instead of solid surface
        // collision, so they can sink into the water on landings.
        compound.collisionBitMask   = floating ? 0 : PC.ground
        compound.contactTestBitMask = PC.ground
        bikeNode.physicsBody = compound
        addChild(bikeNode)

        // Visual wheels / hover pads — children of bikeNode
        switch vehicle {
        case .classic:
            rearWheelVis  = makeWheelVisual(radius: rearR)
            frontWheelVis = makeWheelVisual(radius: frontR)
        case .buggy:
            rearWheelVis  = makeWheelVisual(radius: rearR)
            frontWheelVis = makeWheelVisual(radius: frontR)
        case .hover:
            rearWheelVis  = makeHoverPad(radius: rearR)
            frontWheelVis = makeHoverPad(radius: frontR)
        case .jetski, .fanboat:
            // No visible skids — just the hull riding the surface
            rearWheelVis  = SKNode()
            frontWheelVis = SKNode()
        }
        rearWheelVis.position  = CGPoint(x: -wheelbase/2, y: 0)
        frontWheelVis.position = CGPoint(x:  wheelbase/2, y: 0)
        bikeNode.addChild(rearWheelVis)
        bikeNode.addChild(frontWheelVis)

        // Visual chassis + rider — children of bikeNode
        chassisVis = SKNode()
        chassisVis.zPosition = Z.bike
        bikeNode.addChild(chassisVis)
        switch vehicle {
        case .classic: buildChassisVisual()
        case .hover:   buildHoverVisual()
        case .jetski:  buildJetskiVisual(); attachSpray()
        case .buggy:   buildBuggyVisual()
        case .fanboat:
            buildFanboatVisual()
            if level == .water { attachSpray() }
        }
    }

    /// Soft radial dot for water particles.
    private func makeSoftDotTexture() -> SKTexture {
        let S: CGFloat = 32
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: S, height: S))
        let img = renderer.image { ctx in
            let grad = CGGradient(colorsSpace: nil,
                                  colors: [UIColor.white.cgColor,
                                           UIColor.white.withAlphaComponent(0).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.cgContext.drawRadialGradient(
                grad,
                startCenter: CGPoint(x: S/2, y: S/2), startRadius: 0,
                endCenter: CGPoint(x: S/2, y: S/2), endRadius: S/2, options: [])
        }
        return SKTexture(image: img)
    }

    /// Wake spray kicked up behind the jetski. Intensity driven from update().
    private func attachSpray() {
        let e = SKEmitterNode()
        e.particleTexture = makeSoftDotTexture()
        e.particleBirthRate = 0                        // off until we're moving
        e.particleLifetime = 0.6; e.particleLifetimeRange = 0.3
        e.emissionAngle = .pi * 0.72                   // up and backward
        e.emissionAngleRange = 0.7
        e.particleSpeed = 150; e.particleSpeedRange = 80
        e.yAcceleration = -1300                        // spray falls back to the water
        e.particleAlpha = 0.85; e.particleAlphaSpeed = -1.3
        e.particleScale = 0.4; e.particleScaleRange = 0.25; e.particleScaleSpeed = 1.0
        e.particleColor = SKColor(red: 0.92, green: 0.97, blue: 1.0, alpha: 1)
        e.particleColorBlendFactor = 1
        // Particles render in their targetNode's z-context (the emitter's own
        // zPosition is ignored), so give them a dedicated layer that carries
        // the z — above the water-front overlay, below the HUD.
        let sprayLayer = SKNode()
        sprayLayer.zPosition = Z.bike + 0.8
        addChild(sprayLayer)
        e.targetNode = sprayLayer
        sprayLayer.addChild(e)
        sprayEmitter = e                               // position tracked in update()
    }

    /// Jetski body: white hull with red trim, pointed bow, steering column.
    private func buildJetskiVisual() {
        chassisVis.removeAllChildren()

        let hullWhite = SKColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
        let hullDark  = SKColor(red: 0.35, green: 0.42, blue: 0.52, alpha: 1)
        let accent    = SKColor(red: 0.85, green: 0.20, blue: 0.16, alpha: 1)

        // Hull: pointed bow, deep keel that actually sits in the water
        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: -48, y: -6))
        hullPath.addLine(to: CGPoint(x: -44, y: 8))
        hullPath.addLine(to: CGPoint(x: -14, y: 12))
        hullPath.addLine(to: CGPoint(x: 28, y: 11))
        hullPath.addLine(to: CGPoint(x: 58, y: 2))
        hullPath.addLine(to: CGPoint(x: 50, y: -12))
        hullPath.addLine(to: CGPoint(x: 10, y: -18))
        hullPath.addLine(to: CGPoint(x: -32, y: -16))
        hullPath.closeSubpath()
        let hull = SKShapeNode(path: hullPath)
        hull.fillColor = hullWhite; hull.strokeColor = hullDark; hull.lineWidth = 2
        chassisVis.addChild(hull)

        // Red side stripe sweeping toward the bow
        let stripePath = CGMutablePath()
        stripePath.move(to: CGPoint(x: -40, y: 2))
        stripePath.addQuadCurve(to: CGPoint(x: 52, y: 0), control: CGPoint(x: 8, y: 7))
        stripePath.addLine(to: CGPoint(x: 48, y: -5))
        stripePath.addQuadCurve(to: CGPoint(x: -41, y: -4), control: CGPoint(x: 6, y: 1))
        stripePath.closeSubpath()
        let stripe = SKShapeNode(path: stripePath)
        stripe.fillColor = accent; stripe.strokeColor = .clear
        chassisVis.addChild(stripe)

        // Saddle
        let seat = SKShapeNode(rect: CGRect(x: -32, y: 11, width: 32, height: 10), cornerRadius: 5)
        seat.fillColor = accent
        seat.strokeColor = SKColor(red: 0.55, green: 0.10, blue: 0.06, alpha: 1); seat.lineWidth = 1.5
        chassisVis.addChild(seat)

        // Steering column raked back toward the rider
        let colPath = CGMutablePath()
        colPath.move(to: CGPoint(x: 30, y: 9))
        colPath.addLine(to: CGPoint(x: 22, y: 37))
        colPath.addLine(to: CGPoint(x: 15, y: 39))
        let col = SKShapeNode(path: colPath)
        col.strokeColor = hullDark; col.lineWidth = 4.5; col.lineCap = .round
        chassisVis.addChild(col)

        // Bow deck vents
        for i in 0..<3 {
            let v = SKShapeNode(rect: CGRect(x: 34 + CGFloat(i) * 7, y: 4, width: 4, height: 2.5),
                                cornerRadius: 1)
            v.fillColor = hullDark; v.strokeColor = .clear
            chassisVis.addChild(v)
        }

        buildRider()
    }

    /// Hover pad: no wheel — a dark skid with a pulsing thruster glow beneath.
    /// Dune buggy: open tube-frame roll cage over a bright tub, engine out back.
    private func buildBuggyVisual() {
        let body      = SKColor(red: 0.95, green: 0.45, blue: 0.10, alpha: 1)
        let bodyDark  = SKColor(red: 0.62, green: 0.26, blue: 0.04, alpha: 1)
        let steel     = SKColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)
        let steelDark = SKColor(red: 0.25, green: 0.26, blue: 0.30, alpha: 1)

        // Low-slung tub between the wheels
        let tub = CGMutablePath()
        tub.move(to: CGPoint(x: -44, y: 4))
        tub.addLine(to: CGPoint(x: 44, y: 4))
        tub.addLine(to: CGPoint(x: 38, y: 26))
        tub.addLine(to: CGPoint(x: -36, y: 24))
        tub.closeSubpath()
        let tubNode = SKShapeNode(path: tub)
        tubNode.fillColor = body; tubNode.strokeColor = bodyDark; tubNode.lineWidth = 2.5
        chassisVis.addChild(tubNode)

        // Roll cage: pillars, top bar, rear brace
        let cage = CGMutablePath()
        cage.move(to: CGPoint(x: 18, y: 24));  cage.addLine(to: CGPoint(x: 8, y: 58))
        cage.addLine(to: CGPoint(x: -20, y: 58)); cage.addLine(to: CGPoint(x: -26, y: 22))
        cage.move(to: CGPoint(x: -20, y: 58)); cage.addLine(to: CGPoint(x: -38, y: 20))
        let cageNode = SKShapeNode(path: cage)
        cageNode.strokeColor = steel; cageNode.lineWidth = 5
        cageNode.lineCap = .round; cageNode.lineJoin = .round
        cageNode.fillColor = .clear
        cageNode.zPosition = 0.7                  // in front of the rider
        chassisVis.addChild(cageNode)

        // Bucket seat + rear engine block with upswept exhaust
        let seat = SKShapeNode(rect: CGRect(x: -28, y: 14, width: 16, height: 22),
                               cornerRadius: 5)
        seat.fillColor = SKColor(red: 0.16, green: 0.17, blue: 0.22, alpha: 1)
        seat.strokeColor = .clear
        chassisVis.addChild(seat)
        let engine = SKShapeNode(rect: CGRect(x: -46, y: 8, width: 16, height: 18),
                                 cornerRadius: 3)
        engine.fillColor = steel; engine.strokeColor = steelDark; engine.lineWidth = 2
        chassisVis.addChild(engine)
        let pipe = SKShapeNode(rect: CGRect(x: -52, y: 22, width: 6, height: 16),
                               cornerRadius: 3)
        pipe.fillColor = steelDark; pipe.strokeColor = .clear
        pipe.zRotation = 0.35
        chassisVis.addChild(pipe)

        // Fender arcs over both wheels
        for (wx, wr) in [(-wheelbase / 2, rearR), (wheelbase / 2, frontR)] {
            let fender = SKShapeNode(path: {
                let p = CGMutablePath()
                p.addArc(center: CGPoint(x: wx, y: 0), radius: wr + 6,
                         startAngle: 0.4, endAngle: .pi - 0.4, clockwise: false)
                return p
            }())
            fender.strokeColor = bodyDark; fender.lineWidth = 5
            fender.lineCap = .round; fender.fillColor = .clear
            chassisVis.addChild(fender)
        }

        // Front bumper bar + headlight
        let bumper = SKShapeNode(rect: CGRect(x: 44, y: 6, width: 7, height: 16),
                                 cornerRadius: 3.5)
        bumper.fillColor = steel; bumper.strokeColor = steelDark; bumper.lineWidth = 2
        chassisVis.addChild(bumper)
        let light = SKShapeNode(circleOfRadius: 5)
        light.fillColor = SKColor(red: 1, green: 0.93, blue: 0.55, alpha: 1)
        light.strokeColor = steelDark; light.lineWidth = 2
        light.position = CGPoint(x: 40, y: 30)
        chassisVis.addChild(light)

        buildRider()
    }

    /// Fan boat: flat aluminum hull, raised bench, big caged fan at the stern.
    private func buildFanboatVisual() {
        let alu      = SKColor(red: 0.72, green: 0.74, blue: 0.78, alpha: 1)
        let aluDark  = SKColor(red: 0.42, green: 0.44, blue: 0.50, alpha: 1)
        let accent   = SKColor(red: 0.10, green: 0.55, blue: 0.55, alpha: 1)
        let steelDark = SKColor(red: 0.25, green: 0.26, blue: 0.30, alpha: 1)

        // Flat-bottom hull with an upswept bow
        let hull = CGMutablePath()
        hull.move(to: CGPoint(x: -52, y: -14))
        hull.addLine(to: CGPoint(x: 40, y: -14))
        hull.addQuadCurve(to: CGPoint(x: 58, y: 6), control: CGPoint(x: 54, y: -10))
        hull.addLine(to: CGPoint(x: 52, y: 10))
        hull.addLine(to: CGPoint(x: -52, y: 10))
        hull.closeSubpath()
        let hullNode = SKShapeNode(path: hull)
        hullNode.fillColor = alu; hullNode.strokeColor = aluDark; hullNode.lineWidth = 2.5
        chassisVis.addChild(hullNode)
        // Waterline accent stripe
        let stripe = SKShapeNode(rect: CGRect(x: -50, y: -4, width: 96, height: 5),
                                 cornerRadius: 2.5)
        stripe.fillColor = accent; stripe.strokeColor = .clear
        chassisVis.addChild(stripe)

        // Raised driver bench
        let bench = SKShapeNode(rect: CGRect(x: -22, y: 10, width: 26, height: 12),
                                cornerRadius: 3)
        bench.fillColor = SKColor(red: 0.45, green: 0.22, blue: 0.12, alpha: 1)
        bench.strokeColor = .clear
        chassisVis.addChild(bench)

        // Fan cage on a stern mount
        let cageC = CGPoint(x: -38, y: 36)
        let cageR: CGFloat = 26
        let mount = SKShapeNode(rect: CGRect(x: cageC.x - 3, y: 10, width: 6, height: 18),
                                cornerRadius: 3)
        mount.fillColor = aluDark; mount.strokeColor = .clear
        chassisVis.addChild(mount)

        // Spinning blades behind the cage ribs
        let blades = SKNode()
        blades.position = cageC
        for k in 0..<3 {
            let blade = SKShapeNode(rect: CGRect(x: -3, y: 0, width: 6, height: cageR - 4),
                                    cornerRadius: 3)
            blade.fillColor = SKColor(white: 0.82, alpha: 1)
            blade.strokeColor = aluDark; blade.lineWidth = 1.5
            blade.zRotation = CGFloat(k) * (.pi * 2 / 3)
            blades.addChild(blade)
        }
        let hub = SKShapeNode(circleOfRadius: 4.5)
        hub.fillColor = steelDark; hub.strokeColor = .clear
        blades.addChild(hub)
        chassisVis.addChild(blades)
        fanBlades = blades

        // Cage ring + spokes in front of the blades
        let cage = SKNode()
        cage.position = cageC
        cage.zPosition = 0.1
        let ring = SKShapeNode(circleOfRadius: cageR)
        ring.strokeColor = steelDark; ring.lineWidth = 3.5; ring.fillColor = .clear
        cage.addChild(ring)
        for k in 0..<3 {
            let a = CGFloat(k) * .pi / 3 + .pi / 6
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -cos(a) * cageR, y: -sin(a) * cageR))
            p.addLine(to: CGPoint(x: cos(a) * cageR, y: sin(a) * cageR))
            let spoke = SKShapeNode(path: p)
            spoke.strokeColor = steelDark; spoke.lineWidth = 2
            cage.addChild(spoke)
        }
        chassisVis.addChild(cage)

        // Twin rudders aft of the fan
        for (dy, rot) in [(18, 0.15), (34, -0.1)] as [(CGFloat, CGFloat)] {
            let rudder = SKShapeNode(rect: CGRect(x: -3, y: -11, width: 6, height: 22),
                                     cornerRadius: 3)
            rudder.fillColor = accent; rudder.strokeColor = .clear
            rudder.position = CGPoint(x: -60, y: dy)
            rudder.zRotation = rot
            chassisVis.addChild(rudder)
        }

        buildRider()
    }

    private func makeHoverPad(radius: CGFloat) -> SKNode {
        let node = SKNode()
        node.zPosition = Z.bike

        let strut = SKShapeNode(rect: CGRect(x: -3, y: -6, width: 6, height: 12), cornerRadius: 2)
        strut.fillColor = SKColor(red: 0.24, green: 0.25, blue: 0.28, alpha: 1)
        strut.strokeColor = .clear
        node.addChild(strut)

        let pad = SKShapeNode(rect: CGRect(x: -radius * 0.95, y: -radius * 0.55 - 6,
                                           width: radius * 1.9, height: 12), cornerRadius: 6)
        pad.fillColor   = SKColor(red: 0.18, green: 0.20, blue: 0.24, alpha: 1)
        pad.strokeColor = SKColor(red: 0.45, green: 0.75, blue: 0.85, alpha: 1)
        pad.lineWidth   = 1.5
        node.addChild(pad)

        let glow = SKShapeNode(ellipseOf: CGSize(width: radius * 1.7, height: 8))
        glow.fillColor = SKColor(red: 0.35, green: 0.90, blue: 1.0, alpha: 0.6)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: -radius * 0.55 - 10)
        let dim  = SKAction.fadeAlpha(to: 0.30, duration: 0.35)
        let lite = SKAction.fadeAlpha(to: 0.75, duration: 0.35)
        dim.timingMode = .easeInEaseOut; lite.timingMode = .easeInEaseOut
        glow.run(.repeatForever(.sequence([dim, lite])))
        node.addChild(glow)
        return node
    }

    /// Sleek hover-bike body: teal hull, windshield, rear fin, under-glow.
    private func buildHoverVisual() {
        chassisVis.removeAllChildren()

        let hull     = SKColor(red: 0.16, green: 0.55, blue: 0.66, alpha: 1)
        let hullDark = SKColor(red: 0.07, green: 0.30, blue: 0.38, alpha: 1)
        let accent   = SKColor(red: 0.95, green: 0.55, blue: 0.20, alpha: 1)
        let cream    = SKColor(red: 0.96, green: 0.93, blue: 0.85, alpha: 1)

        // Under-glow strip
        let strip = SKShapeNode(rect: CGRect(x: -40, y: -13, width: 86, height: 5), cornerRadius: 2.5)
        strip.fillColor = SKColor(red: 0.35, green: 0.90, blue: 1.0, alpha: 0.55)
        strip.strokeColor = .clear
        chassisVis.addChild(strip)

        // Hull
        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: -52, y: 2))
        hullPath.addLine(to: CGPoint(x: -40, y: 16))
        hullPath.addLine(to: CGPoint(x:  10, y: 20))
        hullPath.addLine(to: CGPoint(x:  42, y: 16))
        hullPath.addLine(to: CGPoint(x:  56, y: 6))
        hullPath.addLine(to: CGPoint(x:  50, y: -6))
        hullPath.addLine(to: CGPoint(x:  20, y: -11))
        hullPath.addLine(to: CGPoint(x: -38, y: -9))
        hullPath.closeSubpath()
        let body = SKShapeNode(path: hullPath)
        body.fillColor = hull; body.strokeColor = hullDark; body.lineWidth = 2
        chassisVis.addChild(body)

        // Rear fin
        let finPath = CGMutablePath()
        finPath.move(to: CGPoint(x: -38, y: 10))
        finPath.addLine(to: CGPoint(x: -52, y: 28))
        finPath.addLine(to: CGPoint(x: -44, y: 8))
        finPath.closeSubpath()
        let fin = SKShapeNode(path: finPath)
        fin.fillColor = accent; fin.strokeColor = .clear
        chassisVis.addChild(fin)

        // Seat
        let seat = SKShapeNode(rect: CGRect(x: -30, y: 14, width: 26, height: 7), cornerRadius: 3.5)
        seat.fillColor = cream; seat.strokeColor = hullDark; seat.lineWidth = 1.5
        chassisVis.addChild(seat)

        // Windshield
        let shieldPath = CGMutablePath()
        shieldPath.move(to: CGPoint(x: 28, y: 18))
        shieldPath.addLine(to: CGPoint(x: 42, y: 18))
        shieldPath.addLine(to: CGPoint(x: 37, y: 32))
        shieldPath.closeSubpath()
        let shield = SKShapeNode(path: shieldPath)
        shield.fillColor = SKColor(red: 0.55, green: 0.85, blue: 0.98, alpha: 0.65)
        shield.strokeColor = .clear
        chassisVis.addChild(shield)

        // Handlebar reaching back toward the rider's glove
        let barPath = CGMutablePath()
        barPath.move(to: CGPoint(x: 32, y: 20))
        barPath.addLine(to: CGPoint(x: 25, y: 38))
        barPath.addLine(to: CGPoint(x: 17, y: 40))
        let bar = SKShapeNode(path: barPath)
        bar.strokeColor = hullDark; bar.lineWidth = 4; bar.lineCap = .round
        chassisVis.addChild(bar)

        // Headlight
        let hl = SKShapeNode(circleOfRadius: 5)
        hl.fillColor = SKColor(red: 0.75, green: 0.98, blue: 1.0, alpha: 1)
        hl.strokeColor = hullDark; hl.lineWidth = 1.5
        hl.position = CGPoint(x: 52, y: 4)
        chassisVis.addChild(hl)

        buildRider()
    }

    private func makeWheelVisual(radius: CGFloat) -> SKNode {
        let node = SKNode()
        node.zPosition = Z.bike

        let rubber = SKColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1)

        // Knobs: one path of lugs around the circumference (spins with the wheel)
        let knobPath = CGMutablePath()
        let knobCount = 14
        for i in 0..<knobCount {
            let a = CGFloat(i) / CGFloat(knobCount) * .pi * 2
            knobPath.addEllipse(in: CGRect(x: cos(a) * (radius - 0.5) - 3.2,
                                           y: sin(a) * (radius - 0.5) - 3.2,
                                           width: 6.4, height: 6.4))
        }
        let knobs = SKShapeNode(path: knobPath)
        knobs.fillColor = rubber; knobs.strokeColor = .clear
        node.addChild(knobs)

        // Tire body
        let tire = SKShapeNode(circleOfRadius: radius)
        tire.fillColor   = rubber
        tire.strokeColor = SKColor(white: 0.05, alpha: 1)
        tire.lineWidth   = 1.5
        node.addChild(tire)

        // Inner rim
        let rim = SKShapeNode(circleOfRadius: radius * 0.55)
        rim.fillColor   = SKColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1)
        rim.strokeColor = SKColor(white: 0.58, alpha: 1)
        rim.lineWidth   = 2.5
        node.addChild(rim)

        for i in 0..<6 {
            let a = CGFloat(i) * .pi / 3
            let sp = CGMutablePath()
            sp.move(to: .zero)
            sp.addLine(to: CGPoint(x: cos(a) * radius * 0.5, y: sin(a) * radius * 0.5))
            let s = SKShapeNode(path: sp)
            s.strokeColor = SKColor(white: 0.50, alpha: 1); s.lineWidth = 1.8
            node.addChild(s)
        }
        let hub = SKShapeNode(circleOfRadius: 4.5)
        hub.fillColor = SKColor(white: 0.70, alpha: 1); hub.strokeColor = .clear
        node.addChild(hub)
        return node
    }

    private func buildChassisVisual() {
        chassisVis.removeAllChildren()

        // Palette (from the retro reference bike)
        let orange     = SKColor(red: 0.86, green: 0.32, blue: 0.14, alpha: 1)
        let orangeDark = SKColor(red: 0.62, green: 0.20, blue: 0.08, alpha: 1)
        let steel      = SKColor(red: 0.42, green: 0.44, blue: 0.48, alpha: 1)
        let steelDark  = SKColor(red: 0.24, green: 0.25, blue: 0.28, alpha: 1)
        let cream      = SKColor(red: 0.96, green: 0.93, blue: 0.85, alpha: 1)

        func stroke(_ path: CGPath, _ color: SKColor, _ w: CGFloat) -> SKShapeNode {
            let s = SKShapeNode(path: path)
            s.strokeColor = color; s.lineWidth = w; s.lineCap = .round
            return s
        }
        func line(from a: CGPoint, to b: CGPoint) -> CGPath {
            let p = CGMutablePath(); p.move(to: a); p.addLine(to: b); return p
        }

        // --- Swingarm to rear hub + frame tube down to engine ---
        chassisVis.addChild(stroke(line(from: CGPoint(x: -43, y: 0), to: CGPoint(x: -8, y: 6)), steelDark, 5))
        chassisVis.addChild(stroke(line(from: CGPoint(x: -20, y: 16), to: CGPoint(x: -36, y: 0)), steelDark, 4))

        // --- Exhaust: low pipe sweeping back past the rear wheel ---
        let exhPath = CGMutablePath()
        exhPath.move(to: CGPoint(x: 8, y: -10))
        exhPath.addQuadCurve(to: CGPoint(x: -52, y: -14), control: CGPoint(x: -20, y: -20))
        let exh = stroke(exhPath, steel, 7)
        chassisVis.addChild(exh)
        let exhTip = SKShapeNode(circleOfRadius: 4.5)
        exhTip.fillColor = steelDark; exhTip.strokeColor = .clear
        exhTip.position = CGPoint(x: -52, y: -14)
        chassisVis.addChild(exhTip)

        // --- Engine block ---
        let eng = SKShapeNode(rect: CGRect(x: -12, y: -14, width: 26, height: 20), cornerRadius: 4)
        eng.fillColor = steelDark; eng.strokeColor = SKColor(white: 0.55, alpha: 1); eng.lineWidth = 1.5
        chassisVis.addChild(eng)
        // cooling fins
        for i in 0..<3 {
            let fin = SKShapeNode(rect: CGRect(x: -9 + CGFloat(i)*8, y: -12, width: 4, height: 8), cornerRadius: 1)
            fin.fillColor = SKColor(white: 0.45, alpha: 1); fin.strokeColor = .clear
            chassisVis.addChild(fin)
        }

        // --- Front fork: from headstock down to front hub ---
        chassisVis.addChild(stroke(line(from: CGPoint(x: 43, y: 0), to: CGPoint(x: 31, y: 30)), steel, 5))
        chassisVis.addChild(stroke(line(from: CGPoint(x: 47, y: 2), to: CGPoint(x: 35, y: 28)), steelDark, 3))

        // --- Frame tube: headstock back to seat area ---
        chassisVis.addChild(stroke(line(from: CGPoint(x: 30, y: 26), to: CGPoint(x: -6, y: 12)), orangeDark, 5))

        // --- Fuel tank: rounded, sits between seat and headstock ---
        let tankPath = CGMutablePath()
        tankPath.move(to: CGPoint(x: -2, y: 14))
        tankPath.addQuadCurve(to: CGPoint(x: 12, y: 27), control: CGPoint(x: 0, y: 26))
        tankPath.addQuadCurve(to: CGPoint(x: 30, y: 22), control: CGPoint(x: 25, y: 28))
        tankPath.addQuadCurve(to: CGPoint(x: 26, y: 12), control: CGPoint(x: 32, y: 13))
        tankPath.addQuadCurve(to: CGPoint(x: -2, y: 14), control: CGPoint(x: 12, y: 8))
        tankPath.closeSubpath()
        let tank = SKShapeNode(path: tankPath)
        tank.fillColor = orange; tank.strokeColor = orangeDark; tank.lineWidth = 2
        chassisVis.addChild(tank)
        // tank stripe
        let stripePath = CGMutablePath()
        stripePath.move(to: CGPoint(x: 2, y: 19))
        stripePath.addQuadCurve(to: CGPoint(x: 26, y: 18), control: CGPoint(x: 14, y: 22))
        let stripe = stroke(stripePath, cream, 3)
        chassisVis.addChild(stripe)

        // --- Seat: flat cream saddle behind the tank ---
        let seatPath = CGMutablePath()
        seatPath.move(to: CGPoint(x: -30, y: 16))
        seatPath.addQuadCurve(to: CGPoint(x: -4, y: 17), control: CGPoint(x: -17, y: 21))
        seatPath.addLine(to: CGPoint(x: -4, y: 12))
        seatPath.addQuadCurve(to: CGPoint(x: -30, y: 11), control: CGPoint(x: -17, y: 14))
        seatPath.closeSubpath()
        let seat = SKShapeNode(path: seatPath)
        seat.fillColor = cream; seat.strokeColor = steelDark; seat.lineWidth = 1.5
        chassisVis.addChild(seat)

        // --- Rear fender: short orange arc over the rear wheel ---
        let rfPath = CGMutablePath()
        rfPath.addArc(center: CGPoint(x: -43, y: 0), radius: rearR + 6,
                      startAngle: .pi * 0.25, endAngle: .pi * 0.72, clockwise: false)
        let rearFender = stroke(rfPath, orange, 5)
        chassisVis.addChild(rearFender)

        // --- Front fender over the front wheel ---
        let ffPath = CGMutablePath()
        ffPath.addArc(center: CGPoint(x: 43, y: 0), radius: frontR + 5,
                      startAngle: .pi * 0.22, endAngle: .pi * 0.80, clockwise: false)
        let frontFender = stroke(ffPath, orange, 5)
        chassisVis.addChild(frontFender)

        // --- Handlebars ---
        chassisVis.addChild(stroke(line(from: CGPoint(x: 31, y: 30), to: CGPoint(x: 27, y: 40)), steelDark, 3.5))
        chassisVis.addChild(stroke(line(from: CGPoint(x: 27, y: 40), to: CGPoint(x: 19, y: 41)), steelDark, 4.5))

        // --- Headlight on the headstock ---
        let hl = SKShapeNode(circleOfRadius: 6)
        hl.fillColor   = SKColor(red: 1, green: 0.93, blue: 0.55, alpha: 1)
        hl.strokeColor = steelDark; hl.lineWidth = 2
        hl.position    = CGPoint(x: 40, y: 26)
        chassisVis.addChild(hl)

        buildRider()
    }

    private func buildRider() {
        riderNode = SKNode()
        riderNode.zPosition = 0.5
        chassisVis.addChild(riderNode)

        let jacket     = SKColor(red: 0.82, green: 0.20, blue: 0.14, alpha: 1)
        let jacketDark = SKColor(red: 0.55, green: 0.10, blue: 0.06, alpha: 1)
        let pants      = SKColor(red: 0.20, green: 0.22, blue: 0.30, alpha: 1)
        let skin       = SKColor(red: 0.94, green: 0.76, blue: 0.62, alpha: 1)

        // Sits on the saddle (~x -17, y 17), leaning toward the bars.

        // --- Rear leg (far side, drawn first, slightly darker) ---
        let rearLegPath = CGMutablePath()
        rearLegPath.move(to: CGPoint(x: -15, y: 17))
        rearLegPath.addLine(to: CGPoint(x: -1, y: 2))      // knee forward
        rearLegPath.addLine(to: CGPoint(x: -6, y: -10))    // foot on peg
        let rearLeg = SKShapeNode(path: rearLegPath)
        rearLeg.strokeColor = SKColor(red: 0.13, green: 0.14, blue: 0.20, alpha: 1)
        rearLeg.lineWidth = 8.5; rearLeg.lineCap = .round; rearLeg.lineJoin = .round
        riderNode.addChild(rearLeg)

        // --- Near leg: hip → bent knee → foot peg ---
        let legPath = CGMutablePath()
        legPath.move(to: CGPoint(x: -17, y: 19))
        legPath.addLine(to: CGPoint(x: 2, y: 4))           // knee tucked by the tank
        legPath.addLine(to: CGPoint(x: -4, y: -9))         // foot on peg
        let leg = SKShapeNode(path: legPath)
        leg.strokeColor = pants
        leg.lineWidth = 9.5; leg.lineCap = .round; leg.lineJoin = .round
        riderNode.addChild(leg)

        // boot
        let boot = SKShapeNode(rect: CGRect(x: -9, y: -14, width: 16, height: 7), cornerRadius: 2.5)
        boot.fillColor = SKColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1); boot.strokeColor = .clear
        riderNode.addChild(boot)

        // --- Torso: leaning forward over the tank ---
        let torso = SKShapeNode(rect: CGRect(x: -9, y: -2, width: 18, height: 41), cornerRadius: 6)
        torso.fillColor = jacket; torso.strokeColor = jacketDark; torso.lineWidth = 1.5
        torso.position  = CGPoint(x: -13, y: 18)
        torso.zRotation = -0.35                            // forward lean
        riderNode.addChild(torso)

        // --- Arm: shoulder → elbow → grip ---
        let armPath = CGMutablePath()
        armPath.move(to: CGPoint(x: -2, y: 50))
        armPath.addLine(to: CGPoint(x: 11, y: 38))         // elbow out (motocross style)
        armPath.addLine(to: CGPoint(x: 22, y: 41))         // hand on the bars
        let arm = SKShapeNode(path: armPath)
        arm.strokeColor = jacket
        arm.lineWidth = 8; arm.lineCap = .round; arm.lineJoin = .round
        riderNode.addChild(arm)

        // glove
        let glove = SKShapeNode(circleOfRadius: 4.5)
        glove.fillColor = SKColor(white: 0.15, alpha: 1); glove.strokeColor = .clear
        glove.position = CGPoint(x: 22, y: 41)
        riderNode.addChild(glove)

        // --- Helmet: tipped forward, white stripe + visor ---
        let helm = SKShapeNode(ellipseOf: CGSize(width: 31, height: 28))
        helm.fillColor   = SKColor(red: 0.88, green: 0.12, blue: 0.12, alpha: 1)
        helm.strokeColor = SKColor(red: 0.50, green: 0.04, blue: 0.04, alpha: 1); helm.lineWidth = 1.5
        helm.position    = CGPoint(x: 3, y: 60)
        helm.zRotation   = -0.25
        riderNode.addChild(helm)

        let helmStripe = SKShapeNode(rect: CGRect(x: -3, y: -13, width: 6, height: 26), cornerRadius: 3)
        helmStripe.fillColor = SKColor(white: 0.95, alpha: 1); helmStripe.strokeColor = .clear
        helmStripe.position = CGPoint(x: 3, y: 60)
        helmStripe.zRotation = 0.9
        riderNode.addChild(helmStripe)

        // chin + visor
        let chin = SKShapeNode(rect: CGRect(x: 7, y: 51, width: 11, height: 6), cornerRadius: 2.5)
        chin.fillColor = skin; chin.strokeColor = .clear
        riderNode.addChild(chin)
        let visor = SKShapeNode(rect: CGRect(x: 6, y: 56, width: 14, height: 7), cornerRadius: 3)
        visor.fillColor = SKColor(red: 0.30, green: 0.55, blue: 0.90, alpha: 0.9)
        visor.strokeColor = .clear
        riderNode.addChild(visor)
    }

    // MARK: Monster
    private func setupMonster() {
        // Each level has its own horror looming just inside the left screen
        // edge at the start line
        let m: ChaseMonster
        switch level {
        case .desert:   m = DreadWyrm(screenHeight: size.height, startX: 180 - 260)
        case .mountain: m = GraveMaw(screenHeight: size.height, startX: 180 - 260)
        case .water:    m = Kraken(screenHeight: size.height, startX: 180 - 260)
        case .space:    m = VoidSpecter(screenHeight: size.height, startX: 180 - 260)
        case .jungle:   return   // its horror hasn't been dreamed up yet
        }
        m.zPosition = Z.terrain + 0.5     // in front of the ground, behind the bike
        addChild(m)
        monster = m

        // Flashing proximity warning, hidden until it gets close
        let warn = hudLabel(m.warningText, sz: 20, bold: true)
        warn.fontColor = SKColor(red: 1, green: 0.30, blue: 0.20, alpha: 1)
        warn.position = CGPoint(x: 0, y: -size.height * 0.30)
        warn.zPosition = Z.hud
        warn.isHidden = true
        warn.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: 0.35),
                                           .fadeAlpha(to: 1.00, duration: 0.35)])))
        screenNode.addChild(warn)
        monsterWarning = warn
    }

    private func showMonsterBanner() {
        guard let monster else { return }
        let l = hudLabel(monster.bannerText, sz: 24, bold: true)
        l.fontColor = SKColor(red: 1, green: 0.45, blue: 0.15, alpha: 1)
        l.position  = CGPoint(x: 0, y: 100)
        l.zPosition = Z.hud
        l.setScale(0.4)
        screenNode.addChild(l)
        let pop = SKAction.scale(to: 1.0, duration: 0.15)
        pop.timingMode = .easeOut
        l.run(.sequence([pop, .wait(forDuration: 1.8),
                         .group([.fadeOut(withDuration: 0.4),
                                 .moveBy(x: 0, y: 30, duration: 0.4)]),
                         .removeFromParent()]))
    }

    // MARK: HUD
    private func setupHUD() {
        distLabel = hudLabel("0 m", sz: 24, bold: true)
        distLabel.horizontalAlignmentMode = .left
        distLabel.position = CGPoint(x: -size.width/2 + 24, y: size.height/2 - 50)
        distLabel.zPosition = Z.hud
        screenNode.addChild(distLabel)

        pointsLabel = hudLabel("0 pts", sz: 24, bold: true)
        pointsLabel.horizontalAlignmentMode = .right
        pointsLabel.position = CGPoint(x: size.width/2 - 24, y: size.height/2 - 50)
        pointsLabel.zPosition = Z.hud
        screenNode.addChild(pointsLabel)

        speedLabel = hudLabel("0 km/h", sz: 18, bold: true)
        speedLabel.fontColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        speedLabel.position  = CGPoint(x: 0, y: -size.height/2 + 34); speedLabel.zPosition = Z.hud
        screenNode.addChild(speedLabel)

    }

    private func hudLabel(_ text: String, sz: CGFloat, bold: Bool) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: bold ? "AvenirNext-Bold" : "AvenirNext-Medium")
        l.fontSize = sz; l.fontColor = .white; l.text = text
        l.verticalAlignmentMode = .center
        return l
    }

    // MARK: - Contact
    func didBegin(_ contact: SKPhysicsContact) {
        // Measure impact force from relative velocity at contact point
        let velA = contact.bodyA.velocity
        let velB = contact.bodyB.velocity
        let relVelY = abs(velA.dy - velB.dy)
        // Only fire for meaningful impacts (landing, not just rolling)
        let intensity = Float((relVelY / 300).clamped(to: 0...1))
        if intensity > 0.08 {
            BikeAudio.shared.playImpact(intensity: intensity)
        }
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0.016 : min(currentTime - lastTime, 0.05)
        lastTime = currentTime

        guard let pb = bikeNode.physicsBody else { return }

        // Extend terrain ahead
        if generatedUpTo < camNode.position.x + size.width * 3 {
            buildTerrain(to: camNode.position.x + size.width * 5)
        }

        // --- Gas: drive the bike forward ---
        // The body is one rigid unit with high friction + angular damping, so
        // applyForce/torque get absorbed. Accelerate the horizontal velocity
        // directly for reliable, predictable motion; gravity + terrain still
        // handle jumps, climbs and falls (we never touch dy).
        // Grounded = rear wheel within a few points of the terrain surface.
        let groundSlope = terrainSlopeAt(x: bikeNode.position.x)
        let grounded = bikeNode.position.y - heightAt(x: bikeNode.position.x) < rearR + 10

        // --- Crash: rider's head meets the ground ---
        if !crashed {
            let a  = bikeNode.zRotation
            let hx = bikeNode.position.x - sin(a) * 55
            let hy = bikeNode.position.y + cos(a) * 55
            if hy < heightAt(x: hx) + 8 { crash() }
        }

        // --- Crest pop ---
        // The moment we leave the ground at speed under throttle, kick upward
        // proportional to speed. The gentle terrain slopes alone never give a
        // satisfying launch, so we amplify the physics at the transition.
        if wasGrounded && !grounded && gasActive
            && pb.velocity.dx > 250 && pb.velocity.dy > -50 {
            pb.velocity.dy += pb.velocity.dx * 0.42   // launch strength (tunable)
        }

        // --- Landing absorb: soak up vertical speed on touchdown (suspension) ---
        if !wasGrounded && grounded && pb.velocity.dy < 0 {
            suspVel += pb.velocity.dy * 0.18      // kick the visual suspension
            // Haptic tap scaled to how hard we hit
            let hit = min(1.0, abs(pb.velocity.dy) / 900)
            if hit > 0.15 && !crashed {
                landingHaptic.impactOccurred(intensity: hit)
                landingHaptic.prepare()
            }
            if !floating {
                pb.velocity.dy *= 0.35            // watercraft: the water absorbs instead
            }
        }
        wasGrounded = grounded

        // --- Water buoyancy (jetski / fan boat): float at a rest depth ---
        // No solid collision — the hull penetrates the surface, and an upward
        // force grows with depth (sharply past ~20pt so it can't fully submerge).
        // Bigger landings carry more speed in, so they dip deeper.
        if floating {
            let depth = heightAt(x: bikeNode.position.x) - (bikeNode.position.y - rearR)
            if depth > 0 {
                let restDepth: CGFloat = 8
                let gPts: CGFloat = 11 * 150           // matches physicsWorld.gravity
                let buoy = gPts * (depth / restDepth) * (1 + pow(depth / 20, 2))
                pb.velocity.dy += buoy * dt
                // Asymmetric drag: light going in (deep landing dips), heavy
                // coming up (rise once and settle — no cork-bobbing)
                let drag: CGFloat = pb.velocity.dy > 0 ? 10.0 : 3.0
                pb.velocity.dy -= pb.velocity.dy * min(drag * dt, 0.6)
                // Water levels the ski toward the swell surface
                let delta = groundSlope - bikeNode.zRotation
                bikeNode.zRotation += atan2(sin(delta), cos(delta)) * 0.08
                pb.angularVelocity *= 0.90
            }
            // Wake spray: kicks up with speed while the hull is in the water
            let inWater = depth > -4 && !crashed
            let speed = abs(pb.velocity.dx)
            sprayEmitter?.position = bikeNode.convert(CGPoint(x: -52, y: -16), to: self)
            sprayEmitter?.particleBirthRate = inWater && speed > 120
                ? min(speed * 0.4, 400) : 0
            sprayEmitter?.particleSpeed = 120 + speed * 0.15
        }

        // --- Flip counting: ~full airborne rotation = 10 pts ---
        // Accumulate per-frame rotation; a single flickering grounded frame
        // mid-flip must NOT reset progress, so require sustained contact.
        // zRotation wraps at ±π, so normalize the per-frame delta to the
        // shortest arc — otherwise the wrap injects a bogus ±2π jump that
        // cancels out the accumulated flip rotation.
        let dRotRaw = bikeNode.zRotation - lastZRot
        let dRot = atan2(sin(dRotRaw), cos(dRotRaw))
        lastZRot = bikeNode.zRotation
        if grounded {
            groundedFrames += 1
            if groundedFrames > 4 { flipProgress = 0 }
        } else {
            groundedFrames = 0
            if !crashed {
                flipProgress += dRot
                if abs(flipProgress) >= .pi * 1.8 {   // 90% of 360° — forgiving
                    flipCount += 1
                    flipProgress = 0
                    showFlipBonus()
                }
            }
        }

        // --- Air control: throttle pulls the nose up, brake dips it ---
        // This is how you save a bad landing (or throw a backflip).
        if !crashed && !grounded {
            let maxSpin: CGFloat = 4.0                // rad/s cap ≈ full flip / 1.6s
            if gasActive   && pb.angularVelocity <  maxSpin { pb.applyTorque( 12) }
            if brakeActive && pb.angularVelocity > -maxSpin { pb.applyTorque(-12) }
        }

        if !crashed && gasActive && fuel > 0 {
            // ⚡ LUDICROUS MODE: ≈ 1,000,000 km/h on the HUD (dx × 0.09).
            // Engine scales with speed so it's actually reachable this century.
            // (Sane values: maxSpeed 1111, accel 900.)
            let maxSpeed: CGFloat = 11_111_111
            let accel:    CGFloat = max(900, pb.velocity.dx * 0.6) * spec.accelScale
            pb.isResting = false                   // keep the body awake
            if grounded {
                if pb.velocity.dx < maxSpeed {
                    pb.velocity.dx = min(maxSpeed, pb.velocity.dx + accel * dt)
                }
                // Climb assist: ride up the slope instead of ramming into it.
                // Gravity is 4500 pt/s² here, far stronger than the engine, so
                // going uphill we give the bike the vertical component it needs
                // to track the surface. Downhill/flat we leave dy to physics
                // (so crests still launch you airborne).
                if groundSlope > 0 {
                    let climb = pb.velocity.dx * min(tan(groundSlope), 1.2)
                    pb.velocity.dy = max(pb.velocity.dy, climb)
                }
            } else if pb.velocity.dx < maxSpeed {
                // weak air control
                pb.velocity.dx += accel * 0.25 * dt
            }
            rpm  = min(1.0, rpm + dt * 3.0)
            // Fuel drain paused while the gauge is gone — invisible fuel
            // running out would read as a mystery engine failure.
            // fuel = max(0, fuel - dt * 0.006)
        } else {
            rpm = max(0, rpm - dt * 4)
        }

        // Spin wheel visuals proportional to velocity (hover pads don't spin)
        if vehicle == .classic || vehicle == .buggy {
            wheelSpin -= dt * pb.velocity.dx * 0.05
            rearWheelVis.zRotation  = wheelSpin
            frontWheelVis.zRotation = wheelSpin
        }
        // Spin the fan with the throttle
        if vehicle == .fanboat {
            fanBlades?.zRotation -= dt * (6 + rpm * 40)
        }

        // --- Brake (hover barely grips — it's skating on air) ---
        if !crashed && brakeActive && grounded {
            pb.velocity = CGVector(dx: pb.velocity.dx * spec.brakeGrip, dy: pb.velocity.dy)
            rpm = max(0, rpm - dt * 6)
        }

        // Tilt chassis visually to match terrain slope (bike body stays flat)
        chassisSlope += (groundSlope - chassisSlope) * 0.2

        // --- Visual-only wheelie / rear-squat ---
        // Physics stays flat & forward-driven; the whole bike just PIVOTS on its
        // rear wheel for the look. No effect on movement, so it can't stall or flip.
        let maxPitch: CGFloat = 0.30                       // ~17° lift at full revs (tunable)
        let pitchTarget = (gasActive && fuel > 0) ? rpm * maxPitch : 0
        wheeliePitch += (pitchTarget - wheeliePitch) * 0.12
        let p = wheeliePitch
        let rear = -wheelbase/2
        // Rotate the front wheel and chassis about the rear contact point.
        frontWheelVis.position = CGPoint(x: rear + wheelbase * cos(p),
                                         y:        wheelbase * sin(p))

        // --- Visual suspension: chassis rides a damped spring over the wheels ---
        suspVel    += (-90 * suspOffset - 11 * suspVel) * dt   // spring k / damping c
        suspOffset  = (suspOffset + suspVel * dt).clamped(to: -9...5)
        // Hover bike bobs on its air cushion; watercraft bob on the water
        let hoverBob: CGFloat = (vehicle == .hover || floating)
            ? sin(CGFloat(sceneTime) * 4) * 1.8 : 0
        chassisVis.position    = CGPoint(x: rear + wheelbase/2 * cos(p),
                                         y:        wheelbase/2 * sin(p) + suspOffset + hoverBob)
        chassisVis.zRotation   = chassisSlope + p

        // Rider leans with speed changes
        let leanTarget = (gasActive ? -0.12 : 0.0)
        riderNode.zRotation += (leanTarget - riderNode.zRotation) * 0.1

        // --- Camera ---
        let bp = bikeNode.position
        // After a crash the ragdoll is the star — follow it instead.
        let followPos = crashed ? (ragdollTorso?.position ?? bp) : bp

        // Estimate the landing zone: ground height ahead along current velocity
        let landX    = followPos.x + pb.velocity.dx * 0.35
        let groundY  = heightAt(x: landX)
        let altitude = max(0, followPos.y - groundY)

        // Zoom out with speed AND altitude, so big jumps keep the ground in view
        let speedNow  = abs(pb.velocity.dx)
        let speedZoom = min(speedNow / 1200, 1.8)
        let airZoom   = min(max(0, altitude - size.height * 0.30) / (size.height * 0.7), 1.2)
        let targetScale = 1.0 + speedZoom + airZoom
        // Asymmetric: zoom out promptly, drift back in lazily
        let zoomRate: CGFloat = targetScale > camScale ? 0.05 : 0.008
        camScale += (targetScale - camScale) * zoomRate
        // Camera children (screenNode: HUD, sky, parallax) are inherently
        // unaffected by camera scale — no counter-scaling needed.
        camNode.setScale(camScale)

        // Framing: normally look slightly above the bike; on big air, aim at
        // the midpoint between bike and landing so both stay in frame.
        let airBias  = min(1, altitude / (size.height * 0.8))
        let normalCY = followPos.y + 130 * camScale
        let airCY    = (followPos.y + groundY) / 2 + 40 * camScale
        let targetCX = followPos.x + size.width * 0.15 * camScale
        let targetCY = normalCY + (airCY - normalCY) * airBias
        camNode.position.x += (targetCX - camNode.position.x) * 0.08
        camNode.position.y += (targetCY - camNode.position.y) * 0.06

        // --- Monster chase ---
        if let monster {
            if !monster.isChasing && !crashed && bp.x > startX + 40 {
                monster.beginChase()
                showMonsterBanner()
            }
            let meters = max(0, bp.x - startX) / 35
            monster.update(dt: CGFloat(dt), playerX: bp.x, playerMeters: meters) {
                [weak self] x in self?.heightAt(x: x) ?? 0
            }
            // Caught: the kill zone reaches the bike — swallowed whole
            if !crashed && monster.isChasing && monster.catchX >= bp.x - 25 {
                crashCause = monster.devourText
                monster.devour()
                crash(swallowed: true)
            }
            let gap = bp.x - monster.catchX
            monsterWarning?.isHidden = crashed || !monster.isChasing || gap > 700
        }

        // --- Parallax: scroll each layer at its fraction of camera speed ---
        sceneTime += dt
        let camX = camNode.position.x
        let camY = camNode.position.y
        for l in bgLayers {
            let scroll = camX * l.f + l.drift * CGFloat(sceneTime)
            l.content.position.x   = -scroll.truncatingRemainder(dividingBy: l.L)
            l.container.position.y = -camYRef - (camY - camYRef) * l.fy
        }

        // --- HUD ---
        let dist = max(0, bp.x - startX) / 35
        distLabel.text   = String(format: "%.0f m", dist)
        pointsLabel.text = "\(totalPoints()) pts"
        speedLabel.text  = String(format: "%.0f km/h", abs(pb.velocity.dx) * 0.09)

        // Audio
        BikeAudio.shared.updateRPM(Float(rpm))

        // Falling off the world is a crash too
        if !crashed && bp.y < heightAt(x: bp.x) - 250 { crash() }
    }

    private func terrainSlopeAt(x: CGFloat) -> CGFloat {
        for i in 0..<max(0, terrainPoints.count - 1) {
            let a = terrainPoints[i], b = terrainPoints[i+1]
            if x >= a.x && x <= b.x {
                return atan2(b.y - a.y, b.x - a.x)
            }
        }
        return 0
    }

    private func heightAt(x: CGFloat) -> CGFloat {
        // Behind the oldest kept point (the monster samples back there), use
        // its height rather than falling through to the far-ahead last point.
        if let first = terrainPoints.first, x <= first.x { return first.y }
        for i in 0..<max(0, terrainPoints.count - 1) {
            let a = terrainPoints[i], b = terrainPoints[i+1]
            if x >= a.x && x <= b.x {
                let t = (x - a.x) / (b.x - a.x)
                return a.y + (b.y - a.y) * t
            }
        }
        return terrainPoints.last?.y ?? size.height * 0.28
    }
}

// MARK: - Helpers
extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}
extension Array where Element == CGPoint {
    func asPath() -> CGPath {
        let p = CGMutablePath()
        guard !isEmpty else { return p }
        p.move(to: self[0])
        for pt in dropFirst() { p.addLine(to: pt) }
        return p
    }
}
