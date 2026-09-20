import SpriteKit

extension PuzzleWorld {
    func makeScene(size: CGSize) -> SKScene {
        if self == .villagePrototype {
            let scene = VillagePrototypeScene(size: size)
            scene.storyProgress = PrologueStore.shared.progress
            scene.onExit = { [weak scene] in
                guard let view = scene?.view else { return }
                let puzzle = RightDeckPuzzleScene(size: view.bounds.size)
                puzzle.scaleMode = .resizeFill
                view.presentScene(puzzle, transition: .fade(withDuration: 0.25))
            }
            return scene
        }
        return ExplorationScene(size: size, entry: entry, worldLocations: locations)
    }
}
