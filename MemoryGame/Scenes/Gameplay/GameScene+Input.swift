import SpriteKit
import UIKit

// Input adapter. Gameplay rules live in Models and Systems.
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, bag == nil, qte == nil, let touch = touches.first else { return }
        let point = touch.location(in: canvas)
        let names = Set(canvas.nodes(at: point).compactMap(\.name))
        if confirmingRestart {
            if names.contains("confirmRestart") {
                PrologueStore.shared.restart(); progress.prepareJigsaw()
                selected = nil; inventoryPage = 0; confirmingRestart = false; changed()
            } else if names.contains("cancelRestart") { confirmingRestart = false; rebuild() }
            return
        }
        if names.contains("bag") { openBag(); return }
        if names.contains("qte") { openQTE(); return }
        if let name = names.first(where: { $0.hasPrefix("world-") }),
           let id = Int(name.dropFirst(6)), state.canEnter(id) {
            selected = id; dragPiece = nil; rebuild(); return
        }
        if names.contains("previousPage") { inventoryPage = max(0, inventoryPage - 1); rebuild(); return }
        if names.contains("nextPage") {
            let pages = max(1, (state.inventory(progress: progress).count + pageSize - 1) / pageSize)
            inventoryPage = min(pages - 1, inventoryPage + 1); rebuild(); return
        }
        if names.contains("rotate") {
            if let selected {
                session.rotate(selected); changed(focusInventory: true)
            }
            return
        }
        if names.contains("store") {
            if let selected { session.remove(selected); changed(focusInventory: true) }; return
        }
        if names.contains("enter") { enterSelected(); return }
        if names.contains("restart") { confirmingRestart = true; rebuild(); return }
        guard !progress.assembled else { return }
        // Transparent margins and sockets never steal a neighbouring piece's tap.
        let sorted = tiles.sorted { $0.value.zPosition > $1.value.zPosition }
        guard let match = sorted.first(where: { id, node in
            hitPaths[id]?.contains(node.convert(point, from: canvas)) == true
        }) else { return }
        dragPiece = match.key; dragStart = point; dragHome = match.value.position; moved = false
        match.value.zPosition = 50
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, bag == nil, qte == nil, let touch = touches.first, let id = dragPiece, let tile = tiles[id] else { return }
        let point = touch.location(in: canvas)
        if hypot(point.x - dragStart.x, point.y - dragStart.y) > 8 { moved = true }
        if moved {
            tile.setScale(boardScale / (renderScales[id] ?? boardScale))
            tile.position = CGPoint(x: dragHome.x + point.x - dragStart.x, y: dragHome.y + point.y - dragStart.y)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, bag == nil, qte == nil, let id = dragPiece else { return }
        defer { dragPiece = nil }
        if moved, let point = tiles[id]?.position {
            var accepted = true
            if board.contains(point) {
                let col = min(PuzzleCatalog.boardColumns - 1, max(0, Int((point.x - board.minX) / cell.width)))
                let row = min(PuzzleCatalog.boardRows - 1, max(0, Int((board.maxY - point.y) / cell.height)))
                accepted = session.place(id, at: row * PuzzleCatalog.boardColumns + col)
            } else { session.remove(id) }
            selected = id; changed(focusInventory: true)
            if !accepted { message("Keping belum tersedia atau berada di luar papan.") }
        } else { selected = id; rebuild() }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, qte == nil else { return }
        dragPiece = nil; rebuild()
    }
}
