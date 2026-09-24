// Quest 7: Arthur mencari kayu di lereng hutan dan menemukan Buku Catatan Elias.
import SpriteKit
import SwiftUI
import UIKit

final class VillageQuest7Runtime {
    static let shared = VillageQuest7Runtime()

    var progress = VillageQuest7Progress.load()
    var isPresentingDiscovery = false
    var isConfrontingGrandpa = false
}

extension VillageCartoScene {
    var quest7: VillageQuest7Progress {
        get { VillageQuest7Runtime.shared.progress }
        set { VillageQuest7Runtime.shared.progress = newValue }
    }

    var quest7Objective: String {
        VillageQuestEngine.quest7Objective(for: villageQuestSnapshot)
    }

    func saveQuest7() {
        quest7.save()
    }

    func resetQuest7RuntimeFlags() {
        VillageQuest7Runtime.shared.isConfrontingGrandpa = false
        VillageQuest7Runtime.shared.isPresentingDiscovery = false
    }

    var quest7GrandpaPosition: CGPoint {
        if let house = questPosition(for: "arthur-house") {
            return CGPoint(x: house.x + 28, y: house.y - 12)
        }
        let source = CGPoint(
            x: VillageCartoMap.spawn.x + 0.35 * VillageCartoMap.side,
            y: VillageCartoMap.spawn.y - 0.25 * VillageCartoMap.side
        )
        return layout.world(source) ?? CGPoint(x: actor.position.x - 30, y: actor.position.y - 20)
    }

    var quest7ForestPiecePlacement: VillageTileLayout.Placement? {
        layout.placements.first { $0.id == VillageQuestCatalog.PieceID.hollowForestReward }
    }

    var quest7ForestCells: [CGPoint] {
        guard let placement = quest7ForestPiecePlacement else { return [] }
        let cells = VillageTileLayout.cells(of: placement).map(\.center)
        return cells.sorted { ($0.x + $0.y) < ($1.x + $1.y) }
    }

    var quest7ForestPiecePosition: CGPoint? {
        let cells = quest7ForestCells
        guard !cells.isEmpty else { return quest7ForestPiecePlacement?.center }
        let avgX = cells.map(\.x).reduce(0, +) / CGFloat(cells.count)
        let avgY = cells.map(\.y).reduce(0, +) / CGFloat(cells.count)
        return CGPoint(x: avgX, y: avgY)
    }

    var quest7LandslidePosition: CGPoint? {
        let cells = quest7ForestCells
        if let last = cells.last {
            return CGPoint(x: last.x + 6, y: last.y + 6)
        }
        guard let forest = quest7ForestPiecePosition else { return nil }
        return CGPoint(x: forest.x + 28, y: forest.y + 24)
    }

    var quest7WoodStickPositions: [CGPoint] {
        let cells = quest7ForestCells
        if cells.count >= 4 {
            return [
                CGPoint(x: cells[0].x - 14, y: cells[0].y + 8),
                CGPoint(x: cells[0].x + 12, y: cells[0].y - 10),
                CGPoint(x: cells[1].x - 8, y: cells[1].y - 6),
                CGPoint(x: cells[1].x + 14, y: cells[1].y + 10),
                CGPoint(x: cells[2].x, y: cells[2].y)
            ]
        }
        guard let forest = quest7ForestPiecePosition else { return [] }
        return [
            CGPoint(x: forest.x - 36, y: forest.y - 24),
            CGPoint(x: forest.x - 14, y: forest.y - 12),
            CGPoint(x: forest.x + 8, y: forest.y - 32),
            CGPoint(x: forest.x - 22, y: forest.y + 16),
            CGPoint(x: forest.x + 16, y: forest.y + 8)
        ]
    }

