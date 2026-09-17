// Penjelasan file: main.swift
// Program validasi yang dijalankan terpisah dari aplikasi iOS.
// Memeriksa progres cerita, geometri jigsaw, navigasi, penyimpanan, migrasi, dan syarat tiga keping.
// Termasuk regresi crash akses bersamaan dan tes peletakan bebas; expect menghentikan program jika hasil tidak sesuai.

import Foundation
import CoreGraphics

var checks = 0
func expect(_ value: @autoclosure () -> Bool, _ message: String) {
    guard value() else { fatalError(message) }
    checks += 1
}
let progress = PrologueProgress()
expect(progress.discovered.count == 3 && progress.placements.isEmpty, "Start with three loose pieces")
expect(!progress.installed(.house), "Discovery does not open a region")
progress.place(.house, at: 0)
expect(progress.placements[0]?.piece == .house, "Wrong contents must still fit")
expect(progress.placements[0]?.turns == 1, "Wrong orientation must still fit")
progress.place(.mountain, at: 1)
expect(progress.placements[1] == nil, "Cannot place an undiscovered piece")
progress.readBook(); progress.readBook()
expect(progress.discovered.count == 6, "Book rewards granted once")
expect(!progress.installed(.mountain), "New mountain stays fogged until placed")
progress.shownBook.insert(.keneth)
expect(!progress.joined.contains(.keneth), "Showing book alone must not recruit")
for friend in FriendID.allCases { progress.finishConversation(with: friend) }
progress.finishConversation(with: .keneth)
expect(progress.discovered.count == 8 && progress.joined.count == 3, "Dialogue rewards exactly once")
progress.place(.lake, at: 3)
progress.place(.dryLake, at: 7)
expect(progress.lakeVariant == .dryLake && progress.inventory.contains(.lake), "Dry variant returns wet to inventory")
progress.place(.lake, at: 3)
expect(progress.inventory.contains(.dryLake), "Swapping back preserves dry inventory")
progress.rotate(.lake)
expect(progress.placements[3]?.turns == 1, "Rotation affects installed piece")
progress.readMarker(); progress.readMarker()
expect(progress.foundMarker && progress.discovered.count == 9, "Marker gives boundary once")
progress.leaveVillage(childrenAtExit: ["Arthur", "Keneth", "Roland", "Anneth"])
expect(!progress.leftVillage, "Gather before exiting")
progress.groupGathered = true
progress.leaveVillage(childrenAtExit: ["Arthur", "Keneth", "Anneth"])
expect(!progress.leftVillage, "Roland cannot be left behind")
progress.leaveVillage(childrenAtExit: ["Arthur", "Keneth", "Roland", "Anneth"])
expect(progress.leftVillage && progress.discovered.count == 10, "All four unlock closing piece")
expect(!progress.correctlyAssembled, "Leaving village is not prologue completion")
for (slot, piece) in MemoryPiece.main.enumerated() { progress.rotations[piece] = 0; progress.place(piece, at: slot) }
expect(progress.correctlyAssembled, "Final photo with nine correctly oriented originals completes")
progress.place(.dryLake, at: 3)
expect(!progress.correctlyAssembled, "Dry alternate remains a valid placement, but not the final memory")
progress.place(.lake, at: 3)
let recovered = try JSONDecoder().decode(PrologueProgress.self, from: JSONEncoder().encode(progress))
expect(recovered.correctlyAssembled && recovered.joined.count == 3 && recovered.hasBook, "Progress survives serialization")

