// Quest 7: Arthur mencari kayu di lereng hutan dan menemukan Buku Catatan Elias.
// Menyediakan penanganan transisi dan dialog kepulangan di ExplorationScene.
import SpriteKit

private final class Quest7Runtime {
    static let shared = Quest7Runtime()
    var isReturningToGrandpa = false
}

extension ExplorationScene {
    /// Dipanggil ketika Arthur kembali ke desa setelah menemukan Buku Elias di lereng hutan.
    func finishQuest7VillageReturn() {
        guard progress.gatheredWood,
              progress.hasEliasBook,
              !Quest7Runtime.shared.isReturningToGrandpa else { return }

        Quest7Runtime.shared.isReturningToGrandpa = true
        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        quest7TravelFade { [weak self] in
            guard let self else { return }
            self.startDialogue(self.quest7GrandpaConfrontationDialogue) { [weak self] in
                guard let self else { return }
                self.progress.storyProgress = max(self.progress.storyProgress, 10)
                PrologueStore.shared.save()
                self.objective.text = "Quest 7 selesai: Gudang Kosong (Markas Rahasia) terbuka."
                Quest7Runtime.shared.isReturningToGrandpa = false
                self.showUnlockCard(
                    title: "🏚️ GUDANG KOSONG TERBUKA!",
                    body: "Quest 7 selesai. Arthur bergegas menemui para sahabat untuk merencanakan pertemuan di markas rahasia. Bangunan Gudang Kosong kini dapat ditempatkan di peta!"
                )
            }
        }
    }

    private var quest7GrandpaConfrontationDialogue: [StoryLine] {
        [
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
        ]
    }

    private func quest7TravelFade(completion: @escaping () -> Void) {
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
