import Foundation
import CoreGraphics

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}
let allCells = VillageCartoMap.pieces.flatMap { $0 }
check(allCells.count == VillageCartoMap.columns * VillageCartoMap.rows, "Full source coverage")
check(Set(allCells).count == allCells.count, "No overlapping source cells")
check(VillageCartoMap.playablePieceIDs == [5, 26, 20, 38, 6, 12, 8], "Storyboard order plus Quest 6 reward")
check(VillageCartoMap.subdivisions == 6, "Every terrain square uses a 6x6 subgrid")
check(VillageCartoMap.playablePieceIDs.enumerated().allSatisfy {
    VillageCartoMap.displayNumber(forPieceID: $0.element) == $0.offset + 1
}, "Player-facing numbers follow storyboard order")

func normalizedCells(id: Int) -> Set<String> {
    let placement = VillageTileLayout.Placement(
        id: id,
        column: 10,
        row: 10,
        turns: VillageCartoMap.preferredTurns(forPieceID: id)
    )
    let cells = VillageTileLayout.cells(of: placement)
    let minColumn = cells.map(\.column).min()!
    let minRow = cells.map(\.row).min()!
    return Set(cells.map { "\($0.column - minColumn),\($0.row - minRow)" })
}
let referenceShapes: [Set<String>] = [
    ["0,1", "1,1", "1,0", "2,0"],
    ["0,1", "1,1", "2,1", "0,0"],
    ["0,1", "1,1", "1,0", "2,0"],
    ["0,1", "1,1", "2,1", "0,0"],
    ["0,2", "1,2", "1,1", "1,0"],
    ["1,1", "0,0", "1,0", "2,0"],
    ["0,3", "0,2", "0,1", "0,0"]
]
for (index, id) in VillageCartoMap.playablePieceIDs.enumerated() {
    check(normalizedCells(id: id) == referenceShapes[index], "Tetromino \(index + 1) matches its reference")
}
let quest6RewardID = 8
check(quest6RewardID == 8 && normalizedCells(id: quest6RewardID) == ["0,3", "0,2", "0,1", "0,0"],
      "Quest 6 reward is an I tetromino")
for cell in VillageCartoMap.pieces[quest6RewardID] {
    for row in 0..<VillageCartoMap.subdivisions {
        for column in 0..<VillageCartoMap.subdivisions {
            let subcell = VillageCartoMap.Cell(
                x: cell.x * VillageCartoMap.subdivisions + column,
                y: cell.y * VillageCartoMap.subdivisions + row
            )
            check(VillageCartoMap.biomeForSubcell(subcell) == .darkGreenForest,
                  "Every Quest 6 reward subgrid is dark-green forest")
        }
    }
}

// Pada keping 1, kedua segitiga hijau berada di kiri-bawah kotaknya seperti
// storyboard. Primary adalah segitiga kiri-bawah pada renderer SpriteKit.
let firstTopLeft = VillageCartoMap.diagonalBiomes(for: .init(x: 5, y: 8))
let firstBottomMiddle = VillageCartoMap.diagonalBiomes(for: .init(x: 6, y: 7))
check(firstTopLeft.primary == .naturalGrass && firstTopLeft.secondary == .villageSoil,
      "Tetromino 1 upper green triangle occupies the lower-left half")
check(firstBottomMiddle.primary == .naturalGrass && firstBottomMiddle.secondary == .villageSoil,
      "Tetromino 1 lower green triangle occupies the lower-left half")

// Kotak kanan keping 2 hijau muda penuh. Pada kotak tengah, hijau muda masuk
// sebagai segitiga sama kaki sedalam tepat 3/6 subgrid dari sisi kanan.
let secondLightGreenCell = VillageCartoMap.Cell(x: 11, y: 9)
check(VillageCartoMap.terrainSplit(for: secondLightGreenCell) == .centeredRightTriangle,
      "Tetromino 2 uses the centered isosceles triangle")
let secondGreenCounts = (0..<VillageCartoMap.subdivisions).map { row in
    (0..<VillageCartoMap.subdivisions).filter { column in
        VillageCartoMap.biomeForSubcell(.init(
            x: secondLightGreenCell.x * VillageCartoMap.subdivisions + column,
            y: secondLightGreenCell.y * VillageCartoMap.subdivisions + row
        )) == .naturalGrass
    }.count
}
check(secondGreenCounts == [1, 2, 3, 3, 2, 1],
      "Tetromino 2 light-green triangle is only three subgrids deep")
