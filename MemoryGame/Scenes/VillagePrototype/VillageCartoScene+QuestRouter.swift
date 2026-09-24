// Titik sambung kecil antara scene bersama dan file quest terpisah.
// Tambahkan Quest 3+ di sini; implementasi quest tetap berada di file masing-masing.
import CoreGraphics

extension VillageCartoScene {
    var villageQuestSnapshot: VillageQuestSnapshot {
        VillageQuestSnapshot(
            quest1: quest1,
            quest2: quest2,
            quest3: quest3,
            quest4: quest4,
            quest5: quest5,
            quest7: quest7,
            placedPieceIDs: Set(layout.placements.map(\.id)),
            quest6RewardUnlocked: PrologueStore.shared.progress.metBerynAfterHerbal,
            placedBuildingIDs: Set(layout.buildingPlacements.map(\.id))
        )
    }

    var villageQuestUnlocks: VillageQuestUnlocks {
        VillageQuestEngine.unlocks(for: villageQuestSnapshot)
    }

    var villageQuestPieceOrder: [Int] { villageQuestUnlocks.pieceOrder }

    var villageUnlockedPieceIDs: Set<Int> { villageQuestUnlocks.unlockedPieceIDs }

    var villageUnlockedBuildingIDs: Set<String> { villageQuestUnlocks.unlockedBuildingIDs }

    var villageQuestObjective: String {
        VillageQuestEngine.objective(for: villageQuestSnapshot)
    }

    func renderVillageQuestWorld() {
        if !quest1.returnedHome {
            renderQuest1World()
        } else if !quest2.completed {
            renderQuest2World()
        } else if !quest3.completed {
            renderQuest3World()
        } else if !quest4.completed {
            renderQuest4World()
        } else if !quest5.completed {
            renderQuest5World()
        } else {
            renderQuest7World()
        }
    }

    func handleVillageQuestInteraction(at point: CGPoint) -> Bool {
        if !quest1.returnedHome { return handleQuest1Interaction(at: point) }
        if !quest2.completed { return handleQuest2Interaction(at: point) }
        if !quest3.completed { return handleQuest3Interaction(at: point) }
        if !quest4.completed { return handleQuest4Interaction(at: point) }
        if !quest5.completed { return handleQuest5Interaction(at: point) }
        return handleQuest7Interaction(at: point)
    }
}
