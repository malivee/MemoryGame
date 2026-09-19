import SpriteKit
import UIKit

// Rendering adapter. Gameplay rules live in Models and Systems.
extension GameScene {
    func layoutPhoto() {
        canvas.setScale(min(size.width / 1000, size.height / 600))
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rebuild()
    }

    func rebuild(revealComplete: Bool = true) {
        canvas.removeAllChildren()
        tiles.removeAll(); hitPaths.removeAll(); renderScales.removeAll()
        let boardWidth: CGFloat = 600
        let boardHeight = boardWidth * PuzzleCatalog.boardCanvasHeight / PuzzleCatalog.boardCanvasWidth
        board = CGRect(x: -470, y: -150, width: boardWidth, height: boardHeight)
        boardScale = board.width / PuzzleCatalog.boardCanvasWidth
        cell = CGSize(width: board.width / CGFloat(PuzzleCatalog.boardColumns), height: board.height / CGFloat(PuzzleCatalog.boardRows))
        canvas.storyLabel("KEPING KENANGAN  ·  3 KEPING PER MAP", at: CGPoint(x: -110, y: 275), size: 22)
        canvas.storyLabel(progress.objective, at: CGPoint(x: -110, y: 243), size: 13, width: 760)
        let backing = SKShapeNode(rect: board, cornerRadius: 4)
        backing.fillColor = SKColor(white: 1, alpha: 0.025)
        backing.strokeColor = SKColor(white: 1, alpha: 0)
        backing.lineWidth = 1.5
        canvas.addChild(backing)
        for (slot, placement) in state.placements.sorted(by: { $0.key < $1.key }) {
            addTile(placement.id, at: center(slot), inInventory: false)
        }
        addWorldLabels()
        let inventory = state.inventory(progress: progress)
        let pages = max(1, (inventory.count + pageSize - 1) / pageSize)
        inventoryPage = min(inventoryPage, pages - 1)
        canvas.storyLabel("INVENTORI · \(inventory.count) keping", at: CGPoint(x: 330, y: 214), size: 14, color: .lightGray)
        let page = inventory.dropFirst(inventoryPage * pageSize).prefix(pageSize)
        for (index, id) in page.enumerated() {
            addTile(id, at: CGPoint(x: 260 + CGFloat(index % 2) * 140, y: 166 - CGFloat(index / 2) * 79), inInventory: true)
        }
        canvas.storyButton("‹", name: "previousPage", at: CGPoint(x: 244, y: -215), width: 48)
        canvas.storyLabel("\(inventoryPage + 1) / \(pages)", at: CGPoint(x: 330, y: -215), size: 14)
        canvas.storyButton("›", name: "nextPage", at: CGPoint(x: 416, y: -215), width: 48)
        let installed = state.placements.count
        canvas.storyLabel("\(installed) / \(JigsawCatalog.availableIDs(progress: progress).count) keping terbuka terpasang · Susun 3 keping dari map yang sama.",
                          at: CGPoint(x: -175, y: -204), size: 12, color: .lightGray, width: 660)
        let selectedText: String
        if let id = selected, let entry = state.worldEntry(for: id, progress: progress) {
            let number = (PuzzleWorld.containing(id)?.rawValue ?? 0) + 1
            selectedText = "Dipilih: Dunia \(number) · \(worldName(entry)) · \(state.connectedIDs(to: id).count) keping · Siap masuk"
        } else {
            if let id = selected, let world = PuzzleWorld.containing(id) {
                selectedText = "Map \(world.rawValue + 1) · \(world.title) · Sambungan \(state.connectedIDs(to: id).count)/3"
            } else { selectedText = "Pilih keping atau rangkaian map yang ingin dimasuki" }
        }
        canvas.storyLabel(selectedText, at: CGPoint(x: -170, y: -232), size: 14)
        canvas.storyButton("Putar 90°", name: "rotate", at: CGPoint(x: -310, y: -274))
        canvas.storyButton("Simpan", name: "store", at: CGPoint(x: -180, y: -274))
        let destination = selected.flatMap { state.worldEntry(for: $0, progress: progress) }
        let ready = destination != nil
        let enterTitle = destination.map { "Masuk " + worldName($0) } ?? "Terkunci"
        let enterButton = canvas.storyButton(enterTitle, name: "enter", at: CGPoint(x: -50, y: -274))
        enterButton.alpha = ready ? 1 : 0.42
        canvas.storyButton("Uji QTE", name: "qte", at: CGPoint(x: 80, y: -274), width: 105)
        canvas.storyButton("Mulai ulang", name: "restart", at: CGPoint(x: 330, y: -274), width: 140)
        canvas.storyButton("Tas", name: "bag", at: CGPoint(x: 330, y: 267), width: 140)
        if confirmingRestart { addRestartConfirmation() }
        if progress.assembled && revealComplete { showAssembled(animated: false) }
    }

    func worldName(_ entry: MemoryPiece) -> String {
        if entry == .boundary { return "Batas Desa" }
        switch entry.region {
        case .house: return "Rumah"
        case .village: return "Desa"
        case .foothills: return "Bukit"
        }
    }

    func center(_ slot: Int) -> CGPoint {
        CGPoint(x: board.minX + (CGFloat(slot % PuzzleCatalog.boardColumns) + 0.5) * cell.width,
                y: board.maxY - (CGFloat(slot / PuzzleCatalog.boardColumns) + 0.5) * cell.height)
    }

