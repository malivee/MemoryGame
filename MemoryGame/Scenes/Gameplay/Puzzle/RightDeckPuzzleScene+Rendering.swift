import SpriteKit
import UIKit

// Rendering adapter. Gameplay rules live in Models and Systems.
extension RightDeckPuzzleScene {
    func layoutPhoto() {
        canvas.setScale(min(size.width / 1000, size.height / 600))
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rebuild(resetCamera: true)
    }

    func rebuild(revealComplete: Bool = true, resetCamera: Bool = false) {
        if resetCamera { cameraOffset = .zero }
        // --- PASTIKAN SEMUA PROMPT LAMA DIHAPUS DI AWAL REBUILD ---
        canvas.childNode(withName: "emptyDeckPrompt")?.removeFromParent()
        canvas.childNode(withName: "entryPrompt")?.removeFromParent()
        
        boardLayer.removeFromParent()
        boardLayer.removeAllChildren()
        canvas.removeAllChildren()
        tiles.removeAll(); hitPaths.removeAll(); renderScales.removeAll()
        halfWidth = size.width / canvas.xScale / 2
        let unit = canvas.xScale
        let halfHeight = size.height / unit / 2
        let deckWidth: CGFloat = fixedDeckWidth
        deckBounds = CGRect(x: halfWidth - deckWidth, y: -halfHeight,
                            width: deckWidth, height: halfHeight * 2)
        viewport = CGRect(x: -halfWidth, y: -halfHeight,
                          width: max(1, halfWidth * 2 - deckWidth), height: halfHeight * 2)
        let deckCenterX = deckBounds.midX
        // Board fills the viewport width at zoom = 1. The 13x12 grid gives a spacious board area for free piece placement.
        boardScale = viewport.width / PuzzleCatalog.boardCanvasWidth
        let boardSize = CGSize(width: PuzzleCatalog.boardCanvasWidth * boardScale,
                               height: PuzzleCatalog.boardCanvasHeight * boardScale)
        board = CGRect(x: -boardSize.width / 2,
                       y: -boardSize.height / 2,
                       width: boardSize.width,
                       height: boardSize.height)
        cell = CGSize(width: board.width / CGFloat(PuzzleCatalog.boardColumns),
                      height: board.height / CGFloat(PuzzleCatalog.boardRows))
        let minZoom = max(viewport.width / board.width, viewport.height / board.height)
        if resetCamera || zoom < minZoom { zoom = minZoom }
        let crop = SKCropNode()
        let mask = SKShapeNode(rect: viewport)
        mask.fillColor = .white; mask.strokeColor = .clear
        crop.maskNode = mask
        canvas.safeAddChild(crop); crop.safeAddChild(boardLayer)
        applyCamera()
        if resetCamera { centerOnPieces() }
        
        // Backing node strictly covers the 13x12 board grid with warm beige fill and dark border outline.
        let backing = SKShapeNode(rect: board)
        backing.fillColor = SKColor(red: 0.82, green: 0.79, blue: 0.72, alpha: 1)
        backing.strokeColor = SKColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1)
        backing.lineWidth = 3
        boardLayer.safeAddChild(backing)
        
        // Subtle slot guides keep the enlarged board readable while panning.
        for row in 0...PuzzleCatalog.boardRows {
            let path = CGMutablePath()
            let y = board.minY + CGFloat(row) * cell.height
            path.move(to: CGPoint(x: board.minX, y: y)); path.addLine(to: CGPoint(x: board.maxX, y: y))
            let line = SKShapeNode(path: path); line.strokeColor = SKColor(white: 0, alpha: 0.08)
            boardLayer.safeAddChild(line)
        }
        for col in 0...PuzzleCatalog.boardColumns {
            let path = CGMutablePath()
            let x = board.minX + CGFloat(col) * cell.width
            path.move(to: CGPoint(x: x, y: board.minY)); path.addLine(to: CGPoint(x: x, y: board.maxY))
            let line = SKShapeNode(path: path); line.strokeColor = SKColor(white: 0, alpha: 0.08)
            boardLayer.safeAddChild(line)
        }
        for (slot, placement) in state.placements.sorted(by: { $0.key < $1.key }) {
            addTile(placement.id, at: center(slot), inInventory: false)
        }
        