    func renderQuest7World() {
        guard !quest7.completed else { return }

        // 1. Render Kakek di Rumah Arthur
        let grandpa = quest7GrandpaPosition
        questNPC(at: grandpa, name: "Kakek", color: .systemTeal)

        if !quest7.spokeToGrandpa {
            questMarker(at: CGPoint(x: grandpa.x, y: grandpa.y + 25), name: "quest7-grandpa", color: .systemYellow, symbol: "!")
            renderQuest7SpeechBadge(at: CGPoint(x: grandpa.x, y: grandpa.y + 38), text: "Bicara dengan Kakek", color: .systemYellow)
        }

        // 2. Render area lereng hutan, kayu bakar, dan tanah longsor di keping Piece I Hutan
        if let forest = quest7ForestPiecePosition {
            renderQuest7ForestSlope(at: forest)

            // Render Tanah Longsor (Landslide)
            if let landslide = quest7LandslidePosition {
                renderQuest7Landslide(at: landslide)

                if quest7.hasGatheredWood && !quest7.foundEliasBook {
                    questMarker(at: CGPoint(x: landslide.x, y: landslide.y + 30), name: "quest7-landslide", color: .systemOrange, symbol: "!")
                    renderQuest7SpeechBadge(at: CGPoint(x: landslide.x, y: landslide.y + 44), text: "[Inspect: Periksa Longsor]", color: .systemOrange)
                }
            }

            // Render 5 Kayu Bakar jika sudah bicara dengan Kakek dan belum selesai kumpul
            if quest7.spokeToGrandpa && !quest7.hasGatheredWood {
                let sticks = quest7WoodStickPositions
                for (index, stickPos) in sticks.enumerated() {
                    if index >= quest7.woodCollectedCount {
                        renderQuest7WoodStick(at: stickPos, index: index)
                    }
                }
            }
        }

        // 3. Render penanda Kakek setelah Arthur menemukan buku (Arthur harus jalan kembali ke Kakek)
        if quest7.foundEliasBook && !quest7.confrontedGrandpa {
            questMarker(at: CGPoint(x: grandpa.x, y: grandpa.y + 25), name: "quest7-grandpa-confront", color: .systemRed, symbol: "!")
            renderQuest7SpeechBadge(at: CGPoint(x: grandpa.x, y: grandpa.y + 38), text: "Tunjukkan Buku ke Kakek", color: .systemRed)
        }
    }

