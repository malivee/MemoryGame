// Penjelasan file: QuickTimeEvent.swift
// Komponen Quick Time Event (QTE) melingkar bergaya Mahkota Ranting (Wreath) & Kupu-kupu Blue Morpho.
// Visual Upgrade (Enchanted Forest Vibes):
// - Latar belakang redup dengan kunang-kunang (fireflies) yang melayang.
// - Jalinan ranting 3D dengan shadow dan highlight.
// - Dedaunan (Good Zone) berayun halus tertiup angin.
// - Kupu-Kupu Blue Morpho (Great Zone) memancarkan aura neon biru (Additive Blend) & animasi kepakan sayap realistis.
// - Jarum penunjuk berupa duri kayu dengan ujung bercahaya magis.
// - Ledakan partikel "Pixie Dust" biru saat mendapat Great Hit.

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Core Logic & Data Types
// (Sama seperti sebelumnya, tidak ada perubahan pada logika dasar QTE)

public enum QTEStageDirection: Sendable {
    case leftToRight
    case rightToLeft
}

public enum QTEHitResult: Equatable, Sendable {
    case miss
    case good
    case great
}

public struct QTETargetZone: Equatable, Sendable {
    public let start: CGFloat
    public let end: CGFloat
    public let greatStart: CGFloat?
    public let greatEnd: CGFloat?

    public init(start: CGFloat, end: CGFloat, greatStart: CGFloat? = nil, greatEnd: CGFloat? = nil) {
        self.start = max(0.0, min(1.0, start))
        self.end = max(self.start, min(1.0, end))
        if let gStart = greatStart, let gEnd = greatEnd {
            let validGStart = max(self.start, min(self.end, gStart))
            let validGEnd = max(validGStart, min(self.end, gEnd))
            self.greatStart = validGStart
            self.greatEnd = validGEnd
        } else {
            self.greatStart = nil
            self.greatEnd = nil
        }
    }

    public func evaluate(progress: CGFloat) -> QTEHitResult {
        guard progress >= start && progress <= end else { return .miss }
        if let gStart = greatStart, let gEnd = greatEnd, progress >= gStart && progress <= gEnd {
            return .great
        }
        return .good
    }
}

public struct QuickTimeEventConfig: Sendable {
    public var radius: CGFloat
    public var stage1Duration: TimeInterval
    public var stage2Duration: TimeInterval
    public var stage1Zone: QTETargetZone
    public var stage2Zone: QTETargetZone
    public var buttonPrompt: String
    public var allowTouchAnywhere: Bool
    public var autoDismissDelay: TimeInterval
    public var requiredTaps: Int

    public init(
        radius: CGFloat = 85, // Diperbesar sedikit agar daun & kupu-kupu lebih leluasa
        stage1Duration: TimeInterval = 1.35,
        stage2Duration: TimeInterval = 1.10,
        stage1Zone: QTETargetZone = QTETargetZone(start: 0.60, end: 0.85, greatStart: 0.70, greatEnd: 0.74),
        stage2Zone: QTETargetZone = QTETargetZone(start: 0.22, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
        buttonPrompt: String = "TAP LAYAR",
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 0.8,
        requiredTaps: Int = 1
    ) {
        self.radius = radius
        self.stage1Duration = stage1Duration
        self.stage2Duration = stage2Duration
        self.stage1Zone = stage1Zone
        self.stage2Zone = stage2Zone
        self.buttonPrompt = buttonPrompt
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
        self.requiredTaps = requiredTaps
    }
}

public struct QuickTimeEventLogic {
    public private(set) var currentStage: Int = 1
    public private(set) var currentDirection: QTEStageDirection = .leftToRight
    public private(set) var isCompleted: Bool = false
    public private(set) var isSuccess: Bool = false
    public var currentProgress: CGFloat = 0.0

    public let config: QuickTimeEventConfig

    public init(config: QuickTimeEventConfig = QuickTimeEventConfig()) {
        self.config = config
        self.currentStage = 1
        self.currentDirection = .leftToRight
        self.currentProgress = 0.0
    }

