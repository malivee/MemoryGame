// Editor peta bebas: inventori, drag/drop dan rotasi tanpa target susunan.
// Layer dunia memakai susunan serta rotasi yang sama, tanpa mengubah save cerita.
import SpriteKit
import UIKit

final class VillageCartoScene: SKScene {
    var onExit: (() -> Void)?
    private static let saveKey = "village.carto.layout.v2"
    private var layout = VillageTileLayout(data: UserDefaults.standard.data(forKey: saveKey))
    private let world = SKNode(), hud = SKNode(), backdrop = SKNode()
    private let viewport = SKCropNode()
    private let actor = MemoryCharacter(title: "Arthur", color: .systemGreen)
    private let village = SKTexture(imageNamed: "DesaArthurTerrain")
    private var isMap = true
    private var selected: Int?, draftTurns = 0, page = 0
    private var sourcePosition = VillageMap.spawn
    private var mapCenter = VillageTileLayout.initial.center
    private var zoom: CGFloat = 1
    private var activeTouch: UITouch?, touchStart = CGPoint.zero, panStart = CGPoint.zero
    private var dragging = false, panning = false
    private var ghost: SKNode?
    private var inventoryHits: [(id: Int, rect: CGRect)] = []
    private var inventoryArea: CGRect { CGRect(x:size.width-178,y:58,width:168,height:size.height-120) }
    private var stickTouch: UITouch?, stick = CGVector.zero
    private var knob = SKShapeNode(circleOfRadius: 19)
    private var route: [CGPoint] = [], lastTime: TimeInterval = 0
    private let status = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var board: CGRect { CGRect(x:20,y:80,width:max(150,size.width-208),height:max(110,size.height-148)) }
    private var stickCenter: CGPoint { CGPoint(x:85,y:105) }
    // Semua keping tersedia, termasuk keping tanpa jalan.
    private var available: [Int] { layout.inventory }
    private let pageSize = 6
    private var pages: Int { max(1,Int(ceil(Double(available.count)/6))) }
    private let cream = SKColor(red:0.94,green:0.90,blue:0.65,alpha:1)

    override func didMove(to view: SKView) {
        guard world.parent == nil else { return }
        backgroundColor = SKColor(red:0.045,green:0.20,blue:0.24,alpha:1)
        addChild(backdrop); addChild(viewport); viewport.addChild(world); addChild(hud); hud.zPosition = 1000
        village.filteringMode = .linear
        rebuild()
    }
    private func text(_ value: String, at p: CGPoint, size: CGFloat = 14, parent: SKNode, color: SKColor = .white) {
        let node = SKLabelNode(fontNamed:"AvenirNext-DemiBold")
        node.text = value; node.position = p; node.fontSize = size; node.fontColor = color
        node.verticalAlignmentMode = .center; parent.addChild(node)
    }
    private func button(_ title: String, name: String, at p: CGPoint, width: CGFloat = 110) {
        let node = SKShapeNode(rectOf:CGSize(width:width,height:36),cornerRadius:10)
        node.position = p; node.name = name
        node.fillColor = SKColor(red:0.08,green:0.25,blue:0.28,alpha:1)
        node.strokeColor = cream.withAlphaComponent(0.5); node.lineWidth = 1.2
        text(title,at:.zero,size:13,parent:node,color:cream)
        node.children.first?.name = name; hud.addChild(node)
    }

