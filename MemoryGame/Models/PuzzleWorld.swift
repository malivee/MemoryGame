import Foundation

/// Fixed three-piece portals. Art coordinates do not determine the destination.
enum PuzzleWorld: Int, CaseIterable {
    case house, village, hills, boundary

    var pieceIDs: Set<Int> {
        switch self {
        case .house: return [14, 23, 24]
        case .village: return [16, 26, 27]
        case .hills: return [0, 1, 10]
        case .boundary: return [8, 9, 19]
        }
    }
    var title: String {
        switch self {
        case .house: return "Rumah"
        case .village: return "Desa"
        case .hills: return "Bukit"
        case .boundary: return "Batas Desa"
        }
    }
    var entry: MemoryPiece {
        switch self {
        case .house: return .house
        case .village: return .yard
        case .hills: return .oldPath
        case .boundary: return .boundary
        }
    }
    var locations: Set<MemoryPiece> {
        switch self {
        case .house: return [.house]
        case .village: return [.yard, .villageRoad, .garden]
        case .hills: return [.mountain, .oldPath, .dryLake]
        case .boundary: return [.boundary]
        }
    }
    func isUnlocked(in progress: PrologueProgress) -> Bool {
        switch self {
        case .house: return true
        case .village: return progress.hasBook
        case .hills: return progress.hasBook && progress.joined.count == 3
        case .boundary: return progress.hasBook && progress.joined.count == 3 && progress.foundMarker
        }
    }
    static func containing(_ id: Int) -> PuzzleWorld? {
        allCases.first { $0.pieceIDs.contains(id) }
    }
    static var allPieceIDs: Set<Int> {
        allCases.reduce(into: []) { $0.formUnion($1.pieceIDs) }
    }
}