    public var activeZone: QTETargetZone {
        currentStage == 1 ? config.stage1Zone : config.stage2Zone
    }

    public mutating func registerTap() -> (result: QTEHitResult, completed: Bool, isSuccess: Bool) {
        guard !isCompleted else { return (.miss, true, isSuccess) }

        let result = activeZone.evaluate(progress: currentProgress)
        if result == .miss {
            isCompleted = true
            isSuccess = false
            return (.miss, true, false)
        }

        if currentStage == 1 {
            if result == .great {
                isCompleted = true
                isSuccess = true
                return (result, true, true)
            } else {
                currentStage = 2
                currentDirection = .rightToLeft
                currentProgress = 1.0
                return (result, false, false)
            }
        } else {
            isCompleted = true
            isSuccess = true
            return (result, true, true)
        }
    }

    public mutating func update(deltaTime: TimeInterval) -> Bool {
        guard !isCompleted else { return false }

        let duration = currentStage == 1 ? config.stage1Duration : config.stage2Duration
        let deltaProgress = CGFloat(deltaTime / duration)

        if currentDirection == .leftToRight {
            currentProgress += deltaProgress
            if currentProgress >= 1.0 {
                currentProgress = 1.0
                isCompleted = true
                isSuccess = false
                return true
            }
        } else {
            currentProgress -= deltaProgress
            if currentProgress <= 0.0 {
                currentProgress = 0.0
                isCompleted = true
                isSuccess = false
                return true
            }
        }
        return false
    }
}

// MARK: - SpriteKit Node (Visuals)

public final class QuickTimeEventNode: SKNode {