    // Peta dibuat sebagai ilustrasi vektor: tanah, hutan, sungai dan jalan saja.
    // Koordinat jalan berasal dari model desa, sehingga port cocok dengan dunia.
    private func tile(_ id: Int, turns: Int, miniature: Bool) -> SKNode {
        let s = VillageTileLayout.side, h = s/2, origin = VillageTileLayout.sourceOrigin(id)
        let node = SKNode(); node.zRotation = CGFloat(turns) * .pi / 2
        if miniature {
            let crop = SKCropNode()
            let mask = SKSpriteNode(color:.white,size:CGSize(width:s,height:s)); crop.maskNode = mask
            let ground = SKSpriteNode(color:SKColor(red:0.63,green:0.72,blue:0.39,alpha:1),size:CGSize(width:s,height:s))
            crop.addChild(ground)
            func line(_ points: [CGPoint], color: SKColor, width: CGFloat) {
                guard let first = points.first else { return }
                let path = CGMutablePath(); path.move(to:CGPoint(x:first.x-origin.x-h,y:first.y-origin.y-h))
                for p in points.dropFirst() { path.addLine(to:CGPoint(x:p.x-origin.x-h,y:p.y-origin.y-h)) }
                let shape = SKShapeNode(path:path); shape.strokeColor = color; shape.lineWidth = width
                shape.lineCap = .round; shape.lineJoin = .round; crop.addChild(shape)
            }
            line(VillageMap.river,color:SKColor(red:0.38,green:0.72,blue:0.76,alpha:1),width:32)
            // Pohon kecil deterministik; tidak menutupi jalan atau halaman rumah.
            for i in 0..<28 {
                let x = CGFloat((i*73+id*29)%215)+10, y = CGFloat((i*47+id*61)%215)+10
                let p = CGPoint(x:origin.x+x,y:origin.y+y)
                guard !VillageMap.onWalkableGround(p), !VillageMap.solids.contains(where:{$0.insetBy(dx:-10,dy:-10).contains(p)}) else { continue }
                let path = CGMutablePath(); path.move(to:CGPoint(x:x-h,y:y-h+9))
                path.addLine(to:CGPoint(x:x-h-5,y:y-h-6)); path.addLine(to:CGPoint(x:x-h+5,y:y-h-6)); path.closeSubpath()
                let tree = SKShapeNode(path:path); tree.fillColor = SKColor(red:0.22,green:0.42,blue:0.28,alpha:0.85)
                tree.strokeColor = .clear; crop.addChild(tree)
            }
            for road in VillageMap.roads { line(road,color:cream,width:23) }
            node.addChild(crop)
        } else {
            let rect = CGRect(x:origin.x/1672,y:origin.y/941,width:s/1672,height:s/941)
            let texture = SKTexture(rect:rect,in:village); texture.filteringMode = .linear
            node.addChild(SKSpriteNode(texture:texture,size:CGSize(width:s,height:s)))
        }
        if miniature {
            // Garis kertas agak tidak rata, bukan bingkai papan penuh.
            let path = CGMutablePath(); path.move(to:CGPoint(x:-h,y:-h))
            for edge in 0..<4 {
                for step in 1...8 {
                    let t = CGFloat(step)/8, wobble: CGFloat = step == 8 ? 0 : (step%2 == 0 ? 1.2 : -1.2)
                    let p: CGPoint
                    switch edge {
                    case 0: p = CGPoint(x:-h+s*t,y:-h+wobble)
                    case 1: p = CGPoint(x:h+wobble,y:-h+s*t)
                    case 2: p = CGPoint(x:h-s*t,y:h+wobble)
                    default: p = CGPoint(x:-h+wobble,y:h-s*t)
                    }
                    path.addLine(to:p)
                }
            }
            path.closeSubpath()
            let border = SKShapeNode(path:path); border.strokeColor = selected == id ? .systemOrange : cream
            border.lineWidth = selected == id ? 9 : 5; border.fillColor = .clear
            let ink = SKShapeNode(path:path); ink.strokeColor = SKColor(white:0.08,alpha:0.8)
            ink.lineWidth = border.lineWidth+5; ink.fillColor = .clear; node.addChild(ink); node.addChild(border)
            // Ujung jalan ditandai langsung pada border dan ikut rotasi keping.
            for edge in 0..<4 { for value in VillageTileLayout.roadPorts[id][edge] {
                let marker = SKShapeNode(rectOf:edge%2 == 0 ? CGSize(width:9,height:24) : CGSize(width:24,height:9))
                switch edge {
                case 0: marker.position = CGPoint(x:h,y:value-h)
                case 1: marker.position = CGPoint(x:value-h,y:h)
                case 2: marker.position = CGPoint(x:-h,y:value-h)
                default: marker.position = CGPoint(x:value-h,y:-h)
                }
                marker.fillColor = .systemOrange; marker.strokeColor = cream; marker.lineWidth = 2; node.addChild(marker)
            } }
            let badge = SKShapeNode(rectOf:CGSize(width:48,height:30),cornerRadius:6)
            badge.position = CGPoint(x:-h+30,y:h-24); badge.fillColor = SKColor(white:0.08,alpha:0.8); badge.strokeColor = .clear
            badge.zRotation = -node.zRotation; text("\(id+1)",at:.zero,size:20,parent:badge); node.addChild(badge)
        }
        return node
    }

