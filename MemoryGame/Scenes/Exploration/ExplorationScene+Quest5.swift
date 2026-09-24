// Penyambung akhir Quest 5 ke Quest 6. Aktivitas tambang dan QTE rock salt
// tetap memakai implementasi yang sudah ada di ExplorationScene+Gameplay.
import SpriteKit

private final class Quest5Runtime {
    static let shared = Quest5Runtime()
    var isReturningToAnneth = false
}

extension ExplorationScene {
    func finishQuest5VillageReturn() {
        guard progress.mapBStage == .rockSalt,
              progress.hasRockSalt,
              !progress.deliveredRockSalt,
              !Quest5Runtime.shared.isReturningToAnneth else { return }

        Quest5Runtime.shared.isReturningToAnneth = true
        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        startDialogue([
            .init(speaker: "Anneth", text: "Halfway, Arthur. The bag is old."),
            .init(speaker: "Arthur", text: "I brought the salt. Nothing spilled this time."),
            .init(speaker: "Anneth", text: "Good. Kakek Beryn still needs herbs from the hills. Follow the garden path, but do not cross the boundary stones.")
        ]) { [weak self] in
            guard let self else { return }
            self.progress.deliveredRockSalt = true
            self.progress.isHerbalUnlocked = true
            self.progress.hasHerbal = false
            self.progress.encounteredHollow = false
            self.progress.metBerynAfterHerbal = false
            self.progress.mapBStage = .herbalHills
            self.progress.storyProgress = max(self.progress.storyProgress, 7)
            PrologueStore.shared.save()

            Quest5Runtime.shared.isReturningToAnneth = false
            self.enteringMemory = true
            let quest6Scene = ExplorationScene(
                size: self.size,
                entry: self.entry,
                worldLocations: self.worldLocations
            )
            quest6Scene.scaleMode = self.scaleMode
            self.view?.presentScene(quest6Scene, transition: .fade(withDuration: 0.55))
        }
    }
}
