import SpriteKit

extension RightDeckPuzzleScene {
    func addDebugButton() {
        let button = canvas.storyButton("DEBUG", name: "debug", at: CGPoint(x: deckBounds.midX, y: deckBounds.maxY - 24), width: 100)
        button.zPosition = 700
        button.children.forEach { $0.name = "debug" }
        if debugMenuVisible { addDebugWorldChoices() }
    }

    func addDebugWorldChoices() {
        for world in PuzzleWorld.allCases {
            let y = deckBounds.maxY - 72 - CGFloat(world.rawValue) * 34
            let button = canvas.storyButton("\(world.rawValue + 1). \(world.title)",
                                            name: "debug-world-\(world.rawValue)",
                                            at: CGPoint(x: deckBounds.midX, y: y), width: 170)
            button.zPosition = 701
            button.children.forEach { $0.name = button.name }
        }
    }

    func toggleDebugMenu() {
        debugMenuVisible.toggle()
        rebuild(resetCamera: false)
    }

    func enterDebugWorld(_ world: PuzzleWorld) {
        guard !enteringMemory else { return }
        enteringMemory = true
        let destination = world.makeScene(size: size)
        destination.scaleMode = .resizeFill
        view?.presentScene(destination, transition: .fade(withDuration: 0.25))
    }
}