let secondFullGreenCell = VillageCartoMap.Cell(x: 12, y: 9)
check((0..<VillageCartoMap.subdivisions).allSatisfy { row in
    (0..<VillageCartoMap.subdivisions).allSatisfy { column in
        VillageCartoMap.biomeForSubcell(.init(
            x: secondFullGreenCell.x * VillageCartoMap.subdivisions + column,
            y: secondFullGreenCell.y * VillageCartoMap.subdivisions + row
        )) == .naturalGrass
    }
}, "Tetromino 2 rightmost square is fully light green")
let secondDarkGreen = VillageCartoMap.diagonalBiomes(for: .init(x: 10, y: 8))
check(secondDarkGreen.primary == .villageSoil && secondDarkGreen.secondary == .darkGreenForest,
      "Tetromino 2 dark green uses the secondary lower-right triangle")
check(VillageCartoMap.terrainSplit(for: .init(x: 10, y: 8)) == .lowerRightTriangle,
      "Tetromino 2 bottom square uses the rising diagonal")
let secondDarkCounts = (0..<VillageCartoMap.subdivisions).map { row in
    (0..<VillageCartoMap.subdivisions).filter { column in
        VillageCartoMap.biomeForSubcell(.init(
            x: 10 * VillageCartoMap.subdivisions + column,
            y: 8 * VillageCartoMap.subdivisions + row
        )) == .darkGreenForest
    }.count
}
check(secondDarkCounts == [6, 5, 4, 3, 2, 1],
      "Tetromino 2 dark green occupies the lower-right half")

// Keping 3 adalah Z: dua kotak atas, lalu dua kotak bawah bergeser ke kanan.
// Tiga kotak pertama kuning penuh. Kotak kanan bawah memiliki rock salt pada
// segitiga kanan atas seperti storyboard.
let thirdID = VillageCartoMap.playablePieceIDs[2]
check(thirdID == 20 && normalizedCells(id: thirdID) == ["0,1", "1,1", "1,0", "2,0"],
      "Tetromino 3 uses the referenced Z silhouette")
for cell in [VillageCartoMap.Cell(x: 8, y: 5),
             VillageCartoMap.Cell(x: 9, y: 5),
             VillageCartoMap.Cell(x: 9, y: 4)] {
    check((0..<VillageCartoMap.subdivisions).allSatisfy { row in
        (0..<VillageCartoMap.subdivisions).allSatisfy { column in
            VillageCartoMap.biomeForSubcell(.init(
                x: cell.x * VillageCartoMap.subdivisions + column,
                y: cell.y * VillageCartoMap.subdivisions + row
            )) == .villageSoil
        }
    }, "Tetromino 3 keeps its first three cells fully yellow")
}
let thirdRockCell = VillageCartoMap.Cell(x: 10, y: 4)
let thirdRockBiomes = VillageCartoMap.diagonalBiomes(for: thirdRockCell)
check(thirdRockBiomes.primary == .villageSoil && thirdRockBiomes.secondary == .rockSalt,
      "Tetromino 3 bottom-right cell uses yellow and rock salt")
let thirdRockCounts = (0..<VillageCartoMap.subdivisions).map { row in
    (0..<VillageCartoMap.subdivisions).filter { column in
        VillageCartoMap.biomeForSubcell(.init(
            x: thirdRockCell.x * VillageCartoMap.subdivisions + column,
            y: thirdRockCell.y * VillageCartoMap.subdivisions + row
        )) == .rockSalt
    }.count
}
check(thirdRockCounts == [1, 2, 3, 4, 5, 6],
      "Tetromino 3 rock salt fills the upper-right triangle")

// Keping 4 memakai bentuk tiga kotak mendatar dengan satu kotak di bawah
// kiri setelah rotasi preferensi 180°. Segitiga hijau tua pada kotak bawah
// berbentuk sama kaki, setinggi tiga subgrid.
let fourthID = VillageCartoMap.playablePieceIDs[3]
check(fourthID == 38 && VillageCartoMap.preferredTurns(forPieceID: fourthID) == 2,
      "Tetromino 4 uses its referenced orientation")
let fourthDarkCell = VillageCartoMap.Cell(x: 15, y: 2)
check(VillageCartoMap.terrainSplit(for: fourthDarkCell) == .centeredTopTriangle,
      "Tetromino 4 uses the centered dark-green triangle")
