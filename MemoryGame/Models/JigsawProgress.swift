// Penjelasan file: JigsawProgress.swift
// Mengatur keping utama, varian danau kering, hadiah misi, posisi, dan rotasi keping.
// Keping boleh berada di slot mana pun; minimal tiga keping dengan tonjolan dan cekungan cocok membuka akses eksplorasi.
// Penyelesaian akhir tetap memerlukan foto yang benar. File ini juga menjembatani puzzle dengan progres cerita.

import Foundation
import CoreGraphics

/// Actual photo fragments plus one alternate fragment for the same lake.
/// Story locations remain independent from the physical photo-piece identity.
enum JigsawCatalog {
    static let count = PuzzleCatalog.rows * PuzzleCatalog.columns
    static let boardSlotCount = PuzzleCatalog.boardSlotCount
    static let dryLakeID = count
    static let allIDs = Array(0...dryLakeID)
    static let minimumConnectedPieces = 3
    // An L-shaped opening: house above road, yard immediately to its left.
    static let starterIDs: Set<Int> = PuzzleWorld.house.pieceIDs
    static let bookReward = PuzzleWorld.village.pieceIDs
    static let friendsReward = PuzzleWorld.hills.pieceIDs
    static let markerReward = PuzzleWorld.boundary.pieceIDs
    private static let locationIDs: [MemoryPiece: Int] = [
        .echoesBoundary: 5,
        .house: 14,
        .yard: 23,
        .villageRoad: 24,
        .garden: 27,
        .mountain: 0,
        .oldPath: 1,
        .lake: 10,
        .dryLake: dryLakeID,
        .boundary: 8,
        .closing: 9
    ]

    static func location(for id: Int) -> MemoryPiece {
        if id == dryLakeID { return .dryLake }
        if let location = locationIDs.first(where: { $0.value == id })?.key { return location }
        if let world = PuzzleWorld.containing(id) { return world.entry }
        let row = id / PuzzleCatalog.columns
        let col = id % PuzzleCatalog.columns
        let band = col < 3 ? 0 : (col < 5 ? 1 : 2)
        let index = min(MemoryPiece.main.count - 1, (row / 2) * 3 + band)
        return MemoryPiece.main[index]
    }
    static func primaryID(for location: MemoryPiece) -> Int {
        locationIDs[location] ?? PuzzleWorld.house.pieceIDs.sorted()[0]
    }
    static func data(for id: Int) -> PuzzlePieceData {
        PuzzleCatalog.pieces[id == dryLakeID ? primaryID(for: .lake) : id]
    }
    // Menghitung keping yang diperoleh dari misi, termasuk hadiah yang sudah dimiliki pada save lama.
    static func availableIDs(progress: PrologueProgress) -> Set<Int> {
        var ids = PuzzleWorld.allCases.filter { $0.isUnlocked(in: progress) }
            .reduce(into: Set<Int>()) { $0.formUnion($1.pieceIDs) }
        ids.formUnion(StoryProgression.unlockedPieceIDs(for: progress))
        return ids
    }
    static func legacyAvailableIDs(progress: PrologueProgress) -> Set<Int> {
        Set(allIDs.filter { id in
            let location = location(for: id)
            guard progress.discovered.contains(location) else { return false }
            if [.house, .yard, .villageRoad].contains(location), !progress.hasBook {
                return starterIDs.contains(id)
            }
            return true
        })
    }
    // Clockwise edge order: top, right, bottom, left. 0 = flat, +/-1 = tab/socket.
    static func edges(for id: Int, turns: Int = 0) -> [Int] {
        let data = data(for: id)
        let row = data.row - 1, col = data.col - 1
        let sign = (row + col).isMultiple(of: 2) ? 1 : -1
        let original = [row == 0 ? 0 : sign, col == PuzzleCatalog.columns - 1 ? 0 : sign,
                        row == PuzzleCatalog.rows - 1 ? 0 : sign, col == 0 ? 0 : sign]
        let rotation = ((turns % 4) + 4) % 4
        return (0..<4).map { original[($0 - rotation + 4) % 4] }
    }
    // Exploration accepts any earned fragment in any board cell, in any rotation.
    // Hanya memeriksa ID dan batas papan; isi foto, bentuk tepi, serta rotasi tidak membatasi drop.
    static func canPlace(_ id: Int, at slot: Int) -> Bool {
        allIDs.contains(id) && (0..<boardSlotCount).contains(slot)
    }
    // Memeriksa kecocokan bentuk geometris untuk kompatibilitas lama; bukan syarat peletakan bebas saat ini.
    static func fits(_ id: Int, at slot: Int, turns: Int) -> Bool {
        guard allIDs.contains(id), (0..<boardSlotCount).contains(slot) else { return false }
        // The photo's aspect ratio gives rectangular cells. A quarter-turn has
        // different dimensions; a half-turn can fit if the physical edges match.
        if turns % 2 != 0 && abs(PuzzleCatalog.cellWidth - PuzzleCatalog.cellHeight) > 0.01 { return false }
        return edges(for: id, turns: turns) == edges(for: slot)
    }
}

