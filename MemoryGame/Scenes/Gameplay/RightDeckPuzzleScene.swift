// Penjelasan file: RightDeckPuzzleScene.swift
// Alternative layout copied from GameScene: full-width board and fixed right-side deck.
// Layar utama papan jigsaw: menampilkan inventori, menerima drag, rotasi, dan pemilihan keping.
// Perubahan papan diteruskan ke model lalu disimpan; tombol Masuk memeriksa rangkaian minimal tiga keping.
// Scene ini juga menampilkan foto selesai dan animasi perpindahan menuju eksplorasi.

import SpriteKit
import UIKit

/// Helper extension untuk memastikan node aman ditambahkan tanpa memicu crash `already has a parent`
private extension SKNode {
    func safeAddChild(_ node: SKNode) {
        if node.parent != self {
            node.removeFromParent()
            self.addChild(node)
        }
    }
}

/// A 10-column by 4-row jigsaw photo, also used to enter the remembered locations.
final class RightDeckPuzzleScene: SKScene, UIGestureRecognizerDelegate {
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
    private let pageSize = 5
    private var dragPiece: Int?
    private var dragStart = CGPoint.zero
    private var dragHome = CGPoint.zero
    private var moved = false
    private var enteringMemory = false
    private let boardLayer = SKNode()
    private var viewport = CGRect.zero
    private var zoom: CGFloat = 1
    private var cameraOffset = CGPoint.zero
    private var gestures: [UIGestureRecognizer] = []
    private var halfWidth: CGFloat = 500
    private var deckBounds = CGRect.zero
    private var entryVisible = false
    private var rotatingPiece: Int?
    private var rotationStart: CGFloat = 0
    private var trackedTouch: UITouch?
    var bagSelectedPiece: Int?
    
    // Memuat progres, menyiapkan puzzle, lalu membangun papan saat scene dibuka.
    override func didMove(to view: SKView) {
        // Background kekuningan / krem hangat
        backgroundColor = SKColor(red: 0.91, green: 0.89, blue: 0.83, alpha: 1.0)
        progress.prepareJigsaw()
        PrologueStore.shared.save()
        canvas.removeFromParent()
        addChild(canvas)
        if let id = bagSelectedPiece {
            selected = id
            if let index = state.inventory(progress: progress).firstIndex(of: id) { inventoryPage = index / pageSize }
            bagSelectedPiece = nil
        }
        layoutPhoto()
        installGestures(on: view)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        guard canvas.parent != nil, !enteringMemory else { return }
        dragPiece = nil
        layoutPhoto()
    }
    
    // Menyesuaikan skala papan dengan ukuran layar.
    private func layoutPhoto() {
        canvas.setScale(min(size.width / 1000, size.height / 600))
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rebuild()
    }
    
