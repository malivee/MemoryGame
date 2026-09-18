import SpriteKit
import UIKit

// Input adapter. Gameplay rules live in Models and Systems.
extension OpeningCutsceneScene {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !touches.isEmpty, let touch = touches.first else { return }
        let canvasPoint = touch.location(in: canvas)
        let hitNodes = canvas.nodes(at: canvasPoint)
        if hitNodes.contains(where: { $0.name == "skipCutscene" }) {
            skipCutscene()
            return
        }
        advance()
    }
}
