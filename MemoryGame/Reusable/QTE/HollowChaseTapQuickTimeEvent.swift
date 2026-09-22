// Penjelasan file: HollowChaseTapQuickTimeEvent.swift
// Komponen Quick Time Event (QTE) Ketukan Cepat (Button Mashing) Khusus Dikejar The Hollow.
// Visual Upgrade:
// - Procedural Mist/Kabut yang melayang di background.
// - Mata The Hollow dengan efek Additive Glow (menyala dalam gelap).
// - Sulur (Tendrils) bayangan hitam pekat yang meliuk organik.
// - Tombol Abyssal berdarah dengan efek detak jantung dan getaran panik.

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration & Data Types

public struct HollowChaseTapConfig: Sendable {
    public var requiredTaps: Int
    public var buttonPrompt: String
    public var heading: String
    public var instruction: String
    public var decayPerSecond: CGFloat
    public var allowTouchAnywhere: Bool
    public var autoDismissDelay: TimeInterval

    public init(
        requiredTaps: Int = 18,
        buttonPrompt: String = "LARI!",
        heading: String = "LARI DARI THE HOLLOW!",
        instruction: String = "DIA MENDEKAT DARI BALIK KABUT... KETUK CEPAT!",
        decayPerSecond: CGFloat = 0.12,
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 0.8
    ) {
        self.requiredTaps = max(1, requiredTaps)
        self.buttonPrompt = buttonPrompt
        self.heading = heading
        self.instruction = instruction
        self.decayPerSecond = decayPerSecond
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
    }
}

// MARK: - SpriteKit Node: HollowChaseTapQuickTimeEventNode

public final class HollowChaseTapQuickTimeEventNode: SKNode {

