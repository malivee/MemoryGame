// Penjelasan file: ClassicTapQuickTimeEvent.swift
// Komponen Quick Time Event (QTE) Ketukan (Button Mashing) Bergaya Storybook / Cartoon.
// Visual Upgrade:
// - Progress bar DIHAPUS.
// - Tombol kayu solid ala kartun dengan aksen kuningan.
// - Efek partikel "Burst" (debu emas/daun) setiap kali diketuk.
// - Pemain bebas mengetuk sesuka hati, memberi sensasi tak terbatas.

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration & Data Types

public struct ClassicTapConfig: Sendable {
    public var requiredTaps: Int
    public var buttonPrompt: String
    public var heading: String
    public var instruction: String
    public var allowTouchAnywhere: Bool
    public var autoDismissDelay: TimeInterval

    public init(
        requiredTaps: Int = 15,
        buttonPrompt: String = "ANGKAT",
        heading: String = "ANGKAT RAK!",
        instruction: String = "KETUK LAYAR TERUS MENERUS!",
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 0.75
    ) {
        self.requiredTaps = max(1, requiredTaps)
        self.buttonPrompt = buttonPrompt
        self.heading = heading
        self.instruction = instruction
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
    }
}

// MARK: - SpriteKit Node: ClassicTapQuickTimeEventNode

public final class ClassicTapQuickTimeEventNode: SKNode {

    public var onTap: ((_ currentTapCount: Int) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?

    public var config: ClassicTapConfig
    public private(set) var tapCount: Int = 0
    public private(set) var isCompleted: Bool = false
    public private(set) var isSuccess: Bool = false

    private var isRunning: Bool = false

    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    private let buttonShadow = SKShapeNode()
    private let button = SKShapeNode()
    private let buttonCore = SKShapeNode()
    private let pulseRing = SKShapeNode(circleOfRadius: 80)
    
    private let promptLabel = SKLabelNode(fontNamed: "Georgia-Bold")
    private let headingLabel = SKLabelNode(fontNamed: "Georgia-Bold")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    public init(config: ClassicTapConfig = ClassicTapConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 800
        buildVisuals()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildVisuals() {
        addChild(container)

        // 1. Redup Lembut Layar (Warm Storybook Vignette)
        backdrop.color = SKColor(red: 0.12, green: 0.08, blue: 0.05, alpha: 0.75)
        backdrop.size = CGSize(width: 5000, height: 5000)
        backdrop.zPosition = -10
        container.addChild(backdrop)

        // 2. Cincin Denyut Luar (Pulse Ring - Animasi standby)
        pulseRing.strokeColor = SKColor(red: 0.95, green: 0.85, blue: 0.55, alpha: 0.6)
        pulseRing.lineWidth = 4.0
        pulseRing.fillColor = .clear
        pulseRing.zPosition = 1
        container.addChild(pulseRing)

        let r: CGFloat = 65
        
        // 3. Drop Shadow Tombol (3D Cartoon Effect)
        buttonShadow.path = CGPath(ellipseIn: CGRect(x: -r, y: -r - 8, width: r * 2, height: r * 2), transform: nil)
        buttonShadow.fillColor = SKColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 0.8)
        buttonShadow.strokeColor = .clear
        buttonShadow.zPosition = 3
        container.addChild(buttonShadow)

        // 4. Base Tombol Kayu Mahoni
        button.path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2), transform: nil)
        button.fillColor = SKColor(red: 0.35, green: 0.20, blue: 0.12, alpha: 1.0) // Kayu coklat kemerahan
        button.strokeColor = SKColor(red: 0.20, green: 0.10, blue: 0.05, alpha: 1.0)
        button.lineWidth = 6.0
        button.zPosition = 4
        button.name = "classicTapButton"
        container.addChild(button)

