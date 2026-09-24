// Quest 4: Sang Perencana - Arthur membantu Anneth dan menerima misi rock salt.
import SpriteKit

private final class VillageQuest4Runtime {
    static let shared = VillageQuest4Runtime()

    var progress = VillageQuest4Progress.load()
    weak var activeMinigame: ItemSortingMinigameNode?
}

extension VillageCartoScene {
    var quest4: VillageQuest4Progress {
        get { VillageQuest4Runtime.shared.progress }
        set { VillageQuest4Runtime.shared.progress = newValue }
    }

    var activeQuest4Minigame: ItemSortingMinigameNode? {
        get { VillageQuest4Runtime.shared.activeMinigame }
        set { VillageQuest4Runtime.shared.activeMinigame = newValue }
    }

    var quest4Objective: String {
        VillageQuestEngine.quest4Objective(for: villageQuestSnapshot)
    }

    func saveQuest4() {
        quest4.save()
    }

    var quest4AnnethHousePosition: CGPoint? {
        questPosition(for: "anneth-house")
    }

    func renderQuest4World() {
        guard let house = quest4AnnethHousePosition else { return }
        renderAnnethKitchen(at: house)
        let anneth = CGPoint(x: house.x + 26, y: house.y)
        questNPC(at: anneth, name: "Anneth", color: .systemPurple)

        if !quest4.metAnneth {
            questMarker(at: CGPoint(x: anneth.x, y: anneth.y + 25), name: "quest4-anneth", color: .systemYellow, symbol: "!")
        } else if !quest4.sortedTubers {
            let table = quest4KitchenTablePosition(from: house)
            questMarker(at: CGPoint(x: table.x, y: table.y + 18), name: "quest4-tubers", color: .systemOrange, symbol: "!")
        } else if !quest4.completed {
            let mother = quest4MotherPosition(from: house)
            questMarker(at: CGPoint(x: mother.x, y: mother.y + 25), name: "quest4-mother", color: .systemYellow, symbol: "!")
        }
    }

    func renderAnnethKitchen(at position: CGPoint) {
        let kitchen = SKNode()
        kitchen.position = position
        kitchen.zPosition = 54

        let counter = SKShapeNode(rectOf: CGSize(width: 86, height: 30), cornerRadius: 4)
        counter.position = CGPoint(x: -10, y: -10)
        counter.fillColor = SKColor(red: 0.45, green: 0.28, blue: 0.14, alpha: 1)
        counter.strokeColor = SKColor(red: 0.20, green: 0.12, blue: 0.07, alpha: 1)
        counter.lineWidth = 2
        kitchen.addChild(counter)

        for x in [-32.0, -17.0, 1.0] {
            let tuber = SKShapeNode(ellipseOf: CGSize(width: 12, height: 8))
            tuber.position = CGPoint(x: x, y: -5)
            tuber.fillColor = SKColor(red: 0.62, green: 0.40, blue: 0.21, alpha: 1)
            tuber.strokeColor = .black.withAlphaComponent(0.35)
            kitchen.addChild(tuber)
        }

        let pot = SKShapeNode(circleOfRadius: 13)
        pot.position = CGPoint(x: 34, y: 13)
        pot.fillColor = SKColor(red: 0.30, green: 0.31, blue: 0.30, alpha: 1)
        pot.strokeColor = .black.withAlphaComponent(0.45)
        pot.lineWidth = 2
        kitchen.addChild(pot)

        let mother = MemoryCharacter(title: "Ibu Anneth", color: .systemPink)
        mother.position = quest4MotherPosition(from: .zero)
        mother.setScale(0.24)
        mother.zPosition = 2
        kitchen.addChild(mother)

        world.addChild(kitchen)
    }

    func quest4KitchenTablePosition(from house: CGPoint) -> CGPoint {
        CGPoint(x: house.x - 10, y: house.y - 10)
    }

    func quest4MotherPosition(from house: CGPoint) -> CGPoint {
        CGPoint(x: house.x - 34, y: house.y + 10)
    }

