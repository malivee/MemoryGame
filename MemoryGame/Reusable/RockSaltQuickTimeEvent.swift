import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - SpriteKit Circular Node (Mine Cavern, Salt Veins & Pure Salt Monolith)

public final class RockSaltQuickTimeEventNode: SKNode {

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
    private let promptLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    public init(config: QuickTimeEventConfig = QuickTimeEventConfig(
        radius: 78,
        stage1Duration: 1.35,
        stage2Duration: 1.10,
        stage1Zone: QTETargetZone(start: 0.60, end: 0.85, greatStart: 0.70, greatEnd: 0.74),
        stage2Zone: QTETargetZone(start: 0.22, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
        buttonPrompt: "PAHAT BATU",
        allowTouchAnywhere: true,
        autoDismissDelay: 0.65
    )) {
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

    // MARK: - Geometry Helpers

    private func createRockCavernPath(radius: CGFloat, variance: CGFloat = 2.5, addMineralSpikes: Bool = false) -> CGPath {
        let path = CGMutablePath()
        let steps = 64
        for i in 0...steps {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(steps)
            let r = radius + CGFloat.random(in: -variance...variance)
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)

            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }

            if addMineralSpikes && i % 5 == 0 && Bool.random() {
                let spikeAngle = angle + CGFloat.random(in: -0.4...0.4)
                let spikeLen = CGFloat.random(in: 4...9)
                let spikePt = CGPoint(x: pt.x + cos(spikeAngle) * spikeLen, y: pt.y + sin(spikeAngle) * spikeLen)
                path.addLine(to: spikePt)
                path.move(to: pt)
            }
        }
        return path
    }

    private func createChiseledTimberRect(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let hw = width / 2
        let hh = height / 2

        path.move(to: CGPoint(x: -hw - 1.5, y: hh + 2))
        path.addLine(to: CGPoint(x: hw + 2, y: hh - 1.5))
        path.addLine(to: CGPoint(x: hw - 1.5, y: -hh - 2))
        path.addLine(to: CGPoint(x: -hw + 2, y: -hh + 1.5))
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
            let r = radius + CGFloat.random(in: -0.5...0.5)
            let pt = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }

