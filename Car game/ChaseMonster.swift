//
//  ChaseMonster.swift
//  Car game — Moto Hill Rider
//
//  Base class for the level monsters. Every level has one: it looms at the
//  start line, wakes when the rider first moves, chases at a crawl, and gains
//  speed the farther the rider gets. A rubber band keeps it from ever falling
//  hopelessly behind, so stopping is a death sentence. When it catches the
//  bike it takes rider and machine in one bite and keeps on coming.
//
//  Subclasses build their art in code (SKShapeNodes, like the rest of the
//  game) and implement layout(groundY:) to place every part in world
//  coordinates each frame — the node itself stays at the scene origin so each
//  part can hug its own patch of terrain.
//

import SpriteKit
import UIKit

class ChaseMonster: SKNode {

    // MARK: Chase tuning (subclasses may adjust in their init)
    var baseSpeed:     CGFloat = 150    // pt/s right after waking
    var speedPerMeter: CGFloat = 1.4    // extra pt/s per meter of rider distance
    var maxSpeed:      CGFloat = 3600
    var maxGap:        CGFloat = 2400   // never lags farther behind than this
    var devourSpeed:   CGFloat = 1700   // min speed while streaming past after the kill

    // MARK: UI copy (subclasses override)
    var bannerText:  String { "IT STIRS…" }
    var warningText: String { "IT'S CLOSING IN!" }
    var devourText:  String { "DEVOURED!" }

    // MARK: State
    /// World x of the front of the kill zone — jaws, maw, or tentacle tip.
    private(set) var catchX: CGFloat
    /// World point the swallowed bike is pulled into. Set during layout.
    var mouthCenter: CGPoint = .zero
    private(set) var isChasing   = false
    private(set) var hasDevoured = false
    var phase:  CGFloat = 0
    var frenzy: CGFloat = 1     // >1 briefly during the devour lunge

    var idlePhaseRate:  CGFloat { 1.6 }
    var chasePhaseRate: CGFloat { 3.2 }

    init(startX: CGFloat) {
        self.catchX = startX
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Behavior
    func beginChase() {
        isChasing = true
    }

    /// The kill: brief frenzy, then it just keeps on coming.
    func devour() {
        guard !hasDevoured else { return }
        hasDevoured = true
        frenzy = 3.0
        onDevour()
    }

    /// Subclass hook for the kill animation (jaw snap, lunge…).
    func onDevour() {}

    /// Advance the chase and animate. `playerMeters` is HUD distance (pts / 35).
    final func update(dt: CGFloat, playerX: CGFloat, playerMeters: CGFloat,
                      groundY: (CGFloat) -> CGFloat) {
        phase  += dt * (isChasing ? chasePhaseRate : idlePhaseRate) * frenzy
        frenzy  = max(1, frenzy - dt * 2)

        if isChasing {
            var speed = min(baseSpeed + playerMeters * speedPerMeter, maxSpeed)
            if hasDevoured { speed = max(speed, devourSpeed) }
            catchX += speed * dt
            if !hasDevoured && playerX - catchX > maxGap { catchX = playerX - maxGap }
        }
        layout(groundY: groundY)
    }

    /// Subclass hook: place all parts in world coordinates for the current
    /// catchX/phase, and update mouthCenter.
    func layout(groundY: (CGFloat) -> CGFloat) {}

    // MARK: - Shared helpers
    /// Standard ground-churn emitter; caller positions it and sets birth rate.
    func makeDustEmitter(color: SKColor, rangeX: CGFloat) -> SKEmitterNode {
        let dust = SKEmitterNode()
        dust.particleTexture = Self.softDotTexture()
        dust.particleBirthRate = 0
        dust.particleLifetime = 0.7
        dust.particleLifetimeRange = 0.3
        dust.particleSpeed = 150
        dust.particleSpeedRange = 60
        dust.emissionAngle = .pi / 2
        dust.emissionAngleRange = .pi * 0.9
        dust.particleAlpha = 0.5
        dust.particleAlphaSpeed = -0.8
        dust.particleScale = 0.6
        dust.particleScaleRange = 0.3
        dust.particleScaleSpeed = 0.4
        dust.particleColor = color
        dust.particleColorBlendFactor = 1
        dust.particlePositionRange = CGVector(dx: rangeX, dy: 14)
        dust.zPosition = 1.0
        addChild(dust)
        return dust
    }

    /// Soft radial dot for particles.
    static func softDotTexture() -> SKTexture {
        let S: CGFloat = 32
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: S, height: S))
        let img = renderer.image { ctx in
            let grad = CGGradient(colorsSpace: nil,
                                  colors: [UIColor.white.cgColor,
                                           UIColor.white.withAlphaComponent(0).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.cgContext.drawRadialGradient(grad,
                                             startCenter: CGPoint(x: S/2, y: S/2), startRadius: 0,
                                             endCenter: CGPoint(x: S/2, y: S/2), endRadius: S/2,
                                             options: [])
        }
        return SKTexture(image: img)
    }
}