    private func renderQuest7SpeechBadge(at position: CGPoint, text: String, color: SKColor) {
        let badge = SKNode()
        badge.position = position
        badge.zPosition = 85
        badge.name = "quest7-badge"

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

    func renderQuest7ForestSlope(at position: CGPoint) {
        let slope = SKNode()
        slope.position = position
        slope.zPosition = 53

        // Tanah lereng gelap khas bioma hutan
        let ground = SKShapeNode(ellipseOf: CGSize(width: 140, height: 80))
        ground.fillColor = SKColor(red: 0.10, green: 0.20, blue: 0.12, alpha: 0.55)
        ground.strokeColor = .clear
        slope.addChild(ground)

        // Tunggul bekas tebangan kayu pinus warga
        for x in [-42.0, 36.0] {
            let stump = SKShapeNode(rectOf: CGSize(width: 15, height: 11), cornerRadius: 2)
            stump.position = CGPoint(x: x, y: -16)
            stump.fillColor = SKColor(red: 0.40, green: 0.26, blue: 0.15, alpha: 1)
            stump.strokeColor = SKColor(red: 0.24, green: 0.15, blue: 0.08, alpha: 1)
            stump.lineWidth = 1.2
            slope.addChild(stump)
        }

        // Bekas roda gerobak kayu di jalur aman setapak
        let trackPath = CGMutablePath()
        trackPath.move(to: CGPoint(x: -48, y: -26))
        trackPath.addQuadCurve(to: CGPoint(x: 44, y: -20), control: CGPoint(x: 0, y: -30))
        let track = SKShapeNode(path: trackPath)
        track.strokeColor = SKColor(red: 0.20, green: 0.14, blue: 0.08, alpha: 0.6)
        track.lineWidth = 3
        slope.addChild(track)

        world.addChild(slope)
    }

    func renderQuest7Landslide(at position: CGPoint) {
        let mound = SKNode()
        mound.position = position
        mound.zPosition = 55
        mound.name = "quest7-landslide-node"

        // Gundukan tanah longsor basah kecokelatan
        let soil = SKShapeNode(ellipseOf: CGSize(width: 66, height: 38))
        soil.fillColor = SKColor(red: 0.28, green: 0.18, blue: 0.10, alpha: 0.95)
        soil.strokeColor = SKColor(red: 0.18, green: 0.11, blue: 0.06, alpha: 1)
        soil.lineWidth = 1.5
        mound.addChild(soil)

        // Batu-batu kecil runtuhan tebing
        for p in [CGPoint(x: -16, y: -8), CGPoint(x: 20, y: 6), CGPoint(x: 10, y: -12)] {
            let rock = SKShapeNode(circleOfRadius: 4)
            rock.position = p
            rock.fillColor = SKColor(white: 0.35, alpha: 0.9)
            rock.strokeColor = .clear
            mound.addChild(rock)
        }

        // Akar raksasa pohon tua purba yang terekspos akibat longsor
        let rootPath = CGMutablePath()
        rootPath.move(to: CGPoint(x: -28, y: 18))
        rootPath.addCurve(to: CGPoint(x: 20, y: -14), control1: CGPoint(x: -12, y: 6), control2: CGPoint(x: 6, y: 14))
        rootPath.addQuadCurve(to: CGPoint(x: 30, y: -20), control: CGPoint(x: 26, y: -16))

        let roots = SKShapeNode(path: rootPath)
        roots.strokeColor = SKColor(red: 0.44, green: 0.28, blue: 0.16, alpha: 1)
        roots.lineWidth = 4.5
        mound.addChild(roots)

        // Buku terbungkus kain rapuh di sela akar jika belum diambil
        if !quest7.foundEliasBook {
            let bookBundle = SKShapeNode(rectOf: CGSize(width: 16, height: 12), cornerRadius: 2.5)
            bookBundle.position = CGPoint(x: 2, y: 0)
            bookBundle.fillColor = SKColor(red: 0.58, green: 0.45, blue: 0.30, alpha: 1)
            bookBundle.strokeColor = SKColor(red: 0.85, green: 0.70, blue: 0.42, alpha: 0.95)
            bookBundle.lineWidth = 1.2
            mound.addChild(bookBundle)

            // Pendar lembut menunjukkan benda tersembunyi
            let glow = SKShapeNode(circleOfRadius: 12)
            glow.fillColor = SKColor.systemOrange.withAlphaComponent(0.25)
            glow.strokeColor = .clear
            glow.run(.repeatForever(.sequence([
                .scale(to: 1.25, duration: 0.8),
                .scale(to: 0.9, duration: 0.8)
            ])))
            mound.addChild(glow)
        }

        world.addChild(mound)
    }

    func renderQuest7WoodStick(at position: CGPoint, index: Int) {
        let node = SKNode()
        node.position = position
        node.name = "quest7-stick-\(index)"
        node.zPosition = 56

        // Aura pendar penanda kayu interaktif
        let aura = SKShapeNode(circleOfRadius: 15)
        aura.fillColor = SKColor.systemOrange.withAlphaComponent(0.30)
        aura.strokeColor = SKColor.systemYellow.withAlphaComponent(0.6)
        aura.lineWidth = 1.0
        aura.run(.repeatForever(.sequence([
            .scale(to: 1.2, duration: 0.65),
            .scale(to: 0.9, duration: 0.65)
        ])))
        node.addChild(aura)

        // Dua ranting kayu pinus bersilangan
        let stick1 = SKShapeNode(rectOf: CGSize(width: 16, height: 3.5), cornerRadius: 1.5)
        stick1.fillColor = SKColor(red: 0.54, green: 0.38, blue: 0.22, alpha: 1)
        stick1.strokeColor = SKColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1)
        stick1.lineWidth = 0.8
        stick1.zRotation = 0.38
        node.addChild(stick1)

        let stick2 = SKShapeNode(rectOf: CGSize(width: 14, height: 3), cornerRadius: 1.2)
        stick2.fillColor = SKColor(red: 0.44, green: 0.30, blue: 0.16, alpha: 1)
        stick2.strokeColor = SKColor(red: 0.25, green: 0.14, blue: 0.08, alpha: 1)
        stick2.lineWidth = 0.8
        stick2.zRotation = -0.55
        node.addChild(stick2)

        // Label kecil penanda ranting kayu
        let badge = SKLabelNode(fontNamed: "AvenirNext-Bold")
        badge.text = "🪵 Kayu"
        badge.fontSize = 8.5
        badge.fontColor = .systemYellow
        badge.position = CGPoint(x: 0, y: 13)
        node.addChild(badge)

        world.addChild(node)
    }

