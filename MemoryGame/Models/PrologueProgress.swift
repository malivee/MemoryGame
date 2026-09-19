// Penjelasan file: PrologueProgress.swift
// Menyimpan progres cerita: buku, teman yang bergabung, penanda jalan, dan keberangkatan kelompok.
// Model lokasi lama dipertahankan untuk kompatibilitas dan menjadi hasil sinkronisasi puzzle 10x4.
// Persistence lives in Services/PrologueStore.swift.

import Foundation

enum MemoryPiece: String, CaseIterable, Codable {
    case mountain, oldPath, boundary, lake, garden, house, closing, yard, villageRoad, dryLake, echoesBoundary

    static let main: [MemoryPiece] = [.mountain, .oldPath, .boundary, .lake, .garden, .house, .closing, .yard, .villageRoad]
    var slot: Int {
        if self == .echoesBoundary { return 9 }
        return self == .dryLake ? 3 : Self.main.firstIndex(of: self)!
    }
    var title: String {
        switch self {
        case .mountain: return "Pegunungan"
        case .oldPath: return "Jalur lama"
        case .boundary: return "Batas desa"
        case .lake: return "Danau"
        case .garden: return "Kebun"
        case .house: return "Rumah"
        case .closing: return "Penutup foto"
        case .yard: return "Halaman"
        case .villageRoad: return "Jalan desa"
        case .dryLake: return "Cekungan kering"
        case .echoesBoundary: return "Zona Bahaya"
        }
    }
    var region: MemoryRegion {
        switch self {
        case .house: return .house
        case .yard, .villageRoad, .garden: return .village
        case .echoesBoundary: return .echoes
        default: return .foothills
        }
    }
    var location: MemoryPiece { self == .dryLake ? .lake : self }
}

enum MemoryRegion: String, Codable { case house, village, foothills, echoes }
enum FriendID: String, CaseIterable, Codable { case keneth = "Keneth", roland = "Roland", anneth = "Anneth" }

struct PhotoPlacement: Codable, Equatable {
    let piece: MemoryPiece
    var turns: Int
}

/// Story progress is independent of scene lifetime, catches, and photo placement.
final class PrologueProgress: Codable {
    var jigsaw: JigsawProgress?
    var discovered: Set<MemoryPiece> = [.house, .yard, .villageRoad]
    var placements: [Int: PhotoPlacement] = [:]
    var rotations: [MemoryPiece: Int] = [.house: 1, .yard: 0, .villageRoad: 3]
    var hasBook = false
    var shownBook: Set<FriendID> = []
    var joined: Set<FriendID> = []
    var foundMarker = false
    var groupGathered = false
    var leftVillage = false
    var noticedChangedRoute = false
    var assembled = false

    var inventory: [MemoryPiece] {
        MemoryPiece.allCases.filter { piece in
            discovered.contains(piece) && !placements.values.contains { $0.piece == piece }
        }
    }
    var objective: String {
        if assembled { return "Kenangan tersusun" }
        if !hasBook {
            if let jigsaw, !jigsaw.placements.values.contains(where: { JigsawCatalog.location(for: $0.id) == .house && jigsaw.canEnter($0.id) }) {
                return "Susun 3 keping Rumah sesuai gambar untuk membuka map pertama."
            }
            return "Masuk ke rumah dan temukan buku lama."
        }
        if joined.count < 3 {
            return installed(.yard) ? "Desa: tunjukkan buku kepada ketiga teman (\(joined.count)/3)." : "3 keping Desa terbuka! Susun untuk masuk ke map berikutnya."
        }
        if !foundMarker {
            return installed(.oldPath) ? "Bukit: cari dan baca penanda jalan." : "3 keping Bukit terbuka! Susun untuk mencari penanda jalan."
        }
        if !leftVillage {
            return installed(.boundary) ? "Batas Desa: berkumpul, lalu keluar bersama keempat anak." : "3 keping Batas Desa terbuka! Susun untuk melanjutkan perjalanan."
        }
        return "Lengkapi keempat rangkaian map, masing-masing 3 keping."
    }
    func placement(of piece: MemoryPiece) -> PhotoPlacement? {
        placements.values.first { $0.piece == piece }
    }
    func installed(_ piece: MemoryPiece) -> Bool { placement(of: piece) != nil }
    var lakeVariant: MemoryPiece? {
        if installed(.dryLake) { return .dryLake }
        return installed(.lake) ? .lake : nil
    }
    func rotate(_ piece: MemoryPiece) {
        let turns = ((rotations[piece] ?? 0) + 1) % 4
        rotations[piece] = turns
        if let slot = placements.first(where: { $0.value.piece == piece })?.key {
            placements[slot]?.turns = turns
        }
        assembled = false
    }
    func remove(_ piece: MemoryPiece) {
        placements = placements.filter { $0.value.piece != piece }
        assembled = false
    }
    func place(_ piece: MemoryPiece, at slot: Int) {
        guard discovered.contains(piece), (0..<9).contains(slot) else { return }
        // All straight tile edges are compatible. Content/orientation is never rejected.
        // The two lake states describe ONE location, so only one can be active.
        placements = placements.filter { $0.value.piece.location != piece.location }
        placements[slot] = PhotoPlacement(piece: piece, turns: rotations[piece] ?? 0)
        assembled = false
    }
    // Menandai buku ditemukan dan memberikan hadiah lokasi satu kali.
    func readBook() {
        guard !hasBook else { return }
        hasBook = true
        discovered.formUnion([.garden, .mountain, .dryLake])
    }
    // Mencatat teman yang bergabung dan membuka hadiah ketika ketiga teman sudah setuju.
    func finishConversation(with friend: FriendID) {
        guard hasBook else { return }
        shownBook.insert(friend)
        joined.insert(friend)
        if joined.count == 3 { discovered.formUnion([.lake, .oldPath]) }
    }
    // Membuka batas desa setelah semua teman bergabung dan penanda ditemukan.
    func readMarker() {
        guard joined.count == 3, !foundMarker else { return }
        foundMarker = true
        discovered.insert(.boundary)
    }
    // Melanjutkan cerita hanya setelah kelompok berkumpul dan keempat nama hadir di titik keluar.
    func leaveVillage(childrenAtExit: Set<String>) {
        let required: Set<String> = ["Arthur", "Keneth", "Roland", "Anneth"]
        guard foundMarker, groupGathered, required.isSubset(of: childrenAtExit), !leftVillage else { return }
        leftVillage = true
        discovered.insert(.closing)
    }
    var correctlyAssembled: Bool {
        if let jigsaw { return leftVillage && jigsaw.solved }
        return leftVillage && MemoryPiece.main.enumerated().allSatisfy { slot, piece in
            placements[slot] == PhotoPlacement(piece: piece, turns: 0)
        }
    }
}