struct JigsawPlacement: Codable, Equatable {
    let id: Int
    let turns: Int
}

struct JigsawProgress: Codable {
    // Keep retired layouts from older saves without exposing locked pieces.
    var archivedPlacements: [Int: JigsawPlacement]?
    var connectionRulesVersion: Int?
    var legacyGrantedIDs: Set<Int>?
    var placements: [Int: JigsawPlacement] = [:]
    var rotations: [Int: Int] = [:]
    var locationDrivers: [MemoryPiece: Int] = [:]

    // Sambungan harus mengikuti tetangga pada foto sumber; posisi seluruh rangkaian di papan bebas.
    // Bentuk tepi cocok saja tidak cukup: isi foto dan orientasi juga harus benar.
    func interlocks(from slot: Int, to neighbor: Int) -> Bool {
        guard (0..<JigsawCatalog.boardSlotCount).contains(slot), (0..<JigsawCatalog.boardSlotCount).contains(neighbor),
              let first = placements[slot], let second = placements[neighbor],
              JigsawCatalog.allIDs.contains(first.id), JigsawCatalog.allIDs.contains(second.id) else { return false }
        // Gambar harus tegak dan menyambung, bukan hanya memiliki bentuk tepi serupa.
        guard first.turns % 4 == 0, second.turns % 4 == 0 else { return false }
        let firstPhoto = JigsawCatalog.data(for: first.id)
        let secondPhoto = JigsawCatalog.data(for: second.id)
        let boardRowDelta = neighbor / PuzzleCatalog.boardColumns - slot / PuzzleCatalog.boardColumns
        let boardColDelta = neighbor % PuzzleCatalog.boardColumns - slot % PuzzleCatalog.boardColumns
        guard secondPhoto.row - firstPhoto.row == boardRowDelta,
              secondPhoto.col - firstPhoto.col == boardColDelta else { return false }
        let direction: Int
        if neighbor == slot - PuzzleCatalog.boardColumns { direction = 0 }
        else if neighbor == slot + 1 && slot % PuzzleCatalog.boardColumns < PuzzleCatalog.boardColumns - 1 { direction = 1 }
        else if neighbor == slot + PuzzleCatalog.boardColumns { direction = 2 }
        else if neighbor == slot - 1 && slot % PuzzleCatalog.boardColumns > 0 { direction = 3 }
        else { return false }
        let edge = JigsawCatalog.edges(for: first.id, turns: first.turns)[direction]
        let opposite = JigsawCatalog.edges(for: second.id, turns: second.turns)[(direction + 2) % 4]
        return edge != 0 && edge == -opposite
    }

