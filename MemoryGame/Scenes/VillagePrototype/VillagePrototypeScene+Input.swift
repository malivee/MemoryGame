// Penjelasan file: VillagePrototypeScene+Input.swift
// Mengatur stik, ketuk tanah, denah, dan tombol kembali ke layar pembuka.
import SpriteKit
extension VillagePrototypeScene {
    func updateStick(_ touch:UITouch) {
        let p=touch.location(in:hud),dx=p.x-stickCenter.x,dy=p.y-stickCenter.y,length=max(1,hypot(dx,dy))
        let force=min(1,length/40);stick=CGVector(dx:dx/length*force,dy:dy/length*force)
        knob.position=CGPoint(x:stickCenter.x+stick.dx*30,y:stickCenter.y+stick.dy*30)
    }
    override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
        guard !isLeaving, let t=touches.first else { return }
        let p=t.location(in:hud), names=Set(hud.nodes(at:p).compactMap(\.name))
        // Hentikan gerak dan cegah transisi berulang ketika Kembali diketuk.
        if names.contains("exitVillage"), let onExit {
            isLeaving=true;route=[];stick = .zero;stickTouch=nil
            onExit();return
        }
        if names.contains("overview") { overview.toggle();route=[];stick = .zero;stickTouch=nil;knob.position=stickCenter;buildHUD();updateCamera(immediate: true);return }
        if !overview && hypot(p.x-stickCenter.x,p.y-stickCenter.y)<65 { stickTouch=t;route=[];updateStick(t);return }
        let destination=t.location(in:mapNode)
        if overview {
            if let place=VillageMap.landmarks.first(where: { $0.rect.insetBy(dx:-30,dy:-30).contains(destination) }) { hint(place.detail) }
            return
        }
        guard p.y < size.height-65,p.y > 35 else { return }
        guard navigation.walkable(destination) else { hint("Jalur tertutup bangunan atau batas tahap. Coba jalan lain.");return }
        route=navigation.route(from:actor.position,to:destination)
        if route.isEmpty { hint("Belum ada jalur ke tempat itu pada tahap ini.") }
    }
    override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) {
        if let t=stickTouch,touches.contains(t) { updateStick(t) }
    }
    override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) {
        if let t=stickTouch,touches.contains(t) { stickTouch=nil;stick = .zero;knob.position=stickCenter }
    }
    override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?) {
        stickTouch=nil;stick = .zero;knob.position=stickCenter;route=[]
    }
}
