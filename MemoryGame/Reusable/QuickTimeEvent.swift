// Penjelasan file: QuickTimeEvent.swift
// Komponen Quick Time Event (QTE) melingkar bergaya Mahkota Ranting Kayu (Wreath) & Kupu-kupu Blue Morpho.
// Mekanik:
// 1. Mengetuk Kupu-Kupu (Great) = Selesai instan (Menang).
// 2. Mengetuk Dedaunan (Good) = Lanjut Tahap 2 berbalik arah.
// 3. Sentuhan (Touch) kini dapat dilakukan di SELURUH LAYAR (Fullscreen).

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Core Logic & Data Types

public enum QTEStageDirection: Sendable {
    case leftToRight // Searah jarum jam
    case rightToLeft // Berlawanan jarum jam
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

    public init(
        radius: CGFloat = 78,
        stage1Duration: TimeInterval = 1.35,
        stage2Duration: TimeInterval = 1.10,
        stage1Zone: QTETargetZone = QTETargetZone(start: 0.60, end: 0.85, greatStart: 0.70, greatEnd: 0.74),
        stage2Zone: QTETargetZone = QTETargetZone(start: 0.22, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
        buttonPrompt: String = "Tap Anywhere",
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 0.65
    ) {
        self.radius = radius
        self.stage1Duration = stage1Duration
        self.stage2Duration = stage2Duration
        self.stage1Zone = stage1Zone
        self.stage2Zone = stage2Zone
        self.buttonPrompt = buttonPrompt
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
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
            // MEKANIK: Kena Kupu-Kupu (Great) langsung menang. Kena Daun (Good) masuk tahap 2.
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

// MARK: - SpriteKit Circular Node (Twigs, Leaves & Butterfly)

public final class QuickTimeEventNode: SKNode {

    public var onStageSuccess: ((_ stage: Int, _ hitResult: QTEHitResult) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?

    private var logic: QuickTimeEventLogic
    private var isRunning: Bool = false
    private var lastUpdateTime: TimeInterval = 0

    // Visual elements
    private let container = SKNode()
    private let zoneGood = SKNode()
    private let zoneGreat = SKNode()
    private let needle = SKShapeNode()
    private let promptButton = SKShapeNode()
    private let promptLabel = SKLabelNode(fontNamed: "Noteworthy-Bold")

    public init(config: QuickTimeEventConfig = QuickTimeEventConfig()) {
        self.logic = QuickTimeEventLogic(config: config)
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 500
        buildVisuals()
        updateZoneVisuals()
        updateNeedleRotation()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Geometry & Wreath Helpers

    /// Membuat jalinan ranting yang melilit dengan cabang-cabang acak (akar/duri)
    private func createTwigPath(radius: CGFloat, variance: CGFloat = 2.0, addBranches: Bool = false) -> CGPath {
        let path = CGMutablePath()
        let steps = 60
        for i in 0...steps {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(steps)
            let r = radius + CGFloat.random(in: -variance...variance)
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
            
            // Tambahkan cabang mencuat secara acak
            if addBranches && i % 6 == 0 && Bool.random() {
                let branchAngle = angle + CGFloat.random(in: -0.6...0.6)
                let branchLen = CGFloat.random(in: 4...12)
                let branchPt = CGPoint(x: pt.x + cos(branchAngle) * branchLen, y: pt.y + sin(branchAngle) * branchLen)
                path.addLine(to: branchPt)
                path.move(to: pt) // Kembali ke poros utama
            }
        }
        return path
    }

    private func createSketchyRect(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let hw = width / 2
        let hh = height / 2
        
        path.move(to: CGPoint(x: -hw - 1, y: hh + 2))
        path.addLine(to: CGPoint(x: hw + 2, y: hh - 1))
        path.addLine(to: CGPoint(x: hw - 1, y: -hh - 2))
        path.addLine(to: CGPoint(x: -hw + 1, y: -hh + 1))
        path.closeSubpath()
        
        return path
    }

    private func angle(for progress: CGFloat) -> CGFloat {
        return .pi / 2 - progress * (2 * .pi)
    }

    private func createArcPath(startProgress: CGFloat, endProgress: CGFloat, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let aStart = angle(for: startProgress)
        let aEnd = angle(for: endProgress)
        let steps = max(8, Int(abs(endProgress - startProgress) * 72))

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let curAngle = aStart + (aEnd - aStart) * t
            // Sedikit getaran agar sesuai tekstur kayu
            let r = radius + CGFloat.random(in: -1.0...1.0)
            let pt = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }

    // MARK: - Detailed Leaves & Blue Morpho Generators

    /// Membuat daun yang detail dengan tangkai dan urat
    private func createDetailedLeaf() -> SKNode {
        let leafContainer = SKNode()

        // 1. Tangkai daun (Stem)
        let stemPath = CGMutablePath()
        stemPath.move(to: CGPoint(x: -2, y: 0))
        stemPath.addLine(to: CGPoint(x: 2, y: 0))
        let stem = SKShapeNode(path: stemPath)
        stem.strokeColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        stem.lineWidth = 1.2
        leafContainer.addChild(stem)

        // 2. Helai daun (Blade) berbentuk oval melengkung cantik
        let bladePath = CGMutablePath()
        bladePath.move(to: CGPoint(x: 2, y: 0))
        bladePath.addCurve(to: CGPoint(x: 14, y: 0), control1: CGPoint(x: 6, y: 6), control2: CGPoint(x: 10, y: 8))
        bladePath.addCurve(to: CGPoint(x: 2, y: 0), control1: CGPoint(x: 10, y: -8), control2: CGPoint(x: 6, y: -6))
        
        let blade = SKShapeNode(path: bladePath)
        
        // Variasi warna dedaunan (ada yang hijau tua, ada yang sedikit muda)
        let isDark = Bool.random()
        blade.fillColor = isDark ? SKColor(red: 0.25, green: 0.45, blue: 0.15, alpha: 0.95) : SKColor(red: 0.35, green: 0.55, blue: 0.22, alpha: 0.95)
        blade.strokeColor = SKColor(red: 0.15, green: 0.35, blue: 0.10, alpha: 1.0)
        blade.lineWidth = 0.8
        leafContainer.addChild(blade)

        // 3. Urat daun utama (Central Vein)
        let veinPath = CGMutablePath()
        veinPath.move(to: CGPoint(x: 2, y: 0))
        veinPath.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 7, y: 2))
        let vein = SKShapeNode(path: veinPath)
        vein.strokeColor = SKColor(red: 0.2, green: 0.35, blue: 0.1, alpha: 0.7)
        vein.lineWidth = 0.5
        leafContainer.addChild(vein)

        return leafContainer
    }

    /// Membuat Kupu-kupu Blue Morpho yang realistis
    private func createMorphoButterfly() -> SKNode {
        let butterfly = SKNode()
        
        let wingColor = SKColor(red: 0.35, green: 0.65, blue: 0.98, alpha: 1.0) // Biru Morpho cerah
        let lowerWingColor = SKColor(red: 0.25, green: 0.55, blue: 0.90, alpha: 1.0)
        let edgeColor = SKColor(red: 0.1, green: 0.05, blue: 0.05, alpha: 1.0) // Pinggiran sayap hitam
        
        // Aura pendar biru tipis
        let glow = SKShapeNode(circleOfRadius: 18)
        glow.fillColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.25)
        glow.strokeColor = .clear
        glow.zPosition = -1
        butterfly.addChild(glow)

        func buildWingHalf(isLeft: Bool) -> SKNode {
            let half = SKNode()
            let s: CGFloat = isLeft ? -1 : 1

            // Sayap Atas (Forewing) - Lebar ke samping
            let fwPath = CGMutablePath()
            fwPath.move(to: .zero)
            fwPath.addCurve(to: CGPoint(x: 18 * s, y: 15), control1: CGPoint(x: 5 * s, y: 12), control2: CGPoint(x: 12 * s, y: 18))
            fwPath.addCurve(to: CGPoint(x: 22 * s, y: -2), control1: CGPoint(x: 24 * s, y: 10), control2: CGPoint(x: 24 * s, y: 4))
            fwPath.addCurve(to: .zero, control1: CGPoint(x: 10 * s, y: 0), control2: CGPoint(x: 5 * s, y: -2))

            let forewing = SKShapeNode(path: fwPath)
            forewing.fillColor = wingColor
            forewing.strokeColor = edgeColor
            forewing.lineWidth = 2.5
            forewing.lineJoin = .round
            half.addChild(forewing)

            // Sayap Bawah (Hindwing) - Membulat ke bawah
            let hwPath = CGMutablePath()
            hwPath.move(to: .zero)
            hwPath.addCurve(to: CGPoint(x: 20 * s, y: -3), control1: CGPoint(x: 10 * s, y: -1), control2: CGPoint(x: 15 * s, y: -2))
            hwPath.addCurve(to: CGPoint(x: 14 * s, y: -18), control1: CGPoint(x: 22 * s, y: -10), control2: CGPoint(x: 18 * s, y: -16))
            hwPath.addCurve(to: CGPoint(x: 2 * s, y: -8), control1: CGPoint(x: 8 * s, y: -18), control2: CGPoint(x: 4 * s, y: -12))
            hwPath.closeSubpath()

            let hindwing = SKShapeNode(path: hwPath)
            hindwing.fillColor = lowerWingColor
            hindwing.strokeColor = edgeColor
            hindwing.lineWidth = 2.0
            hindwing.lineJoin = .round
            half.addChild(hindwing)

            // Tekstur Urat (Veins)
            let veinPath = CGMutablePath()
            veinPath.move(to: .zero)
            veinPath.addLine(to: CGPoint(x: 14 * s, y: 9))
            veinPath.move(to: .zero)
            veinPath.addLine(to: CGPoint(x: 18 * s, y: 0))
            veinPath.move(to: .zero)
            veinPath.addLine(to: CGPoint(x: 12 * s, y: -10))
            
            let veins = SKShapeNode(path: veinPath)
            veins.strokeColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
            veins.lineWidth = 0.5
            half.addChild(veins)

            return half
        }

        let leftWing = buildWingHalf(isLeft: true)
        let rightWing = buildWingHalf(isLeft: false)
        butterfly.addChild(leftWing)
        butterfly.addChild(rightWing)

        // Tubuh Kupu-kupu
        let body = SKShapeNode(ellipseOf: CGSize(width: 4.0, height: 15))
        body.fillColor = edgeColor
        body.strokeColor = .clear
        body.position = CGPoint(x: 0, y: -2)
        butterfly.addChild(body)

        // Antena
        let antPath = CGMutablePath()
        antPath.move(to: CGPoint(x: -0.5, y: 5))
        antPath.addQuadCurve(to: CGPoint(x: -6, y: 13), control: CGPoint(x: -2, y: 10))
        antPath.move(to: CGPoint(x: 0.5, y: 5))
        antPath.addQuadCurve(to: CGPoint(x: 6, y: 13), control: CGPoint(x: 2, y: 10))
        let antennae = SKShapeNode(path: antPath)
        antennae.strokeColor = edgeColor
        antennae.lineWidth = 0.8
        butterfly.addChild(antennae)

        // Animasi Kepakan Natural
        let flapSpeed: TimeInterval = 0.12
        leftWing.run(.repeatForever(.sequence([
            .scaleX(to: 0.15, duration: flapSpeed),
            .scaleX(to: 1.0, duration: flapSpeed)
        ])))
        rightWing.run(.repeatForever(.sequence([
            .scaleX(to: 0.15, duration: flapSpeed),
            .scaleX(to: 1.0, duration: flapSpeed)
        ])))

        return butterfly
    }

    // MARK: - Visual Setup

    private func buildVisuals() {
        addChild(container)
        
        // --- OVERLAY FULLSCREEN ---
        // Membuat layar raksasa tidak terlihat di belakang untuk menangkap sentuhan di mana pun
        let touchCatcher = SKSpriteNode(color: .clear, size: CGSize(width: 5000, height: 5000))
        touchCatcher.zPosition = -100
        // Karena parent (QuickTimeEventNode) memiliki isUserInteractionEnabled = true,
        // node transparan raksasa ini akan memanjangkan hitbox komponen hingga menutupi layar.
        container.addChild(touchCatcher)

        let r = logic.config.radius

        // 1. Dial Ring Utama (Jalinan Ranting / Intertwining Vines)
        // Ranting Dasar (Gelap & tebal)
        let twigBase1 = SKShapeNode(path: createTwigPath(radius: r, variance: 1.5, addBranches: true))
        twigBase1.fillColor = .clear
        twigBase1.strokeColor = SKColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 1.0)
        twigBase1.lineWidth = 4.0
        twigBase1.zPosition = 1
        container.addChild(twigBase1)

        // Ranting Lilitan 1 (Agak terang)
        let twigBase2 = SKShapeNode(path: createTwigPath(radius: r, variance: 3.0, addBranches: true))
        twigBase2.fillColor = .clear
        twigBase2.strokeColor = SKColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 0.9)
        twigBase2.lineWidth = 2.5
        twigBase2.zPosition = 1.1
        container.addChild(twigBase2)

        // Ranting Highlight (Paling terang)
        let twigMid = SKShapeNode(path: createTwigPath(radius: r, variance: 1.0, addBranches: false))
        twigMid.fillColor = .clear
        twigMid.strokeColor = SKColor(red: 0.48, green: 0.38, blue: 0.28, alpha: 0.8)
        twigMid.lineWidth = 1.5
        twigMid.zPosition = 1.2
        container.addChild(twigMid)

        // 2. Containers untuk Zona Target
        zoneGood.zPosition = 3
        container.addChild(zoneGood)

        zoneGreat.zPosition = 4
        container.addChild(zoneGreat)

        // 3. Jarum Penunjuk (Gaya Ranting Tajam / Duri Merah)
        let needleHalfH: CGFloat = 18
        let needlePath = CGMutablePath()
        needlePath.move(to: CGPoint(x: -1.5, y: r - needleHalfH))
        needlePath.addLine(to: CGPoint(x: 1.5, y: r - needleHalfH))
        needlePath.addLine(to: CGPoint(x: 0.5, y: r + needleHalfH))
        needlePath.addLine(to: CGPoint(x: -0.5, y: r + needleHalfH))
        needlePath.closeSubpath()

        needle.path = needlePath
        needle.fillColor = SKColor(red: 0.90, green: 0.20, blue: 0.15, alpha: 0.95)
        needle.strokeColor = SKColor(red: 0.3, green: 0.05, blue: 0.05, alpha: 0.8)
        needle.lineWidth = 0.5
        needle.zPosition = 6
        container.addChild(needle)

        // 4. Tombol Tengah / Plakat Kayu
        let promptW: CGFloat = 90 // Diperbesar sedikit
        let promptH: CGFloat = 28
        promptButton.path = createSketchyRect(width: promptW, height: promptH)
        promptButton.fillColor = SKColor(red: 0.14, green: 0.10, blue: 0.07, alpha: 0.85)
        promptButton.strokeColor = SKColor(red: 0.45, green: 0.32, blue: 0.20, alpha: 0.8)
        promptButton.lineWidth = 1.5
        promptButton.position = .zero
        promptButton.zPosition = 7
        promptButton.name = "qteTapButton"

        promptLabel.text = logic.config.buttonPrompt
        promptLabel.fontSize = 13
        promptLabel.fontColor = SKColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 0.9)
        promptLabel.position = CGPoint(x: 0, y: -4)
        promptLabel.name = "qteTapButton"
        promptButton.addChild(promptLabel)
        container.addChild(promptButton)
    }

    private func updateZoneVisuals() {
        zoneGood.removeAllChildren()
        zoneGreat.removeAllChildren()

        let zone = logic.activeZone
        let r = logic.config.radius

        // --- ZONA GOOD (Sulur Akar Rambat & Dedaunan Natural) ---
        let vineArc = SKShapeNode(path: createArcPath(startProgress: zone.start, endProgress: zone.end, radius: r))
        vineArc.strokeColor = SKColor(red: 0.30, green: 0.45, blue: 0.20, alpha: 0.9)
        vineArc.lineWidth = 4.5
        vineArc.lineCap = .round
        zoneGood.addChild(vineArc)

        // Sebar daun mengikuti kelengkungan zona
        let arcLength = abs(zone.end - zone.start) * 2 * .pi * r
        let leafSpacing: CGFloat = 11.0
        let leafCount = max(2, Int(arcLength / leafSpacing))

        for i in 0...leafCount {
            let t = CGFloat(i) / CGFloat(leafCount)
            let progress = zone.start + (zone.end - zone.start) * t
            let curAngle = angle(for: progress)

            // Kadang muncul 2 daun bertumpuk agar lebih rimbun
            let numLeavesInCluster = Bool.random() ? 2 : 1
            
            for j in 0..<numLeavesInCluster {
                let leaf = createDetailedLeaf()
                
                // Variasi posisi luar dan dalam cincin
                let isOutside = (i + j) % 2 == 0
                let offsetR = r + (isOutside ? 5.0 : -5.0) + CGFloat.random(in: -1...1)
                leaf.position = CGPoint(x: cos(curAngle) * offsetR, y: sin(curAngle) * offsetR)
                
                let tangent = curAngle + .pi / 2
                // Arahkan daun keluar
                leaf.zRotation = tangent + (isOutside ? .pi/4 : -.pi/4) + CGFloat.random(in: -0.3...0.3)
                leaf.setScale(CGFloat.random(in: 0.8...1.15))
                
                zoneGood.addChild(leaf)
            }
        }

        // --- ZONA GREAT (Kupu-Kupu Blue Morpho) ---
        if let gStart = zone.greatStart, let gEnd = zone.greatEnd {
            // Rel/Jalur tipis sebagai penanda hitbox di bawah kupu-kupu
            let greatBase = SKShapeNode(path: createArcPath(startProgress: gStart, endProgress: gEnd, radius: r))
            greatBase.strokeColor = SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.5)
            greatBase.lineWidth = 2.0
            zoneGreat.addChild(greatBase)

            // Letakkan kupu-kupu tepat di tengah zona Great
            let centerProgress = (gStart + gEnd) / 2.0
            let curAngle = angle(for: centerProgress)
            
            let butterfly = createMorphoButterfly()
            butterfly.position = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            butterfly.zRotation = curAngle + .pi / 2 // Hadap sesuai putaran jarum
            
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

        container.setScale(0.85)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.2),
            .scale(to: 1.0, duration: 0.2)
        ]))

        HapticsService.shared.playSelection()

        removeAction(forKey: "qteUpdateLoop")
        let loop = SKAction.customAction(withDuration: 100.0) { [weak self] _, elapsedTime in
            guard let self, self.isRunning else { return }
            let dt: TimeInterval
            if self.lastUpdateTime == 0 {
                dt = 1.0 / 60.0
            } else {
                dt = min(0.05, max(0.001, Double(elapsedTime) - self.lastUpdateTime))
            }
            self.lastUpdateTime = Double(elapsedTime)

            let timeout = self.logic.update(deltaTime: dt)
            self.updateNeedleRotation()

            if timeout {
                self.handleTimeout()
            }
        }
        run(loop, withKey: "qteUpdateLoop")
    }

    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard isRunning && !logic.isCompleted else { return .miss }

        let outcome = logic.registerTap()

        promptButton.run(.sequence([
            .scale(to: 0.9, duration: 0.05),
            .scale(to: 1.0, duration: 0.1)
        ]))

        switch outcome.result {
        case .great, .good:
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: outcome.result == .great ? .heavy : .medium)
            #endif
            flashDial(success: true, isGreat: outcome.result == .great)

            if !outcome.completed {
                // Berhasil kena Daun (Good) -> Tahap 2 berbalik arah
                onStageSuccess?(1, outcome.result)
                updateZoneVisuals()
            } else {
                // Berhasil kena Kupu-kupu (Great) atau Selesai Tahap 2
                isRunning = false
                removeAction(forKey: "qteUpdateLoop")
                #if canImport(UIKit)
                HapticsService.shared.playNotification(.success)
                #endif
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
            flashColor = SKColor(red: 0.90, green: 0.20, blue: 0.18, alpha: 0.7)
        } else if isGreat {
            // Flash Biru Morpho bersinar saat menang instan
            flashColor = SKColor(red: 0.35, green: 0.75, blue: 1.0, alpha: 0.8)
        } else {
            flashColor = SKColor(red: 0.45, green: 0.85, blue: 0.50, alpha: 0.7)
        }

        // Pendar flash mengikuti bentuk ranting melingkar
        let flashRing = SKShapeNode(path: createTwigPath(radius: logic.config.radius, variance: 3.0, addBranches: true))
        flashRing.fillColor = .clear
        flashRing.strokeColor = flashColor
        flashRing.lineWidth = 12.0
        flashRing.zPosition = 10
        container.addChild(flashRing)
        
        flashRing.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.25),
                .scale(to: 1.15, duration: 0.25)
            ]),
            .removeFromParent()
        ]))
    }

    private func shakeTrack() {
        let shake = SKAction.sequence([
            .moveBy(x: -5, y: -3, duration: 0.04),
            .moveBy(x: 10, y: 6, duration: 0.08),
            .moveBy(x: -8, y: -4, duration: 0.06),
            .moveBy(x: 5, y: 2, duration: 0.05),
            .moveBy(x: -2, y: -1, duration: 0.04),
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
                .fadeOut(withDuration: 0.25),
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
        // Karena ada layar transparan (touchCatcher) di seluruh screen,
        // event ini akan terpanggil asalkan node utama mengizinkan interaksi.
        guard isRunning && logic.config.allowTouchAnywhere else { return }
        handleTap()
    }
    #endif
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("QuickTimeEvent Wreath Morpho Fullscreen") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        // Background hitam-coklat (hutan malam)
        scene.backgroundColor = SKColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0)

        func spawnQTE() {
            let qte = QuickTimeEventNode(config: QuickTimeEventConfig(
                radius: 78,
                stage1Duration: 1.35,
                stage2Duration: 1.15,
                buttonPrompt: "Tap Anywhere",
                autoDismissDelay: 0.8
            ))
            // Posisi tengah layar
            qte.position = CGPoint(x: 250, y: 300)
            qte.onDismiss = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    spawnQTE()
                }
            }
            scene.addChild(qte)
            qte.start()
        }

        spawnQTE()
        return scene
    }())
    .ignoresSafeArea()
}
#endif
