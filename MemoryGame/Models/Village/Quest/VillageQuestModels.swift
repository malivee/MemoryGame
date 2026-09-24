import Foundation

struct VillageQuestDialogueLine {
    let speaker: String
    let text: String
}

struct VillageQuest1Progress: Codable {
    static let saveKey = "village.carto.quest1.v4"

    var spokeToGrandpa = false
    var collectedWater = false
    var spokeToMara = false
    var rackFixed = false
    var returnedHome = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest2Progress: Codable {
    static let saveKey = "village.carto.quest2.v1"

    var spokeToGrandpa = false
    var hasBasket = false
    var metKeneth = false
    var washedHands = false
    var sortedSeeds = false
    var doorWedged = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest3Progress: Codable {
    static let saveKey = "village.carto.quest3.v1"

    var spokeToRoland = false
    var promisedRoland = false
    var stayedSilent = false
    var fenceChecked = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

struct VillageQuest4Progress: Codable {
    static let saveKey = "village.carto.quest4.v1"

    var metAnneth = false
    var sortedTubers = false
    var receivedSaltErrand = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

enum VillageQuestStage: Int, CaseIterable {
    case quest1 = 1
    case quest2
    case quest3
    case quest4
}

struct VillageQuestSnapshot {
    let quest1: VillageQuest1Progress
    let quest2: VillageQuest2Progress
    let quest3: VillageQuest3Progress
    let quest4: VillageQuest4Progress
    let quest6RewardUnlocked: Bool
    let placedBuildingIDs: Set<String>
}

enum VillageQuestPieceRole: Equatable {
    case required
    case reserved(label: String)

    var label: String? {
        switch self {
        case .required:
            return nil
        case .reserved(let label):
            return label
        }
    }
}

struct VillageQuestUnlocks {
    let pieceOrder: [Int]
    let unlockedPieceIDs: Set<Int>
    let unlockedBuildingIDs: Set<String>
    let pieceRoles: [Int: VillageQuestPieceRole]

    func role(forPieceID id: Int) -> VillageQuestPieceRole {
        pieceRoles[id] ?? .required
    }
}

enum VillageQuestCatalog {
    static let pieceOrder = [26, 5, 20, 38, 6, 12, 8]

    enum PieceID {
        static let first = 26
        static let buMaraPath = 5
        static let barnPath = 20
        static let rolandPenPath = 38
        static let annethHousePath = 6
        static let rockSaltPath = 12
        static let hollowForestReward = 8
    }

    enum BuildingID {
        static let arthurHouse = "arthur-house"
        static let villageWell = "village-well"
        static let buMaraHouse = "bu-mara-house"
        static let villageBarn = "village-barn"
        static let rolandPen = "roland-pen"
        static let annethHouse = "anneth-house"
    }
}
