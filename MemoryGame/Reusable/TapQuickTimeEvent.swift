// Penjelasan file: TapQuickTimeEvent.swift
// Komponen Quick Time Event (QTE) berbasis Ketukan Cepat (Button Mashing / Tap-Tap).
// Memiliki 2 Varian Style:
// 1. .classic: Bergaya storybook/Carto hangat (kayu, abu, ember pulse) untuk aksi desa seperti mengangkat rak atau lari biasa.
// 2. .hollowChase: Bergaya horor/mencekam (agak serem) karena dikejar The Hollow: kabut pekat, mata merah menyala, sulur bayangan merayap, getaran panik, dan rune kegelapan.

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration & Data Types

public enum TapQTEStyle: String, Sendable {
    /// Style 1: Classic Carto / Storybook hangat (seperti versi awal)
    case classic
    /// Style 2: Horor mencekam dikejar The Hollow (kabut hitam, mata merah, sulur bayangan)
    case hollowChase
}

public struct TapQuickTimeEventConfig: Sendable {
    public var requiredTaps: Int
    public var buttonPrompt: String
    public var heading: String
    public var instruction: String
    public var style: TapQTEStyle
    public var allowTouchAnywhere: Bool
    public var autoDismissDelay: TimeInterval
    public var decayPerSecond: CGFloat // Penurunan progres jika pemain berhenti mengetuk (khusus chase)

    public init(
        requiredTaps: Int = 16,
        buttonPrompt: String = "TAP",
        heading: String? = nil,
        instruction: String? = nil,
        style: TapQTEStyle = .classic,
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 0.8,
        decayPerSecond: CGFloat = 0.0
    ) {
        self.requiredTaps = max(1, requiredTaps)
        self.buttonPrompt = buttonPrompt
        self.style = style
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
        self.decayPerSecond = decayPerSecond

        if let heading = heading {
            self.heading = heading
        } else {
            self.heading = style == .hollowChase ? "LARI DARI THE HOLLOW!" : "LARI!"
        }

        if let instruction = instruction {
            self.instruction = instruction
        } else {
            self.instruction = style == .hollowChase
                ? (allowTouchAnywhere ? "DIA MENDEKAT... KETUK CEPAT LAYAR!" : "KETUK TOMBOL DENGAN CEPAT!")
                : (allowTouchAnywhere ? "KETUK LAYAR TERUS!" : "KETUK CEPAT BERULANG KALI!")
        }
    }
}

public struct TapQuickTimeEventLogic {
    public let config: TapQuickTimeEventConfig
    public private(set) var tapCount: Int = 0
    public private(set) var currentProgress: CGFloat = 0.0
    public private(set) var isCompleted: Bool = false
    public private(set) var isSuccess: Bool = false

    public init(config: TapQuickTimeEventConfig = TapQuickTimeEventConfig()) {
        self.config = config
        self.tapCount = 0
        self.currentProgress = 0.0
    }

    public mutating func registerTap() -> (result: QTEHitResult, completed: Bool, isSuccess: Bool) {
        guard !isCompleted else { return (.miss, true, isSuccess) }

        tapCount += 1
        currentProgress = min(1.0, CGFloat(tapCount) / CGFloat(config.requiredTaps))

        if tapCount >= config.requiredTaps {
            isCompleted = true
            isSuccess = true
            return (.great, true, true)
        }
        return (.good, false, false)
    }

    public mutating func update(deltaTime: TimeInterval) {
        guard !isCompleted && config.decayPerSecond > 0 else { return }
        let decay = config.decayPerSecond * CGFloat(deltaTime)
        currentProgress = max(0.0, currentProgress - decay)
        tapCount = Int(currentProgress * CGFloat(config.requiredTaps))
    }
}

// MARK: - SpriteKit Node: TapQuickTimeEventNode

public final class TapQuickTimeEventNode: SKNode {

