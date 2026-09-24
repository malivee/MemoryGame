import Foundation

enum VillageQuestEngine {
    static func activeStage(for snapshot: VillageQuestSnapshot) -> VillageQuestStage {
        if !snapshot.quest1.returnedHome { return .quest1 }
        if !snapshot.quest2.completed { return .quest2 }
        if !snapshot.quest3.completed { return .quest3 }
        if !snapshot.quest4.completed { return .quest4 }
        return .quest5
    }

    static func unlocks(for snapshot: VillageQuestSnapshot) -> VillageQuestUnlocks {
        var pieces: Set<Int> = [VillageQuestCatalog.PieceID.first]
        var buildings: Set<String> = [
            VillageQuestCatalog.BuildingID.arthurHouse,
            VillageQuestCatalog.BuildingID.villageWell
        ]

        if snapshot.quest1.collectedWater {
            pieces.insert(VillageQuestCatalog.PieceID.buMaraPath)
            buildings.insert(VillageQuestCatalog.BuildingID.buMaraHouse)
        }

        if snapshot.quest1.returnedHome {
            pieces.insert(VillageQuestCatalog.PieceID.barnPath)
        }

        if snapshot.quest1.returnedHome && snapshot.quest2.spokeToGrandpa {
            buildings.insert(VillageQuestCatalog.BuildingID.villageBarn)
        }

        if snapshot.quest2.completed {
            pieces.insert(VillageQuestCatalog.PieceID.rolandPenPath)
            buildings.insert(VillageQuestCatalog.BuildingID.rolandPen)
        }

        if snapshot.quest3.completed {
            pieces.insert(VillageQuestCatalog.PieceID.rockSaltMinePath)
            buildings.insert(VillageQuestCatalog.BuildingID.annethHouse)
        }

        if snapshot.quest5.completed {
            pieces.insert(VillageQuestCatalog.PieceID.futurePath)
            buildings.insert(VillageQuestCatalog.BuildingID.berynHouse)
        }

        return VillageQuestUnlocks(
            pieceOrder: VillageQuestCatalog.pieceOrder,
            unlockedPieceIDs: pieces,
            unlockedBuildingIDs: buildings,
            pieceRoles: pieceRoles(for: snapshot)
        )
    }

    static func pieceRole(forPieceID id: Int, snapshot: VillageQuestSnapshot) -> VillageQuestPieceRole {
        pieceRoles(for: snapshot)[id] ?? .required
    }

    private static func pieceRoles(for snapshot: VillageQuestSnapshot) -> [Int: VillageQuestPieceRole] {
        var roles: [Int: VillageQuestPieceRole] = [:]
        if !snapshot.quest4.completed {
            roles[VillageQuestCatalog.PieceID.rockSaltMinePath] = .reserved(label: "Pengecoh")
        }
        if !snapshot.quest5.completed {
            roles[VillageQuestCatalog.PieceID.futurePath] = .reserved(label: "Pengecoh")
        }
        return roles
    }

    static func objective(for snapshot: VillageQuestSnapshot) -> String {
        switch activeStage(for: snapshot) {
        case .quest1:
            return quest1Objective(for: snapshot)
        case .quest2:
            return quest2Objective(for: snapshot)
        case .quest3:
            return quest3Objective(for: snapshot)
        case .quest4:
            return quest4Objective(for: snapshot)
        case .quest5:
            return quest5Objective(for: snapshot)
        }
    }