    /// Connected means correctly ordered upright photo neighbors with matching edges, not merely discovered
    /// or belonging to the same location. Separate components unlock independently.
    // Menelusuri slot bertetangga lewat sisi; diagonal dan sambungan melintasi ujung baris tidak dihitung.
    func connectedIDs(to id: Int) -> Set<Int> {
        guard let start = placements.first(where: { $0.value.id == id })?.key,
              let seed = placements[start], JigsawCatalog.canPlace(seed.id, at: start) else { return [] }
        var visited: Set<Int> = [start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let slot = queue[head]; head += 1
            let column = slot % PuzzleCatalog.boardColumns
            let neighbors = [column > 0 ? slot - 1 : -1,
                             column < PuzzleCatalog.boardColumns - 1 ? slot + 1 : -1,
                             slot - PuzzleCatalog.boardColumns, slot + PuzzleCatalog.boardColumns]
            for neighbor in neighbors where (0..<JigsawCatalog.boardSlotCount).contains(neighbor) && !visited.contains(neighbor) {
                guard let neighborPiece = placements[neighbor],
                      PuzzleWorld.containing(neighborPiece.id) == PuzzleWorld.containing(id),
                      interlocks(from: slot, to: neighbor) else { continue }
                visited.insert(neighbor); queue.append(neighbor)
            }
        }
        return Set(visited.compactMap { placements[$0]?.id })
    }
    // Membuka akses hanya jika kelompok keping terpilih berisi setidaknya tiga keping.
    func canEnter(_ id: Int) -> Bool {
        guard let world = PuzzleWorld.containing(id) else { return false }
        return world.pieceIDs.isSubset(of: connectedIDs(to: id))
    }

    // Semua keping dalam satu kelompok menghasilkan kumpulan lokasi dan pintu masuk yang sama.
    func worldLocations(for id: Int) -> Set<MemoryPiece> {
        guard canEnter(id) else { return [] }
        return PuzzleWorld.containing(id)?.locations ?? []
    }
    func worldEntry(for id: Int, progress: PrologueProgress) -> MemoryPiece? {
        guard let world = PuzzleWorld.containing(id), world.isUnlocked(in: progress), canEnter(id) else { return nil }
        return world.entry
    }

    var installedIDs: Set<Int> { Set(placements.values.map(\.id)) }
    var solved: Bool {
        PuzzleWorld.allCases.allSatisfy { world in
            world.pieceIDs.first.map { canEnter($0) } ?? false
        }
    }
    func inventory(progress: PrologueProgress) -> [Int] {
        // Deterministic shuffle rather than revealing the order of the final photo.
        JigsawCatalog.availableIDs(progress: progress).subtracting(installedIDs).sorted {
            (($0 * 29 + 17) % 53) < (($1 * 29 + 17) % 53)
        }
    }
    @discardableResult
    // Memasang keping yang tersedia, memindahkannya dari slot lama, dan menangani penggantian varian danau.
    mutating func place(_ id: Int, at slot: Int, available: Set<Int>) -> Bool {
        let turns = rotations[id] ?? 0
        guard available.contains(id), JigsawCatalog.canPlace(id, at: slot) else { return false }
        let location = JigsawCatalog.location(for: id)
        placements = placements.filter { _, placement in
            if placement.id == id { return false }
            let other = JigsawCatalog.location(for: placement.id)
            if location == .dryLake && other == .lake { return false }
            if location == .lake && other == .dryLake { return false }
            return true
        }
        placements[slot] = JigsawPlacement(id: id, turns: turns)
        locationDrivers[location] = id
        return true
    }
    mutating func remove(_ id: Int) { placements = placements.filter { $0.value.id != id } }
    // Memutar keping 90 derajat sambil mempertahankan slot jika sudah berada di papan.
    mutating func rotate(_ id: Int) {
        let turns = ((rotations[id] ?? 0) + 1) % 4
        rotations[id] = turns
        locationDrivers[JigsawCatalog.location(for: id)] = id
        if let slot = placements.first(where: { $0.value.id == id })?.key {
            placements[slot] = JigsawPlacement(id: id, turns: turns)
        }
    }
}

extension PrologueProgress {
    @discardableResult
    // Menghitung keping tersedia sebelum mengubah jigsaw agar pembacaan dan mutasi tidak memicu crash eksklusivitas Swift.
    func placeJigsawPiece(_ id: Int, at slot: Int) -> Bool {
        // Resolve rewards before beginning exclusive mutation of jigsaw.
        // availableIDs also reads jigsaw to preserve rewards from older saves.
        let available = JigsawCatalog.availableIDs(progress: self)
        return jigsaw?.place(id, at: slot, available: available) ?? false
    }

