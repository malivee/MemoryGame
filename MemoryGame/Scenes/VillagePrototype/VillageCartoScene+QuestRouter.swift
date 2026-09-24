// Titik sambung kecil antara scene bersama dan file quest terpisah.
// Tambahkan Quest 3+ di sini; implementasi quest tetap berada di file masing-masing.
import CoreGraphics

extension VillageCartoScene {
    var villageQuestPieceOrder: [Int] { [26, 5, 20, 38] }

    var villageUnlockedPieceIDs: Set<Int> {
        var result = quest1UnlockedPieceIDs
        // Keping Z (#3) dipakai untuk membangun area lumbung.
        if quest2.spokeToGrandpa { result.insert(20) }
        // Hadiah akhir Quest 2 membuka keping berikutnya menuju peternakan.
        if quest2.completed { result.insert(38) }
        return result
    }

    var villageUnlockedBuildingIDs: Set<String> {
        var result = quest1UnlockedBuildingIDs
        if quest1.returnedHome && quest2.spokeToGrandpa {
            result.insert("village-barn")
        }
        return result
    }

    var villageQuestObjective: String {
        quest1.returnedHome ? quest2Objective : quest1Objective
    }

    func renderVillageQuestWorld() {
        if quest1.returnedHome {
            renderQuest2World()
        } else {
            renderQuest1World()
        }
    }

    func handleVillageQuestInteraction(at point: CGPoint) -> Bool {
        quest1.returnedHome
            ? handleQuest2Interaction(at: point)
            : handleQuest1Interaction(at: point)
    }
}
