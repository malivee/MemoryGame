import SpriteKit

final class VillageQuestDebugRuntime {
    static let shared = VillageQuestDebugRuntime()
    weak var modalNode: SKNode?
}

extension VillageCartoScene {
    func addQuestDebugButton() {
        let btnX: CGFloat = isMap ? 345 : 210
        let btn = buttonNode(
            "⚙️ Quest 1-9",
            name: "debugQuestMenu",
            at: CGPoint(x: btnX, y: size.height - 32),
            width: 120
        )
        btn.fillColor = SKColor(red: 0.16, green: 0.12, blue: 0.24, alpha: 0.95)
        btn.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 0.90)
        btn.lineWidth = 1.4
    }

    @discardableResult
    private func buttonNode(_ title: String, name: String, at p: CGPoint, width: CGFloat = 110) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: 36), cornerRadius: 10)
        node.position = p
        node.name = name
        node.fillColor = SKColor(red: 0.08, green: 0.25, blue: 0.28, alpha: 1)
        node.strokeColor = cream.withAlphaComponent(0.5)
        node.lineWidth = 1.2
        text(title, at: .zero, size: 12.5, parent: node, color: cream)
        node.children.first?.name = name
        hud.addChild(node)
        return node
    }

    func toggleQuestDebugModal() {
        if VillageQuestDebugRuntime.shared.modalNode != nil {
            dismissQuestDebugModal()
        } else {
            showQuestDebugModal()
        }
    }

    func dismissQuestDebugModal() {
        VillageQuestDebugRuntime.shared.modalNode?.removeFromParent()
        VillageQuestDebugRuntime.shared.modalNode = nil
    }

    func showQuestDebugModal() {
        dismissQuestDebugModal()

        let menu = SKNode()
        menu.name = "debugQuestModalContainer"
        menu.position = CGPoint(x: size.width / 2, y: size.height / 2)
        menu.zPosition = 650

        // Backdrop gelap penutup
        let backdrop = SKShapeNode(rectOf: size)
        backdrop.fillColor = SKColor(white: 0, alpha: 0.65)
        backdrop.strokeColor = .clear
        backdrop.name = "debug-quest-backdrop"
        menu.addChild(backdrop)

        // Panel dialog kayu Carto
        let panelW: CGFloat = min(size.width - 36, 680)
        let panelH: CGFloat = min(size.height - 24, 345)
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 18)
        panel.fillColor = SKColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.98)
        panel.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 1.0)
        panel.lineWidth = 2.0
        panel.name = "debugQuestModalPanel"
        menu.addChild(panel)

        // Bingkai emas halus
        let innerFrame = SKShapeNode(rectOf: CGSize(width: panelW - 8, height: panelH - 8), cornerRadius: 14)
        innerFrame.fillColor = .clear
        innerFrame.strokeColor = SKColor(red: 0.85, green: 0.75, blue: 0.45, alpha: 0.3)
        innerFrame.lineWidth = 1.0
        innerFrame.name = "debugQuestModalPanel"
        panel.addChild(innerFrame)

        // Header Title
        let title = SKLabelNode(text: "⚙️ DEBUG IN-GAME · SELEKTOR QUEST (1 - 9)")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 13
        title.fontColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 1.0)
        title.position = CGPoint(x: 0, y: panelH / 2 - 22)
        title.name = "debugQuestModalPanel"
        panel.addChild(title)

        // Subtitle panduan (langsung masuk ke gameplay in-game)
        let sub = SKLabelNode(text: "Pilih quest untuk melompat LANGSUNG KE INGAME (Arthur berjalan & siap interaksi):")
        sub.fontName = "AvenirNext-Medium"
        sub.fontSize = 9.5
        sub.fontColor = SKColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 0.85)
        sub.position = CGPoint(x: 0, y: panelH / 2 - 36)
        sub.name = "debugQuestModalPanel"
        panel.addChild(sub)

        // Tombol Close "✕"
        let closeBtn = SKShapeNode(circleOfRadius: 13)
        closeBtn.fillColor = SKColor(red: 0.28, green: 0.15, blue: 0.15, alpha: 0.95)
        closeBtn.strokeColor = SKColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 0.9)
        closeBtn.lineWidth = 1.2
        closeBtn.position = CGPoint(x: panelW / 2 - 24, y: panelH / 2 - 24)
        closeBtn.name = "debug-quest-close"
        panel.addChild(closeBtn)

        let closeLbl = SKLabelNode(text: "✕")
        closeLbl.fontName = "AvenirNext-Bold"
        closeLbl.fontSize = 11
        closeLbl.fontColor = SKColor(red: 0.98, green: 0.85, blue: 0.85, alpha: 1.0)
        closeLbl.verticalAlignmentMode = .center
        closeLbl.name = "debug-quest-close"
        closeBtn.addChild(closeLbl)

        let colW: CGFloat = (panelW - 48) / 2.0
        let leftColX: CGFloat = -panelW / 4 + 2
        let rightColX: CGFloat = panelW / 4 - 2

        let cardH: CGFloat = 36
        let cardSpacing: CGFloat = 5
        let startY: CGFloat = panelH / 2 - 58

        // Kolom Kiri: Quest 1 - 5
        let leftQuests: [(title: String, desc: String, key: String, color: SKColor)] = [
            ("🏡 In-Game Q1: Arthur & Mara", "Ember air & minigame rak miring", "debug-quest-1", SKColor(red: 0.93, green: 0.86, blue: 0.34, alpha: 1)),
            ("🌾 In-Game Q2: Lumbung Keneth", "Keranjang Mara & sortir benih gandum", "debug-quest-2", SKColor(red: 0.95, green: 0.72, blue: 0.35, alpha: 1)),
            ("🐑 In-Game Q3: Peternakan Roland", "Pagar kandang domba & dialog Roland", "debug-quest-3", SKColor(red: 0.65, green: 0.88, blue: 0.45, alpha: 1)),
            ("🥔 In-Game Q4: Rumah Anneth", "Dapur belakang, sortir umbi & misi garam", "debug-quest-4", SKColor(red: 0.45, green: 0.82, blue: 0.95, alpha: 1)),
            ("🧂 In-Game Q5: Tambang & Beryn", "Garam batu, legenda laut & misi daun perak", "debug-quest-5", SKColor(red: 0.88, green: 0.78, blue: 0.45, alpha: 1))
        ]

        for (idx, item) in leftQuests.enumerated() {
            let cy = startY - CGFloat(idx) * (cardH + cardSpacing)
            addQuestCard(to: panel, title: item.title, desc: item.desc, key: item.key, color: item.color, at: CGPoint(x: leftColX, y: cy), width: colW, height: cardH)
        }

        // Kolom Kanan: Quest 6 - 8
        let rightQuests: [(title: String, desc: String, key: String, color: SKColor)] = [
            ("🌿 In-Game Q6: Perbukitan Herbal", "Daun perak & perjumpaan The Hollow", "debug-quest-6", SKColor(red: 0.45, green: 0.92, blue: 0.65, alpha: 1)),
            ("🪵 In-Game Q7: Hutan & Jurnal Elias", "Kayu bakar & temukan Buku Elias", "debug-quest-7", SKColor(red: 0.35, green: 0.75, blue: 0.48, alpha: 1)),
            ("🏚️ In-Game Q8: Markas Gudang", "Cerita Buku Elias & scripted failure", "debug-quest-8-step1", SKColor(red: 0.95, green: 0.65, blue: 0.35, alpha: 1)),
            ("🌫️ In-Game Q8: Kabut Senja (Old Fog)", "Jalanan berkabut tebal & Tetua Desa", "debug-quest-8-step2", SKColor(red: 0.68, green: 0.68, blue: 0.95, alpha: 1)),
            ("🎒 In-Game Q8: Anneth & Loadout", "Malam hari & kemas 5 barang ekspedisi", "debug-quest-8-step3", SKColor(red: 0.45, green: 0.95, blue: 0.65, alpha: 1))
        ]

        for (idx, item) in rightQuests.enumerated() {
            let cy = startY - CGFloat(idx) * (cardH + cardSpacing)
            addQuestCard(to: panel, title: item.title, desc: item.desc, key: item.key, color: item.color, at: CGPoint(x: rightColX, y: cy), width: colW, height: cardH)
        }

        // Baris Bawah: Reset & Selesaikan Semua
        let bottomY = -panelH / 2 + 22
        let bottomBtnW = (panelW - 60) / 2.0

        // Tombol Reset Semua
        let resetBtn = SKShapeNode(rectOf: CGSize(width: bottomBtnW, height: 28), cornerRadius: 8)
        resetBtn.fillColor = SKColor(red: 0.22, green: 0.12, blue: 0.14, alpha: 0.95)
        resetBtn.strokeColor = SKColor(red: 0.85, green: 0.45, blue: 0.45, alpha: 0.8)
        resetBtn.lineWidth = 1.0
        resetBtn.position = CGPoint(x: -panelW / 4 + 2, y: bottomY)
        resetBtn.name = "debug-quest-reset"
        panel.addChild(resetBtn)

        let resetLbl = SKLabelNode(text: "🔄 Reset Semua Progres (Awal)")
        resetLbl.fontName = "AvenirNext-Bold"
        resetLbl.fontSize = 10
        resetLbl.fontColor = SKColor(red: 0.98, green: 0.82, blue: 0.82, alpha: 1.0)
        resetLbl.verticalAlignmentMode = .center
        resetLbl.name = "debug-quest-reset"
        resetBtn.addChild(resetLbl)

        // Tombol Selesaikan Semua
        let finishAllBtn = SKShapeNode(rectOf: CGSize(width: bottomBtnW, height: 28), cornerRadius: 8)
        finishAllBtn.fillColor = SKColor(red: 0.12, green: 0.24, blue: 0.18, alpha: 0.95)
        finishAllBtn.strokeColor = SKColor(red: 0.45, green: 0.85, blue: 0.55, alpha: 0.8)
        finishAllBtn.lineWidth = 1.0
        finishAllBtn.position = CGPoint(x: panelW / 4 - 2, y: bottomY)
        finishAllBtn.name = "debug-quest-complete-all"
        panel.addChild(finishAllBtn)

        let finishAllLbl = SKLabelNode(text: "🌲 Mulai Quest 9 (Lewati Q1-8)")
        finishAllLbl.fontName = "AvenirNext-Bold"
        finishAllLbl.fontSize = 10
        finishAllLbl.fontColor = SKColor(red: 0.82, green: 0.98, blue: 0.85, alpha: 1.0)
        finishAllLbl.verticalAlignmentMode = .center
        finishAllLbl.name = "debug-quest-complete-all"
        finishAllBtn.addChild(finishAllLbl)

        hud.addChild(menu)
        VillageQuestDebugRuntime.shared.modalNode = menu
    }

    private func addQuestCard(to parent: SKNode, title: String, desc: String, key: String, color: SKColor, at point: CGPoint, width: CGFloat, height: CGFloat) {
        let card = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 7)
        card.fillColor = SKColor(red: 0.14, green: 0.17, blue: 0.20, alpha: 0.96)
        card.strokeColor = color.withAlphaComponent(0.7)
        card.lineWidth = 1.1
        card.position = point
        card.name = key

        // Stripe warna di tepi kiri
        let stripe = SKShapeNode(rectOf: CGSize(width: 3.5, height: height - 6), cornerRadius: 1.5)
        stripe.fillColor = color
        stripe.strokeColor = .clear
        stripe.position = CGPoint(x: -width / 2 + 5, y: 0)
        stripe.name = key
        card.addChild(stripe)

        let tLbl = SKLabelNode(text: title)
        tLbl.fontName = "AvenirNext-Bold"
        tLbl.fontSize = 11
        tLbl.fontColor = color
        tLbl.horizontalAlignmentMode = .left
        tLbl.position = CGPoint(x: -width / 2 + 14, y: 2)
        tLbl.name = key
        card.addChild(tLbl)

        let dLbl = SKLabelNode(text: desc)
        dLbl.fontName = "AvenirNext-Medium"
        dLbl.fontSize = 8.5
        dLbl.fontColor = SKColor(red: 0.85, green: 0.87, blue: 0.90, alpha: 0.85)
        dLbl.horizontalAlignmentMode = .left
        dLbl.position = CGPoint(x: -width / 2 + 14, y: -11)
        dLbl.name = key
        card.addChild(dLbl)

        parent.addChild(card)
    }

    func handleQuestDebugTouch(actions: Set<String>) -> Bool {
        if actions.contains("debugQuestMenu") {
            toggleQuestDebugModal()
            return true
        }

        guard VillageQuestDebugRuntime.shared.modalNode != nil else { return false }

        if actions.contains("debug-quest-close") {
            dismissQuestDebugModal()
            return true
        }

        if actions.contains("debug-quest-1") {
            warpToQuest(stage: 1)
            return true
        }
        if actions.contains("debug-quest-2") {
            warpToQuest(stage: 2)
            return true
        }
        if actions.contains("debug-quest-3") {
            warpToQuest(stage: 3)
            return true
        }
        if actions.contains("debug-quest-4") {
            warpToQuest(stage: 4)
            return true
        }
        if actions.contains("debug-quest-5") {
            warpToQuest(stage: 5)
            return true
        }
        if actions.contains("debug-quest-6") {
            warpToQuest(stage: 6)
            return true
        }
        if actions.contains("debug-quest-7") {
            warpToQuest(stage: 7)
            return true
        }
        if actions.contains("debug-quest-7-step2") {
            warpToQuest(stage: 7, step2: true)
            return true
        }
        if actions.contains("debug-quest-8-step1") {
            warpToQuest(stage: 8, step: 1)
            return true
        }
        if actions.contains("debug-quest-8-step2") {
            warpToQuest(stage: 8, step: 2)
            return true
        }
        if actions.contains("debug-quest-8-step3") {
            warpToQuest(stage: 8, step: 3)
            return true
        }
        if actions.contains("debug-quest-reset") {
            resetAllQuests()
            return true
        }
        if actions.contains("debug-quest-complete-all") {
            completeAllQuests()
            return true
        }

        if actions.contains("debugQuestModalPanel") {
            return true
        }
        if actions.contains("debug-quest-backdrop") {
            dismissQuestDebugModal()
            return true
        }

        return false
    }

    func saveAllVillageQuests() {
        saveQuest1()
        saveQuest2()
        saveQuest3()
        saveQuest4()
        saveQuest5()
        saveQuest7()
        saveQuest8()
        saveQuest9()
    }

    func setArthurSafePosition(_ target: CGPoint) {
        let safe = nearestSafePoint(target) ?? target
        actor.position = safe
        actor.zRotation = 0
        world.zRotation = 0
        if let source = layout.source(safe) {
            sourcePosition = source
        }
    }

    func warpToQuest(stage: Int, step2: Bool = false, step: Int = 1) {
        dismissQuestDebugModal()
        stopInput()
        selected = nil
        selectedBuilding = nil
        draftTurns = 0
        page = 0
        // LANGSUNG MASUK KE INGAME (MODE JELAJAHI), BUKAN KE MAP
        isMap = false

        switch stage {
        case 1:
            quest1 = VillageQuest1Progress()
            quest2 = VillageQuest2Progress()
            quest3 = VillageQuest3Progress()
            quest4 = VillageQuest4Progress()
            quest5 = VillageQuest5Progress()
            quest7 = VillageQuest7Progress()
            quest8 = VillageQuest8Progress()
            resetQuest7RuntimeFlags()
            resetQuest8RuntimeFlags()
            PrologueStore.shared.progress.metBerynAfterHerbal = false
            PrologueStore.shared.progress.hasEliasBook = false
            PrologueStore.shared.save()
            saveAllVillageQuests()

            layout.solveAllPieces()
            layout.autoPlaceBuildings(buildingIDs: [
                VillageQuestCatalog.BuildingID.arthurHouse,
                VillageQuestCatalog.BuildingID.villageWell
            ])
            if let pos = grandpaQuestPosition {
                setArthurSafePosition(CGPoint(x: pos.x + 25, y: pos.y))
            } else {
                setArthurSafePosition(layout.world(sourcePosition) ?? VillageTileLayout.initial.center)
            }
            save()
            rebuild("Debug In-Game: Masuk ke Quest 1 (Arthur & Bu Mara).")

        case 2:
            var q1 = VillageQuest1Progress()
            q1.spokeToGrandpa = true
            q1.collectedWater = true
            q1.spokeToMara = true
            q1.rackFixed = true
            q1.returnedHome = true
            quest1 = q1

            quest2 = VillageQuest2Progress()
            quest3 = VillageQuest3Progress()
            quest4 = VillageQuest4Progress()
            quest5 = VillageQuest5Progress()
            quest7 = VillageQuest7Progress()
            quest8 = VillageQuest8Progress()
            resetQuest7RuntimeFlags()
            resetQuest8RuntimeFlags()
            PrologueStore.shared.progress.metBerynAfterHerbal = false
            PrologueStore.shared.save()
            saveAllVillageQuests()

            layout.solveAllPieces()
            layout.autoPlaceBuildings(buildingIDs: [
                VillageQuestCatalog.BuildingID.arthurHouse,
                VillageQuestCatalog.BuildingID.villageWell,
                VillageQuestCatalog.BuildingID.buMaraHouse,
                VillageQuestCatalog.BuildingID.villageBarn
            ])
            if let pos = quest2MaraPosition {
                setArthurSafePosition(CGPoint(x: pos.x + 25, y: pos.y))
            } else {
                setArthurSafePosition(layout.world(sourcePosition) ?? VillageTileLayout.initial.center)
            }
            save()
            rebuild("Debug In-Game: Masuk ke Quest 2 (Keneth & Lumbung Desa).")

        case 3:
            var q1 = VillageQuest1Progress()
            q1.spokeToGrandpa = true; q1.collectedWater = true; q1.spokeToMara = true; q1.rackFixed = true; q1.returnedHome = true
            quest1 = q1

            var q2 = VillageQuest2Progress()
            q2.spokeToGrandpa = true; q2.hasBasket = true; q2.metKeneth = true; q2.washedHands = true; q2.sortedSeeds = true; q2.doorWedged = true; q2.completed = true
            quest2 = q2

            quest3 = VillageQuest3Progress()
            quest4 = VillageQuest4Progress()
            quest5 = VillageQuest5Progress()
            quest7 = VillageQuest7Progress()
            quest8 = VillageQuest8Progress()
            resetQuest7RuntimeFlags()
            resetQuest8RuntimeFlags()
            PrologueStore.shared.progress.metBerynAfterHerbal = false
            PrologueStore.shared.save()
            saveAllVillageQuests()

            layout.solveAllPieces()
            layout.autoPlaceBuildings(buildingIDs: [
                VillageQuestCatalog.BuildingID.arthurHouse,
                VillageQuestCatalog.BuildingID.villageWell,
                VillageQuestCatalog.BuildingID.buMaraHouse,
                VillageQuestCatalog.BuildingID.villageBarn,
                VillageQuestCatalog.BuildingID.rolandPen
            ])
            if let rolandPos = quest3RolandPenPosition {
                setArthurSafePosition(CGPoint(x: rolandPos.x + 35, y: rolandPos.y))
            } else {
                setArthurSafePosition(layout.world(sourcePosition) ?? VillageTileLayout.initial.center)
            }
            save()
            rebuild("Debug In-Game: Masuk ke Quest 3 (Peternakan Roland).")

        case 4:
            var q1 = VillageQuest1Progress()
            q1.spokeToGrandpa = true; q1.collectedWater = true; q1.spokeToMara = true; q1.rackFixed = true; q1.returnedHome = true
            quest1 = q1

            var q2 = VillageQuest2Progress()
            q2.spokeToGrandpa = true; q2.hasBasket = true; q2.metKeneth = true; q2.washedHands = true; q2.sortedSeeds = true; q2.doorWedged = true; q2.completed = true
            quest2 = q2

            var q3 = VillageQuest3Progress()
            q3.spokeToRoland = true; q3.fenceChecked = true; q3.completed = true
            quest3 = q3

            quest4 = VillageQuest4Progress()
            quest5 = VillageQuest5Progress()
            quest7 = VillageQuest7Progress()
            quest8 = VillageQuest8Progress()
            resetQuest7RuntimeFlags()
            resetQuest8RuntimeFlags()
            PrologueStore.shared.progress.metBerynAfterHerbal = false
            PrologueStore.shared.save()
            saveAllVillageQuests()

            layout.solveAllPieces()
            layout.autoPlaceBuildings(buildingIDs: [
                VillageQuestCatalog.BuildingID.arthurHouse,
                VillageQuestCatalog.BuildingID.villageWell,
                VillageQuestCatalog.BuildingID.buMaraHouse,
                VillageQuestCatalog.BuildingID.villageBarn,
                VillageQuestCatalog.BuildingID.rolandPen,
                VillageQuestCatalog.BuildingID.annethHouse
            ])
            if let annethPos = quest4AnnethHousePosition {
                setArthurSafePosition(CGPoint(x: annethPos.x + 25, y: annethPos.y))
            } else {
                setArthurSafePosition(layout.world(sourcePosition) ?? VillageTileLayout.initial.center)
            }
            save()
            rebuild("Debug In-Game: Masuk ke Quest 4 (Rumah Anneth).")

        case 5:
            var q1 = VillageQuest1Progress()
            q1.spokeToGrandpa = true; q1.collectedWater = true; q1.spokeToMara = true; q1.rackFixed = true; q1.returnedHome = true
            quest1 = q1

            var q2 = VillageQuest2Progress()
            q2.spokeToGrandpa = true; q2.hasBasket = true; q2.metKeneth = true; q2.washedHands = true; q2.sortedSeeds = true; q2.doorWedged = true; q2.completed = true
            quest2 = q2

            var q3 = VillageQuest3Progress()
            q3.spokeToRoland = true; q3.fenceChecked = true; q3.completed = true
            quest3 = q3

            var q4 = VillageQuest4Progress()
            q4.metAnneth = true; q4.sortedTubers = true; q4.receivedSaltErrand = true; q4.completed = true
            quest4 = q4

            quest5 = VillageQuest5Progress()
            quest7 = VillageQuest7Progress()
            quest8 = VillageQuest8Progress()
            resetQuest7RuntimeFlags()
            resetQuest8RuntimeFlags()
            PrologueStore.shared.progress.metBerynAfterHerbal = false
            PrologueStore.shared.save()
            saveAllVillageQuests()

            layout.solveAllPieces()
            layout.autoPlaceBuildings(buildingIDs: [
                VillageQuestCatalog.BuildingID.arthurHouse,
                VillageQuestCatalog.BuildingID.villageWell,
                VillageQuestCatalog.BuildingID.buMaraHouse,
                VillageQuestCatalog.BuildingID.villageBarn,
                VillageQuestCatalog.BuildingID.rolandPen,
                VillageQuestCatalog.BuildingID.annethHouse,
                VillageQuestCatalog.BuildingID.berynHouse
            ])
            if let minePos = quest5RockSaltMinePosition ?? quest5OldMinerPosition {
                setArthurSafePosition(CGPoint(x: minePos.x - 30, y: minePos.y))
            } else {
                setArthurSafePosition(layout.world(sourcePosition) ?? VillageTileLayout.initial.center)
            }
            save()
            rebuild("Debug In-Game: Masuk ke Quest 5 (Tambang Rock Salt & Sesepuh Beryn).")

        case 6:
            var q1 = VillageQuest1Progress()
            q1.spokeToGrandpa = true; q1.collectedWater = true; q1.spokeToMara = true; q1.rackFixed = true; q1.returnedHome = true
            quest1 = q1

            var q2 = VillageQuest2Progress()
            q2.spokeToGrandpa = true; q2.hasBasket = true; q2.metKeneth = true; q2.washedHands = true; q2.sortedSeeds = true; q2.doorWedged = true; q2.completed = true
            quest2 = q2

            var q3 = VillageQuest3Progress()
            q3.spokeToRoland = true; q3.fenceChecked = true; q3.completed = true
            quest3 = q3

            var q4 = VillageQuest4Progress()
            q4.metAnneth = true; q4.sortedTubers = true; q4.receivedSaltErrand = true; q4.completed = true
            quest4 = q4

            var q5 = VillageQuest5Progress()
            q5.minedSalt = true; q5.deliveredSalt = true; q5.heardSeaLegend = true; q5.receivedSilverLeafMission = true; q5.completed = true
            quest5 = q5

            quest7 = VillageQuest7Progress()
            quest8 = VillageQuest8Progress()
            resetQuest7RuntimeFlags()
            resetQuest8RuntimeFlags()
            saveAllVillageQuests()

            let progress = PrologueStore.shared.progress
            progress.isRockSaltUnlocked = true; progress.hasRockSalt = true; progress.deliveredRockSalt = true
            progress.isHerbalUnlocked = true; progress.hasHerbal = false
            progress.encounteredHollow = false; progress.metBerynAfterHerbal = false
            progress.mapBStage = .herbalHills
            progress.placements[MemoryPiece.boundary.slot] = PhotoPlacement(piece: .boundary, turns: 0)
            PrologueStore.shared.save()

            let exploration = ExplorationScene(size: size, entry: .boundary, worldLocations: [.boundary])
            exploration.scaleMode = .resizeFill
            view?.presentScene(exploration, transition: .fade(withDuration: 0.3))

        case 7:
            var q1 = VillageQuest1Progress()
            q1.spokeToGrandpa = true; q1.collectedWater = true; q1.spokeToMara = true; q1.rackFixed = true; q1.returnedHome = true
            quest1 = q1

            var q2 = VillageQuest2Progress()
            q2.spokeToGrandpa = true; q2.hasBasket = true; q2.metKeneth = true; q2.washedHands = true; q2.sortedSeeds = true; q2.doorWedged = true; q2.completed = true
            quest2 = q2

            var q3 = VillageQuest3Progress()
            q3.spokeToRoland = true; q3.fenceChecked = true; q3.completed = true
            quest3 = q3

            var q4 = VillageQuest4Progress()
            q4.metAnneth = true; q4.sortedTubers = true; q4.receivedSaltErrand = true; q4.completed = true
            quest4 = q4

            var q5 = VillageQuest5Progress()
            q5.minedSalt = true; q5.deliveredSalt = true; q5.heardSeaLegend = true; q5.receivedSilverLeafMission = true; q5.completed = true
            quest5 = q5

            PrologueStore.shared.progress.metBerynAfterHerbal = true
            PrologueStore.shared.progress.hasEliasBook = false
            PrologueStore.shared.save()

            resetQuest7RuntimeFlags()
            resetQuest8RuntimeFlags()
            var q7 = VillageQuest7Progress()
            if step2 {
                q7.spokeToGrandpa = true
                q7.woodCollectedCount = 5
                q7.hasGatheredWood = true
                q7.inspectedLandslide = false
                q7.foundEliasBook = false
                q7.confrontedGrandpa = false
                q7.completed = false
            }
            quest7 = q7
            quest8 = VillageQuest8Progress()
            saveAllVillageQuests()

            layout.solveAllPieces()
            layout.autoPlaceBuildings(buildingIDs: [
                VillageQuestCatalog.BuildingID.arthurHouse,
                VillageQuestCatalog.BuildingID.villageWell,
                VillageQuestCatalog.BuildingID.buMaraHouse,
                VillageQuestCatalog.BuildingID.villageBarn,
                VillageQuestCatalog.BuildingID.rolandPen,
                VillageQuestCatalog.BuildingID.annethHouse,
                VillageQuestCatalog.BuildingID.berynHouse
            ])
            if step2, let landslidePos = quest7LandslidePosition {
                setArthurSafePosition(CGPoint(x: landslidePos.x - 30, y: landslidePos.y))
            } else {
                setArthurSafePosition(quest7GrandpaPosition)
            }
            save()
            rebuild(step2 ? "Debug In-Game: Quest 7 Step 2 (Kayu 5/5, siap gali Jurnal Elias)." : "Debug In-Game: Masuk ke Quest 7 (Arthur mencari kayu & menemukan buku).")

        case 8:
            var q1 = VillageQuest1Progress()
            q1.spokeToGrandpa = true; q1.collectedWater = true; q1.spokeToMara = true; q1.rackFixed = true; q1.returnedHome = true
            quest1 = q1

            var q2 = VillageQuest2Progress()
            q2.spokeToGrandpa = true; q2.hasBasket = true; q2.metKeneth = true; q2.washedHands = true; q2.sortedSeeds = true; q2.doorWedged = true; q2.completed = true
            quest2 = q2

            var q3 = VillageQuest3Progress()
            q3.spokeToRoland = true; q3.fenceChecked = true; q3.completed = true
            quest3 = q3

            var q4 = VillageQuest4Progress()
            q4.metAnneth = true; q4.sortedTubers = true; q4.receivedSaltErrand = true; q4.completed = true
            quest4 = q4

            var q5 = VillageQuest5Progress()
            q5.minedSalt = true; q5.deliveredSalt = true; q5.heardSeaLegend = true; q5.receivedSilverLeafMission = true; q5.completed = true
            quest5 = q5

            var q7 = VillageQuest7Progress()
            q7.spokeToGrandpa = true; q7.woodCollectedCount = 5; q7.hasGatheredWood = true; q7.inspectedLandslide = true; q7.foundEliasBook = true; q7.confrontedGrandpa = true; q7.completed = true
            quest7 = q7

            PrologueStore.shared.progress.metBerynAfterHerbal = true
            PrologueStore.shared.progress.hasEliasBook = true
            PrologueStore.shared.progress.hasBook = true
            PrologueStore.shared.save()

            resetQuest8RuntimeFlags()
            var q8 = VillageQuest8Progress()
            if step == 2 {
                q8.secretBaseMetFriends = true
                q8.convincingAttempted = true
                q8.convincingFailed = true
            } else if step == 3 {
                q8.secretBaseMetFriends = true
                q8.convincingAttempted = true
                q8.convincingFailed = true
                q8.experiencedFog = true
                q8.spokeToElderInFog = true
                q8.annethBackyardMet = true
            }
            quest8 = q8
            quest9 = VillageQuest9Progress()
            resetQuest9RuntimeFlags()
            saveAllVillageQuests()

            layout.solveAllPieces()
            layout.autoPlaceBuildings(buildingIDs: [
                VillageQuestCatalog.BuildingID.arthurHouse,
                VillageQuestCatalog.BuildingID.villageWell,
                VillageQuestCatalog.BuildingID.buMaraHouse,
                VillageQuestCatalog.BuildingID.villageBarn,
                VillageQuestCatalog.BuildingID.rolandPen,
                VillageQuestCatalog.BuildingID.annethHouse,
                VillageQuestCatalog.BuildingID.berynHouse,
                VillageQuestCatalog.BuildingID.emptyWarehouse
            ])

            if step == 1 {
                setArthurSafePosition(quest8WarehousePosition)
                save()
                rebuild("Debug In-Game: Quest 8 Fase 1 (Gudang Kosong & Diskusi Buku Elias).")
            } else if step == 2 {
                setArthurSafePosition(quest8ElderFogPosition)
                save()
                rebuild("Debug In-Game: Quest 8 Fase 2 (The Old Fog & Peringatan Tetua).")
            } else {
                setArthurSafePosition(quest8AnnethBackyardPosition)
                save()
                rebuild("Debug In-Game: Quest 8 Fase 3 & 4 (Belakang Rumah Anneth & Party Loadout).")
            }

        default:
            break
        }
    }

    func completeAllQuests() {
        dismissQuestDebugModal()
        stopInput()
        isMap = false

        var q1 = VillageQuest1Progress()
        q1.spokeToGrandpa = true; q1.collectedWater = true; q1.spokeToMara = true; q1.rackFixed = true; q1.returnedHome = true
        quest1 = q1

        var q2 = VillageQuest2Progress()
        q2.spokeToGrandpa = true; q2.hasBasket = true; q2.metKeneth = true; q2.washedHands = true; q2.sortedSeeds = true; q2.doorWedged = true; q2.completed = true
        quest2 = q2

        var q3 = VillageQuest3Progress()
        q3.spokeToRoland = true; q3.fenceChecked = true; q3.completed = true
        quest3 = q3

        var q4 = VillageQuest4Progress()
        q4.metAnneth = true; q4.sortedTubers = true; q4.receivedSaltErrand = true; q4.completed = true
        quest4 = q4

        var q5 = VillageQuest5Progress()
        q5.minedSalt = true; q5.deliveredSalt = true; q5.heardSeaLegend = true; q5.receivedSilverLeafMission = true; q5.completed = true
        quest5 = q5

        var q7 = VillageQuest7Progress()
        q7.spokeToGrandpa = true; q7.woodCollectedCount = 5; q7.hasGatheredWood = true
        q7.inspectedLandslide = true; q7.foundEliasBook = true; q7.confrontedGrandpa = true; q7.completed = true
        quest7 = q7

        var q8 = VillageQuest8Progress()
        q8.secretBaseMetFriends = true
        q8.convincingAttempted = true
        q8.convincingFailed = true
        q8.experiencedFog = true
        q8.spokeToElderInFog = true
        q8.annethBackyardMet = true
        q8.packedKnife = true
        q8.packedRope = true
        q8.packedWater = true
        q8.packedOintment = true
        q8.packedJournal = true
        q8.completed = true
        quest8 = q8
        quest9 = VillageQuest9Progress()
        resetQuest9RuntimeFlags()

        let progress = PrologueStore.shared.progress
        progress.metBerynAfterHerbal = true
        progress.hasEliasBook = true
        progress.hasBook = true
        progress.boundaryMarked = true
        PrologueStore.shared.save()

        saveAllVillageQuests()
        layout.solveAllPieces()
        layout.autoPlaceBuildings(buildingIDs: [
            VillageQuestCatalog.BuildingID.arthurHouse,
            VillageQuestCatalog.BuildingID.villageWell,
            VillageQuestCatalog.BuildingID.buMaraHouse,
            VillageQuestCatalog.BuildingID.villageBarn,
            VillageQuestCatalog.BuildingID.rolandPen,
            VillageQuestCatalog.BuildingID.annethHouse,
            VillageQuestCatalog.BuildingID.berynHouse,
            VillageQuestCatalog.BuildingID.emptyWarehouse
        ])
        setArthurSafePosition(quest9HomePosition)
        save()
        rebuild("Debug In-Game: Quest 1-8 selesai. Quest 9 Perjalanan Keluar Desa dimulai.")
    }

    func resetAllQuests() {
        dismissQuestDebugModal()
        stopInput()
        isMap = false

        quest1 = VillageQuest1Progress()
        quest2 = VillageQuest2Progress()
        quest3 = VillageQuest3Progress()
        quest4 = VillageQuest4Progress()
        quest5 = VillageQuest5Progress()
        quest7 = VillageQuest7Progress()
        quest8 = VillageQuest8Progress()
        quest9 = VillageQuest9Progress()
        resetQuest7RuntimeFlags()
        resetQuest8RuntimeFlags()
        resetQuest9RuntimeFlags()

        let progress = PrologueStore.shared.progress
        progress.metBerynAfterHerbal = false
        progress.hasEliasBook = false
        progress.hasBook = false
        progress.boundaryMarked = false
        PrologueStore.shared.save()

        saveAllVillageQuests()
        layout = VillageTileLayout()
        layout.autoPlaceBuildings(buildingIDs: [
            VillageQuestCatalog.BuildingID.arthurHouse,
            VillageQuestCatalog.BuildingID.villageWell
        ])
        setArthurSafePosition(layout.world(sourcePosition) ?? VillageTileLayout.initial.center)
        save()
        rebuild("Debug In-Game: Seluruh progres Quest 1 - 9 telah di-reset ke awal mula.")
    }
}
