import SpriteKit

extension VillagePrototypeScene {
    func refreshStory() {
        guard let storyProgress else { return }
        setAccess(StoryProgression.villageAccess(for: storyProgress))
        storyNPCs.removeAllChildren()
        if StoryProgression.showsWellResidents(for: storyProgress) {
            let positions = [CGPoint(x: 805, y: 720), CGPoint(x: 905, y: 700), CGPoint(x: 1005, y: 720)]
            let colors: [SKColor] = [.brown, .systemGray, .systemTeal]
            for (index, position) in positions.enumerated() {
                let node = MemoryCharacter(title: "", color: colors[index])
                node.name = "well-resident-\(index)"
                node.position = position
                node.zPosition = 22
                storyNPCs.addChild(node)
            }
        }
        activeStoryStep = StoryProgression.currentStep(for: storyProgress)
        if activeStoryStep?.world != .villagePrototype {
            activeStoryStep = StoryProgression.steps.last {
                $0.world == .villagePrototype && $0.id <= storyProgress.storyProgress
            }
        }
        guard let step = activeStoryStep, step.world == .villagePrototype else { return }
        let positions: [Int: CGPoint] = [
            1: CGPoint(x: 1400, y: 545), 2: CGPoint(x: 1275, y: 520),
            3: CGPoint(x: 1220, y: 1005), 4: CGPoint(x: 1550, y: 320),
            5: CGPoint(x: 565, y: 1280), 7: CGPoint(x: 565, y: 1280),
            12: CGPoint(x: 1170, y: 850),
            9: CGPoint(x: 1105, y: 270), 11: CGPoint(x: 1660, y: 935)
        ]
        guard let position = positions[step.id] else { return }
        for (index, npc) in step.npcs.enumerated() {
            let visibleName = step.id == 12 ? "" : npc.name
            let node = MemoryCharacter(title: visibleName, color: .systemTeal)
            node.name = npc.id
            let offset: [(CGFloat, CGFloat)] = [(-90, 55), (0, -70), (90, 55)]
            let delta: (CGFloat, CGFloat) = step.npcs.count == 1 ? (0, 0) : offset[min(index, offset.count - 1)]
            node.position = CGPoint(x: position.x + delta.0, y: position.y + delta.1)
            node.zPosition = 22
            storyNPCs.addChild(node)
        }
    }

    var currentDialogueLines: [StoryLine] {
        if isWellConversation {
            return [StoryProgression.wellConversation[min(wellResidentIndex,
                                                          StoryProgression.wellConversation.count - 1)]]
        }
        return activeStoryStep?.dialogue ?? []
    }

    func renderStoryDialogue() {
        storyPanel.removeFromParent()
        storyPanel.removeAllChildren()
        guard let index = dialogueIndex,
              currentDialogueLines.indices.contains(index) else { return }
        let line = currentDialogueLines[index]
        let width = max(180, min(size.width-40, 620))
        let text = SKLabelNode(fontNamed: "AvenirNext-Regular")
        text.text = line.text
        text.fontSize = 16
        text.fontColor = .white
        text.preferredMaxLayoutWidth = width-36
        text.numberOfLines = 0
        text.verticalAlignmentMode = .top
        let height = max(115, text.frame.height+66)
        let background = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
        background.fillColor = SKColor(white: 0.10, alpha: 0.97)
        background.strokeColor = SKColor(white: 0.8, alpha: 0.5)
        storyPanel.addChild(background)
        let speaker = label(line.speaker, at: CGPoint(x: 0, y: height/2-28), size: 15, on: storyPanel)
        speaker.fontColor = .systemYellow
        text.position = CGPoint(x: 0, y: height/2-45)
        storyPanel.addChild(text)
        storyPanel.position = CGPoint(x: size.width/2, y: height/2+40)
        storyPanel.zPosition = 100
        hud.addChild(storyPanel)
    }

    func advanceStoryDialogue() {
        guard let index = dialogueIndex else { return }
        if index+1 < currentDialogueLines.count {
            dialogueIndex = index+1
            renderStoryDialogue()
            return
        }
        dialogueIndex = nil
        renderStoryDialogue()
        if isWellConversation {
            isWellConversation = false
            return
        }
        guard let step = activeStoryStep, let storyProgress else { return }
        if StoryProgression.complete(step, in: storyProgress) {
            PrologueStore.shared.save()
            refreshStory()
            hint("Bagian kenangan berikutnya terbuka.")
        }
    }
}