for region in [MemoryRegion.house, .village, .foothills] {
    for turns in 0..<4 {
        progress.rotations[.oldPath] = turns; progress.place(.oldPath, at: 1)
        progress.rotations[.villageRoad] = turns; progress.place(.villageRoad, at: 8)
        let level = PrologueLevel.make(region: region, progress: progress)
        let navigation = MemoryNavigation(bounds: PrologueLevel.bounds, solids: level.obstacles.map(\.rect), fog: level.fog(progress: progress))
        let entry: MemoryPiece = region == .house ? .house : (region == .village ? .yard : .boundary)
        let spawn = navigation.nearestOpen(to: level.spawn(for: entry, progress: progress))
        expect(navigation.walkable(spawn), "Spawn must be walkable: \(region) / \(turns)")
        if let book = level.book { expect(!navigation.route(from: spawn, to: book).isEmpty, "Book reachable") }
        for (friend, point) in level.friends {
            expect(navigation.walkable(point), "NPC cannot be inside rotated obstacle: \(friend) / \(turns)")
            expect(!navigation.route(from: spawn, to: point).isEmpty, "Every friend reachable")
        }
        if let exit = level.exit, let gathering = level.gathering {
            expect(!navigation.route(from: gathering, to: exit).isEmpty, "All followers can route from gathering to exit")
        }
    }
}
let barrier = CGRect(x: 100, y: 50, width: 30, height: 150)
let nav = MemoryNavigation(bounds: CGRect(x: 0, y: 0, width: 300, height: 250), solids: [barrier], fog: [])
expect(!nav.visible(from: CGPoint(x: 50, y: 100), to: CGPoint(x: 180, y: 100)), "Cover blocks sight")
expect(nav.visible(from: CGPoint(x: 50, y: 30), to: CGPoint(x: 180, y: 30)), "Clear corridor preserves sight")
expect(abs(nav.sightEnd(from: CGPoint(x: 50, y: 100), to: CGPoint(x: 180, y: 100)).x - 100) < 0.01, "Vision cone clips at same wall as detection")
expect(!nav.walkable(CGPoint(x: 105, y: 100)), "Wall blocks movement")
let fogNav = MemoryNavigation(bounds: CGRect(x: 0, y: 0, width: 300, height: 250), solids: [], fog: [CGRect(x: 140, y: 0, width: 160, height: 250)])
expect(!fogNav.walkable(CGPoint(x: 200, y: 80)), "Fog blocks movement")
expect(!fogNav.visible(from: CGPoint(x: 50, y: 80), to: CGPoint(x: 200, y: 80)), "Memory fog blocks sight without lore attribution")
// A dry basin is a real traversable alternative, not just a texture swap.
progress.place(.lake, at: 3)
let wet = PrologueLevel.make(region: .foothills, progress: progress)
let wetNav = MemoryNavigation(bounds: PrologueLevel.bounds, solids: wet.obstacles.map(\.rect), fog: wet.fog(progress: progress))
progress.place(.dryLake, at: 3)
let dry = PrologueLevel.make(region: .foothills, progress: progress)
let dryNav = MemoryNavigation(bounds: PrologueLevel.bounds, solids: dry.obstacles.map(\.rect), fog: dry.fog(progress: progress))
expect(!wetNav.walkable(CGPoint(x: 465, y: 105)) && dryNav.walkable(CGPoint(x: 465, y: 105)), "Lake variant changes real collision")
// Disconnected installed areas remain independently enterable from the photo.
let isolated = PrologueProgress()
isolated.readBook()
isolated.place(.mountain, at: 0)
isolated.place(.villageRoad, at: 8)
let isolatedLevel = PrologueLevel.make(region: .foothills, progress: isolated)
let isolatedNav = MemoryNavigation(bounds: PrologueLevel.bounds, solids: isolatedLevel.obstacles.map(\.rect), fog: isolatedLevel.fog(progress: isolated))
expect(isolatedNav.walkable(isolatedLevel.spawn(for: .mountain, progress: isolated)), "Isolated mountain supports direct photo travel")
expect(!isolatedNav.walkable(CGPoint(x: 465, y: 350)), "Missing middle remains fogged")