let fourthDarkBiomes = VillageCartoMap.diagonalBiomes(for: fourthDarkCell)
check(fourthDarkBiomes.primary == .villageSoil && fourthDarkBiomes.secondary == .darkGreenForest,
      "Tetromino 4 triangle combines yellow and dark green")
let fourthDarkCounts = (0..<VillageCartoMap.subdivisions).map { row in
    (0..<VillageCartoMap.subdivisions).filter { column in
        VillageCartoMap.biomeForSubcell(.init(
            x: fourthDarkCell.x * VillageCartoMap.subdivisions + column,
            y: fourthDarkCell.y * VillageCartoMap.subdivisions + row
        )) == .darkGreenForest
    }.count
}
check(fourthDarkCounts == [0, 0, 0, 2, 4, 6],
      "Tetromino 4 source triangle becomes a three-subgrid bottom triangle after rotation")
let fourthLightCell = VillageCartoMap.Cell(x: 13, y: 1)
let fourthLightBiomes = VillageCartoMap.diagonalBiomes(for: fourthLightCell)
check(fourthLightBiomes.primary == .naturalGrass && fourthLightBiomes.secondary == .villageSoil,
      "Tetromino 4 keeps the light-green diagonal from the reference")

var layout = VillageTileLayout()
let start = VillageTileLayout.initial
check(start.id == 26, "Quest 1 starts on the L piece before the Z piece")
check(layout.inventory.contains(5), "The Z piece follows the L starter")
let player = layout.world(VillageCartoMap.spawn)!
check(layout.walkable(player), "Starter has a safe spawn")

// Susunan L lalu Z yang tersambung harus cukup untuk seluruh bangunan Quest 1.
var questOneLayout = VillageTileLayout()
check(questOneLayout.place(id: 5, column: 10, row: 12, turns: 0),
      "Quest 1 Z piece can be placed after the L starter")
check(VillageTileLayout.linked(
    questOneLayout.placements.first { $0.id == 26 }!,
    questOneLayout.placements.first { $0.id == 5 }!
), "Quest 1 L and Z pieces are connected")
check(questOneLayout.placeBuilding(id: "arthur-house", subColumn: 72, subRow: 60),
      "Quest 1 supports Arthur's house on L and Z")
check(questOneLayout.placeBuilding(id: "village-well", subColumn: 63, subRow: 75),
      "Quest 1 supports the unlocked well")
check(questOneLayout.placeBuilding(id: "bu-mara-house", subColumn: 66, subRow: 72),
      "Quest 1 supports Bu Mara's unlocked house")
let buildingLockedPieceIDs = questOneLayout.placements
    .map(\.id)
    .filter { questOneLayout.hasBuilding(onPieceID: $0) }
check(!buildingLockedPieceIDs.isEmpty,
      "A building locks every puzzle piece beneath its footprint")