        let currentWorld = selected.flatMap { PuzzleWorld.containing($0) }
            ?? PuzzleWorld.allCases.last(where: { $0.isUnlocked(in: progress) }) ?? .house
        let worldBadge = SKShapeNode(rectOf: CGSize(width: 180, height: 32), cornerRadius: 16)
        worldBadge.position = CGPoint(x: viewport.midX, y: viewport.maxY - 28)
        worldBadge.zPosition = 100
        worldBadge.fillColor = SKColor(red: 0.22, green: 0.25, blue: 0.22, alpha: 0.88)
        worldBadge.strokeColor = SKColor(red: 0.81, green: 0.72, blue: 0.52, alpha: 0.6)
        worldBadge.storyLabel(currentWorld.title, at: .zero, size: 14,
                              color: SKColor(red: 0.96, green: 0.92, blue: 0.81, alpha: 1))
        canvas.safeAddChild(worldBadge)
        // Akses langsung ke desa untuk review; tidak memakai syarat portal puzzle.
        let villageButton = canvas.storyButton("Area Desa", name: "villagePreview",
            at: CGPoint(x: viewport.minX + 88, y: viewport.maxY - 28), width: 140)
        villageButton.zPosition = 110
        villageButton.fillColor = worldBadge.fillColor
        villageButton.strokeColor = worldBadge.strokeColor

