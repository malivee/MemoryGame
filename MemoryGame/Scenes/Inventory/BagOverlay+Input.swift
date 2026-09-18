import SpriteKit
import UIKit

// Input adapter. Gameplay rules live in Models and Systems.
extension BagOverlay {
    func action(at point: CGPoint) -> String? {
        for node in nodes(at: point) {
            var current: SKNode? = node
            while let candidate = current, candidate !== self {
                if let name = candidate.name { return name }
                current = candidate.parent
            }
        }
        return nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        pressed = action(at: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { pressed = nil }
        guard let touch = touches.first, let pressed, pressed == action(at: touch.location(in: self)) else { return }
        if pressed == "close" { onClose?(); return }
        if pressed == "previous", page > 0 { page -= 1; rebuild(); return }
        if pressed == "next", page + 1 < inventory.pageCount { page += 1; rebuild(); return }
        if pressed == "use", let selected { onUse?(selected); return }
        if pressed.hasPrefix("slot-"), let slot = Int(pressed.dropFirst(5)) {
            let visible = inventory.items(on: page)
            selected = visible.indices.contains(slot) ? visible[slot] : nil
            HapticsService.shared.playSelection()
            rebuild()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { pressed = nil }
}