for id in buildingLockedPieceIDs {
    let piece = questOneLayout.placements.first { $0.id == id }!
    check(!questOneLayout.canPlace(
        id: id,
        column: piece.column + 1,
        row: piece.row,
        turns: piece.turns
    ), "A piece with a building cannot be moved")
    var removalAttempt = questOneLayout
    check(!removalAttempt.remove(id: id),
          "A piece with a building cannot be returned to inventory")
}
var unlockedAfterBuildingsMove = questOneLayout
for building in Array(unlockedAfterBuildingsMove.buildingPlacements) {
    check(unlockedAfterBuildingsMove.removeBuilding(id: building.id),
          "Building can be returned before moving its supporting piece")
}
for id in buildingLockedPieceIDs {
    check(!unlockedAfterBuildingsMove.hasBuilding(onPieceID: id),
          "Supporting piece unlocks after buildings are removed")
}
for id in VillageTileLayout.playablePieceIDs {
    let shape = VillageCartoMap.pieces[id]
    check(shape.count == 4 && Set(shape).count == 4, "Exactly four cells per piece")
    var connected: Set<VillageCartoMap.Cell> = [shape[0]]
    for _ in 0..<4 {
        for cell in connected {
            for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
                let neighbor = VillageCartoMap.Cell(x:cell.x+dx,y:cell.y+dy)
                if shape.contains(neighbor) { connected.insert(neighbor) }
            }
        }
    }
    check(connected.count == 4, "Cells form one connected piece")
    let path = VillageTileLayout.outline(id)
    let anchor = shape[0]
    for x in -4...4 {
        for y in -4...4 {
            let sourceCell = VillageCartoMap.Cell(x:anchor.x+x,y:anchor.y+y)
            check(path.contains(CGPoint(x:CGFloat(x)*VillageTileLayout.side,y:CGFloat(y)*VillageTileLayout.side))
                == shape.contains(sourceCell), "Concave shape clipping and touch path")
        }
    }
    for turns in 0..<4 {
        var single = VillageTileLayout()
        check(single.remove(id:start.id), "Remove complete starter group")
        check(single.place(id:id,column:10,row:10,turns:turns), "Rotate complete group")
        let piece = single.placements[0]
        check(VillageTileLayout.cells(of:piece).count == 4, "Four occupied board cells")
        for cell in shape {
            let source = CGPoint(x:(CGFloat(cell.x)+0.5)*VillageTileLayout.side,
                                 y:(CGFloat(cell.y)+0.5)*VillageTileLayout.side)
            let world = single.world(source)!
            check(single.placement(at:world)?.id == id, "Every cell selects the same piece")
            let restored = single.source(world)!
            check(hypot(source.x-restored.x,source.y-restored.y) < 0.001, "Rotated source/world roundtrip")
        }
        for occupied in VillageTileLayout.cells(of:piece) {
            let other = VillageTileLayout.playablePieceIDs.first { $0 != id }!
            let before = single.placements
            check(!single.place(id:other,column:occupied.column,row:occupied.row,turns:0), "Overlap rejected on every cell")
            check(single.placements == before, "Rejected placement is atomic")
        }
    }
}

// Debug layout contains all storyboard and reward pieces without overlap.
var assembled = VillageTileLayout()
assembled.solveAllPieces()
check(assembled.inventory.isEmpty, "All pieces assembled")
check(VillageTileLayout(data:assembled.encoded).placements == assembled.placements, "Save roundtrip")
check(Set(assembled.placements.map(\.id)) == Set(VillageTileLayout.playablePieceIDs), "Debug layout uses all seven pieces")
check(assembled.placements.allSatisfy {
    $0.turns == VillageCartoMap.preferredTurns(forPieceID: $0.id)
}, "Initial orientations match all references")

// Matching must examine every exposed subcell edge, not only the anchor.
var good = 0, bad = 0
for id in VillageTileLayout.playablePieceIDs where id != start.id {
    for turn in 0..<4 {
        for dx in -4...4 {
            for dy in -4...4 {
                let candidate = VillageTileLayout.Placement(id:id,column:start.column+dx,row:start.row+dy,turns:turn)
                let expected = VillageTileLayout.valid([start,candidate]) && VillageTileLayout.matching(start,candidate)
                check(layout.canPlace(id:id,column:candidate.column,row:candidate.row,turns:turn) == expected,
                      "Full footprint and every touching road edge validated")
                if expected { good += 1 } else { bad += 1 }
            }
        }
    }
}
check(good > 0 && bad > 0, "Both accepted and rejected placements")
let before = layout.placements
check(!layout.place(id:start.id,column:VillageTileLayout.columns-1,row:8,turns:0), "Whole shape must stay in board")
check(!layout.place(id:-1,column:0,row:0,turns:0), "Invalid ID rejected")
check(layout.placements == before, "Invalid placements preserve state")
check(layout.remove(id:start.id), "Starter returned to inventory as one unit")
check(layout.inventory.contains(start.id), "Returned group available")
check(layout.placements.isEmpty, "Empty board allowed")
check(VillageTileLayout(data:layout.encoded).placements == [start], "Loading an empty save restores Arthur's starter piece")
check(!layout.remove(id:start.id), "Double return rejected")
check(layout.place(id:start.id,column:8,row:5,turns:3), "Place after empty board")
check(layout.walkable(layout.world(VillageCartoMap.spawn)!), "Arthur stays walkable after rotating his group")
check(VillageTileLayout(data:Data("bad".utf8)).placements == [start], "Corrupt save fallback")
let legacy = try JSONEncoder().encode([start])
check(VillageTileLayout(data:legacy).placements == [start], "Old square schema cannot be interpreted as groups")
print("PASS: seven ordered tetrominoes, 6x6 subgrids, all rotations/hit paths, player transforms, \(good) valid and \(bad) invalid placements, saves and boundaries")

