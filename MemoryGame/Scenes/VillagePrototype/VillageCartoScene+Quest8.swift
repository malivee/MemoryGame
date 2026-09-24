// Quest 8: Arthur menceritakan Buku Elias dan pertemuannya dengan The Hollow ke teman-temannya.
// Alur:
// 1. Prasyarat: Harus ada Rumah Kakek dan Rumah Kosong (Gudang Kosong) di peta baru bisa mulai.
// 2. Secret Base (Gudang Kosong Dekat Sungai): Dialog pilihan Scripted Failure.
// 3. The Old Fog (Kabut Kuno Senja): Suasana mencekam & pengumuman Tetua Desa.
// 4. Belakang Rumah Anneth (Malam Hari): Musyawarah malam hari.
// 5. Minigame Kemas Barang (In-World Pickup kayak ranting kayu): 5 barang wajib dikumpulkan.
// 6. Rumah Kakek: Arthur kembali ke rumah kakek untuk beristirahat sebelum fajar.

import SpriteKit
import SwiftUI
import UIKit

final class VillageQuest8Runtime {
    static let shared = VillageQuest8Runtime()

    var progress = VillageQuest8Progress.load()
    var choiceCompletion: ((Int) -> Void)?
    var isTransitioning = false
}

extension VillageCartoScene {
    var quest8: VillageQuest8Progress {
        get { VillageQuest8Runtime.shared.progress }
        set { VillageQuest8Runtime.shared.progress = newValue }
    }

    var quest8Objective: String {
        VillageQuestEngine.quest8Objective(for: villageQuestSnapshot)
    }

    func saveQuest8() {
        quest8.save()
    }

    func resetQuest8RuntimeFlags() {
        VillageQuest8Runtime.shared.choiceCompletion = nil
        VillageQuest8Runtime.shared.isTransitioning = false
    }

    // MARK: - Prasyarat Bangunan (Hardcoded Auto-Placement & Fallbacks)

    var hasEmptyWarehousePlaced: Bool {
        layout.buildingPlacements.contains { $0.id == VillageQuestCatalog.BuildingID.emptyWarehouse }
    }

    var hasGrandpaHousePlaced: Bool {
        layout.buildingPlacements.contains {
            $0.id == VillageQuestCatalog.BuildingID.berynHouse ||
            $0.id == VillageQuestCatalog.BuildingID.arthurHouse
        }
    }

    var hasQuest8Prerequisites: Bool {
        ensureQuest8PrerequisitesHardcoded()
        return true
    }

    func ensureQuest8PrerequisitesHardcoded() {
        var needed: [String] = []
        if !hasEmptyWarehousePlaced {
            needed.append(VillageQuestCatalog.BuildingID.emptyWarehouse)
        }
        if !hasGrandpaHousePlaced {
            needed.append(VillageQuestCatalog.BuildingID.berynHouse)
        }
        if !layout.buildingPlacements.contains(where: { $0.id == VillageQuestCatalog.BuildingID.annethHouse }) {
            needed.append(VillageQuestCatalog.BuildingID.annethHouse)
        }
        if !needed.isEmpty {
            layout.autoPlaceBuildings(buildingIDs: needed)
            save()
        }
    }

    // MARK: - Key World Positions (Hardcoded Rock-Solid Fallbacks)

    var quest8WarehousePosition: CGPoint {
        if let warehouse = questPosition(for: "empty-warehouse") {
            return CGPoint(x: warehouse.x + 24, y: warehouse.y - 12)
        }
        let spawnPos = layout.world(VillageCartoMap.spawn) ?? actor.position
        return CGPoint(x: spawnPos.x - 115, y: spawnPos.y - 75)
    }

    var quest8GrandpaPosition: CGPoint {
        if let beryn = questPosition(for: "beryn-house") {
            return CGPoint(x: beryn.x + 28, y: beryn.y - 12)
        }
        if let arthur = questPosition(for: "arthur-house") {
            return CGPoint(x: arthur.x + 28, y: arthur.y - 12)
        }
        let spawnPos = layout.world(VillageCartoMap.spawn) ?? actor.position
        return CGPoint(x: spawnPos.x + 85, y: spawnPos.y + 60)
    }

    var quest8ElderFogPosition: CGPoint {
        let spawnPos = layout.world(VillageCartoMap.spawn) ?? actor.position
        return CGPoint(x: spawnPos.x + 18, y: spawnPos.y - 28)
    }

    var quest8AnnethBackyardPosition: CGPoint {
        if let anneth = questPosition(for: "anneth-house") {
            return CGPoint(x: anneth.x - 24, y: anneth.y + 26)
        }
        let spawnPos = layout.world(VillageCartoMap.spawn) ?? actor.position
        return CGPoint(x: spawnPos.x - 65, y: spawnPos.y + 85)
    }

    // 5 Posisi Barang Ekspedisi (Hardcoded, Tersebar Rapi di Halaman Anneth)
    var quest8LoadoutItemPositions: [(id: String, name: String, icon: String, position: CGPoint)] {
        let yard = quest8AnnethBackyardPosition
        return [
            ("knife", "Pisau Kecil", "🗡️", CGPoint(x: yard.x - 52, y: yard.y - 18)),
            ("rope", "Tali Rami Kuat", "🪢", CGPoint(x: yard.x + 52, y: yard.y - 14)),
            ("water", "Botol Air Minum", "🍶", CGPoint(x: yard.x - 36, y: yard.y + 44)),
            ("ointment", "Salep Herbal & Kain", "🌿", CGPoint(x: yard.x + 38, y: yard.y + 42)),
            ("journal", "Buku Jurnal Elias", "📖", CGPoint(x: yard.x, y: yard.y - 48))
        ]
    }

