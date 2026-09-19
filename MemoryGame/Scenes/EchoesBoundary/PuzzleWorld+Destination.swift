import SpriteKit

extension PuzzleWorld {
    func makeScene(size: CGSize) -> SKScene {
        return ExplorationScene(size: size, entry: entry, worldLocations: locations)
    }
}
