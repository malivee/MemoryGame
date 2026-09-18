import SpriteKit
import UIKit

// Flow adapter. Gameplay rules live in Models and Systems.
extension OpeningCutsceneScene {
    func skipCutscene() {
        guard !leaving, let view else { return }
        leaving = true
        removeAction(forKey: "advanceCutscene")
        UserDefaults.standard.set(true, forKey: "hasSeenOpeningCutscene")
        let puzzle = RightDeckPuzzleScene(size: size)
        puzzle.scaleMode = .resizeFill
        MemoryFogTransition.present(puzzle, from: self, in: view)
    }

    func advance() {
        guard !changingShot, !leaving, let view else { return }
        removeAction(forKey: "advanceCutscene")
        changingShot = true
        if index == shots.count - 1 {
            leaving = true

            UserDefaults.standard.set(true, forKey: "hasSeenOpeningCutscene")
            let puzzle = RightDeckPuzzleScene(size: size)
            puzzle.scaleMode = .resizeFill
            hint.run(.fadeOut(withDuration: 0.25))
            subtitle.run(.fadeOut(withDuration: 0.4))
            MemoryFogTransition.present(puzzle, from: self, in: view)
            return
        }
        picture.removeAction(forKey: "drift")
        picture.run(.fadeOut(withDuration: 0.2))
        subtitle.run(.fadeOut(withDuration: 0.2))
        run(.sequence([.wait(forDuration: 0.2), .run { [weak self] in
            guard let self else { return }
            self.index += 1
            self.showShot()
        }]), withKey: "changeShot")
    }
}
