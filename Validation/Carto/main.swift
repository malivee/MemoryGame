import Foundation
import CoreGraphics

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}
let allCells = VillageCartoMap.pieces.flatMap { $0 }
check(allCells.count == VillageCartoMap.columns * VillageCartoMap.rows, "Full source coverage")
check(Set(allCells).count == allCells.count, "No overlapping source cells")

var layout = VillageTileLayout()
let start = VillageTileLayout.initial
let player = layout.world(VillageCartoMap.spawn)!
check(layout.walkable(player), "Starter has a safe spawn")
for id in 0..<VillageTileLayout.count {
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
            let other = (id+1)%VillageTileLayout.count
            let before = single.placements
            check(!single.place(id:other,column:occupied.column,row:occupied.row,turns:0), "Overlap rejected on every cell")
            check(single.placements == before, "Rejected placement is atomic")
        }
    }
}

// Correct original arrangement remains legal, including shared road boundaries.
var assembled = VillageTileLayout()
assembled.remove(id:start.id)
for id in 0..<VillageTileLayout.count {
    let anchor = VillageCartoMap.pieces[id][0]
    check(assembled.place(id:id,column:anchor.x+4,row:anchor.y+4,turns:0), "Source arrangement joins correctly")
}
check(assembled.inventory.isEmpty, "All pieces assembled")
check(VillageTileLayout(data:assembled.encoded).placements == assembled.placements, "Save roundtrip")
let roads = VillageCartoMap.roads
var traversable = 0
for road in roads {
    for (a,b) in zip(road,road.dropFirst()) {
        for i in 1..<20 {
            let t = CGFloat(i)/20
            let source = CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t)
            if let point = assembled.world(source), assembled.walkable(point) { traversable += 1 }
        }
    }
}
check(traversable > 150, "Aligned trails support exploration")

// Matching must examine every exposed subcell edge, not only the anchor.
var good = 0, bad = 0
for id in 0..<VillageTileLayout.count where id != start.id {
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
check(!layout.place(id:14,column:VillageTileLayout.columns-1,row:8,turns:0), "Whole shape must stay in board")
check(!layout.place(id:-1,column:0,row:0,turns:0), "Invalid ID rejected")
check(layout.placements == before, "Invalid placements preserve state")
check(layout.remove(id:start.id), "Starter returned to inventory as one unit")
check(layout.inventory.contains(start.id), "Returned group available")
check(layout.placements.isEmpty, "Empty board allowed")
check(VillageTileLayout(data:layout.encoded).placements.isEmpty, "Empty board persistence")
check(!layout.remove(id:start.id), "Double return rejected")
check(layout.place(id:start.id,column:8,row:5,turns:3), "Place after empty board")
check(layout.walkable(layout.world(VillageCartoMap.spawn)!), "Arthur stays walkable after rotating his group")
check(VillageTileLayout(data:Data("bad".utf8)).placements == [start], "Corrupt save fallback")
let legacy = try JSONEncoder().encode([start])
check(VillageTileLayout(data:legacy).placements == [start], "Old square schema cannot be interpreted as groups")
print("PASS: 45 tetrominoes, all rotations/hit paths, player transforms, \(good) valid and \(bad) invalid placements, \(traversable) road samples, saves and boundaries")

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
for id in 0..<VillageTileLayout.count {
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
                    check(actual == mask.contains(sub), "Build mask follows every rotation and translation")
                    if actual {
                        check(VillageCartoMap.grassBuildPieceIDs.contains(id), "Whitelist remains mandatory")
                        allowedCount += 1
                    } else { rejectedCount += 1 }
                }
            }
        }
    }
}
check(allowedCount > 0 && rejectedCount > allowedCount, "Not every subcell is buildable")
check(!VillageTileLayout.buildableSubcell(column:0,row:0,pieces:[]), "Empty space cannot support a building")
var validSitesByBuilding: [String: [(Int, Int)]] = [:]
for building in VillageCartoMap.buildings {
    var sites: [(Int, Int)] = []
    for row in 0..<(VillageTileLayout.rows * VillageCartoMap.subdivisions) {
        for column in 0..<(VillageTileLayout.columns * VillageCartoMap.subdivisions) {
            if assembled.canPlaceBuilding(id:building.id,subColumn:column,subRow:row) {
                sites.append((column, row))
            }
        }
    }
    validSitesByBuilding[building.id] = sites
    check(!sites.isEmpty, "\(building.title) has a valid outlined-zone site")
}
let originalBuildings = assembled.buildingPlacements
check(!assembled.placeBuilding(id:"building-3x2",subColumn:0,subRow:0), "Invalid footprint rejected")
check(assembled.buildingPlacements == originalBuildings, "Building failure is atomic")
if let (column, row) = validSitesByBuilding["building-3x2"]?.first {
    check(assembled.placeBuilding(id:"building-3x2",subColumn:column,subRow:row), "Place building inside outline")
    check(VillageTileLayout(data:assembled.encoded).buildingPlacements == assembled.buildingPlacements,
          "Valid outlined-zone building survives save roundtrip")
}
print("PASS: \(mask.count) outlined-zone subcells; \(allowedCount) rotated valid and \(rejectedCount) invalid checks; seven building sizes have valid sites")
