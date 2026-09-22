// Editor peta bebas: inventori, drag/drop dan rotasi tanpa target susunan.
// Layer dunia memakai susunan serta rotasi yang sama, tanpa mengubah save cerita.
import SpriteKit
import UIKit

final class VillageCartoScene: SKScene {
    var onExit: (() -> Void)?
    private static let saveKey = "village.carto.layout.v3"
    private var layout = VillageTileLayout(data: UserDefaults.standard.data(forKey: saveKey))
    private let world = SKNode(), hud = SKNode(), backdrop = SKNode()
    private let viewport = SKCropNode()
    private let actor = MemoryCharacter(title: "Arthur", color: .systemGreen)
    private let village = SKTexture(imageNamed: VillageCartoMap.imageName)
    private var isMap = true
    private var selected: Int?, draftTurns = 0, page = 0
    private var selectedBuilding: String?
    private var buildingPage = 0
    private var sourcePosition = VillageCartoMap.spawn
    private var mapCenter = VillageTileLayout.initial.center
    private var zoom: CGFloat = 1
    private var activeTouch: UITouch?, touchStart = CGPoint.zero, panStart = CGPoint.zero
    private var dragging = false, panning = false
    private var cameraTransitioning = false
    private var ghost: SKNode?
    private var buildingGrid: SKShapeNode?
    private var inventoryHits: [(id: Int, node: SKNode)] = []
    private var buildingInventoryHits: [(id: String, node: SKNode)] = []
    private var dragOffset = CGPoint.zero
    private var rightEdge: CGFloat { size.width - max(12, view?.safeAreaInsets.right ?? 0) }
    private var inventoryArea: CGRect { CGRect(x:rightEdge-178,y:58,width:168,height:size.height-120) }
    private var stickTouch: UITouch?, stick = CGVector.zero
    private var knob = SKShapeNode(circleOfRadius: 19)
    private var route: [CGPoint] = [], lastTime: TimeInterval = 0
    private let status = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var board: CGRect { CGRect(x:20,y:80,width:max(150,rightEdge-208),height:max(110,size.height-148)) }
    private var stickCenter: CGPoint { CGPoint(x:85,y:105) }
    private let actorExplorationZ: CGFloat = 80

    // MARK: - 7-Phase Story Progression System
    struct StoryPhase {
        let phaseNumber: Int
        let title: String
        let buildingID: String
        let targetPieceIDs: [Int]
        let instruction: String
        let tip: String
    }

    static let storyPhases: [StoryPhase] = [
        .init(
            phaseNumber: 1,
            title: "Fase 1: Rumah Arthur",
            buildingID: "building-3x2",
            targetPieceIDs: [24], // Starter piece: Keping I (#25, id: 24) dipasangkan ke keping L awal (#7, id: 6)
            instruction: "Hubungkan keping I (#25) ke keping L awal, lalu tempatkan Rumah Arthur!",
            tip: "Pondok kayu Arthur butuh lahan 3x2 grid. Taruh di daratan hijau."
        ),
        .init(
            phaseNumber: 2,
            title: "Fase 2: Rumah Ibu Mara",
            buildingID: "building-4x3-a",
            targetPieceIDs: [20, 11], // Keping Z (#21, id: 20) + Keping Kotak (#12, id: 11)
            instruction: "Sambungkan keping Z (#21) & O (#12) ke barat untuk Pondok Tembikar Bu Mara!",
            tip: "Bengkel Bu Mara butuh lahan 4x3 grid dekat lekukan sungai."
        ),
        .init(
            phaseNumber: 3,
            title: "Fase 3: Lumbung Keneth",
            buildingID: "building-7x5",
            targetPieceIDs: [12, 13], // Keping T (#13 & #14)
            instruction: "Buka lahan masif 7x5 di timur dan bangun Lumbung Gandum Keneth!",
            tip: "Kunci keping T (#13 & #14) ke jalan timur agar lumbung bertingkat muat."
        ),
        .init(
            phaseNumber: 4,
            title: "Fase 4: Peternakan Roland",
            buildingID: "building-10x2",
            targetPieceIDs: [30, 31], // Keping T (#31 & #32)
            instruction: "Bentuk koridor daratan panjang memanjang (10x2) untuk Peternakan Roland!",
            tip: "Rebahkan keping T mendatar di sepanjang tepi daratan timur."
        ),
        .init(
            phaseNumber: 5,
            title: "Fase 5: Rumah Anneth",
            buildingID: "building-5x5",
            targetPieceIDs: [10, 16], // Keping L (#11 & #17)
            instruction: "Kunci siku keping L di tenggara untuk Rumah & Kebun Sayur Anneth (5x5)!",
            tip: "Pastikan tapak persegi 5x5 tidak menabrak batas jurang atau air."
        ),
        .init(
            phaseNumber: 6,
            title: "Fase 6: Rumah Sesepuh Beryn",
            buildingID: "building-4x3-b",
            targetPieceIDs: [17, 21], // Keping jalur perbatasan I & L (#18 & #22)
            instruction: "Hubungkan jalur ke bukit untuk Rumah Sesepuh Beryn (3x4 Menegak: Lebar > Panjang)!",
            tip: "Pondok kakek memiliki variasi menegak (lebar 4 > panjang 3). Bisa diputar dengan tombol Putar."
        ),
        .init(
            phaseNumber: 7,
            title: "Fase 7: Gudang Kosong (Markas)",
            buildingID: "building-3x3",
            targetPieceIDs: [28, 33, 34], // Keping tepi sungai
            instruction: "Klimaks: Hubungkan bantaran sungai dan bangun Gudang Kosong Markas 4 Sahabat!",
            tip: "Markas rahasia 4 sahabat menempati 3x3 grid di seberang sungai."
        )
    ]

    private var isProgressionMode = true
    private var currentPhase = 1
    private var selectedBuildingIsRotated = false

    private var currentPhaseInfo: StoryPhase {
        Self.storyPhases.first { $0.phaseNumber == currentPhase } ?? Self.storyPhases[0]
    }

    private var unlockedPieceIDs: Set<Int> {
        if !isProgressionMode { return Set(0..<VillageCartoMap.pieces.count) }
        var ids = Set<Int>()
        ids.insert(VillageTileLayout.initial.id)
        for phase in Self.storyPhases where phase.phaseNumber <= currentPhase {
            for id in phase.targetPieceIDs {
                ids.insert(id)
            }
        }
        return ids
    }

    private var unlockedBuildingIDs: Set<String> {
        if !isProgressionMode { return Set(VillageCartoMap.buildings.map(\.id)) }
        var ids = Set<String>()
        for phase in Self.storyPhases where phase.phaseNumber <= currentPhase {
            ids.insert(phase.buildingID)
        }
        return ids
    }

    private var available: [Int] {
        layout.inventory.filter { unlockedPieceIDs.contains($0) }
    }
    private let pageSize = 4
    private let buildingPageSize = 2
    private var pages: Int { max(1,Int(ceil(Double(available.count)/Double(pageSize)))) }
    private let cream = SKColor(red:0.94,green:0.90,blue:0.65,alpha:1)
    private let explorationBuildingScale: CGFloat = 0.48

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

    // Map editing shows the puzzle outline; exploration draws clean map cells without cutout seams.
    private func tile(_ id: Int, turns: Int, miniature: Bool) -> SKNode {
        let s = VillageTileLayout.side, h = s/2
        let origin = VillageTileLayout.sourceOrigin(id)
        let cells = VillageCartoMap.pieces[id]
        let node = SKNode()
        node.zRotation = CGFloat(turns) * .pi / 2

        if !miniature {
            for cell in cells {
                let minX = CGFloat(cell.x) * s
                let minY = CGFloat(cell.y) * s
                let rect = CGRect(
                    x: minX / VillageCartoMap.size.width,
                    y: minY / VillageCartoMap.size.height,
                    width: s / VillageCartoMap.size.width,
                    height: s / VillageCartoMap.size.height
                )
                let texture = SKTexture(rect: rect, in: village)
                texture.filteringMode = .linear
                let image = SKSpriteNode(texture: texture, size: CGSize(width: s + 1, height: s + 1))
                image.position = CGPoint(
                    x: minX + h - origin.x - h,
                    y: minY + h - origin.y - h
                )
                node.addChild(image)
            }
            return node
        }

        let minX = CGFloat(cells.map(\.x).min()!) * s
        let minY = CGFloat(cells.map(\.y).min()!) * s
        let width = CGFloat(cells.map(\.x).max()! - cells.map(\.x).min()! + 1) * s
        let height = CGFloat(cells.map(\.y).max()! - cells.map(\.y).min()! + 1) * s
        let rect = CGRect(x:minX/VillageCartoMap.size.width,y:minY/VillageCartoMap.size.height,
                          width:width/VillageCartoMap.size.width,height:height/VillageCartoMap.size.height)
        let texture = SKTexture(rect:rect,in:village)
        texture.filteringMode = .linear
        let image = SKSpriteNode(texture:texture,size:CGSize(width:width,height:height))
        image.position = CGPoint(x:minX+width/2-origin.x-h,y:minY+height/2-origin.y-h)
        let path = VillageTileLayout.outline(id)
        let crop = SKCropNode()
        let mask = SKShapeNode(path:path)
        mask.fillColor = .white; mask.strokeColor = .clear
        crop.maskNode = mask; crop.addChild(image)
        node.addChild(crop)
        if miniature {
            let border = SKShapeNode(path:path)
            border.strokeColor = selected == id ? .systemOrange : cream
            border.fillColor = .clear; border.lineWidth = selected == id ? 4 : 2
            let ink = SKShapeNode(path:path)
            ink.strokeColor = SKColor(white:0.08,alpha:0.8)
            ink.fillColor = .clear; ink.lineWidth = border.lineWidth+3
            node.addChild(ink); node.addChild(border)
            for port in VillageTileLayout.boundaryPorts(id) {
                let marker = SKShapeNode(rectOf:port.edge%2 == 0
                    ? CGSize(width:5,height:12) : CGSize(width:12,height:5))
                marker.position = port.point
                marker.fillColor = .systemOrange; marker.strokeColor = cream
                node.addChild(marker)
            }
            let badge = SKShapeNode(circleOfRadius:13)
            badge.fillColor = SKColor(white:0,alpha:0.7); badge.strokeColor = .clear
            badge.zRotation = -node.zRotation
            text("\(id+1)",at:.zero,size:15,parent:badge)
            node.addChild(badge)
        }
        return node
    }

