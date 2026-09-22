import Foundation
import CoreGraphics
func check(_ condition: @autoclosure () -> Bool,_ message:String) { if !condition() { fatalError(message) } }
var layout = VillageTileLayout()
let start = VillageTileLayout.initial
var good = 0, bad = 0
for id in 0..<28 where id != start.id {
 for turn in 0..<4 {
  for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
   let p = VillageTileLayout.Placement(id:id,column:start.column+dx,row:start.row+dy,turns:turn)
   let matches = VillageTileLayout.matching(start,p)
   check(layout.canPlace(id:id,column:p.column,row:p.row,turns:turn) == matches,"Placement must obey every touching road edge")
   if matches { good += 1 } else { bad += 1 }
  }
 }
}
check(good > 0 && bad > 0,"Both accepted and rejected edge cases")
check(layout.place(id:0,column:0,row:0,turns:2),"Detached placements still free")
check(layout.remove(id:start.id),"Starter/Arthur tile can return to inventory")
check(layout.inventory.contains(start.id),"Returned tile in inventory")
check(layout.remove(id:0),"Last tile can be returned")
check(layout.placements.isEmpty,"Empty board")
check(VillageTileLayout(data:layout.encoded).placements.isEmpty,"Empty board save roundtrip")
check(!layout.remove(id:0),"Double return rejected")
check(layout.place(id:start.id,column:8,row:5,turns:3),"Re-place after empty board")
let world = layout.world(VillageMap.spawn)!
let restored = layout.source(world)!
check(hypot(restored.x-VillageMap.spawn.x,restored.y-VillageMap.spawn.y)<0.0001,"Rotated player coordinate preserved")
check(layout.walkable(world),"Replaced player still walkable")
let before = layout.placements
check(!layout.place(id:2,column:8,row:5,turns:0),"Overlap rejected")
check(layout.placements == before,"Failed placement atomic")
check(VillageTileLayout(data:Data("bad".utf8)).placements == [start],"Corrupt save fallback")
check(VillageTileLayout(data:layout.encoded).placements == layout.placements,"Save roundtrip")
print("PASS: \(good) matching and \(bad) mismatched neighbors, rotations, free isolated placement, return all pieces, empty board/save, overlap and player transform")
