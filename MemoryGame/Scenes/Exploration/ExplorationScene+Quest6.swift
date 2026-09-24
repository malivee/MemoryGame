// Quest 6: Arthur mencari herbal dan mengalami perjumpaan pertama dengan The Hollow.
// Alur ini dimulai sesudah Quest 5 menyerahkan rock salt dan membuka Herbal Hills.
import SpriteKit
import SwiftUI
import UIKit

private final class Quest6Runtime {
    static let shared = Quest6Runtime()

    var isPresentingForaging = false
    var isReturningToVillage = false
}

extension ExplorationScene {
    /// Entry mandiri Quest 6 tersedia melalui Debug > Quest 6: Perbukitan Herbal.
    func startQuest6Foraging() {
        guard progress.mapBStage == .herbalHills,
              progress.deliveredRockSalt,
              progress.isHerbalUnlocked,
              !progress.hasHerbal,
              !Quest6Runtime.shared.isPresentingForaging,
              activeQTE == nil,
              let rootViewController = view?.window?.rootViewController else { return }

        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter
        Quest6Runtime.shared.isPresentingForaging = true

        var hostingController: UIHostingController<FlowerFieldForagingView>?
        let minigame = FlowerFieldForagingView(
            onComplete: { [weak self] in
                hostingController?.dismiss(animated: true) {
                    Quest6Runtime.shared.isPresentingForaging = false
                    self?.completeQuest6Foraging()
                }
            },
            onDismiss: {
                hostingController?.dismiss(animated: true) {
                    Quest6Runtime.shared.isPresentingForaging = false
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
        progress.hasHerbal = true
        PrologueStore.shared.save()
        herbalNode?.removeFromParent()
        herbalNode = nil
        objective.text = progress.currentObjective(for: entry.region)

        startDialogue([
            .init(speaker: "Arthur", text: "The herbs used to grow right by the fence. Now I have to walk all the way up here."),
            .init(speaker: "Arthur", text: "The insects... they were just buzzing a second ago."),
            .init(speaker: "Arthur", text: "No...")
        ]) { [weak self] in
            self?.startQuest6HollowEncounter()
        }
    }

    func startQuest6HollowEncounter() {
        guard progress.mapBStage == .herbalHills,
              progress.deliveredRockSalt,
              progress.isHerbalUnlocked,
              progress.hasHerbal,
              !progress.encounteredHollow,
              activeQTE == nil else { return }

        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter
        showQuest6AtmosphereShift { [weak self] in
            self?.startQuest6ChaseQTE()
        }
    }

    private func showQuest6AtmosphereShift(completion: @escaping () -> Void) {
        let fog = SKSpriteNode(
            color: SKColor(red: 0.29, green: 0.32, blue: 0.35, alpha: 0.0),
            size: size
        )
        fog.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fog.zPosition = 820
        hud.addChild(fog)

        let whisper = SKLabelNode(fontNamed: "AvenirNext-Italic")
        whisper.text = "...ranting patah dari balik kabut..."
        whisper.fontSize = 17
        whisper.fontColor = .white.withAlphaComponent(0.82)
        whisper.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        whisper.alpha = 0
        whisper.zPosition = 821
        hud.addChild(whisper)

        fog.run(.sequence([
            .fadeAlpha(to: 0.78, duration: 1.15),
            .wait(forDuration: 0.45),
            .fadeOut(withDuration: 0.35),
            .removeFromParent()
        ]))
        whisper.run(.sequence([
            .wait(forDuration: 0.55),
            .fadeIn(withDuration: 0.25),
            .wait(forDuration: 0.55),
            .fadeOut(withDuration: 0.25),
            .removeFromParent(),
            .run(completion)
        ]))
    }

    private func startQuest6ChaseQTE() {
        guard activeQTE == nil else { return }

        let chase = HollowChaseTapQuickTimeEventNode(config: .init(
            requiredTaps: 22,
            buttonPrompt: "LARI!",
            heading: "THE HOLLOW MENGEJAR!",
            instruction: "KETUK CEPAT · HINDARI POHON DAN BATU",
            decayPerSecond: 0.14,
            allowTouchAnywhere: true,
            autoDismissDelay: 0.75
        ))
        chase.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chase.zPosition = 3000
        hud.addChild(chase)
        activeQTE = chase

        var chaseSucceeded = false
        chase.onComplete = { success in
            chaseSucceeded = success
        }
        chase.onDismiss = { [weak self, weak chase] in
            guard let self else { return }
            if self.activeQTE === chase { self.activeQTE = nil }
            if chaseSucceeded {
                self.startQuest6StumbleQTE()
            } else {
                self.say("Bayangan semakin dekat. Ketuk cepat untuk menjauh!", duration: 3)
            }
        }
        chase.start()
    }

    private func startQuest6StumbleQTE() {
        guard activeQTE == nil else { return }

        let stumble = HollowQuickTimeEventNode(config: .init(
            radius: 88,
            stage1Duration: 1.25,
            stage2Duration: 1.05,
            stage1Zone: .init(start: 0.58, end: 0.84, greatStart: 0.70, greatEnd: 0.74),
            stage2Zone: .init(start: 0.20, end: 0.44, greatStart: 0.28, greatEnd: 0.32),
            buttonPrompt: "BANGUN!",
            allowTouchAnywhere: true,
            autoDismissDelay: 0.75
        ))
        stumble.position = CGPoint(x: size.width / 2, y: size.height / 2)
        stumble.zPosition = 3000
        hud.addChild(stumble)
        activeQTE = stumble

        var escaped = false
        stumble.onComplete = { success in escaped = success }
        stumble.onDismiss = { [weak self, weak stumble] in
            guard let self else { return }
            if self.activeQTE === stumble { self.activeQTE = nil }
            if escaped {
                self.completeQuest6Escape()
            } else {
                self.say("Arthur terlambat bangkit. Dekati bayangan untuk mencoba pelarian lagi.", duration: 4)
            }
        }
        stumble.start()
    }

    private func completeQuest6Escape() {
        progress.encounteredHollow = true
        PrologueStore.shared.save()
        objective.text = progress.currentObjective(for: entry.region)
        hollowNode?.run(.sequence([
            .group([
                .fadeOut(withDuration: 1.0),
                .moveBy(x: 50, y: 12, duration: 1.0)
            ]),
            .removeFromParent()
        ]))

        startDialogue([
            .init(speaker: "Perempuan di Kebun", text: "Goodness, Arthur! Are you alright? Were you chased by a dog?"),
            .init(speaker: "Arthur", text: "No... No, I just tripped."),
            .init(speaker: "Perempuan di Kebun", text: "Well, catch your breath and get some water.")
        ]) { [weak self] in
            self?.showAnnouncementBanner(
                icon: "🌿",
                title: "Antarkan Herbal",
                subtitle: "Bawa daun obat ke Kakek Beryn di rumah berbatu pipih."
            )
        }
    }

    /// Dipanggil ketika Arthur mencapai jalur desa setelah lolos dari Hollow.
    func finishQuest6VillageReturn() {
        guard progress.mapBStage == .herbalHills,
              progress.deliveredRockSalt,
              progress.isHerbalUnlocked,
              progress.hasHerbal,
              progress.encounteredHollow,
              !progress.metBerynAfterHerbal,
              !Quest6Runtime.shared.isReturningToVillage else { return }

        Quest6Runtime.shared.isReturningToVillage = true
        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        quest6TravelFade { [weak self] in
            guard let self else { return }
            self.startDialogue(self.quest6BerynDialogue) { [weak self] in
                guard let self else { return }
                self.quest6TravelFade { [weak self] in
                    guard let self else { return }
                    self.startDialogue(self.quest6NightDialogue) { [weak self] in
                        guard let self else { return }
                        self.progress.metBerynAfterHerbal = true
                        self.progress.storyProgress = max(self.progress.storyProgress, 9)
                        PrologueStore.shared.save()
                        self.objective.text = "Quest 6 selesai. Pagi berikutnya dimulai."
                        Quest6Runtime.shared.isReturningToVillage = false
                        self.showUnlockCard(
                            title: "🌲 KEPING HUTAN TERBUKA!",
                            body: "Quest 6 selesai. Keping 7 berbentuk I dengan biome hutan hijau tua telah masuk ke inventori peta."
                        )
                    }
                }
            }
        }
    }

    private var quest6BerynDialogue: [StoryLine] {
        [
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
        ]
    }

    private var quest6NightDialogue: [StoryLine] {
        [
            .init(speaker: "Arthur", text: "Every time the wood creaks, I open my eyes. I didn't tell my grandfather what happened."),
            .init(speaker: "Arthur", text: "I was just looking for leaves. It sounds so stupid now."),
            .init(speaker: "Arthur", text: "The stories they tell the children... they're real. But why won't anyone explain it to me?")
        ]
    }

    private func quest6TravelFade(completion: @escaping () -> Void) {
        let cover = SKSpriteNode(color: .black, size: size)
        cover.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cover.alpha = 0
        cover.zPosition = 3500
        hud.addChild(cover)
        cover.run(.sequence([
            .fadeIn(withDuration: 0.35),
            .wait(forDuration: 0.45),
            .fadeOut(withDuration: 0.35),
            .removeFromParent(),
            .run(completion)
        ]))
    }
}