    func checkQuest7Proximity() {
        guard !quest7.completed else { return }
        guard questDialogue.isEmpty else { return }
        guard !VillageQuest7Runtime.shared.isConfrontingGrandpa else { return }

        // 1. Arthur memungut kayu secara otomatis jika berjalan tepat di atasnya
        if quest7.spokeToGrandpa && !quest7.hasGatheredWood {
            let sticks = quest7WoodStickPositions
            for (index, stickPos) in sticks.enumerated() {
                if index >= quest7.woodCollectedCount {
                    if hypot(actor.position.x - stickPos.x, actor.position.y - stickPos.y) < 28 {
                        collectQuest7WoodStick(at: stickPos, index: index)
                        break
                    }
                }
            }
        }

        // 2. Arthur kembali ke Kakek: jika sudah mendekat, Kakek siap diajak bicara
        if quest7.foundEliasBook && !quest7.confrontedGrandpa && !VillageQuest7Runtime.shared.isConfrontingGrandpa {
            let grandpa = quest7GrandpaPosition
            if hypot(actor.position.x - grandpa.x, actor.position.y - grandpa.y) < 42 {
                startQuest7GrandpaConfrontationDialogue()
            }
        }
    }

    func handleQuest7Interaction(at point: CGPoint) -> Bool {
        guard questDialogue.isEmpty else { return false }
        let grandpa = quest7GrandpaPosition

        // 1. Arthur bicara awal dengan Kakek (Mengambil misi mencari kayu)
        if !quest7.spokeToGrandpa {
            let hitGrandpa = hypot(point.x - grandpa.x, point.y - grandpa.y) < 48 ||
                             hypot(actor.position.x - grandpa.x, actor.position.y - grandpa.y) < 55
            if hitGrandpa {
                startQuest7GrandpaOpeningDialogue()
                return true
            }
        }

        // 2. Arthur memungut 5 ranting kayu bakar di lereng hutan
        if quest7.spokeToGrandpa && !quest7.hasGatheredWood {
            let sticks = quest7WoodStickPositions
            for (index, stickPos) in sticks.enumerated() {
                if index >= quest7.woodCollectedCount {
                    let hitStick = hypot(point.x - stickPos.x, point.y - stickPos.y) < 42 ||
                                   hypot(actor.position.x - stickPos.x, actor.position.y - stickPos.y) < 50
                    if hitStick {
                        collectQuest7WoodStick(at: stickPos, index: index)
                        return true
                    }
                }
            }
        }

        // 3. Arthur memeriksa tanah longsor & akar pohon tua (Menemukan Buku Elias)
        if let landslide = quest7LandslidePosition {
            let hitLandslide = hypot(point.x - landslide.x, point.y - landslide.y) < 58 ||
                               hypot(actor.position.x - landslide.x, actor.position.y - landslide.y) < 68
            if hitLandslide {
                if !quest7.hasGatheredWood {
                    presentQuestDialogue([
                        .init(speaker: "Arthur", text: "Aku harus mengumpulkan 5 ranting kayu bakar terlebih dahulu sebelum memeriksa longsoran ini.")
                    ])
                    return true
                } else if !quest7.foundEliasBook {
                    startQuest7EliasBookDiscovery()
                    return true
                }
            }
        }

        // 4. Arthur kembali ke rumah & konfrontasi dramatis dengan Kakek
        if quest7.foundEliasBook && !quest7.confrontedGrandpa && !VillageQuest7Runtime.shared.isConfrontingGrandpa {
            let hitGrandpa = hypot(point.x - grandpa.x, point.y - grandpa.y) < 50 ||
                             hypot(actor.position.x - grandpa.x, actor.position.y - grandpa.y) < 60
            if hitGrandpa {
                startQuest7GrandpaConfrontationDialogue()
                return true
            }
        }

        return false
    }

