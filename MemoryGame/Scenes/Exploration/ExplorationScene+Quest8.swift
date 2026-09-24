// Quest 8: Arthur cerita ke temannya (Roland, Anneth, Keneth) di ExplorationScene.
// Mendukung dialog pertemuan di markas rahasia, The Old Fog, dan persiapan ekspedisi.
import SpriteKit
import SwiftUI
import UIKit

private final class Quest8ExplorationRuntime {
    static let shared = Quest8ExplorationRuntime()
    var isPresentingLoadout = false
    var isTransitioning = false
}

extension ExplorationScene {
    /// Memulai rangkaian dialog Quest 8 jika Arthur berinteraksi dengan teman-temannya di desa.
    func startQuest8FriendsMeeting() {
        guard progress.hasEliasBook,
              !Quest8ExplorationRuntime.shared.isTransitioning else { return }

        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        startDialogue([
            .init(speaker: "Narasi", text: "Arthur meletakkan Buku Elias di atas batu. Halaman terbuka menampilkan The Hollow yang menelan manusia."),
            .init(speaker: "Keneth", text: "And you’re only telling us this now?!"),
            .init(speaker: "Arthur", text: "I was still trying to understand it myself."),
            .init(speaker: "Roland", text: "You said you’d tell me. You almost didn't make it home, Arthur. Were you actually planning to leave?"),
            .init(speaker: "Arthur", text: "I didn't plan it! I was just looking for leaves"),
            .init(speaker: "Roland", text: "Yeah. You didn't plan it. That's the problem."),
            .init(speaker: "Anneth", text: "This might be important, Arthur. But it's not a map. There’s no route, no survival plan. It’s too dangerous to use as an excuse to just wander off."),
            .init(speaker: "Arthur", text: "We're losing resources! The rock salt, the dry wood, the herbs... If there's another place out there, if someone knows something—"),
            .init(speaker: "Keneth", text: "We have enough! We are still eating. That’s no reason to throw your neck to the monsters. Take it to the elders.")
        ]) { [weak self] in
            self?.showQuest8AtmosphericFogEvent()
        }
    }

    private func showQuest8AtmosphericFogEvent() {
        Quest8ExplorationRuntime.shared.isTransitioning = true

        quest8TravelFade { [weak self] in
            guard let self else { return }

            // Tampilkan dialog Tetua di kabut senja
            self.startDialogue([
                .init(speaker: "Tetua Desa", text: "Stay calm, everyone! It’s just the old season fog. The valley is changing, but the village protection holds. Finish your chores and close your doors."),
                .init(speaker: "Arthur", text: "Desa memang tidak diserang malam ini... tapi alam di luar sana jelas sedang berubah drastis."),
                .init(speaker: "Arthur", text: "Malam ini, aku harus mengumpulkan mereka kembali di belakang rumah Anneth.")
            ]) { [weak self] in
                self?.startQuest8NightBackyardGathering()
            }
        }
    }

    private func startQuest8NightBackyardGathering() {
        quest8TravelFade { [weak self] in
            guard let self else { return }

            self.startDialogue([
                .init(speaker: "Arthur", text: "We don't go far. Just to the tree where I found the book. We check the dirt around the roots. If there's nothing else, we come back. Long before dark."),
                .init(speaker: "Keneth", text: "You still want to go."),
                .init(speaker: "Arthur", text: "I just want to know if any of this is real. Not to fight the monster. Keneth... if we want this village to survive, don't we need to know what's out there?"),
                .init(speaker: "Keneth", text: "My father didn't just move the sacks because the wall was damp. The floorboards are rotting. We keep delaying the repairs because there’s no good wood left... I'll go as far as the tree. That's it. I just want to come home to a house that's still standing."),
                .init(speaker: "Roland", text: "I don't trust your plan, Arthur. But I trust you by yourself even less. If you don't come back, we're the ones who have to look for you."),
                .init(speaker: "Anneth", text: "Supplies for four. Water. Ropes. A small knife to cut branches, not to act brave. Ointment and clean cloth. We leave past the eastern hill gap, and if we hear anything strange, we don't separate. Understand?"),
                .init(speaker: "Arthur", text: "Understood.")
            ]) { [weak self] in
                self?.presentQuest8ExplorationPartyLoadout()
            }
        }
    }

    private func presentQuest8ExplorationPartyLoadout() {
        guard !Quest8ExplorationRuntime.shared.isPresentingLoadout,
              let rootVC = view?.window?.rootViewController else {
            completeQuest8Exploration()
            return
        }

        Quest8ExplorationRuntime.shared.isPresentingLoadout = true
        var hostingController: UIHostingController<PartyLoadoutPrepView>?
        let minigameView = PartyLoadoutPrepView(
            onComplete: { [weak self] in
                hostingController?.dismiss(animated: true) {
                    Quest8ExplorationRuntime.shared.isPresentingLoadout = false
                    self?.completeQuest8Exploration()
                }
            },
            onDismiss: {
                hostingController?.dismiss(animated: true) {
                    Quest8ExplorationRuntime.shared.isPresentingLoadout = false
                }
            }
        )

        let controller = UIHostingController(rootView: minigameView)
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        hostingController = controller
        rootVC.present(controller, animated: true)
    }

    private func completeQuest8Exploration() {
        HapticsService.shared.playNotification(.success)
        progress.boundaryMarked = true
        progress.storyProgress = max(progress.storyProgress, 11)
        PrologueStore.shared.save()
        objective.text = "Quest 8 selesai: Rombongan siap berangkat keluar desa esok fajar."
        Quest8ExplorationRuntime.shared.isTransitioning = false

        showUnlockCard(
            title: "🎒 PERSIAPAN EKSPEDISI LENGKAP!",
            body: "Quest 8 selesai. Roland, Anneth, dan Keneth telah sepakat ikut demi masa depan desa. Lima barang wajib telah terkemas di tas ransel. Besok fajar, ekspedisi ke The Boundary dimulai!"
        )
    }

    private func quest8TravelFade(completion: @escaping () -> Void) {
        let cover = SKSpriteNode(color: .black, size: size)
        cover.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cover.alpha = 0
        cover.zPosition = 3500
        hud.addChild(cover)

        cover.run(.sequence([
            .fadeIn(withDuration: 0.35),
            .wait(forDuration: 0.40),
            .fadeOut(withDuration: 0.35),
            .removeFromParent(),
            .run(completion)
        ]))
    }
}