        let deck = SKShapeNode(rect: deckBounds)
        deck.zPosition = 65
        deck.fillColor = SKColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 0.9)
        deck.strokeColor = SKColor(red: 0.65, green: 0.52, blue: 0.35, alpha: 1)
        canvas.safeAddChild(deck)
        let deckTitle = canvas.storyLabel("Kepingan Puzzle", at: CGPoint(x: deckCenterX, y: deckBounds.maxY - 18), size: 13,
                                          color: SKColor(red: 0.92, green: 0.84, blue: 0.67, alpha: 1))
        deckTitle.zPosition = 70
        
        // HUD sits above the cropped board but below a dragged piece.
        let inventory = state.inventory(progress: progress)
        
        if !inventory.isEmpty {
            let pages = max(1, (inventory.count + pageSize - 1) / pageSize)
            inventoryPage = min(inventoryPage, pages - 1)
            let page = Array(inventory.dropFirst(inventoryPage * pageSize).prefix(pageSize))
            for (index, id) in page.enumerated() {
                let top = deckBounds.maxY - 78
                let bottom = deckBounds.minY + 16
                let spacing = min(88, (top - bottom) / CGFloat(max(1, page.count)))
                let piecePosition = CGPoint(x: deckCenterX, y: top - spacing * (CGFloat(index) + 0.5))
                addTile(id, at: piecePosition, inInventory: true)
            }
        }
        
        updateEntryPrompt()
        if progress.assembled && revealComplete { showAssembled(animated: false) }
        addDebugButton()
    }

    func worldName(_ entry: MemoryPiece) -> String {
        if entry == .echoesBoundary { return PuzzleWorld.echoesBoundary.title }
        if entry == .boundary { return "Batas Desa" }
        switch entry.region {
        case .house: return "Rumah"
        case .village: return "Desa"
        case .foothills: return "Bukit"
        case .boundary: return "Batas Desa"
        case .echoes: return PuzzleWorld.echoesBoundary.title
        }
    }

    func center(_ slot: Int) -> CGPoint {
        let col = slot % PuzzleCatalog.boardColumns
        let row = slot / PuzzleCatalog.boardColumns
        return CGPoint(x: board.minX + (CGFloat(col) + 0.5) * cell.width,
                y: board.maxY - (CGFloat(row) + 0.5) * cell.height)
    }

    func addTile(_ id: Int, at position: CGPoint, inInventory: Bool) {
        let data = JigsawCatalog.data(for: id)
        let scale = inInventory ? min(78 / data.width, 78 / data.height) : boardScale
        let coreX = CGFloat(data.col - 1) * PuzzleCatalog.cellWidth - data.targetX + PuzzleCatalog.cellWidth / 2
        let coreY = CGFloat(data.row - 1) * PuzzleCatalog.cellHeight - data.targetY + PuzzleCatalog.cellHeight / 2
        let tile = SKNode()
        tile.position = position
        tile.zRotation = -CGFloat(state.rotations[id] ?? 0) * .pi / 2
        tile.zPosition = inInventory ? (selected == id ? 69 : 68) : (selected == id ? 40 : 10)
        let image = SKSpriteNode(texture: textures.texture(for: data, dryVariant: id == JigsawCatalog.dryLakeID))
        image.size = CGSize(width: data.width * scale, height: data.height * scale)
        image.position = CGPoint(x: (data.width / 2 - coreX) * scale, y: (coreY - data.height / 2) * scale)
        tile.safeAddChild(image)
        var transform = CGAffineTransform(a: scale, b: 0, c: 0, d: -scale, tx: -coreX * scale, ty: coreY * scale)
        let path = JigsawOutline.path(for: data).copy(using: &transform)!
        if inInventory && selected == id {
            let selectedBacking = SKShapeNode(path: path)
            selectedBacking.fillColor = SKColor(red: 1, green: 0.79, blue: 0.40, alpha: 0.12)
            selectedBacking.strokeColor = SKColor(red: 1, green: 0.79, blue: 0.40, alpha: 0.85)
            selectedBacking.lineWidth = 3
            selectedBacking.glowWidth = 1.6
            selectedBacking.zPosition = -1
            tile.safeAddChild(selectedBacking)
        }
        // Inventori abu-abu; sambungan siap berwarna putih tipis; pilihan di papan oranye.
        let activeGroup = !inInventory && (selected.map { state.connectedIDs(to: id).contains($0) } ?? false)
        let raisedGroup = activeGroup && entryVisible && rotatingPiece == nil
            && (selected.flatMap { state.worldEntry(for: $0, progress: progress) } != nil)
        if raisedGroup {
            // Lift the artwork equally across all three pieces, preserving their joins
            // and the logical slot coordinates used for dragging and saving.
            tile.zPosition = 45
            let shadow = SKShapeNode(path: path)
            shadow.position = CGPoint(x: 2, y: -4)
            shadow.fillColor = SKColor(white: 0, alpha: 0.28)
            shadow.strokeColor = SKColor(white: 0, alpha: 0.12)
            shadow.lineWidth = 5
            shadow.glowWidth = 3
            shadow.zPosition = -1
            tile.safeAddChild(shadow)
            let lift: CGFloat = 6
            if UIAccessibility.isReduceMotionEnabled {
                image.position.y += lift
            } else {
                let action = SKAction.moveBy(x: 0, y: lift, duration: 0.16)
                action.timingMode = .easeOut
                image.run(action)
            }
        }
        (inInventory ? canvas : boardLayer).safeAddChild(tile)
        if inInventory { tile.zPosition = 75 }
        tiles[id] = tile; hitPaths[id] = path; renderScales[id] = scale
    }

    func message(_ text: String) {
        canvas.childNode(withName: "statusMessage")?.removeFromParent()
        let label = canvas.storyLabel(text, at: CGPoint(x: viewport.midX, y: viewport.minY + 32), size: 13, width: min(650, viewport.width - 32))
        label.name = "statusMessage"; label.zPosition = 100
        let backing = SKShapeNode(rectOf: CGSize(width: 650, height: 27), cornerRadius: 6)
        backing.fillColor = SKColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 1); backing.strokeColor = .clear
        backing.zPosition = -1; label.safeAddChild(backing)
        label.run(.sequence([.wait(forDuration: 3), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }

    func showAssembled(animated: Bool) {
        guard boardLayer.childNode(withName: "assembled") == nil else { return }
        let photo = SKSpriteNode(imageNamed: PuzzleCatalog.imageName)
        photo.name = "assembled"; photo.size = board.size
        photo.position = CGPoint(x: board.midX, y: board.midY); photo.zPosition = 100; photo.alpha = animated ? 0 : 1
        boardLayer.safeAddChild(photo); photo.run(.fadeIn(withDuration: 1.5))
        for tile in tiles.values { tile.run(.sequence([.wait(forDuration: 1.5), .fadeOut(withDuration: 0.3)])) }
    }

    func updateEntryPrompt() {
        canvas.childNode(withName: "entryPrompt")?.removeFromParent()
        guard entryVisible, !enteringMemory, rotatingPiece == nil, dragPiece == nil,
              let id = selected, let tile = tiles[id], tile.parent === boardLayer,
              let entry = state.worldEntry(for: id, progress: progress) else { return }
        let bounds = tile.calculateAccumulatedFrame()
        let top = canvas.convert(CGPoint(x: bounds.midX, y: bounds.maxY), from: boardLayer)
        let center = canvas.convert(tile.position, from: boardLayer)
        guard viewport.contains(center) else { return }
        let button = canvas.storyButton("Masuk " + worldName(entry), name: "enter",
                                        at: CGPoint(x: min(viewport.maxX - 100, max(viewport.minX + 100, top.x)),
                                                    y: min(viewport.maxY - 28, top.y + 30)), width: 180)
        button.name = "entryPrompt"
        button.zPosition = 110
        // storyButton already attaches the button to canvas.
        // The parent and label both resolve to the entry action.
        button.children.forEach { $0.name = "enter" }
    }

    func applyCamera() {
        let minZoom = max(viewport.width / board.width, viewport.height / board.height)
        if zoom < minZoom { zoom = minZoom }
        let limitX = max(0, (board.width * zoom - viewport.width) / 2)
        let limitY = max(0, (board.height * zoom - viewport.height) / 2)
        cameraOffset.x = min(limitX, max(-limitX, cameraOffset.x))
        cameraOffset.y = min(limitY, max(-limitY, cameraOffset.y))
        boardLayer.setScale(zoom)
        boardLayer.position = CGPoint(x: viewport.midX + cameraOffset.x, y: viewport.midY + cameraOffset.y)
        updateEntryPrompt()
    }

    func centerOnPieces() {
        let placedSlots: [Int]
        if let sel = selected, let slot = state.placements.first(where: { $0.value.id == sel })?.key {
            let groupIDs = state.connectedIDs(to: sel)
            let groupSlots = state.placements.compactMap { (s, p) in groupIDs.contains(p.id) ? s : nil }
            placedSlots = groupSlots.isEmpty ? [slot] : groupSlots
        } else {
            placedSlots = Array(state.placements.keys)
        }
        
        guard !placedSlots.isEmpty else {
            cameraOffset = .zero
            applyCamera()
            return
        }
        
        var totalX: CGFloat = 0
        var totalY: CGFloat = 0
        for slot in placedSlots {
            let pCenter = center(slot)
            totalX += pCenter.x
            totalY += pCenter.y
        }
        let avgX = totalX / CGFloat(placedSlots.count)
        let avgY = totalY / CGFloat(placedSlots.count)
        
        cameraOffset.x = -avgX * zoom
        cameraOffset.y = -avgY * zoom
        applyCamera()
    }
    func clearPlaceHighlights() {
        boardLayer.enumerateChildNodes(withName: "//candidateSlotHighlight") { node, _ in
            node.removeFromParent()
        }
    }

    func updatePlaceHighlight(dragScreenPoint: CGPoint) {
        // Highlight the board slot under the drag position
        boardLayer.childNode(withName: "candidateSlotHighlight")?.removeFromParent()
        guard viewport.contains(dragScreenPoint) else { return }
        let point = boardLayer.convert(dragScreenPoint, from: canvas)
        guard board.contains(point) else { return }

        let col = min(PuzzleCatalog.boardColumns - 1, max(0, Int((point.x - board.minX) / cell.width)))
        let row = min(PuzzleCatalog.boardRows - 1, max(0, Int((board.maxY - point.y) / cell.height)))
        let slot = row * PuzzleCatalog.boardColumns + col

        let slotRect = CGRect(x: board.minX + CGFloat(col) * cell.width,
                              y: board.maxY - CGFloat(row + 1) * cell.height,
                              width: cell.width, height: cell.height)
        let isOccupied = state.placements[slot] != nil && (dragPiece == nil || state.placements[slot]?.id != dragPiece)
        let highlight = SKShapeNode(rect: slotRect.insetBy(dx: 2, dy: 2), cornerRadius: 4)
        highlight.name = "candidateSlotHighlight"
        highlight.fillColor = isOccupied ? SKColor(red: 0.85, green: 0.25, blue: 0.20, alpha: 0.14)
                                         : SKColor(red: 1.0, green: 0.88, blue: 0.20, alpha: 0.18)
        highlight.strokeColor = isOccupied ? SKColor(red: 0.90, green: 0.30, blue: 0.25, alpha: 0.80)
                                           : SKColor(red: 1.0, green: 0.88, blue: 0.20, alpha: 0.85)
        highlight.lineWidth = 2.2
        highlight.glowWidth = 4.0
        highlight.zPosition = 8
        boardLayer.safeAddChild(highlight)
    }

}