    func isQuest8ItemPacked(id: String) -> Bool {
        switch id {
        case "knife": return quest8.packedKnife
        case "rope": return quest8.packedRope
        case "water": return quest8.packedWater
        case "ointment": return quest8.packedOintment
        case "journal": return quest8.packedJournal
        default: return false
        }
    }

    // MARK: - World Rendering

    func renderQuest8World() {
        guard !quest8.completed else { return }

        // Pastikan prasyarat bangunan terpasang otomatis (hardcoded guarantee)
        ensureQuest8PrerequisitesHardcoded()

        // FASE 1: Sore Hari di Gudang Kosong (Secret Base)
        if !quest8.convincingFailed {
            renderQuest8SecretBase()
            return
        }

        // FASE 2: Senja Menjelang Malam — The Old Fog
        if quest8.convincingFailed && !quest8.experiencedFog {
            renderQuest8TheOldFogEvent()
            return
        }

        // FASE 3 & 4: Malam Hari di Belakang Rumah Anneth (Musyawarah & Kemas Barang)
        if quest8.experiencedFog && !quest8.allItemsPacked {
            renderQuest8AnnethBackyardNight()
            if quest8.annethBackyardMet {
                renderQuest8LoadoutHUD()
            }
            return
        }

        // FASE 5: Setelah semua barang terkemas -> Kembali ke Rumah Kakek!
        if quest8.allItemsPacked && !quest8.returnedToGrandpa {
            renderQuest8ReturnToGrandpaHouse()
        }
    }

    // MARK: - Phase 1: Secret Base (Gudang Kosong Dekat Sungai)