let mask = VillageCartoMap.buildableSourceSubcells
check(!mask.isEmpty, "Outlined zone has usable land")
for index in VillageCartoMap.waterSubcellIndices {
    let columns = VillageCartoMap.columns * VillageCartoMap.subdivisions
    check(!mask.contains(.init(x:index%columns,y:index/columns)),
          "Every subcell touching blue water is excluded, including feathered edges")
}
func terrainSubcell(_ x: CGFloat, _ y: CGFloat) -> VillageCartoMap.Cell {
    .init(x:Int(x/1818*CGFloat(VillageCartoMap.columns * VillageCartoMap.subdivisions)),
          y:Int((1-y/1344)*CGFloat(VillageCartoMap.rows * VillageCartoMap.subdivisions)))
}
check(mask.contains(terrainSubcell(1000,350)), "Northern plateau is not clipped by old piece IDs")
check(mask.contains(terrainSubcell(650,880)), "Southwestern plateau is covered")
check(!mask.contains(terrainSubcell(900,770)), "River between contours is excluded")
check(!mask.contains(terrainSubcell(100,100)), "Land outside contours is excluded")
let unit = VillageCartoMap.subcellSide
var allowedCount = 0, rejectedCount = 0
for id in VillageTileLayout.playablePieceIDs {
    for turns in 0..<4 {
        var sample = VillageTileLayout()
        sample.remove(id:start.id)
        check(sample.place(id:id,column:12,row:10,turns:turns), "Isolated rotated building test")
        for cell in VillageCartoMap.pieces[id] {
            for row in 0..<VillageCartoMap.subdivisions {
                for column in 0..<VillageCartoMap.subdivisions {
                    let sub = VillageCartoMap.Cell(
                        x: cell.x * VillageCartoMap.subdivisions + column,
                        y: cell.y * VillageCartoMap.subdivisions + row
                    )
                    let source = CGPoint(x:(CGFloat(sub.x)+0.5)*unit,y:(CGFloat(sub.y)+0.5)*unit)
                    let world = sample.world(source)!
                    let actual = VillageTileLayout.buildableSubcell(
                        column:Int(world.x/unit),row:Int(world.y/unit),pieces:sample.placements)
                    check(actual == VillageCartoMap.canPlaceObject(onSubcell: sub),
                          "Curated terrain follows every rotation and translation")
                    if actual {
                        allowedCount += 1
                    } else { rejectedCount += 1 }
                }
            }
        }
    }
}
check(allowedCount > 0 && rejectedCount > 0, "Both buildable and blocked terrain remain present")
check(!VillageTileLayout.buildableSubcell(column:0,row:0,pieces:[]), "Empty space cannot support a building")
let crossedSubcell = VillageCartoMap.Cell(
    x: 5 * VillageCartoMap.subdivisions + 2,
    y: 8 * VillageCartoMap.subdivisions + 3
)
check(VillageCartoMap.biomeForSubcell(crossedSubcell) == .villageSoil,
      "Crossed subcell center alone would look yellow")
check(!VillageCartoMap.canPlaceObject(onSubcell: crossedSubcell),
      "A subcell cut by the yellow-green boundary cannot support a building")

check(VillageCartoMap.buildings.count >= 6,
      "All progression buildings are available")
let house = VillageCartoMap.buildings[0]
let well = VillageCartoMap.buildings[1]
let buMaraHouse = VillageCartoMap.buildings[2]
let barn = VillageCartoMap.buildings[3]
let rolandPen = VillageCartoMap.buildings[4]
let annethHouse = VillageCartoMap.buildings[5]
check(house.id == "arthur-house" && house.title == "Rumah Arthur" &&
      house.width == 6 && house.height == 9 &&
      house.explorationWidth == 2 && house.explorationHeight == 3,
      "Arthur's house is 6x9 on the map and 2x3 in exploration")
check(well.id == "village-well" && well.title == "Sumur" &&
      well.width == 3 && well.height == 3 &&
      well.explorationWidth == 1 && well.explorationHeight == 1,
      "The well is 3x3 on the map and 1x1 in exploration")
check(buMaraHouse.id == "bu-mara-house" && buMaraHouse.title == "Rumah Bu Mara" &&
      buMaraHouse.width == 6 && buMaraHouse.height == 6 &&
      buMaraHouse.explorationWidth == 2 && buMaraHouse.explorationHeight == 2,
      "Bu Mara's house is 6x6 on the map and 2x2 in exploration")