    private func rebuild(_ message: String? = nil) {
        let mask = SKShapeNode(rect:isMap ? board : CGRect(origin:.zero,size:size))
        mask.fillColor = .white; mask.strokeColor = .clear; viewport.maskNode = mask
        ghost?.removeFromParent(); ghost = nil; inventoryHits = []
        actor.removeFromParent(); world.removeAllChildren(); hud.removeAllChildren(); backdrop.removeAllChildren()
        // Motif garis air di ruang kosong, tetap ringan karena hanya node vektor.
        if isMap {
            for row in 0..<8 { for col in 0..<14 {
                let p = CGMutablePath(); p.move(to:.zero); p.addLine(to:CGPoint(x:7,y:3)); p.addLine(to:CGPoint(x:14,y:0)); p.addLine(to:CGPoint(x:21,y:3))
                let wave = SKShapeNode(path:p); wave.strokeColor = SKColor(white:1,alpha:0.07)
                wave.position = CGPoint(x:CGFloat(col)*92+CGFloat(row%2)*25,y:CGFloat(row)*72+25); backdrop.addChild(wave)
            } }
        }
        for piece in layout.placements {
            let displayedTurns = isMap && selected == piece.id ? draftTurns : piece.turns
            let node = tile(piece.id,turns:displayedTurns,miniature:isMap)
            if displayedTurns != piece.turns { node.alpha = 0.65 }
            node.position = piece.center; world.addChild(node)
        }
        // Keping Arthur boleh dikembalikan. Cari tempat aman di keping tersisa.
        if layout.world(sourcePosition) == nil {
            for piece in layout.placements {
                if let safe = nearestSafePoint(piece.center), let source = layout.source(safe) { sourcePosition = source; break }
            }
        }
        if let position = layout.world(sourcePosition) {
            actor.position = position
            if !layout.walkable(position), let p = nearestSafePoint(position) {
                actor.position = p; sourcePosition = layout.source(p) ?? sourcePosition
            }
            if !isMap {
                actor.zPosition = 20; world.addChild(actor)
            } else {
                let marker = SKShapeNode(circleOfRadius:10); marker.fillColor = .systemOrange
                marker.strokeColor = .white; marker.lineWidth = 2; marker.position = actor.position; marker.zPosition = 20; world.addChild(marker)
            }
        }

        button("Kembali",name:"exit",at:CGPoint(x:80,y:size.height-32))
        button(isMap ? "Jelajahi" : "Susun peta",name:"toggle",at:CGPoint(x:size.width-90,y:size.height-32),width:135)
        text(isMap ? "KEPING DESA" : "DESA ARTHUR",at:CGPoint(x:size.width/2,y:size.height-30),size:18,parent:hud,color:cream)
        if isMap {
            let panel = SKShapeNode(rect:CGRect(x:size.width-178,y:58,width:168,height:size.height-120),cornerRadius:14)
            panel.fillColor = SKColor(red:0.035,green:0.15,blue:0.18,alpha:0.98); panel.strokeColor = cream.withAlphaComponent(0.2); hud.addChild(panel)
            text("INVENTORI / BALIKKAN",at:CGPoint(x:size.width-94,y:size.height-85),size:13,parent:hud,color:cream)
            page = min(page,pages-1)
            let thumb = min(CGFloat(65),max(28,(size.height-252)/2.5))
            for (index,id) in available.dropFirst(page*pageSize).prefix(pageSize).enumerated() {
                let node = tile(id,turns:selected == id ? draftTurns : 0,miniature:true)
                node.setScale(max(0.1,thumb/VillageTileLayout.side)); node.name = "inventory-\(id)"
                node.position = CGPoint(x:size.width-134+CGFloat(index%2)*80,y:size.height-120-CGFloat(index/2)*(thumb+13))
                hud.addChild(node)
                inventoryHits.append((id,CGRect(x:node.position.x-thumb/2,y:node.position.y-thumb/2,width:thumb,height:thumb)))
            }
            button("‹",name:"prev",at:CGPoint(x:size.width-147,y:82),width:35)
            button("›",name:"next",at:CGPoint(x:size.width-39,y:82),width:35)
            text("\(page+1)/\(pages)",at:CGPoint(x:size.width-94,y:82),size:12,parent:hud,color:cream)
            button("Putar 90°",name:"rotate",at:CGPoint(x:82,y:56),width:120)
            button("Balikkan keping",name:"remove",at:CGPoint(x:219,y:56),width:140)
            button("−",name:"minus",at:CGPoint(x:315,y:56),width:38)
            button("+",name:"plus",at:CGPoint(x:362,y:56),width:38)
            button("Pusatkan",name:"center",at:CGPoint(x:435,y:56),width:90)
            if let id = selected {
                text("Keping \(id+1) · \(draftTurns*90)°",at:CGPoint(x:board.midX,y:size.height-58),size:12,parent:hud,color:cream)
            }
        } else {
            let base = SKShapeNode(circleOfRadius:49); base.position = stickCenter
            base.fillColor = SKColor(white:0.1,alpha:0.45); base.strokeColor = .clear; hud.addChild(base)
            knob = SKShapeNode(circleOfRadius:19); knob.position = stickCenter
            knob.fillColor = SKColor(white:1,alpha:0.65); knob.strokeColor = .clear; hud.addChild(knob)
        }
        status.removeFromParent(); status.fontSize = 11; status.fontColor = cream; status.verticalAlignmentMode = .center
        status.position = CGPoint(x:size.width/2,y:19); hud.addChild(status)
        status.text = message ?? (isMap ? "Border oranye = pilihan · Tanda ujung jalan harus cocok · Geser keping ke inventori untuk membalikkan." : "Geser stik atau ketuk jalan. Ruang kosong tidak bisa dilalui.")
        updateCamera()
    }
    private func nearestSafePoint(_ current: CGPoint) -> CGPoint? {
        guard let piece = layout.placement(at:current) else { return nil }
        var result: CGPoint?, distance = CGFloat.greatestFiniteMagnitude
        for x in stride(from:CGFloat(12),to:VillageTileLayout.side-12,by:8) {
            for y in stride(from:CGFloat(12),to:VillageTileLayout.side-12,by:8) {
                let p = CGPoint(x:piece.origin.x+x,y:piece.origin.y+y), d = hypot(p.x-current.x,p.y-current.y)
                if d < distance && layout.walkable(p) { distance = d; result = p }
            }
        }
        return result
    }
    private func updateCamera() {
        if isMap {
            let scale = min(board.width/(VillageTileLayout.side*5),board.height/(VillageTileLayout.side*3))*zoom
            world.setScale(scale); world.position = CGPoint(x:board.midX-mapCenter.x*scale,y:board.midY-mapCenter.y*scale)
        } else {
            let scale = min(1.1,max(0.8,size.height/440)); world.setScale(scale)
            world.position = CGPoint(x:size.width/2-actor.position.x*scale,y:size.height/2-actor.position.y*scale)
        }
    }
    override func didChangeSize(_ oldSize: CGSize) {
        guard world.parent != nil else { return }; stopInput(); rebuild()
    }
    private func stopInput() { activeTouch = nil; stickTouch = nil; stick = .zero; route = []; dragging = false; panning = false; ghost?.removeFromParent(); ghost = nil }
    private func save() { if let data = layout.encoded { UserDefaults.standard.set(data,forKey:Self.saveKey) } }
    private func returnSelected() {
        guard let id = selected else { status.text = "Pilih keping yang ingin dibalikkan."; return }
        if layout.remove(id:id) {
            save(); selected = nil
            if let index = available.firstIndex(of:id) { page = index/pageSize }
            rebuild("Keping \(id+1) kembali ke inventori.")
        } else { status.text = "Keping ini sudah ada di inventori." }
    }
    private func select(_ id: Int) {
        if selected != id { draftTurns = layout.placements.first(where:{$0.id == id})?.turns ?? 0 }
        selected = id; rebuild()
    }
    private func updateStick(_ touch: UITouch) {
        let p = touch.location(in:hud), dx = p.x-stickCenter.x, dy = p.y-stickCenter.y
        let length = max(1,hypot(dx,dy)), amount = min(1,length/40)
        stick = CGVector(dx:dx/length*amount,dy:dy/length*amount)
        knob.position = CGPoint(x:stickCenter.x+stick.dx*30,y:stickCenter.y+stick.dy*30)
    }
    private func names(at p: CGPoint) -> Set<String> {
        var result = Set<String>()
        for node in hud.nodes(at:p) {
            var current: SKNode? = node
            while let n = current, n !== hud { if let name = n.name { result.insert(name) }; current = n.parent }
        }
        return result
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, stickTouch == nil, let touch = touches.first else { return }
        let p = touch.location(in:hud), actions = names(at:p)
        if actions.contains("exit") { stopInput(); onExit?(); return }
        if actions.contains("toggle") {
            if isMap && (layout.world(sourcePosition) == nil || !layout.walkable(layout.world(sourcePosition)!)) {
                status.text = "Pasang keping dengan tempat berjalan dahulu sebelum menjelajah."; return
            }
            if isMap, let id = selected, let piece = layout.placements.first(where:{$0.id == id}), piece.turns != draftTurns {
                status.text = "Rotasi belum diterapkan. Taruh di slot kosong atau pilih keping lain untuk batal."
                return
            }
            stopInput(); isMap.toggle(); selected = nil; rebuild(); return
        }
        if isMap {
            if actions.contains("rotate") {
                guard selected != nil else { status.text = "Pilih keping terlebih dahulu."; return }
                draftTurns = (draftTurns+1)%4
                if let id = selected, let piece = layout.placements.first(where:{$0.id == id}) {
                    if layout.place(id:id,column:piece.column,row:piece.row,turns:draftTurns) {
                        save(); rebuild("Keping diputar 90°.")
                    } else { rebuild("Rotasi belum dipasang: ujung jalan tidak cocok. Pindahkan keping ke ruang kosong.") }
                } else { rebuild("Rotasi siap. Letakkan keping di slot kosong untuk menerapkan.") }
                return
            }
            if actions.contains("remove") { returnSelected(); return }
            if actions.contains("prev") || actions.contains("next") { page = (page+(actions.contains("next") ? 1 : pages-1))%pages; rebuild(); return }
            if actions.contains("plus") || actions.contains("minus") { zoom = max(0.5,min(2,zoom*(actions.contains("plus") ? 1.2 : 1/1.2))); updateCamera(); return }
            if actions.contains("center") { mapCenter = layout.world(sourcePosition) ?? VillageTileLayout.initial.center; updateCamera(); return }
            // Hitbox memakai kotak thumbnail, bukan path jalan di dalam crop
            // (path tersebut bisa memanjang ke thumbnail lain meski tidak terlihat).
            if let hit = inventoryHits.first(where: { $0.rect.contains(p) }) {
                select(hit.id); activeTouch = touch; touchStart = p; return
            }
            guard board.contains(p) else { return }
            let q = touch.location(in:world)
            if let piece = layout.placement(at:q) {
                select(piece.id); activeTouch = touch; touchStart = p
            } else {
                activeTouch = touch; touchStart = p; panStart = mapCenter; panning = true
            }
        } else {
            guard p.y < size.height-58, p.y > 38 else { return }
            if hypot(p.x-stickCenter.x,p.y-stickCenter.y) < 62 { stickTouch = touch; route = []; updateStick(touch) }
            else {
                route = layout.route(from:actor.position,to:touch.location(in:world))
                if route.isEmpty { status.text = "Tidak ada jalan ke sana. Coba susun kembali kepingnya." }
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = stickTouch, touches.contains(touch) { updateStick(touch); return }
        guard let touch = activeTouch,touches.contains(touch) else { return }
        let p = touch.location(in:hud)
        dragging = dragging || hypot(p.x-touchStart.x,p.y-touchStart.y)>7
        guard dragging else { return }
        if panning {
            mapCenter = CGPoint(x:max(0,min(VillageTileLayout.bounds.width,panStart.x-(p.x-touchStart.x)/world.xScale)),y:max(0,min(VillageTileLayout.bounds.height,panStart.y-(p.y-touchStart.y)/world.yScale)))
            updateCamera()
        } else if let id = selected {
            if ghost == nil { let node = tile(id,turns:draftTurns,miniature:true); node.alpha = 0.8; node.zPosition = 40; world.addChild(node); ghost = node }
            ghost?.position = touch.location(in:world)
            world.childNode(withName:"dropSlot")?.removeFromParent()
            if let (col,row) = VillageTileLayout.cell(touch.location(in:world)) {
                let slot = SKShapeNode(rectOf:CGSize(width:VillageTileLayout.side-4,height:VillageTileLayout.side-4))
                slot.name = "dropSlot"; slot.position = CGPoint(x:(CGFloat(col)+0.5)*VillageTileLayout.side,y:(CGFloat(row)+0.5)*VillageTileLayout.side)
                slot.strokeColor = layout.canPlace(id:id,column:col,row:row,turns:draftTurns) ? .systemGreen : .systemRed
                slot.fillColor = .clear; slot.lineWidth = 4; slot.zPosition = 41; world.addChild(slot)
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = stickTouch,touches.contains(touch) { stickTouch = nil; stick = .zero; knob.position = stickCenter; return }
        guard let touch = activeTouch,touches.contains(touch) else { return }
        let wasDrag = dragging, wasPan = panning, p = touch.location(in:hud), q = touch.location(in:world)
        stopInput()
        if wasDrag && !wasPan && inventoryArea.contains(p) { returnSelected(); return }
        let changedRotation = selected.flatMap { id in layout.placements.first(where:{$0.id == id}) }.map { $0.turns != draftTurns } ?? false
        if let id = selected, board.contains(p), ((!wasPan && (wasDrag || changedRotation)) || (wasPan && !wasDrag)), let (col,row) = VillageTileLayout.cell(q) {
            if layout.place(id:id,column:col,row:row,turns:draftTurns) { save(); rebuild("Keping diletakkan. Posisi dan rotasinya diterapkan ke dunia.") }
            else { rebuild("Tidak bisa menempel: ujung jalan harus cocok. Coba putar atau pilih slot kosong lain.") }
        } else { rebuild() }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { stopInput(); rebuild() }
    override func update(_ time: TimeInterval) {
        let dt = CGFloat(min(0.04,max(0,lastTime == 0 ? 0 : time-lastTime))); lastTime = time
        guard !isMap else { return }
        var delta = CGVector(dx:stick.dx*140*dt,dy:stick.dy*140*dt)
        if hypot(stick.dx,stick.dy)<0.05, let goal = route.first {
            let dx = goal.x-actor.position.x, dy = goal.y-actor.position.y, d = hypot(dx,dy)
            if d < 3 { route.removeFirst() }
            else { let amount = min(d,140*dt); delta = CGVector(dx:dx/d*amount,dy:dy/d*amount) }
        }
        let next = layout.moved(from:actor.position,by:delta)
        actor.applyMovement(dx:next.x-actor.position.x,dy:next.y-actor.position.y,dt:dt)
        actor.position = next; sourcePosition = layout.source(next) ?? sourcePosition; updateCamera()
    }
}
