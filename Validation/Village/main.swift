import Foundation
import CoreGraphics
var failures=0
for stage in VillageAccess.allCases {
 let nav=VillageNavigation(stage:stage)
 let points = VillageMap.landmarks.filter{$0.stage.rawValue<=stage.rawValue}.map{($0.id,$0.approach)} + [("water",VillageMap.wellApproach),("rack",VillageMap.rackApproach)]
 for (id,p) in points {
  if !nav.walkable(p) || nav.route(from:VillageMap.spawn,to:p).isEmpty { print("FAIL",stage,id,p);failures += 1 }
 }
}
for p in [VillageMap.point(100,400),VillageMap.point(850,870),VillageMap.point(400,170)] {
 if VillageNavigation(stage:.wholeVillage).walkable(p) {failures += 1;print("FAIL cliff/water")}
}
for (step,center) in VillageMap.storyPositions where [5,7,11,12].contains(step) {
 for delta in [CGPoint(x:-24,y:0),CGPoint(x:0,y:-22),CGPoint(x:24,y:0)] {
  let p=CGPoint(x:center.x+delta.x,y:center.y+delta.y)
  if !VillageNavigation(stage:.wholeVillage).walkable(p) { print("FAIL npc",step,p);failures += 1 }
 }
}
print("Failures:",failures)
exit(failures == 0 ? 0 : 1)
