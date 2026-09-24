// Quest 6 tetap berlangsung di layer dunia Desa Arthur yang dibentuk dari kepingan pemain.
// Minigame Flower Field serta QTE Hollow lama dipakai kembali tanpa membuka dunia baru.
import SpriteKit
import SwiftUI
import UIKit

private final class VillageQuest6Runtime {
    static let shared = VillageQuest6Runtime()
    static let startedKey = "village.carto.quest6.started.v1"

    var isPresentingForaging = false
    weak var activeQTE: SKNode?

    var started: Bool {
        get { UserDefaults.standard.bool(forKey: Self.startedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.startedKey) }
    }
}

extension VillageCartoScene {
    private var quest6Progress: PrologueProgress { PrologueStore.shared.progress }

    private var quest6HasStarted: Bool {
        VillageQuest6Runtime.shared.started || quest6Progress.hasHerbal ||
        quest6Progress.encounteredHollow || quest6Progress.metBerynAfterHerbal
    }

    private var quest6BerynHousePosition: CGPoint? {
        questPosition(for: VillageQuestCatalog.BuildingID.berynHouse)
    }

    private var quest6BerynPosition: CGPoint? {
        quest6BerynHousePosition.map { CGPoint(x: $0.x + 20, y: $0.y - 18) }
    }

    private var quest6ChildPosition: CGPoint? {
        quest6BerynHousePosition.map { CGPoint(x: $0.x - 23, y: $0.y - 20) }
    }

    /// Mengikuti kepingan dan rotasi pemain. Kandidat hanya berasal dari
    /// subgrid biome hijau yang benar-benar dapat dicapai Arthur.
    private var quest6HerbalPosition: CGPoint? {
        let origin = quest6BerynHousePosition ?? actor.position
        var candidates: [CGPoint] = []

        for placement in layout.placements {
            for cell in VillageCartoMap.pieces[placement.id] {
                for row in 0..<VillageCartoMap.subdivisions {
                    for column in 0..<VillageCartoMap.subdivisions {
                        let subcell = VillageCartoMap.Cell(
                            x: cell.x * VillageCartoMap.subdivisions + column,
                            y: cell.y * VillageCartoMap.subdivisions + row
                        )
                        let biome = VillageCartoMap.biomeForSubcell(subcell)
                        guard biome == .darkGreenForest else { continue }

                        let source = CGPoint(
                            x: (CGFloat(subcell.x) + 0.5) * VillageCartoMap.subcellSide,
                            y: (CGFloat(subcell.y) + 0.5) * VillageCartoMap.subcellSide
                        )
                        guard let worldPoint = layout.world(source), layout.walkable(worldPoint) else { continue }
                        candidates.append(worldPoint)
                    }
                }
            }
        }

        return candidates.max {
            hypot($0.x - origin.x, $0.y - origin.y) < hypot($1.x - origin.x, $1.y - origin.y)
        }
    }

    var quest6VillageObjective: String {
        guard layout.buildingPlacements.contains(where: {
            $0.id == VillageQuestCatalog.BuildingID.berynHouse
        }) else {
            return "Tempatkan Rumah Kakek Beryn (9x9), lalu Jelajahi."
        }

        if quest6Progress.metBerynAfterHerbal {
            return "Quest 6 selesai: laporan tentang Hollow telah disampaikan kepada Kakek Beryn."
        }
        if quest6Progress.hasHerbal && quest6Progress.encounteredHollow {
            return "Kembali ke Rumah Kakek Beryn dan ceritakan penampakan Hollow."
        }
        if quest6Progress.hasHerbal { return "Lolos dari The Hollow." }
        if quest6HasStarted {
            return quest6HerbalPosition == nil
                ? "Hubungkan kepingan yang memiliki biome hijau tua untuk mencari Silverleaf."
                : "Cari Silverleaf pada area hijau tua di kepingan desa."
        }
        return "Temui Anak Kecil dan Kakek Beryn di depan rumah untuk memulai pencarian Silverleaf."
    }