    public var onProgress: ((_ current: Int, _ total: Int) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?

    private var logic: TapQuickTimeEventLogic
    private var isRunning: Bool = false
    private var lastUpdateTime: TimeInterval = 0

    // Hierarchy nodes
    private let container = SKNode()
    private let shieldNode = SKSpriteNode()
    private let atmosphereNode = SKNode()
    private let button = SKShapeNode()
    private let buttonCore = SKShapeNode()
    private let progressTrack = SKShapeNode()
    private let progressBar = SKShapeNode()
    private let pulseRing = SKShapeNode(circleOfRadius: 62)
    private let promptLabel = SKLabelNode()
    private let headingLabel = SKLabelNode()
    private let instructionLabel = SKLabelNode()
    private let statusBanner = SKLabelNode()

    // Hollow Chase specific nodes
    private var shadowTendrils: [SKNode] = []
    private var hollowEyesNode: SKNode?

    public init(config: TapQuickTimeEventConfig = TapQuickTimeEventConfig()) {
        self.logic = TapQuickTimeEventLogic(config: config)
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 800
        buildVisuals()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual Setup

    private func buildVisuals() {
        addChild(container)

        // 1. Fullscreen Touch Catcher & Dark Shield
        let shieldColor = logic.config.style == .hollowChase
            ? SKColor(red: 0.04, green: 0.015, blue: 0.045, alpha: 0.88) // Hitam keunguan mencekam
            : SKColor(red: 0.03, green: 0.02, blue: 0.02, alpha: 0.82)  // Hitam arang storybook
        shieldNode.color = shieldColor
        shieldNode.size = CGSize(width: 5000, height: 5000)
        shieldNode.zPosition = -10
        container.addChild(shieldNode)

        // 2. Efek Atmosferik (Khusus Hollow Chase: Kabut Merayap & Mata Merah)
        container.addChild(atmosphereNode)
        atmosphereNode.zPosition = -5
        if logic.config.style == .hollowChase {
            buildHollowChaseAtmosphere()
        }

        // 3. Tombol Tap Utama
        buildTapButton()

        // 4. Bar / Lingkaran Kemajuan (Progress Track)
        buildProgressBar()

        // 5. Label Judul & Petunjuk
        buildLabels()
    }

    private func buildTapButton() {
        let isHollow = logic.config.style == .hollowChase

        // Lingkaran Denyut Luar (Pulse Ring)
        let pulseColor = isHollow
            ? SKColor(red: 0.85, green: 0.15, blue: 0.25, alpha: 0.6) // Merah darah Hollow
            : SKColor(red: 0.82, green: 0.74, blue: 0.60, alpha: 0.5) // Ash klasik
        pulseRing.path = CGPath(ellipseIn: CGRect(x: -62, y: -62, width: 124, height: 124), transform: nil)
        pulseRing.strokeColor = pulseColor
        pulseRing.lineWidth = isHollow ? 3.0 : 2.0
        pulseRing.fillColor = .clear
        pulseRing.zPosition = 1
        container.addChild(pulseRing)

        // Tombol Utama (Button Frame)
        let buttonRadius: CGFloat = 54
        button.path = CGPath(ellipseIn: CGRect(x: -buttonRadius, y: -buttonRadius, width: buttonRadius * 2, height: buttonRadius * 2), transform: nil)
        button.zPosition = 4
        button.name = "qteTapButton"

        if isHollow {
            // Gaya Rune Kegelapan: Hitam jurang berbingkai crimson menyala
            button.fillColor = SKColor(red: 0.12, green: 0.04, blue: 0.10, alpha: 0.95)
            button.strokeColor = SKColor(red: 0.90, green: 0.20, blue: 0.25, alpha: 0.95)
            button.lineWidth = 4.5

            // Inti Rune Void di tengah
            buttonCore.path = CGPath(ellipseIn: CGRect(x: -36, y: -36, width: 72, height: 72), transform: nil)
            buttonCore.fillColor = SKColor(red: 0.22, green: 0.05, blue: 0.16, alpha: 0.75)
            buttonCore.strokeColor = SKColor(red: 0.75, green: 0.10, blue: 0.35, alpha: 0.6)
            buttonCore.lineWidth = 2.0
            buttonCore.zPosition = 4.1
            buttonCore.name = "qteTapButton"
            container.addChild(buttonCore)
        } else {
            // Gaya Klasik: Kayu arang berbingkai abu hangat
            button.fillColor = SKColor(red: 0.14, green: 0.11, blue: 0.09, alpha: 0.95)
            button.strokeColor = SKColor(red: 0.82, green: 0.74, blue: 0.60, alpha: 1.0)
            button.lineWidth = 4.0
        }
        container.addChild(button)

        // Teks Tombol (Prompt)
        promptLabel.text = logic.config.buttonPrompt
        promptLabel.fontName = isHollow ? "AvenirNext-Heavy" : "Georgia-Bold"
        promptLabel.fontSize = isHollow ? 24 : 22
        promptLabel.fontColor = isHollow
            ? SKColor(red: 1.0, green: 0.85, blue: 0.85, alpha: 1.0)
            : SKColor(red: 0.86, green: 0.80, blue: 0.68, alpha: 1.0)
        promptLabel.verticalAlignmentMode = .center
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.position = .zero
        promptLabel.zPosition = 5
        promptLabel.name = "qteTapButton"
        container.addChild(promptLabel)
    }

    private func buildProgressBar() {
        // Cincin Progres di sekeliling tombol (Radius 68)
        let r: CGFloat = 68
        let circlePath = CGMutablePath()
        circlePath.addArc(center: .zero, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: false)

        progressTrack.path = circlePath
        progressTrack.strokeColor = logic.config.style == .hollowChase
            ? SKColor(red: 0.25, green: 0.08, blue: 0.20, alpha: 0.5)
            : SKColor(red: 0.30, green: 0.26, blue: 0.22, alpha: 0.5)
        progressTrack.lineWidth = 5.0
        progressTrack.fillColor = .clear
        progressTrack.zPosition = 3
        container.addChild(progressTrack)

        progressBar.strokeColor = logic.config.style == .hollowChase
            ? SKColor(red: 1.0, green: 0.22, blue: 0.28, alpha: 1.0) // Merah Crimson menyala
            : SKColor(red: 0.88, green: 0.68, blue: 0.24, alpha: 1.0) // Emas hangat klasik
        progressBar.lineWidth = 5.5
        progressBar.lineCap = .round
        progressBar.fillColor = .clear
        progressBar.zPosition = 3.1
        container.addChild(progressBar)

        updateProgressBar()
    }

    private func updateProgressBar() {
        let p = logic.currentProgress
        guard p > 0.01 else {
            progressBar.path = nil
            return
        }
        let r: CGFloat = 68
        let startAngle: CGFloat = .pi / 2
        let endAngle = startAngle - (p * 2 * .pi)

        let arcPath = CGMutablePath()
        arcPath.addArc(center: .zero, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressBar.path = arcPath
    }

    private func buildLabels() {
        let isHollow = logic.config.style == .hollowChase

        // Judul Utama (Heading)
        headingLabel.text = logic.config.heading
        headingLabel.fontName = isHollow ? "AvenirNext-Heavy" : "Georgia-Bold"
        headingLabel.fontSize = isHollow ? 28 : 30
        headingLabel.fontColor = isHollow
            ? SKColor(red: 1.0, green: 0.25, blue: 0.28, alpha: 1.0) // Merah darah menyala
            : SKColor(red: 0.88, green: 0.82, blue: 0.70, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: 105)
        headingLabel.zPosition = 6
        container.addChild(headingLabel)

        // Subtitle / Instruksi
        instructionLabel.text = logic.config.instruction
        instructionLabel.fontName = "AvenirNext-Medium"
        instructionLabel.fontSize = 14
        instructionLabel.fontColor = isHollow
            ? SKColor(red: 0.85, green: 0.65, blue: 0.75, alpha: 0.9)
            : SKColor(red: 0.75, green: 0.70, blue: 0.62, alpha: 0.85)
        instructionLabel.position = CGPoint(x: 0, y: -98)
        instructionLabel.zPosition = 6
        container.addChild(instructionLabel)

        // Banner Status Akhir
        statusBanner.fontName = "AvenirNext-Bold"
        statusBanner.fontSize = 15
        statusBanner.fontColor = .white
        statusBanner.position = CGPoint(x: 0, y: -125)
        statusBanner.zPosition = 6
        statusBanner.alpha = 0
        container.addChild(statusBanner)
    }

    // MARK: - Hollow Chase Atmosphere (Horor Dikejar The Hollow)

    private func buildHollowChaseAtmosphere() {
        // 1. Mata Merah Menyala The Hollow di Balik Kabut Atas
        let eyesContainer = SKNode()
        eyesContainer.position = CGPoint(x: 0, y: 155)

        func makeEye(isLeft: Bool) -> SKNode {
            let eyeNode = SKNode()
            let s: CGFloat = isLeft ? -1 : 1

            // Pendar aura merah redup
            let eyeGlow = SKShapeNode(ellipseOf: CGSize(width: 22, height: 12))
            eyeGlow.fillColor = SKColor(red: 0.95, green: 0.1, blue: 0.15, alpha: 0.35)
            eyeGlow.strokeColor = .clear
            eyeGlow.position = CGPoint(x: 18 * s, y: 0)
            eyeNode.addChild(eyeGlow)

            // Titik pupil merah menyala tajam
            let pupil = SKShapeNode(ellipseOf: CGSize(width: 10, height: 4.5))
            pupil.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 0.95)
            pupil.strokeColor = SKColor(red: 0.95, green: 0.15, blue: 0.2, alpha: 1.0)
            pupil.lineWidth = 1.0
            pupil.position = CGPoint(x: 18 * s, y: 0)
            pupil.zRotation = (isLeft ? 0.2 : -0.2)
            eyeNode.addChild(pupil)

            return eyeNode
        }

        let leftEye = makeEye(isLeft: true)
        let rightEye = makeEye(isLeft: false)
        eyesContainer.addChild(leftEye)
        eyesContainer.addChild(rightEye)

        // Animasi kedipan mengintai Hollow
        eyesContainer.run(.repeatForever(.sequence([
            .wait(forDuration: 2.2),
            .scaleY(to: 0.1, duration: 0.08),
            .scaleY(to: 1.0, duration: 0.12),
            .wait(forDuration: 3.5),
            .group([
                .fadeAlpha(to: 0.4, duration: 0.2),
                .moveBy(x: 4, y: -2, duration: 0.2)
            ]),
            .group([
                .fadeAlpha(to: 1.0, duration: 0.3),
                .moveBy(x: -4, y: 2, duration: 0.3)
            ])
        ])))
        atmosphereNode.addChild(eyesContainer)
        self.hollowEyesNode = eyesContainer

        // 2. Sulur Bayangan Menyeramkan di Pinggir Layar (Shadow Tendrils)
        let tendrilCount = 6
        for i in 0..<tendrilCount {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(tendrilCount)) + CGFloat.random(in: -0.2...0.2)
            let distance: CGFloat = 190

            let tendril = SKShapeNode()
            let path = CGMutablePath()
            let rootPt = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            let midPt = CGPoint(x: cos(angle) * (distance - 45) + CGFloat.random(in: -15...15),
                                y: sin(angle) * (distance - 45) + CGFloat.random(in: -15...15))
            let tipPt = CGPoint(x: cos(angle) * (distance - 85), y: sin(angle) * (distance - 85))

            path.move(to: rootPt)
            path.addQuadCurve(to: midPt, control: CGPoint(x: rootPt.x + 20, y: rootPt.y - 10))
            path.addQuadCurve(to: tipPt, control: midPt)

            tendril.path = path
            tendril.strokeColor = SKColor(red: 0.15, green: 0.05, blue: 0.18, alpha: 0.6)
            tendril.lineWidth = 4.0
            tendril.lineCap = .round

            // Animasi merayap maju-mundur halus
            let sway = SKAction.sequence([
                .scale(to: 1.15, duration: Double.random(in: 0.6...0.9)),
                .scale(to: 0.95, duration: Double.random(in: 0.6...0.9))
            ])
            tendril.run(.repeatForever(sway))

            atmosphereNode.addChild(tendril)
            shadowTendrils.append(tendril)
        }
    }

    // MARK: - Lifecycle & Actions

    public func start() {
        guard !isRunning && !logic.isCompleted else { return }
        isRunning = true
        lastUpdateTime = 0

        container.setScale(0.88)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.18),
            .scale(to: 1.0, duration: 0.18)
        ]))

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: logic.config.style == .hollowChase ? .heavy : .medium)
        #endif

        // Animasi Denyut Tombol (Mash Pulse)
        let isHollow = logic.config.style == .hollowChase
        let pulseDuration = isHollow ? 0.32 : 0.45 // Hollow berdenyut cepat seperti detak jantung panik
        pulseRing.run(.repeatForever(.sequence([
            .group([
                .scale(to: 1.35, duration: pulseDuration),
                .fadeOut(withDuration: pulseDuration)
            ]),
            .scale(to: 1.0, duration: 0),
            .fadeIn(withDuration: 0)
        ])), withKey: "mashPulse")

        // Hollow Chase Jitter (Getaran Mencekam)
        if isHollow {
            headingLabel.run(.repeatForever(.sequence([
                .moveBy(x: -1.5, y: 0.5, duration: 0.04),
                .moveBy(x: 3.0, y: -1.0, duration: 0.08),
                .moveBy(x: -1.5, y: 0.5, duration: 0.04)
            ])), withKey: "terrorJitter")
        }

        // Loop Update jika ada Decay (Penurunan progres jika berhenti mengetuk)
        if logic.config.decayPerSecond > 0 {
            removeAction(forKey: "qteDecayLoop")
            let decayAction = SKAction.customAction(withDuration: 120.0) { [weak self] _, elapsedTime in
                guard let self, self.isRunning else { return }
                let dt: TimeInterval = self.lastUpdateTime == 0 ? 0.016 : min(0.05, Double(elapsedTime) - self.lastUpdateTime)
                self.lastUpdateTime = Double(elapsedTime)

                self.logic.update(deltaTime: dt)
                self.updateProgressBar()
            }
            run(decayAction, withKey: "qteDecayLoop")
        }
    }

    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard isRunning && !logic.isCompleted else { return .miss }

        let outcome = logic.registerTap()
        updateProgressBar()
        onProgress?(logic.tapCount, logic.config.requiredTaps)

        let isHollow = logic.config.style == .hollowChase

        // Haptic Feedback
        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: isHollow ? .medium : .light)
        #endif

        // Animasi Tekanan Tombol Membal (Punchy Tap Animation)
        button.removeAction(forKey: "btnPress")
        button.run(.sequence([
            .scale(to: 0.91, duration: 0.03),
            .scale(to: 1.0, duration: 0.07)
        ]), withKey: "btnPress")

        if isHollow {
            buttonCore.removeAction(forKey: "corePress")
            buttonCore.run(.sequence([
                .scale(to: 0.85, duration: 0.03),
                .scale(to: 1.0, duration: 0.07)
            ]), withKey: "corePress")

            // Efek panik: Layar sedikit bergetar setiap kali mengetuk
            container.run(.sequence([
                .moveBy(x: CGFloat.random(in: -3...3), y: CGFloat.random(in: -2...2), duration: 0.02),
                .moveTo(x: 0, duration: 0.02)
            ]))
        }

        if outcome.completed {
            finishEvent(isSuccess: outcome.isSuccess)
        }

        return outcome.result
    }

    private func finishEvent(isSuccess: Bool) {
        guard isRunning else { return }
        isRunning = false
        removeAction(forKey: "qteDecayLoop")
        pulseRing.removeAllActions()
        pulseRing.isHidden = true
        headingLabel.removeAction(forKey: "terrorJitter")

        let isHollow = logic.config.style == .hollowChase

        #if canImport(UIKit)
        HapticsService.shared.playNotification(isSuccess ? .success : .error)
        #endif

        if isSuccess {
            headingLabel.text = isHollow ? "LOLOS DARI THE HOLLOW!" : "LOLOS!"
            headingLabel.fontColor = SKColor(red: 0.35, green: 0.95, blue: 0.45, alpha: 1.0)
            promptLabel.text = "BERHASIL"
            instructionLabel.text = isHollow ? "Kabut tebal menipis. Arthur berhasil menjaga jarak!" : "Kamu berhasil lolos tepat waktu."

            // Flash Keberhasilan
            let winGlow = SKShapeNode(circleOfRadius: 85)
            winGlow.fillColor = isHollow
                ? SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.5)
                : SKColor(red: 0.88, green: 0.75, blue: 0.35, alpha: 0.5)
            winGlow.strokeColor = .clear
            winGlow.zPosition = 2
            container.addChild(winGlow)
            winGlow.run(.sequence([
                .group([.scale(to: 1.4, duration: 0.3), .fadeOut(withDuration: 0.3)]),
                .removeFromParent()
            ]))
        } else {
            headingLabel.text = isHollow ? "TERKEPUNG KABUT..." : "TERLAMBAT"
            headingLabel.fontColor = SKColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1.0)
            promptLabel.text = "GAGAL"
            instructionLabel.text = isHollow ? "Sosok The Hollow semakin mendekat..." : "Kamu tertangkap."
        }

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
        removeAction(forKey: "qteDecayLoop")
        removeAllActions()
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

