import SpriteKit
import UIKit

/// Illustrated opening, once per launch. Tap or wait to advance each shot.
final class OpeningCutsceneScene: SKScene {
    struct Shot {
        let image: String
        let subtitle: String
    }
    let shots: [Shot] = [
        Shot(image: "ArthurOpening1", subtitle: "Sudah lama sekali… mengapa rumah itu masih terasa dekat?"),
        Shot(image: "ArthurOpening2", subtitle: "Relief ini… aku menyimpannya sejak masih muda."),
        Shot(image: "ArthurOpening3", subtitle: "Jalan kecil itu. Bukit di belakang rumah. Aku pernah di sana."),
        Shot(image: "ArthurOpening4", subtitle: "Tapi wajah-wajah mereka… mengapa begitu sulit kuingat?"),
        Shot(image: "ArthurOpening5", subtitle: "Keneth… Roland… Anneth. Kita pernah berjalan bersama."),
        Shot(image: "ArthurOpening6", subtitle: "Mungkin, jika kususun kembali… aku bisa mengingat semuanya.")
    ]
    let canvas = SKNode()
    let picture = SKSpriteNode()
    let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
    let hint = SKLabelNode(fontNamed: "AvenirNext-Regular")
    var index = 0
    var changingShot = false
    var leaving = false

    override func didMove(to view: SKView) {
        guard canvas.parent == nil else { return }
        backgroundColor = .black
        addChild(canvas)
        buildCanvas()

        layoutCanvas()
        showShot()
    }

    override func didChangeSize(_ oldSize: CGSize) { layoutCanvas() }

    override func willMove(from view: SKView) { removeAllActions() }
}
