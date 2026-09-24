// Titik sambung kecil antara scene bersama dan file quest terpisah.
// Tambahkan Quest 3+ di sini; implementasi quest tetap berada di file masing-masing.
import CoreGraphics

extension VillageCartoScene {
    var villageQuestPieceOrder: [Int] { [26, 5, 20, 38, 6, 12] }

    var villageUnlockedPieceIDs: Set<Int> {
        var result = quest1UnlockedPieceIDs
        // Keping Z (#3) dipakai untuk membangun area lumbung.
        if quest2.spokeToGrandpa { result.insert(20) }
        // Hadiah akhir Quest 2 membuka keping menuju peternakan.
        if quest2.completed { result.insert(38) }
        // Hadiah Quest 3 membuka keping L siku untuk Rumah Anneth.
        if quest3.completed { result.insert(6) }
        // Milestone Quest 4 membuka biome Rock Salt.
        if quest4.completed { result.insert(12) }
        return result
    }

    var villageUnlockedBuildingIDs: Set<String> {
        var result = quest1UnlockedBuildingIDs
        if quest1.returnedHome && quest2.spokeToGrandpa {
            result.insert("village-barn")
        }
        if quest2.completed {
            result.insert("roland-pen")
        }
        if quest3.completed {
            result.insert("anneth-house")
        }
        return result
    }

    var villageQuestObjective: String {
        if !quest1.returnedHome { return quest1Objective }
        if !quest2.completed { return quest2Objective }
        if !quest3.completed { return quest3Objective }
        return quest4Objective
    }

    func renderVillageQuestWorld() {
        if !quest1.returnedHome {
            renderQuest1World()
        } else if !quest2.completed {
            renderQuest2World()
        } else if !quest3.completed {
            renderQuest3World()
        } else {
            renderQuest4World()
        }
    }

    func handleVillageQuestInteraction(at point: CGPoint) -> Bool {
        if !quest1.returnedHome { return handleQuest1Interaction(at: point) }
        if !quest2.completed { return handleQuest2Interaction(at: point) }
        if !quest3.completed { return handleQuest3Interaction(at: point) }
        return handleQuest4Interaction(at: point)
    }
}