#Preview("TapQTE · Classic Village Style") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0)

        func spawnClassic() {
            let qte = TapQuickTimeEventNode(config: TapQuickTimeEventConfig(
                requiredTaps: 14,
                buttonPrompt: "ANGKAT",
                heading: "ANGKAT RAK!",
                instruction: "KETUK LAYAR CEPAT UNTUK MENEGAKKAN RAK!",
                style: .classic,
                allowTouchAnywhere: true,
                autoDismissDelay: 0.8
            ))
            qte.position = CGPoint(x: 250, y: 300)
            qte.onDismiss = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    spawnClassic()
                }
            }
            scene.addChild(qte)
            qte.start()
        }

        spawnClassic()
        return scene
    }())
    .ignoresSafeArea()
}

#Preview("TapQTE · Hollow Chase (Serem)") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.05, green: 0.02, blue: 0.05, alpha: 1.0)

        func spawnHollow() {
            let qte = TapQuickTimeEventNode(config: TapQuickTimeEventConfig(
                requiredTaps: 18,
                buttonPrompt: "LARI!",
                heading: "LARI DARI THE HOLLOW!",
                instruction: "DIA MENDEKAT DARI KABUT... KETUK CEPAT!",
                style: .hollowChase,
                allowTouchAnywhere: true,
                autoDismissDelay: 0.8,
                decayPerSecond: 0.12 // Sedikit decay agar terasa dikejar
            ))
            qte.position = CGPoint(x: 250, y: 300)
            qte.onDismiss = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    spawnHollow()
                }
            }
            scene.addChild(qte)
            qte.start()
        }

        spawnHollow()
        return scene
    }())
    .ignoresSafeArea()
}
#endif
