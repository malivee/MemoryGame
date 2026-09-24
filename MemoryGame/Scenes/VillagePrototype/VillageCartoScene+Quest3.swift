// Quest 3: Suara Pelindung - Arthur mencari Roland di peternakan.
import SpriteKit

private final class VillageQuest3Runtime {
    static let shared = VillageQuest3Runtime()

    var progress = VillageQuest3Progress.load()
    var choiceCompletion: ((Bool) -> Void)?
    weak var activeQTE: TapQuickTimeEventNode?
}

extension VillageCartoScene {
    var quest3: VillageQuest3Progress {
        get { VillageQuest3Runtime.shared.progress }
        set { VillageQuest3Runtime.shared.progress = newValue }
    }

    var activeQuest3QTE: TapQuickTimeEventNode? {
        get { VillageQuest3Runtime.shared.activeQTE }
        set { VillageQuest3Runtime.shared.activeQTE = newValue }
    }

    var quest3Objective: String {
        VillageQuestEngine.quest3Objective(for: villageQuestSnapshot)
    }

    func saveQuest3() {
        quest3.save()
    }

    var quest3RolandPenPosition: CGPoint? {
        questPosition(for: "roland-pen")
    }

    func renderQuest3World() {
        guard let pen = quest3RolandPenPosition else { return }
        renderRolandFence(at: pen)
        let roland = CGPoint(x: pen.x + 28, y: pen.y)
        questNPC(at: roland, name: "Roland", color: .systemOrange)

        if !quest3.spokeToRoland {
            questMarker(at: CGPoint(x: roland.x, y: roland.y + 25), name: "quest3-roland", color: .systemYellow, symbol: "!")
        } else if !quest3.fenceChecked {
            let fence = quest3FencePosition(from: pen)
            questMarker(at: CGPoint(x: fence.x, y: fence.y + 18), name: "quest3-fence", color: .systemOrange, symbol: "!")
        }
    }

    func renderRolandFence(at position: CGPoint) {
        let yard = SKNode()
        yard.position = position
        yard.zPosition = 54

        let dust = SKShapeNode(ellipseOf: CGSize(width: 92, height: 44))
        dust.fillColor = SKColor(red: 0.55, green: 0.43, blue: 0.25, alpha: 0.45)
        dust.strokeColor = .clear
        yard.addChild(dust)

        for x in stride(from: -36, through: 36, by: 18) {
            let post = SKShapeNode(rectOf: CGSize(width: 6, height: 42), cornerRadius: 2)
            post.position = CGPoint(x: CGFloat(x), y: -5)
            post.fillColor = SKColor(red: 0.42, green: 0.26, blue: 0.13, alpha: 1)
            post.strokeColor = .black.withAlphaComponent(0.35)
            yard.addChild(post)
        }
        for y in [-16.0, 4.0] {
            let rail = SKShapeNode(rectOf: CGSize(width: 88, height: 5), cornerRadius: 1)
            rail.position = CGPoint(x: 0, y: y)
            rail.fillColor = SKColor(red: 0.48, green: 0.31, blue: 0.15, alpha: 1)
            rail.strokeColor = .black.withAlphaComponent(0.28)
            yard.addChild(rail)
        }

        world.addChild(yard)
    }

    func quest3FencePosition(from pen: CGPoint) -> CGPoint {
        CGPoint(x: pen.x - 24, y: pen.y - 8)
    }

    func handleQuest3Interaction(at point: CGPoint) -> Bool {
        guard let pen = quest3RolandPenPosition else { return false }
        let roland = CGPoint(x: pen.x + 28, y: pen.y)
        if hypot(point.x - roland.x, point.y - roland.y) <= 48 {
            if !quest3.spokeToRoland {
                approachOrInteract(roland, message: "Dekati Roland untuk berbicara.") { [weak self] in
                    self?.startQuest3RolandDialogue()
                }
            } else if quest3.fenceChecked && !quest3.completed {
                completeQuest3AfterFence()
            } else {
                status.text = quest3Objective
            }
            return true
        }

        let fence = quest3FencePosition(from: pen)
        if quest3.spokeToRoland,
           !quest3.fenceChecked,
           hypot(point.x - fence.x, point.y - fence.y) <= 44 {
            approachOrInteract(fence, message: "Dekati pagar kandang.") { [weak self] in
                self?.startQuest3FenceQTE()
            }
            return true
        }

        return false
    }

    func startQuest3RolandDialogue() {
        presentQuestDialogue([
            .init(speaker: "Roland", text: "Find it yet? Whatever it is you lost. You always walk around looking like you’re searching for a spoon at the bottom of a well."),
            .init(speaker: "Arthur", text: "Someday... I want to see the forest boundary up close."),
            .init(speaker: "Roland", text: "Tell me first. So I know which idiot I have to go looking for."),
            .init(speaker: "Arthur", text: "I didn't say I was going."),
            .init(speaker: "Roland", text: "Good. Glad you still know the difference between 'want to' and 'going to'."),
            .init(speaker: "Roland", text: "Yesterday, you climbed the warehouse beam just to check out a nest. You only asked if the beam was strong enough after you were already up there."),
            .init(speaker: "Arthur", text: "The nest was empty."),
            .init(speaker: "Roland", text: "The beam almost snapped, Arthur."),
            .init(speaker: "Roland", text: "Just... tell me, Arthur.")
        ]) { [weak self] in
            self?.presentQuest3Choice()
        }
    }