    /// Membuat shape bintang/sparkling 4 sudut
    private func createSparkPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size))
        path.addQuadCurve(to: CGPoint(x: size/3, y: size/3), control: CGPoint(x: 0, y: size/3))
        path.addQuadCurve(to: CGPoint(x: size, y: 0), control: CGPoint(x: size/3, y: 0))
        path.addQuadCurve(to: CGPoint(x: size/3, y: -size/3), control: CGPoint(x: size/3, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: -size), control: CGPoint(x: 0, y: -size/3))
        path.addQuadCurve(to: CGPoint(x: -size/3, y: -size/3), control: CGPoint(x: 0, y: -size/3))
        path.addQuadCurve(to: CGPoint(x: -size, y: 0), control: CGPoint(x: -size/3, y: 0))
        path.addQuadCurve(to: CGPoint(x: -size/3, y: size/3), control: CGPoint(x: -size/3, y: 0))
        path.closeSubpath()
        return path
    }

    // MARK: - Rock Salt & Crystal Generators

    private func createRockSaltCrystal() -> SKNode {
        let crystalNode = SKNode()

        let prismW: CGFloat = CGFloat.random(in: 8...13)
        let prismH: CGFloat = CGFloat.random(in: 14...20)
        let isLightShard = Bool.random()

        let crystalPath = CGMutablePath()
        crystalPath.move(to: CGPoint(x: 0, y: prismH / 2))
        crystalPath.addLine(to: CGPoint(x: prismW / 2, y: prismH / 4))
        crystalPath.addLine(to: CGPoint(x: prismW / 2, y: -prismH / 4))
        crystalPath.addLine(to: CGPoint(x: 0, y: -prismH / 2))
        crystalPath.addLine(to: CGPoint(x: -prismW / 2, y: -prismH / 4))
        crystalPath.addLine(to: CGPoint(x: -prismW / 2, y: prismH / 4))
        crystalPath.closeSubpath()

        // Core Body
        let crystalBody = SKShapeNode(path: crystalPath)
        crystalBody.fillColor = isLightShard ? SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.85) : SKColor(red: 0.65, green: 0.85, blue: 0.95, alpha: 0.85)
        crystalBody.strokeColor = SKColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0)
        crystalBody.lineWidth = 1.0
        crystalNode.addChild(crystalBody)

        // Inner Glow / Refraction (menggunakan blend mode Add)
        let glowFacetPath = CGMutablePath()
        glowFacetPath.move(to: CGPoint(x: 0, y: prismH / 2))
        glowFacetPath.addLine(to: CGPoint(x: prismW / 4, y: 0))
        glowFacetPath.addLine(to: CGPoint(x: -prismW / 4, y: 0))
        glowFacetPath.closeSubpath()
        
        let glowFacet = SKShapeNode(path: glowFacetPath)
        glowFacet.fillColor = SKColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 0.6)
        glowFacet.strokeColor = .clear
        glowFacet.blendMode = .add
        crystalNode.addChild(glowFacet)

        return crystalNode
    }

    private func createPureRockSaltMonolith() -> SKNode {
        let monolith = SKNode()

        // 1. Layered Glow Aura (Additive)
        for radius in [15.0, 22.0, 30.0] {
            let aura = SKShapeNode(circleOfRadius: radius)
            aura.fillColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.25)
            aura.strokeColor = .clear
            aura.blendMode = .add
            aura.zPosition = -1
            monolith.addChild(aura)
            
            aura.run(.repeatForever(.sequence([
                .scale(to: 1.15, duration: CGFloat.random(in: 0.8...1.2)),
                .scale(to: 0.9, duration: CGFloat.random(in: 0.8...1.2))
            ])))
        }

        // 2. Gugusan 3 Prisma Kristal Berlian Garam
        func drawTower(path: CGPath, color: SKColor) -> SKShapeNode {
            let tower = SKShapeNode(path: path)
            tower.fillColor = color
            tower.strokeColor = .white
            tower.lineWidth = 1.5
            return tower
        }

        let cPath = CGMutablePath()
        cPath.move(to: CGPoint(x: 0, y: 19))
        cPath.addLine(to: CGPoint(x: 8, y: 5))
        cPath.addLine(to: CGPoint(x: 6, y: -13))
        cPath.addLine(to: CGPoint(x: -6, y: -13))
        cPath.addLine(to: CGPoint(x: -8, y: 5))
        cPath.closeSubpath()
        monolith.addChild(drawTower(path: cPath, color: SKColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 0.95)))

        let lPath = CGMutablePath()
        lPath.move(to: CGPoint(x: -11, y: 11))
        lPath.addLine(to: CGPoint(x: -4, y: 3))
        lPath.addLine(to: CGPoint(x: -5, y: -11))
        lPath.addLine(to: CGPoint(x: -14, y: -9))
        lPath.addLine(to: CGPoint(x: -16, y: 2))
        lPath.closeSubpath()
        monolith.addChild(drawTower(path: lPath, color: SKColor(red: 0.65, green: 0.88, blue: 1.0, alpha: 0.90)))

        let rPath = CGMutablePath()
        rPath.move(to: CGPoint(x: 12, y: 9))
        rPath.addLine(to: CGPoint(x: 16, y: 1))
        rPath.addLine(to: CGPoint(x: 14, y: -10))
        rPath.addLine(to: CGPoint(x: 5, y: -11))
        rPath.addLine(to: CGPoint(x: 4, y: 2))
        rPath.closeSubpath()
        monolith.addChild(drawTower(path: rPath, color: SKColor(red: 0.70, green: 0.90, blue: 1.0, alpha: 0.90)))

        // 3. Custom Sparks (Add blend mode)
        for pos in [CGPoint(x: -10, y: 14), CGPoint(x: 12, y: 12), CGPoint(x: 0, y: -8)] {
            let spark = SKShapeNode(path: createSparkPath(size: 6))
            spark.fillColor = .white
            spark.strokeColor = SKColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 0.8)
            spark.blendMode = .add
            spark.position = pos
            monolith.addChild(spark)
            
            spark.run(.repeatForever(.sequence([
                .wait(forDuration: TimeInterval.random(in: 0...0.5)),
                .group([
                    .scale(to: 1.5, duration: 0.3),
                    .rotate(byAngle: .pi, duration: 0.6),
                    .sequence([.fadeAlpha(to: 1.0, duration: 0.3), .fadeAlpha(to: 0.2, duration: 0.3)])
                ]),
                .scale(to: 0.5, duration: 0.3)
            ])))
        }

        // Animasi bernapas kristal (Levitasi tipis)
        monolith.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 1.2),
            .moveBy(x: 0, y: -3, duration: 1.2)
        ])))

        return monolith
    }

    // MARK: - Visual Setup

    private func buildVisuals() {
        addChild(container)

        // Overlay Fullscreen
        let touchCatcher = SKSpriteNode(color: .clear, size: CGSize(width: 5000, height: 5000))
        touchCatcher.zPosition = -100
        container.addChild(touchCatcher)

        let r = logic.config.radius

        // 1. Dial Ring Utama (Dinding Batu)
        // Lapisan Dalam (Bayangan Gua)
        let cavernShadow = SKShapeNode(circleOfRadius: r - 4)
        cavernShadow.fillColor = SKColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 0.8)
        cavernShadow.strokeColor = .clear
        cavernShadow.zPosition = 0.5
        container.addChild(cavernShadow)

        // Lapisan Batu Dasar Luar (Batu slate gelap pekat)
        let rockBase = SKShapeNode(path: createRockCavernPath(radius: r, variance: 3.0, addMineralSpikes: true))
        rockBase.fillColor = .clear
        rockBase.strokeColor = SKColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0)
        rockBase.lineWidth = 8.0
        rockBase.zPosition = 1
        container.addChild(rockBase)

        // Lapisan Tengah
        let rockMid = SKShapeNode(path: createRockCavernPath(radius: r, variance: 1.5))
        rockMid.fillColor = .clear
        rockMid.strokeColor = SKColor(red: 0.25, green: 0.28, blue: 0.32, alpha: 1.0)
        rockMid.lineWidth = 3.0
        rockMid.zPosition = 1.1
        container.addChild(rockMid)

        // Urat Garam Biru Es Berkilau
        let saltVeinRing = SKShapeNode(path: createRockCavernPath(radius: r, variance: 0.8))
        saltVeinRing.fillColor = .clear
        saltVeinRing.strokeColor = SKColor(red: 0.35, green: 0.70, blue: 0.90, alpha: 0.6)
        saltVeinRing.lineWidth = 2.0
        saltVeinRing.blendMode = .add
        saltVeinRing.zPosition = 1.2
        container.addChild(saltVeinRing)

        // 2. Containers Zona Target
        zoneGood.zPosition = 3
        container.addChild(zoneGood)

        zoneGreat.zPosition = 4
        container.addChild(zoneGreat)

        // 3. Jarum Penunjuk (Beliung Besi)
        let needleHalfH: CGFloat = 20
        let needlePath = CGMutablePath()
        // Pangkal (Besi tempa gelap)
        needlePath.move(to: CGPoint(x: -3.5, y: r - needleHalfH))
        needlePath.addLine(to: CGPoint(x: 3.5, y: r - needleHalfH))
        needlePath.addLine(to: CGPoint(x: 2.0, y: r + needleHalfH - 5))
        // Mata pahat bercahaya
        needlePath.addLine(to: CGPoint(x: 0, y: r + needleHalfH + 6))
        needlePath.addLine(to: CGPoint(x: -2.0, y: r + needleHalfH - 5))
        needlePath.closeSubpath()

        needle.path = needlePath
        needle.fillColor = SKColor(red: 0.6, green: 0.65, blue: 0.7, alpha: 1.0) // Silver baja
        needle.strokeColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        needle.lineWidth = 1.2
        needle.zPosition = 6
        
        // Pendar cyan di mata pahat
        let needleGlow = SKShapeNode(circleOfRadius: 4.5)
        needleGlow.position = CGPoint(x: 0, y: r + needleHalfH + 3)
        needleGlow.fillColor = SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 0.8)
        needleGlow.strokeColor = .clear
        needleGlow.blendMode = .add
        needle.addChild(needleGlow)
        
        container.addChild(needle)

        // 4. Tombol Tengah (Balok Kayu Tambang)
        let promptW: CGFloat = 110
        let promptH: CGFloat = 34
        promptButton.path = createChiseledTimberRect(width: promptW, height: promptH)
        promptButton.fillColor = SKColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.98)
        promptButton.strokeColor = SKColor(red: 0.40, green: 0.70, blue: 0.85, alpha: 0.80)
        promptButton.lineWidth = 2.0
        promptButton.position = .zero
        promptButton.zPosition = 7
        promptButton.name = "qteTapButton"

        promptLabel.text = logic.config.buttonPrompt
        promptLabel.fontSize = 13.0
        promptLabel.fontColor = SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
        promptLabel.position = CGPoint(x: 0, y: -4.5)
        promptLabel.name = "qteTapButton"
        
        // Tambahkan bayangan teks agar lebih tebal
        let shadowLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shadowLabel.text = logic.config.buttonPrompt
        shadowLabel.fontSize = 13.0
        shadowLabel.fontColor = .black
        shadowLabel.position = CGPoint(x: 1, y: -5.5)
        shadowLabel.zPosition = -1
        promptLabel.addChild(shadowLabel)
        
        promptButton.addChild(promptLabel)
        container.addChild(promptButton)
    }

    private func updateZoneVisuals() {
        zoneGood.removeAllChildren()
        zoneGreat.removeAllChildren()

        let zone = logic.activeZone
        let r = logic.config.radius

        // --- ZONA GOOD (Rekahan Endapan Rock Salt) ---
        let saltArc = SKShapeNode(path: createArcPath(startProgress: zone.start, endProgress: zone.end, radius: r))
        saltArc.strokeColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.6)
        saltArc.lineWidth = 7.0
        saltArc.lineCap = .round
        saltArc.blendMode = .add
        zoneGood.addChild(saltArc)

        let arcLength = abs(zone.end - zone.start) * 2 * .pi * r
        let crystalSpacing: CGFloat = 12.0
        let crystalCount = max(2, Int(arcLength / crystalSpacing))

        for i in 0...crystalCount {
            let t = CGFloat(i) / CGFloat(crystalCount)
            let progress = zone.start + (zone.end - zone.start) * t
            let curAngle = angle(for: progress)

            let numCrystals = Bool.random() ? 2 : 1
            for j in 0..<numCrystals {
                let crystal = createRockSaltCrystal()
                let isOutside = (i + j) % 2 == 0
                let offsetR = r + (isOutside ? 5.0 : -5.0) + CGFloat.random(in: -1...1)
                
                crystal.position = CGPoint(x: cos(curAngle) * offsetR, y: sin(curAngle) * offsetR)
                crystal.zRotation = curAngle + (isOutside ? .pi/3 : -.pi/3) + CGFloat.random(in: -0.2...0.2)
                crystal.setScale(CGFloat.random(in: 0.7...1.2))
                
                // Tambahkan animasi melayang/bersinar halus
                crystal.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.7, duration: CGFloat.random(in: 0.5...1.0)),
                    .fadeAlpha(to: 1.0, duration: CGFloat.random(in: 0.5...1.0))
                ])))

                zoneGood.addChild(crystal)
            }
        }

        // --- ZONA GREAT (Bongkahan Rock Salt Murni Bercahaya) ---
        if let gStart = zone.greatStart, let gEnd = zone.greatEnd {
            let greatBase = SKShapeNode(path: createArcPath(startProgress: gStart, endProgress: gEnd, radius: r))
            greatBase.strokeColor = SKColor(red: 0.70, green: 0.95, blue: 1.0, alpha: 0.9)
            greatBase.lineWidth = 3.5
            greatBase.blendMode = .add
            zoneGreat.addChild(greatBase)

            let centerProgress = (gStart + gEnd) / 2.0
            let curAngle = angle(for: centerProgress)

            let monolith = createPureRockSaltMonolith()
            monolith.position = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            monolith.zRotation = curAngle + .pi / 2
            zoneGreat.addChild(monolith)
            
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

        container.setScale(0.7)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.3),
            .scale(to: 1.0, duration: 0.4).applyTimingMode(.easeOut)
        ]))

        HapticsService.shared.playSelection()

        removeAction(forKey: "qteUpdateLoop")
        let loop = SKAction.customAction(withDuration: 100.0) { [weak self] _, elapsedTime in
            guard let self, self.isRunning else { return }
            let dt: TimeInterval = self.lastUpdateTime == 0 ? 1.0/60.0 : min(0.05, max(0.001, Double(elapsedTime) - self.lastUpdateTime))
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
            .scale(to: 0.85, duration: 0.05),
            .scale(to: 1.0, duration: 0.15).applyTimingMode(.easeOut)
        ]))

        switch outcome.result {
        case .great, .good:
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: outcome.result == .great ? .heavy : .medium)
            #endif
            flashDial(success: true, isGreat: outcome.result == .great)

            if !outcome.completed {
                onStageSuccess?(1, outcome.result)
                updateZoneVisuals()
                
                // Beri efek transisi saat berbalik arah
                container.run(.sequence([
                    .scale(to: 1.08, duration: 0.05),
                    .scale(to: 1.0, duration: 0.15)
                ]))
            } else {
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
        let flashColor = success ? (isGreat ? SKColor(red: 0.8, green: 0.98, blue: 1.0, alpha: 1.0) : SKColor(red: 0.4, green: 0.85, blue: 0.95, alpha: 0.8)) : SKColor(red: 0.95, green: 0.2, blue: 0.1, alpha: 0.85)

        // Buat ledakan cahaya (Additive glow)
        let flashRing = SKShapeNode(path: createRockCavernPath(radius: logic.config.radius, variance: 4.0, addMineralSpikes: true))
        flashRing.fillColor = success ? flashColor.withAlphaComponent(0.3) : .clear
        flashRing.strokeColor = flashColor
        flashRing.lineWidth = success ? 16.0 : 8.0
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

    private func shakeTrack() {
        let shake = SKAction.sequence([
            .moveBy(x: -7, y: -4, duration: 0.04),
            .moveBy(x: 14, y: 8, duration: 0.08),
            .moveBy(x: -10, y: -5, duration: 0.06),
            .moveBy(x: 6, y: 3, duration: 0.05),
            .moveBy(x: -3, y: -2, duration: 0.04),
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

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("Rock Salt QTE (Mine Cavern)") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)

        func spawn() {
            let qte = RockSaltQuickTimeEventNode(config: QuickTimeEventConfig(
                radius: 82,
                stage1Duration: 1.40,
                stage2Duration: 1.15,
                stage1Zone: QTETargetZone(start: 0.58, end: 0.85, greatStart: 0.70, greatEnd: 0.75),
                stage2Zone: QTETargetZone(start: 0.20, end: 0.45, greatStart: 0.28, greatEnd: 0.33),
                buttonPrompt: "Pahat Garam",
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