    func startQuest7GrandpaOpeningDialogue() {
        guard questDialogue.isEmpty else { return }
        route = []
        stick = .zero
        presentQuestDialogue([
            .init(speaker: "Kakek", text: "We're low on wood. Gather some at the bottom of the slope."),
            .init(speaker: "Arthur", text: "Baik, Kakek. Aku akan pergi mencari ranting kayu ke lereng hutan.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest7.spokeToGrandpa = true
            self.saveQuest7()
            self.rebuild("Kumpulkan 5 ranting kayu bakar di lereng hutan.")
        }
    }

    func collectQuest7WoodStick(at position: CGPoint, index: Int) {
        quest7.woodCollectedCount += 1
        HapticsService.shared.playSelection()

        // Efek visual teks mengapung
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+1 Ranting Kayu (\(quest7.woodCollectedCount)/5)"
        label.fontSize = 13
        label.fontColor = .systemYellow
        label.position = CGPoint(x: position.x, y: position.y + 15)
        label.zPosition = 90
        world.addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 22, duration: 0.65),
                .fadeOut(withDuration: 0.65)
            ]),
            .removeFromParent()
        ]))

        if quest7.woodCollectedCount >= 5 {
            quest7.hasGatheredWood = true
            let progress = PrologueStore.shared.progress
            progress.gatheredWood = true
            PrologueStore.shared.save()
            saveQuest7()
            startQuest7WoodCompleteDialogue()
        } else {
            saveQuest7()
            rebuild("Kumpulkan 5 ranting kayu bakar (\(quest7.woodCollectedCount)/5).")
        }
    }

    func startQuest7WoodCompleteDialogue() {
        HapticsService.shared.playNotification(.success)
        presentQuestDialogue([
            .init(speaker: "Arthur", text: "Tumpukan kayu pinus ini sudah cukup untuk dibawa pulang."),
            .init(speaker: "Arthur", text: "Tapi tunggu... ada bekas tanah longsor baru di dekat akar pohon tua itu!"),
            .init(speaker: "Arthur", text: "Akar pohon raksasa itu mencengkeram tebing yang runtuh. Tampak ada sesuatu yang terselip di sana! Mari kita periksa.")
        ]) { [weak self] in
            self?.rebuild("Periksa tanah longsor dan akar pohon tua di lereng hutan.")
        }
    }

    func startQuest7EliasBookDiscovery() {
        guard !VillageQuest7Runtime.shared.isPresentingDiscovery,
              let rootVC = view?.window?.rootViewController else {
            finishQuest7EliasBookDiscovery()
            return
        }

        VillageQuest7Runtime.shared.isPresentingDiscovery = true
        var hostingController: UIHostingController<EliasJournalDiscoveryView>?
        let discoveryView = EliasJournalDiscoveryView(
            onComplete: { [weak self] in
                hostingController?.dismiss(animated: true) {
                    VillageQuest7Runtime.shared.isPresentingDiscovery = false
                    self?.finishQuest7EliasBookDiscovery()
                }
            },
            onDismiss: {
                hostingController?.dismiss(animated: true) {
                    VillageQuest7Runtime.shared.isPresentingDiscovery = false
                }
            },
            onOpenBook: { [weak self] in
                hostingController?.dismiss(animated: true) {
                    VillageQuest7Runtime.shared.isPresentingDiscovery = false
                    self?.finishQuest7EliasBookDiscovery()
                }
            }
        )

        let controller = UIHostingController(rootView: discoveryView)
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        hostingController = controller
        rootVC.present(controller, animated: true)
    }

    func finishQuest7EliasBookDiscovery() {
        HapticsService.shared.playNotification(.success)
        quest7.inspectedLandslide = true
        quest7.foundEliasBook = true

        let progress = PrologueStore.shared.progress
        progress.hasEliasBook = true
        progress.hasBook = true
        progress.foundMarker = true
        PrologueStore.shared.save()
        saveQuest7()

        presentQuestDialogue([
            .init(speaker: "Arthur", text: "It's the exact same shape. The one from yesterday..."),
            .init(speaker: "UI Buku", text: "I found this book in the ruins of the old watchtower, north of the village. - Elias."),
            .init(speaker: "Arthur", text: "Elias? Watchtower? 'North of the village'...? There is no watchtower in our valley. He's talking about... another village. We are not the only ones."),
            .init(speaker: "Arthur", text: "Aku harus segera membawa buku ini pulang dan menunjukkannya kepada Kakek!")
        ]) { [weak self] in
            // Player tetap berada di lereng hutan, dan harus berjalan pulang ke rumah Kakek
            self?.rebuild("Kembali ke Rumah Arthur dan tanyakan isi buku kepada Kakek.")
        }
    }

    func startQuest7GrandpaConfrontationDialogue() {
        guard !VillageQuest7Runtime.shared.isConfrontingGrandpa else { return }
        guard !quest7.confrontedGrandpa else { return }
        guard questDialogue.isEmpty else { return }

        VillageQuest7Runtime.shared.isConfrontingGrandpa = true
        route = []
        stick = .zero

        presentQuestDialogue([
            .init(speaker: "Arthur", text: "Can you read this?"),
            .init(speaker: "Kakek", text: "..."),
            .init(speaker: "Arthur", text: "I can read the middle part. Someone named Elias wrote it. He said he found it near his village"),
            .init(speaker: "Kakek", text: "Where exactly did you find this?"),
            .init(speaker: "Arthur", text: "At the slope. Under an old tree root. Grandfather... if the writings are true"),
            .init(speaker: "Kakek", text: "Things like this make people look for things that should stay lost, Arthur."),
            .init(speaker: "Arthur", text: "But if they didn't make it up, is there another village out there?"),
            .init(speaker: "Kakek", text: "This... this is all that's left of the people who never came home. Let the elders keep it. They'll know what to do with it."),
            .init(speaker: "Arthur", text: "Are there other people out there?! Elias wrote about his village!"),
            .init(speaker: "Kakek", text: "Knowing something doesn't always make you safer. Give me the book."),
            .init(speaker: "Arthur", text: "I'll bring it back later. I just want to read it for a bit."),
            .init(speaker: "Arthur", text: "I think I have to tell this to all of my friends, maybe they feel the same thing.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest7TravelFade { [weak self] in
                guard let self else { return }
                self.quest7.confrontedGrandpa = true
                self.quest7.completed = true
                VillageQuest7Runtime.shared.isConfrontingGrandpa = false

                let progress = PrologueStore.shared.progress
                progress.storyProgress = max(progress.storyProgress, 10)
                PrologueStore.shared.save()
                self.saveQuest7()
                self.rebuild("Quest 7 selesai. Gudang Kosong (Markas Rahasia) telah terbuka.")
            }
        }
    }

    private func quest7TravelFade(completion: @escaping () -> Void) {
        let cover = SKSpriteNode(color: .black, size: size)
        cover.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cover.alpha = 0
        cover.zPosition = 3500
        hud.addChild(cover)

        cover.run(.sequence([
            .fadeIn(withDuration: 0.4),
            .wait(forDuration: 0.35),
            .fadeOut(withDuration: 0.4),
            .removeFromParent(),
            .run(completion)
        ]))
    }
}