check(barn.id == "village-barn" && barn.title == "Lumbung Desa" &&
      barn.width == 9 && barn.height == 15 &&
      barn.explorationWidth == 3 && barn.explorationHeight == 5,
      "The barn is 9 wide x 15 high on the map and 3x5 in exploration")
check(rolandPen.id == "roland-pen" && rolandPen.title == "Kandang Roland" &&
      rolandPen.width == 12 && rolandPen.height == 9 &&
      rolandPen.explorationWidth == 4 && rolandPen.explorationHeight == 3,
      "Roland's pen is 12x9 on the map and 4x3 in exploration")
check(annethHouse.id == "anneth-house" && annethHouse.title == "Rumah Anneth" &&
      annethHouse.width == 6 && annethHouse.height == 9 &&
      annethHouse.explorationWidth == 2 && annethHouse.explorationHeight == 3,
      "Anneth's house is 6x9 on the map and 2x3 in exploration")

var validSitesByBuilding: [String: [(Int, Int)]] = [:]
var questTwoLayout = VillageTileLayout()
check(questTwoLayout.place(id: 5, column: 7, row: 5, turns: 0),
      "Quest 2 can place the second piece")
check(questTwoLayout.place(id: 20, column: 8, row: 6, turns: 0),
      "Quest 2 can place its unlocked Z piece")
// Empat bangunan awal mempunyai fixture susunan map di validasi ini. Dua
// bangunan berikutnya memakai susunan keping sesuai progres quest masing-masing.
for building in VillageCartoMap.buildings.prefix(4) {
    let placementLayout = building.id == "village-barn" ? questTwoLayout : assembled
    var sites: [(Int, Int)] = []
    for row in 0..<(VillageTileLayout.rows * VillageCartoMap.subdivisions) {
        for column in 0..<(VillageTileLayout.columns * VillageCartoMap.subdivisions) {
            if placementLayout.canPlaceBuilding(id:building.id,subColumn:column,subRow:row) {
                sites.append((column, row))
            }
        }
    }
    validSitesByBuilding[building.id] = sites
    check(!sites.isEmpty, "\(building.title) has a fully yellow placement site")
}
let originalBuildings = assembled.buildingPlacements
check(!assembled.placeBuilding(id:"arthur-house",subColumn:0,subRow:0), "Invalid footprint rejected")
check(assembled.buildingPlacements == originalBuildings, "Building failure is atomic")
if let (column, row) = validSitesByBuilding["arthur-house"]?.first {
    check(assembled.placeBuilding(id:"arthur-house",subColumn:column,subRow:row), "Place Arthur's house on yellow terrain")
    check(VillageTileLayout(data:assembled.encoded).buildingPlacements == assembled.buildingPlacements,
          "Valid outlined-zone building survives save roundtrip")
}

// Dua bangunan boleh mepet tepat pada sisi atau sudut, tetapi satu subgrid
// yang saling tumpang tindih tetap harus ditolak.
var adjacentPair: ((Int, Int), (Int, Int))?
if let houseSites = validSitesByBuilding["arthur-house"],
   let wellSites = validSitesByBuilding["village-well"] {
    outer: for houseSite in houseSites {
        let touchingCandidates = [
            (houseSite.0 + house.width, houseSite.1),
            (houseSite.0 - well.width, houseSite.1),
            (houseSite.0, houseSite.1 + house.height),
            (houseSite.0, houseSite.1 - well.height),
            (houseSite.0 + house.width, houseSite.1 + house.height)
        ]
        for wellSite in touchingCandidates where wellSites.contains(where: { $0 == wellSite }) {
            adjacentPair = (houseSite, wellSite)
            break outer
        }
    }
}
check(adjacentPair != nil, "A fully yellow touching site exists for both buildings")
if let (houseSite, wellSite) = adjacentPair {
    var touching = assembled
    touching.removeBuilding(id: "arthur-house")
    touching.removeBuilding(id: "village-well")
    check(touching.placeBuilding(id: "arthur-house", subColumn: houseSite.0, subRow: houseSite.1),
          "Place Arthur's house for adjacency test")
    check(touching.placeBuilding(id: "village-well", subColumn: wellSite.0, subRow: wellSite.1),
          "Buildings may touch exactly without a forced gap")
}
print("PASS: \(mask.count) outlined-zone subcells; \(allowedCount) rotated valid and \(rejectedCount) invalid checks; six scaled buildings and strict early-quest placement")