    // Menyiapkan state baru atau memigrasikan save lama tanpa menghapus progres cerita.
    func prepareJigsaw() {
        if var existing = jigsaw {
            if existing.connectionRulesVersion == nil {
                if hasBook {
                    existing.legacyGrantedIDs = JigsawCatalog.legacyAvailableIDs(progress: self)
                } else {
                    // Old starters were all sockets, so they could not form one
                    // connected cluster. Swap only these unearned opening pieces.
                    for (oldID, newID) in [13: 14, 20: 23, 21: 24, 29: 14, 35: 23, 36: 23, 37: 24] {
                        existing.rotations[newID] = existing.rotations.removeValue(forKey: oldID) ?? 0
                        if let slot = existing.placements.first(where: { $0.value.id == oldID })?.key {
                            existing.placements.removeValue(forKey: slot)
                            let turns = existing.rotations[newID] ?? 0
                            if JigsawCatalog.fits(newID, at: slot, turns: turns) {
                                existing.placements[slot] = JigsawPlacement(id: newID, turns: turns)
                            }
                        }
                    }
                }
                existing.connectionRulesVersion = 1
            }
            let available = JigsawCatalog.availableIDs(progress: self)
            let retired = existing.placements.filter { !available.contains($0.value.id) }
            if !retired.isEmpty {
                var archive = existing.archivedPlacements ?? [:]
                archive.merge(retired) { original, _ in original }
                existing.archivedPlacements = archive
                existing.placements = existing.placements.filter { available.contains($0.value.id) }
            }
            jigsaw = existing
            synchronizeJigsaw()
            return
        }
        var state = JigsawProgress()
        state.connectionRulesVersion = 1
        if hasBook { state.legacyGrantedIDs = JigsawCatalog.legacyAvailableIDs(progress: self) }
        for location in [MemoryPiece.house, .yard, .villageRoad] {
            state.rotations[JigsawCatalog.primaryID(for: location)] = rotations[location] ?? 0
        }
        if assembled && leftVillage {
            for id in PuzzleWorld.allPieceIDs { state.placements[id] = JigsawPlacement(id: id, turns: 0) }
        } else {
            // Upgrade the previous nine-tile save without erasing story progress.
            // Each installed location becomes one matching fragment in the new grid.
            for old in placements.values {
                let id = JigsawCatalog.primaryID(for: old.piece)
                let slot = old.piece == .dryLake ? JigsawCatalog.primaryID(for: .lake) : id
                let turns = JigsawCatalog.fits(id, at: slot, turns: old.turns) ? old.turns : 0
                state.rotations[id] = turns
                state.placements[slot] = JigsawPlacement(id: id, turns: turns)
                state.locationDrivers[old.piece] = id
            }
        }
        jigsaw = state
        prepareJigsaw()
    }
    // Menerjemahkan kelompok keping yang bisa dimasuki menjadi lokasi terbuka dan status penyelesaian cerita.
    func synchronizeJigsaw() {
        guard let jigsaw else { return }
        placements.removeAll()
        for world in PuzzleWorld.allCases where world.isUnlocked(in: self) {
            guard let id = world.pieceIDs.first, jigsaw.canEnter(id) else { continue }
            for location in world.locations {
                placements[location.slot] = PhotoPlacement(piece: location, turns: 0)
                rotations[location] = 0
            }
        }
        assembled = leftVillage && jigsaw.solved
    }
}

extension JigsawProgress {
    /// Connected groups eligible for a portal label, independent of scene layout.
    var enterableGroups: [Set<Int>] {
        var visited: Set<Int> = []
        var result: [Set<Int>] = []
        for id in installedIDs.sorted() where !visited.contains(id) {
            let group = connectedIDs(to: id)
            visited.formUnion(group)
            if group.count >= JigsawCatalog.minimumConnectedPieces { result.append(group) }
        }
        return result
    }
}
