import Foundation

/// Shared puzzle commands. No nodes, gestures, or storage APIs belong here.
struct PuzzleSession {
    let progress: PrologueProgress

    @discardableResult
    func place(_ id: Int, at slot: Int) -> Bool {
        if let occupant = progress.jigsaw?.placements[slot], occupant.id != id { return false }
        return progress.placeJigsawPiece(id, at: slot)
    }

    func remove(_ id: Int) { progress.jigsaw?.remove(id) }

    func rotate(_ id: Int, quarterTurns: Int = 1) {
        guard JigsawCatalog.availableIDs(progress: progress).contains(id) else { return }
        let turns = ((quarterTurns % 4) + 4) % 4
        for _ in 0..<turns { progress.jigsaw?.rotate(id) }
    }

    func synchronize() { progress.synchronizeJigsaw() }
}
