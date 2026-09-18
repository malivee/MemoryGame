import SpriteKit
import UIKit

/// Illustrated opening, once per launch. Tap or wait to advance each shot.
final class OpeningCutsceneScene: SKScene {
    private struct Shot {
        let image: String
        let subtitle: String
    }
    private let shots: [Shot] = [
        Shot(image: "ArthurOpening1", subtitle: "Sudah lama sekali… mengapa rumah itu masih terasa dekat?"),
        Shot(image: "ArthurOpening2", subtitle: "Relief ini… aku menyimpannya sejak masih muda."),
        Shot(image: "ArthurOpening3", subtitle: "Jalan kecil itu. Bukit di belakang rumah. Aku pernah di sana."),
        Shot(image: "ArthurOpening4", subtitle: "Tapi wajah-wajah mereka… mengapa begitu sulit kuingat?"),
        Shot(image: "ArthurOpening5", subtitle: "Keneth… Roland… Anneth. Kita pernah berjalan bersama."),
        Shot(image: "ArthurOpening6", subtitle: "Mungkin, jika kususun kembali… aku bisa mengingat semuanya.")
    ]
    private let canvas = SKNode()
    private let picture = SKSpriteNode()
    private let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let hint = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private var index = 0
    private var changingShot = false
    private var leaving = false

    override func didMove(to view: SKView) {
        guard canvas.parent == nil else { return }
        backgroundColor = .black
        addChild(canvas)
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
        layoutCanvas()
        showShot()
    }

    override func didChangeSize(_ oldSize: CGSize) { layoutCanvas() }

    private func layoutCanvas() {
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        canvas.setScale(min(size.width / 1000, size.height / 600))
    }

    private func showShot() {
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

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !touches.isEmpty else { return }
        advance()
    }

    private func advance() {
        guard !changingShot, !leaving, let view else { return }
        removeAction(forKey: "advanceCutscene")
        changingShot = true
        if index == shots.count - 1 {
            leaving = true
            let puzzle = RightDeckPuzzleScene(size: size)
            puzzle.scaleMode = .resizeFill
            hint.run(.fadeOut(withDuration: 0.25))
            subtitle.run(.fadeOut(withDuration: 0.4))
            MemoryFogTransition.present(puzzle, from: self, in: view)
            return
        }
        picture.removeAction(forKey: "drift")
        picture.run(.fadeOut(withDuration: 0.2))
        subtitle.run(.fadeOut(withDuration: 0.2))
        run(.sequence([.wait(forDuration: 0.2), .run { [weak self] in
            guard let self else { return }
            self.index += 1
            self.showShot()
        }]), withKey: "changeShot")
    }

    override func willMove(from view: SKView) { removeAllActions() }
}