    public var onStageSuccess: ((_ stage: Int, _ hitResult: QTEHitResult) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?

    private var logic: QuickTimeEventLogic
    private var isRunning: Bool = false
    private var lastUpdateTime: TimeInterval = 0

    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    private let fireflyLayer = SKNode()
    private let zoneGood = SKNode()
    private let zoneGreat = SKNode()
    private let needle = SKNode() // Needle sekarang berbentuk node kompleks
    private let promptButton = SKShapeNode()
    private let promptLabel = SKLabelNode(fontNamed: "Georgia-Bold")

    public init(config: QuickTimeEventConfig = QuickTimeEventConfig()) {
        self.logic = QuickTimeEventLogic(config: config)
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 800
        buildVisuals()
        updateZoneVisuals()
        updateNeedleRotation()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Geometry & Shape Generators

    private func angle(for progress: CGFloat) -> CGFloat {
        return .pi / 2 - progress * (2 * .pi)
    }

    private func createTwigPath(radius: CGFloat, variance: CGFloat = 2.0, addBranches: Bool = false) -> CGPath {
        let path = CGMutablePath()
        let steps = 60
        for i in 0...steps {
            let a = CGFloat(i) * 2 * .pi / CGFloat(steps)
            let r = radius + CGFloat.random(in: -variance...variance)
            let pt = CGPoint(x: cos(a) * r, y: sin(a) * r)
            
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            
            if addBranches && i % 6 == 0 && Bool.random() {
                let branchAngle = a + CGFloat.random(in: -0.6...0.6)
                let branchLen = CGFloat.random(in: 5...12)
                let branchPt = CGPoint(x: pt.x + cos(branchAngle) * branchLen, y: pt.y + sin(branchAngle) * branchLen)
                path.addLine(to: branchPt)
                path.move(to: pt)
            }
        }
        return path
    }

    private func createArcPath(startProgress: CGFloat, endProgress: CGFloat, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let aStart = angle(for: startProgress)
        let aEnd = angle(for: endProgress)
        let steps = max(10, Int(abs(endProgress - startProgress) * 72))

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let curAngle = aStart + (aEnd - aStart) * t
            let r = radius + CGFloat.random(in: -1.0...1.0)
            let pt = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }

    // MARK: - Nature Generators (Leaves, Butterfly, Fireflies)

    private func createDetailedLeaf() -> SKNode {
        let leafContainer = SKNode()

        // Helai daun
        let bladePath = CGMutablePath()
        bladePath.move(to: CGPoint(x: 2, y: 0))
        bladePath.addCurve(to: CGPoint(x: 16, y: 0), control1: CGPoint(x: 6, y: 7), control2: CGPoint(x: 12, y: 9))
        bladePath.addCurve(to: CGPoint(x: 2, y: 0), control1: CGPoint(x: 12, y: -9), control2: CGPoint(x: 6, y: -7))
        
        let blade = SKShapeNode(path: bladePath)
        let isDark = Bool.random()
        blade.fillColor = isDark ? SKColor(red: 0.25, green: 0.50, blue: 0.20, alpha: 0.95) : SKColor(red: 0.40, green: 0.65, blue: 0.25, alpha: 0.95)
        blade.strokeColor = SKColor(red: 0.15, green: 0.35, blue: 0.10, alpha: 1.0)
        blade.lineWidth = 1.0
        leafContainer.addChild(blade)

        // Urat daun
        let veinPath = CGMutablePath()
        veinPath.move(to: CGPoint(x: 1, y: 0))
        veinPath.addQuadCurve(to: CGPoint(x: 14, y: 0), control: CGPoint(x: 8, y: 2))
        let vein = SKShapeNode(path: veinPath)
        vein.strokeColor = SKColor(red: 0.2, green: 0.4, blue: 0.1, alpha: 0.7)
        vein.lineWidth = 0.6
        leafContainer.addChild(vein)

        // Animasi angin berayun
        leafContainer.run(.repeatForever(.sequence([
            .rotate(byAngle: 0.15, duration: TimeInterval.random(in: 1.2...1.8)).applyTimingMode(.easeInEaseOut),
            .rotate(byAngle: -0.15, duration: TimeInterval.random(in: 1.2...1.8)).applyTimingMode(.easeInEaseOut)
        ])))

        return leafContainer
    }

    private func createMorphoButterfly() -> SKNode {
        let butterfly = SKNode()
        let wingColor = SKColor(red: 0.2, green: 0.65, blue: 1.0, alpha: 1.0)
        let lowerWingColor = SKColor(red: 0.1, green: 0.5, blue: 0.95, alpha: 1.0)
        let edgeColor = SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        
        // Aura Magis (Additive)
        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = SKColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.3)
        glow.strokeColor = .clear
        glow.blendMode = .add
        glow.zPosition = -1
        butterfly.addChild(glow)

        func buildWingHalf(isLeft: Bool) -> SKNode {
            let half = SKNode()
            let s: CGFloat = isLeft ? -1 : 1

            let fwPath = CGMutablePath()
            fwPath.move(to: .zero)
            fwPath.addCurve(to: CGPoint(x: 20 * s, y: 16), control1: CGPoint(x: 8 * s, y: 12), control2: CGPoint(x: 14 * s, y: 18))
            fwPath.addCurve(to: CGPoint(x: 24 * s, y: -2), control1: CGPoint(x: 26 * s, y: 10), control2: CGPoint(x: 26 * s, y: 4))
            fwPath.addCurve(to: .zero, control1: CGPoint(x: 12 * s, y: 0), control2: CGPoint(x: 6 * s, y: -2))

            let forewing = SKShapeNode(path: fwPath)
            forewing.fillColor = wingColor
            forewing.strokeColor = edgeColor
            forewing.lineWidth = 2.0
            half.addChild(forewing)

            let hwPath = CGMutablePath()
            hwPath.move(to: .zero)
            hwPath.addCurve(to: CGPoint(x: 22 * s, y: -4), control1: CGPoint(x: 12 * s, y: -2), control2: CGPoint(x: 16 * s, y: -3))
            hwPath.addCurve(to: CGPoint(x: 15 * s, y: -20), control1: CGPoint(x: 24 * s, y: -12), control2: CGPoint(x: 20 * s, y: -18))
            hwPath.addCurve(to: CGPoint(x: 2 * s, y: -10), control1: CGPoint(x: 10 * s, y: -20), control2: CGPoint(x: 5 * s, y: -14))
            hwPath.closeSubpath()

            let hindwing = SKShapeNode(path: hwPath)
            hindwing.fillColor = lowerWingColor
            hindwing.strokeColor = edgeColor
            hindwing.lineWidth = 1.5
            half.addChild(hindwing)
            
            // Animasi kepakan sayap natural (3D illusion scale)
            let flapSpeed: TimeInterval = 0.15
            let flap = SKAction.sequence([
                .scaleX(to: 0.2, duration: flapSpeed).applyTimingMode(.easeInEaseOut),
                .scaleX(to: 1.0, duration: flapSpeed).applyTimingMode(.easeInEaseOut),
                .wait(forDuration: TimeInterval.random(in: 0.05...0.15))
            ])
            half.run(.repeatForever(flap))

            return half
        }

        let leftWing = buildWingHalf(isLeft: true)
        let rightWing = buildWingHalf(isLeft: false)
        butterfly.addChild(leftWing)
        butterfly.addChild(rightWing)

        let body = SKShapeNode(ellipseOf: CGSize(width: 4.5, height: 16))
        body.fillColor = edgeColor
        body.strokeColor = .clear
        butterfly.addChild(body)

        // Melayang perlahan (Hovering)
        butterfly.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 4, duration: 1.0).applyTimingMode(.easeInEaseOut),
            .moveBy(x: 0, y: -4, duration: 1.0).applyTimingMode(.easeInEaseOut)
        ])))

        return butterfly
    }

    private func buildFireflies() {
        for _ in 0..<15 {
            let firefly = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.0))
            let isBlue = Bool.random()
            firefly.fillColor = isBlue ? SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.8) : SKColor(red: 0.8, green: 1.0, blue: 0.4, alpha: 0.8)
            firefly.strokeColor = .clear
            firefly.blendMode = .add
            firefly.position = CGPoint(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -150...150))
            
            let move = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -30...30), duration: TimeInterval.random(in: 2...4))
            let fade = SKAction.sequence([
                .fadeAlpha(to: 0.2, duration: TimeInterval.random(in: 1...2)),
                .fadeAlpha(to: 0.9, duration: TimeInterval.random(in: 1...2))
            ])
            
            firefly.run(.repeatForever(.sequence([move, move.reversed()])))
            firefly.run(.repeatForever(fade))
            fireflyLayer.addChild(firefly)
        }
    }

    // MARK: - Visual Setup

    private func buildVisuals() {
        addChild(container)
        
        let touchCatcher = SKSpriteNode(color: .clear, size: CGSize(width: 5000, height: 5000))
        touchCatcher.zPosition = -100
        container.addChild(touchCatcher)

        // Background redup (Vignette hangat hutan)
        backdrop.color = SKColor(red: 0.08, green: 0.09, blue: 0.06, alpha: 0.85)
        backdrop.size = CGSize(width: 5000, height: 5000)
        backdrop.zPosition = -90
        container.addChild(backdrop)

        // Fireflies
        fireflyLayer.zPosition = -10
        container.addChild(fireflyLayer)
        buildFireflies()

        let r = logic.config.radius

        // 1. Dial Ring Utama (Wreath / Mahkota Ranting)
        let shadowWreath = SKShapeNode(circleOfRadius: r)
        shadowWreath.strokeColor = SKColor(red: 0.05, green: 0.03, blue: 0.02, alpha: 0.6)
        shadowWreath.lineWidth = 14.0
        shadowWreath.position = CGPoint(x: 0, y: -4)
        shadowWreath.zPosition = 0.5
        container.addChild(shadowWreath)

        let twigBase1 = SKShapeNode(path: createTwigPath(radius: r, variance: 1.5, addBranches: true))
        twigBase1.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
        twigBase1.lineWidth = 5.0
        twigBase1.zPosition = 1
        container.addChild(twigBase1)

        let twigBase2 = SKShapeNode(path: createTwigPath(radius: r, variance: 3.5, addBranches: true))
        twigBase2.strokeColor = SKColor(red: 0.35, green: 0.28, blue: 0.20, alpha: 1.0)
        twigBase2.lineWidth = 3.0
        twigBase2.zPosition = 1.1
        container.addChild(twigBase2)

        // 2. Containers Zona
        zoneGood.zPosition = 3
        container.addChild(zoneGood)

        zoneGreat.zPosition = 4
        container.addChild(zoneGreat)

        // 3. Jarum Penunjuk (Duri Kayu dengan Cahaya Magis)
        needle.zPosition = 6
        container.addChild(needle)
        
        let needleHalfH: CGFloat = 22
        let nPath = CGMutablePath()
        nPath.move(to: CGPoint(x: -2.0, y: r - needleHalfH + 4))
        nPath.addLine(to: CGPoint(x: 2.0, y: r - needleHalfH + 4))
        nPath.addLine(to: CGPoint(x: 0, y: r + needleHalfH)) // Ujung runcing
        nPath.closeSubpath()
        
        let nShape = SKShapeNode(path: nPath)
        nShape.fillColor = SKColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0) // Kayu
        nShape.strokeColor = SKColor(red: 0.2, green: 0.1, blue: 0.05, alpha: 1.0)
        nShape.lineWidth = 1.0
        needle.addChild(nShape)

        // Pendar magis di ujung jarum
        let nGlow = SKShapeNode(circleOfRadius: 5.0)
        nGlow.fillColor = SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.9)
        nGlow.strokeColor = .clear
        nGlow.blendMode = .add
        nGlow.position = CGPoint(x: 0, y: r + needleHalfH - 2)
        needle.addChild(nGlow)
        
        nGlow.run(.repeatForever(.sequence([
            .scale(to: 1.5, duration: 0.3),
            .scale(to: 0.8, duration: 0.3)
        ])))

        // 4. Tombol Tengah (Plakat Kayu Elegan)
        let promptW: CGFloat = 110
        let promptH: CGFloat = 34
        let btnRect = CGRect(x: -promptW/2, y: -promptH/2, width: promptW, height: promptH)
        
        // Shadow Plakat
        let btnShadow = SKShapeNode(rect: btnRect, cornerRadius: 8)
        btnShadow.fillColor = SKColor(red: 0.05, green: 0.03, blue: 0.02, alpha: 0.6)
        btnShadow.strokeColor = .clear
        btnShadow.position = CGPoint(x: 0, y: -4)
        btnShadow.zPosition = 6.9
        container.addChild(btnShadow)

        promptButton.path = CGPath(roundedRect: btnRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        promptButton.fillColor = SKColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 0.95)
        promptButton.strokeColor = SKColor(red: 0.75, green: 0.60, blue: 0.35, alpha: 1.0) // Bingkai kuningan
        promptButton.lineWidth = 2.5
        promptButton.zPosition = 7
        promptButton.name = "qteTapButton"

        promptLabel.text = logic.config.buttonPrompt
        promptLabel.fontSize = 14
        promptLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
        promptLabel.position = CGPoint(x: 0, y: -5)
        promptLabel.zPosition = 7.1
        promptLabel.name = "qteTapButton"
        
        // Drop shadow untuk teks agar timbul
        let txtShadow = SKLabelNode(fontNamed: "Georgia-Bold")
        txtShadow.text = logic.config.buttonPrompt
        txtShadow.fontSize = 14
        txtShadow.fontColor = .black
        txtShadow.position = CGPoint(x: 1, y: -1)
        txtShadow.zPosition = -1
        promptLabel.addChild(txtShadow)

        promptButton.addChild(promptLabel)
        container.addChild(promptButton)
    }

    private func updateZoneVisuals() {
        zoneGood.removeAllChildren()
        zoneGreat.removeAllChildren()

        let zone = logic.activeZone
        let r = logic.config.radius

        // --- ZONA GOOD (Jalur Akar Hijau & Dedaunan Rimba) ---
        let vineArc = SKShapeNode(path: createArcPath(startProgress: zone.start, endProgress: zone.end, radius: r))
        vineArc.strokeColor = SKColor(red: 0.45, green: 0.75, blue: 0.35, alpha: 0.7)
        vineArc.lineWidth = 8.0
        vineArc.lineCap = .round
        vineArc.blendMode = .add
        zoneGood.addChild(vineArc)

        let arcLength = abs(zone.end - zone.start) * 2 * .pi * r
        let leafCount = max(2, Int(arcLength / 12.0))

        for i in 0...leafCount {
            let t = CGFloat(i) / CGFloat(leafCount)
            let curAngle = angle(for: zone.start + (zone.end - zone.start) * t)

            for j in 0..<(Bool.random() ? 2 : 1) {
                let leaf = createDetailedLeaf()
                let isOutside = (i + j) % 2 == 0
                let offsetR = r + (isOutside ? 6.0 : -6.0) + CGFloat.random(in: -2...2)
                leaf.position = CGPoint(x: cos(curAngle) * offsetR, y: sin(curAngle) * offsetR)
                
                let tangent = curAngle + .pi / 2
                leaf.zRotation = tangent + (isOutside ? .pi/4 : -.pi/4) + CGFloat.random(in: -0.4...0.4)
                leaf.setScale(CGFloat.random(in: 0.8...1.2))
                zoneGood.addChild(leaf)
            }
        }

        // --- ZONA GREAT (Kupu-Kupu Blue Morpho) ---
        if let gStart = zone.greatStart, let gEnd = zone.greatEnd {
            let greatBase = SKShapeNode(path: createArcPath(startProgress: gStart, endProgress: gEnd, radius: r))
            greatBase.strokeColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.6)
            greatBase.lineWidth = 3.0
            greatBase.blendMode = .add
            zoneGreat.addChild(greatBase)

            let centerProgress = (gStart + gEnd) / 2.0
            let curAngle = angle(for: centerProgress)
            
            let butterfly = createMorphoButterfly()
            butterfly.position = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            butterfly.zRotation = curAngle + .pi / 2
            zoneGreat.addChild(butterfly)
            zoneGreat.isHidden = false
        } else {
            zoneGreat.isHidden = true
        }
    }

    private func updateNeedleRotation() {
        let curAngle = angle(for: logic.currentProgress)
        needle.zRotation = curAngle - .pi / 2
    }

    // MARK: - Lifecycle & Actions

    public func start() {
        guard !isRunning && !logic.isCompleted else { return }
        isRunning = true
        lastUpdateTime = 0

        container.setScale(0.8)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.25),
            .scale(to: 1.0, duration: 0.35).applyTimingMode(.easeOut)
        ]))

        HapticsService.shared.playSelection()

        removeAction(forKey: "qteUpdateLoop")
        let loop = SKAction.customAction(withDuration: 100.0) { [weak self] _, elapsedTime in
            guard let self, self.isRunning else { return }
            let dt: TimeInterval = self.lastUpdateTime == 0 ? 1.0 / 60.0 : min(0.05, max(0.001, Double(elapsedTime) - self.lastUpdateTime))
            self.lastUpdateTime = Double(elapsedTime)

            let timeout = self.logic.update(deltaTime: dt)
            self.updateNeedleRotation()

            if timeout { self.handleTimeout() }
        }
        run(loop, withKey: "qteUpdateLoop")
    }

    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard isRunning && !logic.isCompleted else { return .miss }

        let outcome = logic.registerTap()

        promptButton.run(.sequence([
            .scale(to: 0.9, duration: 0.05),
            .scale(to: 1.0, duration: 0.15).applyTimingMode(.easeOut)
        ]))

        switch outcome.result {
        case .great, .good:
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: outcome.result == .great ? .heavy : .medium)
            #endif
            flashDial(success: true, isGreat: outcome.result == .great)

            if !outcome.completed {
                // Kena daun (Good) -> Tahap 2
                onStageSuccess?(1, outcome.result)
                updateZoneVisuals()
            } else {
                // Kena kupu-kupu (Great) atau selesai
                isRunning = false
                removeAction(forKey: "qteUpdateLoop")
                #if canImport(UIKit)
                HapticsService.shared.playNotification(.success)
                #endif
                spawnPixieDust() // Efek spesial kemenangan
                onStageSuccess?(logic.currentStage, outcome.result)
                finishEvent(isSuccess: true)
            }

        case .miss:
            handleFailure()
        }

        return outcome.result
    }

    private func handleTimeout() {
        guard isRunning else { return }
        handleFailure()
    }

    private func handleFailure() {
        isRunning = false
        removeAction(forKey: "qteUpdateLoop")
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        flashDial(success: false, isGreat: false)
        shakeTrack()
        finishEvent(isSuccess: false)
    }

    private func flashDial(success: Bool, isGreat: Bool) {
        let flashColor: SKColor
        if !success {
            flashColor = SKColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 0.8)
        } else if isGreat {
            flashColor = SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.9) // Pendar biru terang
        } else {
            flashColor = SKColor(red: 0.5, green: 0.9, blue: 0.5, alpha: 0.8) // Daun hijau
        }

        let flashRing = SKShapeNode(path: createTwigPath(radius: logic.config.radius, variance: 4.0, addBranches: true))
        flashRing.fillColor = success ? flashColor.withAlphaComponent(0.2) : .clear
        flashRing.strokeColor = flashColor
        flashRing.lineWidth = 14.0
        flashRing.blendMode = .add
        flashRing.zPosition = 10
        container.addChild(flashRing)
        
        flashRing.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.35).applyTimingMode(.easeIn),
                .scale(to: 1.25, duration: 0.35).applyTimingMode(.easeOut)
            ]),
            .removeFromParent()
        ]))
    }
    
    private func spawnPixieDust() {
        // Ledakan partikel kunang-kunang/debu peri biru saat menang (Great Hit)
        for _ in 0..<30 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...4.5))
            spark.fillColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
            spark.strokeColor = .clear
            spark.blendMode = .add
            spark.zPosition = 15
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 30...140)
            let movePt = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            
            container.addChild(spark)
            spark.run(.sequence([
                .group([
                    .move(to: movePt, duration: TimeInterval.random(in: 0.4...0.8)).applyTimingMode(.easeOut),
                    .fadeOut(withDuration: TimeInterval.random(in: 0.4...0.8)),
                    .scale(to: 0.1, duration: TimeInterval.random(in: 0.4...0.8))
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func shakeTrack() {
        let shake = SKAction.sequence([
            .moveBy(x: -6, y: -4, duration: 0.03),
            .moveBy(x: 12, y: 8, duration: 0.06),
            .moveBy(x: -9, y: -5, duration: 0.05),
            .moveBy(x: 6, y: 3, duration: 0.04),
            .moveTo(x: 0, duration: 0.03)
        ])
        container.run(shake)
    }

    private func finishEvent(isSuccess: Bool) {
        onComplete?(isSuccess)
        let dismissDelay = logic.config.autoDismissDelay
        if dismissDelay > 0 {
            run(.sequence([
                .wait(forDuration: dismissDelay),
                .group([
                    .fadeOut(withDuration: 0.3),
                    .scale(to: 0.8, duration: 0.3).applyTimingMode(.easeIn)
                ]),
                .run { [weak self] in
                    self?.onDismiss?()
                    self?.removeFromParent()
                }
            ]))
        }
    }

    public func cancel() {
        isRunning = false
        removeAction(forKey: "qteUpdateLoop")
        removeFromParent()
    }

    #if canImport(UIKit)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning && logic.config.allowTouchAnywhere else { return }
        handleTap()
    }
    #endif
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("QuickTimeEvent Wreath Morpho Fullscreen") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.12, green: 0.18, blue: 0.14, alpha: 1.0)

        func spawn() {
            let qte = QuickTimeEventNode(config: QuickTimeEventConfig(
                radius: 85,
                stage1Duration: 1.35,
                stage2Duration: 1.10,
                stage1Zone: QTETargetZone(start: 0.60, end: 0.85, greatStart: 0.70, greatEnd: 0.74),
                stage2Zone: QTETargetZone(start: 0.22, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
                buttonPrompt: "TAP LAYAR",
                allowTouchAnywhere: true,
                autoDismissDelay: 0.8
            ))
            qte.position = CGPoint(x: 250, y: 300)
            qte.onDismiss = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { spawn() }
            }
            scene.addChild(qte)
            qte.start()
        }

        spawn()
        return scene
    }())
    .ignoresSafeArea()
}
#endif