    private func buildingNode(_ id: String, isRotated: Bool = false, miniature: Bool) -> SKNode {
        guard let building = VillageTileLayout.building(id) else { return SKNode() }
        let dims = VillageTileLayout.buildingDimensions(id, isRotated: isRotated) ?? (building.width, building.height)
        let unit = VillageTileLayout.side / 3
        let size = CGSize(width: CGFloat(dims.width) * unit, height: CGFloat(dims.height) * unit)
        let node = SKNode()

        // 1. Footprint Lahan / Plot Tanah Pekarangan
        let footprint = SKShapeNode(rectOf: size, cornerRadius: miniature ? 5 : 8)
        footprint.fillColor = SKColor(red: 0.22, green: 0.20, blue: 0.14, alpha: miniature ? 0.45 : 0.36)
        footprint.strokeColor = selectedBuilding == id ? .systemOrange : cream.withAlphaComponent(0.65)
        footprint.lineWidth = selectedBuilding == id ? 4 : 1.8
        node.addChild(footprint)

        // 2. Konten Spesifik Bangunan & Hiasan Pekarangan
        let contentNode = createBuildingArt(id: id, building: building, size: size, miniature: miniature)
        node.addChild(contentNode)

        // 3. Grid Panduan Subcell Halus
        let grid = SKShapeNode(rectOf: size)
        grid.strokeColor = SKColor(white: 0.05, alpha: 0.20)
        grid.lineWidth = miniature ? 0.6 : 0.9
        node.addChild(grid)

        // 4. Label Nama Bangunan & Dimensi Subgrid
        let orientText = dims.width < dims.height ? " (Tegak)" : (dims.width > dims.height ? " (Datar)" : "")
        let labelText = miniature ? "\(building.title)\(orientText)" : "\(building.title) (\(dims.width)x\(dims.height))\(orientText)"
        text(labelText, at: CGPoint(x: 0, y: -size.height * 0.5 - (miniature ? 8 : 13)), size: miniature ? 8 : 10.5, parent: node, color: cream)

        func tagAll(_ root: SKNode, name: String) {
            root.name = name
            for child in root.children {
                tagAll(child, name: name)
            }
        }
        tagAll(node, name: "building-\(id)")
        return node
    }