// 6 x 8 jigsaw progression and backward-compatible saves.
expect(PuzzleCatalog.rows == 6 && PuzzleCatalog.columns == 8 && JigsawCatalog.count == 48, "48 physical pieces")
let opening = PrologueProgress()
opening.prepareJigsaw()
expect(JigsawCatalog.availableIDs(progress: opening).count == 3, "Three starter fragments")
expect(opening.jigsaw!.placements.isEmpty, "Opening pieces remain loose")
let houseID = JigsawCatalog.primaryID(for: .house)
opening.jigsaw!.rotations[houseID] = 0
expect(opening.jigsaw!.place(houseID, at: houseID, available: JigsawCatalog.availableIDs(progress: opening)), "Starter house can be assembled")
opening.synchronizeJigsaw()
expect(!opening.installed(.house), "One house fragment must not open exploration")
for id in JigsawCatalog.starterIDs {
    opening.jigsaw!.rotations[id] = 0
    _ = opening.jigsaw!.place(id, at: id, available: JigsawCatalog.availableIDs(progress: opening))
}
opening.synchronizeJigsaw()
expect(opening.installed(.house), "Connected starter cluster opens house")
opening.readBook()
expect(JigsawCatalog.availableIDs(progress: opening).count == 15, "Book unlocks a limited first batch")
expect(!opening.installed(.mountain), "Discovered fragment still does not open its area")
for friend in FriendID.allCases { opening.finishConversation(with: friend) }
expect(JigsawCatalog.availableIDs(progress: opening).count == 27, "Friends unlock water and old-path batches")
opening.readMarker()
expect(JigsawCatalog.availableIDs(progress: opening).count == 39, "Marker unlocks boundary batch")
opening.groupGathered = true
opening.leaveVillage(childrenAtExit: ["Arthur", "Keneth", "Roland", "Anneth"])
let available = JigsawCatalog.availableIDs(progress: opening)
expect(available.count == 49, "48 main fragments plus one alternate")
var physical = JigsawProgress()
for id in 0..<48 { expect(physical.place(id, at: id, available: available), "Every original fits its intended edges") }
expect(physical.solved, "Complete 48-piece photo")
let wetID = JigsawCatalog.primaryID(for: .lake)
expect(physical.place(JigsawCatalog.dryLakeID, at: wetID, available: available), "Alternate has the same physical shape")
expect(!physical.installedIDs.contains(where: { JigsawCatalog.location(for: $0) == .lake }), "Only one lake variant active")
expect(!physical.solved, "Alternate never silently completes photo")
expect(physical.place(wetID, at: wetID, available: available), "Water can replace dry variant")
expect(!physical.installedIDs.contains(JigsawCatalog.dryLakeID), "Dry piece returns to inventory")
// Two internal sockets with identical edge profiles can hold wrong image content.
var permissive = JigsawProgress()
expect(JigsawCatalog.fits(9, at: 11, turns: 0), "Compatible wrong image is accepted")
expect(permissive.place(9, at: 11, available: available), "Wrong-image placement is not auto-rejected")
permissive.rotations[9] = 2
expect(permissive.place(9, at: 11, available: available), "Compatible upside-down image is accepted")
expect(!JigsawCatalog.fits(0, at: 11, turns: 0), "Straight outer edge cannot fill an internal socket")
let before = permissive.placements
expect(!permissive.place(0, at: 48, available: available) && permissive.placements == before, "Out-of-board drop is non-destructive")
permissive.rotate(9)
expect(permissive.placements[11] == JigsawPlacement(id: 9, turns: 3), "Quarter-turn stays on board")
opening.jigsaw = physical
opening.synchronizeJigsaw()
expect(!opening.assembled, "Fewer than 48 installed fragments cannot complete prologue")
for id in 0..<48 { _ = opening.jigsaw!.place(id, at: id, available: available) }
opening.synchronizeJigsaw()
expect(opening.correctlyAssembled && opening.assembled, "Both story and complete jigsaw are required")
let saved48 = try JSONDecoder().decode(PrologueProgress.self, from: JSONEncoder().encode(opening))
expect(saved48.jigsaw!.solved && saved48.hasBook && saved48.joined.count == 3, "48-piece save survives reload")
let legacy = PrologueProgress()
legacy.readBook(); legacy.place(.house, at: 5)
var legacyJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
legacyJSON.removeValue(forKey: "jigsaw")
let migrated = try JSONDecoder().decode(PrologueProgress.self, from: JSONSerialization.data(withJSONObject: legacyJSON))
migrated.prepareJigsaw()
expect(migrated.hasBook && migrated.jigsaw!.installedIDs.contains(houseID) && !migrated.installed(.house), "Legacy story survives but a lone piece no longer opens its area")

