import SpriteKit
import UIKit

// Input adapter. Gameplay rules live in Models and Systems.
extension RightDeckPuzzleScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil else { return }
        if (event?.allTouches?.count ?? touches.count) > 1 {
            trackedTouch = nil; dragPiece = nil; isSwipingGrid = false; entryVisible = false; clearPlaceHighlights(); rebuild()
            return
        }
        guard trackedTouch == nil, let touch = touches.first else { return }
        let point = touch.location(in: canvas)
        let names = Set(canvas.nodes(at: point).compactMap(\.name))
        if names.contains("debug") { toggleDebugMenu(); return }
        for world in PuzzleWorld.allCases where names.contains("debug-world-\(world.rawValue)") {
            enterDebugWorld(world)
            return
        }
        if names.contains("enter") || names.contains("entryPrompt") { enterSelected(); return }
        guard !progress.assembled else { return }
        // Transparent margins and sockets never steal a neighbouring piece's tap.
        let sorted = tiles.sorted { $0.value.zPosition > $1.value.zPosition }
        if let match = sorted.first(where: { id, node in
            (node.parent === canvas || viewport.contains(point)) && hitPaths[id]?.contains(node.convert(point, from: canvas)) == true
        }) {
            isSwipingGrid = false
            trackedTouch = touch
            entryVisible = false
            updateEntryPrompt()
            dragPiece = match.key; dragStart = point
            let tile = match.value
            let origin = tile.parent!.convert(tile.position, to: canvas)
            let scale = tile.parent === boardLayer ? zoom : 1
            canvas.safeAddChild(tile)
            tile.position = origin; tile.setScale(scale)
            dragHome = origin; moved = false
            tile.zPosition = 90
            updatePlaceHighlight(dragScreenPoint: origin)
        } else if viewport.contains(point) {
            // Touch down on empty grid space: swipe through grid!
            trackedTouch = touch
            isSwipingGrid = true
            swipeStartPoint = point
            swipeStartCameraOffset = cameraOffset
            moved = false
            entryVisible = false
            selected = nil
            clearPlaceHighlights()
            rebuild()
        } else {
            clearPlaceHighlights()
            entryVisible = false; selected = nil; rebuild()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil, let touch = trackedTouch, touches.contains(touch) else { return }
        let point = touch.location(in: canvas)
        if hypot(point.x - dragStart.x, point.y - dragStart.y) > 8 { moved = true }
        
        if isSwipingGrid {
            let deltaX = (point.x - swipeStartPoint.x) / zoom
            let deltaY = (point.y - swipeStartPoint.y) / zoom
            cameraOffset.x = swipeStartCameraOffset.x + deltaX
            cameraOffset.y = swipeStartCameraOffset.y + deltaY
            applyCamera()
        } else if let id = dragPiece, let tile = tiles[id] {
            if moved {
                tile.setScale(boardScale * zoom / (renderScales[id] ?? boardScale))
                let newPos = CGPoint(x: dragHome.x + point.x - dragStart.x, y: dragHome.y + point.y - dragStart.y)
                tile.position = newPos
                updatePlaceHighlight(dragScreenPoint: newPos)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil, let touch = trackedTouch, touches.contains(touch) else { return }
        if isSwipingGrid {
            isSwipingGrid = false
            trackedTouch = nil
            return
        }
        guard let id = dragPiece else { return }
        let releasePoint = touch.location(in: canvas)
        if hypot(releasePoint.x - dragStart.x, releasePoint.y - dragStart.y) > 8 { moved = true }
        trackedTouch = nil; dragPiece = nil
        if moved {
            // touchesEnded may arrive beyond the last touchesMoved position.
            let screenPoint = CGPoint(x: dragHome.x + releasePoint.x - dragStart.x,
                                      y: dragHome.y + releasePoint.y - dragStart.y)
            var accepted = true
            // Convert the release point into boardLayer space (accounts for zoom + pan).
            let point = boardLayer.convert(screenPoint, from: canvas)
            if viewport.contains(screenPoint) {
                let col = min(PuzzleCatalog.boardColumns - 1, max(0, Int((point.x - board.minX) / cell.width)))
                let row = min(PuzzleCatalog.boardRows - 1, max(0, Int((board.maxY - point.y) / cell.height)))
                // Accept the drop anywhere on or near the board (one-cell margin handles
                // slightly-off-edge drops while still rejecting truly blank-area drops).
                let snapMargin = max(cell.width, cell.height)
                let expanded = board.insetBy(dx: -snapMargin, dy: -snapMargin)
                if expanded.contains(point) {
                    let slot = row * PuzzleCatalog.boardColumns + col
                    accepted = session.place(id, at: slot)
                } else {
                    accepted = false
                }
            } else if deckBounds.contains(releasePoint) {
                session.remove(id)
                accepted = true
            } else {
                // A drop in the frame/gap restores the original slot, rather than discarding it.
                accepted = false
            }
            clearPlaceHighlights()
            selected = id; changed(focusInventory: true)
            if !accepted { message("Letakkan keping pada slot kosong di papan.") }
        } else {
            clearPlaceHighlights()
            selected = id; entryVisible = true; rebuild()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil else { return }
        if let touch = trackedTouch, touches.contains(touch) {
            trackedTouch = nil; dragPiece = nil; isSwipingGrid = false
            clearPlaceHighlights()
            rebuild()
        }
    }

    func setZoom(_ value: CGFloat) {
        let minimum = max(viewport.width / board.width, viewport.height / board.height)
        zoom = min(3, max(minimum, value))
        applyCamera()
    }

    func installGestures(on view: SKView) {
        guard gestures.isEmpty else { return }
        view.isMultipleTouchEnabled = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchBoard(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panBoard(_:)))
        pan.minimumNumberOfTouches = 1
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(rotatePiece(_:)))
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swipeDeck(_:)))
        left.direction = .up
        left.numberOfTouchesRequired = 2
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swipeDeck(_:)))
        right.direction = .down
        right.numberOfTouchesRequired = 2
        for gesture: UIGestureRecognizer in [pinch, pan, rotation, left, right] {
            gesture.delegate = self
            view.addGestureRecognizer(gesture)
            gestures.append(gesture)
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard allowsBoardGestures, let view else { return false }
        let scenePoint = convertPoint(fromView: gestureRecognizer.location(in: view))
        let point = canvas.convert(scenePoint, from: self)
        if gestureRecognizer is UISwipeGestureRecognizer { return deckBounds.contains(point) }
        if gestureRecognizer is UIRotationGestureRecognizer {
            return !progress.assembled && rotationTarget(at: point) != nil
        }
        if gestureRecognizer is UIPanGestureRecognizer {
            return viewport.contains(point) && dragPiece == nil && trackedTouch == nil
        }
        if gestureRecognizer is UIPinchGestureRecognizer {
            return viewport.contains(point) && dragPiece == nil
        }
        return viewport.contains(point)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestures.contains(where: { $0 === gestureRecognizer }) && gestures.contains(where: { $0 === otherGestureRecognizer })
    }

    @objc func pinchBoard(_ gesture: UIPinchGestureRecognizer) {
        guard allowsBoardGestures, dragPiece == nil else { return }
        if gesture.state == .began { trackedTouch = nil; dragPiece = nil; entryVisible = false; clearPlaceHighlights(); rebuild() }
        setZoom(zoom * gesture.scale)
        gesture.scale = 1
    }

    @objc func panBoard(_ gesture: UIPanGestureRecognizer) {
        guard allowsBoardGestures, dragPiece == nil, trackedTouch == nil, let view else { return }
        if gesture.state == .began { isSwipingGrid = false; entryVisible = false; clearPlaceHighlights(); rebuild() }
        let delta = gesture.translation(in: view)
        cameraOffset.x += delta.x / canvas.xScale / zoom
        cameraOffset.y -= delta.y / canvas.yScale / zoom
        
        gesture.setTranslation(CGPoint.zero, in: view)
        
        applyCamera()
    }

    func rotationTarget(at point: CGPoint) -> Int? {
        let candidates = tiles.filter { _, node in
            node.parent === canvas ? deckBounds.contains(point) : viewport.contains(point)
        }
        // Prefer the piece between the fingers; tolerate fingers straddling a small deck card.
        return candidates.min { lhs, rhs in
            let a = canvas.convert(CGPoint.zero, from: lhs.value)
            let b = canvas.convert(CGPoint.zero, from: rhs.value)
            return hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
        }.flatMap { id, node in
            let center = canvas.convert(CGPoint.zero, from: node)
            return hypot(center.x - point.x, center.y - point.y) < 120 ? id : nil
        }
    }

    @objc func rotatePiece(_ gesture: UIRotationGestureRecognizer) {
        guard !enteringMemory, let view else { return }
        if gesture.state == .began {
            let point = canvas.convert(convertPoint(fromView: gesture.location(in: view)), from: self)
            guard let id = rotationTarget(at: point) else { return }
            trackedTouch = nil; dragPiece = nil; entryVisible = false
            clearPlaceHighlights()
            selected = id; rotatingPiece = id
            rebuild()
            rotationStart = tiles[id]?.zRotation ?? 0
        }
        guard let id = rotatingPiece, let tile = tiles[id] else { return }
        // UIKit uses clockwise angles; SpriteKit's y-axis points upwards.
        tile.zRotation = rotationStart - gesture.rotation
        if gesture.state == .ended {
            let steps = Int((gesture.rotation / (.pi / 2)).rounded())
            let clockwiseTurns = ((steps % 4) + 4) % 4
            session.rotate(id, quarterTurns: clockwiseTurns)
            rotatingPiece = nil
            changed(focusInventory: true)
        } else if gesture.state == .cancelled || gesture.state == .failed {
            rotatingPiece = nil
            rebuild()
        }
    }

    @objc func swipeDeck(_ gesture: UISwipeGestureRecognizer) {
        guard allowsBoardGestures else { return }
        trackedTouch = nil; dragPiece = nil; entryVisible = false
        clearPlaceHighlights()
        let pages = max(1, (state.inventory(progress: progress).count + pageSize - 1) / pageSize)
        inventoryPage = min(pages - 1, max(0, inventoryPage + (gesture.direction == .up ? 1 : -1)))
        rebuild()
    }
}
