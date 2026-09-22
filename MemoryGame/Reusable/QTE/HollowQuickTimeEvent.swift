// Penjelasan file: HollowQuickTimeEvent.swift
// Komponen Quick Time Event (QTE) melingkar 2-Tahap khusus peristiwa Dikejar The Hollow.
// Visual Upgrade:
// - Latar belakang kabut ungu gelap (Creeping Mist) yang bergerak prosedural.
// - Rel dial terbuat dari akar/duri bayangan hitam pekat (Dark Brambles).
// - Zona Good berupa gumpalan energi jiwa/kabut ungu terang (Additive Blend).
// - Zona Great (Sweet Spot) ditandai dengan Mata Merah The Hollow yang berkedip dan menyala.
// - Jarum jam/rel berupa Tulang Berdarah (Bone Spike) bercahaya neon merah.

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - SpriteKit Node: HollowQuickTimeEventNode

public final class HollowQuickTimeEventNode: SKNode {

    public var onStageSuccess: ((_ stage: Int, _ hitResult: QTEHitResult) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?

    private var logic: QuickTimeEventLogic
    private var isRunning: Bool = false
    private var lastUpdateTime: TimeInterval = 0

    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    private let mistLayer = SKNode()
    private let atmosphereNode = SKNode()
    private let zoneGood = SKNode()
    private let zoneGreat = SKNode()
    private let needle = SKShapeNode()
    private let promptButton = SKShapeNode()
    private let promptButtonCore = SKShapeNode()
    private let promptLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let headingLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    public init(config: QuickTimeEventConfig = QuickTimeEventConfig(
        radius: 88, // Diperbesar sedikit agar visual horor lebih leluasa
        stage1Duration: 1.25,
        stage2Duration: 1.05,
        stage1Zone: QTETargetZone(start: 0.58, end: 0.84, greatStart: 0.70, greatEnd: 0.74),
        stage2Zone: QTETargetZone(start: 0.20, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
        buttonPrompt: "LARI!",
        allowTouchAnywhere: true,
        autoDismissDelay: 0.75
    )) {
        self.logic = QuickTimeEventLogic(config: config)
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 850
        buildVisuals()
        updateZoneVisuals()
        updateNeedleRotation()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Geometry & Dark Bramble Generators

    private func angle(for progress: CGFloat) -> CGFloat {
        return .pi / 2 - progress * (2 * .pi)
    }

    /// Membuat jalinan ranting berduri hitam legam yang tidak beraturan
    private func createDarkBramblePath(radius: CGFloat, variance: CGFloat = 2.5, addThorns: Bool = false) -> CGPath {
        let path = CGMutablePath()
        let steps = 64
        for i in 0...steps {
            let a = CGFloat(i) * 2 * .pi / CGFloat(steps)
            let r = radius + CGFloat.random(in: -variance...variance)
            let pt = CGPoint(x: cos(a) * r, y: sin(a) * r)

            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }

            // Duri-duri tajam hitam mencuat
            if addThorns && i % 5 == 0 && Bool.random() {
                let thornAngle = a + CGFloat.random(in: -0.5...0.5)
                let thornLen = CGFloat.random(in: 8...15)
                let thornPt = CGPoint(x: pt.x + cos(thornAngle) * thornLen, y: pt.y + sin(thornAngle) * thornLen)
                path.addLine(to: thornPt)
                path.move(to: pt)
            }
        }
        return path
    }

    private func createArcPath(startProgress: CGFloat, endProgress: CGFloat, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let aStart = angle(for: startProgress)
        let aEnd = angle(for: endProgress)
        let steps = max(10, Int(abs(endProgress - startProgress) * 80))

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let curAngle = aStart + (aEnd - aStart) * t
            let r = radius + CGFloat.random(in: -0.5...0.5)
            let pt = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }

    /// Membuat gumpalan roh kabut bayangan ungu terang (Good Zone Indicator)
    private func createShadowWisp() -> SKNode {
        let wisp = SKNode()
        let blobCount = 3
        for _ in 0..<blobCount {
            let r = CGFloat.random(in: 6...10)
            let blob = SKShapeNode(circleOfRadius: r)
            blob.fillColor = SKColor(red: 0.6, green: 0.1, blue: 0.4, alpha: 0.6)
            blob.strokeColor = .clear
            blob.blendMode = .add
            blob.position = CGPoint(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -5...5))
            
            // Wisp animation
            blob.run(.repeatForever(.sequence([
                .scale(to: 1.3, duration: TimeInterval.random(in: 0.4...0.8)),
                .scale(to: 0.8, duration: TimeInterval.random(in: 0.4...0.8))
            ])))
            wisp.addChild(blob)
        }
        return wisp
    }

    /// Membuat Mata Merah Menyala The Hollow (Great Zone / Sweet Spot)
    private func createHollowEye() -> SKNode {
        let eye = SKNode()

        // 1. Pendar aura merah darah mistis
        let glow = SKShapeNode(circleOfRadius: 18)
        glow.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.15, alpha: 0.5)
        glow.strokeColor = .clear
        glow.blendMode = .add
        glow.zPosition = -1
        eye.addChild(glow)

        // 2. Bentuk kelopak mata bayangan tajam
        let socketPath = CGMutablePath()
        socketPath.move(to: CGPoint(x: -16, y: 0))
        socketPath.addQuadCurve(to: CGPoint(x: 16, y: 0), control: CGPoint(x: 0, y: 12))
        socketPath.addQuadCurve(to: CGPoint(x: -16, y: 0), control: CGPoint(x: 0, y: -12))
        socketPath.closeSubpath()

        let socket = SKShapeNode(path: socketPath)
        socket.fillColor = SKColor(red: 0.02, green: 0.0, blue: 0.02, alpha: 1.0)
        socket.strokeColor = SKColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 1.0)
        socket.lineWidth = 1.5
        eye.addChild(socket)

