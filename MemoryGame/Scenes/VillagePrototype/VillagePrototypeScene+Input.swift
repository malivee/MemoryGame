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
        guard activeQTE == nil else { return }
        let p=t.location(in:hud), names=Set(hud.nodes(at:p).compactMap(\.name))
        // Hentikan gerak dan cegah transisi berulang ketika Kembali diketuk.
        if names.contains("exitVillage"), let onExit {
            isLeaving=true;route=[];stick = .zero;stickTouch=nil
            onExit();return
        }
        if dialogueIndex != nil { advanceStoryDialogue(); return }
        if names.contains("overview") { overview.toggle();route=[];stick = .zero;stickTouch=nil;knob.position=stickCenter;buildHUD();updateCamera(immediate: true);return }
        if !overview && hypot(p.x-stickCenter.x,p.y-stickCenter.y)<65 { stickTouch=t;route=[];updateStick(t);return }
        let destination=t.location(in:mapNode)
        if !overview,
           hypot(rackInteraction.position.x-destination.x,
                 rackInteraction.position.y-destination.y) < 70,
           rackInteraction.isHidden == false {
            if hypot(rackInteraction.position.x-actor.position.x,
                     rackInteraction.position.y-actor.position.y) <= 150 {
                startRackQTE()
            } else {
                let approach=CGPoint(x:1415,y:545)
                route=navigation.route(from:actor.position,to:approach)
                hint("Dekati rak miring di halaman Bu Mara.")
            }
            return
        }
        if !overview, let npc = storyNPCs.children.first(where: {
            hypot($0.position.x-destination.x, $0.position.y-destination.y) < 85
        }) {
            if hypot(npc.position.x-actor.position.x, npc.position.y-actor.position.y) <= 145 {
                route=[];stick = .zero;stickTouch=nil;knob.position=stickCenter
                isWellConversation = npc.name?.hasPrefix("well-resident-") == true
                if isWellConversation,
                   let suffix = npc.name?.split(separator: "-").last,
                   let index = Int(suffix) {
                    wellResidentIndex = index
                }
                dialogueIndex=0;renderStoryDialogue()
            } else {
                route=navigation.route(from: actor.position, to: npc.position)
                hint("Dekati lalu ketuk tokoh untuk berbicara.")
            }
            return
        }
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