        // 5. Inti Tombol (Plat Kuningan / Emas Kusam)
        let coreR: CGFloat = 50
        buttonCore.path = CGPath(ellipseIn: CGRect(x: -coreR, y: -coreR, width: coreR * 2, height: coreR * 2), transform: nil)
        buttonCore.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.30, alpha: 1.0) // Emas/Kuningan
        buttonCore.strokeColor = SKColor(red: 0.95, green: 0.85, blue: 0.55, alpha: 1.0)
        buttonCore.lineWidth = 3.0
        buttonCore.zPosition = 4.1
        buttonCore.name = "classicTapButton"
        container.addChild(buttonCore)
        
        // Baut hiasan di plat kuningan
        let rivetAngles: [CGFloat] = [0, .pi / 2, .pi, 3 * .pi / 2]
        for angle in rivetAngles {
            let rivet = SKShapeNode(circleOfRadius: 3.5)
            rivet.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 0.8)
            rivet.strokeColor = .clear
            rivet.position = CGPoint(x: cos(angle) * 38, y: sin(angle) * 38)
            rivet.zPosition = 4.2
            container.addChild(rivet)
        }

        // 6. Teks Prompt (Angkat!)
        promptLabel.text = config.buttonPrompt
        promptLabel.fontSize = 22
        promptLabel.fontColor = SKColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 1.0)
        promptLabel.verticalAlignmentMode = .center
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.position = .zero
        promptLabel.zPosition = 5
        promptLabel.name = "classicTapButton"
        container.addChild(promptLabel)
        
        // Shadow putih/kuning muda untuk teks prompt (emboss effect)
        let promptHighlight = SKLabelNode(fontNamed: "Georgia-Bold")
        promptHighlight.text = config.buttonPrompt
        promptHighlight.fontSize = 22
        promptHighlight.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 0.9)
        promptHighlight.verticalAlignmentMode = .center
        promptHighlight.horizontalAlignmentMode = .center
        promptHighlight.position = CGPoint(x: 0, y: -2)
        promptHighlight.zPosition = -1
        promptLabel.addChild(promptHighlight)

        // 7. Label Judul & Instruksi
        headingLabel.text = config.heading
        headingLabel.fontSize = 32
        headingLabel.fontColor = SKColor(red: 0.95, green: 0.85, blue: 0.65, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: 110)
        headingLabel.zPosition = 6
        
        // Shadow Judul
        let headingShadow = SKLabelNode(fontNamed: "Georgia-Bold")
        headingShadow.text = config.heading
        headingShadow.fontSize = 32
        headingShadow.fontColor = SKColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 1.0)
        headingShadow.position = CGPoint(x: 2, y: -3)
        headingShadow.zPosition = -1
        headingLabel.addChild(headingShadow)
        container.addChild(headingLabel)

        instructionLabel.text = config.instruction
        instructionLabel.fontSize = 15
        instructionLabel.fontColor = SKColor(red: 0.85, green: 0.75, blue: 0.60, alpha: 1.0)
        instructionLabel.position = CGPoint(x: 0, y: -110)
        instructionLabel.zPosition = 6
        container.addChild(instructionLabel)
    }

    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true

        container.setScale(0.7)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.25),
            .scale(to: 1.0, duration: 0.35).applyTimingMode(.easeOut)
        ]))

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .medium)
        #endif

        // Animasi bernapas (Standby)
        pulseRing.run(.repeatForever(.sequence([
            .group([
                .scale(to: 1.4, duration: 0.6).applyTimingMode(.easeOut),
                .fadeOut(withDuration: 0.6)
            ]),
            .scale(to: 1.0, duration: 0),
            .fadeIn(withDuration: 0),
            .wait(forDuration: 0.2)
        ])), withKey: "classicPulse")
        
        // Ayunan kartun lembut pada judul
        headingLabel.run(.repeatForever(.sequence([
            .rotate(byAngle: 0.05, duration: 1.5).applyTimingMode(.easeInEaseOut),
            .rotate(byAngle: -0.1, duration: 3.0).applyTimingMode(.easeInEaseOut),
            .rotate(byAngle: 0.05, duration: 1.5).applyTimingMode(.easeInEaseOut)
        ])))
    }

    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard isRunning && !isCompleted else { return .miss }

        tapCount += 1
        onTap?(tapCount) // Beri tahu sistem jumlah tap saat ini

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .light)
        #endif

        // Efek visual menekan tombol (Squash and Stretch)
        button.removeAction(forKey: "press")
        buttonCore.removeAction(forKey: "press")
        
        let squash = SKAction.scaleX(to: 1.05, y: 0.88, duration: 0.04)
        let stretch = SKAction.scaleX(to: 0.95, y: 1.05, duration: 0.06)
        let normal = SKAction.scale(to: 1.0, duration: 0.08)
        let bounceSequence = SKAction.sequence([squash, stretch, normal])
        
        button.run(bounceSequence, withKey: "press")
        buttonCore.run(bounceSequence, withKey: "press")
        
        // Spawn partikel debu kayu/bintang untuk kepuasan visual (Juiciness)
        spawnTapParticles()

        // Cek kelulusan QTE (Jika ada batas ketukan)
        if tapCount >= config.requiredTaps {
            isCompleted = true
            isSuccess = true
            finishEvent()
            return .great
        }
        return .good
    }
    
    private func spawnTapParticles() {
        let particleCount = Int.random(in: 4...7)
        for _ in 0..<particleCount {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.0))
            p.fillColor = Bool.random() ? SKColor(red: 0.95, green: 0.85, blue: 0.55, alpha: 1.0) : SKColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1.0)
            p.strokeColor = .clear
            p.zPosition = 3.5
            
            // Random sudut ledakan
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 55...95)
            let moveX = cos(angle) * distance
            let moveY = sin(angle) * distance
            
            container.addChild(p)
            
            p.run(.sequence([
                .group([
                    .moveBy(x: moveX, y: moveY, duration: TimeInterval.random(in: 0.3...0.5)).applyTimingMode(.easeOut),
                    .fadeOut(withDuration: TimeInterval.random(in: 0.3...0.5)),
                    .scale(to: 0.2, duration: 0.4)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func finishEvent() {
        guard isRunning else { return }
        isRunning = false
        pulseRing.removeAllActions()
        pulseRing.isHidden = true
        headingLabel.removeAllActions()

        #if canImport(UIKit)
        HapticsService.shared.playNotification(isSuccess ? .success : .error)
        #endif

        if isSuccess {
            headingLabel.text = "BERHASIL!"
            headingLabel.fontColor = SKColor(red: 0.5, green: 0.9, blue: 0.5, alpha: 1.0)
            promptLabel.text = "SELESAI"
            
            // Ledakan partikel kemenangan
            for _ in 0..<20 { spawnTapParticles() }

            let glow = SKShapeNode(circleOfRadius: 90)
            glow.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.55, alpha: 0.5)
            glow.strokeColor = .clear
            glow.zPosition = 2
            container.addChild(glow)
            glow.run(.sequence([
                .group([
                    .scale(to: 1.8, duration: 0.35).applyTimingMode(.easeOut),
                    .fadeOut(withDuration: 0.35)
                ]),
                .removeFromParent()
            ]))
        }

        onComplete?(isSuccess)

        if config.autoDismissDelay > 0 {
            run(.sequence([
                .wait(forDuration: config.autoDismissDelay),
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

#Preview("Classic Tap QTE (Storybook Carto)") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0)

        func spawn() {
            let qte = ClassicTapQuickTimeEventNode(config: ClassicTapConfig(
                requiredTaps: 14,
                buttonPrompt: "ANGKAT",
                heading: "ANGKAT RAK!",
                instruction: "KETUK LAYAR BERULANG KALI UNTUK MENEGAKKAN RAK!",
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