        // 3. Iris & Pupil merah menyala tajam
        let iris = SKShapeNode(ellipseOf: CGSize(width: 10, height: 10))
        iris.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.15, alpha: 1.0)
        iris.strokeColor = SKColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
        iris.lineWidth = 1.0
        eye.addChild(iris)

        let slit = SKShapeNode(ellipseOf: CGSize(width: 2.5, height: 9))
        slit.fillColor = .black
        slit.strokeColor = .clear
        eye.addChild(slit)

        // Animasi mata mengintimidasi
        glow.run(.repeatForever(.sequence([
            .scale(to: 1.4, duration: 0.4),
            .scale(to: 0.9, duration: 0.4)
        ])))

        return eye
    }

    // MARK: - Visual Setup

    private func buildVisuals() {
        addChild(container)

        // Fullscreen touch overlay
        let touchCatcher = SKSpriteNode(color: .clear, size: CGSize(width: 5000, height: 5000))
        touchCatcher.zPosition = -100
        container.addChild(touchCatcher)

        // Backdrop kabut ungu pekat
        backdrop.color = SKColor(red: 0.03, green: 0.0, blue: 0.04, alpha: 0.92)
        backdrop.size = CGSize(width: 5000, height: 5000)
        backdrop.zPosition = -90
        container.addChild(backdrop)

        // Mist Layer (Kabut melayang di background)
        mistLayer.zPosition = -80
        container.addChild(mistLayer)
        buildCreepingMist()

        // Atmosphere (Sulur bayangan di sekitar dial)
        atmosphereNode.zPosition = -70
        container.addChild(atmosphereNode)
        buildAtmosphere()

        let r = logic.config.radius

        // 1. Dial Ring Utama (Duri-Duri Hitam / Dark Brambles)
        // Shadow/Glow di bawah akar
        let brambleShadow = SKShapeNode(circleOfRadius: r)
        brambleShadow.strokeColor = SKColor(red: 0.3, green: 0.0, blue: 0.15, alpha: 0.4)
        brambleShadow.lineWidth = 12.0
        brambleShadow.fillColor = .clear
        brambleShadow.blendMode = .add
        brambleShadow.zPosition = 0.5
        container.addChild(brambleShadow)

        // Akar tebal 1
        let bramble1 = SKShapeNode(path: createDarkBramblePath(radius: r, variance: 2.0, addThorns: true))
        bramble1.strokeColor = SKColor(red: 0.05, green: 0.0, blue: 0.05, alpha: 1.0)
        bramble1.lineWidth = 6.0
        bramble1.zPosition = 1
        container.addChild(bramble1)

        // Akar tebal 2 bersilangan
        let bramble2 = SKShapeNode(path: createDarkBramblePath(radius: r, variance: 3.5, addThorns: true))
        bramble2.strokeColor = SKColor(red: 0.15, green: 0.0, blue: 0.1, alpha: 0.9)
        bramble2.lineWidth = 3.0
        bramble2.zPosition = 1.1
        container.addChild(bramble2)

        // 2. Containers Zona
        zoneGood.zPosition = 3
        container.addChild(zoneGood)

        zoneGreat.zPosition = 4
        container.addChild(zoneGreat)

        // 3. Jarum Penunjuk (Tulang Berdarah / Cursed Bone Spike)
        let needleHalfH: CGFloat = 24
        let needlePath = CGMutablePath()
        needlePath.move(to: CGPoint(x: -3.5, y: r - needleHalfH + 5))
        needlePath.addLine(to: CGPoint(x: 3.5, y: r - needleHalfH + 5))
        needlePath.addLine(to: CGPoint(x: 1.5, y: r + needleHalfH))
        needlePath.addLine(to: CGPoint(x: -1.5, y: r + needleHalfH))
        needlePath.closeSubpath()

        needle.path = needlePath
        needle.fillColor = SKColor(red: 0.8, green: 0.1, blue: 0.15, alpha: 1.0)
        needle.strokeColor = SKColor(red: 0.3, green: 0.0, blue: 0.05, alpha: 1.0)
        needle.lineWidth = 1.5
        needle.zPosition = 6
        
        // Ujung jarum menyala (neon darah)
        let needleGlow = SKShapeNode(circleOfRadius: 4.5)
        needleGlow.position = CGPoint(x: 0, y: r + needleHalfH - 3)
        needleGlow.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.8)
        needleGlow.strokeColor = .clear
        needleGlow.blendMode = .add
        needle.addChild(needleGlow)

        container.addChild(needle)

        // 4. Tombol Tengah (Plakat Batu Obsidian Rune Berdenyut)
        let promptW: CGFloat = 96
        let promptH: CGFloat = 34
        
        // Base luar
        let btnRect = CGRect(x: -promptW/2, y: -promptH/2, width: promptW, height: promptH)
        promptButton.path = CGPath(roundedRect: btnRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        promptButton.fillColor = SKColor(red: 0.05, green: 0.0, blue: 0.05, alpha: 1.0)
        promptButton.strokeColor = SKColor(red: 0.8, green: 0.1, blue: 0.2, alpha: 0.8)
        promptButton.lineWidth = 2.5
        promptButton.position = .zero
        promptButton.zPosition = 7
        promptButton.name = "qteTapButton"
        container.addChild(promptButton)
        
        // Inti dalam (Membara)
        let coreRect = CGRect(x: -(promptW/2) + 4, y: -(promptH/2) + 4, width: promptW - 8, height: promptH - 8)
        promptButtonCore.path = CGPath(roundedRect: coreRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        promptButtonCore.fillColor = SKColor(red: 0.2, green: 0.0, blue: 0.05, alpha: 0.9)
        promptButtonCore.strokeColor = .clear
        promptButtonCore.blendMode = .add
        promptButtonCore.zPosition = 7.1
        promptButtonCore.name = "qteTapButton"
        
        promptButtonCore.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.4, duration: 0.5),
            .fadeAlpha(to: 1.0, duration: 0.5)
        ])))
        container.addChild(promptButtonCore)

        // Label Tombol
        promptLabel.text = logic.config.buttonPrompt
        promptLabel.fontSize = 15
        promptLabel.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.85, alpha: 1.0)
        promptLabel.position = CGPoint(x: 0, y: -5.5)
        promptLabel.zPosition = 7.2
        promptLabel.name = "qteTapButton"
        container.addChild(promptLabel)

        // 5. Judul Mencekam di Atas
        headingLabel.text = "SERGAPAN THE HOLLOW!"
        headingLabel.fontSize = 22
        headingLabel.fontColor = SKColor(red: 1.0, green: 0.15, blue: 0.2, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: r + 45)
        headingLabel.zPosition = 8
        
        // Shadow judul
        let headingShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        headingShadow.text = headingLabel.text
        headingShadow.fontSize = 22
        headingShadow.fontColor = .black
        headingShadow.position = CGPoint(x: 1.5, y: -1.5)
        headingShadow.zPosition = -1
        headingLabel.addChild(headingShadow)
        
        container.addChild(headingLabel)
    }

    private func buildCreepingMist() {
        let colors = [
            SKColor(red: 0.25, green: 0.0, blue: 0.15, alpha: 0.15),
            SKColor(red: 0.15, green: 0.0, blue: 0.25, alpha: 0.2)
        ]
        
        for i in 0..<4 {
            let blob = SKShapeNode(circleOfRadius: CGFloat.random(in: 120...200))
            blob.fillColor = colors[i % 2]
            blob.strokeColor = .clear
            blob.blendMode = .screen
            blob.position = CGPoint(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -200...200))
            
            let move = SKAction.moveBy(x: CGFloat.random(in: -40...40), y: CGFloat.random(in: -25...25), duration: TimeInterval.random(in: 4...7))
            let scale = SKAction.scale(by: CGFloat.random(in: 1.1...1.3), duration: TimeInterval.random(in: 3...5))
            
            blob.run(.repeatForever(.sequence([move, move.reversed()])))
            blob.run(.repeatForever(.sequence([scale, scale.reversed()])))
            mistLayer.addChild(blob)
        }
    }

    private func buildAtmosphere() {
        // Sulur bayangan (Tentacles) bergerak di sekitar cincin
        for i in 0..<6 {
            let a = CGFloat(i) * (2 * .pi / 6.0)
            let tendril = SKShapeNode()
            let path = CGMutablePath()
            
            let rRoot: CGFloat = 220
            let rTip: CGFloat = 70
            
            let rootPt = CGPoint(x: cos(a) * rRoot, y: sin(a) * rRoot)
            let midPt = CGPoint(x: cos(a+0.3) * (rRoot - 70), y: sin(a+0.3) * (rRoot - 70))
            let tipPt = CGPoint(x: cos(a) * rTip, y: sin(a) * rTip)

            path.move(to: rootPt)
            path.addQuadCurve(to: tipPt, control: midPt)

            tendril.path = path
            tendril.strokeColor = SKColor(red: 0.05, green: 0.0, blue: 0.05, alpha: 0.8)
            tendril.lineWidth = 10.0
            tendril.lineCap = .round

            let sway = SKAction.sequence([
                .rotate(byAngle: 0.1, duration: TimeInterval.random(in: 1.0...1.5)),
                .rotate(byAngle: -0.2, duration: TimeInterval.random(in: 1.5...2.0)),
                .rotate(byAngle: 0.1, duration: TimeInterval.random(in: 1.0...1.5))
            ])
            tendril.run(.repeatForever(sway))
            atmosphereNode.addChild(tendril)
        }
    }

    private func updateZoneVisuals() {
        zoneGood.removeAllChildren()
        zoneGreat.removeAllChildren()

        let zone = logic.activeZone
        let r = logic.config.radius

        // --- ZONA GOOD (Kabut Violet Menyala) ---
        let mistArc = SKShapeNode(path: createArcPath(startProgress: zone.start, endProgress: zone.end, radius: r))
        mistArc.strokeColor = SKColor(red: 0.8, green: 0.2, blue: 0.5, alpha: 0.8)
        mistArc.lineWidth = 8.0
        mistArc.lineCap = .round
        mistArc.blendMode = .add
        zoneGood.addChild(mistArc)

        let arcLen = abs(zone.end - zone.start) * 2 * .pi * r
        let wispCount = max(3, Int(arcLen / 15.0))

        for i in 0...wispCount {
            let t = CGFloat(i) / CGFloat(wispCount)
            let curAngle = angle(for: zone.start + (zone.end - zone.start) * t)

            let wisp = createShadowWisp()
            let offsetR = r + CGFloat.random(in: -5...5)
            wisp.position = CGPoint(x: cos(curAngle) * offsetR, y: sin(curAngle) * offsetR)
            zoneGood.addChild(wisp)
        }

        // --- ZONA GREAT (Mata Merah Menyala The Hollow) ---
        if let gStart = zone.greatStart, let gEnd = zone.greatEnd {
            let greatBase = SKShapeNode(path: createArcPath(startProgress: gStart, endProgress: gEnd, radius: r))
            greatBase.strokeColor = SKColor(red: 1.0, green: 0.1, blue: 0.2, alpha: 1.0)
            greatBase.lineWidth = 4.0
            greatBase.blendMode = .add
            zoneGreat.addChild(greatBase)

            let centerProgress = (gStart + gEnd) / 2.0
            let curAngle = angle(for: centerProgress)

            let eye = createHollowEye()
            eye.position = CGPoint(x: cos(curAngle) * r, y: sin(curAngle) * r)
            eye.zRotation = curAngle + .pi / 2
            zoneGreat.addChild(eye)
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
            .fadeIn(withDuration: 0.2),
            .scale(to: 1.0, duration: 0.3).applyTimingMode(.easeOut)
        ]))

        // Gemetar panik judul
        headingLabel.run(.repeatForever(.sequence([
            .moveBy(x: -1.5, y: 1.0, duration: 0.04),
            .moveBy(x: 3.0, y: -2.0, duration: 0.08),
            .moveBy(x: -1.5, y: 1.0, duration: 0.04),
            .wait(forDuration: 0.05)
        ])), withKey: "terrorJitter")

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .heavy)
        #endif

        removeAction(forKey: "hollowQTEUpdateLoop")
        let loop = SKAction.customAction(withDuration: 100.0) { [weak self] _, elapsedTime in
            guard let self, self.isRunning else { return }
            let dt: TimeInterval = self.lastUpdateTime == 0 ? 1.0 / 60.0 : min(0.05, max(0.001, Double(elapsedTime) - self.lastUpdateTime))
            self.lastUpdateTime = Double(elapsedTime)

            let timeout = self.logic.update(deltaTime: dt)
            self.updateNeedleRotation()

            if timeout {
                self.handleTimeout()
            }
        }
        run(loop, withKey: "hollowQTEUpdateLoop")
    }

    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard isRunning && !logic.isCompleted else { return .miss }

        let outcome = logic.registerTap()

        // Squash & Stretch button feedback
        promptButton.run(.sequence([
            .scale(to: 0.85, duration: 0.04),
            .scale(to: 1.0, duration: 0.1).applyTimingMode(.easeOut)
        ]))
        promptButtonCore.run(.sequence([
            .scale(to: 0.75, duration: 0.04),
            .scale(to: 1.0, duration: 0.1).applyTimingMode(.easeOut)
        ]))

        switch outcome.result {
        case .great, .good:
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: outcome.result == .great ? .heavy : .medium)
            #endif
            flashDial(success: true, isGreat: outcome.result == .great)

            if !outcome.completed {
                // Good Hit -> Tahap 2 berbalik arah
                onStageSuccess?(1, outcome.result)
                updateZoneVisuals()
                
                // Guncangan kamera kecil saat berbalik arah
                container.run(.sequence([
                    .scale(to: 1.05, duration: 0.05),
                    .scale(to: 1.0, duration: 0.15)
                ]))
            } else {
                // Great Hit atau Selesai Tahap 2
                isRunning = false
                removeAction(forKey: "hollowQTEUpdateLoop")
                headingLabel.removeAction(forKey: "terrorJitter")
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
        removeAction(forKey: "hollowQTEUpdateLoop")
        headingLabel.removeAction(forKey: "terrorJitter")
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
            flashColor = SKColor(red: 1.0, green: 0.0, blue: 0.1, alpha: 0.9) // Gagal = Merah darah ledakan
        } else if isGreat {
            flashColor = SKColor(red: 0.8, green: 1.0, blue: 0.9, alpha: 1.0) // Great = Cahaya putih purifying mengusir kabut
        } else {
            flashColor = SKColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 0.8) // Good = Benturan ungu magis
        }

        let flashRing = SKShapeNode(path: createDarkBramblePath(radius: logic.config.radius, variance: 4.0, addThorns: true))
        flashRing.fillColor = success ? flashColor.withAlphaComponent(0.2) : .clear
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
            .moveBy(x: -8, y: -5, duration: 0.03),
            .moveBy(x: 16, y: 10, duration: 0.06),
            .moveBy(x: -12, y: -7, duration: 0.05),
            .moveBy(x: 8, y: 4, duration: 0.04),
            .moveTo(x: 0, duration: 0.03)
        ])
        container.run(shake)
    }

    private func finishEvent(isSuccess: Bool) {
        onComplete?(isSuccess)
        
        if isSuccess {
            headingLabel.text = "LOLOS!"
            headingLabel.fontColor = SKColor(red: 0.4, green: 0.95, blue: 0.6, alpha: 1.0)
            
            // Sulur dan kabut menjauh karena kalah
            atmosphereNode.run(.group([.scale(to: 0.5, duration: 0.5), .fadeOut(withDuration: 0.5)]))
        } else {
            headingLabel.text = "TERTANGKAP..."
            headingLabel.fontColor = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
            
            // Layar ditelan kegelapan
            let loseDarkness = SKSpriteNode(color: .black, size: CGSize(width: 5000, height: 5000))
            loseDarkness.alpha = 0
            loseDarkness.zPosition = 100
            container.addChild(loseDarkness)
            loseDarkness.run(.fadeAlpha(to: 1.0, duration: 0.3))
        }
        
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
        removeAction(forKey: "hollowQTEUpdateLoop")
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

#Preview("Hollow QTE 2-Stage Dial") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.04, green: 0.015, blue: 0.04, alpha: 1.0)

        func spawn() {
            let qte = HollowQuickTimeEventNode(config: QuickTimeEventConfig(
                radius: 82,
                stage1Duration: 1.25,
                stage2Duration: 1.05,
                stage1Zone: QTETargetZone(start: 0.58, end: 0.84, greatStart: 0.70, greatEnd: 0.74),
                stage2Zone: QTETargetZone(start: 0.20, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
                buttonPrompt: "LARI!",
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