    private func renderQuest8SecretBase() {
        let base = quest8WarehousePosition

        let baseNode = SKNode()
        baseNode.position = base
        baseNode.zPosition = 52
        baseNode.name = "quest8-base-environment"

        // Rerumputan rahasia tepi sungai
        let grass = SKShapeNode(ellipseOf: CGSize(width: 130, height: 80))
        grass.fillColor = SKColor(red: 0.16, green: 0.28, blue: 0.18, alpha: 0.55)
        grass.strokeColor = .clear
        baseNode.addChild(grass)

        // Aliran riak sungai kecil
        let riverRipples = SKShapeNode(rectOf: CGSize(width: 140, height: 16), cornerRadius: 8)
        riverRipples.position = CGPoint(x: 0, y: -44)
        riverRipples.fillColor = SKColor(red: 0.15, green: 0.40, blue: 0.50, alpha: 0.45)
        riverRipples.strokeColor = SKColor(red: 0.35, green: 0.70, blue: 0.85, alpha: 0.6)
        riverRipples.lineWidth = 1.0
        riverRipples.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.3, duration: 1.2),
            .fadeAlpha(to: 0.7, duration: 1.2)
        ])))
        baseNode.addChild(riverRipples)

        // Batu-batu besar tempat duduk (Sitting Boulders)
        let boulderPositions: [CGPoint] = [
            CGPoint(x: -32, y: -10), // Keneth
            CGPoint(x: 34, y: 12),   // Roland
            CGPoint(x: 0, y: 28),    // Anneth
            CGPoint(x: 0, y: -4)     // Batu Datar Buku Elias
        ]

        for (idx, p) in boulderPositions.enumerated() {
            let boulder = SKShapeNode(ellipseOf: CGSize(width: idx == 3 ? 34 : 26, height: idx == 3 ? 24 : 18))
            boulder.position = p
            boulder.fillColor = idx == 3 ? SKColor(white: 0.38, alpha: 1) : SKColor(white: 0.30, alpha: 1)
            boulder.strokeColor = SKColor(white: 0.20, alpha: 1)
            boulder.lineWidth = 1.5
            baseNode.addChild(boulder)
        }

        // Buku Elias Terbuka di Atas Batu Tengah
        let openBook = SKNode()
        openBook.position = CGPoint(x: 0, y: -4)

        let pageLeft = SKShapeNode(rectOf: CGSize(width: 9, height: 11), cornerRadius: 1.5)
        pageLeft.position = CGPoint(x: -4.5, y: 0)
        pageLeft.fillColor = SKColor(red: 0.94, green: 0.88, blue: 0.75, alpha: 1)
        pageLeft.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1)
        pageLeft.lineWidth = 0.8
        openBook.addChild(pageLeft)

        let pageRight = SKShapeNode(rectOf: CGSize(width: 9, height: 11), cornerRadius: 1.5)
        pageRight.position = CGPoint(x: 4.5, y: 0)
        pageRight.fillColor = SKColor(red: 0.94, green: 0.88, blue: 0.75, alpha: 1)
        pageRight.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1)
        pageRight.lineWidth = 0.8
        openBook.addChild(pageRight)

        // Sketsa Hollow
        let hollowDrawing = SKShapeNode(circleOfRadius: 2.5)
        hollowDrawing.position = CGPoint(x: 4.5, y: 0)
        hollowDrawing.fillColor = .black
        hollowDrawing.strokeColor = .clear
        openBook.addChild(hollowDrawing)

        let bookGlow = SKShapeNode(circleOfRadius: 14)
        bookGlow.fillColor = SKColor.systemOrange.withAlphaComponent(0.25)
        bookGlow.strokeColor = .clear
        bookGlow.run(.repeatForever(.sequence([
            .scale(to: 1.25, duration: 0.7),
            .scale(to: 0.9, duration: 0.7)
        ])))
        openBook.addChild(bookGlow)

        baseNode.addChild(openBook)
        world.addChild(baseNode)

        // Render teman-teman di sekeliling batu
        questNPC(at: CGPoint(x: base.x - 30, y: base.y - 8), name: "Keneth", color: .systemOrange)
        questNPC(at: CGPoint(x: base.x + 32, y: base.y + 10), name: "Roland", color: .systemRed)
        questNPC(at: CGPoint(x: base.x, y: base.y + 30), name: "Anneth", color: .systemPurple)

        questMarker(at: CGPoint(x: base.x, y: base.y + 44), name: "quest8-secret-base", color: .systemYellow, symbol: "!")
        renderQuest8Badge(at: CGPoint(x: base.x, y: base.y + 58), text: "[Bicara dengan Teman-teman]", color: .systemYellow)
    }

    // MARK: - Phase 2: Atmospheric Event (The Old Fog / Kabut Kuno Senja)

    private func renderQuest8TheOldFogEvent() {
        let elderPos = quest8ElderFogPosition

        let fogLayer = SKNode()
        fogLayer.name = "quest8-fog-layer"
        fogLayer.zPosition = 88

        let twilightTint = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        twilightTint.fillColor = SKColor(red: 0.16, green: 0.14, blue: 0.24, alpha: 0.40)
        twilightTint.strokeColor = .clear
        fogLayer.addChild(twilightTint)

        for i in 0..<6 {
            let mistBand = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 260...440), height: CGFloat.random(in: 55...95)))
            mistBand.position = CGPoint(
                x: elderPos.x + CGFloat((i - 3) * 75),
                y: elderPos.y + CGFloat.random(in: -90...90)
            )
            mistBand.fillColor = SKColor(white: 0.94, alpha: 0.32)
            mistBand.strokeColor = .clear
            mistBand.zPosition = 89

            let moveRight = SKAction.moveBy(x: 35, y: CGFloat.random(in: -10...10), duration: Double.random(in: 3.5...5.0))
            let moveLeft = SKAction.moveBy(x: -35, y: CGFloat.random(in: -10...10), duration: Double.random(in: 3.5...5.0))
            mistBand.run(.repeatForever(.sequence([moveRight, moveLeft])))

            fogLayer.addChild(mistBand)
        }

        world.addChild(fogLayer)

        questNPC(at: elderPos, name: "Tetua Desa", color: .systemTeal)

        let lantern = SKShapeNode(circleOfRadius: 5)
        lantern.position = CGPoint(x: elderPos.x + 10, y: elderPos.y - 2)
        lantern.fillColor = SKColor.systemYellow
        lantern.strokeColor = SKColor.systemOrange
        lantern.lineWidth = 1.0

        let lanternGlow = SKShapeNode(circleOfRadius: 18)
        lanternGlow.fillColor = SKColor.systemYellow.withAlphaComponent(0.35)
        lanternGlow.strokeColor = .clear
        lanternGlow.run(.repeatForever(.sequence([
            .scale(to: 1.2, duration: 0.8),
            .scale(to: 0.85, duration: 0.8)
        ])))
        lantern.addChild(lanternGlow)
        world.addChild(lantern)

        questMarker(at: CGPoint(x: elderPos.x, y: elderPos.y + 24), name: "quest8-elder-fog", color: .systemYellow, symbol: "!")
        renderQuest8Badge(at: CGPoint(x: elderPos.x, y: elderPos.y + 38), text: "Dengarkan Peringatan Tetua", color: .systemYellow)
    }

    // MARK: - Phase 3 & 4: Belakang Rumah Anneth & Kemas 5 Barang Kayak Kayu Q7

    private func renderQuest8AnnethBackyardNight() {
        let yard = quest8AnnethBackyardPosition

        let nightNode = SKNode()
        nightNode.position = yard
        nightNode.zPosition = 52
        nightNode.name = "quest8-anneth-night-env"

        let darkYard = SKShapeNode(ellipseOf: CGSize(width: 150, height: 100))
        darkYard.fillColor = SKColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 0.70)
        darkYard.strokeColor = .clear
        nightNode.addChild(darkYard)

        // Pendar cahaya jendela dapur Anneth
        let kitchenGlow = SKShapeNode(ellipseOf: CGSize(width: 75, height: 45))
        kitchenGlow.position = CGPoint(x: 18, y: 22)
        kitchenGlow.fillColor = SKColor(red: 0.98, green: 0.72, blue: 0.28, alpha: 0.35)
        kitchenGlow.strokeColor = .clear
        kitchenGlow.run(.repeatForever(.sequence([
            .scale(to: 1.12, duration: 1.4),
            .scale(to: 0.95, duration: 1.4)
        ])))
        nightNode.addChild(kitchenGlow)

        // Meja kayu tempat tas ransel
        let workbench = SKShapeNode(rectOf: CGSize(width: 32, height: 20), cornerRadius: 3)
        workbench.position = CGPoint(x: 0, y: -4)
        workbench.fillColor = SKColor(red: 0.32, green: 0.22, blue: 0.14, alpha: 1)
        workbench.strokeColor = SKColor(red: 0.18, green: 0.11, blue: 0.06, alpha: 1)
        workbench.lineWidth = 1.2
        nightNode.addChild(workbench)

        // Tas ransel kulit Anneth
        let satchel = SKShapeNode(rectOf: CGSize(width: 14, height: 10), cornerRadius: 2)
        satchel.position = CGPoint(x: 0, y: -4)
        satchel.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.18, alpha: 1)
        satchel.strokeColor = SKColor(red: 0.90, green: 0.75, blue: 0.35, alpha: 0.9)
        satchel.lineWidth = 1.0
        nightNode.addChild(satchel)

        world.addChild(nightNode)

        // Render teman-teman berkerumun
        questNPC(at: CGPoint(x: yard.x - 24, y: yard.y + 10), name: "Keneth", color: .systemOrange)
        questNPC(at: CGPoint(x: yard.x + 24, y: yard.y + 10), name: "Roland", color: .systemRed)
        questNPC(at: CGPoint(x: yard.x, y: yard.y + 18), name: "Anneth", color: .systemPurple)

        if !quest8.annethBackyardMet {
            questMarker(at: CGPoint(x: yard.x, y: yard.y + 36), name: "quest8-anneth-backyard", color: .systemYellow, symbol: "!")
            renderQuest8Badge(at: CGPoint(x: yard.x, y: yard.y + 50), text: "Musyawarah Malam Hari", color: .systemYellow)
        } else {
            // Render 5 Barang Ekspedisi di halaman (PERSIS SEPERTI KAYU DI Q7)
            renderQuest8ScatteredLoadoutItems()
        }
    }

    // MARK: - Phase 4: Click to Pick In-World Loadout Items

    private func renderQuest8ScatteredLoadoutItems() {
        for item in quest8LoadoutItemPositions {
            if !isQuest8ItemPacked(id: item.id) {
                renderQuest8SingleLoadoutItemNode(item: item)
            }
        }
    }

    private func renderQuest8SingleLoadoutItemNode(item: (id: String, name: String, icon: String, position: CGPoint)) {
        let node = SKNode()
        node.position = item.position
        node.name = "quest8-item-\(item.id)"
        node.zPosition = 60

        // Bayangan lembut di bawah barang
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 24, height: 10))
        shadow.fillColor = SKColor(white: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -4)
        node.addChild(shadow)

        // Aura pendar penanda interaktif (persis gaya ranting kayu Quest 7)
        let aura = SKShapeNode(circleOfRadius: 15)
        aura.fillColor = SKColor.systemOrange.withAlphaComponent(0.30)
        aura.strokeColor = SKColor.systemYellow.withAlphaComponent(0.65)
        aura.lineWidth = 1.0
        aura.run(.repeatForever(.sequence([
            .scale(to: 1.2, duration: 0.65),
            .scale(to: 0.9, duration: 0.65)
        ])))
        node.addChild(aura)

        // Ikon barang
        let iconLbl = SKLabelNode(text: item.icon)
        iconLbl.fontSize = 15
        iconLbl.verticalAlignmentMode = .center
        node.addChild(iconLbl)

        // Label penanda barang (gaya konsisten Carto seperti file lain)
        let badge = SKNode()
        badge.position = CGPoint(x: 0, y: 15)
        badge.name = "quest8-pick-\(item.id)"

        let text = "\(item.icon) \(item.name)"
        let bg = SKShapeNode(rectOf: CGSize(width: CGFloat(text.count * 6 + 18), height: 18), cornerRadius: 6)
        bg.fillColor = SKColor(white: 0.1, alpha: 0.90)
        bg.strokeColor = SKColor.systemYellow.withAlphaComponent(0.85)
        bg.lineWidth = 1.0
        badge.addChild(bg)

        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = text
        lbl.fontSize = 8.5
        lbl.fontColor = .systemYellow
        lbl.verticalAlignmentMode = .center
        badge.addChild(lbl)

        node.addChild(badge)

        world.addChild(node)
    }

    // MARK: - HUD Top Bar: Click-to-Pick Expedition Loadout

    func renderQuest8LoadoutHUD() {
        hud.childNode(withName: "quest8-loadout-hud")?.removeFromParent()

        let hudBar = SKNode()
        hudBar.name = "quest8-loadout-hud"
        hudBar.zPosition = 200

        let barWidth = min(size.width - 32, 540)
        let barHeight: CGFloat = 48
        hudBar.position = CGPoint(x: size.width / 2, y: size.height - 52)

        let bg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 12)
        bg.fillColor = SKColor(red: 0.07, green: 0.10, blue: 0.15, alpha: 0.94)
        bg.strokeColor = SKColor(red: 0.85, green: 0.70, blue: 0.35, alpha: 0.8)
        bg.lineWidth = 1.2
        hudBar.addChild(bg)

        let titleLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLbl.text = "🎒 BEKAL EKSPEDISI (\(quest8.packedCount)/5) — KLIK BARANG UNTUK MENGEMAS"
        titleLbl.fontSize = 10.5
        titleLbl.fontColor = .systemYellow
        titleLbl.position = CGPoint(x: 0, y: 11)
        hudBar.addChild(titleLbl)

        let items = quest8LoadoutItemPositions
        let itemWidth: CGFloat = (barWidth - 24) / CGFloat(items.count)
        let startX = -barWidth / 2 + itemWidth / 2 + 12

        for (idx, item) in items.enumerated() {
            let cx = startX + CGFloat(idx) * itemWidth
            let isPacked = isQuest8ItemPacked(id: item.id)

            let slot = SKShapeNode(rectOf: CGSize(width: itemWidth - 6, height: 22), cornerRadius: 6)
            slot.position = CGPoint(x: cx, y: -9)
            slot.name = "quest8-hud-item-\(item.id)"

            if isPacked {
                slot.fillColor = SKColor.systemGreen.withAlphaComponent(0.25)
                slot.strokeColor = SKColor.systemGreen.withAlphaComponent(0.85)
                slot.lineWidth = 1.0
            } else {
                slot.fillColor = SKColor(white: 0.18, alpha: 0.85)
                slot.strokeColor = SKColor.systemYellow.withAlphaComponent(0.7)
                slot.lineWidth = 1.0
            }

            let slotLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
            slotLbl.text = isPacked ? "\(item.icon) ✓" : "\(item.icon) Ambil"
            slotLbl.fontSize = 9.5
            slotLbl.fontColor = isPacked ? .systemGreen : .systemYellow
            slotLbl.verticalAlignmentMode = .center
            slotLbl.name = "quest8-hud-item-\(item.id)"
            slot.addChild(slotLbl)

            hudBar.addChild(slot)
        }

        hud.addChild(hudBar)
    }

    func handleQuest8HUDTap(actions: Set<String>) -> Bool {
        guard quest8.annethBackyardMet && !quest8.allItemsPacked else { return false }
        for item in quest8LoadoutItemPositions {
            if actions.contains("quest8-hud-item-\(item.id)") && !isQuest8ItemPacked(id: item.id) {
                collectQuest8LoadoutItem(id: item.id, name: item.name, position: item.position)
                return true
            }
        }
        return false
    }

    // MARK: - Phase 5: Return to Rumah Kakek After Loadout

    private func renderQuest8ReturnToGrandpaHouse() {
        let grandpa = quest8GrandpaPosition
        questNPC(at: grandpa, name: "Rumah Kakek", color: .systemTeal)

        questMarker(at: CGPoint(x: grandpa.x, y: grandpa.y + 25), name: "quest8-return-grandpa", color: .systemGreen, symbol: "!")
        renderQuest8Badge(at: CGPoint(x: grandpa.x, y: grandpa.y + 38), text: "Kembali ke Rumah Kakek", color: .systemGreen)
    }

    private func renderQuest8Badge(at position: CGPoint, text: String, color: SKColor) {
        let badge = SKNode()
        badge.position = position
        badge.zPosition = 85
        badge.name = "quest8-badge"

        let bg = SKShapeNode(rectOf: CGSize(width: CGFloat(text.count * 6 + 18), height: 18), cornerRadius: 6)
        bg.fillColor = SKColor(white: 0.1, alpha: 0.90)
        bg.strokeColor = color.withAlphaComponent(0.85)
        bg.lineWidth = 1.0
        badge.addChild(bg)

        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = text
        lbl.fontSize = 9
        lbl.fontColor = color
        lbl.verticalAlignmentMode = .center
        badge.addChild(lbl)

        world.addChild(badge)
    }

    // MARK: - Proximity Check (Otomatis Memungut Barang Saat Arthur Berjalan di Atasnya)

    func checkQuest8Proximity() {
        guard !quest8.completed else { return }
        guard questDialogue.isEmpty else { return }
        guard !VillageQuest8Runtime.shared.isTransitioning else { return }

        // FASE 2: Arthur mendekati Tetua Desa di jalanan berkabut
        if quest8.convincingFailed && !quest8.experiencedFog {
            let elder = quest8ElderFogPosition
            if hypot(actor.position.x - elder.x, actor.position.y - elder.y) < 38 {
                startQuest8ElderFogDialogue()
                return
            }
        }

        // FASE 4: Arthur memungut 5 barang secara otomatis jika berjalan tepat di atasnya (PERSIS KAYU Q7)
        if quest8.annethBackyardMet && !quest8.allItemsPacked {
            for item in quest8LoadoutItemPositions {
                if !isQuest8ItemPacked(id: item.id) {
                    if hypot(actor.position.x - item.position.x, actor.position.y - item.position.y) < 28 {
                        collectQuest8LoadoutItem(id: item.id, name: item.name, position: item.position)
                        break
                    }
                }
            }
            return
        }

        // FASE 5: Arthur kembali ke Rumah Kakek setelah barang terkemas
        if quest8.allItemsPacked && !quest8.returnedToGrandpa {
            let grandpa = quest8GrandpaPosition
            if hypot(actor.position.x - grandpa.x, actor.position.y - grandpa.y) < 42 {
                startQuest8ReturnToGrandpaDialogue()
            }
        }
    }

    // MARK: - Interaction Handler

    func handleQuest8Interaction(at point: CGPoint) -> Bool {
        guard questDialogue.isEmpty else { return false }
        guard !VillageQuest8Runtime.shared.isTransitioning else { return false }

        // FASE 1: Interaksi di Gudang Kosong (Secret Base)
        if !quest8.convincingFailed {
            let base = quest8WarehousePosition
            let hitBase = hypot(point.x - base.x, point.y - base.y) < 65 ||
                          hypot(actor.position.x - base.x, actor.position.y - base.y) < 75
            if hitBase {
                startQuest8SecretBaseDialogue()
                return true
            }
        }

        // FASE 2: Interaksi dengan Tetua Desa di kabut senja
        if quest8.convincingFailed && !quest8.experiencedFog {
            let elder = quest8ElderFogPosition
            let hitElder = hypot(point.x - elder.x, point.y - elder.y) < 45 ||
                           hypot(actor.position.x - elder.x, actor.position.y - elder.y) < 55
            if hitElder {
                startQuest8ElderFogDialogue()
                return true
            }
        }

        // FASE 3: Pertemuan Malam Hari di Belakang Rumah Anneth
        if quest8.experiencedFog && !quest8.annethBackyardMet {
            let yard = quest8AnnethBackyardPosition
            let hitYard = hypot(point.x - yard.x, point.y - yard.y) < 60 ||
                          hypot(actor.position.x - yard.x, actor.position.y - yard.y) < 70
            if hitYard {
                startQuest8AnnethBackyardDialogue()
                return true
            }
        }

        // FASE 4: Click to Pick Barang Ekspedisi di halaman (Generous 60 pt radius)
        if quest8.annethBackyardMet && !quest8.allItemsPacked {
            for item in quest8LoadoutItemPositions {
                if !isQuest8ItemPacked(id: item.id) {
                    let hitItem = hypot(point.x - item.position.x, point.y - item.position.y) < 60
                    if hitItem {
                        collectQuest8LoadoutItem(id: item.id, name: item.name, position: item.position)
                        return true
                    }
                }
            }
        }

        // FASE 5: Interaksi Kembali ke Rumah Kakek
        if quest8.allItemsPacked && !quest8.returnedToGrandpa {
            let grandpa = quest8GrandpaPosition
            let hitGrandpa = hypot(point.x - grandpa.x, point.y - grandpa.y) < 55 ||
                             hypot(actor.position.x - grandpa.x, actor.position.y - grandpa.y) < 65
            if hitGrandpa {
                startQuest8ReturnToGrandpaDialogue()
                return true
            }
        }

        return false
    }

    // MARK: - Phase 1: Dialogue & Scripted Failure System

    func startQuest8SecretBaseDialogue() {
        guard questDialogue.isEmpty else { return }
        route = []
        stick = .zero
        actor.zRotation = 0
        world.zRotation = 0

        quest8.secretBaseMetFriends = true
        saveQuest8()

        presentQuestDialogue([
            .init(speaker: "Narasi", text: "Arthur meletakkan Buku Elias di atas batu datar. Halaman terbuka menampilkan sketsa The Hollow yang mengerikan menelan manusia."),
            .init(speaker: "Keneth", text: "And you’re only telling us this now?!"),
            .init(speaker: "Arthur", text: "I was still trying to understand it myself."),
            .init(speaker: "Roland", text: "You said you’d tell me. You almost didn't make it home, Arthur. Were you actually planning to leave?"),
            .init(speaker: "Arthur", text: "I didn't plan it! I was just looking for leaves"),
            .init(speaker: "Roland", text: "Yeah. You didn't plan it. That's the problem."),
            .init(speaker: "Narasi", text: "Anneth membaca teks di buku itu dengan sangat hati-hati, lalu menutup halaman bergambar monster tersebut."),
            .init(speaker: "Anneth", text: "This might be important, Arthur. But it's not a map. There’s no route, no survival plan. It’s too dangerous to use as an excuse to just wander off.")
        ]) { [weak self] in
            self?.presentQuest8ConvincingChoice()
        }
    }

    private func presentQuest8ConvincingChoice() {
        VillageQuest8Runtime.shared.choiceCompletion = { [weak self] chosenIndex in
            self?.executeQuest8ScriptedFailure(chosenIndex: chosenIndex)
        }

        renderQuest8Choice(
            title: "Coba Yakinkan Teman-temanmu (Pilih Alasan):",
            optionA: "Kita kekurangan sumber daya! Garam, kayu, obat...",
            optionB: "Ada desa lain di luar sana! Elias menulis ini!",
            optionC: "Kita tidak bisa selamanya bersembunyi di lembah!"
        )
    }

    func renderQuest8Choice(title: String, optionA: String, optionB: String, optionC: String) {
        hud.childNode(withName: "quest8-choice-panel")?.removeFromParent()
        let width = min(size.width - 40, 620)
        let height: CGFloat = 168
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 14)
        panel.name = "quest8-choice-panel"
        panel.position = CGPoint(x: size.width / 2, y: 110)
        panel.fillColor = SKColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 0.98)
        panel.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 0.95)
        panel.lineWidth = 1.8
        panel.zPosition = 2700

        let titleLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLbl.text = title
        titleLbl.fontSize = 12
        titleLbl.fontColor = .systemYellow
        titleLbl.position = CGPoint(x: 0, y: height / 2 - 20)
        titleLbl.name = "quest8-choice-panel"
        panel.addChild(titleLbl)

        let btnW = width - 36
        let btnH: CGFloat = 34
        let options = [(optionA, "quest8-choice-0"), (optionB, "quest8-choice-1"), (optionC, "quest8-choice-2")]

        for (idx, item) in options.enumerated() {
            let cy = height / 2 - 48 - CGFloat(idx) * 38
            let btn = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: 8)
            btn.name = item.1
            btn.position = CGPoint(x: 0, y: cy)
            btn.fillColor = SKColor(red: 0.14, green: 0.19, blue: 0.25, alpha: 1)
            btn.strokeColor = SKColor(red: 0.85, green: 0.70, blue: 0.40, alpha: 0.6)
            btn.lineWidth = 1.0

            let lbl = SKLabelNode(fontNamed: "AvenirNext-Medium")
            lbl.text = item.0
            lbl.fontSize = 11
            lbl.fontColor = SKColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1)
            lbl.verticalAlignmentMode = .center
            lbl.name = item.1
            btn.addChild(lbl)

            panel.addChild(btn)
        }

        hud.addChild(panel)
    }

    func handleQuest8ChoiceTap(actions: Set<String>) -> Bool {
        guard let completion = VillageQuest8Runtime.shared.choiceCompletion else { return false }

        if actions.contains("quest8-choice-0") {
            hud.childNode(withName: "quest8-choice-panel")?.removeFromParent()
            VillageQuest8Runtime.shared.choiceCompletion = nil
            completion(0)
            return true
        }
        if actions.contains("quest8-choice-1") {
            hud.childNode(withName: "quest8-choice-panel")?.removeFromParent()
            VillageQuest8Runtime.shared.choiceCompletion = nil
            completion(1)
            return true
        }
        if actions.contains("quest8-choice-2") {
            hud.childNode(withName: "quest8-choice-panel")?.removeFromParent()
            VillageQuest8Runtime.shared.choiceCompletion = nil
            completion(2)
            return true
        }
        return false
    }

    private func executeQuest8ScriptedFailure(chosenIndex: Int) {
        HapticsService.shared.playSelection()

        let arthurLine: String
        switch chosenIndex {
        case 0:
            arthurLine = "We're losing resources! The rock salt, the dry wood, the herbs... If there's another place out there, if someone knows something—"
        case 1:
            arthurLine = "Elias wrote about another village! We aren't the only ones out there! If we go to the boundary—"
        default:
            arthurLine = "The barrier won't protect us forever! The valley is changing, we have to see for ourselves—"
        }

        presentQuestDialogue([
            .init(speaker: "Arthur", text: arthurLine),
            .init(speaker: "Keneth", text: "We have enough! We are still eating. That’s no reason to throw your neck to the monsters. Take it to the elders."),
            .init(speaker: "Roland", text: "He's right. You almost died, Arthur. We are not doing this."),
            .init(speaker: "Anneth", text: "I'm sorry, Arthur. It's too reckless. We cannot just abandon safety."),
            .init(speaker: "Narasi", text: "Semua temannya menolak. Roland mengantar Arthur sampai ke persimpangan desa tanpa sepatah kata pun bicara, lalu pulang ke rumahnya.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest8TravelFade { [weak self] in
                guard let self else { return }
                self.quest8.convincingAttempted = true
                self.quest8.convincingFailed = true
                self.saveQuest8()

                let elderPos = self.quest8ElderFogPosition
                self.setArthurSafePosition(CGPoint(x: elderPos.x - 35, y: elderPos.y))
                self.rebuild("Kabut tebal mendadak turun di jalan desa. Temui Tetua Desa.")
            }
        }
    }

    // MARK: - Phase 2: Atmospheric Event "The Old Fog"

    func startQuest8ElderFogDialogue() {
        guard questDialogue.isEmpty else { return }
        route = []
        stick = .zero
        actor.zRotation = 0
        world.zRotation = 0

        presentQuestDialogue([
            .init(speaker: "Tetua Desa", text: "Stay calm, everyone! It’s just the old season fog. The valley is changing, but the village protection holds. Finish your chores and close your doors."),
            .init(speaker: "Narasi", text: "Arthur menatap kabut tebal itu menyusup ke sela pagar dan jalanan. Suara derit pintu rumah yang ditutup rapat menggema di lorong desa."),
            .init(speaker: "Arthur", text: "Desa memang tidak diserang malam ini... tapi alam di luar sana jelas sedang berubah drastis."),
            .init(speaker: "Arthur", text: "Aku tidak boleh menyerah. Aku harus mengumpulkan Roland, Anneth, dan Keneth kembali malam ini di belakang rumah Anneth.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest8TravelFade { [weak self] in
                guard let self else { return }
                self.quest8.experiencedFog = true
                self.quest8.spokeToElderInFog = true
                self.saveQuest8()

                let yard = self.quest8AnnethBackyardPosition
                self.setArthurSafePosition(CGPoint(x: yard.x, y: yard.y - 30))
                self.rebuild("Malam tiba. Temui teman-teman di belakang rumah Anneth.")
            }
        }
    }

    // MARK: - Phase 3: Night Meeting at Anneth's Backyard

    func startQuest8AnnethBackyardDialogue() {
        guard questDialogue.isEmpty else { return }
        route = []
        stick = .zero
        actor.zRotation = 0
        world.zRotation = 0

        presentQuestDialogue([
            .init(speaker: "Arthur", text: "We don't go far. Just to the tree where I found the book. We check the dirt around the roots. If there's nothing else, we come back. Long before dark."),
            .init(speaker: "Keneth", text: "You still want to go."),
            .init(speaker: "Arthur", text: "I just want to know if any of this is real. Not to fight the monster. Keneth... if we want this village to survive, don't we need to know what's out there?"),
            .init(speaker: "Narasi", text: "Keneth terdiam lama sambil memutar benang di ujung bajunya."),
            .init(speaker: "Keneth", text: "My father didn't just move the sacks because the wall was damp. The floorboards are rotting. We keep delaying the repairs because there’s no good wood left... I'll go as far as the tree. That's it. I just want to come home to a house that's still standing."),
            .init(speaker: "Narasi", text: "Roland mengusap belakang lehernya sambil menghela napas kasar."),
            .init(speaker: "Roland", text: "I don't trust your plan, Arthur. But I trust you by yourself even less. If you don't come back, we're the ones who have to look for you."),
            .init(speaker: "Anneth", text: "Supplies for four. Water. Ropes. A small knife to cut branches, not to act brave. Ointment and clean cloth. We leave past the eastern hill gap, and if we hear anything strange, we don't separate. Understand?"),
            .init(speaker: "Arthur", text: "Understood."),
            .init(speaker: "Anneth", text: "Bantu aku mengumpulkan kelima barang wajib ini di sekitar halaman dan masukkan ke dalam tas ransel sekarang juga.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest8.annethBackyardMet = true
            self.saveQuest8()
            self.rebuild("Kumpulkan dan masukkan 5 barang wajib ke dalam tas ekspedisi (\(self.quest8.packedCount)/5).")
        }
    }

    // MARK: - Phase 4: Click to Pick Item Collection

    func collectQuest8LoadoutItem(id: String, name: String, position: CGPoint) {
        switch id {
        case "knife": quest8.packedKnife = true
        case "rope": quest8.packedRope = true
        case "water": quest8.packedWater = true
        case "ointment": quest8.packedOintment = true
        case "journal": quest8.packedJournal = true
        default: break
        }

        HapticsService.shared.playSelection()
        saveQuest8()

        // Pastikan Arthur dan layar selalu tegak lurus sempurna (tidak boleh miring)
        actor.zRotation = 0
        world.zRotation = 0

        // Arah hadap kiri/kanan seperti karakter lain di game (Carto style)
        let dx = position.x - actor.position.x
        if dx > 2 {
            actor.visualRoot.xScale = 1.0
        } else if dx < -2 {
            actor.visualRoot.xScale = -1.0
        }

        // Efek visual floating label (persis seperti ranting kayu di Quest 7)
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+1 \(name) (\(quest8.packedCount)/5)"
        label.fontSize = 13
        label.fontColor = .systemYellow
        label.position = CGPoint(x: position.x, y: position.y + 16)
        label.zPosition = 90
        world.addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 22, duration: 0.65),
                .fadeOut(withDuration: 0.65)
            ]),
            .removeFromParent()
        ]))

        if quest8.allItemsPacked {
            HapticsService.shared.playNotification(.success)
            hud.childNode(withName: "quest8-loadout-hud")?.removeFromParent()
            presentQuestDialogue([
                .init(speaker: "Anneth", text: "Semua perlengkapan untuk empat orang sudah lengkap di dalam tas. Besok pagi lewat celah bukit timur. Jangan berpisah!"),
                .init(speaker: "Arthur", text: "Terima kasih, Anneth. Sekarang aku akan membawa tas ini pulang ke Rumah Kakek untuk beristirahat malam ini.")
            ]) { [weak self] in
                self?.actor.zRotation = 0
                self?.world.zRotation = 0
                self?.rebuild("Semua perbekalan siap! Kembali ke Rumah Kakek untuk beristirahat sebelum fajar.")
            }
        } else {
            actor.zRotation = 0
            world.zRotation = 0
            rebuild("Kemas 5 barang ekspedisi ke dalam tas (\(quest8.packedCount)/5).")
        }
    }

    // MARK: - Phase 5: Return to Rumah Kakek & Conclude Quest 8

    func startQuest8ReturnToGrandpaDialogue() {
        guard questDialogue.isEmpty else { return }
        route = []
        stick = .zero
        actor.zRotation = 0
        world.zRotation = 0

        presentQuestDialogue([
            .init(speaker: "Arthur", text: "Aku sudah kembali ke rumah dan meletakkan tas ransel ekspedisi di samping pintu."),
            .init(speaker: "Arthur", text: "Kakek sudah tertidur pulas. Malam ini kabut di luar terasa sangat dingin dan menakutkan."),
            .init(speaker: "Arthur", text: "Maafkan aku, Kakek. Besok saat fajar menyingsing, kami harus mencari tahu apa yang sebenarnya terjadi di balik The Boundary.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest8.returnedToGrandpa = true
            self.quest8.completed = true

            let progress = PrologueStore.shared.progress
            progress.storyProgress = max(progress.storyProgress, 11)
            progress.boundaryMarked = true
            PrologueStore.shared.save()
            self.saveQuest8()

            self.quest8TravelFade { [weak self] in
                guard let self else { return }
                self.showQuest8UnlockCard(
                    title: "🎒 PERSIAPAN EKSPEDISI LENGKAP!",
                    body: "Quest 8 selesai. Dinamika rombongan telah terkunci karena rasa saling menjaga dan keterdesakan sumber daya. Besok fajar, Arthur, Roland, Anneth, dan Keneth berangkat menuju The Boundary!"
                )
                self.rebuild("Quest 8 selesai: Rombongan Arthur siap menjelajah keluar desa esok fajar.")
            }
        }
    }

    func showQuest8UnlockCard(title: String, body: String) {
        hud.childNode(withName: "quest8UnlockCard")?.removeFromParent()

        let card = SKNode()
        card.name = "quest8UnlockCard"
        card.zPosition = 600
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)

        let cardWidth = min(size.width - 50, 480)
        let cardHeight: CGFloat = 195

        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor(white: 0, alpha: 0.58)
        dim.strokeColor = .clear
        dim.name = "quest8UnlockCard"
        card.addChild(dim)

        let bg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        bg.fillColor = SKColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.98)
        bg.strokeColor = SKColor(red: 0.96, green: 0.84, blue: 0.45, alpha: 1.0)
        bg.lineWidth = 2.2
        bg.name = "quest8UnlockCard"
        card.addChild(bg)

        let inner = SKShapeNode(rectOf: CGSize(width: cardWidth - 14, height: cardHeight - 14), cornerRadius: 14)
        inner.fillColor = .clear
        inner.strokeColor = SKColor(red: 0.72, green: 0.60, blue: 0.35, alpha: 0.45)
        inner.lineWidth = 1.0
        inner.name = "quest8UnlockCard"
        card.addChild(inner)

        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 15
        titleLabel.fontColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: cardHeight / 2 - 38)
        titleLabel.name = "quest8UnlockCard"
        card.addChild(titleLabel)

        let bodyLabel = SKLabelNode(text: body)
        bodyLabel.fontName = "AvenirNext-Medium"
        bodyLabel.fontSize = 11
        bodyLabel.fontColor = SKColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 0.95)
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = cardWidth - 48
        bodyLabel.position = CGPoint(x: 0, y: cardHeight / 2 - 95)
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.name = "quest8UnlockCard"
        card.addChild(bodyLabel)

        let btn = SKShapeNode(rectOf: CGSize(width: 140, height: 32), cornerRadius: 8)
        btn.fillColor = SKColor(red: 0.18, green: 0.28, blue: 0.22, alpha: 1)
        btn.strokeColor = SKColor(red: 0.45, green: 0.85, blue: 0.55, alpha: 0.9)
        btn.lineWidth = 1.2
        btn.position = CGPoint(x: 0, y: -cardHeight / 2 + 30)
        btn.name = "quest8UnlockCard"
        card.addChild(btn)

        let btnLbl = SKLabelNode(text: "Lanjutkan")
        btnLbl.fontName = "AvenirNext-Bold"
        btnLbl.fontSize = 11.5
        btnLbl.fontColor = SKColor(red: 0.85, green: 0.98, blue: 0.88, alpha: 1)
        btnLbl.verticalAlignmentMode = .center
        btnLbl.name = "quest8UnlockCard"
        btn.addChild(btnLbl)

        hud.addChild(card)
    }

    // MARK: - Scene Transition Fade

    private func quest8TravelFade(completion: @escaping () -> Void) {
        VillageQuest8Runtime.shared.isTransitioning = true
        let cover = SKSpriteNode(color: .black, size: size)
        cover.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cover.alpha = 0
        cover.zPosition = 3500
        hud.addChild(cover)

        cover.run(.sequence([
            .fadeIn(withDuration: 0.4),
            .wait(forDuration: 0.45),
            .fadeOut(withDuration: 0.4),
            .removeFromParent(),
            .run {
                VillageQuest8Runtime.shared.isTransitioning = false
                completion()
            }
        ]))
    }
}
