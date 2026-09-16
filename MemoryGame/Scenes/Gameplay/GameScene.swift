import SpriteKit
import UIKit

/// A 6-row by 8-column jigsaw photo, also used to enter the remembered locations.
final class GameScene: SKScene {
    private var progress: PrologueProgress { PrologueStore.shared.progress }
    private var state: JigsawProgress { progress.jigsaw ?? JigsawProgress() }
    private let textures = PuzzleTextureService()
    private let canvas = SKNode()
    private var tiles: [Int: SKNode] = [:]
    private var hitPaths: [Int: CGPath] = [:]
    private var renderScales: [Int: CGFloat] = [:]
    private var selected: Int?
    private var board = CGRect.zero
    private var boardScale: CGFloat = 1
    private var cell = CGSize.zero
    private var inventoryPage = 0
    private let pageSize = 10
    private var dragPiece: Int?
    private var dragStart = CGPoint.zero
    private var dragHome = CGPoint.zero
    private var moved = false
    private var confirmingRestart = false
    private var enteringMemory = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.12, blue: 0.14, alpha: 1)
        progress.prepareJigsaw()
        PrologueStore.shared.save()
        addChild(canvas)
        layoutPhoto()
    }
    override func didChangeSize(_ oldSize: CGSize) {
        guard canvas.parent != nil, !enteringMemory else { return }
        dragPiece = nil
        layoutPhoto()
    }
    private func layoutPhoto() {
        canvas.setScale(min(size.width / 1000, size.height / 600))
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rebuild()
    }
    private func rebuild(revealComplete: Bool = true) {
        canvas.removeAllChildren()
        tiles.removeAll(); hitPaths.removeAll(); renderScales.removeAll()
        board = CGRect(x: -470, y: -182, width: 600, height: 400)
        boardScale = board.width / PuzzleCatalog.canvasWidth
        cell = CGSize(width: board.width / CGFloat(PuzzleCatalog.columns), height: board.height / CGFloat(PuzzleCatalog.rows))
        canvas.storyLabel("KEPING KENANGAN  ·  JIGSAW 6 × 8", at: CGPoint(x: -110, y: 275), size: 22)
        canvas.storyLabel(progress.objective, at: CGPoint(x: -110, y: 243), size: 13, width: 760)
        let backing = SKShapeNode(rect: board, cornerRadius: 4)
        backing.fillColor = SKColor(white: 1, alpha: 0.025)
        backing.strokeColor = SKColor(white: 1, alpha: 0.28)
        backing.lineWidth = 1.5
        canvas.addChild(backing)
        // Neutral cell centres help dropping; they disclose no image or edge solution.
        for slot in 0..<JigsawCatalog.count {
            let dot = SKShapeNode(circleOfRadius: 1)
            dot.position = center(slot); dot.strokeColor = .clear
            dot.fillColor = SKColor(white: 1, alpha: 0.12)
            canvas.addChild(dot)
        }
        for (slot, placement) in state.placements.sorted(by: { $0.key < $1.key }) {
            addTile(placement.id, at: center(slot), inInventory: false)
        }
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
        canvas.storyLabel("\(installed) / 48 terpasang · Taruh di mana saja · Dekatkan 3 keping lewat sisi, lalu Masuk.",
                          at: CGPoint(x: -175, y: -204), size: 12, color: .lightGray, width: 660)
        let selectedText = selected.map {
            "\(JigsawCatalog.location(for: $0).title) · \((state.rotations[$0] ?? 0) * 90)° · Sambungan \(state.connectedIDs(to: $0).count)/3"
        } ?? "Pilih keping dari rangkaian yang ingin dimasuki"
        canvas.storyLabel(selectedText, at: CGPoint(x: -170, y: -232), size: 14)
        canvas.storyButton("Putar 90°", name: "rotate", at: CGPoint(x: -310, y: -274))
        canvas.storyButton("Simpan", name: "store", at: CGPoint(x: -180, y: -274))
        let ready = selected.map { state.canEnter($0) } ?? false
        let enterButton = canvas.storyButton(ready ? "Masuk" : "Terkunci", name: "enter", at: CGPoint(x: -50, y: -274))
        enterButton.alpha = ready ? 1 : 0.42
        canvas.storyButton("Mulai ulang", name: "restart", at: CGPoint(x: 330, y: -274), width: 140)
        if confirmingRestart { addRestartConfirmation() }
        if progress.assembled && revealComplete { showAssembled(animated: false) }
    }
    private func addRestartConfirmation() {
        let shade = SKShapeNode(rectOf: CGSize(width: 990, height: 590), cornerRadius: 10)
        shade.zPosition = 200; shade.fillColor = SKColor(white: 0.04, alpha: 0.97); shade.strokeColor = .clear
        canvas.addChild(shade)
        shade.storyLabel("Mulai ulang prolog? Progres tersimpan akan dihapus.", at: CGPoint(x: 0, y: 35), size: 18)
        shade.storyButton("Batal", name: "cancelRestart", at: CGPoint(x: -75, y: -35))
        shade.storyButton("Mulai ulang", name: "confirmRestart", at: CGPoint(x: 75, y: -35), width: 130)
    }
    private func center(_ slot: Int) -> CGPoint {
        CGPoint(x: board.minX + (CGFloat(slot % PuzzleCatalog.columns) + 0.5) * cell.width,
                y: board.maxY - (CGFloat(slot / PuzzleCatalog.columns) + 0.5) * cell.height)
    }
    private func addTile(_ id: Int, at position: CGPoint, inInventory: Bool) {
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
        let outline = SKShapeNode(path: path)
        outline.strokeColor = selected == id ? SKColor(red: 0.98, green: 0.80, blue: 0.42, alpha: 1) : SKColor(white: 1, alpha: 0.58)
        outline.lineWidth = selected == id ? 2.2 : 0.85
        outline.fillColor = .clear; outline.zPosition = 1
        tile.addChild(outline)
        canvas.addChild(tile)
        tiles[id] = tile; hitPaths[id] = path; renderScales[id] = scale
    }
    private func changed(focusInventory: Bool = false) {
        let wasComplete = progress.assembled
        progress.synchronizeJigsaw()
        if focusInventory, let selected, let index = state.inventory(progress: progress).firstIndex(of: selected) { inventoryPage = index / pageSize }
        PrologueStore.shared.save()
        rebuild(revealComplete: false)
        if progress.assembled { showAssembled(animated: !wasComplete) }
    }
    private func message(_ text: String) {
        canvas.childNode(withName: "statusMessage")?.removeFromParent()
        let label = canvas.storyLabel(text, at: CGPoint(x: -165, y: -232), size: 13, width: 650)
        label.name = "statusMessage"; label.zPosition = 100
        let backing = SKShapeNode(rectOf: CGSize(width: 650, height: 27), cornerRadius: 6)
        backing.fillColor = SKColor(red: 0.08, green: 0.12, blue: 0.14, alpha: 1); backing.strokeColor = .clear
        backing.zPosition = -1; label.addChild(backing)
        label.run(.sequence([.wait(forDuration: 3), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }
    private func showAssembled(animated: Bool) {
        guard canvas.childNode(withName: "assembled") == nil else { return }
        let photo = SKSpriteNode(imageNamed: PuzzleCatalog.imageName)
        photo.name = "assembled"; photo.size = board.size
        photo.position = CGPoint(x: board.midX, y: board.midY); photo.zPosition = 100; photo.alpha = animated ? 0 : 1
        canvas.addChild(photo); photo.run(.fadeIn(withDuration: 1.5))
        let caption = canvas.storyLabel("Kenangan tersusun · 48 keping", at: CGPoint(x: board.midX, y: -232), size: 21)
        caption.zPosition = 101
        for tile in tiles.values { tile.run(.sequence([.wait(forDuration: 1.5), .fadeOut(withDuration: 0.3)])) }
    }
    private func enterSelected() {
        guard !enteringMemory, let view else { return }
        guard let id = selected else { message("Pilih keping dari rangkaian yang ingin dimasuki."); return }
        guard state.canEnter(id) else {
            message("Sambungkan minimal 3 keping lewat sisinya, lalu tekan Masuk.")
            return
        }
        enteringMemory = true; dragPiece = nil
        progress.synchronizeJigsaw(); PrologueStore.shared.save()
        let reduced = UIAccessibility.isReduceMotionEnabled
        let duration: TimeInterval = reduced ? 0.18 : 0.65
        let veil = SKSpriteNode(color: SKColor(red: 0.10, green: 0.14, blue: 0.12, alpha: 1), size: size)
        veil.position = CGPoint(x: size.width / 2, y: size.height / 2); veil.alpha = 0; veil.zPosition = 500
        addChild(veil); veil.run(.fadeAlpha(to: 0.9, duration: duration))
        if !reduced, let tile = tiles[id] {
            let data = JigsawCatalog.data(for: id)
            let lift = SKSpriteNode(texture: textures.texture(for: data, dryVariant: id == JigsawCatalog.dryLakeID))
            lift.size = CGSize(width: data.width * boardScale * canvas.xScale, height: data.height * boardScale * canvas.yScale)
            lift.position = canvas.convert(tile.position, to: self)
            lift.zRotation = tile.zRotation; lift.zPosition = 501; addChild(lift)
            let zoom = max(size.width / lift.size.width, size.height / lift.size.height) * 1.6
            let action = SKAction.group([
                .move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: duration),
                .scale(to: zoom, duration: duration), .rotate(toAngle: 0, duration: duration, shortestUnitArc: true)
            ])
            action.timingMode = .easeInEaseOut; lift.run(action)
            canvas.run(.fadeAlpha(to: 0.18, duration: duration))
        }
        run(.sequence([.wait(forDuration: duration), .run { [weak self, weak view] in
            guard let self, let view, self.view === view else { return }
            let exploration = ExplorationScene(size: self.size, entry: JigsawCatalog.location(for: id))
            exploration.scaleMode = .resizeFill
            let transition = SKTransition.fade(with: SKColor(red: 0.87, green: 0.83, blue: 0.68, alpha: 1), duration: reduced ? 0.18 : 0.38)
            transition.pausesIncomingScene = false; transition.pausesOutgoingScene = false
            view.presentScene(exploration, transition: transition)
        }]), withKey: "enterMemory")
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, let touch = touches.first else { return }
        let point = touch.location(in: canvas)
        let names = Set(canvas.nodes(at: point).compactMap(\.name))
        if confirmingRestart {
            if names.contains("confirmRestart") {
                PrologueStore.shared.restart(); progress.prepareJigsaw()
                selected = nil; inventoryPage = 0; confirmingRestart = false; changed()
            } else if names.contains("cancelRestart") { confirmingRestart = false; rebuild() }
            return
        }
        if names.contains("previousPage") { inventoryPage = max(0, inventoryPage - 1); rebuild(); return }
        if names.contains("nextPage") {
            let pages = max(1, (state.inventory(progress: progress).count + pageSize - 1) / pageSize)
            inventoryPage = min(pages - 1, inventoryPage + 1); rebuild(); return
        }
        if names.contains("rotate") {
            if let selected {
                progress.jigsaw?.rotate(selected); changed(focusInventory: true)
            }
            return
        }
        if names.contains("store") {
            if let selected { progress.jigsaw?.remove(selected); changed(focusInventory: true) }; return
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
        guard !enteringMemory, let touch = touches.first, let id = dragPiece, let tile = tiles[id] else { return }
        let point = touch.location(in: canvas)
        if hypot(point.x - dragStart.x, point.y - dragStart.y) > 8 { moved = true }
        if moved {
            tile.setScale(boardScale / (renderScales[id] ?? boardScale))
            tile.position = CGPoint(x: dragHome.x + point.x - dragStart.x, y: dragHome.y + point.y - dragStart.y)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, let id = dragPiece else { return }
        defer { dragPiece = nil }
        if moved, let point = tiles[id]?.position {
            var accepted = true
            if board.contains(point) {
                let col = min(7, max(0, Int((point.x - board.minX) / cell.width)))
                let row = min(5, max(0, Int((board.maxY - point.y) / cell.height)))
                accepted = progress.placeJigsawPiece(id, at: row * 8 + col)
            } else { progress.jigsaw?.remove(id) }
            selected = id; changed(focusInventory: true)
            if !accepted { message("Keping belum tersedia atau berada di luar papan.") }
        } else { selected = id; rebuild() }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory else { return }
        dragPiece = nil; rebuild()
    }
}