    public var onProgress: ((_ current: Int, _ total: Int) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?

    public var config: HollowChaseTapConfig
    public private(set) var tapCount: Int = 0
    public private(set) var currentProgress: CGFloat = 0.0
    public private(set) var isCompleted: Bool = false
    public private(set) var isSuccess: Bool = false

    private var isRunning: Bool = false
    private var lastUpdateTime: TimeInterval = 0

    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    private let mistLayer = SKNode()
    private let atmosphereNode = SKNode()
    private let button = SKShapeNode()
    private let buttonCore = SKShapeNode()
    private let progressRing = SKShapeNode()
    private let pulseRing = SKShapeNode(circleOfRadius: 65)
    private let promptLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let headingLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")

    public init(config: HollowChaseTapConfig = HollowChaseTapConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 850
        buildVisuals()
        updateProgressArc()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual Setup

    private func buildVisuals() {
        addChild(container)

        // 1. Fullscreen Dark Vignette (Hitam Keunguan Mencekam)
        backdrop.color = SKColor(red: 0.02, green: 0.0, blue: 0.03, alpha: 0.95)
        backdrop.size = CGSize(width: 5000, height: 5000)
        backdrop.zPosition = -10
        container.addChild(backdrop)

        // 2. Mist Layer (Kabut bergerak prosedural)
        mistLayer.zPosition = -8
        container.addChild(mistLayer)
        buildCreepingMist()

        // 3. Atmosfer Horor (Mata & Sulur)
        atmosphereNode.zPosition = -5
        container.addChild(atmosphereNode)
        buildAtmosphere()

        // 4. Cincin Denyut Merah Darah (Heartbeat Pulse) - Additive Blend
        pulseRing.strokeColor = SKColor(red: 0.95, green: 0.10, blue: 0.20, alpha: 0.8)
        pulseRing.lineWidth = 6.0
        pulseRing.fillColor = .clear
        pulseRing.blendMode = .add
        pulseRing.zPosition = 1
        container.addChild(pulseRing)

        // 5. Tombol Rune Kegelapan (Abyssal Void Button)
        let r: CGFloat = 60
        // Cincin luar bergerigi/tajam (Ilusi korupsi)
        let outerPath = CGMutablePath()
        for i in 0..<36 {
            let angle = CGFloat(i) * (2 * .pi / 36)
            let radiusVariation = i % 2 == 0 ? r : r - 4
            let pt = CGPoint(x: cos(angle) * radiusVariation, y: sin(angle) * radiusVariation)
            if i == 0 { outerPath.move(to: pt) } else { outerPath.addLine(to: pt) }
        }
        outerPath.closeSubpath()
        
        button.path = outerPath
        button.fillColor = SKColor(red: 0.05, green: 0.0, blue: 0.08, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.8, green: 0.1, blue: 0.2, alpha: 0.9)
        button.lineWidth = 3.0
        button.zPosition = 4
        button.name = "hollowChaseTapButton"
        container.addChild(button)

        // Inti Tombol Membara
        let coreR: CGFloat = 45
        buttonCore.path = CGPath(ellipseIn: CGRect(x: -coreR, y: -coreR, width: coreR * 2, height: coreR * 2), transform: nil)
        buttonCore.fillColor = SKColor(red: 0.15, green: 0.0, blue: 0.05, alpha: 0.9)
        buttonCore.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.5)
        buttonCore.lineWidth = 4.0
        buttonCore.blendMode = .add
        buttonCore.zPosition = 4.1
        buttonCore.name = "hollowChaseTapButton"
        container.addChild(buttonCore)

        // 6. Cincin Progres Crimson Menyala
        progressRing.lineWidth = 8.0
        progressRing.strokeColor = SKColor(red: 1.0, green: 0.15, blue: 0.25, alpha: 1.0)
        progressRing.lineCap = .round
        progressRing.fillColor = .clear
        progressRing.blendMode = .add
        progressRing.zPosition = 5
        container.addChild(progressRing)

        // Track Ring gelap
        let trackRing = SKShapeNode(circleOfRadius: r + 12)
        trackRing.strokeColor = SKColor(red: 0.2, green: 0.0, blue: 0.05, alpha: 0.8)
        trackRing.lineWidth = 8.0
        trackRing.fillColor = .clear
        trackRing.zPosition = 2.9
        container.addChild(trackRing)

        // 7. Label & Teks dengan Shadow/Glow
        promptLabel.text = config.buttonPrompt
        promptLabel.fontSize = 24
        promptLabel.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.85, alpha: 1.0)
        promptLabel.verticalAlignmentMode = .center
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.position = .zero
        promptLabel.zPosition = 6
        promptLabel.name = "hollowChaseTapButton"
        
        let promptShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        promptShadow.text = config.buttonPrompt
        promptShadow.fontSize = 24
        promptShadow.fontColor = .black
        promptShadow.verticalAlignmentMode = .center
        promptShadow.horizontalAlignmentMode = .center
        promptShadow.position = CGPoint(x: 1.5, y: -1.5)
        promptShadow.zPosition = -1
        promptLabel.addChild(promptShadow)
        container.addChild(promptLabel)

        headingLabel.text = config.heading
        headingLabel.fontSize = 26
        headingLabel.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: 125)
        headingLabel.zPosition = 6
        container.addChild(headingLabel)

