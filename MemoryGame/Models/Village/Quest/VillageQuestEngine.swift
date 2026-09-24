import Foundation

enum VillageQuestEngine {
    static func activeStage(for snapshot: VillageQuestSnapshot) -> VillageQuestStage {
        if !snapshot.quest1.returnedHome { return .quest1 }
        if !snapshot.quest2.completed { return .quest2 }
        if !snapshot.quest3.completed { return .quest3 }
        if !snapshot.quest4.completed { return .quest4 }
        if !snapshot.quest5.completed { return .quest5 }
        if !snapshot.quest7.completed { return .quest7 }
        if !snapshot.quest8.completed { return .quest8 }
        if !snapshot.quest9.completed { return .quest9 }
        return .quest10
    }

    static func unlocks(for snapshot: VillageQuestSnapshot) -> VillageQuestUnlocks {
        if snapshot.quest9.completed {
            let pieces = Set(VillageQuestCatalog.quest10PieceOrder)
            return VillageQuestUnlocks(
                pieceOrder: VillageQuestCatalog.quest10PieceOrder,
                unlockedPieceIDs: pieces,
                unlockedBuildingIDs: [],
                pieceRoles: [:]
            )
        }

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
            pieces.insert(VillageQuestCatalog.PieceID.annethHousePath)
            buildings.insert(VillageQuestCatalog.BuildingID.annethHouse)
        }

        if snapshot.quest5.completed {
            buildings.insert(VillageQuestCatalog.BuildingID.berynHouse)
        }

        if snapshot.quest6RewardUnlocked {
            pieces.insert(VillageQuestCatalog.PieceID.hollowForestReward)
        }

        if snapshot.quest7.completed {
            buildings.insert(VillageQuestCatalog.BuildingID.emptyWarehouse)
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
        case .quest7:
            return quest7Objective(for: snapshot)
        case .quest8:
            return quest8Objective(for: snapshot)
        case .quest9:
            return quest9Objective(for: snapshot)
        case .quest10:
            return quest10Objective(for: snapshot)
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
        if quest.completed { return "Quest 5 selesai: Rumah Kakek Beryn telah terbuka." }
        if quest.deliveredSalt { return "Temui Anak Kecil di persimpangan jalan." }
        if quest.minedSalt { return "Kembali ke Rumah Anneth dan serahkan rock salt ke Ibu Anneth." }
        return snapshot.hasPiece(VillageQuestCatalog.PieceID.rockSaltMinePath)
            ? "Jelajahi ke mulut tambang di keping Rock Salt."
            : "Tempatkan keping Rock Salt (piece 5), lalu Jelajahi ke mulut tambang."
    }

    static func quest7Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest7
        if quest.completed {
            return "Quest 7 selesai: Gudang Kosong (Markas Rahasia) telah terbuka."
        }
        guard snapshot.hasPiece(VillageQuestCatalog.PieceID.hollowForestReward) else {
            return "Tempatkan Keping Hutan (#8) yang didapat dari Quest 6 di papan peta."
        }
        if quest.confrontedGrandpa {
            return "Arthur telah bergegas menemui teman-temannya."
        }
        if quest.foundEliasBook {
            return "Kembali ke Rumah Arthur dan tanyakan isi buku kepada Kakek."
        }
        if quest.hasGatheredWood {
            return "Periksa tanah longsor dan akar pohon tua di dekat lereng hutan."
        }
        if quest.spokeToGrandpa {
            return "Cari dan kumpulkan 5 ranting kayu bakar di lereng hutan (\(quest.woodCollectedCount)/5)."
        }
        return "Bicara dengan Kakek di Rumah Arthur untuk mengambil tugas mencari kayu."
    }

    static func quest8Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest8
        if quest.completed {
            return "Quest 8 selesai: Rombongan Arthur siap menjelajah keluar desa esok fajar."
        }
        if quest.allItemsPacked {
            return quest.returnedToGrandpa
                ? "Quest 8 selesai: Rombongan Arthur siap menjelajah keluar desa esok fajar."
                : "Kembali ke Rumah Kakek untuk beristirahat malam sebelum fajar keberangkatan."
        }
        if quest.annethBackyardMet {
            return "Kumpulkan dan kemas 5 perlengkapan ekspedisi di sekitar halaman Anneth (\(quest.packedCount)/5)."
        }
        if quest.experiencedFog {
            return "Temui Roland, Keneth, dan Anneth di belakang rumah Anneth malam ini."
        }
        if quest.convincingFailed {
            return "Berjalan pulang menyusuri jalan desa di tengah kabut senja."
        }
        if quest.secretBaseMetFriends {
            return "Bicarakan Buku Elias dan yakinkan teman-teman di Gudang Kosong."
        }
        return "Temui Roland, Keneth, dan Anneth di Gudang Kosong dekat sungai (Markas Rahasia)."
    }

    static func quest9Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest9
        if quest.completed { return "Quest 9 selesai: rombongan terperangkap di dalam ilusi Hutan Berkabut." }
        if quest.markedTree { return "Masuki Hutan Berkabut. Tetap dekat dengan tanda Anneth dan jangan lebih dari dua puluh langkah." }
        if quest.inspectedSoil && !quest.heardForestVoices { return "Waktu pencarian habis. Dengarkan suara dari kedalaman hutan." }
        if quest.inspectedBark { return "Periksa bekas tanah basah di bawah akar pohon." }
        if quest.inspectedRock { return "Cari dan periksa sisa kulit kayu di dekat akar." }
        if quest.metPartyAtBoundary { return "Gunakan Investigate Mode: cari batu yang tidak pada tempatnya di lokasi longsor." }
        if quest.stealthStarted { return "Menyelinap ke titik kumpul tanpa masuk ke area pandang Kakek dan warga." }
        return "Keluar rumah saat fajar. Tentukan apakah Arthur akan pamit atau pergi diam-diam."
    }

    static func quest10Objective(for snapshot: VillageQuestSnapshot) -> String {
        let quest = snapshot.quest10
        if quest.completed { return "Quest 10 selesai: tidak ada jalan pulang. Rombongan masuk lebih dalam ke Hutan Dalam." }
        if quest.rolandPulledArthur { return "Roland menarik Arthur lepas. Terus kabur ke celah hutan sebelum The Hollow menyusul lagi." }
        if quest.routeChoiceMade { return "The Hollow mengejar. Gunakan jalur hasil puzzle untuk mencapai celah hutan." }
        if quest.sawIllusion { return "Pilih reaksi Arthur saat jalan pulang menghilang." }
        let placedQuest10Pieces = Set(VillageQuestCatalog.quest10PieceOrder).intersection(snapshot.placedPieceIDs).count
        if placedQuest10Pieces < VillageQuestCatalog.quest10PieceOrder.count {
            return "Semua tile lama hilang. Susun keping O, L, dan I hutan-bukit (\(placedQuest10Pieces)/3), lalu Jelajahi."
        }
        return "Jelajahi peta hutan ilusi. Tidak ada rumah, hanya satu celah jalan."
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
