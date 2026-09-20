import Foundation
import CoreGraphics
var count=0
func check(_ value: @autoclosure () -> Bool, _ message:String) { precondition(value(),message);count += 1 }
for stage in VillageAccess.allCases {
    let nav=VillageNavigation(stage:stage)
    check(nav.walkable(VillageMap.spawn),"Spawn safe at every stage")
    for landmark in VillageMap.landmarks {
        let accessible=landmark.stage.rawValue<=stage.rawValue
        check(nav.walkable(landmark.approach)==accessible,"Stage access: \(landmark.id), \(stage)")
        if accessible { check(!nav.route(from:VillageMap.spawn,to:landmark.approach).isEmpty,"Route reaches \(landmark.id)") }
        check(!nav.walkable(CGPoint(x:landmark.rect.midX,y:landmark.rect.midY)),"Cannot enter solid building")
    }
    check(!nav.walkable(CGPoint(x:-10,y:700)),"World boundary")
    let start=CGPoint(x:905,y:700)
    let reached=nav.moved(from:start,by:CGVector(dx:0,dy:400))
    check(reached.y < VillageMap.well.minY,"Long move cannot tunnel through well")
}
check(!VillageNavigation(stage:.opening).walkable(CGPoint(x:750,y:1000)),"North route initially locked")
check(VillageNavigation(stage:.barnRoute).walkable(CGPoint(x:750,y:1000)),"North route unlocks")
check(!VillageNavigation(stage:.barnRoute).walkable(VillageMap.landmarks[3].approach),"Anneth remains locked until stage 3")
print("Passed \(count) village navigation and access checks.")
