// Penjelasan file: VillagePrototypeScene.swift
// Dunia desa memakai progres tersimpan; Canvas tanpa storyProgress tetap menjadi preview mandiri.
// Awal eksplorasi dibatasi ke rumah Arthur, Kakek, dan sumur.
import SpriteKit
final class VillagePrototypeScene: SKScene {
    let mapNode = SKNode(), hud = SKNode()
    let actor = MemoryCharacter(title: "Arthur", color: SKColor(red:0.49,green:0.59,blue:0.35,alpha:1))
    // Host menentukan tujuan kembali; Canvas tetap dapat berjalan tanpa callback.
    var onExit: (() -> Void)?
    var isLeaving = false
    var access: VillageAccess = .opening
    var storyProgress: PrologueProgress?
    let storyNPCs = SKNode()
    var activeStoryStep: StoryProgressionStep?
    var dialogueIndex: Int?
    var isWellConversation = false
    var wellResidentIndex = 0
    let storyPanel = SKNode()
    var navigation: VillageNavigation { VillageNavigation(stage: access) }
    var route: [CGPoint] = []
    var overview = false, showBounds = false
    var lastTime: TimeInterval = 0
    var stickTouch: UITouch?
    var stick = CGVector.zero
    var knob = SKShapeNode(circleOfRadius: 18)
    var stickCenter: CGPoint { CGPoint(x: 88, y: 88) }
    var info = SKLabelNode(), stageLabel = SKLabelNode()
    var hintUntil: TimeInterval = 0
    var collisionOverlay = SKNode()
    let memoryFog = SKCropNode()
    override func didMove(to view: SKView) {
        guard mapNode.parent == nil else { return }
        if storyProgress == nil { storyProgress = PrologueStore.shared.progress }
        backgroundColor = SKColor(red:0.10,green:0.16,blue:0.13,alpha:1)
        addChild(mapNode); addChild(hud); hud.zPosition=1000
        if let storyProgress { access = StoryProgression.villageAccess(for: storyProgress) }
        buildMap(); buildHUD(); actor.position=VillageMap.spawn
        refreshStory()
        updateCamera(immediate: true)
    }
    func setAccess(_ value: VillageAccess) {
        access=value; route=[]; stick = .zero; stickTouch=nil; knob.position=stickCenter
        if !navigation.walkable(actor.position) { actor.position=VillageMap.spawn }
        stageLabel.text="Desa di lembah"
        updateMemoryFog(); updateCollisionOverlay(); updateCamera(immediate: true)
    }
    // Rumus zoom dan interpolasi sama dengan ExplorationScene bawaan proyek.
    var worldScale: CGFloat { max(1.45, min(1.85, size.height / 250)) }
    override func didChangeSize(_ oldSize: CGSize) {
        guard mapNode.parent != nil else { return }
        stickTouch=nil;stick = .zero
        buildHUD();renderStoryDialogue();updateCamera(immediate: true)
    }
    func updateCamera(dt: CGFloat = 0, immediate: Bool = false) {
        let bounds=VillageMap.bounds
        let scale = overview ? min(size.width/bounds.width,size.height/bounds.height)*0.94 : worldScale
        mapNode.setScale(scale)
        func offset(_ actor: CGFloat, _ extent: CGFloat, _ screen: CGFloat) -> CGFloat {
            let length=extent*scale
            if overview || length <= screen { return (screen-length)/2 }
            return min(0,max(screen-length,screen/2-actor*scale))
        }
        let target=CGPoint(x:offset(actor.position.x,bounds.width,size.width),
                           y:offset(actor.position.y,bounds.height,size.height))
        let blend: CGFloat = immediate ? 1 : min(1,dt*7.5)
        mapNode.position.x += (target.x-mapNode.position.x)*blend
        mapNode.position.y += (target.y-mapNode.position.y)*blend
    }
    override func update(_ currentTime: TimeInterval) {
        let dt=CGFloat(min(0.04,max(0,lastTime == 0 ? 0:currentTime-lastTime))); lastTime=currentTime
        if !overview && dialogueIndex == nil {
            var delta=CGVector(dx:stick.dx*140*dt,dy:stick.dy*140*dt)
            if hypot(stick.dx,stick.dy)<0.05, let target=route.first {
                let dx=target.x-actor.position.x,dy=target.y-actor.position.y,d=hypot(dx,dy)
                if d<5 { route.removeFirst() }
                else { let amount=min(d,140*dt); delta=CGVector(dx:dx/d*amount,dy:dy/d*amount) }
            }
            let next=navigation.moved(from:actor.position,by:delta)
            if hypot(delta.dx,delta.dy)>0.01 {
                if hypot(next.x-actor.position.x,next.y-actor.position.y)<0.01 { route=[] }

            }
            actor.applyMovement(dx: next.x-actor.position.x, dy: next.y-actor.position.y, dt: dt)
            actor.position=next; actor.zPosition=20; updateCamera(dt: dt)
        }
        if currentTime>hintUntil {
            let nearest=VillageMap.landmarks.min { hypot($0.approach.x-actor.position.x,$0.approach.y-actor.position.y)<hypot($1.approach.x-actor.position.x,$1.approach.y-actor.position.y) }
            info.text = activeStoryStep?.title ?? nearest.map { hypot($0.approach.x-actor.position.x,$0.approach.y-actor.position.y)<110 ? $0.name : "Jelajahi jalan desa · ketuk tanah atau gunakan stik" }
        }
    }
    func hint(_ text: String) { info.text=text; hintUntil=lastTime+4 }
}