    func handleQuest4Interaction(at point: CGPoint) -> Bool {
        guard let house = quest4AnnethHousePosition else { return false }
        let anneth = CGPoint(x: house.x + 26, y: house.y)
        if hypot(point.x - anneth.x, point.y - anneth.y) <= 48 {
            if !quest4.metAnneth {
                approachOrInteract(anneth, message: "Dekati Anneth di dapur belakang.") { [weak self] in
                    self?.startQuest4AnnethDialogue()
                }
            } else if !quest4.sortedTubers && activeQuest4Minigame == nil {
                startQuest4SortingMinigame()
            } else {
                status.text = quest4Objective
            }
            return true
        }

        let table = quest4KitchenTablePosition(from: house)
        if quest4.metAnneth,
           !quest4.sortedTubers,
           hypot(point.x - table.x, point.y - table.y) <= 48 {
            approachOrInteract(table, message: "Dekati meja umbi.") { [weak self] in
                self?.startQuest4SortingMinigame()
            }
            return true
        }

        let mother = quest4MotherPosition(from: house)
        if quest4.sortedTubers,
           !quest4.completed,
           hypot(point.x - mother.x, point.y - mother.y) <= 48 {
            approachOrInteract(mother, message: "Dekati Ibu Anneth.") { [weak self] in
                self?.completeQuest4SaltErrand()
            }
            return true
        }

        return false
    }

    func startQuest4AnnethDialogue() {
        presentQuestDialogue([
            .init(speaker: "Anneth", text: "That pile hasn't been checked."),
            .init(speaker: "Arthur", text: "I was going to check it."),
            .init(speaker: "Anneth", text: "Check it over there. Don't mix it with the ones I've already done.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest4.metAnneth = true
            self.saveQuest4()
            self.rebuild("Sortir umbi di kain bersih Anneth.")
        }
    }

    func startQuest4SortingMinigame() {
        guard quest4.metAnneth,
              !quest4.sortedTubers,
              activeQuest4Minigame == nil else { return }

        route = []
        stick = .zero
        let minigame = ItemSortingMinigameNode(config: ItemSortingConfig(
            requiredItems: 5,
            headingText: "SORTIR UMBI",
            instructionText: "Taruh umbi bersih ke kain. Jangan campur yang belum dicek."
        ))
        minigame.position = CGPoint(x: size.width / 2, y: size.height / 2)
        minigame.zPosition = 3000
        minigame.onComplete = { [weak self] success in
            guard let self, success else { return }
            self.quest4.sortedTubers = true
            self.saveQuest4()
        }
        minigame.onDismiss = { [weak self, weak minigame] in
            guard let self else { return }
            if self.activeQuest4Minigame === minigame { self.activeQuest4Minigame = nil }
            guard self.quest4.sortedTubers else {
                self.rebuild("Sortir umbi belum selesai. Coba lagi di meja Anneth.")
                return
            }
            self.presentQuestDialogue([
                .init(speaker: "Ibu Anneth", text: "Arthur, if you don't have another job waiting, could you fetch some rock salt for me? Just fill this halfway. Not too much, the bag is old."),
                .init(speaker: "Anneth", text: "Halfway, Arthur. Don't fill it to the brim and rip the bag. And take the cart path. Don’t cut through the woods side."),
                .init(speaker: "Arthur", text: "It's longer."),
                .init(speaker: "Anneth", text: "The path is clear. Just stick to the road.")
            ]) { [weak self] in
                self?.completeQuest4SaltErrand()
            }
        }
        activeQuest4Minigame = minigame
        addChild(minigame)
        minigame.start()
    }

    func completeQuest4SaltErrand() {
        guard !quest4.completed else { return }
        quest4.receivedSaltErrand = true
        quest4.completed = true
        let progress = PrologueStore.shared.progress
        progress.storyProgress = max(progress.storyProgress, 5)
        progress.isRockSaltUnlocked = true
        PrologueStore.shared.save()
        saveQuest4()
        rebuild("Quest 4 selesai. Keping Rock Salt terbuka dan Arthur mendapat cloth bag.")
    }
}