// Verify real Bezier geometry rather than only edge metadata.
let paths: [CGPath] = PuzzleCatalog.pieces.map { piece in
    let path = JigsawOutline.path(for: piece)
    expect(CGRect(x: -0.01, y: -0.01, width: piece.width + 0.02, height: piece.height + 0.02).contains(path.boundingBoxOfPath), "Tabs stay inside declared texture bounds")
    var translation = CGAffineTransform(translationX: piece.targetX, y: piece.targetY)
    return path.copy(using: &translation)!
}
for y in stride(from: CGFloat(7.31), to: PuzzleCatalog.canvasHeight, by: 19) {
    for x in stride(from: CGFloat(9.73), to: PuzzleCatalog.canvasWidth, by: 19) {
        let point = CGPoint(x: x, y: y)
        let count = paths.filter { $0.contains(point) }.count
        expect(count == 1, "Assembled jigsaw has no holes or overlaps at \(point)")
    }
}


// Entry requires the selected piece's own orthogonally connected component.
var cluster = JigsawProgress()
let all = Set(JigsawCatalog.allIDs)
_ = cluster.place(29, at: 29, available: all)
expect(!cluster.canEnter(29), "Single piece cannot enter")
_ = cluster.place(37, at: 37, available: all)
expect(cluster.connectedIDs(to: 29).count == 2 && !cluster.canEnter(29), "Two connected pieces cannot enter")
_ = cluster.place(36, at: 36, available: all)
expect(cluster.canEnter(29) && cluster.canEnter(36) && cluster.canEnter(37), "L-shaped starter cluster allows entry")
cluster.remove(37)
expect(!cluster.canEnter(29) && !cluster.canEnter(36), "Removing the bridge re-locks both separated pieces")
var diagonal = JigsawProgress()
for id in [9, 18, 27] { _ = diagonal.place(id, at: id, available: all) }
expect(diagonal.connectedIDs(to: 18).count == 1 && !diagonal.canEnter(18), "Diagonal corners do not connect")
var rowBoundary = JigsawProgress()
for id in [6, 7, 8] { _ = rowBoundary.place(id, at: id, available: all) }
expect(rowBoundary.connectedIDs(to: 7).count == 2 && rowBoundary.connectedIDs(to: 8).count == 1, "Last column cannot wrap to next row")
var separate = JigsawProgress()
for id in [0, 1, 8, 29, 36, 37, 12] { _ = separate.place(id, at: id, available: all) }
expect(separate.canEnter(0) && separate.canEnter(29), "Independent local clusters are both visitable")
expect(!separate.canEnter(12), "Other ready clusters do not unlock an isolated selected piece")
expect(!separate.canEnter(48), "Inventory-only alternate cannot enter")
let gates = PrologueProgress()
gates.prepareJigsaw()
gates.jigsaw = separate
gates.synchronizeJigsaw()
expect(gates.installed(.house) && gates.installed(.mountain) && !gates.installed(.oldPath), "World fog uses the same connectivity gate as entry")
let staged = PrologueProgress()
staged.prepareJigsaw()
expect(JigsawCatalog.availableIDs(progress: staged) == JigsawCatalog.starterIDs, "Fresh game exposes only three pieces")
for id in JigsawCatalog.starterIDs { staged.jigsaw!.rotations[id] = 0; _ = staged.jigsaw!.place(id, at: id, available: JigsawCatalog.availableIDs(progress: staged)) }
staged.synchronizeJigsaw()
expect(staged.installed(.house), "Opening is solvable without future rewards")
staged.readBook()
for id in JigsawCatalog.availableIDs(progress: staged).sorted() {
    staged.jigsaw!.rotations[id] = 0
    let slot = id == 48 ? JigsawCatalog.primaryID(for: .lake) : id
    _ = staged.jigsaw!.place(id, at: slot, available: JigsawCatalog.availableIDs(progress: staged))
}
staged.synchronizeJigsaw()
expect(staged.installed(.yard) && staged.installed(.villageRoad) && staged.installed(.mountain) && staged.installed(.garden) && staged.installed(.dryLake), "Book reward pack supports required visitable clusters")
for friend in FriendID.allCases { staged.finishConversation(with: friend) }
for id in JigsawCatalog.friendsReward { _ = staged.jigsaw!.place(id, at: id, available: JigsawCatalog.availableIDs(progress: staged)) }
staged.synchronizeJigsaw()
expect(staged.installed(.oldPath) && staged.installed(.lake), "Friends reward pack permits marker mission")
staged.readMarker()
for id in JigsawCatalog.markerReward { _ = staged.jigsaw!.place(id, at: id, available: JigsawCatalog.availableIDs(progress: staged)) }
staged.synchronizeJigsaw()
expect(staged.installed(.boundary), "Marker reward pack permits exit mission")
expect(JigsawCatalog.availableIDs(progress: staged).count < 49, "Full photo is never provided before final mission")
// Upgrade old three-socket openings without erasing story progress.
let oldOpening = PrologueProgress()
var oldState = JigsawProgress()
oldState.rotations = [21: 1, 35: 0, 37: 3]
oldState.placements[35] = JigsawPlacement(id: 35, turns: 0)
oldOpening.jigsaw = oldState
oldOpening.prepareJigsaw()
expect(oldOpening.jigsaw!.connectionRulesVersion == 1 && JigsawCatalog.availableIDs(progress: oldOpening).count == 3, "Old opening upgrades to exactly three connectable pieces")
expect(!oldOpening.jigsaw!.installedIDs.contains(35), "Retired starter is not left stranded on board")
let oldEarned = PrologueProgress()
oldEarned.readBook(); oldEarned.jigsaw = JigsawProgress()
oldEarned.prepareJigsaw()
expect(JigsawCatalog.availableIDs(progress: oldEarned).count == 27 && oldEarned.hasBook, "Previously earned pieces and mission flags survive upgrade")
let reloadGates = try JSONDecoder().decode(PrologueProgress.self, from: JSONEncoder().encode(staged))
reloadGates.prepareJigsaw()
expect(reloadGates.installed(.boundary) && reloadGates.jigsaw!.connectionRulesVersion == 1, "Connectivity gates survive reload")
// Exercise the same computed progress getter and placement entry point as GameScene.
final class DropRegression {
    let saved = PrologueProgress()
    var progress: PrologueProgress { saved }
    func drop(_ id: Int, at slot: Int) -> Bool {
        progress.placeJigsawPiece(id, at: slot)
    }
}
let dropScene = DropRegression()
expect(!dropScene.drop(36, at: 36), "Unprepared board safely rejects drops")
dropScene.progress.prepareJigsaw()
for id in [29, 36, 37] {
    dropScene.progress.jigsaw?.rotations[id] = 0
    expect(dropScene.drop(id, at: id), "Scene drop path places starter without an access conflict")
    dropScene.progress.synchronizeJigsaw()
}
expect(dropScene.progress.jigsaw!.canEnter(29), "Three dropped starters unlock entry")
let beforeRejectedDrop = dropScene.progress.jigsaw!.placements
expect(!dropScene.drop(0, at: 0), "Locked pieces remain unavailable")
expect(!dropScene.drop(36, at: -1), "Out-of-board drop rejects safely")
expect(dropScene.progress.jigsaw!.placements == beforeRejectedDrop, "Rejected drop preserves board")
expect(dropScene.drop(36, at: 36), "Repeated drops remain safe")
let savedDrop = try JSONDecoder().decode(PrologueProgress.self, from: JSONEncoder().encode(dropScene.progress))
expect(savedDrop.jigsaw!.canEnter(29), "Dropped pieces survive save and reload")
// Every starter accepts every cell and rotation; shape never blocks early play.
for id in JigsawCatalog.starterIDs {
    for slot in 0..<48 {
        for turns in 0..<4 {
            var free = JigsawProgress()
            free.rotations[id] = turns
            expect(free.place(id, at: slot, available: JigsawCatalog.starterIDs), "Starter accepts any slot/rotation")
        }
    }
}
let freeStart = PrologueProgress()
freeStart.prepareJigsaw()
for (id, slot) in [(29, 1), (37, 9), (36, 8)] {
    freeStart.jigsaw?.rotations[id] = 0
    expect(freeStart.placeJigsawPiece(id, at: slot), "Opening works at arbitrary cells with default rotations")
}
freeStart.synchronizeJigsaw()
expect(freeStart.installed(.house) && freeStart.jigsaw!.canEnter(29), "Arbitrary adjacent starter cluster opens house")
expect(!freeStart.correctlyAssembled, "Free placement does not count as solved photo")
freeStart.jigsaw?.rotate(29)
expect(!freeStart.jigsaw!.canEnter(29), "Quarter-turn breaks physical alignment")
freeStart.jigsaw?.rotate(29)
expect(freeStart.placeJigsawPiece(37, at: 47), "Placed piece moves freely")
freeStart.synchronizeJigsaw()
expect(!freeStart.installed(.house), "Moving piece away relocks the cluster")
expect(freeStart.placeJigsawPiece(37, at: 8), "Occupied cell accepts replacement")
expect(!freeStart.jigsaw!.installedIDs.contains(36) && freeStart.jigsaw!.inventory(progress: freeStart).contains(36), "Displaced piece returns to inventory")
let reloadedFree = try JSONDecoder().decode(PrologueProgress.self, from: JSONEncoder().encode(freeStart))
reloadedFree.prepareJigsaw()
expect(reloadedFree.jigsaw!.placements == freeStart.jigsaw!.placements, "Arbitrary placements survive reload")
// Satu rangkaian mempunyai pintu masuk dan daftar area yang sama untuk semua anggotanya.
let portalProgress = PrologueProgress()
portalProgress.prepareJigsaw()
for id in JigsawCatalog.starterIDs { portalProgress.jigsaw?.rotations[id] = 0 }
expect(portalProgress.jigsaw!.worldEntry(for: 29, progress: portalProgress) == nil, "Inventory has no world")
_ = portalProgress.placeJigsawPiece(29, at: 1)
_ = portalProgress.placeJigsawPiece(36, at: 8)
expect(portalProgress.jigsaw!.worldLocations(for: 29).isEmpty, "Two pieces do not create a world")
_ = portalProgress.placeJigsawPiece(37, at: 9)
portalProgress.synchronizeJigsaw()
for id in [29, 36, 37] {
    expect(portalProgress.jigsaw!.worldEntry(for: id, progress: portalProgress) == .house, "Every starter enters the same house world")
    expect(portalProgress.jigsaw!.worldLocations(for: id) == [.house, .yard, .villageRoad], "Cluster shares all its areas")
}
portalProgress.readBook()
for id in [29, 36, 37] {
    expect(portalProgress.jigsaw!.worldEntry(for: id, progress: portalProgress) == .house, "Original starter world stays House after reading book")
}
_ = portalProgress.placeJigsawPiece(28, at: 0)
expect(portalProgress.jigsaw!.worldEntry(for: 29, progress: portalProgress) == .yard, "Mission rewards can expand the group into the next world")
portalProgress.jigsaw?.remove(28)
portalProgress.jigsaw?.remove(36)
expect(portalProgress.jigsaw!.worldEntry(for: 29, progress: portalProgress) == nil, "Broken cluster loses its portal")
expect(separate.worldLocations(for: 0).isDisjoint(with: separate.worldLocations(for: 29)), "Separate clusters do not share world areas")
expect(separate.worldLocations(for: 12).isEmpty, "Isolated piece cannot borrow another world's portal")
// Bertetangga saja tidak cukup: dua tonjolan atau dua cekungan tidak saling mengunci.
var falseCluster = JigsawProgress()
for (id, slot) in [(29, 0), (36, 1), (21, 2)] {
    _ = falseCluster.place(id, at: slot, available: Set(JigsawCatalog.allIDs))
}
expect(!falseCluster.interlocks(from: 0, to: 1), "Two tabs cannot interlock")
expect(!falseCluster.canEnter(29), "Mere adjacency never unlocks Jump In")
var trueCluster = JigsawProgress()
for (id, slot) in [(29, 1), (37, 9), (36, 8)] {
    _ = trueCluster.place(id, at: slot, available: Set(JigsawCatalog.allIDs))
}
expect(trueCluster.canEnter(29), "Complementary edges connect away from photo solution")
expect(trueCluster.interlocks(from: 1, to: 9) && trueCluster.interlocks(from: 9, to: 1), "Connection is symmetric")
trueCluster.rotate(36)
expect(!trueCluster.canEnter(29), "Rotating bridge breaks the world gate")
trueCluster.rotate(36)
expect(!trueCluster.canEnter(29), "Upside-down photo cannot reconnect despite matching edges")
trueCluster.rotate(36); trueCluster.rotate(36)
expect(trueCluster.canEnter(29), "Upright photo reconnects")
var flatEdges = JigsawProgress()
_ = flatEdges.place(7, at: 0, available: Set(JigsawCatalog.allIDs))
_ = flatEdges.place(0, at: 1, available: Set(JigsawCatalog.allIDs))
expect(!flatEdges.interlocks(from: 0, to: 1), "Flat edges do not form a jigsaw joint")
// Regresi dua screenshot: baris lurus salah, L sesuai foto benar di lokasi papan bebas.
var screenshotWrong = JigsawProgress()
for (id, slot) in [(36, 18), (37, 19), (29, 20)] {
    _ = screenshotWrong.place(id, at: slot, available: Set(JigsawCatalog.allIDs))
}
for id in [29, 36, 37] { expect(!screenshotWrong.canEnter(id), "Wrong photo order never opens Jump In") }
for row in 0..<5 {
    for col in 0..<7 {
        var translated = JigsawProgress()
        for (id, slot) in [(29, row * 8 + col + 1), (36, (row + 1) * 8 + col), (37, (row + 1) * 8 + col + 1)] {
            _ = translated.place(id, at: slot, available: Set(JigsawCatalog.allIDs))
        }
        for id in [29, 36, 37] { expect(translated.canEnter(id), "Correct L works anywhere within board bounds") }
    }
}
let wrongSave = PrologueProgress()
wrongSave.jigsaw = screenshotWrong
wrongSave.prepareJigsaw()
expect(!wrongSave.installed(.house), "Reloading old incorrect arrangement re-locks world without deleting pieces")
expect(wrongSave.jigsaw!.placements.count == 3, "Incorrect saved pieces remain movable")
print("Passed \(checks) progression, connectivity and jigsaw checks")
