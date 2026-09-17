import Foundation

/// Inventory is a projection of saved progression, so old saves keep their
/// items and placing a fragment cannot duplicate it in the bag.
enum BagItem: Equatable {
    case book
    case fragment(Int)

    var title: String {
        switch self {
        case .book: return "Buku lama"
        case .fragment(let id): return "Keping \(JigsawCatalog.location(for: id).title)"
        }
    }
    var category: String {
        switch self {
        case .book: return "ITEM CERITA"
        case .fragment: return "KEPING KENANGAN"
        }
    }
    var detail: String {
        switch self {
        case .book: return "Manuskrip tua yang ditemukan Arthur di rumah. Buka untuk membaca halaman-halamannya."
        case .fragment: return "Bagian dari foto kenangan. Pilih keping ini di papan puzzle untuk menyusun foto atau membuka lokasi."
        }
    }
}

struct BagInventory {
    static let slotsPerPage = 30
    let items: [BagItem]
    init(progress: PrologueProgress) {
        items = (progress.hasBook ? [.book] : []) +
            (progress.jigsaw ?? JigsawProgress()).inventory(progress: progress).map(BagItem.fragment)
    }
    var pageCount: Int { max(1, (items.count + Self.slotsPerPage - 1) / Self.slotsPerPage) }
    func items(on page: Int) -> [BagItem] {
        guard (0..<pageCount).contains(page) else { return [] }
        return Array(items.dropFirst(page * Self.slotsPerPage).prefix(Self.slotsPerPage))
    }
}