    private func createBuildingArt(id: String, building: VillageCartoMap.Building, size: CGSize, miniature: Bool) -> SKNode {
        let container = SKNode()

        // Helper: Bayangan Tanah Halus (Ambient Drop Shadow)
        let groundShadow = SKShapeNode(rectOf: CGSize(width: size.width * 0.92, height: size.height * 0.84), cornerRadius: miniature ? 4 : 7)
        groundShadow.position = CGPoint(x: 0, y: -size.height * 0.05)
        groundShadow.fillColor = SKColor(white: 0, alpha: miniature ? 0.16 : 0.22)
        groundShadow.strokeColor = .clear
        container.addChild(groundShadow)

        switch id {
        case "building-3x2":
            // =========================================================================
            // 1. RUMAH ARTHUR & KAKEK (3x2 Subgrid)
            // Pondok kayu cedar hangat, cerobong asap batu, jendela bercahaya keemasan,
            // tunggul tempat membelah kayu dengan kapak, dan tumpukan kayu bakar rapi.
            // =========================================================================
            let houseW = size.width * 0.58
            let houseH = size.height * 0.65
            let houseX = size.width * 0.12
            let houseY = -size.height * 0.04

            // Pondasi batu sungai di dasar dinding
            let baseStone = SKShapeNode(rectOf: CGSize(width: houseW * 1.04, height: miniature ? 3.5 : 5), cornerRadius: 1.5)
            baseStone.position = CGPoint(x: houseX, y: houseY - houseH * 0.38)
            baseStone.fillColor = SKColor(red: 0.42, green: 0.39, blue: 0.36, alpha: 1)
            baseStone.strokeColor = SKColor(red: 0.22, green: 0.20, blue: 0.18, alpha: 0.9)
            baseStone.lineWidth = 0.8
            container.addChild(baseStone)

            // Dinding kayu gelondongan cedar (Log Cabin Walls)
            let wall = SKShapeNode(rectOf: CGSize(width: houseW, height: houseH * 0.58), cornerRadius: miniature ? 3 : 5)
            wall.position = CGPoint(x: houseX, y: houseY - houseH * 0.11)
            wall.fillColor = SKColor(red: 0.58, green: 0.38, blue: 0.22, alpha: 1)
            wall.strokeColor = SKColor(red: 0.28, green: 0.16, blue: 0.08, alpha: 0.95)
            wall.lineWidth = miniature ? 1.2 : 1.8
            container.addChild(wall)

            // Garis serat kayu horizontal dinding
            for yOff in [-houseH * 0.22, -houseH * 0.02] {
                let plank = SKShapeNode(rectOf: CGSize(width: houseW * 0.92, height: 1))
                plank.position = CGPoint(x: houseX, y: houseY + CGFloat(yOff))
                plank.fillColor = SKColor(red: 0.38, green: 0.22, blue: 0.12, alpha: 0.75)
                plank.strokeColor = .clear
                container.addChild(plank)
            }

            // Atap Pelana Kayu Hangat (Warm Cedar Shingle Gable Roof)
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: houseX - houseW * 0.60, y: houseY + houseH * 0.08))
            roofPath.addLine(to: CGPoint(x: houseX, y: houseY + houseH * 0.56))
            roofPath.addLine(to: CGPoint(x: houseX + houseW * 0.60, y: houseY + houseH * 0.08))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.78, green: 0.46, blue: 0.24, alpha: 1)
            roof.strokeColor = SKColor(red: 0.32, green: 0.16, blue: 0.08, alpha: 1)
            roof.lineWidth = miniature ? 1.4 : 2.2
            container.addChild(roof)

            // Lis tepi atap depan
            let roofRidge = SKShapeNode(rectOf: CGSize(width: miniature ? 3 : 5, height: houseH * 0.46))
            roofRidge.position = CGPoint(x: houseX, y: houseY + houseH * 0.32)
            roofRidge.fillColor = SKColor(red: 0.88, green: 0.58, blue: 0.32, alpha: 0.85)
            roofRidge.strokeColor = .clear
            container.addChild(roofRidge)

            // Cerobong asap batu kali
            let chimney = SKShapeNode(rectOf: CGSize(width: miniature ? 5 : 8, height: miniature ? 10 : 14), cornerRadius: 1)
            chimney.position = CGPoint(x: houseX + houseW * 0.30, y: houseY + houseH * 0.40)
            chimney.fillColor = SKColor(red: 0.44, green: 0.40, blue: 0.38, alpha: 1)
            chimney.strokeColor = SKColor(red: 0.22, green: 0.20, blue: 0.18, alpha: 1)
            chimney.lineWidth = 0.8
            container.addChild(chimney)

            // Kepulan asap perapian lembut
            if !miniature {
                for (offsetY, r, alpha) in [(8.0, 3.2, 0.65), (15.0, 4.6, 0.45), (23.0, 6.0, 0.25)] {
                    let smoke = SKShapeNode(circleOfRadius: CGFloat(r))
                    smoke.position = CGPoint(x: chimney.position.x + CGFloat(offsetY * 0.25), y: chimney.position.y + CGFloat(offsetY))
                    smoke.fillColor = SKColor(white: 0.96, alpha: CGFloat(alpha))
                    smoke.strokeColor = .clear
                    container.addChild(smoke)
                }
            }

            // Pintu pondok kayu
            let door = SKShapeNode(rectOf: CGSize(width: houseW * 0.22, height: houseH * 0.32), cornerRadius: 2)
            door.position = CGPoint(x: houseX - houseW * 0.14, y: wall.position.y - houseH * 0.08)
            door.fillColor = SKColor(red: 0.26, green: 0.16, blue: 0.09, alpha: 1)
            door.strokeColor = SKColor(red: 0.16, green: 0.10, blue: 0.05, alpha: 0.9)
            door.lineWidth = 1
            container.addChild(door)

            // Gagang pintu kuningan
            let doorknob = SKShapeNode(circleOfRadius: miniature ? 1 : 1.6)
            doorknob.position = CGPoint(x: door.position.x + houseW * 0.06, y: door.position.y)
            doorknob.fillColor = SKColor(red: 0.96, green: 0.80, blue: 0.35, alpha: 1)
            doorknob.strokeColor = .clear
            container.addChild(doorknob)

            // Jendela berpenerangan hangat dengan kisi kayu
            let window = SKShapeNode(rectOf: CGSize(width: houseW * 0.18, height: houseH * 0.20), cornerRadius: 2)
            window.position = CGPoint(x: houseX + houseW * 0.20, y: wall.position.y + 2)
            window.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 0.96)
            window.strokeColor = SKColor(red: 0.38, green: 0.22, blue: 0.12, alpha: 1)
            window.lineWidth = 1
            container.addChild(window)

            // Palang jendela (Cross Mullions)
            let winBarH = SKShapeNode(rectOf: CGSize(width: houseW * 0.16, height: 1))
            winBarH.position = window.position
            winBarH.fillColor = SKColor(red: 0.38, green: 0.22, blue: 0.12, alpha: 1)
            winBarH.strokeColor = .clear
            container.addChild(winBarH)

            // HIASAN PEKARANGAN ARTHUR:
            // Tumpukan kayu bakar rapi di pekarangan kiri
            let woodX = -size.width * 0.28
            let woodY = -size.height * 0.16
            for i in 0..<3 {
                let log = SKShapeNode(rectOf: CGSize(width: miniature ? 13 : 18, height: miniature ? 3.5 : 4.8), cornerRadius: 1.6)
                log.position = CGPoint(x: woodX, y: woodY + CGFloat(i) * (miniature ? 3.6 : 5.0))
                log.fillColor = SKColor(red: 0.50, green: 0.32, blue: 0.18, alpha: 1)
                log.strokeColor = SKColor(red: 0.26, green: 0.15, blue: 0.08, alpha: 1)
                log.lineWidth = 0.8
                container.addChild(log)

                // Titik serat lingkaran kayu di ujung log
                let logEnd = SKShapeNode(circleOfRadius: miniature ? 1.2 : 1.8)
                logEnd.position = CGPoint(x: log.position.x + (miniature ? 5.5 : 7.5), y: log.position.y)
                logEnd.fillColor = SKColor(red: 0.80, green: 0.62, blue: 0.42, alpha: 1)
                logEnd.strokeColor = .clear
                container.addChild(logEnd)
            }

            // Tunggul pembelah kayu & kapak Arthur
            if !miniature {
                let stump = SKShapeNode(rectOf: CGSize(width: 10, height: 8), cornerRadius: 2)
                stump.position = CGPoint(x: woodX + 16, y: woodY + 2)
                stump.fillColor = SKColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1)
                stump.strokeColor = SKColor(red: 0.24, green: 0.14, blue: 0.08, alpha: 1)
                stump.lineWidth = 0.8
                container.addChild(stump)

                // Mata kapak besi tertancap di tunggul
                let axeBlade = SKShapeNode(rectOf: CGSize(width: 4, height: 3))
                axeBlade.position = CGPoint(x: stump.position.x, y: stump.position.y + 5)
                axeBlade.fillColor = SKColor(red: 0.75, green: 0.78, blue: 0.82, alpha: 1)
                axeBlade.strokeColor = .clear
                container.addChild(axeBlade)
            }

        case "building-4x3-a":
            // =========================================================================
            // 2. PONDOK TEMBIKAR BU MARA (4x3 Subgrid)
            // Dinding plester putih-krem, genteng lengkung terakota, rak gerabah
            // bertingkat dengan pot warna-warni, dan tungku pembakaran tanah liat berkobar.
            // =========================================================================
            let houseW = size.width * 0.54
            let houseH = size.height * 0.62
            let houseX = -size.width * 0.14
            let houseY = -size.height * 0.03

            // Dinding plester adobe/krem hangat Bu Mara
            let wall = SKShapeNode(rectOf: CGSize(width: houseW, height: houseH * 0.58), cornerRadius: miniature ? 4 : 7)
            wall.position = CGPoint(x: houseX, y: houseY - houseH * 0.12)
            wall.fillColor = SKColor(red: 0.84, green: 0.78, blue: 0.68, alpha: 1)
            wall.strokeColor = SKColor(red: 0.44, green: 0.34, blue: 0.24, alpha: 0.9)
            wall.lineWidth = miniature ? 1.4 : 2
            container.addChild(wall)

            // Atap Genteng Terakota Lengkung Tuscan
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: houseX - houseW * 0.60, y: houseY + houseH * 0.10))
            roofPath.addLine(to: CGPoint(x: houseX, y: houseY + houseH * 0.58))
            roofPath.addLine(to: CGPoint(x: houseX + houseW * 0.60, y: houseY + houseH * 0.10))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.86, green: 0.42, blue: 0.22, alpha: 1)
            roof.strokeColor = SKColor(red: 0.46, green: 0.20, blue: 0.10, alpha: 1)
            roof.lineWidth = miniature ? 1.5 : 2.2
            container.addChild(roof)

            // Pintu lengkung bengkel tembikar
            let door = SKShapeNode(rectOf: CGSize(width: houseW * 0.22, height: houseH * 0.34), cornerRadius: 4)
            door.position = CGPoint(x: houseX, y: wall.position.y - houseH * 0.08)
            door.fillColor = SKColor(red: 0.36, green: 0.22, blue: 0.14, alpha: 1)
            door.strokeColor = SKColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 0.9)
            door.lineWidth = 1
            container.addChild(door)

            // Jendela bengkel dengan cahaya hangat tembikar
            let window = SKShapeNode(rectOf: CGSize(width: houseW * 0.18, height: houseH * 0.20), cornerRadius: 2)
            window.position = CGPoint(x: houseX + houseW * 0.26, y: wall.position.y + 4)
            window.fillColor = SKColor(red: 1.0, green: 0.82, blue: 0.40, alpha: 0.95)
            window.strokeColor = SKColor(red: 0.42, green: 0.30, blue: 0.20, alpha: 1)
            window.lineWidth = 1
            container.addChild(window)

            // HIASAN: Rak Display Pot Keramik Bu Mara di Pekarangan Kanan
            let shelfX = size.width * 0.28
            let shelfY = -size.height * 0.14
            let shelf = SKShapeNode(rectOf: CGSize(width: miniature ? 22 : 32, height: miniature ? 8 : 11), cornerRadius: 2)
            shelf.position = CGPoint(x: shelfX, y: shelfY)
            shelf.fillColor = SKColor(red: 0.48, green: 0.32, blue: 0.18, alpha: 1)
            shelf.strokeColor = SKColor(red: 0.24, green: 0.16, blue: 0.08, alpha: 1)
            shelf.lineWidth = 1
            container.addChild(shelf)

            // Pot keramik warna-warni (Pirus/Turquoise, Saffron Kuning, Terakota Merah)
            let potSpecs: [(color: SKColor, radius: CGFloat)] = [
                (SKColor(red: 0.20, green: 0.68, blue: 0.65, alpha: 1), 3.4), // Pirus antik
                (SKColor(red: 0.94, green: 0.74, blue: 0.28, alpha: 1), 2.8), // Saffron
                (SKColor(red: 0.88, green: 0.36, blue: 0.22, alpha: 1), 3.2)  // Terakota
            ]
            let potSpacing: CGFloat = miniature ? 6.0 : 9.5
            for (idx, spec) in potSpecs.enumerated() {
                let pot = SKShapeNode(circleOfRadius: miniature ? spec.radius * 0.75 : spec.radius)
                pot.position = CGPoint(x: shelfX - potSpacing + CGFloat(idx) * potSpacing, y: shelfY + (miniature ? 5.5 : 8.0))
                pot.fillColor = spec.color
                pot.strokeColor = SKColor(white: 0.1, alpha: 0.8)
                pot.lineWidth = 0.8
                container.addChild(pot)
            }

            // Tungku Pembakaran Tanah Liat Bu Mara (Domed Kiln with Fire Glow)
            let kilnX = size.width * 0.28
            let kilnY = size.height * 0.20
            let kiln = SKShapeNode(circleOfRadius: miniature ? 8 : 12)
            kiln.position = CGPoint(x: kilnX, y: kilnY)
            kiln.fillColor = SKColor(red: 0.54, green: 0.35, blue: 0.26, alpha: 1)
            kiln.strokeColor = SKColor(red: 0.28, green: 0.16, blue: 0.10, alpha: 1)
            kiln.lineWidth = miniature ? 1.0 : 1.5
            container.addChild(kiln)

            // Cerobong atas tungku
            let kilnSpout = SKShapeNode(rectOf: CGSize(width: miniature ? 4 : 6, height: miniature ? 5 : 7), cornerRadius: 1)
            kilnSpout.position = CGPoint(x: kilnX, y: kilnY + (miniature ? 7 : 11))
            kilnSpout.fillColor = SKColor(red: 0.40, green: 0.25, blue: 0.18, alpha: 1)
            kilnSpout.strokeColor = .clear
            container.addChild(kilnSpout)

            // Mulut api tungku membara hangat
            let kilnFireGlow = SKShapeNode(circleOfRadius: miniature ? 5 : 7.5)
            kilnFireGlow.position = CGPoint(x: kilnX, y: kilnY - (miniature ? 3 : 5))
            kilnFireGlow.fillColor = SKColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 0.45)
            kilnFireGlow.strokeColor = .clear
            container.addChild(kilnFireGlow)

            let kilnOpening = SKShapeNode(rectOf: CGSize(width: miniature ? 5 : 7, height: miniature ? 4 : 5.5), cornerRadius: 1.5)
            kilnOpening.position = CGPoint(x: kilnX, y: kilnY - (miniature ? 3 : 5))
            kilnOpening.fillColor = SKColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 1)
            kilnOpening.strokeColor = .clear
            container.addChild(kilnOpening)

        case "building-7x5":
            // =========================================================================
            // 3. LUMBUNG GANDUM KENETH (7x5 Subgrid)
            // Lumbung raksasa merah pedesaan, atap sirap gambrel bertingkat,
            // pintu gudang besar palang silang X, tumpukan karung gandum, dan kereta dorong.
            // =========================================================================
            let barnW = size.width * 0.65
            let barnH = size.height * 0.70
            let barnX = -size.width * 0.10
            let barnY = -size.height * 0.02

            // Dinding lumbung merah kayu rustic
            let wall = SKShapeNode(rectOf: CGSize(width: barnW, height: barnH * 0.58), cornerRadius: miniature ? 5 : 8)
            wall.position = CGPoint(x: barnX, y: barnY - barnH * 0.14)
            wall.fillColor = SKColor(red: 0.56, green: 0.24, blue: 0.16, alpha: 1)
            wall.strokeColor = SKColor(red: 0.28, green: 0.12, blue: 0.08, alpha: 0.95)
            wall.lineWidth = miniature ? 1.6 : 2.4
            container.addChild(wall)

            // Balok penopang putih di pojok dinding lumbung
            for xSide in [-barnW * 0.46, barnW * 0.46] {
                let post = SKShapeNode(rectOf: CGSize(width: miniature ? 3 : 5, height: barnH * 0.56))
                post.position = CGPoint(x: barnX + CGFloat(xSide), y: wall.position.y)
                post.fillColor = SKColor(red: 0.90, green: 0.86, blue: 0.80, alpha: 0.9)
                post.strokeColor = .clear
                container.addChild(post)
            }

            // Pintu lumbung besar ganda dengan palang X
            let doorW = barnW * 0.35
            let doorH = barnH * 0.38
            let barnDoor = SKShapeNode(rectOf: CGSize(width: doorW, height: doorH), cornerRadius: 3)
            barnDoor.position = CGPoint(x: barnX, y: wall.position.y - barnH * 0.08)
            barnDoor.fillColor = SKColor(red: 0.32, green: 0.14, blue: 0.08, alpha: 1)
            barnDoor.strokeColor = SKColor(red: 0.75, green: 0.58, blue: 0.40, alpha: 0.9)
            barnDoor.lineWidth = 1.4
            container.addChild(barnDoor)

            // Garis silang X pintu
            let xLine1 = SKShapeNode(rectOf: CGSize(width: doorW * 0.85, height: 1.4))
            xLine1.position = barnDoor.position
            xLine1.zRotation = 0.55
            xLine1.fillColor = SKColor(red: 0.85, green: 0.70, blue: 0.48, alpha: 0.9)
            xLine1.strokeColor = .clear
            container.addChild(xLine1)

            let xLine2 = SKShapeNode(rectOf: CGSize(width: doorW * 0.85, height: 1.4))
            xLine2.position = barnDoor.position
            xLine2.zRotation = -0.55
            xLine2.fillColor = SKColor(red: 0.85, green: 0.70, blue: 0.48, alpha: 0.9)
            xLine2.strokeColor = .clear
            container.addChild(xLine2)

            // Atap Sirap Gambrel Lumbung Bertingkat
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: barnX - barnW * 0.58, y: barnY + barnH * 0.10))
            roofPath.addLine(to: CGPoint(x: barnX - barnW * 0.28, y: barnY + barnH * 0.44))
            roofPath.addLine(to: CGPoint(x: barnX, y: barnY + barnH * 0.62))
            roofPath.addLine(to: CGPoint(x: barnX + barnW * 0.28, y: barnY + barnH * 0.44))
            roofPath.addLine(to: CGPoint(x: barnX + barnW * 0.58, y: barnY + barnH * 0.10))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.88, green: 0.74, blue: 0.38, alpha: 1)
            roof.strokeColor = SKColor(red: 0.46, green: 0.34, blue: 0.16, alpha: 1)
            roof.lineWidth = miniature ? 1.8 : 2.6
            container.addChild(roof)

            // Jendela loteng gandum & balok kerekan
            let loftHole = SKShapeNode(rectOf: CGSize(width: barnW * 0.18, height: barnH * 0.16), cornerRadius: 2)
            loftHole.position = CGPoint(x: barnX, y: barnY + barnH * 0.32)
            loftHole.fillColor = SKColor(red: 0.24, green: 0.12, blue: 0.08, alpha: 1)
            loftHole.strokeColor = SKColor(red: 0.70, green: 0.55, blue: 0.35, alpha: 0.8)
            loftHole.lineWidth = 1
            container.addChild(loftHole)

            // Jerami emas menjulur dari loteng
            let hayTuft = SKShapeNode(rectOf: CGSize(width: barnW * 0.14, height: 4), cornerRadius: 1)
            hayTuft.position = CGPoint(x: barnX, y: loftHole.position.y - barnH * 0.08)
            hayTuft.fillColor = SKColor(red: 0.96, green: 0.84, blue: 0.35, alpha: 1)
            hayTuft.strokeColor = .clear
            container.addChild(hayTuft)

            // HIASAN: Tumpukan Karung Gandum Keneth di Sisi Kanan
            let sacksX = size.width * 0.32
            let sacksY = -size.height * 0.14
            for i in 0..<4 {
                let sack = SKShapeNode(rectOf: CGSize(width: miniature ? 13 : 18, height: miniature ? 8 : 11), cornerRadius: 3.5)
                sack.position = CGPoint(x: sacksX + CGFloat(i % 2) * (miniature ? 9 : 13), y: sacksY + CGFloat(i / 2) * (miniature ? 7 : 10))
                sack.fillColor = SKColor(red: 0.86, green: 0.78, blue: 0.62, alpha: 1)
                sack.strokeColor = SKColor(red: 0.44, green: 0.36, blue: 0.26, alpha: 1)
                sack.lineWidth = 0.8
                container.addChild(sack)
            }

            // Kereta dorong hasil panen (Wooden Handcart)
            if !miniature {
                let cartX = size.width * 0.25
                let cartY = -size.height * 0.32
                let cart = SKShapeNode(rectOf: CGSize(width: 24, height: 12), cornerRadius: 2)
                cart.position = CGPoint(x: cartX, y: cartY)
                cart.fillColor = SKColor(red: 0.60, green: 0.40, blue: 0.24, alpha: 1)
                cart.strokeColor = SKColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1)
                cart.lineWidth = 1.2
                container.addChild(cart)

                for wX in [-9.0, 9.0] {
                    let wheel = SKShapeNode(circleOfRadius: 4.5)
                    wheel.position = CGPoint(x: cartX + CGFloat(wX), y: cartY - 7)
                    wheel.fillColor = SKColor(red: 0.32, green: 0.20, blue: 0.12, alpha: 1)
                    wheel.strokeColor = SKColor(red: 0.16, green: 0.10, blue: 0.06, alpha: 1)
                    wheel.lineWidth = 1
                    container.addChild(wheel)
                }
            }

        case "building-10x2":
            // =========================================================================
            // 4. PETERNAKAN ROLAND (10x2 Subgrid Memanjang)
            // Kandang ternak memanjang, pagar kayu palang ganda, palungan pakan & air,
            // balok jerami bundar, dan tiang jilat garam ternak.
            // =========================================================================
            let shedW = size.width * 0.34
            let shedH = size.height * 0.82
            let shedX = -size.width * 0.30

            // Bangsal / Shelter hewan ternak di kiri
            let shed = SKShapeNode(rectOf: CGSize(width: shedW, height: shedH * 0.64), cornerRadius: 4)
            shed.position = CGPoint(x: shedX, y: -shedH * 0.10)
            shed.fillColor = SKColor(red: 0.50, green: 0.34, blue: 0.20, alpha: 1)
            shed.strokeColor = SKColor(red: 0.26, green: 0.16, blue: 0.08, alpha: 1)
            shed.lineWidth = 1.4
            container.addChild(shed)

            // Atap seng/sirap kandang miring
            let shedRoof = SKShapeNode(rectOf: CGSize(width: shedW * 1.10, height: shedH * 0.36), cornerRadius: 2.5)
            shedRoof.position = CGPoint(x: shedX, y: shedH * 0.24)
            shedRoof.fillColor = SKColor(red: 0.38, green: 0.24, blue: 0.14, alpha: 1)
            shedRoof.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.06, alpha: 1)
            shedRoof.lineWidth = 1.2
            container.addChild(shedRoof)

            // Pintu terbuka kandang dengan jerami di lantai
            let stall = SKShapeNode(rectOf: CGSize(width: shedW * 0.45, height: shedH * 0.38), cornerRadius: 2)
            stall.position = CGPoint(x: shedX, y: -shedH * 0.20)
            stall.fillColor = SKColor(red: 0.24, green: 0.15, blue: 0.09, alpha: 1)
            stall.strokeColor = .clear
            container.addChild(stall)

            // PAGAR KAYU MEMANJANG (Post & Rail Fence) sepanjang 10x2
            let fenceStartX = -size.width * 0.10
            let fenceEndX = size.width * 0.46
            let fenceW = fenceEndX - fenceStartX
            let fenceY = -size.height * 0.06

            // Dua rel mendatar pagar
            for yOff in [-6.0, 6.0] {
                let rail = SKShapeNode(rectOf: CGSize(width: fenceW, height: miniature ? 2.0 : 3.0), cornerRadius: 1)
                rail.position = CGPoint(x: (fenceStartX + fenceEndX) / 2, y: fenceY + CGFloat(yOff))
                rail.fillColor = SKColor(red: 0.74, green: 0.56, blue: 0.38, alpha: 1)
                rail.strokeColor = SKColor(red: 0.36, green: 0.24, blue: 0.14, alpha: 0.8)
                rail.lineWidth = 0.8
                container.addChild(rail)
            }

            // Tiang vertikal pagar
            let postCount = 5
            for i in 0..<postCount {
                let pX = fenceStartX + CGFloat(i) * (fenceW / CGFloat(postCount - 1))
                let post = SKShapeNode(rectOf: CGSize(width: miniature ? 3 : 4.5, height: miniature ? 16 : 22), cornerRadius: 1)
                post.position = CGPoint(x: pX, y: fenceY)
                post.fillColor = SKColor(red: 0.56, green: 0.40, blue: 0.26, alpha: 1)
                post.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.10, alpha: 1)
                post.lineWidth = 0.8
                container.addChild(post)
            }

            // Palungan Kayu Pakan & Air Ternak (Wooden Trough)
            let troughW = miniature ? 32.0 : 54.0
            let trough = SKShapeNode(rectOf: CGSize(width: troughW, height: miniature ? 7.0 : 10.0), cornerRadius: 2.5)
            trough.position = CGPoint(x: size.width * 0.18, y: fenceY - (miniature ? 9 : 14))
            trough.fillColor = SKColor(red: 0.40, green: 0.26, blue: 0.16, alpha: 1)
            trough.strokeColor = SKColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1)
            trough.lineWidth = 1
            container.addChild(trough)

            // Refleksi air biru & jerami di dalam palungan
            let troughWater = SKShapeNode(rectOf: CGSize(width: troughW * 0.85, height: miniature ? 3.0 : 4.5), cornerRadius: 1)
            troughWater.position = trough.position
            troughWater.fillColor = SKColor(red: 0.35, green: 0.65, blue: 0.75, alpha: 0.85)
            troughWater.strokeColor = .clear
            container.addChild(troughWater)

            // Balok Jerami Emas Roland (Golden Hay Bales)
            for i in 0..<2 {
                let hayBale = SKShapeNode(rectOf: CGSize(width: miniature ? 13 : 18, height: miniature ? 8 : 12), cornerRadius: 2)
                hayBale.position = CGPoint(x: shedX + shedW * 0.70 + CGFloat(i) * (miniature ? 14 : 19), y: -size.height * 0.12)
                hayBale.fillColor = SKColor(red: 0.94, green: 0.80, blue: 0.34, alpha: 1)
                hayBale.strokeColor = SKColor(red: 0.58, green: 0.44, blue: 0.16, alpha: 1)
                hayBale.lineWidth = 1
                container.addChild(hayBale)
            }

        case "building-5x5":
            // =========================================================================
            // 5. RUMAH & DAPUR ANNETH (5x5 Subgrid)
            // Pondok asri beratap lumut hijau, cerobong dapur berasap, jendela teluk
            // dengan kotak bunga semerbak, dan kebun sayur bedengan umbi & rempah.
            // =========================================================================
            let houseW = size.width * 0.55
            let houseH = size.height * 0.50
            let houseX = -size.width * 0.14
            let houseY = size.height * 0.12

            // Dinding plester putih-krem dengan penopang kayu oak
            let wall = SKShapeNode(rectOf: CGSize(width: houseW, height: houseH * 0.58), cornerRadius: miniature ? 4 : 7)
            wall.position = CGPoint(x: houseX, y: houseY - houseH * 0.12)
            wall.fillColor = SKColor(red: 0.88, green: 0.82, blue: 0.72, alpha: 1)
            wall.strokeColor = SKColor(red: 0.38, green: 0.26, blue: 0.18, alpha: 0.95)
            wall.lineWidth = miniature ? 1.4 : 2
            container.addChild(wall)

            // Atap Pelana Lumut Hijau Asri (Sage Green Shingle Roof)
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: houseX - houseW * 0.60, y: houseY + houseH * 0.10))
            roofPath.addLine(to: CGPoint(x: houseX, y: houseY + houseH * 0.60))
            roofPath.addLine(to: CGPoint(x: houseX + houseW * 0.60, y: houseY + houseH * 0.10))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.44, green: 0.58, blue: 0.40, alpha: 1)
            roof.strokeColor = SKColor(red: 0.20, green: 0.30, blue: 0.18, alpha: 1)
            roof.lineWidth = miniature ? 1.5 : 2.4
            container.addChild(roof)

            // Cerobong batu dapur Anneth
            let chimney = SKShapeNode(rectOf: CGSize(width: miniature ? 5 : 8, height: miniature ? 11 : 15), cornerRadius: 1)
            chimney.position = CGPoint(x: houseX - houseW * 0.28, y: houseY + houseH * 0.42)
            chimney.fillColor = SKColor(red: 0.48, green: 0.44, blue: 0.40, alpha: 1)
            chimney.strokeColor = SKColor(red: 0.24, green: 0.22, blue: 0.20, alpha: 1)
            chimney.lineWidth = 0.8
            container.addChild(chimney)

            // Jendela teluk dapur bercahaya hangat
            let window = SKShapeNode(rectOf: CGSize(width: houseW * 0.22, height: houseH * 0.24), cornerRadius: 2.5)
            window.position = CGPoint(x: houseX + houseW * 0.18, y: wall.position.y + 2)
            window.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 0.95)
            window.strokeColor = SKColor(red: 0.40, green: 0.26, blue: 0.16, alpha: 1)
            window.lineWidth = 1
            container.addChild(window)

            // Kotak bunga warna-warni di bawah jendela
            let flowerBox = SKShapeNode(rectOf: CGSize(width: houseW * 0.24, height: miniature ? 3 : 5), cornerRadius: 1)
            flowerBox.position = CGPoint(x: window.position.x, y: window.position.y - houseH * 0.14)
            flowerBox.fillColor = SKColor(red: 0.88, green: 0.32, blue: 0.42, alpha: 1) // Bunga merah jambu
            flowerBox.strokeColor = .clear
            container.addChild(flowerBox)

            // HIASAN: Kebun Sayur & Rempah Anneth (2 Bedengan Tanah Gembur Berbaris)
            let gardenW = size.width * 0.82
            let gardenH = size.height * 0.34
            let gardenY = -size.height * 0.22
            for row in 0..<2 {
                let rowY = gardenY + CGFloat(row) * (miniature ? 12 : 18)
                let bed = SKShapeNode(rectOf: CGSize(width: gardenW, height: gardenH * 0.38), cornerRadius: 2.5)
                bed.position = CGPoint(x: 0, y: rowY)
                bed.fillColor = SKColor(red: 0.32, green: 0.22, blue: 0.14, alpha: 1)
                bed.strokeColor = SKColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 0.85)
                bed.lineWidth = 0.8
                container.addChild(bed)

                // Tanaman kubis & wortel hijau bermunculan
                let plantCount = miniature ? 5 : 7
                for p in 0..<plantCount {
                    let pX = -gardenW * 0.40 + CGFloat(p) * (gardenW * 0.80 / CGFloat(plantCount - 1))
                    let sprout = SKShapeNode(circleOfRadius: miniature ? 1.8 : 2.6)
                    sprout.position = CGPoint(x: pX, y: rowY)
                    sprout.fillColor = row == 0 ? SKColor(red: 0.35, green: 0.72, blue: 0.28, alpha: 1) : SKColor(red: 0.65, green: 0.30, blue: 0.60, alpha: 1)
                    sprout.strokeColor = .clear
                    container.addChild(sprout)
                }
            }

            // Meja pengawetan garam dapur Anneth
            let saltX = size.width * 0.28
            let saltY = houseY - 4
            let saltTable = SKShapeNode(rectOf: CGSize(width: miniature ? 16 : 24, height: miniature ? 10 : 15), cornerRadius: 2)
            saltTable.position = CGPoint(x: saltX, y: saltY)
            saltTable.fillColor = SKColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1)
            saltTable.strokeColor = SKColor(red: 0.48, green: 0.34, blue: 0.22, alpha: 1)
            saltTable.lineWidth = 1.2
            container.addChild(saltTable)

        case "building-4x3-b":
            // =========================================================================
            // 6. RUMAH SESEPUH BERYN (4x3 Subgrid)
            // Pondok kayu cedar tua terhormat di lereng bukit, atap perisai hijau lumut gelap,
            // serambi panggung dengan lentera besi bercahaya, dan tiang batu penjaga desa.
            // =========================================================================
            let lodgeW = size.width * 0.64
            let lodgeH = size.height * 0.60
            let lodgeX = 0.0
            let lodgeY = size.height * 0.08

            // Dinding kayu cedar tua Sesepuh Beryn
            let wall = SKShapeNode(rectOf: CGSize(width: lodgeW, height: lodgeH * 0.56), cornerRadius: miniature ? 4 : 6)
            wall.position = CGPoint(x: lodgeX, y: lodgeY - lodgeH * 0.12)
            wall.fillColor = SKColor(red: 0.44, green: 0.30, blue: 0.18, alpha: 1)
            wall.strokeColor = SKColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 0.95)
            wall.lineWidth = miniature ? 1.4 : 2
            container.addChild(wall)

            // Atap Perisai Hijau Tua Berpuncak Anggun (Elder Slate Hip Roof)
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: lodgeX - lodgeW * 0.60, y: lodgeY + lodgeH * 0.08))
            roofPath.addLine(to: CGPoint(x: lodgeX, y: lodgeY + lodgeH * 0.56))
            roofPath.addLine(to: CGPoint(x: lodgeX + lodgeW * 0.60, y: lodgeY + lodgeH * 0.08))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.30, green: 0.42, blue: 0.32, alpha: 1)
            roof.strokeColor = SKColor(red: 0.15, green: 0.22, blue: 0.16, alpha: 1)
            roof.lineWidth = miniature ? 1.5 : 2.2
            container.addChild(roof)

            // Serambi panggung kayu tempat duduk Sesepuh
            let porchW = lodgeW * 0.92
            let porchH = size.height * 0.28
            let porchY = -size.height * 0.22
            let porch = SKShapeNode(rectOf: CGSize(width: porchW, height: porchH), cornerRadius: 2.5)
            porch.position = CGPoint(x: lodgeX, y: porchY)
            porch.fillColor = SKColor(red: 0.56, green: 0.40, blue: 0.24, alpha: 1)
            porch.strokeColor = SKColor(red: 0.26, green: 0.16, blue: 0.08, alpha: 0.9)
            porch.lineWidth = 1.2
            container.addChild(porch)

            // Tangga kayu serambi
            let steps = SKShapeNode(rectOf: CGSize(width: porchW * 0.35, height: 4), cornerRadius: 1)
            steps.position = CGPoint(x: lodgeX, y: porchY - porchH * 0.45)
            steps.fillColor = SKColor(red: 0.40, green: 0.28, blue: 0.16, alpha: 1)
            steps.strokeColor = .clear
            container.addChild(steps)

            // Lentera besi serambi dengan pendar cahaya hangat
            let lanternX = lodgeX + porchW * 0.36
            let lanternY = porchY + 6
            let lanternGlow = SKShapeNode(circleOfRadius: miniature ? 5 : 8)
            lanternGlow.position = CGPoint(x: lanternX, y: lanternY)
            lanternGlow.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.45)
            lanternGlow.strokeColor = .clear
            container.addChild(lanternGlow)

            let lantern = SKShapeNode(circleOfRadius: miniature ? 2.5 : 3.8)
            lantern.position = CGPoint(x: lanternX, y: lanternY)
            lantern.fillColor = SKColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 1)
            lantern.strokeColor = SKColor(red: 0.45, green: 0.30, blue: 0.10, alpha: 1)
            lantern.lineWidth = 1
            container.addChild(lantern)

        case "building-3x3":
            // =========================================================================
            // 7. GUDANG KOSONG / MARKAS RAHASIA 4 SAHABAT (3x3 Subgrid)
            // Gudang tepi sungai kayu lapuk, pintu geser kargo sedikit terbuka,
            // 4 peti kayu tempat duduk melingkar 4 sahabat, lentera gantung, dan dermaga air.
            // =========================================================================
            let whW = size.width * 0.66
            let whH = size.height * 0.60
            let whX = -size.width * 0.08
            let whY = size.height * 0.04

            // Dinding kayu lapuk tua (Weathered River Driftwood Walls)
            let wall = SKShapeNode(rectOf: CGSize(width: whW, height: whH * 0.58), cornerRadius: miniature ? 3 : 5)
            wall.position = CGPoint(x: whX, y: whY - whH * 0.12)
            wall.fillColor = SKColor(red: 0.45, green: 0.38, blue: 0.30, alpha: 1)
            wall.strokeColor = SKColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 0.95)
            wall.lineWidth = miniature ? 1.4 : 2
            container.addChild(wall)

            // Garis papan kayu vertikal lapuk
            for xOff in [-whW * 0.30, -whW * 0.10, whW * 0.10, whW * 0.30] {
                let seam = SKShapeNode(rectOf: CGSize(width: 1, height: whH * 0.54))
                seam.position = CGPoint(x: whX + CGFloat(xOff), y: wall.position.y)
                seam.fillColor = SKColor(red: 0.28, green: 0.22, blue: 0.18, alpha: 0.7)
                seam.strokeColor = .clear
                container.addChild(seam)
            }

            // Atap Sirap Gudang Tepian Sungai
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: whX - whW * 0.60, y: whY + whH * 0.10))
            roofPath.addLine(to: CGPoint(x: whX, y: whY + whH * 0.56))
            roofPath.addLine(to: CGPoint(x: whX + whW * 0.60, y: whY + whH * 0.10))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.52, green: 0.42, blue: 0.32, alpha: 1)
            roof.strokeColor = SKColor(red: 0.26, green: 0.20, blue: 0.14, alpha: 1)
            roof.lineWidth = miniature ? 1.5 : 2.2
            container.addChild(roof)

            // Pintu Geser Kargo Kayu Besar (Sedikit terbuka, ada cahaya hangat di dalam!)
            let door = SKShapeNode(rectOf: CGSize(width: whW * 0.36, height: whH * 0.38), cornerRadius: 2)
            door.position = CGPoint(x: whX - 3, y: wall.position.y - whH * 0.06)
            door.fillColor = SKColor(red: 0.28, green: 0.22, blue: 0.16, alpha: 1)
            door.strokeColor = SKColor(red: 0.62, green: 0.50, blue: 0.36, alpha: 0.8)
            door.lineWidth = 1
            container.addChild(door)

            // Celah cahaya rahasia dari dalam markas
            let lightLeak = SKShapeNode(rectOf: CGSize(width: miniature ? 2 : 3, height: whH * 0.34))
            lightLeak.position = CGPoint(x: door.position.x + whW * 0.17, y: door.position.y)
            lightLeak.fillColor = SKColor(red: 1.0, green: 0.80, blue: 0.30, alpha: 0.9)
            lightLeak.strokeColor = .clear
            container.addChild(lightLeak)

            // HIASAN: 4 Peti Kayu Tempat Duduk 4 Sahabat (Arthur, Keneth, Roland, Anneth)
            let crateX = size.width * 0.26
            let crateY = -size.height * 0.14
            for i in 0..<4 {
                let crate = SKShapeNode(rectOf: CGSize(width: miniature ? 8 : 11, height: miniature ? 8 : 11), cornerRadius: 1.5)
                crate.position = CGPoint(x: crateX + CGFloat(i % 2) * (miniature ? 7.5 : 10.5), y: crateY + CGFloat(i / 2) * (miniature ? 7.5 : 10.5))
                crate.fillColor = SKColor(red: 0.60, green: 0.44, blue: 0.26, alpha: 1)
                crate.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.10, alpha: 1)
                crate.lineWidth = 0.8
                container.addChild(crate)
            }

            // Lentera Rahasia Markas Menggantung
            if !miniature {
                let lantern = SKShapeNode(circleOfRadius: 3.5)
                lantern.position = CGPoint(x: whX + whW * 0.26, y: wall.position.y + 8)
                lantern.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.36, alpha: 1)
                lantern.strokeColor = .clear
                container.addChild(lantern)
            }

        default:
            let houseWidth = size.width * 0.74
            let houseHeight = size.height * 0.58
            let wall = SKShapeNode(rectOf: CGSize(width: houseWidth, height: houseHeight * 0.58), cornerRadius: miniature ? 4 : 7)
            wall.position = CGPoint(x: 0, y: -size.height * 0.03)
            wall.fillColor = SKColor(red: 0.64, green: 0.43, blue: 0.25, alpha: 1)
            wall.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.11, alpha: 0.7)
            wall.lineWidth = miniature ? 1.4 : 2
            container.addChild(wall)

            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: -houseWidth * 0.55, y: houseHeight * 0.10))
            roofPath.addLine(to: CGPoint(x: 0, y: houseHeight * 0.56))
            roofPath.addLine(to: CGPoint(x: houseWidth * 0.55, y: houseHeight * 0.10))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.82, green: 0.62, blue: 0.34, alpha: 1)
            roof.strokeColor = SKColor(red: 0.35, green: 0.23, blue: 0.14, alpha: 0.85)
            roof.lineWidth = miniature ? 1.6 : 2.4
            container.addChild(roof)

            let door = SKShapeNode(rectOf: CGSize(width: houseWidth * 0.16, height: houseHeight * 0.26), cornerRadius: miniature ? 2 : 4)
            door.position = CGPoint(x: 0, y: -houseHeight * 0.20)
            door.fillColor = SKColor(red: 0.23, green: 0.44, blue: 0.40, alpha: 1)
            door.strokeColor = .clear
            container.addChild(door)
        }

        return container
    }

    private func buildingRect(id: String, centeredAt center: CGPoint, isRotated: Bool = false) -> CGRect? {
        guard let dims = VillageTileLayout.buildingDimensions(id, isRotated: isRotated) else { return nil }
        let unit = VillageTileLayout.side / 3
        return CGRect(
            x: center.x - CGFloat(dims.width) * unit / 2,
            y: center.y - CGFloat(dims.height) * unit / 2,
            width: CGFloat(dims.width) * unit,
            height: CGFloat(dims.height) * unit
        )
    }

    private func buildingSubcell(id: String, centeredAt center: CGPoint, isRotated: Bool = false) -> (Int, Int)? {
        guard let rect = buildingRect(id: id, centeredAt: center, isRotated: isRotated) else { return nil }
        let unit = VillageTileLayout.side / 3
        return (Int(round(rect.minX / unit)), Int(round(rect.minY / unit)))
    }

    private func showBuildingGrid() {
        guard buildingGrid == nil else { return }
        let side = VillageTileLayout.side
        let unit = side / 3
        let path = CGMutablePath()
        let borderPath = CGMutablePath()

        for piece in layout.placements {
            for cell in VillageTileLayout.cells(of: piece) {
                let origin = cell.origin
                let cellRect = CGRect(origin: origin, size: CGSize(width: side, height: side))

                borderPath.addRect(cellRect)
                for row in 0..<VillageCartoMap.subdivisions {
                    for column in 0..<VillageCartoMap.subdivisions {
                        let x = cell.column*VillageCartoMap.subdivisions+column
                        let y = cell.row*VillageCartoMap.subdivisions+row
                        guard VillageTileLayout.buildableSubcell(column:x,row:y,pieces:layout.placements) else { continue }
                        path.addRect(CGRect(x:CGFloat(x)*unit,y:CGFloat(y)*unit,width:unit,height:unit))
                    }
                }
            }
        }

        let gridFeather = SKShapeNode(path: path)
        gridFeather.name = "buildingGrid"
        gridFeather.zPosition = 33.5
        world.addChild(gridFeather)

        let grid = SKShapeNode(path: path)
        grid.name = "buildingGrid"
        grid.strokeColor = SKColor.systemRed.withAlphaComponent(0.88)
        grid.fillColor = SKColor.systemRed.withAlphaComponent(0.16)
        grid.lineWidth = 1.2
        grid.zPosition = 34
        world.addChild(grid)
        buildingGrid = grid

        let border = SKShapeNode(path: borderPath)
        border.name = "buildingGrid"
        border.strokeColor = SKColor.white.withAlphaComponent(0.2)
        border.fillColor = .clear
        border.lineWidth = 1
        border.zPosition = 33
        world.addChild(border)
    }

    private func hideBuildingGrid() {
        buildingGrid?.removeFromParent()
        buildingGrid = nil
        world.enumerateChildNodes(withName: "buildingGrid") { node, _ in
            node.removeFromParent()
        }
    }

    private func rebuild(_ message: String? = nil) {
        let mask = SKShapeNode(rect:isMap ? board : CGRect(origin:.zero,size:size))
        mask.fillColor = .white; mask.strokeColor = .clear; viewport.maskNode = mask
        ghost?.removeFromParent(); ghost = nil; hideBuildingGrid(); inventoryHits = []; buildingInventoryHits = []
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
        for placement in layout.buildingPlacements {
            guard let rect = VillageTileLayout.buildingRect(placement) else { continue }
            let node = buildingNode(placement.id, isRotated: placement.isRotated, miniature: isMap)
            node.position = CGPoint(x: rect.midX, y: rect.midY)
            if !isMap { node.setScale(explorationBuildingScale) }
            node.zPosition = 22
            world.addChild(node)
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
                actor.setScale(0.3)
                keepActorAboveMap(); world.addChild(actor)
            } else {
                let marker = SKShapeNode(circleOfRadius:10); marker.fillColor = .systemOrange
                marker.strokeColor = .white; marker.lineWidth = 2; marker.position = actor.position; marker.zPosition = 20; world.addChild(marker)
            }
        }

        button("Kembali",name:"exit",at:CGPoint(x:42,y:size.height-32),width:68)
        button(isMap ? "Jelajahi" : "Susun peta",name:"toggle",at:CGPoint(x:rightEdge-70,y:size.height-32),width:105)
        if isMap {
            button(isProgressionMode ? "Cerita" : "Bebas",name:"toggleProgression",at:CGPoint(x:114,y:size.height-32),width:62)
            button("‹",name:"phasePrev",at:CGPoint(x:156,y:size.height-32),width:20)
            button("›",name:"phaseNext",at:CGPoint(x:178,y:size.height-32),width:20)
            button("Reset",name:"resetPhase",at:CGPoint(x:208,y:size.height-32),width:40)

            // Quest Banner
            let bannerW = min(board.width - 20, CGFloat(330))
            let banner = SKShapeNode(rectOf: CGSize(width: bannerW, height: 32), cornerRadius: 6)
            banner.position = CGPoint(x: board.midX + 50, y: size.height - 32)
            banner.fillColor = SKColor(red: 0.05, green: 0.16, blue: 0.20, alpha: 0.95)
            banner.strokeColor = isProgressionMode ? SKColor.systemOrange : cream.withAlphaComponent(0.4)
            banner.lineWidth = 1.2
            hud.addChild(banner)

            let titleStr = isProgressionMode ? "\(currentPhaseInfo.title.uppercased())" : "MODE BEBAS (SEMUA TERBUKA)"
            text(titleStr, at: CGPoint(x: board.midX + 50, y: size.height - 25), size: 10, parent: hud, color: isProgressionMode ? .systemOrange : cream)
            let subStr = isProgressionMode ? currentPhaseInfo.instruction : "Letakkan keping dan bangunan bebas di atas lahan hijau."
            text(subStr, at: CGPoint(x: board.midX + 50, y: size.height - 37), size: 8, parent: hud, color: .white)
        } else {
            text("DESA ARTHUR",at:CGPoint(x:size.width/2,y:size.height-30),size:18,parent:hud,color:cream)
        }
        if isMap {
            let panel = SKShapeNode(rect:inventoryArea,cornerRadius:8)
            panel.fillColor = SKColor(red:0.035,green:0.15,blue:0.18,alpha:0.98); panel.strokeColor = cream.withAlphaComponent(0.2); hud.addChild(panel)
            text("PUZZLE",at:CGPoint(x:rightEdge-94,y:size.height-85),size:13,parent:hud,color:cream)
            page = min(page,pages-1)
            let puzzleRows: CGFloat = 2
            let puzzleTopY = size.height - 120
            let buildingReserve: CGFloat = 150
            let availablePuzzleHeight = max(108, inventoryArea.height - buildingReserve)
            let thumb = min(CGFloat(54), max(32, (availablePuzzleHeight - 28) / puzzleRows))
            let puzzleSpacing = thumb + 10
            for (index,id) in available.dropFirst(page*pageSize).prefix(pageSize).enumerated() {
                let node = tile(id,turns:selected == id ? draftTurns : 0,miniature:true)
                let bounds = VillageTileLayout.outline(id).boundingBoxOfPath
                node.setScale(thumb/max(bounds.width,bounds.height)); node.name = "inventory-\(id)"
                node.position = CGPoint(
                    x: rightEdge - 134 + CGFloat(index % 2) * 80,
                    y: puzzleTopY - CGFloat(index / 2) * puzzleSpacing
                )
                let center = VillageTileLayout.rotated(CGPoint(x:bounds.midX,y:bounds.midY),
                    turns:selected == id ? draftTurns : 0)
                node.position.x -= center.x*node.xScale
                node.position.y -= center.y*node.yScale
                hud.addChild(node)
                inventoryHits.append((id,node))
            }
            let puzzleBottomY = puzzleTopY - (puzzleRows - 1) * puzzleSpacing - thumb * 0.5
            let buildingHeaderY = max(146, min(puzzleBottomY - 30, 225))
            let divider = SKShapeNode(rectOf: CGSize(width: 138, height: 1))
            divider.position = CGPoint(x: rightEdge - 94, y: buildingHeaderY + 16)
            divider.fillColor = cream.withAlphaComponent(0.22)
            divider.strokeColor = .clear
            hud.addChild(divider)
            text("BANGUNAN",at:CGPoint(x:rightEdge-94,y:buildingHeaderY),size:11,parent:hud,color:cream)
            let buildingInventory = layout.buildingInventory.filter { unlockedBuildingIDs.contains($0.id) }
            let buildingPages = max(1, Int(ceil(Double(buildingInventory.count) / Double(buildingPageSize))))
            buildingPage = min(buildingPage, buildingPages - 1)
            for (index, building) in buildingInventory
                .dropFirst(buildingPage * buildingPageSize)
                .prefix(buildingPageSize)
                .enumerated() {
                let isCurrentSelected = selectedBuilding == building.id
                let isRot = isCurrentSelected ? selectedBuildingIsRotated : false
                let node = buildingNode(building.id, isRotated: isRot, miniature: true)
                let dims = VillageTileLayout.buildingDimensions(building.id, isRotated: isRot) ?? (building.width, building.height)
                let unit = VillageTileLayout.side / 3
                let maxSide = max(CGFloat(dims.width) * unit, CGFloat(dims.height) * unit)
                node.setScale(min(0.9, 76 / maxSide))
                node.name = "building-\(building.id)"
                node.position = CGPoint(
                    x: rightEdge - 94,
                    y: buildingHeaderY - 42 - CGFloat(index) * 54
                )
                hud.addChild(node)
                buildingInventoryHits.append((building.id,node))
            }
            text("\(buildingPage + 1)/\(buildingPages)",at:CGPoint(x:rightEdge-94,y:buildingHeaderY-130),size:10,parent:hud,color:cream)
            button("‹",name:"building-prev",at:CGPoint(x:rightEdge-134,y:buildingHeaderY-130),width:28)
            button("›",name:"building-next",at:CGPoint(x:rightEdge-54,y:buildingHeaderY-130),width:28)
            button("‹",name:"prev",at:CGPoint(x:rightEdge-147,y:82),width:35)
            button("›",name:"next",at:CGPoint(x:rightEdge-39,y:82),width:35)
            text("\(page+1)/\(pages)",at:CGPoint(x:rightEdge-94,y:82),size:12,parent:hud,color:cream)
            let rotateBtnTitle = selectedBuilding != nil ? (selectedBuildingIsRotated ? "Putar: Datar" : "Putar: Tegak") : "Putar 90°"
            button(rotateBtnTitle, name: selectedBuilding != nil ? "rotateBuilding" : "rotate", at: CGPoint(x: 82, y: 56), width: 120)
            button(selectedBuilding != nil ? "Simpan bangunan" : "Balikkan keping", name: "remove", at: CGPoint(x: 219, y: 56), width: 140)
            button("−",name:"minus",at:CGPoint(x:315,y:56),width:38)
            button("+",name:"plus",at:CGPoint(x:362,y:56),width:38)
            button("Pusatkan",name:"center",at:CGPoint(x:435,y:56),width:90)
            if let id = selected {
                text("Keping \(id+1) · \(draftTurns*90)°",at:CGPoint(x:board.midX,y:size.height-58),size:12,parent:hud,color:cream)
            } else if let id = selectedBuilding, let building = VillageTileLayout.building(id) {
                let dims = VillageTileLayout.buildingDimensions(id, isRotated: selectedBuildingIsRotated) ?? (building.width, building.height)
                let orientDesc = dims.width < dims.height ? "Tegak (Lebar > Panjang)" : (dims.width > dims.height ? "Mendatar (Panjang > Lebar)" : "Bujur Sangkar")
                text("\(building.title) · \(dims.width)x\(dims.height) [\(orientDesc)]",at:CGPoint(x:board.midX,y:size.height-58),size:12,parent:hud,color:cream)
            }
        } else {
            let base = SKShapeNode(circleOfRadius:49); base.position = stickCenter
            base.fillColor = SKColor(white:0.1,alpha:0.45); base.strokeColor = .clear; hud.addChild(base)
            knob = SKShapeNode(circleOfRadius:19); knob.position = stickCenter
            knob.fillColor = SKColor(white:1,alpha:0.65); knob.strokeColor = .clear; hud.addChild(knob)
        }
        status.removeFromParent(); status.fontSize = 11; status.fontColor = cream; status.verticalAlignmentMode = .center
        status.position = CGPoint(x:size.width/2,y:19); hud.addChild(status)
        status.text = message ?? ""
        updateCamera()
    }
    private func nearestSafePoint(_ current: CGPoint) -> CGPoint? {
        guard let piece = layout.placement(at:current) else { return nil }
        var result: CGPoint?, distance = CGFloat.greatestFiniteMagnitude
        for cell in VillageTileLayout.cells(of:piece) {
            for x in stride(from:CGFloat(12),to:VillageTileLayout.side-12,by:8) {
                for y in stride(from:CGFloat(12),to:VillageTileLayout.side-12,by:8) {
                    let p = CGPoint(x:cell.origin.x+x,y:cell.origin.y+y)
                    let d = hypot(p.x-current.x,p.y-current.y)
                    if d < distance && layout.walkable(p) { distance = d; result = p }
                }
            }
        }
        return result
    }
    private func updateCamera() {
        if isMap {
            let scale = min(board.width/(VillageTileLayout.side*10),board.height/(VillageTileLayout.side*6))*zoom
            world.setScale(scale); world.position = CGPoint(x:board.midX-mapCenter.x*scale,y:board.midY-mapCenter.y*scale)
        } else {
            let scale = min(2.8,max(2.1,size.height/190)) * 2.8
            world.setScale(scale)
            world.position = CGPoint(x:size.width/2-actor.position.x*scale,y:size.height/2-actor.position.y*scale)
        }
    }
    private func keepActorAboveMap() {
        actor.zPosition = actorExplorationZ
    }
    private func animateWorldCamera(fromScale: CGFloat, fromPosition: CGPoint) {
        let targetScale = world.xScale
        let targetPosition = world.position
        cameraTransitioning = true
        world.removeAction(forKey: "cameraTransition")
        world.setScale(fromScale)
        world.position = fromPosition

        let scale = SKAction.scale(to: targetScale, duration: 0.42)
        let move = SKAction.move(to: targetPosition, duration: 0.42)
        scale.timingMode = .easeInEaseOut
        move.timingMode = .easeInEaseOut

        world.run(.sequence([
            .group([scale, move]),
            .run { [weak self] in
                self?.cameraTransitioning = false
                self?.updateCamera()
            }
        ]), withKey: "cameraTransition")
    }
    override func didChangeSize(_ oldSize: CGSize) {
        guard world.parent != nil else { return }; stopInput(); rebuild()
    }
    private func stopInput() { activeTouch = nil; stickTouch = nil; stick = .zero; route = []; dragging = false; panning = false; ghost?.removeFromParent(); ghost = nil; hideBuildingGrid(); world.childNode(withName:"dropSlot")?.removeFromParent() }
    private func save() { if let data = layout.encoded { UserDefaults.standard.set(data,forKey:Self.saveKey) } }
    private func returnSelected() {
        if let buildingID = selectedBuilding {
            if layout.removeBuilding(id: buildingID) {
                save(); selectedBuilding = nil
                rebuild("Bangunan kembali ke inventori.")
            } else {
                status.text = "Bangunan ini sudah ada di inventori."
            }
            return
        }
        guard let id = selected else { status.text = "Pilih keping yang ingin dibalikkan."; return }
        if layout.remove(id:id) {
            save(); selected = nil
            if let index = available.firstIndex(of:id) { page = index/pageSize }
            rebuild("Keping \(id+1) kembali ke inventori.")
        } else { status.text = "Keping ini sudah ada di inventori." }
    }
    private func select(_ id: Int) {
        if selected != id { draftTurns = layout.placements.first(where:{$0.id == id})?.turns ?? 0 }
        selected = id; selectedBuilding = nil; rebuild()
    }
    private func selectBuilding(_ id: String) {
        selected = nil; selectedBuilding = id; rebuild()
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
        if actions.contains("toggleProgression") {
            isProgressionMode.toggle()
            page = 0
            buildingPage = 0
            rebuild(isProgressionMode ? "Mode Cerita aktif: Progresi bertahap per fase." : "Mode Bebas aktif: Semua keping dan bangunan terbuka.")
            return
        }
        if actions.contains("phasePrev") {
            currentPhase = max(1, currentPhase - 1)
            page = 0
            buildingPage = 0
            rebuild("Kembali ke \(currentPhaseInfo.title)")
            return
        }
        if actions.contains("phaseNext") {
            currentPhase = min(Self.storyPhases.count, currentPhase + 1)
            page = 0
            buildingPage = 0
            rebuild("Lompat ke \(currentPhaseInfo.title)")
            return
        }
        if actions.contains("resetPhase") {
            layout = VillageTileLayout()
            currentPhase = 1
            page = 0
            buildingPage = 0
            selected = nil
            selectedBuilding = nil
            save()
            rebuild("Fase 1 dimulai: Sambungkan keping I ke keping L, lalu letakkan Rumah Arthur!")
            return
        }
        if actions.contains("exit") { stopInput(); onExit?(); return }
        if actions.contains("debugSolveCarto") {
            stopInput()
            layout.solveAllPieces()
            selected = nil
            selectedBuilding = nil
            draftTurns = 0
            page = 0
            mapCenter = layout.world(sourcePosition) ?? VillageTileLayout.initial.center
            save()
            rebuild("Debug: semua keping Carto sudah dipasang.")
            return
        }
        if actions.contains("toggle") {
            if isMap && (layout.world(sourcePosition) == nil || !layout.walkable(layout.world(sourcePosition)!)) {
                status.text = "Pasang keping dengan tempat berjalan dahulu sebelum menjelajah."; return
            }
            if isMap, let id = selected, let piece = layout.placements.first(where:{$0.id == id}), piece.turns != draftTurns {
                status.text = "Rotasi belum diterapkan. Taruh di slot kosong atau pilih keping lain untuk batal."
                return
            }
            let oldScale = world.xScale
            let oldPosition = world.position
            stopInput(); isMap.toggle(); selected = nil; rebuild()
            animateWorldCamera(fromScale: oldScale, fromPosition: oldPosition)
            return
        }
        if isMap {
            if actions.contains("rotate") || actions.contains("rotateBuilding") {
                if let buildingID = selectedBuilding {
                    selectedBuildingIsRotated.toggle()
                    if let placed = layout.buildingPlacements.first(where: { $0.id == buildingID }) {
                        if layout.placeBuilding(id: buildingID, subColumn: placed.subColumn, subRow: placed.subRow, isRotated: selectedBuildingIsRotated) {
                            save()
                            let dims = VillageTileLayout.buildingDimensions(buildingID, isRotated: selectedBuildingIsRotated)!
                            rebuild("Bangunan diputar ke \(dims.width)x\(dims.height) (\(dims.width < dims.height ? "Menegak: Lebar > Panjang" : "Mendatar")).")
                        } else {
                            selectedBuildingIsRotated.toggle()
                            rebuild("Rotasi bangunan terhalang zona atau bangunan lain.")
                        }
                    } else {
                        let dims = VillageTileLayout.buildingDimensions(buildingID, isRotated: selectedBuildingIsRotated)!
                        rebuild("Orientasi bangunan: \(dims.width)x\(dims.height) (\(dims.width < dims.height ? "Menegak: Lebar > Panjang" : "Mendatar")).")
                    }
                    return
                }
                guard selected != nil else { status.text = "Pilih keping atau bangunan terlebih dahulu."; return }
                draftTurns = (draftTurns+1)%4
                if let id = selected, let piece = layout.placements.first(where:{$0.id == id}) {
                    if layout.place(id:id,column:piece.column,row:piece.row,turns:draftTurns) {
                        save(); rebuild("Keping diputar 90°.")
                    } else { rebuild("Rotasi terhalang keping lain, batas peta, atau sambungan jalan.") }
                } else { rebuild("Rotasi siap. Letakkan keping di slot kosong untuk menerapkan.") }
                return
            }
            if actions.contains("remove") { returnSelected(); return }
            if actions.contains("prev") || actions.contains("next") { page = (page+(actions.contains("next") ? 1 : pages-1))%pages; rebuild(); return }
            if actions.contains("building-prev") || actions.contains("building-next") {
                let count = max(1, Int(ceil(Double(layout.buildingInventory.count) / Double(buildingPageSize))))
                buildingPage = (buildingPage + (actions.contains("building-next") ? 1 : count - 1)) % count
                rebuild()
                return
            }
            if actions.contains("plus") || actions.contains("minus") { zoom = max(0.5,min(2,zoom*(actions.contains("plus") ? 1.2 : 1/1.2))); updateCamera(); return }
            if actions.contains("center") { mapCenter = layout.world(sourcePosition) ?? VillageTileLayout.initial.center; updateCamera(); return }
            if let hit = inventoryHits.first(where: {
                VillageTileLayout.outline($0.id).contains($0.node.convert(p,from:hud))
            }) {
                let local = hit.node.convert(p,from:hud)
                let offset = VillageTileLayout.rotated(local,turns:selected == hit.id ? draftTurns : 0)
                select(hit.id)
                dragOffset = CGPoint(x:-offset.x,y:-offset.y)
                activeTouch = touch; touchStart = p; return
            }
            if let hit = buildingInventoryHits.first(where: { id, node in
                guard let rect = buildingRect(id: id, centeredAt: .zero, isRotated: selectedBuilding == id ? selectedBuildingIsRotated : false) else { return false }
                return rect.insetBy(dx: -14, dy: -22).contains(node.convert(p, from: hud))
            }) {
                if selectedBuilding == hit.id {
                    selectedBuildingIsRotated.toggle()
                    rebuild("Orientasi bangunan diubah!")
                } else {
                    selectBuilding(hit.id)
                    selectedBuildingIsRotated = false
                }
                dragOffset = .zero
                activeTouch = touch; touchStart = p; return
            }
            guard board.contains(p) else { return }
            let q = touch.location(in:world)
            if let building = layout.buildingPlacement(at: q),
               let rect = VillageTileLayout.buildingRect(building) {
                selectBuilding(building.id)
                selectedBuildingIsRotated = building.isRotated
                dragOffset = CGPoint(x: rect.midX - q.x, y: rect.midY - q.y)
                activeTouch = touch; touchStart = p
            } else if let piece = layout.placement(at:q) {
                select(piece.id); dragOffset = CGPoint(x:piece.center.x-q.x,y:piece.center.y-q.y)
                activeTouch = touch; touchStart = p
            } else {
                activeTouch = touch; touchStart = p; panStart = mapCenter; panning = true; dragOffset = .zero
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
        } else if let buildingID = selectedBuilding {
            showBuildingGrid()
            if ghost == nil {
                let node = buildingNode(buildingID, isRotated: selectedBuildingIsRotated, miniature: true)
                node.alpha = 0.82; node.zPosition = 40; world.addChild(node); ghost = node
            }
            let touchPoint = touch.location(in:world)
            let center = CGPoint(x: touchPoint.x + dragOffset.x, y: touchPoint.y + dragOffset.y)
            let unit = VillageTileLayout.side / 3
            let snapped = CGPoint(x: round(center.x / unit) * unit, y: round(center.y / unit) * unit)
            ghost?.position = snapped
            world.childNode(withName:"dropSlot")?.removeFromParent()
            if let (subColumn, subRow) = buildingSubcell(id: buildingID, centeredAt: snapped, isRotated: selectedBuildingIsRotated),
               let rect = buildingRect(id: buildingID, centeredAt: snapped, isRotated: selectedBuildingIsRotated) {
                let slot = SKShapeNode(rectOf: rect.size, cornerRadius: 9)
                slot.name = "dropSlot"; slot.position = snapped
                slot.strokeColor = layout.canPlaceBuilding(id: buildingID, subColumn: subColumn, subRow: subRow, isRotated: selectedBuildingIsRotated) ? .systemGreen : .systemRed
                slot.fillColor = slot.strokeColor.withAlphaComponent(0.16)
                slot.lineWidth = 4; slot.zPosition = 41; world.addChild(slot)
            }
        } else if let id = selected {
            if ghost == nil { let node = tile(id,turns:draftTurns,miniature:true); node.alpha = 0.8; node.zPosition = 40; world.addChild(node); ghost = node }
            let touchPoint = touch.location(in:world)
            let anchor = CGPoint(x:touchPoint.x+dragOffset.x,y:touchPoint.y+dragOffset.y)
            ghost?.position = anchor
            world.childNode(withName:"dropSlot")?.removeFromParent()
            if let (col,row) = VillageTileLayout.cell(anchor) {
                let center = CGPoint(x:(CGFloat(col)+0.5)*VillageTileLayout.side,
                                     y:(CGFloat(row)+0.5)*VillageTileLayout.side)
                ghost?.position = center
                let slot = SKShapeNode(path:VillageTileLayout.outline(id))
                slot.name = "dropSlot"; slot.position = center
                slot.zRotation = CGFloat(draftTurns) * .pi / 2
                slot.strokeColor = layout.canPlace(id:id,column:col,row:row,turns:draftTurns) ? .systemGreen : .systemRed
                slot.fillColor = slot.strokeColor.withAlphaComponent(0.12)
                slot.lineWidth = 4; slot.zPosition = 41; world.addChild(slot)
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = stickTouch,touches.contains(touch) { stickTouch = nil; stick = .zero; knob.position = stickCenter; return }
        guard let touch = activeTouch,touches.contains(touch) else { return }
        let wasDrag = dragging, wasPan = panning, p = touch.location(in:hud)
        let touchPoint = touch.location(in:world)
        let q = CGPoint(x:touchPoint.x+dragOffset.x,y:touchPoint.y+dragOffset.y)
        stopInput()
        if wasDrag && !wasPan && inventoryArea.contains(p) { returnSelected(); return }
        let changedRotation = selected.flatMap { id in layout.placements.first(where:{$0.id == id}) }.map { $0.turns != draftTurns } ?? false
        if let buildingID = selectedBuilding,
           board.contains(p),
           (wasDrag || layout.buildingPlacements.contains(where: { $0.id == buildingID })) {
            let unit = VillageTileLayout.side / 3
            let snapped = CGPoint(x: round(q.x / unit) * unit, y: round(q.y / unit) * unit)
            if let (subColumn, subRow) = buildingSubcell(id: buildingID, centeredAt: snapped, isRotated: selectedBuildingIsRotated),
               layout.placeBuilding(id: buildingID, subColumn: subColumn, subRow: subRow, isRotated: selectedBuildingIsRotated) {
                save()
                let title = VillageTileLayout.building(buildingID)?.title ?? "Bangunan"
                let dims = VillageTileLayout.buildingDimensions(buildingID, isRotated: selectedBuildingIsRotated)!
                let orient = dims.width < dims.height ? " (Menegak: Lebar > Panjang)" : (dims.width > dims.height ? " (Mendatar)" : "")
                if isProgressionMode && buildingID == currentPhaseInfo.buildingID {
                    if currentPhase < Self.storyPhases.count {
                        currentPhase += 1
                        let next = currentPhaseInfo
                        rebuild("🎉 \(title)\(orient) berhasil dipasang! Lanjut ke \(next.title)")
                    } else {
                        rebuild("🏆 SELURUH FASE SELESAI! Desa Carto telah lengkap!")
                    }
                } else {
                    rebuild("\(title)\(orient) ditempatkan di gabungan keping.")
                }
            } else {
                rebuild("Seluruh tapak bangunan harus berada di dalam zona bangunan dan tidak bertumpuk.")
            }
        } else if let id = selected, board.contains(p), ((!wasPan && (wasDrag || changedRotation)) || (wasPan && !wasDrag)), let (col,row) = VillageTileLayout.cell(q) {
            if layout.place(id:id,column:col,row:row,turns:draftTurns) { save(); rebuild("Keping diletakkan. Posisi dan rotasinya diterapkan ke dunia.") }
            else { rebuild("Keping bertumpuk, melewati batas peta, atau ujung jalan tidak cocok.") }
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
        actor.position = next
        keepActorAboveMap()
        sourcePosition = layout.source(next) ?? sourcePosition
        if !cameraTransitioning { updateCamera() }
    }
}
