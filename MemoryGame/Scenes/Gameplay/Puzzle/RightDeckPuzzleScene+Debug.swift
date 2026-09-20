import SpriteKit

extension RightDeckPuzzleScene {
    func addDebugButton() {
        let halfH = deckBounds.maxY
        let button = canvas.storyButton("⚙️ DEBUG", name: "debug", at: CGPoint(x: deckBounds.midX, y: halfH - 45), width: 125)
        button.fillColor = SKColor(red: 0.18, green: 0.14, blue: 0.24, alpha: 0.95)
        button.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 0.9)
        button.lineWidth = 2
        button.zPosition = 800
        button.children.forEach { $0.name = "debug" }
        if debugMenuVisible { showDebugMenuOverlay() }
    }

    func showDebugMenuOverlay() {
        let halfH = deckBounds.maxY
        let menu = SKNode()
        menu.name = "debugModalContainer"
        menu.position = .zero
        menu.zPosition = 850

        // Backdrop
        let backdrop = SKShapeNode(rectOf: CGSize(width: halfWidth * 2, height: halfH * 2))
        backdrop.fillColor = SKColor(white: 0, alpha: 0.55)
        backdrop.strokeColor = SKColor.clear
        backdrop.name = "debug-backdrop"
        menu.addChild(backdrop)

        // Panel
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

        let choices: [(String, String)] = [
            ("1. 🏠 Rumah Arthur", "debug-world-0"),
            ("2. 🏡 Pusat Desa", "debug-world-1"),
            ("3. 🏔️ Kaki Perbukitan", "debug-world-2"),
            ("4. 🧂 B1: Tambang Rock Salt", "debug-b1"),
            ("5. 🌿 B2: Perbukitan Herbal", "debug-b2"),
            ("6. 🪵 B3: Lereng Kayu / Buku", "debug-b3"),
            ("7. 🎗️ B4: The Boundary", "debug-b4"),
            ("8. 🌫️ Zona Bahaya (Echoes)", "debug-world-4")
        ]

        let btnW: CGFloat = 300
        let btnH: CGFloat = 26
        let startY = panelH / 2 - 58

        for (idx, choice) in choices.enumerated() {
            let y = startY - CGFloat(idx) * (btnH + 6)
            let btn = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: 6)
            btn.fillColor = SKColor(red: 0.22, green: 0.25, blue: 0.28, alpha: 0.95)
            btn.strokeColor = SKColor(red: 0.55, green: 0.58, blue: 0.62, alpha: 0.6)
            btn.lineWidth = 1
            btn.position = CGPoint(x: 0, y: y)
            btn.name = choice.1

            let lbl = SKLabelNode(text: choice.0)
            lbl.fontName = "AvenirNext-DemiBold"
            lbl.fontSize = 11
            lbl.fontColor = SKColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
            lbl.verticalAlignmentMode = .center
            lbl.name = choice.1
            btn.addChild(lbl)

            panel.addChild(btn)
        }

        canvas.addChild(menu)
    }

    func toggleDebugMenu() {
        debugMenuVisible.toggle()
        rebuild(resetCamera: false)
    }

    func enterDebugWorld(_ world: PuzzleWorld) {
        enteringMemory = true
        let progress = PrologueStore.shared.progress
        for piece in world.locations {
            progress.placements[piece.slot] = PhotoPlacement(piece: piece, turns: 0)
            progress.rotations[piece] = 0
        }
        PrologueStore.shared.save()
        let destination = world.makeScene(size: size)
        destination.scaleMode = .resizeFill
        view?.presentScene(destination, transition: .fade(withDuration: 0.25))
    }

    func enterDebugBoundaryStage(_ stage: MapBStage) {
        enteringMemory = true
        let progress = PrologueStore.shared.progress
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
        let destination = ExplorationScene(size: size, entry: .boundary, worldLocations: [.boundary])
        destination.scaleMode = .resizeFill
        view?.presentScene(destination, transition: .fade(withDuration: 0.25))
    }
}
