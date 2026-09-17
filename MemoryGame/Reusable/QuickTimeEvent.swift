import SpriteKit
import UIKit

/// Add to a scene, then start(). The scene owner handles the outcome.
public final class QuickTimeEventNode: SKNode {
    public var onComplete: ((Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    public var onProgress: ((Int, Int) -> Void)?
    private var logic: QuickTimeEventLogic
    private var running = false
    private let wreath = SKNode()
    private let button = SKShapeNode()
    private let prompt = SKLabelNode(fontNamed: "Georgia-Bold")
    private let heading = SKLabelNode(fontNamed: "Georgia-Bold")
    private let instruction = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let pulse = SKShapeNode(circleOfRadius: 64)
    private let ash = SKColor(red: 0.78, green: 0.72, blue: 0.60, alpha: 1)
    private let ember = SKColor(red: 0.68, green: 0.24, blue: 0.20, alpha: 1)

    public init(config: QuickTimeEventConfig = QuickTimeEventConfig()) {
        logic = QuickTimeEventLogic(config: config)
        super.init()
        isUserInteractionEnabled = true
        zPosition = 500
        buildVisuals()
        refresh()
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func label(_ node: SKLabelNode, text: String, size: CGFloat, y: CGFloat) {
        node.text = text; node.fontSize = size; node.fontColor = ash
        node.verticalAlignmentMode = .center; node.position.y = y
        node.zPosition = 5; wreath.addChild(node)
    }
    private func buildVisuals() {
        // Consume off-button touches too, so misses cannot move the player below.
        let shield = SKSpriteNode(color: SKColor(red: 0.025, green: 0.018, blue: 0.023, alpha: 0.86),
                                  size: CGSize(width: 10000, height: 10000))
        shield.zPosition = -10
        addChild(shield); addChild(wreath)
        // A fixed hit target stays easy to mash while the surrounding prompt pulses.
        button.path = CGPath(ellipseIn: CGRect(x: -54, y: -54, width: 108, height: 108), transform: nil)
        button.fillColor = SKColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
        button.strokeColor = ash; button.lineWidth = 4
        button.zPosition = 4; button.name = "qteTapButton"
        wreath.addChild(button)
        pulse.strokeColor = ash; pulse.lineWidth = 2; pulse.fillColor = .clear
        wreath.addChild(pulse)
        prompt.text = logic.config.buttonPrompt; prompt.fontSize = 22
        prompt.fontColor = ash; prompt.verticalAlignmentMode = .center
        prompt.preferredMaxLayoutWidth = 102; prompt.numberOfLines = 2
        button.addChild(prompt)
        label(heading, text: "LARI!", size: 32, y: 96)
        label(instruction, text: logic.config.allowTouchAnywhere ? "KETUK LAYAR TERUS!" : "KETUK CEPAT BERULANG KALI!", size: 15, y: -80)
    }
    private func refresh() {
    }
    public func start() {
        guard !running, !logic.isCompleted else { return }
        running = true
        wreath.alpha = 0; wreath.run(.fadeIn(withDuration: 0.15))
        if !UIAccessibility.isReduceMotionEnabled {
            pulse.run(.repeatForever(.sequence([
                .group([.scale(to: 1.3, duration: 0.42), .fadeOut(withDuration: 0.42)]),
                .scale(to: 1, duration: 0), .fadeIn(withDuration: 0)
            ])), withKey: "mashPulse")
        }
    }
    @discardableResult
    public func handleTap() -> QTEHitResult {
        guard running, !logic.isCompleted else { return .miss }
        let outcome = logic.registerTap()
        refresh()
        HapticsService.shared.playImpact(style: .light)
        if !UIAccessibility.isReduceMotionEnabled {
            button.removeAction(forKey: "press"); button.setScale(1)
            button.run(.sequence([.scale(to: 0.94, duration: 0.035), .scale(to: 1, duration: 0.075)]), withKey: "press")
        }
        onProgress?(logic.tapCount, logic.config.requiredTaps)
        if running && outcome.completed { finishEvent() }
        return outcome.result
    }
    private func finishEvent() {
        guard running else { return }
        running = false; refresh()
        pulse.removeAllActions(); pulse.isHidden = true
        heading.position.x = 0
        heading.text = logic.isSuccess ? "LOLOS!" : "TERLAMBAT"
        prompt.text = logic.isSuccess ? "BERHASIL" : "GAGAL"
        prompt.fontSize = 16
        instruction.text = logic.isSuccess ? "Kamu berhasil melarikan diri." : "Kamu tertangkap."
        HapticsService.shared.playNotification(logic.isSuccess ? .success : .error)
        // Schedule first so an owner can cancel safely from onComplete.
        if logic.config.autoDismissDelay > 0 {
            run(.sequence([.wait(forDuration: logic.config.autoDismissDelay), .fadeOut(withDuration: 0.2),
                           .run { [weak self] in
                guard let self else { return }
                self.removeFromParent(); self.onDismiss?()
            }]), withKey: "qteDismiss")
        }
        onComplete?(logic.isSuccess)
    }
    public func cancel() {
        running = false; removeAllActions(); button.removeAllActions(); removeFromParent()
    }
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard running else { return }
        // Holding/dragging never repeats; one simultaneous touch batch is one tap.
        if logic.config.allowTouchAnywhere || touches.contains(where: { button.contains($0.location(in: wreath)) }) {
            handleTap()
        }
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
private final class MashPreviewScene: SKScene {
    private weak var activeQTE: QuickTimeEventNode?
    override func didMove(to view: SKView) {
        guard activeQTE == nil else { return }
        backgroundColor = SKColor(red: 0.07, green: 0.055, blue: 0.055, alpha: 1)
        spawnQTE()
    }
    private func spawnQTE() {
        let node = QuickTimeEventNode()
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.onDismiss = { [weak self] in self?.spawnQTE() }
        addChild(node); activeQTE = node; node.start()
    }
    override func didChangeSize(_ oldSize: CGSize) {
        activeQTE?.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
}
#Preview("QTE · Chase Button Mashing") {
    SpriteView(scene: {
        let scene = MashPreviewScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        return scene
    }()).ignoresSafeArea()
}
#endif