        instructionLabel.text = config.instruction
        instructionLabel.fontSize = 13
        instructionLabel.fontColor = SKColor(red: 0.7, green: 0.6, blue: 0.65, alpha: 0.9)
        instructionLabel.position = CGPoint(x: 0, y: -110)
        instructionLabel.zPosition = 6
        container.addChild(instructionLabel)
    }

    private func buildCreepingMist() {
        // Membuat gumpalan kabut ungu gelap yang melayang
        let colors = [
            SKColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 0.15),
            SKColor(red: 0.10, green: 0.0, blue: 0.15, alpha: 0.2)
        ]
        
        for i in 0..<4 {
            let blob = SKShapeNode(circleOfRadius: CGFloat.random(in: 150...250))
            blob.fillColor = colors[i % 2]
            blob.strokeColor = .clear
            blob.blendMode = .screen
            blob.position = CGPoint(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -200...200))
            
            // Animasi melayang prosedural
            let move = SKAction.moveBy(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -30...30), duration: TimeInterval.random(in: 4...7))
            let rev = move.reversed()
            let scale = SKAction.scale(by: CGFloat.random(in: 1.1...1.3), duration: TimeInterval.random(in: 3...5))
            let scaleRev = scale.reversed()
            
            blob.run(.repeatForever(.sequence([move, rev])))
            blob.run(.repeatForever(.sequence([scale, scaleRev])))
            
            mistLayer.addChild(blob)
        }
    }

    private func buildAtmosphere() {
        // Mata Merah Menyala The Hollow di Kabut Atas
        let eyes = SKNode()
        eyes.position = CGPoint(x: 0, y: 175)

        for isLeft in [true, false] {
            let s: CGFloat = isLeft ? -1 : 1
            
            // Outer Glow (Additive)
            let glow = SKShapeNode(ellipseOf: CGSize(width: 45, height: 20))
            glow.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.1, alpha: 0.25)
            glow.strokeColor = .clear
            glow.blendMode = .add
            glow.position = CGPoint(x: 22 * s, y: 0)
            eyes.addChild(glow)

            // Inner Eye
            let eyeShape = SKShapeNode(ellipseOf: CGSize(width: 18, height: 8))
            eyeShape.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.9)
            eyeShape.strokeColor = SKColor(red: 0.8, green: 0.0, blue: 0.1, alpha: 1.0)
            eyeShape.lineWidth = 1.0
            eyeShape.position = CGPoint(x: 22 * s, y: 0)
            eyeShape.zRotation = isLeft ? 0.15 : -0.15
            eyes.addChild(eyeShape)

            // Slit Pupil (Mata kucing iblis)
            let pupil = SKShapeNode(ellipseOf: CGSize(width: 2.5, height: 7.5))
            pupil.fillColor = .black
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: 22 * s, y: 0)
            pupil.zRotation = isLeft ? 0.15 : -0.15
            eyes.addChild(pupil)
        }

        // Animasi menatap dan mengintimidasi (Mengecil tajam lalu membesar)
        eyes.run(.repeatForever(.sequence([
            .wait(forDuration: 2.0),
            .group([.scaleY(to: 0.2, duration: 0.1), .scaleX(to: 1.2, duration: 0.1)]),
            .group([.scaleY(to: 1.0, duration: 0.15), .scaleX(to: 1.0, duration: 0.15)]),
            .wait(forDuration: 0.5),
            .scale(to: 1.05, duration: 0.5),
            .scale(to: 1.0, duration: 0.5)
        ])))
        atmosphereNode.addChild(eyes)

        // 8 Sulur Bayangan Menyeramkan (Tentacles of Mist)
        for i in 0..<8 {
            let a = CGFloat(i) * (2 * .pi / 8.0)
            let tendril = SKShapeNode()
            let path = CGMutablePath()
            
            let rRoot: CGFloat = 280
            let rTip: CGFloat = 85
            
            let rootPt = CGPoint(x: cos(a) * rRoot, y: sin(a) * rRoot)
            // Sulur dibuat lebih bergelombang
            let midPt1 = CGPoint(x: cos(a+0.2) * (rRoot - 60), y: sin(a+0.2) * (rRoot - 60))
            let midPt2 = CGPoint(x: cos(a-0.2) * (rRoot - 130), y: sin(a-0.2) * (rRoot - 130))
            let tipPt = CGPoint(x: cos(a) * rTip, y: sin(a) * rTip)

            path.move(to: rootPt)
            path.addQuadCurve(to: midPt2, control: midPt1)
            path.addQuadCurve(to: tipPt, control: CGPoint(x: (midPt2.x + tipPt.x)/2 + 20, y: (midPt2.y + tipPt.y)/2 - 20))

            tendril.path = path
            tendril.strokeColor = SKColor(red: 0.05, green: 0.0, blue: 0.08, alpha: 0.9)
            tendril.lineWidth = 14.0
            tendril.lineCap = .round
            tendril.zPosition = -2

            // Animasi mengayun bagai cacing/akar hidup
            let sway = SKAction.sequence([
                .rotate(byAngle: 0.08, duration: TimeInterval.random(in: 0.8...1.2)),
                .rotate(byAngle: -0.16, duration: TimeInterval.random(in: 1.0...1.6)),
                .rotate(byAngle: 0.08, duration: TimeInterval.random(in: 0.8...1.2))
            ])
            tendril.run(.repeatForever(sway))
            atmosphereNode.addChild(tendril)
        }
    }

    private func updateProgressArc() {
        guard currentProgress > 0.01 else {
            progressRing.path = nil
            return
        }
        let r: CGFloat = 72
        let startAngle: CGFloat = .pi / 2
        let endAngle = startAngle - (currentProgress * 2 * .pi)
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressRing.path = path
        
        // Intensitas warna kabut dan sulur berubah sesuai kelambanan/kemajuan
        let tension = 1.0 - currentProgress
        atmosphereNode.setScale(1.0 + (tension * 0.15)) // Hollow makin besar kalau progress rendah
    }

    // MARK: - Lifecycle

    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        lastUpdateTime = 0

        container.setScale(0.85)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.25),
            .scale(to: 1.0, duration: 0.35).applyTimingMode(.easeOut)
        ]))

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .heavy)
        #endif

        // Denyut Panik Cepat (Heartbeat)
        pulseRing.run(.repeatForever(.sequence([
            .group([
                .scale(to: 1.45, duration: 0.25),
                .fadeOut(withDuration: 0.25)
            ]),
            .scale(to: 1.0, duration: 0),
            .fadeIn(withDuration: 0),
            .wait(forDuration: 0.15)
        ])), withKey: "hollowPulse")

        // Gemetar Panik Judul
        headingLabel.run(.repeatForever(.sequence([
            .moveBy(x: -2.0, y: 1.0, duration: 0.04),
            .moveBy(x: 4.0, y: -2.0, duration: 0.08),
            .moveBy(x: -2.0, y: 1.0, duration: 0.04),
            .wait(forDuration: 0.05)
        ])), withKey: "terrorJitter")

        // Decay Loop
        if config.decayPerSecond > 0 {
            removeAction(forKey: "hollowDecayLoop")
            let decayAction = SKAction.customAction(withDuration: 120.0) { [weak self] _, elapsedTime in
                guard let self, self.isRunning else { return }
                let dt: TimeInterval = self.lastUpdateTime == 0 ? 0.016 : min(0.05, Double(elapsedTime) - self.lastUpdateTime)
                self.lastUpdateTime = Double(elapsedTime)

                if self.currentProgress > 0 {
                    let decay = self.config.decayPerSecond * CGFloat(dt)
                    self.currentProgress = max(0.0, self.currentProgress - decay)
                    self.tapCount = Int(self.currentProgress * CGFloat(self.config.requiredTaps))
                    self.updateProgressArc()
                }
            }
            run(decayAction, withKey: "hollowDecayLoop")
        }
    }

    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard isRunning && !isCompleted else { return .miss }

        tapCount += 1
        currentProgress = min(1.0, CGFloat(tapCount) / CGFloat(config.requiredTaps))
        updateProgressArc()
        onProgress?(tapCount, config.requiredTaps)

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .rigid)
        #endif

        button.removeAction(forKey: "press")
        button.run(.sequence([
            .scale(to: 0.88, duration: 0.03),
            .scale(to: 1.0, duration: 0.08).applyTimingMode(.easeOut)
        ]), withKey: "press")

        buttonCore.removeAction(forKey: "corePress")
        buttonCore.run(.sequence([
            .scale(to: 0.80, duration: 0.03),
            .scale(to: 1.0, duration: 0.08).applyTimingMode(.easeOut)
        ]), withKey: "corePress")

        // Guncangan panik layar saat mengetuk
        container.run(.sequence([
            .moveBy(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -3...3), duration: 0.02),
            .moveTo(x: 0, duration: 0.03)
        ]))

        if tapCount >= config.requiredTaps {
            isCompleted = true
            isSuccess = true
            finishEvent()
            return .great
        }
        return .good
    }

    private func finishEvent() {
        guard isRunning else { return }
        isRunning = false
        removeAction(forKey: "hollowDecayLoop")
        pulseRing.removeAllActions()
        pulseRing.isHidden = true
        headingLabel.removeAction(forKey: "terrorJitter")

        #if canImport(UIKit)
        HapticsService.shared.playNotification(isSuccess ? .success : .error)
        #endif

        if isSuccess {
            headingLabel.text = "LOLOS DARI THE HOLLOW!"
            headingLabel.fontColor = SKColor(red: 0.4, green: 0.95, blue: 0.6, alpha: 1.0)
            promptLabel.text = "BERHASIL"
            instructionLabel.text = "Kabut tebal menipis. Arthur berhasil menjauh!"

            // Cahaya terang (sukses) mengusir gelap
            let winGlow = SKShapeNode(circleOfRadius: 150)
            winGlow.fillColor = SKColor(red: 0.8, green: 1.0, blue: 0.9, alpha: 1.0)
            winGlow.strokeColor = .clear
            winGlow.blendMode = .add
            winGlow.zPosition = 10
            container.addChild(winGlow)
            
            winGlow.run(.sequence([
                .group([
                    .scale(to: 4.0, duration: 0.4).applyTimingMode(.easeIn),
                    .fadeOut(withDuration: 0.4)
                ]),
                .removeFromParent()
            ]))
            
            // Sulur kabur mundur
            atmosphereNode.run(.group([
                .scale(to: 0.5, duration: 0.5),
                .fadeOut(withDuration: 0.5)
            ]))
            
        } else {
            headingLabel.text = "TERKEPUNG KABUT..."
            headingLabel.fontColor = SKColor(red: 0.95, green: 0.1, blue: 0.1, alpha: 1.0)
            promptLabel.text = "GAGAL"
            instructionLabel.text = "Bayangan The Hollow menelanmu..."
            
            // Kegelapan total menyelimuti (gagal)
            let loseDarkness = SKSpriteNode(color: .black, size: CGSize(width: 5000, height: 5000))
            loseDarkness.alpha = 0
            loseDarkness.zPosition = 10
            container.addChild(loseDarkness)
            loseDarkness.run(.fadeAlpha(to: 1.0, duration: 0.3))
        }

        onComplete?(isSuccess)

        if config.autoDismissDelay > 0 {
            run(.sequence([
                .wait(forDuration: config.autoDismissDelay),
                .group([
                    .fadeOut(withDuration: 0.3),
                    .scale(to: 0.9, duration: 0.3)
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
        removeAction(forKey: "hollowDecayLoop")
        removeAllActions()
        removeFromParent()
    }

    #if canImport(UIKit)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning && config.allowTouchAnywhere else { return }
        handleTap()
    }
    #endif
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("Hollow Chase Tap QTE (Dikejar Hollow)") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.05, green: 0.02, blue: 0.05, alpha: 1.0)

        func spawn() {
            let qte = HollowChaseTapQuickTimeEventNode(config: HollowChaseTapConfig(
                requiredTaps: 18,
                buttonPrompt: "LARI!",
                heading: "LARI DARI THE HOLLOW!",
                instruction: "DIA MENDEKAT DARI BALIK KABUT... KETUK CEPAT!",
                decayPerSecond: 0.12,
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