    // Menggambar ulang papan, inventori, dan tombol berdasarkan state terbaru.
    private func rebuild(revealComplete: Bool = true) {
        // --- PASTIKAN SEMUA PROMPT LAMA DIHAPUS DI AWAL REBUILD ---
        canvas.childNode(withName: "emptyDeckPrompt")?.removeFromParent()
        canvas.childNode(withName: "entryPrompt")?.removeFromParent()
        
        boardLayer.removeFromParent()
        boardLayer.removeAllChildren()
        canvas.removeAllChildren()
        tiles.removeAll(); hitPaths.removeAll(); renderScales.removeAll()
        halfWidth = size.width / canvas.xScale / 2
        let insets = view?.safeAreaInsets ?? .zero
        let unit = canvas.xScale
        let halfHeight = size.height / unit / 2
        let rightPadding = insets.right / unit
        let deckWidth: CGFloat = 160 + rightPadding
        deckBounds = CGRect(x: halfWidth - deckWidth, y: -halfHeight,
                            width: deckWidth, height: halfHeight * 2)
        viewport = CGRect(x: -halfWidth, y: -halfHeight,
                          width: max(1, halfWidth * 2 - deckWidth - 6), height: halfHeight * 2)
        let width = viewport.width
        let deckCenterX = deckBounds.minX + 80
        // Preserve image proportions while the deck occupies the right side.
        let boardHeight = width * PuzzleCatalog.canvasHeight / PuzzleCatalog.canvasWidth
        board = CGRect(x: -width / 2, y: -boardHeight / 2, width: width, height: boardHeight)
        boardScale = board.width / PuzzleCatalog.canvasWidth
        cell = CGSize(width: board.width / CGFloat(PuzzleCatalog.columns), height: board.height / CGFloat(PuzzleCatalog.rows))
        let crop = SKCropNode()
        let shadow = SKShapeNode(rect: viewport.offsetBy(dx: 0, dy: -5).insetBy(dx: -7, dy: -7), cornerRadius: 13)
        shadow.fillColor = SKColor(red: 0.26, green: 0.20, blue: 0.13, alpha: 0.15)
        shadow.strokeColor = .clear
        canvas.safeAddChild(shadow)
        let frame = SKShapeNode(rect: viewport.insetBy(dx: -6, dy: -6), cornerRadius: 12)
        frame.fillColor = SKColor(red: 0.48, green: 0.37, blue: 0.24, alpha: 1)
        frame.strokeColor = SKColor(red: 0.68, green: 0.55, blue: 0.36, alpha: 1)
        frame.lineWidth = 2
        canvas.safeAddChild(frame)
        let mask = SKShapeNode(rect: viewport, cornerRadius: 7)
        mask.fillColor = .white; mask.strokeColor = .clear
        crop.maskNode = mask
        canvas.safeAddChild(crop); crop.safeAddChild(boardLayer)
        applyCamera()
        
        let backing = SKShapeNode(rect: board)
        backing.fillColor = SKColor(red: 0.82, green: 0.79, blue: 0.72, alpha: 1)
        backing.strokeColor = SKColor(white: 0, alpha: 0.15)
        boardLayer.safeAddChild(backing)
        
        // Subtle slot guides keep the enlarged board readable while panning.
        for row in 0...PuzzleCatalog.rows {
            let path = CGMutablePath()
            let y = board.minY + CGFloat(row) * cell.height
            path.move(to: CGPoint(x: board.minX, y: y)); path.addLine(to: CGPoint(x: board.maxX, y: y))
            let line = SKShapeNode(path: path); line.strokeColor = SKColor(white: 0, alpha: 0.08)
            boardLayer.safeAddChild(line)
        }
        for col in 0...PuzzleCatalog.columns {
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
        worldBadge.position = CGPoint(x: viewport.midX, y: viewport.maxY - insets.top / unit - 28)
        worldBadge.zPosition = 100
        worldBadge.fillColor = SKColor(red: 0.22, green: 0.25, blue: 0.22, alpha: 0.88)
        worldBadge.strokeColor = SKColor(red: 0.81, green: 0.72, blue: 0.52, alpha: 0.6)
        worldBadge.storyLabel(currentWorld.title, at: .zero, size: 14,
                              color: SKColor(red: 0.96, green: 0.92, blue: 0.81, alpha: 1))
        canvas.safeAddChild(worldBadge)

        let deck = SKShapeNode(rect: deckBounds)
        deck.zPosition = 65
        deck.fillColor = SKColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 0.9)
        deck.strokeColor = SKColor(red: 0.65, green: 0.52, blue: 0.35, alpha: 1)
        canvas.safeAddChild(deck)
        let deckTitle = canvas.storyLabel("Kepingan Puzzle", at: CGPoint(x: deckCenterX, y: deckBounds.maxY - insets.top / unit - 25), size: 14,
                                         color: SKColor(red: 0.92, green: 0.84, blue: 0.67, alpha: 1))
        deckTitle.zPosition = 70
        
        // HUD sits above the cropped board but below a dragged piece.
        let inventory = state.inventory(progress: progress)
        
        if !inventory.isEmpty {
            let pages = max(1, (inventory.count + pageSize - 1) / pageSize)
            inventoryPage = min(inventoryPage, pages - 1)
            let page = Array(inventory.dropFirst(inventoryPage * pageSize).prefix(pageSize))
            for (index, id) in page.enumerated() {
                let top = deckBounds.maxY - insets.top / unit - 65
                let bottom = deckBounds.minY + insets.bottom / unit + 12
                let spacing = min(96, (top - bottom) / CGFloat(max(1, page.count)))
                let piecePosition = CGPoint(x: deckCenterX, y: top - spacing * (CGFloat(index) + 0.5))
                if selected == id {
                    let halo = SKShapeNode(circleOfRadius: 46)
                    halo.position = piecePosition
                    halo.zPosition = 66
                    halo.fillColor = SKColor(red: 1, green: 0.79, blue: 0.40, alpha: 0.10)
                    halo.strokeColor = SKColor(red: 1, green: 0.79, blue: 0.40, alpha: 0.70)
                    halo.lineWidth = 2
                    canvas.safeAddChild(halo)
                }
                addTile(id, at: piecePosition, inInventory: true)
            }
        }
        
        updateEntryPrompt()
        if progress.assembled && revealComplete { showAssembled(animated: false) }
    }
    
