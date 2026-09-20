import SpriteKit

extension ExplorationScene {
    func addDebugButton() {
        let btn = hud.storyButton("⚙️ DEBUG", name: "debugWarp", at: CGPoint(x: size.width - 220, y: size.height - 34), width: 95)
        btn.fillColor = SKColor(red: 0.18, green: 0.14, blue: 0.24, alpha: 0.92)
        btn.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 0.85)
        btn.zPosition = 60
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
        backdrop.fillColor = SKColor(white: 0, alpha: 0.55)
        backdrop.strokeColor = .clear
        backdrop.name = "debug-warp-backdrop"
        menu.addChild(backdrop)

        // Panel dialog kayu gelap Carto
        let panelW: CGFloat = 340
        let panelH: CGFloat = 320
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 16)
        panel.fillColor = SKColor(red: 0.14, green: 0.16, blue: 0.18, alpha: 0.98)
        panel.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 1.0)
        panel.lineWidth = 2.5
        panel.name = "debugMenuPanel"
        menu.addChild(panel)

        // Judul menu
        let title = SKLabelNode(text: "⚙️ DEBUG WARP SELEKTOR MAP")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 14
        title.fontColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 1.0)
        title.position = CGPoint(x: 0, y: panelH / 2 - 28)
        panel.addChild(title)

        let warps: [(String, String)] = [
            ("1. 🏠 Rumah Arthur", "debug-warp-house"),
            ("2. 🏡 Pusat Desa", "debug-warp-village"),
            ("3. 🏔️ Kaki Perbukitan", "debug-warp-hills"),
            ("4. 🧂 B1: Tambang Rock Salt", "debug-warp-b1"),
            ("5. 🌿 B2: Perbukitan Herbal", "debug-warp-b2"),
            ("6. 🪵 B3: Lereng Kayu / Buku", "debug-warp-b3"),
            ("7. 🎗️ B4: The Boundary", "debug-warp-b4"),
            ("8. 🌫️ Zona Bahaya (Echoes)", "debug-warp-echoes")
        ]

        let btnW: CGFloat = 300
        let btnH: CGFloat = 26
        let startY = panelH / 2 - 58

        for (idx, warp) in warps.enumerated() {
            let y = startY - CGFloat(idx) * (btnH + 6)
            let btn = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: 6)
            btn.fillColor = SKColor(red: 0.22, green: 0.25, blue: 0.28, alpha: 0.95)
            btn.strokeColor = SKColor(red: 0.55, green: 0.58, blue: 0.62, alpha: 0.6)
            btn.lineWidth = 1
            btn.position = CGPoint(x: 0, y: y)
            btn.name = warp.1

            let lbl = SKLabelNode(text: warp.0)
            lbl.fontName = "AvenirNext-DemiBold"
            lbl.fontSize = 11
            lbl.fontColor = SKColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
            lbl.verticalAlignmentMode = .center
            lbl.name = warp.1
            btn.addChild(lbl)

            panel.addChild(btn)
        }

        hud.addChild(menu)
        debugMenuNode = menu
    }

    func handleDebugWarpTouch(hudPoint: CGPoint, names: Set<String>) -> Bool {
        guard let menu = debugMenuNode else { return false }

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