    static func quest1Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest1
        if quest.returnedHome { return "Quest 1 selesai: Arthur telah kembali ke rumah." }
        if quest.rackFixed {
            return snapshot.hasBuilding(VillageQuestCatalog.BuildingID.arthurHouse)
                ? "Kembali ke Rumah Arthur dan bicara dengan Kakek."
                : "Tempatkan Rumah Arthur, lalu kembali menemui Kakek."
        }
        if quest.spokeToMara { return "Dekati rak miring lalu ketuk [Interact: Periksa Rak]." }
        if quest.collectedWater {
            return snapshot.hasBuilding(VillageQuestCatalog.BuildingID.buMaraHouse)
                ? "Temui Bu Mara di depan rumahnya."
                : "Keping kedua dan Rumah Bu Mara terbuka. Tempatkan Rumah Bu Mara (6x6) di area kuning."
        }
        if quest.spokeToGrandpa {
            return snapshot.hasBuilding(VillageQuestCatalog.BuildingID.villageWell)
                ? "Dekati Sumur dan ambil air."
                : "Tempatkan Sumur (3x3) di area kuning keping awal."
        }
        let hasArthur = snapshot.hasBuilding(VillageQuestCatalog.BuildingID.arthurHouse)
        let hasWell = snapshot.hasBuilding(VillageQuestCatalog.BuildingID.villageWell)
        if hasArthur && hasWell {
            return "Jelajahi dan bicara dengan Kakek di Rumah Arthur."
        }
        return "Tempatkan Rumah Arthur dan Sumur di area kuning keping awal."
    }

    static func quest2Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest2
        if quest.completed {
            return "Quest 2 selesai: keping menuju peternakan dan jalur Rock Salt telah terbuka."
        }
        if quest.sortedSeeds {
            return "Selesaikan percakapan dengan Keneth."
        }
        if quest.washedHands {
            return "Goyangkan perangkat untuk memisahkan gandum dan biji hitam."
        }
        if quest.metKeneth {
            return "Cuci tangan menggunakan ember di pojok lumbung."
        }
        if quest.hasBasket {
            return snapshot.hasBuilding(VillageQuestCatalog.BuildingID.villageBarn)
                ? "Temui Keneth di Lumbung Desa dan berikan keranjang."
                : "Tempatkan Lumbung Desa (9x15) di area kuning."
        }
        if quest.spokeToGrandpa {
            return snapshot.hasBuilding(VillageQuestCatalog.BuildingID.buMaraHouse)
                ? "Temui Bu Mara untuk mengambil keranjang tampah."
                : "Tempatkan kembali Rumah Bu Mara untuk mengambil keranjang."
        }
        return "Bicara dengan Kakek di Rumah Arthur untuk membuka Lumbung Desa."
    }

    static func quest3Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest3
        if quest.completed { return "Quest 3 selesai: keping Rumah Anneth telah terbuka." }
        if quest.fenceChecked { return "Selesaikan percakapan dengan Roland." }
        if quest.spokeToRoland { return "Ketuk pagar kandang untuk membantu Roland mengecek tiangnya." }
        return snapshot.hasBuilding(VillageQuestCatalog.BuildingID.rolandPen)
            ? "Jelajahi dan bicara dengan Roland di Kandang."
            : "Tempatkan Kandang Roland (12x9), lalu Jelajahi."
    }

    static func quest4Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest4
        if quest.completed { return "Quest 4 selesai: misi Rock Salt telah diterima." }
        if quest.sortedTubers { return "Dengarkan misi garam dari Ibu Anneth." }
        if quest.metAnneth { return "Selesaikan sortir umbi di dapur belakang Anneth." }
        return snapshot.hasBuilding(VillageQuestCatalog.BuildingID.annethHouse)
            ? "Jelajahi dan temui Anneth di dapur belakang."
            : "Tempatkan Rumah Anneth (6x9), lalu Jelajahi."
    }

    static func quest5Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest5
        if quest.completed { return "Quest 5 selesai: keping hutan T dan Rumah Kakek Beryn telah terbuka." }
        if quest.deliveredSalt { return "Temui Anak Kecil di persimpangan jalan." }
        if quest.minedSalt { return "Kembali ke Rumah Anneth dan serahkan rock salt ke Ibu Anneth." }
        return snapshot.hasPiece(VillageQuestCatalog.PieceID.rockSaltMinePath)
            ? "Jelajahi ke mulut tambang di keping Rock Salt."
            : "Tempatkan keping Rock Salt (piece 5), lalu Jelajahi ke mulut tambang."
    }
}

private extension VillageQuestSnapshot {
    func hasBuilding(_ id: String) -> Bool {
        placedBuildingIDs.contains(id)
    }

    func hasPiece(_ id: Int) -> Bool {
        placedPieceIDs.contains(id)
    }
}
