import SpriteKit
import UIKit

// Rendering adapter. Gameplay rules live in Models and Systems.
extension OpeningCutsceneScene {
    func layoutCanvas() {
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        canvas.setScale(min(size.width / 1000, size.height / 600))
    }

    func showShot() {
        let shot = shots[index]
        let texture = SKTexture(imageNamed: shot.image)
        picture.texture = texture
        let source = texture.size()
        let fit = min(940 / max(1, source.width), 440 / max(1, source.height))
        picture.size = CGSize(width: source.width * fit, height: source.height * fit)
        picture.setScale(1)
        picture.alpha = 0
        subtitle.text = shot.subtitle
        subtitle.alpha = 0
        hint.text = "\(index + 1) / \(shots.count)   ·   Ketuk untuk melanjutkan"
        picture.run(.fadeIn(withDuration: 0.35))
        subtitle.run(.fadeIn(withDuration: 0.35))
        if !UIAccessibility.isReduceMotionEnabled {
            picture.run(.scale(to: 1.025, duration: 8), withKey: "drift")
        }
        changingShot = true
        run(.sequence([.wait(forDuration: 0.35), .run { [weak self] in
            self?.changingShot = false
        }]), withKey: "unlockTap")
        run(.sequence([.wait(forDuration: 8), .run { [weak self] in
            self?.advance()
        }]), withKey: "advanceCutscene")
    }
    func buildCanvas() {
        picture.position.y = 42
        canvas.addChild(picture)
        subtitle.fontSize = 23
        subtitle.fontColor = SKColor(white: 0.96, alpha: 1)
        subtitle.numberOfLines = 2
        subtitle.preferredMaxLayoutWidth = 820
        subtitle.horizontalAlignmentMode = .center
        subtitle.verticalAlignmentMode = .center
        subtitle.position.y = -226
        canvas.addChild(subtitle)
        hint.fontSize = 12
        hint.fontColor = SKColor(white: 0.55, alpha: 1)
        hint.position.y = -280
        canvas.addChild(hint)

        // Tombol Lewati di pojok kanan atas
        let skipBtn = SKShapeNode(rectOf: CGSize(width: 96, height: 32), cornerRadius: 16)
        skipBtn.name = "skipCutscene"
        skipBtn.position = CGPoint(x: 410, y: 260)
        skipBtn.fillColor = SKColor(white: 0.15, alpha: 0.75)
        skipBtn.strokeColor = SKColor(white: 1.0, alpha: 0.28)
        skipBtn.lineWidth = 1.2
        canvas.addChild(skipBtn)

        let skipLabel = SKLabelNode(text: "Lewati ›")
        skipLabel.name = "skipCutscene"
        skipLabel.fontName = "AvenirNext-Medium"
        skipLabel.fontSize = 13
        skipLabel.fontColor = SKColor(white: 0.90, alpha: 1)
        skipLabel.verticalAlignmentMode = .center
        skipBtn.addChild(skipLabel)

    }

}