    func renderQuest6VillageWorld() {
        guard quest5.completed, !quest6Progress.metBerynAfterHerbal else { return }

        if let beryn = quest6BerynPosition, let child = quest6ChildPosition {
            questNPC(at: beryn, name: "Kakek Beryn", color: .systemGray)
            questNPC(at: child, name: "Anak Kecil", color: .systemGreen)
            if !quest6HasStarted || (quest6Progress.hasHerbal && quest6Progress.encounteredHollow) {
                questMarker(at: CGPoint(x: child.x, y: child.y + 27),
                            name: "quest6-beryn-house", color: .systemYellow, symbol: "!")
            }
        }

        if quest6HasStarted, !quest6Progress.hasHerbal, let herb = quest6HerbalPosition {
            renderQuest6HerbalPatch(at: herb)
            questMarker(at: CGPoint(x: herb.x, y: herb.y + 24),
                        name: "quest6-herbal", color: .systemGreen, symbol: "!")
        }
    }

    private func renderQuest6HerbalPatch(at position: CGPoint) {
        let patch = SKNode()
        patch.position = position
        patch.zPosition = 61
        for index in 0..<7 {
            let angle = CGFloat(index) * (.pi * 2 / 7)
            let leaf = SKShapeNode(ellipseOf: CGSize(width: 7, height: 17))
            leaf.position = CGPoint(x: cos(angle) * 8, y: sin(angle) * 5)
            leaf.zRotation = angle - .pi / 2
            leaf.fillColor = SKColor(red: 0.66, green: 0.79, blue: 0.64, alpha: 1)
            leaf.strokeColor = SKColor(red: 0.83, green: 0.88, blue: 0.79, alpha: 1)
            leaf.lineWidth = 1
            patch.addChild(leaf)
        }
        let glow = SKShapeNode(circleOfRadius: 16)
        glow.fillColor = SKColor.systemGreen.withAlphaComponent(0.12)
        glow.strokeColor = SKColor.systemGreen.withAlphaComponent(0.55)
        glow.lineWidth = 1.5
        glow.zPosition = -1
        patch.addChild(glow)
        world.addChild(patch)
    }

    func handleQuest6VillageInteraction(at point: CGPoint) -> Bool {
        guard quest5.completed, !quest6Progress.metBerynAfterHerbal else { return false }

        if let child = quest6ChildPosition,
           let beryn = quest6BerynPosition,
           (!quest6HasStarted || (quest6Progress.hasHerbal && quest6Progress.encounteredHollow)) {
            let touchesChild = hypot(point.x - child.x, point.y - child.y) <= 52
            let touchesBeryn = hypot(point.x - beryn.x, point.y - beryn.y) <= 52
            if touchesChild || touchesBeryn {
                let target = touchesChild ? child : beryn
                approachOrInteract(target, message: "Dekati Rumah Kakek Beryn.") { [weak self] in
                    guard let self else { return }
                    if self.quest6Progress.hasHerbal && self.quest6Progress.encounteredHollow {
                        self.finishQuest6AtBerynHouse()
                    } else {
                        self.startQuest6FromBerynHouse()
                    }
                }
                return true
            }
        }

        if quest6HasStarted, !quest6Progress.hasHerbal,
           let herb = quest6HerbalPosition,
           hypot(point.x - herb.x, point.y - herb.y) <= 52 {
            approachOrInteract(herb, message: "Dekati tanaman Silverleaf.") { [weak self] in
                self?.presentQuest6ForagingMinigame()
            }
            return true
        }
        return false
    }

    private func startQuest6FromBerynHouse() {
        guard !quest6Progress.metBerynAfterHerbal else { return }
        presentQuestDialogue([
            .init(speaker: "Anak Kecil", text: "Grandpa's knees are getting worse. Please find the silver leaves for his ointment."),
            .init(speaker: "Kakek Beryn", text: "They grow beyond the gardens, near the boundary stones. Do not wander farther than you must."),
            .init(speaker: "Arthur", text: "I'll bring them back before dark.")
        ]) { [weak self] in
            guard let self else { return }
            VillageQuest6Runtime.shared.started = true
            self.quest6Progress.deliveredRockSalt = true
            self.quest6Progress.isHerbalUnlocked = true
            self.quest6Progress.mapBStage = .herbalHills
            self.quest6Progress.storyProgress = max(self.quest6Progress.storyProgress, 6)
            PrologueStore.shared.save()
            self.rebuild("Quest 6 dimulai. Cari Silverleaf pada area hijau tua di susunan kepinganmu.")
        }
    }