    func addTile(_ id: Int, at position: CGPoint, inInventory: Bool) {
        let data = JigsawCatalog.data(for: id)
        let scale = inInventory ? min(70 / data.width, 70 / data.height) : boardScale
        let coreX = CGFloat(data.col - 1) * PuzzleCatalog.cellWidth - data.targetX + PuzzleCatalog.cellWidth / 2
        let coreY = CGFloat(data.row - 1) * PuzzleCatalog.cellHeight - data.targetY + PuzzleCatalog.cellHeight / 2
        let tile = SKNode()
        tile.position = position
        tile.zRotation = -CGFloat(state.rotations[id] ?? 0) * .pi / 2
        tile.zPosition = selected == id ? 40 : 10
        let image = SKSpriteNode(texture: textures.texture(for: data, dryVariant: id == JigsawCatalog.dryLakeID))
        image.size = CGSize(width: data.width * scale, height: data.height * scale)
        image.position = CGPoint(x: (data.width / 2 - coreX) * scale, y: (coreY - data.height / 2) * scale)
        tile.addChild(image)
        var transform = CGAffineTransform(a: scale, b: 0, c: 0, d: -scale, tx: -coreX * scale, ty: coreY * scale)
        let path = JigsawOutline.path(for: data).copy(using: &transform)!
        canvas.addChild(tile)
        tiles[id] = tile; hitPaths[id] = path; renderScales[id] = scale
    }

    func message(_ text: String) {
        canvas.childNode(withName: "statusMessage")?.removeFromParent()
        let label = canvas.storyLabel(text, at: CGPoint(x: -165, y: -232), size: 13, width: 650)
        label.name = "statusMessage"; label.zPosition = 100
        let backing = SKShapeNode(rectOf: CGSize(width: 650, height: 27), cornerRadius: 6)
        backing.fillColor = SKColor(red: 0.08, green: 0.12, blue: 0.14, alpha: 1); backing.strokeColor = .clear
        backing.zPosition = -1; label.addChild(backing)
        label.run(.sequence([.wait(forDuration: 3), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }

    func showAssembled(animated: Bool) {
        guard canvas.childNode(withName: "assembled") == nil else { return }
        let photo = SKSpriteNode(imageNamed: PuzzleCatalog.imageName)
        photo.name = "assembled"; photo.size = board.size
        photo.position = CGPoint(x: board.midX, y: board.midY); photo.zPosition = 100; photo.alpha = animated ? 0 : 1
        canvas.addChild(photo); photo.run(.fadeIn(withDuration: 1.5))
        let caption = canvas.storyLabel("Kenangan tersusun · 4 map · 12 keping", at: CGPoint(x: board.midX, y: -232), size: 21)
        caption.zPosition = 101
        for tile in tiles.values { tile.run(.sequence([.wait(forDuration: 1.5), .fadeOut(withDuration: 0.3)])) }
    }

    func worldColor(_ id: Int) -> SKColor {
        // Warna menunjukkan pilihan aktif, bukan identitas dunia yang berbeda.
        let active = selected.map { state.connectedIDs(to: id).contains($0) } ?? false
        return active ? SKColor(red: 1, green: 0.53, blue: 0.15, alpha: 1)
            : SKColor(white: 1, alpha: 0)
    }

    func addWorldLabels() {
        for group in worldGroups {
            guard let id = group.min(), let entry = state.worldEntry(for: id, progress: progress) else { continue }
            let index = PuzzleWorld.containing(id)?.rawValue ?? 0
            var bounds = CGRect.null
            for member in group {
                if let tile = tiles[member] { bounds = bounds.union(tile.calculateAccumulatedFrame()) }
            }
            let active = selected.map { group.contains($0) } ?? false
            let text = "\(active ? "✓ " : "")\(index + 1) · \(worldName(entry)) · \(group.count) keping"
            let y = bounds.minY - 18 >= board.minY + 15 ? bounds.minY - 18 : bounds.maxY + 18
            let badge = SKShapeNode(rectOf: CGSize(width: 168, height: 26), cornerRadius: 8)
            badge.position = CGPoint(x: min(board.maxX - 86, max(board.minX + 86, bounds.midX)),
                                     y: min(board.maxY - 15, max(board.minY + 15, y)))
            badge.name = "world-\(id)"; badge.zPosition = 60
            badge.fillColor = SKColor(red: 0.07, green: 0.12, blue: 0.14, alpha: 0.96)
            badge.strokeColor = worldColor(id); badge.lineWidth = active ? 1.4 : 0.7
            let label = badge.storyLabel(text, at: .zero, size: 12, color: worldColor(id))
            label.name = badge.name
            canvas.addChild(badge)
        }
    }

    func addRestartConfirmation() {
        let shade = SKShapeNode(rectOf: CGSize(width: 990, height: 590), cornerRadius: 10)
        shade.zPosition = 200; shade.fillColor = SKColor(white: 0.04, alpha: 0.97); shade.strokeColor = .clear
        canvas.addChild(shade)
        shade.storyLabel("Mulai ulang prolog? Progres tersimpan akan dihapus.", at: CGPoint(x: 0, y: 35), size: 18)
        shade.storyButton("Batal", name: "cancelRestart", at: CGPoint(x: -75, y: -35))
        shade.storyButton("Mulai ulang", name: "confirmRestart", at: CGPoint(x: 75, y: -35), width: 130)
    }
}
