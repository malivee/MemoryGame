// Penjelasan file: MudTapQuickTimeEvent.swift
// Komponen Quick Time Event (QTE) Ketukan Cepat (Button Mashing) Khusus Bertema Menarik Buku dari Lumpur & Akar.
// Visual Upgrade:
// - Kubangan lumpur organik dengan highlight basah/lengket.
// - Tombol berbentuk buku jurnal tua yang terjerat akar raksasa.
// - Cipratan partikel lumpur kental (mud globs) setiap ketukan.
// - Animasi fisik Tarik-Ulur (Buku naik saat diketuk, tersedot turun saat diam).

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration & Data Types

public struct MudTapConfig: Sendable {
    public var requiredTaps: Int
    public var buttonPrompt: String
    public var heading: String
    public var instruction: String
    public var suctionDecay: CGFloat
    public var allowTouchAnywhere: Bool
    public var autoDismissDelay: TimeInterval

    public init(
        requiredTaps: Int = 16,
        buttonPrompt: String = "TARIK!",
        heading: String = "TERKUBUR DI LUMPUR!",
        instruction: String = "KETUK CEPAT UNTUK MENARIKNYA DARI AKAR POHON!",
        suctionDecay: CGFloat = 0.08,
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 0.8
    ) {
        self.requiredTaps = max(1, requiredTaps)
        self.buttonPrompt = buttonPrompt
        self.heading = heading
        self.instruction = instruction
        self.suctionDecay = suctionDecay
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
    }
}

// MARK: - SpriteKit Node: MudTapQuickTimeEventNode

public final class MudTapQuickTimeEventNode: SKNode {