    private func presentQuest6ForagingMinigame() {
        guard !quest6Progress.hasHerbal,
              !VillageQuest6Runtime.shared.isPresentingForaging,
              VillageQuest6Runtime.shared.activeQTE == nil,
              let rootViewController = view?.window?.rootViewController else { return }
        route = []
        stick = .zero
        VillageQuest6Runtime.shared.isPresentingForaging = true

        var hostingController: UIHostingController<FlowerFieldForagingView>?
        let minigame = FlowerFieldForagingView(
            onComplete: { [weak self] in
                hostingController?.dismiss(animated: true) {
                    VillageQuest6Runtime.shared.isPresentingForaging = false
                    self?.completeQuest6Foraging()
                }
            },
            onDismiss: {
                hostingController?.dismiss(animated: true) {
                    VillageQuest6Runtime.shared.isPresentingForaging = false
                }
            }
        )
        let controller = UIHostingController(rootView: minigame)
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        hostingController = controller
        rootViewController.present(controller, animated: true)
    }

    private func completeQuest6Foraging() {
        HapticsService.shared.playNotification(.success)
        quest6Progress.hasHerbal = true
        PrologueStore.shared.save()
        presentQuestDialogue([
            .init(speaker: "Arthur", text: "The herbs used to grow right by the fence. Now I have to walk all the way out here."),
            .init(speaker: "Arthur", text: "The insects... they were just buzzing a second ago."),
            .init(speaker: "Arthur", text: "No...")
        ]) { [weak self] in self?.showQuest6AtmosphereShift() }
    }

    private func showQuest6AtmosphereShift() {
        let fog = SKSpriteNode(color: SKColor(red: 0.29, green: 0.32, blue: 0.35, alpha: 0), size: size)
        fog.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fog.zPosition = 2800
        hud.addChild(fog)
        let whisper = SKLabelNode(fontNamed: "AvenirNext-Italic")
        whisper.text = "...ranting patah dari balik kabut..."
        whisper.fontSize = 17
        whisper.fontColor = .white.withAlphaComponent(0.82)
        whisper.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        whisper.alpha = 0
        whisper.zPosition = 2801
        hud.addChild(whisper)
        fog.run(.sequence([.fadeAlpha(to: 0.78, duration: 1.15), .wait(forDuration: 0.45),
                           .fadeOut(withDuration: 0.35), .removeFromParent()]))
        whisper.run(.sequence([.wait(forDuration: 0.55), .fadeIn(withDuration: 0.25),
                               .wait(forDuration: 0.55), .fadeOut(withDuration: 0.25),
                               .removeFromParent(), .run { [weak self] in self?.startQuest6ChaseQTE() }]))
    }

    private func startQuest6ChaseQTE() {
        guard VillageQuest6Runtime.shared.activeQTE == nil else { return }
        let chase = HollowChaseTapQuickTimeEventNode(config: .init(
            requiredTaps: 22, buttonPrompt: "LARI!", heading: "THE HOLLOW MENGEJAR!",
            instruction: "KETUK CEPAT · HINDARI POHON DAN BATU", decayPerSecond: 0.14,
            allowTouchAnywhere: true, autoDismissDelay: 0.75
        ))
        chase.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chase.zPosition = 3000
        hud.addChild(chase)
        VillageQuest6Runtime.shared.activeQTE = chase
        var succeeded = false
        chase.onComplete = { succeeded = $0 }
        chase.onDismiss = { [weak self, weak chase] in
            if VillageQuest6Runtime.shared.activeQTE === chase { VillageQuest6Runtime.shared.activeQTE = nil }
            guard let self else { return }
            if succeeded {
                self.startQuest6StumbleQTE()
            } else {
                self.presentQuestDialogue([.init(speaker: "Arthur", text: "It's getting closer. I have to keep moving!")]) {
                    [weak self] in self?.startQuest6ChaseQTE()
                }
            }
        }
        chase.start()
    }