    func presentQuest3Choice() {
        VillageQuest3Runtime.shared.choiceCompletion = { [weak self] promised in
            guard let self else { return }
            self.quest3.spokeToRoland = true
            self.quest3.promisedRoland = promised
            self.quest3.stayedSilent = !promised
            self.saveQuest3()
            self.presentQuestDialogue([
                .init(speaker: "Roland", text: promised ? "Good. Keep that promise where I can see it." : "You're impossible."),
                .init(speaker: "Roland", text: "Just... don't do anything stupid alone. Anneth has been looking for you all morning. Go see her."),
                .init(speaker: "Arthur", text: "I will. After I help with the fence.")
            ]) { [weak self] in
                self?.rebuild("Bantu Roland mengecek pagar kandang.")
            }
        }
        renderQuestChoice(
            title: "Jawaban Arthur",
            first: "Mengangguk Janji",
            second: "Tetap Diam"
        )
    }

    func renderQuestChoice(title: String, first: String, second: String) {
        hud.childNode(withName: "quest-choice")?.removeFromParent()
        let width = min(size.width - 50, 520)
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: 128), cornerRadius: 14)
        panel.name = "quest-choice"
        panel.position = CGPoint(x: size.width / 2, y: 116)
        panel.fillColor = SKColor(white: 0.06, alpha: 0.96)
        panel.strokeColor = cream.withAlphaComponent(0.8)
        panel.lineWidth = 2
        panel.zPosition = 2700

        text(title, at: CGPoint(x: 0, y: 42), size: 14, parent: panel, color: .systemYellow)
        questChoiceButton(first, name: "quest-choice-yes", at: CGPoint(x: -width * 0.24, y: -12), parent: panel)
        questChoiceButton(second, name: "quest-choice-no", at: CGPoint(x: width * 0.24, y: -12), parent: panel)
        hud.addChild(panel)
    }

    private func questChoiceButton(_ title: String, name: String, at point: CGPoint, parent: SKNode) {
        let node = SKShapeNode(rectOf: CGSize(width: 190, height: 42), cornerRadius: 10)
        node.name = name
        node.position = point
        node.fillColor = SKColor(red: 0.08, green: 0.25, blue: 0.28, alpha: 1)
        node.strokeColor = cream.withAlphaComponent(0.65)
        node.lineWidth = 1.5
        text(title, at: .zero, size: 12, parent: node, color: cream)
        node.children.first?.name = name
        parent.addChild(node)
    }

    func handleQuestChoiceTap(actions: Set<String>) -> Bool {
        guard let completion = VillageQuest3Runtime.shared.choiceCompletion else { return false }
        if actions.contains("quest-choice-yes") || actions.contains("quest-choice-no") {
            hud.childNode(withName: "quest-choice")?.removeFromParent()
            VillageQuest3Runtime.shared.choiceCompletion = nil
            completion(actions.contains("quest-choice-yes"))
            return true
        }
        return false
    }

    func startQuest3FenceQTE() {
        guard activeQuest3QTE == nil else { return }
        let qte = TapQuickTimeEventNode(config: TapQuickTimeEventConfig(
            requiredTaps: 18,
            buttonPrompt: "TEKAN",
            heading: "KUATKAN PAGAR",
            instruction: "Ketuk cepat untuk menahan tiang kandang.",
            style: .classic,
            allowTouchAnywhere: true,
            autoDismissDelay: 0.45
        ))
        qte.position = CGPoint(x: size.width / 2, y: size.height / 2)
        qte.zPosition = 3100
        qte.onComplete = { [weak self] success in
            guard let self else { return }
            if success {
                self.quest3.fenceChecked = true
                self.saveQuest3()
            }
        }
        qte.onDismiss = { [weak self, weak qte] in
            guard let self else { return }
            if self.activeQuest3QTE === qte { self.activeQuest3QTE = nil }
            guard self.quest3.fenceChecked else {
                self.rebuild("Pagar belum kuat. Coba bantu Roland lagi.")
                return
            }
            self.completeQuest3AfterFence()
        }
        activeQuest3QTE = qte
        addChild(qte)
        qte.start()
    }

    func completeQuest3AfterFence() {
        presentQuestDialogue([
            .init(speaker: "Roland", text: "That's enough. The fence will hold."),
            .init(speaker: "Roland", text: "Anneth has been looking for you all morning. Go see her."),
            .init(speaker: "Arthur", text: "I'll go now.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest3.completed = true
            let progress = PrologueStore.shared.progress
            progress.storyProgress = max(progress.storyProgress, 4)
            PrologueStore.shared.save()
            self.saveQuest3()
            self.rebuild("Quest 3 selesai. Keping Rumah Anneth terbuka.")
        }
    }
}