    public var onProgress: ((_ current: Int, _ total: Int) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?

    public var config: MudTapConfig
    public private(set) var tapCount: Int = 0
    public private(set) var currentProgress: CGFloat = 0.0
    public private(set) var isCompleted: Bool = false
    public private(set) var isSuccess: Bool = false

    private var isRunning: Bool = false
    private var lastUpdateTime: TimeInterval = 0

    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    private let mudCrater = SKNode()
    private let buttonContainer = SKNode() // Untuk animasi naik-turun buku
    private let bookButton = SKShapeNode()
    private let rootBindings = SKNode()
    
    private let progressRing = SKShapeNode()
    private let pulseRing = SKShapeNode()
    private let promptLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let headingLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let splashNode = SKNode()

    public init(config: MudTapConfig = MudTapConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 820
        buildVisuals()
        updateProgressArc()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Shape Generators

    private func createOrganicPuddle(radius: CGFloat, variance: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let steps = 24
        for i in 0...steps {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(steps)
            let r = radius + CGFloat.random(in: -variance...variance)
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * (r * 0.85)) // Sedikit pipih
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }

    private func createMudGlobPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size)) // Ujung atas lancip
        path.addQuadCurve(to: CGPoint(x: size/2, y: -size/2), control: CGPoint(x: size/2, y: size/4))
        path.addQuadCurve(to: CGPoint(x: -size/2, y: -size/2), control: CGPoint(x: 0, y: -size)) // Pantat bulat
        path.addQuadCurve(to: CGPoint(x: 0, y: size), control: CGPoint(x: -size/2, y: size/4))
        return path
    }

    private func createRootPath(start: CGPoint, end: CGPoint, curvature: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: start)
        let midX = (start.x + end.x) / 2 + CGFloat.random(in: -curvature...curvature)
        let midY = (start.y + end.y) / 2 + CGFloat.random(in: -curvature...curvature)
        path.addQuadCurve(to: end, control: CGPoint(x: midX, y: midY))
        return path
    }

    // MARK: - Visual Setup

    private func buildVisuals() {
        addChild(container)

        // 1. Redup Layar Bernuansa Tanah Lembap Basah
        backdrop.color = SKColor(red: 0.08, green: 0.05, blue: 0.03, alpha: 0.88)
        backdrop.size = CGSize(width: 5000, height: 5000)
        backdrop.zPosition = -10
        container.addChild(backdrop)

        // 2. Kubangan Tanah Longsor Organik (Mud Crater)
        container.addChild(mudCrater)
        mudCrater.zPosition = 0.5
        
        let baseMud = SKShapeNode(path: createOrganicPuddle(radius: 95, variance: 8))
        baseMud.fillColor = SKColor(red: 0.12, green: 0.08, blue: 0.05, alpha: 1.0)
        baseMud.strokeColor = SKColor(red: 0.08, green: 0.05, blue: 0.03, alpha: 1.0)
        baseMud.lineWidth = 4.0
        mudCrater.addChild(baseMud)

        let midMud = SKShapeNode(path: createOrganicPuddle(radius: 75, variance: 6))
        midMud.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.07, alpha: 1.0)
        midMud.strokeColor = .clear
        mudCrater.addChild(midMud)

        // Highlight lumpur basah lengket (Wet Specular Highlight)
        let wetHighlight = SKShapeNode(path: createOrganicPuddle(radius: 65, variance: 12))
        wetHighlight.fillColor = SKColor(red: 0.35, green: 0.28, blue: 0.22, alpha: 0.2)
        wetHighlight.strokeColor = .clear
        wetHighlight.position = CGPoint(x: -8, y: 12)
        mudCrater.addChild(wetHighlight)

        // 3. Tombol Bentuk Buku Jurnal Tua Tertanam
        container.addChild(buttonContainer)
        buttonContainer.zPosition = 4
        buttonContainer.name = "mudTapButton"

        let bookW: CGFloat = 80
        let bookH: CGFloat = 100
        let bookRect = CGRect(x: -bookW/2, y: -bookH/2, width: bookW, height: bookH)
        
        // Bayangan buku di lumpur
        let bookShadow = SKShapeNode(rect: bookRect, cornerRadius: 8)
        bookShadow.fillColor = SKColor(red: 0.05, green: 0.02, blue: 0.01, alpha: 0.8)
        bookShadow.strokeColor = .clear
        bookShadow.position = CGPoint(x: 0, y: -6)
        buttonContainer.addChild(bookShadow)

        bookButton.path = CGPath(roundedRect: bookRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        bookButton.fillColor = SKColor(red: 0.28, green: 0.18, blue: 0.12, alpha: 1.0) // Kulit buku kotor
        bookButton.strokeColor = SKColor(red: 0.15, green: 0.08, blue: 0.05, alpha: 1.0)
        bookButton.lineWidth = 4.0
        bookButton.name = "mudTapButton"
        buttonContainer.addChild(bookButton)

        // Halaman buku menguning di samping
        let pagesPath = CGMutablePath()
        pagesPath.addRoundedRect(in: CGRect(x: (bookW/2) - 12, y: -bookH/2 + 4, width: 8, height: bookH - 8), cornerWidth: 2, cornerHeight: 2)
        let pages = SKShapeNode(path: pagesPath)
        pages.fillColor = SKColor(red: 0.75, green: 0.68, blue: 0.52, alpha: 0.8)
        pages.strokeColor = .clear
        buttonContainer.addChild(pages)

        // 4. Akar Pohon Raksasa Menjerat Buku
        buttonContainer.addChild(rootBindings)
        
        for _ in 0..<3 {
            let startY = CGFloat.random(in: -40...40)
            let endY = startY + CGFloat.random(in: -20...20)
            let rootPath = createRootPath(start: CGPoint(x: -55, y: startY), end: CGPoint(x: 55, y: endY), curvature: 20)
            
            let rootNode = SKShapeNode(path: rootPath)
            rootNode.strokeColor = SKColor(red: 0.14, green: 0.10, blue: 0.06, alpha: 1.0)
            rootNode.lineWidth = CGFloat.random(in: 6...12)
            rootNode.lineCap = .round
            rootBindings.addChild(rootNode)
        }

        // 5. Cincin Progres
        let rRing: CGFloat = 85
        pulseRing.path = CGPath(ellipseIn: CGRect(x: -rRing, y: -rRing, width: rRing*2, height: rRing*2), transform: nil)
        pulseRing.strokeColor = SKColor(red: 0.65, green: 0.48, blue: 0.32, alpha: 0.6)
        pulseRing.lineWidth = 4.0
        pulseRing.fillColor = .clear
        pulseRing.zPosition = 1
        container.addChild(pulseRing)

        progressRing.lineWidth = 8.0
        progressRing.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.35, alpha: 1.0)
        progressRing.lineCap = .round
        progressRing.fillColor = .clear
        progressRing.zPosition = 3
        container.addChild(progressRing)

        let trackRing = SKShapeNode(circleOfRadius: rRing)
        trackRing.strokeColor = SKColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 0.8)
        trackRing.lineWidth = 6.0
        trackRing.fillColor = .clear
        trackRing.zPosition = 2.9
        container.addChild(trackRing)

        // 6. Label Teks
        promptLabel.text = config.buttonPrompt
        promptLabel.fontSize = 24
        promptLabel.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
        promptLabel.verticalAlignmentMode = .center
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.position = .zero
        promptLabel.zPosition = 5
        
        // Shadow teks agar terbaca jelas di atas warna lumpur
        let promptShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        promptShadow.text = config.buttonPrompt
        promptShadow.fontSize = 24
        promptShadow.fontColor = .black
        promptShadow.verticalAlignmentMode = .center
        promptShadow.horizontalAlignmentMode = .center
        promptShadow.position = CGPoint(x: 1, y: -2)
        promptShadow.zPosition = -1
        promptLabel.addChild(promptShadow)
        
        buttonContainer.addChild(promptLabel)

        headingLabel.text = config.heading
        headingLabel.fontSize = 26
        headingLabel.fontColor = SKColor(red: 0.95, green: 0.75, blue: 0.45, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: 125)
        headingLabel.zPosition = 6
        container.addChild(headingLabel)

        instructionLabel.text = config.instruction
        instructionLabel.fontSize = 13
        instructionLabel.fontColor = SKColor(red: 0.78, green: 0.68, blue: 0.58, alpha: 0.9)
        instructionLabel.position = CGPoint(x: 0, y: -120)
        instructionLabel.zPosition = 6
        container.addChild(instructionLabel)

        // 7. Splash Node
        container.addChild(splashNode)
        splashNode.zPosition = 15
    }

    private func updateProgressArc() {
        guard currentProgress > 0.01 else {
            progressRing.path = nil
            return
        }
        let r: CGFloat = 85
        let startAngle: CGFloat = .pi / 2
        let endAngle = startAngle - (currentProgress * 2 * .pi)
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressRing.path = path
        
        // Animasi "Tarik Ulur": Buku terangkat dari lumpur seiring progres
        let targetY = -15.0 + (currentProgress * 30.0) // Dari bawah naik ke atas
        buttonContainer.run(.moveTo(y: targetY, duration: 0.1))
        
        // Akar menipis/merenggang seolah mau putus
        rootBindings.alpha = 1.0 - (currentProgress * 0.8)
    }

    private func spawnMudSplatter() {
        let dropCount = Int.random(in: 4...7)
        for _ in 0..<dropCount {
            let size = CGFloat.random(in: 4.0...8.0)
            let drop = SKShapeNode(path: createMudGlobPath(size: size))
            
            // Variasi warna lumpur
            let isDark = Bool.random()
            drop.fillColor = isDark ? SKColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 0.95) : SKColor(red: 0.28, green: 0.20, blue: 0.12, alpha: 0.9)
            drop.strokeColor = .clear

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 60...110)
            let targetPt = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)

            drop.position = CGPoint(x: cos(angle) * 30, y: sin(angle) * 30)
            drop.zRotation = angle - .pi/2 // Tetesan mengarah ke luar
            splashNode.addChild(drop)

            drop.run(.sequence([
                .group([
                    .move(to: targetPt, duration: TimeInterval.random(in: 0.2...0.4)).applyTimingMode(.easeOut),
                    .scale(to: 0.3, duration: 0.35),
                    .fadeOut(withDuration: 0.35)
                ]),
                .removeFromParent()
            ]))
        }
    }

    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        lastUpdateTime = 0

        container.setScale(0.85)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.2),
            .scale(to: 1.0, duration: 0.3).applyTimingMode(.easeOut)
        ]))

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .heavy)
        #endif

        // Animasi denyut kubangan lumpur
        pulseRing.run(.repeatForever(.sequence([
            .group([
                .scale(to: 1.4, duration: 0.6).applyTimingMode(.easeOut),
                .fadeOut(withDuration: 0.6)
            ]),
            .scale(to: 1.0, duration: 0),
            .fadeIn(withDuration: 0),
            .wait(forDuration: 0.2)
        ])), withKey: "mudPulse")

        // Suction decay loop (Daya hisap lumpur menarik buku turun)
        if config.suctionDecay > 0 {
            removeAction(forKey: "mudDecayLoop")
            let decayAction = SKAction.customAction(withDuration: 120.0) { [weak self] _, elapsedTime in
                guard let self, self.isRunning else { return }
                let dt: TimeInterval = self.lastUpdateTime == 0 ? 0.016 : min(0.05, Double(elapsedTime) - self.lastUpdateTime)
                self.lastUpdateTime = Double(elapsedTime)

                if self.currentProgress > 0 {
                    let decay = self.config.suctionDecay * CGFloat(dt)
                    self.currentProgress = max(0.0, self.currentProgress - decay)
                    self.tapCount = Int(self.currentProgress * CGFloat(self.config.requiredTaps))
                    self.updateProgressArc()
                }
            }
            run(decayAction, withKey: "mudDecayLoop")
        }
    }

    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard isRunning && !isCompleted else { return .miss }

        tapCount += 1
        currentProgress = min(1.0, CGFloat(tapCount) / CGFloat(config.requiredTaps))
        updateProgressArc()
        spawnMudSplatter()
        onProgress?(tapCount, config.requiredTaps)

        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .rigid) // Rigid terasa keras dan lengket
        #endif

        // Guncangan tombol berjuang melawan lumpur
        buttonContainer.removeAction(forKey: "press")
        buttonContainer.run(.sequence([
            .moveBy(x: CGFloat.random(in: -3...3), y: 4, duration: 0.03),
            .scaleX(to: 0.95, y: 1.05, duration: 0.03),
            .scale(to: 1.0, duration: 0.08).applyTimingMode(.easeOut)
        ]), withKey: "press")

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
        removeAction(forKey: "mudDecayLoop")
        pulseRing.removeAllActions()
        pulseRing.isHidden = true

        #if canImport(UIKit)
        HapticsService.shared.playNotification(isSuccess ? .success : .error)
        #endif

        if isSuccess {
            headingLabel.text = "BUKU BERHASIL DITARIK!"
            headingLabel.fontColor = SKColor(red: 0.5, green: 0.95, blue: 0.6, alpha: 1.0)
            promptLabel.text = "DAPAT!"
            
            // Animasi akar putus terlempar
            rootBindings.run(.group([
                .scale(to: 1.5, duration: 0.3),
                .fadeOut(withDuration: 0.3)
            ]))

            // Buku terbang keluar dari lumpur (Bebas)
            buttonContainer.run(.sequence([
                .moveBy(x: 0, y: 60, duration: 0.4).applyTimingMode(.easeOut),
                .wait(forDuration: 0.1)
            ]))

            // Cipratan besar terakhir tanda pembebasan
            for _ in 0..<18 {
                spawnMudSplatter()
            }
        }

        onComplete?(isSuccess)

        if config.autoDismissDelay > 0 {
            run(.sequence([
                .wait(forDuration: config.autoDismissDelay + 0.3), // Ekstra waktu u/ liat buku keluar
                .group([
                    .fadeOut(withDuration: 0.3),
                    .scale(to: 0.85, duration: 0.3).applyTimingMode(.easeIn)
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
        removeAction(forKey: "mudDecayLoop")
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

#Preview("Mud Tap QTE (Terjebak di Lumpur)") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.06, green: 0.04, blue: 0.03, alpha: 1.0)

        func spawn() {
            let qte = MudTapQuickTimeEventNode(config: MudTapConfig(
                requiredTaps: 16,
                buttonPrompt: "TARIK!",
                heading: "TERJEBAK DI LUMPUR!",
                instruction: "KETUK LAYAR CEPAT UNTUK MEMBEBASKAN DIRI!",
                suctionDecay: 0.08,
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
