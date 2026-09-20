// Penjelasan file: VillagePrototypeScene+Rendering.swift
// Membuat gambar dunia, label landmark, NPC dekoratif, HUD, dan overlay collision opsional.
import SpriteKit
extension VillagePrototypeScene {
    @discardableResult
    func label(_ text:String, at p:CGPoint, size:CGFloat, on parent:SKNode, color:SKColor = .white) -> SKLabelNode {
        parent.storyLabel(text, at: p, size: size, color: color)
    }
    func button(_ text:String, name:String, at p:CGPoint, width:CGFloat=140) {
        let n=hud.storyButton(text,name:name,at:p,width:width)
        n.fillColor=SKColor(red:0.12,green:0.16,blue:0.14,alpha:0.88)
        n.strokeColor=SKColor(red:0.88,green:0.80,blue:0.55,alpha:0.5)
    }
    func buildMap() {
        if let image=VillageArtwork().image() {
            let terrain=SKSpriteNode(texture:SKTexture(cgImage:image));terrain.anchorPoint = .zero
            terrain.size=VillageMap.bounds.size;terrain.zPosition = -10;mapNode.addChild(terrain)
        }
        for place in VillageMap.landmarks {
            label(place.name,at:CGPoint(x:place.rect.midX,y:place.rect.maxY+35),size:12,on:mapNode,
                  color:SKColor(white:1,alpha:0.4))
        }
        label("SUMUR",at:CGPoint(x:905,y:869),size:14,on:mapNode)
        label("Sungai kecil",at:CGPoint(x:1730,y:1330),size:16,on:mapNode)
        label("Ke pinggiran hutan →",at:CGPoint(x:1780,y:335),size:14,on:mapNode)
        // NPC hanya penanda visual. Dialog, hadiah, minigame, dan quest belum dihubungkan.
        for (name,p,color) in [
            ("Kakek",CGPoint(x:570,y:560),SKColor.brown),
            ("Bu Mara",CGPoint(x:1400,y:545),SKColor(red:0.67,green:0.42,blue:0.33,alpha:1)),
            ("Keneth",CGPoint(x:1220,y:1005),SKColor.orange),
            ("Anneth",CGPoint(x:565,y:1280),SKColor.systemTeal),
            ("Roland",CGPoint(x:1550,y:320),SKColor.systemYellow)] {
            let node=MemoryCharacter(title:name,color:color);node.position=p;node.zPosition=12;mapNode.addChild(node)
        }
        actor.zPosition=20;mapNode.addChild(actor)
        mapNode.addChild(collisionOverlay);collisionOverlay.zPosition=40
    }
    func buildHUD() {
        // HUD tetap di koordinat layar sehingga tidak ikut membesar bersama dunia.
        // Posisi, ukuran, font, dan warna mengikuti HUD exploration asli.
        hud.removeAllChildren()
        let width=min(size.width*0.52,460)
        let pill=SKShapeNode(rectOf:CGSize(width:width,height:36),cornerRadius:18)
        pill.position=CGPoint(x:size.width/2,y:size.height-34)
        pill.fillColor=SKColor(red:0.12,green:0.16,blue:0.14,alpha:0.88)
        pill.strokeColor=SKColor(red:0.88,green:0.80,blue:0.55,alpha:0.45)
        pill.lineWidth=1.2;hud.addChild(pill)
        stageLabel=label("Desa di lembah",at:pill.position,size:13,on:hud,
                         color:SKColor(red:0.98,green:0.94,blue:0.82,alpha:1))
        if onExit != nil {
            button("Kembali ke foto",name:"exitVillage",at:CGPoint(x:size.width-92,y:size.height-34),width:145)
        }
        button(overview ? "Jelajahi" : "Peta",name:"overview",at:CGPoint(x:size.width-65,y:55),width:90)
        info=label("Geser stik atau ketuk tanah untuk bergerak",at:CGPoint(x:size.width/2,y:18),size:11,on:hud,
                   color:SKColor(white:1,alpha:0.5))
        info.preferredMaxLayoutWidth=max(100,size.width-230);info.numberOfLines=2
        let base=SKShapeNode(circleOfRadius:44);base.position=stickCenter
        base.fillColor=SKColor(white:0.08,alpha:0.45);base.strokeColor=SKColor(white:1,alpha:0.28)
        base.lineWidth=1.5;hud.addChild(base)
        knob.position=stickCenter;knob.fillColor=SKColor(white:1,alpha:0.45);knob.strokeColor = .clear;hud.addChild(knob)
    }
    func updateCollisionOverlay() {
        collisionOverlay.removeAllChildren();guard showBounds else { return }
        for r in VillageMap.solids {
            let shape=SKShapeNode(rect:r);shape.fillColor=SKColor.red.withAlphaComponent(0.12);shape.strokeColor = .systemRed;collisionOverlay.addChild(shape)
        }
        if access != .wholeVillage {
            for x in stride(from:CGFloat(36),to:1884,by:48) {
                for y in stride(from:CGFloat(36),to:1404,by:48) where !VillageMap.accessible(CGPoint(x:x,y:y),stage:access) {
                    let dot=SKShapeNode(circleOfRadius:3);dot.position=CGPoint(x:x,y:y);dot.fillColor = .systemOrange;dot.strokeColor = .clear;collisionOverlay.addChild(dot)
                }
            }
        }
    }
}