    private func startQuest6StumbleQTE() {
        guard VillageQuest6Runtime.shared.activeQTE == nil else { return }
        let stumble = HollowQuickTimeEventNode(config: .init(
            radius: 88, stage1Duration: 1.25, stage2Duration: 1.05,
            stage1Zone: .init(start: 0.58, end: 0.84, greatStart: 0.70, greatEnd: 0.74),
            stage2Zone: .init(start: 0.20, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
            buttonPrompt: "BANGUN!", allowTouchAnywhere: true, autoDismissDelay: 0.75
        ))
        stumble.position = CGPoint(x: size.width / 2, y: size.height / 2)
        stumble.zPosition = 3000
        hud.addChild(stumble)
        VillageQuest6Runtime.shared.activeQTE = stumble
        var escaped = false
        stumble.onComplete = { escaped = $0 }
        stumble.onDismiss = { [weak self, weak stumble] in
            if VillageQuest6Runtime.shared.activeQTE === stumble { VillageQuest6Runtime.shared.activeQTE = nil }
            guard let self else { return }
            if escaped {
                self.completeQuest6Escape()
            } else {
                self.presentQuestDialogue([.init(speaker: "Arthur", text: "Get up, Arthur. Get up!")]) {
                    [weak self] in self?.startQuest6StumbleQTE()
                }
            }
        }
        stumble.start()
    }

    private func completeQuest6Escape() {
        quest6Progress.encounteredHollow = true
        PrologueStore.shared.save()
        presentQuestDialogue([
            .init(speaker: "Perempuan di Kebun", text: "Goodness, Arthur! Are you alright? Were you chased by a dog?"),
            .init(speaker: "Arthur", text: "No... No, I just tripped."),
            .init(speaker: "Perempuan di Kebun", text: "Well, catch your breath and get some water.")
        ]) { [weak self] in self?.rebuild("Bawa Silverleaf kembali ke Rumah Kakek Beryn.") }
    }

    private func finishQuest6AtBerynHouse() {
        presentQuestDialogue([
            .init(speaker: "Anak Kecil", text: "Grandpa, he got it!"),
            .init(speaker: "Arthur", text: "There is something in the hills."),
            .init(speaker: "Kakek Beryn", text: "Go take the dirty water out back."),
            .init(speaker: "Kakek Beryn", text: "That is what we have been warning you about."),
            .init(speaker: "Arthur", text: "Have you seen it?"),
            .init(speaker: "Kakek Beryn", text: "You have seen enough today to understand why it is forbidden to go too far."),
            .init(speaker: "Arthur", text: "Why didn't it follow me into the gardens? Because of the stones?"),
            .init(speaker: "Kakek Beryn", text: "The hills. The forest. Everything surrounding us... and the rules kept by those before us. That is what keeps us alive."),
            .init(speaker: "Arthur", text: "But how—"),
            .init(speaker: "Kakek Beryn", text: "Arthur. You made it home. Be grateful for that first.")
        ]) { [weak self] in
            self?.bucketFade { [weak self] in
                guard let self else { return }
                self.presentQuestDialogue([
                    .init(speaker: "Arthur", text: "Every time the wood creaks, I open my eyes."),
                    .init(speaker: "Arthur", text: "The stories they tell the children... they're real. But why won't anyone explain it to me?")
                ]) { [weak self] in
                    guard let self else { return }
                    self.quest6Progress.metBerynAfterHerbal = true
                    self.quest6Progress.storyProgress = max(self.quest6Progress.storyProgress, 9)
                    PrologueStore.shared.save()
                    self.rebuild("Quest 6 selesai. Keping hutan hijau tua masuk ke inventori peta.")
                }
            }
        }
    }
}