    private func worldName(_ entry: MemoryPiece) -> String {
        if entry == .boundary { return "Batas Desa" }
        switch entry.region {
        case .house: return "Rumah"
        case .village: return "Desa"
        case .foothills: return "Bukit"
        }
    }
    
    private func updateEntryPrompt() {
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
    
    // Mengubah indeks slot menjadi titik tengah pada papan SpriteKit.
    private func center(_ slot: Int) -> CGPoint {
        CGPoint(x: board.minX + (CGFloat(slot % PuzzleCatalog.columns) + 0.5) * cell.width,
                y: board.maxY - (CGFloat(slot / PuzzleCatalog.columns) + 0.5) * cell.height)
    }
    
    // Membuat gambar keping, outline, dan bentuk hit-test yang mengabaikan bagian transparan.
    private func addTile(_ id: Int, at position: CGPoint, inInventory: Bool) {
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
        let outline = SKShapeNode(path: path)
        // Inventori abu-abu; sambungan siap berwarna putih tipis; pilihan di papan oranye.
        let connected = !inInventory && state.connectedIDs(to: id).count >= 2
        let activeGroup = !inInventory && (selected.map { state.connectedIDs(to: id).contains($0) } ?? false)
        let raisedGroup = activeGroup && entryVisible && rotatingPiece == nil
            && (selected.flatMap { state.worldEntry(for: $0, progress: progress) } != nil)
        if inInventory {
            outline.strokeColor = SKColor(white: selected == id ? 0.85 : 0.65, alpha: 0.85)
        } else if raisedGroup {
            outline.strokeColor = SKColor(red: 1, green: 0.82, blue: 0.37, alpha: 1)
        } else if activeGroup {
            outline.strokeColor = SKColor(red: 1, green: 0.53, blue: 0.15, alpha: 1)
        } else {
            outline.strokeColor = connected ? SKColor(white: 1, alpha: 0.72) : SKColor(white: 0.65, alpha: 0.7)
        }
        outline.lineWidth = raisedGroup ? 4 : (activeGroup ? 1.8 : (selected == id ? 1.2 : 0.85))
        outline.glowWidth = raisedGroup ? 2.5 : 0
        outline.fillColor = .clear; outline.zPosition = 1
        tile.safeAddChild(outline)
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
                outline.position.y = lift
            } else {
                let action = SKAction.moveBy(x: 0, y: lift, duration: 0.16)
                action.timingMode = .easeOut
                image.run(action)
                outline.run(action)
            }
        }
        (inInventory ? canvas : boardLayer).safeAddChild(tile)
        if inInventory { tile.zPosition = 75 }
        tiles[id] = tile; hitPaths[id] = path; renderScales[id] = scale
    }
    
    // Menyinkronkan area cerita, menyimpan progres, lalu memperbarui tampilan setelah perubahan keping.
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
        let label = canvas.storyLabel(text, at: CGPoint(x: viewport.midX, y: viewport.minY + 32), size: 13, width: min(650, viewport.width - 32))
        label.name = "statusMessage"; label.zPosition = 100
        let backing = SKShapeNode(rectOf: CGSize(width: 650, height: 27), cornerRadius: 6)
        backing.fillColor = SKColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 1); backing.strokeColor = .clear
        backing.zPosition = -1; label.safeAddChild(backing)
        label.run(.sequence([.wait(forDuration: 3), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }
    
    // Menampilkan foto lengkap setelah syarat penyelesaian terpenuhi.
    private func showAssembled(animated: Bool) {
        guard boardLayer.childNode(withName: "assembled") == nil else { return }
        let photo = SKSpriteNode(imageNamed: PuzzleCatalog.imageName)
        photo.name = "assembled"; photo.size = board.size
        photo.position = CGPoint(x: board.midX, y: board.midY); photo.zPosition = 100; photo.alpha = animated ? 0 : 1
        boardLayer.safeAddChild(photo); photo.run(.fadeIn(withDuration: 1.5))
        for tile in tiles.values { tile.run(.sequence([.wait(forDuration: 1.5), .fadeOut(withDuration: 0.3)])) }
    }
    
    // Memastikan keping terhubung minimal tiga, kemudian menjalankan transisi ke area kenangannya.
    private func enterSelected() {
        guard !enteringMemory, let view else { return }
        guard let id = selected else { message("Pilih keping dari rangkaian yang ingin dimasuki."); return }
        guard state.canEnter(id) else {
            message("Susun 3 keping dari map yang sama sesuai gambar dan putar hingga tegak.")
            return
        }
        guard let entry = state.worldEntry(for: id, progress: progress) else { return }
        let locations = state.worldLocations(for: id)
        let connected = state.connectedIDs(to: id)
        enteringMemory = true; dragPiece = nil
        progress.synchronizeJigsaw(); PrologueStore.shared.save()
        let reduced = UIAccessibility.isReduceMotionEnabled
        let duration: TimeInterval = reduced ? 0.22 : 1.25
        let veil = SKSpriteNode(color: SKColor(red: 0.91, green: 0.89, blue: 0.83, alpha: 1), size: size)
        veil.position = CGPoint(x: size.width / 2, y: size.height / 2); veil.alpha = 0; veil.zPosition = 500
        safeAddChild(veil); veil.run(.fadeAlpha(to: 0.9, duration: duration))
        // Angkat seluruh rangkaian agar portal terasa berasal dari satu dunia, bukan satu keping.
        let members = connected.compactMap { tiles[$0] }
        let count = CGFloat(max(1, members.count))
        let center = CGPoint(x: members.reduce(CGFloat(0)) { $0 + $1.position.x } / count,
                             y: members.reduce(CGFloat(0)) { $0 + $1.position.y } / count)
        let origin = boardLayer.convert(center, to: self)
        if !reduced {
            let lift = SKNode(); lift.position = origin; lift.zPosition = 501
            lift.setScale(canvas.xScale * zoom); safeAddChild(lift)
            for member in members {
                let copy = member.copy() as! SKNode
                copy.position = CGPoint(x: member.position.x - center.x, y: member.position.y - center.y)
                lift.safeAddChild(copy)
            }
            let action = SKAction.group([
                .move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: duration),
                .scale(to: canvas.xScale * zoom * 2.6, duration: duration), .fadeOut(withDuration: duration)
            ])
            action.timingMode = .easeInEaseOut; lift.run(action)
            canvas.run(.fadeAlpha(to: 0.1, duration: duration))
        }
        MemoryPortal.play(on: self, origin: origin, inward: true, duration: duration)
        run(.sequence([.wait(forDuration: duration), .run { [weak self, weak view] in
            guard let self, let view, self.view === view else { return }
            let exploration = ExplorationScene(size: self.size, entry: entry, worldLocations: locations)
            exploration.scaleMode = .resizeFill
            let transition = SKTransition.fade(with: SKColor(red: 0.87, green: 0.83, blue: 0.68, alpha: 1), duration: reduced ? 0.18 : 0.38)
            transition.pausesIncomingScene = false; transition.pausesOutgoingScene = false
            view.presentScene(exploration, transition: transition)
        }]), withKey: "enterMemory")
    }
    
    // Membedakan tombol dan pemilihan keping, lalu menyiapkan posisi awal drag.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil else { return }
        if (event?.allTouches?.count ?? touches.count) > 1 {
            trackedTouch = nil; dragPiece = nil; entryVisible = false; rebuild()
            return
        }
        guard trackedTouch == nil, let touch = touches.first else { return }
        let point = touch.location(in: canvas)
        let names = Set(canvas.nodes(at: point).compactMap(\.name))
        if names.contains("enter") || names.contains("entryPrompt") { enterSelected(); return }
        guard !progress.assembled else { return }
        // Transparent margins and sockets never steal a neighbouring piece's tap.
        let sorted = tiles.sorted { $0.value.zPosition > $1.value.zPosition }
        guard let match = sorted.first(where: { id, node in
            (node.parent === canvas || viewport.contains(point)) && hitPaths[id]?.contains(node.convert(point, from: canvas)) == true
        }) else { entryVisible = false; selected = nil; rebuild(); return }
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
    }
    
    // Memindahkan keping mengikuti sentuhan dan membedakan drag dari ketukan biasa.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil, let touch = trackedTouch, touches.contains(touch), let id = dragPiece, let tile = tiles[id] else { return }
        let point = touch.location(in: canvas)
        if hypot(point.x - dragStart.x, point.y - dragStart.y) > 8 { moved = true }
        if moved {
            tile.setScale(boardScale * zoom / (renderScales[id] ?? boardScale))
            tile.position = CGPoint(x: dragHome.x + point.x - dragStart.x, y: dragHome.y + point.y - dragStart.y)
        }
    }
    
    // Mengubah posisi lepas menjadi slot; drop di luar papan mengembalikan keping ke inventori.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil, let touch = trackedTouch, touches.contains(touch), let id = dragPiece else { return }
        let releasePoint = touch.location(in: canvas)
        if hypot(releasePoint.x - dragStart.x, releasePoint.y - dragStart.y) > 8 { moved = true }
        trackedTouch = nil; dragPiece = nil
        if moved {
            // touchesEnded may arrive beyond the last touchesMoved position.
            let screenPoint = CGPoint(x: dragHome.x + releasePoint.x - dragStart.x,
                                      y: dragHome.y + releasePoint.y - dragStart.y)
            let point = boardLayer.convert(screenPoint, from: canvas)
            var accepted = true
            if viewport.contains(screenPoint), board.contains(point) {
                let col = min(7, max(0, Int((point.x - board.minX) / cell.width)))
                let row = min(5, max(0, Int((board.maxY - point.y) / cell.height)))
                let slot = row * PuzzleCatalog.columns + col
                if let occupant = state.placements[slot], occupant.id != id {
                    accepted = false
                } else {
                    accepted = progress.placeJigsawPiece(id, at: slot)
                }
            } else if deckBounds.contains(releasePoint) {
                progress.jigsaw?.remove(id)
            } else {
                // A drop in the frame/gap restores the original slot, rather than discarding it.
                accepted = false
            }
            selected = id; changed(focusInventory: true)
            if !accepted { message("Letakkan keping pada slot kosong di papan.") }
        } else { selected = id; entryVisible = true; rebuild() }
    }
    
    // Membatalkan drag ketika sentuhan terputus dan memulihkan tampilan dari state.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, rotatingPiece == nil else { return }
        trackedTouch = nil; dragPiece = nil; rebuild()
    }
    
    private var allowsBoardGestures: Bool {
        !enteringMemory && rotatingPiece == nil
    }
    private func applyCamera() {
        let limitX = max(0, (board.width * zoom - viewport.width) / 2)
        let limitY = max(0, (board.height * zoom - viewport.height) / 2)
        cameraOffset.x = min(limitX, max(-limitX, cameraOffset.x))
        cameraOffset.y = min(limitY, max(-limitY, cameraOffset.y))
        boardLayer.setScale(zoom)
        boardLayer.position = CGPoint(x: viewport.midX + cameraOffset.x, y: viewport.midY + cameraOffset.y)
        updateEntryPrompt()
    }
    private func setZoom(_ value: CGFloat) {
        let minimum = min(viewport.width / board.width, viewport.height / board.height)
        zoom = min(3, max(minimum, value))
        applyCamera()
    }
    private func installGestures(on view: SKView) {
        guard gestures.isEmpty else { return }
        view.isMultipleTouchEnabled = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchBoard(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panBoard(_:)))
        pan.minimumNumberOfTouches = 2
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
        return viewport.contains(point)
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestures.contains(where: { $0 === gestureRecognizer }) && gestures.contains(where: { $0 === otherGestureRecognizer })
    }
    @objc private func pinchBoard(_ gesture: UIPinchGestureRecognizer) {
        guard allowsBoardGestures else { return }
        if gesture.state == .began { trackedTouch = nil; dragPiece = nil; entryVisible = false; rebuild() }
        setZoom(zoom * gesture.scale)
        gesture.scale = 1
    }
    @objc private func panBoard(_ gesture: UIPanGestureRecognizer) {
        guard allowsBoardGestures, let view else { return }
        if gesture.state == .began { dragPiece = nil; entryVisible = false; rebuild() }
        let delta = gesture.translation(in: view)
        cameraOffset.x += delta.x / canvas.xScale
        cameraOffset.y -= delta.y / canvas.yScale
        
        gesture.setTranslation(CGPoint.zero, in: view)
        
        applyCamera()
    }
    
    private func rotationTarget(at point: CGPoint) -> Int? {
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
    @objc private func rotatePiece(_ gesture: UIRotationGestureRecognizer) {
        guard !enteringMemory, let view else { return }
        if gesture.state == .began {
            let point = canvas.convert(convertPoint(fromView: gesture.location(in: view)), from: self)
            guard let id = rotationTarget(at: point) else { return }
            trackedTouch = nil; dragPiece = nil; entryVisible = false
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
            for _ in 0..<clockwiseTurns { progress.jigsaw?.rotate(id) }
            rotatingPiece = nil
            changed(focusInventory: true)
        } else if gesture.state == .cancelled || gesture.state == .failed {
            rotatingPiece = nil
            rebuild()
        }
    }
    @objc private func swipeDeck(_ gesture: UISwipeGestureRecognizer) {
        guard allowsBoardGestures else { return }
        trackedTouch = nil; dragPiece = nil; entryVisible = false
        let pages = max(1, (state.inventory(progress: progress).count + pageSize - 1) / pageSize)
        inventoryPage = min(pages - 1, max(0, inventoryPage + (gesture.direction == .up ? 1 : -1)))
        rebuild()
    }
    override func willMove(from view: SKView) {
        gestures.forEach { view.removeGestureRecognizer($0) }
        gestures.removeAll()
    }
}
