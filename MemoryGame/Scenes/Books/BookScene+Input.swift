import SpriteKit

extension BookScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackedTouch == nil, let touch = touches.first else { return }
        let point = touch.location(in: self)
        if closeBookIfNeeded(at: point) { return }
        guard containsBookPoint(point) else { return }
        trackedTouch = touch
        touchStartPoint = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackedTouch, touches.contains(touch), let start = touchStartPoint else { return }
        trackedTouch = nil
        touchStartPoint = nil
        let end = touch.location(in: self)
        let dx = end.x - start.x
        let dy = end.y - start.y
        if abs(dx) > 36 && abs(dx) > abs(dy) {
            if dx < 0 { flipPageUp() } else { flipPageBack() }
        } else if abs(dx) < 20 && abs(dy) < 20 && containsBookPoint(end) {
            if end.x < bookNode.position.x { flipPageBack() } else { flipPageUp() }
        } else if dy > 36 && abs(dy) > abs(dx) {
            if start.x < bookNode.position.x { flipPageBack() } else { flipPageUp() }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackedTouch, touches.contains(touch) else { return }
        trackedTouch = nil
        touchStartPoint = nil
    }
    func closeBookIfNeeded(at point: CGPoint) -> Bool {
        guard onClose != nil else { return false }
        let tappedClose = nodes(at: point).contains { node in
            var current: SKNode? = node
            while let inspected = current {
                if inspected.name == closeButtonName { return true }
                current = inspected.parent
            }
            return false
        }
        if tappedClose {
            trackedTouch = nil
            touchStartPoint = nil
            finishTurn()
            let close = onClose
            onClose = nil // A second tap during the transition must not reopen.
            close?()
        }
        return tappedClose
    }

}
