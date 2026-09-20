import Foundation
import CoreGraphics

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
    checks += 1
}

let progress = PrologueProgress()
progress.prepareJigsaw()
let session = PuzzleSession(progress: progress)
let starters = PuzzleWorld.house.pieceIDs.sorted()
expect(JigsawCatalog.availableIDs(progress: progress) == Set(starters), "Only house pieces start unlocked")
expect(!session.place(16, at: 16), "Locked pieces cannot be placed")
expect(!session.place(starters[0], at: JigsawCatalog.boardSlotCount), "Out-of-bounds placement is rejected")
func photoSlot(_ id: Int) -> Int {
    (id / PuzzleCatalog.columns) * PuzzleCatalog.boardColumns + (id % PuzzleCatalog.columns)
}
for id in starters {
    session.rotate(id, quarterTurns: -(progress.jigsaw?.rotations[id] ?? 0))
    expect(session.place(id, at: photoSlot(id)), "Starter can occupy its photo slot")
}
session.synchronize()
expect(progress.installed(.house), "Three connected upright pieces open the house")
expect(progress.jigsaw?.worldEntry(for: starters[0], progress: progress) == .house, "House portal has correct destination")
let beforeCollision = progress.jigsaw!.placements
expect(!session.place(starters[0], at: photoSlot(starters[1])), "Occupied slot cannot evict another piece")
expect(progress.jigsaw!.placements == beforeCollision, "Rejected drop preserves both pieces")
session.rotate(starters[0])
session.synchronize()
expect(!progress.installed(.house), "Rotating a connected piece closes the portal")
session.rotate(starters[0], quarterTurns: -1)
session.synchronize()
expect(progress.installed(.house), "Counter-rotation restores the portal")
session.remove(starters[0])
session.synchronize()
expect(!progress.installed(.house), "Returning a piece to the deck closes the portal")
expect(progress.jigsaw!.inventory(progress: progress).contains(starters[0]), "Returned piece appears in inventory")
expect(session.place(starters[0], at: 9), "Tenth column is a valid destination")
expect(session.place(starters[0], at: 39), "Last cell of the 10 by 4 board is reachable")
expect(progress.jigsaw!.placements.values.filter { $0.id == starters[0] }.count == 1, "Moving cannot duplicate a piece")
progress.readBook()
expect(PuzzleWorld.villagePrototype.pieceIDs.isSubset(of: JigsawCatalog.availableIDs(progress: progress)), "Book pickup unlocks the village")
let decoded = try JSONDecoder().decode(PrologueProgress.self, from: JSONEncoder().encode(progress))
expect(decoded.hasBook && decoded.jigsaw!.placements == progress.jigsaw!.placements, "Existing save format round-trips")

let house = PrologueLevel.make(region: .house, progress: progress)
let solids = ExplorationCollisionGeometry.solids(for: house)
expect(solids.count == 12, "House keeps all authored collision footprints")
expect(solids.contains { $0.contains(CGPoint(x: 600, y: 80)) }, "Bed remains solid")
expect(!solids.contains { $0.contains(CGPoint(x: 30, y: 250)) }, "Door opening remains traversable")
let village = PrologueLevel.make(region: .village, progress: progress)
let villageSolids = ExplorationCollisionGeometry.solids(for: village)
expect(villageSolids.count == village.obstacles.count, "Each world obstacle retains its footprint")
for (obstacle, footprint) in zip(village.obstacles, villageSolids) where obstacle.kind == "Pohon" {
    expect(footprint.width < obstacle.rect.width && footprint.height < obstacle.rect.height, "Trees collide at their trunk, not their canopy")
}
print("Architecture regressions passed: \(checks) checks")
