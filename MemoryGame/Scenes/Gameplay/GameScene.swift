// Penjelasan file: GameScene.swift
// Layar utama papan jigsaw: menampilkan inventori, menerima drag, rotasi, dan pemilihan keping.
// Perubahan papan diteruskan ke model lalu disimpan; tombol Masuk memeriksa rangkaian minimal tiga keping.
// Scene ini juga menampilkan foto selesai dan animasi perpindahan menuju eksplorasi.

import SpriteKit
import UIKit

/// A 10-column by 4-row jigsaw photo, also used to enter the remembered locations.
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
    private var bag: BagOverlay?
    private var qte: QuickTimeEventNode?
    var bagSelectedPiece: Int?

    // Memuat progres, menyiapkan puzzle, lalu membangun papan saat scene dibuka.
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.12, blue: 0.14, alpha: 1)
        progress.prepareJigsaw()
        PrologueStore.shared.save()
        if canvas.parent == nil { addChild(canvas) }
        if let id = bagSelectedPiece {
            selected = id
            if let index = state.inventory(progress: progress).firstIndex(of: id) { inventoryPage = index / pageSize }
            bagSelectedPiece = nil
        }
        layoutPhoto()
    }
    override func didChangeSize(_ oldSize: CGSize) {
        qte?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        guard canvas.parent != nil, !enteringMemory else { return }
        dragPiece = nil
        layoutPhoto()
        bag?.resize(to: size)
    }
    // Menyesuaikan skala papan dengan ukuran layar.
    private func layoutPhoto() {
        canvas.setScale(min(size.width / 1000, size.height / 600))
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rebuild()
    }
    // Menggambar ulang papan, inventori, dan tombol berdasarkan state terbaru.
    private func rebuild(revealComplete: Bool = true) {
        canvas.removeAllChildren()
        tiles.removeAll(); hitPaths.removeAll(); renderScales.removeAll()
        let boardWidth: CGFloat = 600
        let boardHeight = boardWidth * PuzzleCatalog.canvasHeight / PuzzleCatalog.canvasWidth
        board = CGRect(x: -470, y: -150, width: boardWidth, height: boardHeight)
        boardScale = board.width / PuzzleCatalog.canvasWidth
        cell = CGSize(width: board.width / CGFloat(PuzzleCatalog.columns), height: board.height / CGFloat(PuzzleCatalog.rows))
        canvas.storyLabel("KEPING KENANGAN  ·  3 KEPING PER MAP", at: CGPoint(x: -110, y: 275), size: 22)
        canvas.storyLabel(progress.objective, at: CGPoint(x: -110, y: 243), size: 13, width: 760)
        let backing = SKShapeNode(rect: board, cornerRadius: 4)
        backing.fillColor = SKColor(white: 1, alpha: 0.025)
        backing.strokeColor = SKColor(white: 1, alpha: 0.28)
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
    // Kelompok dihitung dari sambungan gambar yang valid, bukan kedekatan visual saja.
    private var worldGroups: [Set<Int>] {
        var visited: Set<Int> = []
        var result: [Set<Int>] = []
        for id in state.installedIDs.sorted() where !visited.contains(id) {
            let group = state.connectedIDs(to: id)
            visited.formUnion(group)
            if group.count >= JigsawCatalog.minimumConnectedPieces { result.append(group) }
        }
        return result
    }
    private func worldName(_ entry: MemoryPiece) -> String {
        if entry == .boundary { return "Batas Desa" }
        switch entry.region {
        case .house: return "Rumah"
        case .village: return "Desa"
        case .foothills: return "Bukit"
        }
    }
    private func worldColor(_ id: Int) -> SKColor {
        // Warna menunjukkan pilihan aktif, bukan identitas dunia yang berbeda.
        let active = selected.map { state.connectedIDs(to: id).contains($0) } ?? false
        return active ? SKColor(red: 1, green: 0.53, blue: 0.15, alpha: 1)
            : SKColor(white: 1, alpha: 0.72)
    }
    // Label dapat diketuk untuk memilih seluruh dunia. Nama dan nomor tetap membedakan
    // kelompok meskipun warnanya mirip atau pengguna sulit membedakan warna.
    private func addWorldLabels() {
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
    private func addRestartConfirmation() {
        let shade = SKShapeNode(rectOf: CGSize(width: 990, height: 590), cornerRadius: 10)
        shade.zPosition = 200; shade.fillColor = SKColor(white: 0.04, alpha: 0.97); shade.strokeColor = .clear
        canvas.addChild(shade)
        shade.storyLabel("Mulai ulang prolog? Progres tersimpan akan dihapus.", at: CGPoint(x: 0, y: 35), size: 18)
        shade.storyButton("Batal", name: "cancelRestart", at: CGPoint(x: -75, y: -35))
        shade.storyButton("Mulai ulang", name: "confirmRestart", at: CGPoint(x: 75, y: -35), width: 130)
    }
    // Mengubah indeks slot menjadi titik tengah pada papan SpriteKit.
    private func center(_ slot: Int) -> CGPoint {
        CGPoint(x: board.minX + (CGFloat(slot % PuzzleCatalog.columns) + 0.5) * cell.width,
                y: board.maxY - (CGFloat(slot / PuzzleCatalog.columns) + 0.5) * cell.height)
    }
    // Membuat gambar keping, outline, dan bentuk hit-test yang mengabaikan bagian transparan.
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
        canvas.addChild(tile)
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
        let label = canvas.storyLabel(text, at: CGPoint(x: -165, y: -232), size: 13, width: 650)
        label.name = "statusMessage"; label.zPosition = 100
        let backing = SKShapeNode(rectOf: CGSize(width: 650, height: 27), cornerRadius: 6)
        backing.fillColor = SKColor(red: 0.08, green: 0.12, blue: 0.14, alpha: 1); backing.strokeColor = .clear
        backing.zPosition = -1; label.addChild(backing)
        label.run(.sequence([.wait(forDuration: 3), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }
    // Menampilkan foto lengkap setelah syarat penyelesaian terpenuhi.
    private func showAssembled(animated: Bool) {
        guard canvas.childNode(withName: "assembled") == nil else { return }
        let photo = SKSpriteNode(imageNamed: PuzzleCatalog.imageName)
        photo.name = "assembled"; photo.size = board.size
        photo.position = CGPoint(x: board.midX, y: board.midY); photo.zPosition = 100; photo.alpha = animated ? 0 : 1
        canvas.addChild(photo); photo.run(.fadeIn(withDuration: 1.5))
        let caption = canvas.storyLabel("Kenangan tersusun · 4 map · 12 keping", at: CGPoint(x: board.midX, y: -232), size: 21)
        caption.zPosition = 101
        for tile in tiles.values { tile.run(.sequence([.wait(forDuration: 1.5), .fadeOut(withDuration: 0.3)])) }
    }
    // Memastikan keping terhubung minimal tiga, kemudian menjalankan transisi ke area kenangannya.
    private func enterSelected() {
        guard !enteringMemory, qte == nil, let view else { return }
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
        let veil = SKSpriteNode(color: SKColor(red: 0.10, green: 0.14, blue: 0.12, alpha: 1), size: size)
        veil.position = CGPoint(x: size.width / 2, y: size.height / 2); veil.alpha = 0; veil.zPosition = 500
        addChild(veil); veil.run(.fadeAlpha(to: 0.9, duration: duration))
        // Angkat seluruh rangkaian agar portal terasa berasal dari satu dunia, bukan satu keping.
        let members = connected.compactMap { tiles[$0] }
        let count = CGFloat(max(1, members.count))
        let center = CGPoint(x: members.reduce(CGFloat(0)) { $0 + $1.position.x } / count,
                             y: members.reduce(CGFloat(0)) { $0 + $1.position.y } / count)
        let origin = canvas.convert(center, to: self)
        if !reduced {
            let lift = SKNode(); lift.position = origin; lift.zPosition = 501
            lift.setScale(canvas.xScale); addChild(lift)
            for member in members {
                let copy = member.copy() as! SKNode
                copy.position = CGPoint(x: member.position.x - center.x, y: member.position.y - center.y)
                lift.addChild(copy)
            }
            let action = SKAction.group([
                .move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: duration),
                .scale(to: canvas.xScale * 2.6, duration: duration), .fadeOut(withDuration: duration)
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
    private func openBag() {
        guard bag == nil, qte == nil, !enteringMemory else { return }
        dragPiece = nil
        rebuild()
        let overlay = BagOverlay(progress: progress, sceneSize: size)
        overlay.onClose = { [weak self] in self?.closeBag() }
        overlay.onUse = { [weak self] item in
            guard let self else { return }
            self.closeBag()
            switch item {
            case .fragment(let id):
                self.selected = id
                if let index = self.state.inventory(progress: self.progress).firstIndex(of: id) { self.inventoryPage = index / self.pageSize }
                self.rebuild()
            case .book:
                guard self.progress.hasBook, let view = self.view else { return }
                let book = BookScene(size: self.size)
                book.scaleMode = .resizeFill
                book.onClose = { [self, weak view] in
                    view?.presentScene(self, transition: .fade(withDuration: 0.3))
                }
                view.presentScene(book, transition: .fade(withDuration: 0.3))
            }
        }
        bag = overlay
        addChild(overlay)
    }
    private func closeBag() {
        bag?.removeFromParent()
        bag = nil
    }
    // QTE berjalan sebagai overlay di layar puzzle supaya interaksi papan berhenti sementara.
    private func openQTE() {
        guard qte == nil, bag == nil, !enteringMemory else { return }
        dragPiece = nil
        let event = QuickTimeEventNode(config: QuickTimeEventConfig(requiredTaps: 15))
        event.position = CGPoint(x: size.width / 2, y: size.height / 2)
        event.onComplete = { [weak self] success in
            self?.message(success ? "Kamu lolos dari bayangan itu." : "Bayangan itu semakin dekat.")
        }
        event.onDismiss = { [weak self, weak event] in
            guard let self, self.qte === event else { return }
            self.qte = nil
            self.canvas.run(.fadeAlpha(to: 1, duration: 0.18))
        }
        qte = event
        canvas.run(.fadeAlpha(to: 0.32, duration: 0.15))
        addChild(event)
        event.start()
    }
    // Membedakan tombol dan pemilihan keping, lalu menyiapkan posisi awal drag.
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
    // Memindahkan keping mengikuti sentuhan dan membedakan drag dari ketukan biasa.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, bag == nil, qte == nil, let touch = touches.first, let id = dragPiece, let tile = tiles[id] else { return }
        let point = touch.location(in: canvas)
        if hypot(point.x - dragStart.x, point.y - dragStart.y) > 8 { moved = true }
        if moved {
            tile.setScale(boardScale / (renderScales[id] ?? boardScale))
            tile.position = CGPoint(x: dragHome.x + point.x - dragStart.x, y: dragHome.y + point.y - dragStart.y)
        }
    }
    // Mengubah posisi lepas menjadi slot; drop di luar papan mengembalikan keping ke inventori.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, bag == nil, qte == nil, let id = dragPiece else { return }
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
    // Membatalkan drag ketika sentuhan terputus dan memulihkan tampilan dari state.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, qte == nil else { return }
        dragPiece = nil; rebuild()
    }
}
