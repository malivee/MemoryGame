import SpriteKit

extension ExplorationScene {
    func addDebugButton() {
        hud.childNode(withName: "debugWarp")?.removeFromParent()
        let btn = hud.storyButton("⚙️ DEBUG", name: "debugWarp", at: CGPoint(x: size.width - 65, y: size.height - 24), width: 86)
        btn.fillColor = SKColor(red: 0.16, green: 0.12, blue: 0.22, alpha: 0.94)
        btn.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 0.90)
        btn.lineWidth = 1.4
        btn.zPosition = 100
    }

    func toggleDebugWarp() {
        if let menu = debugMenuNode {
            menu.removeFromParent()
            debugMenuNode = nil
            return
        }
        showDebugWarpMenu()
    }

    func showDebugWarpMenu() {
        debugMenuNode?.removeFromParent()

        let menu = SKNode()
        menu.name = "debugMenuContainer"
        menu.position = CGPoint(x: size.width / 2, y: size.height / 2)
        menu.zPosition = 500

        // Backdrop peredup
        let backdrop = SKShapeNode(rectOf: size)
        backdrop.fillColor = SKColor(white: 0, alpha: 0.65)
        backdrop.strokeColor = .clear
        backdrop.name = "debug-warp-backdrop"
        menu.addChild(backdrop)

        // Panel dialog kayu gelap Carto (2-Kolom Landscape)
        let panelW: CGFloat = min(size.width - 40, 620)
        let panelH: CGFloat = 310
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 18)
        panel.fillColor = SKColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.98)
        panel.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 1.0)
        panel.lineWidth = 2.0
        panel.name = "debugMenuPanel"
        menu.addChild(panel)

        // Inner frame emas halus
        let innerFrame = SKShapeNode(rectOf: CGSize(width: panelW - 8, height: panelH - 8), cornerRadius: 14)
        innerFrame.fillColor = .clear
        innerFrame.strokeColor = SKColor(red: 0.85, green: 0.75, blue: 0.45, alpha: 0.3)
        innerFrame.lineWidth = 1.0
        innerFrame.name = "debugMenuPanel"
        panel.addChild(innerFrame)

        // Judul menu
        let title = SKLabelNode(text: "⚙️ DEBUG WARP · SELEKTOR MAP & WILAYAH")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 13.5
        title.fontColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 1.0)
        title.position = CGPoint(x: 0, y: panelH / 2 - 26)
        title.name = "debugMenuPanel"
        panel.addChild(title)

        // Tombol Close "✕" di pojok kanan atas
        let closeBtn = SKShapeNode(circleOfRadius: 13)
        closeBtn.fillColor = SKColor(red: 0.28, green: 0.15, blue: 0.15, alpha: 0.95)
        closeBtn.strokeColor = SKColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 0.9)
        closeBtn.lineWidth = 1.2
        closeBtn.position = CGPoint(x: panelW / 2 - 26, y: panelH / 2 - 26)
        closeBtn.name = "debug-warp-close"
        panel.addChild(closeBtn)

        let closeLbl = SKLabelNode(text: "✕")
        closeLbl.fontName = "AvenirNext-Bold"
        closeLbl.fontSize = 11
        closeLbl.fontColor = SKColor(red: 0.98, green: 0.85, blue: 0.85, alpha: 1.0)
        closeLbl.verticalAlignmentMode = .center
        closeLbl.name = "debug-warp-close"
        closeBtn.addChild(closeLbl)

        let colW: CGFloat = (panelW - 50) / 2.0
        let leftColX: CGFloat = -panelW / 4 + 2
        let rightColX: CGFloat = panelW / 4 - 2

        // Header Kolom Kiri
        let leftHeader = SKLabelNode(text: "🏡 WILAYAH DESA & PROLOG")
        leftHeader.fontName = "AvenirNext-Bold"
        leftHeader.fontSize = 10.5
        leftHeader.fontColor = SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.75)
        leftHeader.position = CGPoint(x: leftColX, y: panelH / 2 - 50)
        leftHeader.name = "debugMenuPanel"
        panel.addChild(leftHeader)

        // Header Kolom Kanan
        let rightHeader = SKLabelNode(text: "🗺️ MAP B: PINGGIRAN (4 SUB-TAHAP)")
        rightHeader.fontName = "AvenirNext-Bold"
        rightHeader.fontSize = 10.5
        rightHeader.fontColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 0.95)
        rightHeader.position = CGPoint(x: rightColX, y: panelH / 2 - 50)
        rightHeader.name = "debugMenuPanel"
        panel.addChild(rightHeader)

        let cardH: CGFloat = 46
        let cardSpacing: CGFloat = 8
        let startY = panelH / 2 - 82

        // --- Kolom Kiri: Wilayah Desa ---
        let leftItems: [(title: String, sub: String, key: String)] = [
            ("1. 🏠 Rumah Arthur", "Kamar tidur & meja peta Anneth", "debug-warp-house"),
            ("2. 🏡 Pusat Desa", "Jalan utama, kedai & warga lembah", "debug-warp-village"),
            ("3. 🏔️ Kaki Perbukitan", "Jalan setapak lama & tebing", "debug-warp-hills"),
            ("4. 🌫️ Wilayah Echoes", "Zona bahaya kabut kenangan", "debug-warp-echoes")
        ]

        for (idx, item) in leftItems.enumerated() {
            let cy = startY - CGFloat(idx) * (cardH + cardSpacing)
            let card = SKShapeNode(rectOf: CGSize(width: colW, height: cardH), cornerRadius: 8)
            card.fillColor = SKColor(red: 0.16, green: 0.19, blue: 0.22, alpha: 0.95)
            card.strokeColor = SKColor(red: 0.45, green: 0.50, blue: 0.55, alpha: 0.65)
            card.lineWidth = 1.0
            card.position = CGPoint(x: leftColX, y: cy)
            card.name = item.key

            let tLbl = SKLabelNode(text: item.title)
            tLbl.fontName = "AvenirNext-Bold"
            tLbl.fontSize = 11
            tLbl.fontColor = SKColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
            tLbl.horizontalAlignmentMode = .left
            tLbl.position = CGPoint(x: -colW / 2 + 12, y: 3)
            tLbl.name = item.key
            card.addChild(tLbl)

            let sLbl = SKLabelNode(text: item.sub)
            sLbl.fontName = "AvenirNext-Medium"
            sLbl.fontSize = 8.5
            sLbl.fontColor = SKColor(red: 0.75, green: 0.80, blue: 0.85, alpha: 0.85)
            sLbl.horizontalAlignmentMode = .left
            sLbl.position = CGPoint(x: -colW / 2 + 12, y: -12)
            sLbl.name = item.key
            card.addChild(sLbl)

            panel.addChild(card)
        }

        // --- Kolom Kanan: 4 Sub-Tahap Map B ---
        let mapBItems: [(title: String, sub: String, key: String, color: SKColor)] = [
            ("🧂 B1: Tambang Rock Salt", "Garam batu, gerobak & mulut gua", "debug-warp-b1", SKColor(red: 0.45, green: 0.88, blue: 0.98, alpha: 1.0)),
            ("🌿 B2: Perbukitan Herbal", "Kebun, parit, menhir & sosok Hollow", "debug-warp-b2", SKColor(red: 0.55, green: 0.92, blue: 0.45, alpha: 1.0)),
            ("🪵 B3: Lereng Penebang Kayu", "Kayu bakar, terasering & Buku Elias", "debug-warp-b3", SKColor(red: 0.95, green: 0.75, blue: 0.38, alpha: 1.0)),
            ("🎗️ B4: The Boundary", "Lingkar batu, pohon batas & Deep Woods", "debug-warp-b4", SKColor(red: 0.98, green: 0.45, blue: 0.25, alpha: 1.0))
        ]

        for (idx, item) in mapBItems.enumerated() {
            let cy = startY - CGFloat(idx) * (cardH + cardSpacing)
            let card = SKShapeNode(rectOf: CGSize(width: colW, height: cardH), cornerRadius: 8)
            card.fillColor = SKColor(red: 0.14, green: 0.18, blue: 0.19, alpha: 0.96)
            card.strokeColor = item.color
            card.lineWidth = 1.4
            card.position = CGPoint(x: rightColX, y: cy)
            card.name = item.key

            // Strip warna di tepi kiri kartu
            let stripe = SKShapeNode(rectOf: CGSize(width: 4, height: cardH - 6), cornerRadius: 2)
            stripe.fillColor = item.color
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: -colW / 2 + 6, y: 0)
            stripe.name = item.key
            card.addChild(stripe)

            let tLbl = SKLabelNode(text: item.title)
            tLbl.fontName = "AvenirNext-Bold"
            tLbl.fontSize = 11.5
            tLbl.fontColor = item.color
            tLbl.horizontalAlignmentMode = .left
            tLbl.position = CGPoint(x: -colW / 2 + 16, y: 3)
            tLbl.name = item.key
            card.addChild(tLbl)

            let sLbl = SKLabelNode(text: item.sub)
            sLbl.fontName = "AvenirNext-Medium"
            sLbl.fontSize = 8.5
            sLbl.fontColor = SKColor(red: 0.92, green: 0.92, blue: 0.90, alpha: 0.90)
            sLbl.horizontalAlignmentMode = .left
            sLbl.position = CGPoint(x: -colW / 2 + 16, y: -12)
            sLbl.name = item.key
            card.addChild(sLbl)

            panel.addChild(card)
        }

        hud.addChild(menu)
        debugMenuNode = menu
    }

    func handleDebugWarpTouch(hudPoint: CGPoint, names: Set<String>) -> Bool {
        guard let menu = debugMenuNode else { return false }

        if names.contains("debug-warp-close") {
            menu.removeFromParent()
            debugMenuNode = nil
            return true
        }

        if names.contains("debug-warp-house") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpTo(piece: .house)
            return true
        }
        if names.contains("debug-warp-village") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpTo(piece: .villageRoad)
            return true
        }
        if names.contains("debug-warp-hills") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpTo(piece: .oldPath)
            return true
        }
        if names.contains("debug-warp-b1") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpToBoundaryStage(.rockSalt)
            return true
        }
        if names.contains("debug-warp-b2") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpToBoundaryStage(.herbalHills)
            return true
        }
        if names.contains("debug-warp-b3") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpToBoundaryStage(.woodcutterSlope)
            return true
        }
        if names.contains("debug-warp-b4") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpToBoundaryStage(.theBoundary)
            return true
        }
        if names.contains("debug-warp-echoes") {
            menu.removeFromParent()
            debugMenuNode = nil
            warpTo(piece: .echoesBoundary)
            return true
        }

        // Tapping inside panel absorbs touch
        if names.contains("debugMenuPanel") {
            return true
        }

        // Tapping outside on backdrop dismisses menu
        if names.contains("debug-warp-backdrop") {
            menu.removeFromParent()
            debugMenuNode = nil
            return true
        }

        return false
    }

    func warpToBoundaryStage(_ stage: MapBStage) {
        progress.mapBStage = stage
        progress.placements[MemoryPiece.boundary.slot] = PhotoPlacement(piece: .boundary, turns: 0)
        progress.rotations[.boundary] = 0
        switch stage {
        case .rockSalt:
            progress.isRockSaltUnlocked = true
            progress.hasRockSalt = false
            progress.deliveredRockSalt = false
        case .herbalHills:
            progress.isRockSaltUnlocked = true
            progress.hasRockSalt = true
            progress.deliveredRockSalt = true
            progress.isHerbalUnlocked = true
            progress.hasHerbal = false
            progress.metBerynAfterHerbal = false
        case .woodcutterSlope:
            progress.isRockSaltUnlocked = true
            progress.hasRockSalt = true
            progress.deliveredRockSalt = true
            progress.isHerbalUnlocked = true
            progress.hasHerbal = true
            progress.metBerynAfterHerbal = true
            progress.gatheredWood = false
            progress.hasEliasBook = false
        case .theBoundary:
            progress.hasRockSalt = true
            progress.deliveredRockSalt = true
            progress.isHerbalUnlocked = true
            progress.hasHerbal = true
            progress.metBerynAfterHerbal = true
            progress.gatheredWood = true
            progress.hasEliasBook = true
            progress.boundaryMarked = false
        }
        PrologueStore.shared.save()
        warpTo(piece: .boundary)
    }

    func warpTo(piece: MemoryPiece) {
        enteringMemory = true
        progress.placements[piece.slot] = PhotoPlacement(piece: piece, turns: 0)
        progress.rotations[piece] = 0
        PrologueStore.shared.save()
        let newScene = ExplorationScene(size: size, entry: piece, worldLocations: [piece])
        newScene.scaleMode = .resizeFill
        view?.presentScene(newScene, transition: .fade(withDuration: 0.25))
    }
}
