// Editor peta bebas: inventori, drag/drop dan rotasi tanpa target susunan.
// Layer dunia memakai susunan serta rotasi yang sama, tanpa mengubah save cerita.
import SpriteKit
import UIKit

final class VillageCartoScene: SKScene, UIGestureRecognizerDelegate {
    var onExit: (() -> Void)?
    private static let saveKey = "village.carto.layout.v6"
    private var layout = VillageTileLayout(data: UserDefaults.standard.data(forKey: saveKey))
    private let world = SKNode(), hud = SKNode(), backdrop = SKNode()
    private let viewport = SKCropNode()
    private let actor = MemoryCharacter(title: "Arthur", color: .systemGreen)
    private var isMap = true
    private var selected: Int?, draftTurns = 0, page = 0
    private var selectedBuilding: String?
    private var buildingPage = 0
    private var sourcePosition = VillageCartoMap.spawn
    private var mapCenter = VillageTileLayout.initial.center
    private var zoom: CGFloat = 1
    private weak var pinchGesture: UIPinchGestureRecognizer?
    private var pinchActive = false
    private weak var rotationGesture: UIRotationGestureRecognizer?
    private var rotationActive = false
    private var rotationStartTurns = 0
    private weak var twoFingerPanGesture: UIPanGestureRecognizer?
    private var twoFingerPanActive = false
    private var twoFingerPanStart = CGPoint.zero
    private enum TwoFingerMode { case none, zoom, rotate, pan }
    private var twoFingerMode: TwoFingerMode = .none
    private var lastPinchScale: CGFloat = 1
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

    private struct Quest1Progress: Codable {
        var spokeToGrandpa = false
        var collectedWater = false
        var spokeToMara = false
        var rackFixed = false
        var returnedHome = false
    }

    private static let quest1SaveKey = "village.carto.quest1.v3"
    private var quest1: Quest1Progress = {
        guard let data = UserDefaults.standard.data(forKey: quest1SaveKey),
              let saved = try? JSONDecoder().decode(Quest1Progress.self, from: data) else {
            return Quest1Progress()
        }
        return saved
    }()
    private weak var activeQuestMinigame: ShelfBalanceMinigameNode?

    private struct QuestDialogueLine {
        let speaker: String
        let text: String
    }
    private var questDialogue: [QuestDialogueLine] = []
    private var questDialogueIndex = 0
    private var questDialogueCompletion: (() -> Void)?

    // Quest 1 dimulai dari L (ID 26), kemudian Z (ID 5). Keping lain
    // disimpan untuk quest berikutnya.
    private let quest1PieceOrder = [26, 5]
    // Dokumen Quest 1 menetapkan L dan Z sebagai dua keping awal.
    private var unlockedQuest1PieceIDs: Set<Int> { [26, 5] }
    private var available: [Int] {
        quest1PieceOrder.filter {
            unlockedQuest1PieceIDs.contains($0) && layout.inventory.contains($0)
        }
    }
    private var unlockedBuildingIDs: Set<String> {
        var result: Set<String> = ["arthur-house"]
        if quest1.spokeToGrandpa { result.insert("village-well") }
        if quest1.collectedWater { result.insert("bu-mara-house") }
        return result
    }
    private var unlockedBuildingInventory: [VillageCartoMap.Building] {
        layout.buildingInventory.filter { unlockedBuildingIDs.contains($0.id) }
    }
    private let pageSize = 4
    private let buildingPageSize = 2
    private var pages: Int { max(1,Int(ceil(Double(available.count)/Double(pageSize)))) }
    private let cream = SKColor(red:0.94,green:0.90,blue:0.65,alpha:1)

    override func didMove(to view: SKView) {
        guard world.parent == nil else { return }
        backgroundColor = SKColor(red:0.045,green:0.20,blue:0.24,alpha:1)
        addChild(backdrop); addChild(viewport); viewport.addChild(world); addChild(hud); hud.zPosition = 1000

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.cancelsTouchesInView = false
        pinch.delegate = self
        view.addGestureRecognizer(pinch)
        pinchGesture = pinch

        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotation.cancelsTouchesInView = false
        rotation.delegate = self
        view.addGestureRecognizer(rotation)
        rotationGesture = rotation

        let twoFingerPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        twoFingerPan.cancelsTouchesInView = false
        twoFingerPan.delegate = self
        view.addGestureRecognizer(twoFingerPan)
        twoFingerPanGesture = twoFingerPan

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

    private func biomeColor(_ biome: BiomeType) -> SKColor {
        switch biome {
        case .rockSalt:
            return SKColor(red: 0.86, green: 0.76, blue: 0.42, alpha: 1)
        case .villageSoil:
            return SKColor(red: 0.93, green: 0.86, blue: 0.34, alpha: 1)
        case .naturalGrass:
            return SKColor(red: 0.38, green: 0.62, blue: 0.27, alpha: 1)
        case .darkGreenForest:
            return SKColor(red: 0.12, green: 0.34, blue: 0.20, alpha: 1)
        case .hillSoil:
            return SKColor(red: 0.56, green: 0.58, blue: 0.54, alpha: 1)
        case .water:
            return SKColor(red: 0.30, green: 0.74, blue: 0.94, alpha: 1)
        }
    }

    private func triangleNode(points: [CGPoint], color: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = color
        node.strokeColor = .clear
        return node
    }

    // Map editing shows the puzzle outline; exploration draws clean map cells without cutout seams.
    private func tile(_ id: Int, turns: Int, miniature: Bool) -> SKNode {
        let s = VillageTileLayout.side, h = s/2
        let origin = VillageTileLayout.sourceOrigin(id)
        let cells = VillageCartoMap.pieces[id]
        let node = SKNode()
        node.zRotation = CGFloat(turns) * .pi / 2

        for cell in cells {
            let center = CGPoint(
                x: CGFloat(cell.x) * s + h - origin.x - h,
                y: CGFloat(cell.y) * s + h - origin.y - h
            )
            let diagonal = VillageCartoMap.diagonalBiomes(for: cell)
            let bottomLeft = CGPoint(x: center.x - h, y: center.y - h)
            let bottomRight = CGPoint(x: center.x + h, y: center.y - h)
            let topLeft = CGPoint(x: center.x - h, y: center.y + h)
            let topRight = CGPoint(x: center.x + h, y: center.y + h)
            switch VillageCartoMap.terrainSplit(for: cell) {
            case .diagonal:
                node.addChild(triangleNode(points: [bottomLeft, bottomRight, topLeft], color: biomeColor(diagonal.primary)))
                node.addChild(triangleNode(points: [topRight, topLeft, bottomRight], color: biomeColor(diagonal.secondary)))
            case .centeredRightTriangle:
                node.addChild(triangleNode(
                    points: [bottomLeft, bottomRight, topRight, topLeft],
                    color: biomeColor(diagonal.primary)
                ))
                node.addChild(triangleNode(
                    points: [center, bottomRight, topRight],
                    color: biomeColor(diagonal.secondary)
                ))
            case .lowerRightTriangle:
                node.addChild(triangleNode(
                    points: [bottomLeft, bottomRight, topRight, topLeft],
                    color: biomeColor(diagonal.primary)
                ))
                node.addChild(triangleNode(
                    points: [bottomLeft, bottomRight, topRight],
                    color: biomeColor(diagonal.secondary)
                ))
            }

            if miniature {
                let cellBorder = SKShapeNode(rectOf: CGSize(width: s, height: s))
                cellBorder.position = center
                cellBorder.strokeColor = SKColor(white: 0.05, alpha: 0.28)
                cellBorder.fillColor = .clear
                cellBorder.lineWidth = 1
                node.addChild(cellBorder)

                let gridPath = CGMutablePath()
                for index in 1..<VillageCartoMap.subdivisions {
                    let offset = -h + CGFloat(index) * VillageCartoMap.subcellSide
                    gridPath.move(to: CGPoint(x: center.x - h, y: center.y + offset))
                    gridPath.addLine(to: CGPoint(x: center.x + h, y: center.y + offset))
                    gridPath.move(to: CGPoint(x: center.x + offset, y: center.y - h))
                    gridPath.addLine(to: CGPoint(x: center.x + offset, y: center.y + h))
                }
                let subgrid = SKShapeNode(path: gridPath)
                subgrid.strokeColor = SKColor.systemBlue.withAlphaComponent(0.26)
                subgrid.lineWidth = 0.8
                node.addChild(subgrid)
            }
        }

        let path = VillageTileLayout.outline(id)
        if miniature {
            let outerShadow = SKShapeNode(path: path)
            outerShadow.strokeColor = SKColor(white: 0.04, alpha: 0.78)
            outerShadow.fillColor = .clear
            outerShadow.lineWidth = 5
            node.addChild(outerShadow)

            let outerBorder = SKShapeNode(path: path)
            outerBorder.strokeColor = selected == id ? .systemOrange : cream
            outerBorder.fillColor = .clear
            outerBorder.lineWidth = selected == id ? 4 : 2
            node.addChild(outerBorder)

            let badge = SKShapeNode(circleOfRadius:13)
            badge.fillColor = SKColor(white:0,alpha:0.7); badge.strokeColor = .clear
            badge.zRotation = -node.zRotation
            let number = VillageCartoMap.displayNumber(forPieceID: id) ?? (id + 1)
            text("\(number)",at:.zero,size:15,parent:badge)
            node.addChild(badge)
        }
        return node
    }

    private func buildingNode(_ id: String, miniature: Bool, inExploration: Bool = false) -> SKNode {
        guard let building = VillageTileLayout.building(id) else { return SKNode() }
        let unit = VillageCartoMap.subcellSide
        let displaySize = building.displaySize(inExploration: inExploration)
        let size = CGSize(width: displaySize.width * unit, height: displaySize.height * unit)
        let node = SKNode()
        let footprint = SKShapeNode(rectOf: size, cornerRadius: miniature ? 5 : 8)
        footprint.fillColor = SKColor(red: 0.26, green: 0.22, blue: 0.15, alpha: miniature ? 0.45 : 0.34)
        footprint.strokeColor = selectedBuilding == id ? .systemOrange : cream.withAlphaComponent(0.75)
        footprint.lineWidth = selectedBuilding == id ? 4 : 2
        footprint.name = "building-\(id)"
        node.addChild(footprint)

        if building.kind == .well {
            let radius = min(size.width, size.height) * 0.38
            let stone = SKShapeNode(circleOfRadius: radius)
            stone.fillColor = SKColor(red: 0.48, green: 0.48, blue: 0.43, alpha: 1)
            stone.strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.22, alpha: 1)
            stone.lineWidth = miniature ? 1.4 : 2
            stone.name = "building-\(id)"
            node.addChild(stone)

            let water = SKShapeNode(circleOfRadius: radius * 0.58)
            water.fillColor = SKColor(red: 0.25, green: 0.58, blue: 0.66, alpha: 1)
            water.strokeColor = SKColor(red: 0.17, green: 0.35, blue: 0.39, alpha: 1)
            water.lineWidth = miniature ? 1 : 1.5
            water.name = "building-\(id)"
            node.addChild(water)
        } else {
        let houseWidth = size.width * 0.74
        let houseHeight = size.height * 0.58
        let wall = SKShapeNode(rectOf: CGSize(width: houseWidth, height: houseHeight * 0.58), cornerRadius: miniature ? 4 : 7)
        wall.position = CGPoint(x: 0, y: -size.height * 0.03)
        wall.fillColor = SKColor(red: 0.64, green: 0.43, blue: 0.25, alpha: 1)
        wall.strokeColor = SKColor(red: 0.28, green: 0.18, blue: 0.11, alpha: 0.7)
        wall.lineWidth = miniature ? 1.4 : 2
        wall.name = "building-\(id)"
        node.addChild(wall)

        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -houseWidth * 0.55, y: houseHeight * 0.10))
        roofPath.addLine(to: CGPoint(x: 0, y: houseHeight * 0.56))
        roofPath.addLine(to: CGPoint(x: houseWidth * 0.55, y: houseHeight * 0.10))
        roofPath.closeSubpath()
        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = SKColor(red: 0.82, green: 0.62, blue: 0.34, alpha: 1)
        roof.strokeColor = SKColor(red: 0.35, green: 0.23, blue: 0.14, alpha: 0.85)
        roof.lineWidth = miniature ? 1.6 : 2.4
        roof.name = "building-\(id)"
        node.addChild(roof)

        let door = SKShapeNode(rectOf: CGSize(width: houseWidth * 0.16, height: houseHeight * 0.26), cornerRadius: miniature ? 2 : 4)
        door.position = CGPoint(x: 0, y: -houseHeight * 0.20)
        door.fillColor = SKColor(red: 0.23, green: 0.44, blue: 0.40, alpha: 1)
        door.strokeColor = .clear
        door.name = "building-\(id)"
        node.addChild(door)
        }

        let grid = SKShapeNode(rectOf: size)
        grid.strokeColor = SKColor(white: 0.05, alpha: 0.30)
        grid.lineWidth = miniature ? 0.8 : 1
        grid.name = "building-\(id)"
        node.addChild(grid)

        text(building.title, at: CGPoint(x: 0, y: -size.height * 0.5 - (miniature ? 8 : 13)), size: miniature ? 8 : 11, parent: node, color: cream)
        node.children.forEach { $0.name = "building-\(id)" }
        return node
    }

    private func buildingRect(id: String, centeredAt center: CGPoint) -> CGRect? {
        guard let building = VillageTileLayout.building(id) else { return nil }
        let unit = VillageCartoMap.subcellSide
        return CGRect(
            x: center.x - CGFloat(building.width) * unit / 2,
            y: center.y - CGFloat(building.height) * unit / 2,
            width: CGFloat(building.width) * unit,
            height: CGFloat(building.height) * unit
        )
    }

    private func buildingSubcell(id: String, centeredAt center: CGPoint) -> (Int, Int)? {
        guard let rect = buildingRect(id: id, centeredAt: center) else { return nil }
        let unit = VillageCartoMap.subcellSide
        return (Int(round(rect.minX / unit)), Int(round(rect.minY / unit)))
    }

    private func showBuildingGrid() {
        guard buildingGrid == nil else { return }
        let unit = VillageCartoMap.subcellSide
        let path = CGMutablePath()

        for piece in layout.placements {
            for cell in VillageTileLayout.cells(of: piece) {
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

        let border = SKShapeNode(path: path)
        border.name = "buildingGrid"
        border.strokeColor = SKColor.systemBlue.withAlphaComponent(0.55)
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
            let node = buildingNode(placement.id, miniature: isMap, inExploration: !isMap)
            node.position = CGPoint(x: rect.midX, y: rect.midY)
            node.zPosition = 22
            world.addChild(node)
        }
        if !isMap {
            renderQuest1World()
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

        button("Kembali",name:"exit",at:CGPoint(x:80,y:size.height-32))
        button(isMap ? "Jelajahi" : "Susun peta",name:"toggle",at:CGPoint(x:rightEdge-90,y:size.height-32),width:135)
        if isMap {
            button("Debug selesai",name:"debugSolveCarto",at:CGPoint(x:210,y:size.height-32),width:145)
        }
        text(isMap ? "KEPING DESA" : "DESA ARTHUR",at:CGPoint(x:size.width/2,y:size.height-30),size:18,parent:hud,color:cream)
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
                let inventoryTurns = selected == id
                    ? draftTurns
                    : VillageCartoMap.preferredTurns(forPieceID: id)
                let node = tile(id,turns:inventoryTurns,miniature:true)
                let bounds = VillageTileLayout.outline(id).boundingBoxOfPath
                node.setScale(thumb/max(bounds.width,bounds.height)); node.name = "inventory-\(id)"
                node.position = CGPoint(
                    x: rightEdge - 134 + CGFloat(index % 2) * 80,
                    y: puzzleTopY - CGFloat(index / 2) * puzzleSpacing
                )
                let center = VillageTileLayout.rotated(CGPoint(x:bounds.midX,y:bounds.midY),
                    turns:inventoryTurns)
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
            let buildingInventory = unlockedBuildingInventory
            let buildingPages = max(1, Int(ceil(Double(buildingInventory.count) / Double(buildingPageSize))))
            buildingPage = min(buildingPage, buildingPages - 1)
            for (index, building) in buildingInventory
                .dropFirst(buildingPage * buildingPageSize)
                .prefix(buildingPageSize)
                .enumerated() {
                let node = buildingNode(building.id, miniature: true)
                let unit = VillageCartoMap.subcellSide
                let maxSide = max(CGFloat(building.width) * unit, CGFloat(building.height) * unit)
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
            button("Putar 90°",name:"rotate",at:CGPoint(x:82,y:56),width:120)
            button("Balikkan keping",name:"remove",at:CGPoint(x:219,y:56),width:140)
            button("−",name:"minus",at:CGPoint(x:315,y:56),width:38)
            button("+",name:"plus",at:CGPoint(x:362,y:56),width:38)
            button("Pusatkan",name:"center",at:CGPoint(x:435,y:56),width:90)
            if let id = selected {
                let number = VillageCartoMap.displayNumber(forPieceID: id) ?? (id + 1)
                text("Keping \(number) · \(draftTurns*90)°",at:CGPoint(x:board.midX,y:size.height-58),size:12,parent:hud,color:cream)
            } else if let id = selectedBuilding, let building = VillageTileLayout.building(id) {
                text("\(building.title) · \(building.width)x\(building.height) subgrid",at:CGPoint(x:board.midX,y:size.height-58),size:12,parent:hud,color:cream)
            }
        } else {
            let base = SKShapeNode(circleOfRadius:49); base.position = stickCenter
            base.fillColor = SKColor(white:0.1,alpha:0.45); base.strokeColor = .clear; hud.addChild(base)
            knob = SKShapeNode(circleOfRadius:19); knob.position = stickCenter
            knob.fillColor = SKColor(white:1,alpha:0.65); knob.strokeColor = .clear; hud.addChild(knob)
        }
        status.removeFromParent(); status.fontSize = 11; status.fontColor = cream; status.verticalAlignmentMode = .center
        status.position = CGPoint(x:size.width/2,y:19); hud.addChild(status)
        status.text = message ?? quest1Objective
        updateCamera()
    }

    private var quest1Objective: String {
        if quest1.returnedHome { return "Quest 1 selesai: Arthur telah kembali ke rumah." }
        if quest1.rackFixed {
            return layout.buildingPlacements.contains(where: { $0.id == "arthur-house" })
                ? "Kembali ke Rumah Arthur dan bicara dengan Kakek."
                : "Tempatkan Rumah Arthur, lalu kembali menemui Kakek."
        }
        if quest1.spokeToMara { return "Dekati rak miring lalu ketuk [Interact: Periksa Rak]." }
        if quest1.collectedWater {
            return layout.buildingPlacements.contains(where: { $0.id == "bu-mara-house" })
                ? "Temui Bu Mara di depan rumahnya."
                : "Tempatkan Rumah Bu Mara (6x6) di area kuning."
        }
        if quest1.spokeToGrandpa {
            return layout.buildingPlacements.contains(where: { $0.id == "village-well" })
                ? "Dekati Sumur dan ambil air."
                : "Sumur terbuka. Tempatkan Sumur (3x3) pada susunan awal L dan Z."
        }
        return layout.buildingPlacements.contains(where: { $0.id == "arthur-house" })
            ? "Susun keping awal L dan Z, lalu Jelajahi dan bicara dengan Kakek di Rumah Arthur."
            : "Tempatkan Rumah Arthur (6x9) di area kuning pada keping L, lalu susun L dan Z."
    }

    private func presentQuestDialogue(
        _ lines: [QuestDialogueLine],
        onFinished: (() -> Void)? = nil
    ) {
        questDialogue = lines
        questDialogueIndex = 0
        questDialogueCompletion = onFinished
        renderQuestDialogue()
    }

    private func renderQuestDialogue() {
        hud.childNode(withName: "quest-dialogue")?.removeFromParent()
        guard questDialogue.indices.contains(questDialogueIndex) else { return }
        let line = questDialogue[questDialogueIndex]
        let width = min(size.width - 44, 680)
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: 116), cornerRadius: 12)
        panel.name = "quest-dialogue"
        panel.position = CGPoint(x: size.width / 2, y: 96)
        panel.fillColor = SKColor(white: 0.08, alpha: 0.96)
        panel.strokeColor = cream.withAlphaComponent(0.75)
        panel.lineWidth = 2
        panel.zPosition = 2500

        let speaker = SKLabelNode(fontNamed: "AvenirNext-Bold")
        speaker.text = line.speaker
        speaker.fontSize = 15
        speaker.fontColor = .systemYellow
        speaker.horizontalAlignmentMode = .left
        speaker.position = CGPoint(x: -width / 2 + 20, y: 31)
        panel.addChild(speaker)

        let body = SKLabelNode(fontNamed: "AvenirNext-Regular")
        body.text = line.text
        body.fontSize = 13
        body.fontColor = .white
        body.horizontalAlignmentMode = .left
        body.verticalAlignmentMode = .top
        body.preferredMaxLayoutWidth = width - 40
        body.numberOfLines = 3
        body.position = CGPoint(x: -width / 2 + 20, y: 13)
        panel.addChild(body)

        let next = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        next.text = questDialogueIndex == questDialogue.count - 1 ? "Ketuk untuk lanjut" : "Ketuk untuk berikutnya"
        next.fontSize = 10
        next.fontColor = cream.withAlphaComponent(0.8)
        next.position = CGPoint(x: width / 2 - 82, y: -43)
        panel.addChild(next)
        hud.addChild(panel)
    }

    private func advanceQuestDialogue() {
        guard !questDialogue.isEmpty else { return }
        questDialogueIndex += 1
        if questDialogue.indices.contains(questDialogueIndex) {
            renderQuestDialogue()
            return
        }
        hud.childNode(withName: "quest-dialogue")?.removeFromParent()
        questDialogue = []
        questDialogueIndex = 0
        let completion = questDialogueCompletion
        questDialogueCompletion = nil
        completion?()
    }

    private func bucketFade(completion: @escaping () -> Void) {
        let fade = SKSpriteNode(color: .black, size: size)
        fade.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fade.alpha = 0
        fade.zPosition = 2900
        hud.addChild(fade)
        AudioService.shared.playSystemSound(id: 1104)
        fade.run(.sequence([
            .fadeAlpha(to: 0.95, duration: 0.35),
            .wait(forDuration: 0.28),
            .fadeOut(withDuration: 0.35),
            .removeFromParent(),
            .run(completion)
        ]))
    }

    private func saveQuest1() {
        if let data = try? JSONEncoder().encode(quest1) {
            UserDefaults.standard.set(data, forKey: Self.quest1SaveKey)
        }
    }

    private func questPosition(for buildingID: String, offset: CGPoint = .zero) -> CGPoint? {
        guard let placement = layout.buildingPlacements.first(where: { $0.id == buildingID }),
              let rect = VillageTileLayout.buildingRect(placement) else { return nil }
        return CGPoint(x: rect.midX + offset.x, y: rect.midY + offset.y)
    }

    private func questMarker(at position: CGPoint, name: String, color: SKColor, symbol: String) {
        let marker = SKShapeNode(circleOfRadius: 10)
        marker.name = name
        marker.position = position
        marker.fillColor = color
        marker.strokeColor = .white
        marker.lineWidth = 1.5
        marker.zPosition = 70
        text(symbol, at: .zero, size: 10, parent: marker)
        world.addChild(marker)
    }

    private func questNPC(at position: CGPoint, name: String, color: SKColor) {
        let npc = MemoryCharacter(title: name, color: color)
        npc.name = "quest-\(name)"
        npc.position = position
        npc.setScale(0.3)
        npc.zPosition = 65
        world.addChild(npc)
    }

    private var grandpaQuestPosition: CGPoint? {
        if let house = questPosition(for: "arthur-house") {
            return CGPoint(x: house.x + 30, y: house.y)
        }
        return nil
    }

    private func renderGrandpaPorch(at position: CGPoint) {
        let porch = SKShapeNode(rectOf: CGSize(width: 62, height: 25), cornerRadius: 3)
        porch.position = CGPoint(x: position.x, y: position.y - 7)
        porch.fillColor = SKColor(red: 0.38, green: 0.23, blue: 0.12, alpha: 1)
        porch.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.06, alpha: 1)
        porch.lineWidth = 2
        porch.zPosition = 54
        world.addChild(porch)

        for x in stride(from: -24, through: 24, by: 12) {
            let plank = SKShapeNode(rectOf: CGSize(width: 1.5, height: 22))
            plank.position = CGPoint(x: CGFloat(x), y: 0)
            plank.fillColor = cream.withAlphaComponent(0.25)
            plank.strokeColor = .clear
            porch.addChild(plank)
        }
    }

    private func renderMaraBackyard(at position: CGPoint) {
        let yard = SKNode()
        yard.position = position
        yard.zPosition = 53

        for offset in [CGPoint(x: -25, y: -14), CGPoint(x: 15, y: -17)] {
            let mud = SKShapeNode(ellipseOf: CGSize(width: 42, height: 18))
            mud.position = offset
            mud.fillColor = SKColor(red: 0.28, green: 0.19, blue: 0.12, alpha: 0.75)
            mud.strokeColor = SKColor(red: 0.16, green: 0.11, blue: 0.08, alpha: 0.8)
            yard.addChild(mud)
        }

        let shelf = SKShapeNode(rectOf: CGSize(width: 46, height: 5), cornerRadius: 1)
        shelf.position = CGPoint(x: -18, y: 4)
        shelf.zRotation = -0.16
        shelf.fillColor = .systemBrown
        shelf.strokeColor = .black.withAlphaComponent(0.45)
        yard.addChild(shelf)
        for x in [-17.0, 17.0] {
            let leg = SKShapeNode(rectOf: CGSize(width: 4, height: 25))
            leg.position = CGPoint(x: x, y: -11)
            leg.fillColor = .systemBrown
            leg.strokeColor = .clear
            shelf.addChild(leg)
        }
        for x in [-31.0, -18.0, -5.0] {
            let pot = SKShapeNode(circleOfRadius: 5)
            pot.position = CGPoint(x: x, y: 13)
            pot.fillColor = SKColor(red: 0.72, green: 0.35, blue: 0.18, alpha: 1)
            pot.strokeColor = .black.withAlphaComponent(0.35)
            yard.addChild(pot)
        }
        let brick = SKShapeNode(rectOf: CGSize(width: 14, height: 7), cornerRadius: 1)
        brick.position = CGPoint(x: 28, y: -9)
        brick.fillColor = .systemRed
        brick.strokeColor = .black.withAlphaComponent(0.4)
        yard.addChild(brick)
        world.addChild(yard)
    }

    private func renderQuest1World() {
        if let grandpa = grandpaQuestPosition {
            renderGrandpaPorch(at: grandpa)
            questNPC(at: grandpa, name: "Kakek", color: .systemBrown)
            if !quest1.spokeToGrandpa || quest1.rackFixed {
                questMarker(at: CGPoint(x: grandpa.x, y: grandpa.y + 25),
                            name: "quest-grandpa", color: .systemYellow, symbol: "!")
            }
        }

        if quest1.spokeToGrandpa,
           !quest1.collectedWater,
           let well = questPosition(for: "village-well") {
            questMarker(at: CGPoint(x: well.x, y: well.y + 22),
                        name: "quest-well", color: .systemTeal, symbol: "!")
        }

        if quest1.collectedWater,
           let maraHouse = questPosition(for: "bu-mara-house") {
            renderMaraBackyard(at: CGPoint(x: maraHouse.x - 28, y: maraHouse.y))
            let mara = CGPoint(x: maraHouse.x + 28, y: maraHouse.y)
            questNPC(at: mara, name: "Bu Mara", color: .systemTeal)
            if !quest1.spokeToMara {
                questMarker(at: CGPoint(x: mara.x, y: mara.y + 25),
                            name: "quest-mara", color: .systemYellow, symbol: "!")
            } else if !quest1.rackFixed {
                questMarker(at: CGPoint(x: maraHouse.x - 28, y: maraHouse.y),
                            name: "quest-rack", color: .systemOrange, symbol: "!")
            }
        }
    }

    private func closeEnough(_ target: CGPoint) -> Bool {
        hypot(actor.position.x - target.x, actor.position.y - target.y) <= 70
    }

    private func approachOrInteract(_ target: CGPoint, message: String, action: () -> Void) {
        if closeEnough(target) {
            route = []
            stick = .zero
            action()
        } else {
            route = [target]
            status.text = message
        }
    }

    private func handleQuest1Interaction(at point: CGPoint) -> Bool {
        if let grandpa = grandpaQuestPosition {
            if hypot(point.x - grandpa.x, point.y - grandpa.y) <= 45 {
                approachOrInteract(grandpa, message: "Dekati Kakek untuk berbicara.") { [weak self] in
                    guard let self else { return }
                    if self.quest1.rackFixed {
                        self.presentQuestDialogue([
                            .init(
                                speaker: "Kakek",
                                text: "Did the well move further away today? Half your water is gone."
                            ),
                            .init(
                                speaker: "Arthur",
                                text: "Bu Mara's shelf almost collapsed. I had to fix it."
                            ),
                            .init(
                                speaker: "Kakek",
                                text: "Good thing you saw it before the well collapsed too."
                            ),
                            .init(
                                speaker: "Narasi",
                                text: "Kakek menyodorkan mangkuk sarapan kepada Arthur."
                            ),
                            .init(
                                speaker: "Kakek",
                                text: "Where are you off to next?"
                            ),
                            .init(
                                speaker: "Arthur",
                                text: "The barn. If there's nothing to help with, I'll come straight home."
                            ),
                            .init(
                                speaker: "Kakek",
                                text: "We both know you rarely find a day like that."
                            )
                        ]) { [weak self] in
                            guard let self else { return }
                            self.quest1.returnedHome = true
                            let progress = PrologueStore.shared.progress
                            progress.storyProgress = max(progress.storyProgress, 1)
                            PrologueStore.shared.save()
                            self.saveQuest1()
                            self.rebuild("Quest 1 selesai. Tujuan berikutnya: lumbung.")
                        }
                    } else if !self.quest1.spokeToGrandpa {
                        self.presentQuestDialogue([
                            .init(
                                speaker: "Kakek",
                                text: "Arthur, can you bring me well water? Our water is running out."
                            ),
                            .init(
                                speaker: "Arthur",
                                text: "Sure, Grandpa. I will bring the bucket and get the water."
                            )
                        ]) { [weak self] in
                            guard let self else { return }
                            self.quest1.spokeToGrandpa = true
                            self.saveQuest1()
                            self.rebuild("Sumur terbuka. Tempatkan Sumur pada susunan L dan Z.")
                        }
                    } else {
                        self.status.text = self.quest1Objective
                    }
                }
                return true
            }
        }

        if quest1.spokeToGrandpa,
           !quest1.collectedWater,
           let well = questPosition(for: "village-well"),
           hypot(point.x - well.x, point.y - well.y) <= 45 {
            approachOrInteract(well, message: "Dekati Sumur untuk mengambil air.") { [weak self] in
                guard let self else { return }
                self.quest1.collectedWater = true
                self.saveQuest1()
                self.rebuild("Air diambil. Bu Mara muncul dan Rumah Bu Mara terbuka.")
            }
            return true
        }

        if quest1.collectedWater,
           let maraHouse = questPosition(for: "bu-mara-house") {
            let mara = CGPoint(x: maraHouse.x + 28, y: maraHouse.y)
            if !quest1.spokeToMara,
               hypot(point.x - mara.x, point.y - mara.y) <= 45 {
                approachOrInteract(mara, message: "Dekati Bu Mara untuk berbicara.") { [weak self] in
                    guard let self else { return }
                    self.presentQuestDialogue([
                        .init(
                            speaker: "Narasi",
                            text: "Arthur berjalan membawa ember air. Bu Mara melambai dari halaman belakangnya yang becek."
                        ),
                        .init(
                            speaker: "Bu Mara",
                            text: "Arthur! Just in time. Can you help me move these clay pots? The shelf is about to give out."
                        ),
                        .init(
                            speaker: "Arthur",
                            text: "The ground is sinking under this leg, Bu Mara. Moving the pots won't fix it. Let me wedge this broken brick under it."
                        )
                    ]) { [weak self] in
                        guard let self else { return }
                        self.quest1.spokeToMara = true
                        self.saveQuest1()
                        self.rebuild("Dekati rak dan ketuk [Interact: Periksa Rak].")
                    }
                }
                return true
            }

            let rack = CGPoint(x: maraHouse.x - 28, y: maraHouse.y)
            if quest1.spokeToMara,
               !quest1.rackFixed,
               hypot(point.x - rack.x, point.y - rack.y) <= 45 {
                approachOrInteract(rack, message: "Dekati rak lalu ketuk [Interact: Periksa Rak].") { [weak self] in
                    self?.startQuest1RackMinigame()
                }
                return true
            }
        }
        return false
    }

    private func startQuest1RackMinigame() {
        guard activeQuestMinigame == nil else { return }
        let event = ShelfBalanceMinigameNode()
        event.position = CGPoint(x: size.width / 2, y: size.height / 2)
        event.zPosition = 3000
        event.onComplete = { [weak self] success in
            guard success, let self else { return }
            self.quest1.rackFixed = true
            self.saveQuest1()
        }
        event.onDismiss = { [weak self, weak event] in
            guard let self else { return }
            if self.activeQuestMinigame === event {
                self.activeQuestMinigame = nil
            }
            if self.quest1.rackFixed {
                self.presentQuestDialogue([
                    .init(
                        speaker: "Bu Mara",
                        text: "Oh, thank you! I can always count on you, Arthur. Now, since you're already here... help me lift these other two pots anyway."
                    ),
                    .init(
                        speaker: "Narasi",
                        text: "Arthur menghela napas pasrah sambil tersenyum, memindahkan dua pot, lalu mengambil kembali ember yang isinya sudah tumpah separuh."
                    )
                ]) { [weak self] in
                    self?.bucketFade { [weak self] in
                        self?.rebuild("Air tinggal separuh. Kembali ke Rumah Arthur.")
                    }
                }
            } else {
                self.rebuild("Rak belum selesai. Ketuk rak untuk mencoba lagi.")
            }
        }
        activeQuestMinigame = event
        addChild(event)
        event.start()
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
    override func willMove(from view: SKView) {
        if let pinchGesture { view.removeGestureRecognizer(pinchGesture) }
        if let rotationGesture { view.removeGestureRecognizer(rotationGesture) }
        if let twoFingerPanGesture { view.removeGestureRecognizer(twoFingerPanGesture) }
        pinchGesture = nil
        rotationGesture = nil
        twoFingerPanGesture = nil
        pinchActive = false
        rotationActive = false
        twoFingerPanActive = false
        twoFingerMode = .none
    }
    private func dominantTwoFingerMode() -> TwoFingerMode? {
        let zoomScore = abs(log(max(0.001, pinchGesture?.scale ?? 1))) / 0.08
        let rotationScore = abs(rotationGesture?.rotation ?? 0) / 0.10
        let translation = twoFingerPanGesture?.translation(in: twoFingerPanGesture?.view) ?? .zero
        let panScore = hypot(translation.x,translation.y) / 14
        let best = max(zoomScore,rotationScore,panScore)
        guard best >= 1 else { return nil }
        if panScore >= zoomScore && panScore >= rotationScore { return .pan }
        if rotationScore > zoomScore { return .rotate }
        return .zoom
    }
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard isMap, let skView = gesture.view as? SKView else { pinchActive = false; return }
        let p = convertPoint(fromView: gesture.location(in: skView))
        switch gesture.state {
        case .began:
            guard board.contains(p) else { pinchActive = false; return }
            stopInput()
            pinchActive = true
            lastPinchScale = 1
            if selected == nil { twoFingerMode = .zoom }
        case .changed:
            guard pinchActive else { return }
            if twoFingerMode == .none {
                guard let mode = dominantTwoFingerMode() else { return }
                twoFingerMode = mode
            }
            guard twoFingerMode == .zoom else { return }
            let oldScale = world.xScale
            guard oldScale > 0 else { return }
            let anchor = CGPoint(x: mapCenter.x + (p.x-board.midX)/oldScale, y: mapCenter.y + (p.y-board.midY)/oldScale)
            let factor = gesture.scale / max(0.001, lastPinchScale)
            zoom = max(0.5,min(2,zoom*factor))
            lastPinchScale = gesture.scale
            let newScale = min(board.width/(VillageTileLayout.side*10),board.height/(VillageTileLayout.side*6))*zoom
            mapCenter = CGPoint(
                x: max(0,min(VillageTileLayout.bounds.width,anchor.x-(p.x-board.midX)/newScale)),
                y: max(0,min(VillageTileLayout.bounds.height,anchor.y-(p.y-board.midY)/newScale))
            )
            updateCamera()
        case .ended, .cancelled, .failed:
            pinchActive = false
            lastPinchScale = 1
            if !rotationActive { twoFingerMode = .none }
        default:
            break
        }
    }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === pinchGesture { return isMap }
        if gestureRecognizer === rotationGesture {
            guard isMap, selectedBuilding == nil, let selected else { return false }
            return !layout.hasBuilding(onPieceID: selected)
        }
        if gestureRecognizer === twoFingerPanGesture { return isMap }
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let first = gestureRecognizer === pinchGesture || gestureRecognizer === rotationGesture || gestureRecognizer === twoFingerPanGesture
        let second = otherGestureRecognizer === pinchGesture || otherGestureRecognizer === rotationGesture || otherGestureRecognizer === twoFingerPanGesture
        return first && second
    }
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard isMap, selectedBuilding == nil, let id = selected, let skView = gesture.view as? SKView else {
            rotationActive = false
            return
        }
        let p = convertPoint(fromView: gesture.location(in: skView))
        switch gesture.state {
        case .began:
            guard board.contains(p) else { rotationActive = false; return }
            stopInput()
            rotationStartTurns = draftTurns
            rotationActive = true
        case .changed:
            guard rotationActive else { return }
            if twoFingerMode == .none {
                guard let mode = dominantTwoFingerMode() else { return }
                twoFingerMode = mode
            }
            guard twoFingerMode == .rotate else { return }
            let step = Int(round(-gesture.rotation / (.pi / 2)))
            let turns = ((rotationStartTurns + step) % 4 + 4) % 4
            if turns != draftTurns {
                draftTurns = turns
                rebuild()
            }
        case .ended:
            guard rotationActive else { return }
            rotationActive = false
            if twoFingerMode == .rotate {
                if let piece = layout.placements.first(where: { $0.id == id }) {
                    if layout.place(id:id,column:piece.column,row:piece.row,turns:draftTurns) {
                        save(); rebuild("Keping diputar \(draftTurns * 90)°.")
                    } else {
                        draftTurns = piece.turns
                        rebuild("Rotasi terhalang keping lain, batas peta, atau sambungan biome.")
                    }
                } else {
                    rebuild("Rotasi siap. Letakkan keping di slot kosong untuk menerapkan.")
                }
            }
            if !pinchActive { twoFingerMode = .none }
        case .cancelled, .failed:
            if twoFingerMode == .rotate { draftTurns = rotationStartTurns; rebuild() }
            rotationActive = false
            if !pinchActive { twoFingerMode = .none }
        default:
            break
        }
    }
    @objc private func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard isMap, let skView = gesture.view as? SKView else {
            twoFingerPanActive = false
            return
        }
        let p = convertPoint(fromView: gesture.location(in: skView))
        switch gesture.state {
        case .began:
            guard board.contains(p) else { twoFingerPanActive = false; return }
            stopInput()
            twoFingerPanStart = mapCenter
            twoFingerPanActive = true
        case .changed:
            guard twoFingerPanActive else { return }
            if twoFingerMode == .none {
                guard let mode = dominantTwoFingerMode() else { return }
                twoFingerMode = mode
            }
            guard twoFingerMode == .pan else { return }
            let translation = gesture.translation(in: skView)
            mapCenter = CGPoint(
                x: max(0,min(VillageTileLayout.bounds.width,twoFingerPanStart.x-translation.x/world.xScale)),
                y: max(0,min(VillageTileLayout.bounds.height,twoFingerPanStart.y+translation.y/world.yScale))
            )
            updateCamera()
        case .ended, .cancelled, .failed:
            twoFingerPanActive = false
            if !pinchActive && !rotationActive { twoFingerMode = .none }
        default:
            break
        }
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
        guard !layout.hasBuilding(onPieceID: id) else {
            status.text = "Keping tidak bisa dikembalikan karena masih ada bangunan di atasnya."
            return
        }
        if layout.remove(id:id) {
            save(); selected = nil
            if let index = available.firstIndex(of:id) { page = index/pageSize }
            let number = VillageCartoMap.displayNumber(forPieceID: id) ?? (id + 1)
            rebuild("Keping \(number) kembali ke inventori.")
        } else { status.text = "Keping ini sudah ada di inventori." }
    }
    private func select(_ id: Int) {
        if selected != id {
            draftTurns = layout.placements.first(where:{$0.id == id})?.turns
                ?? VillageCartoMap.preferredTurns(forPieceID: id)
        }
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
        if !questDialogue.isEmpty {
            advanceQuestDialogue()
            return
        }
        guard activeTouch == nil, stickTouch == nil, let touch = touches.first else { return }
        let p = touch.location(in:hud), actions = names(at:p)
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
            if actions.contains("rotate") {
                guard let selectedID = selected else { status.text = "Pilih keping terlebih dahulu."; return }
                guard !layout.hasBuilding(onPieceID: selectedID) else {
                    status.text = "Pindahkan bangunan dari keping ini sebelum memutarnya."
                    return
                }
                draftTurns = (draftTurns+1)%4
                if let piece = layout.placements.first(where:{$0.id == selectedID}) {
                    if layout.place(id:selectedID,column:piece.column,row:piece.row,turns:draftTurns) {
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
                guard let rect = buildingRect(id: id, centeredAt: .zero) else { return false }
                return rect.insetBy(dx: -14, dy: -22).contains(node.convert(p, from: hud))
            }) {
                selectBuilding(hit.id)
                dragOffset = .zero
                activeTouch = touch; touchStart = p; return
            }
            guard board.contains(p) else { return }
            let q = touch.location(in:world)
            if let building = layout.buildingPlacement(at: q),
               let rect = VillageTileLayout.buildingRect(building) {
                selectBuilding(building.id)
                dragOffset = CGPoint(x: rect.midX - q.x, y: rect.midY - q.y)
                activeTouch = touch; touchStart = p
            } else if let piece = layout.placement(at:q) {
                if layout.hasBuilding(onPieceID: piece.id) {
                    status.text = "Keping terkunci karena masih ada bangunan di atasnya. Pindahkan bangunannya dahulu."
                    return
                }
                select(piece.id); dragOffset = CGPoint(x:piece.center.x-q.x,y:piece.center.y-q.y)
                activeTouch = touch; touchStart = p
            } else {
                activeTouch = touch; touchStart = p; panStart = mapCenter; panning = true; dragOffset = .zero
            }
        } else {
            guard p.y < size.height-58, p.y > 38 else { return }
            if hypot(p.x-stickCenter.x,p.y-stickCenter.y) < 62 {
                stickTouch = touch
                route = []
                updateStick(touch)
            } else {
                let destination = touch.location(in: world)
                if handleQuest1Interaction(at: destination) { return }
                route = layout.route(from: actor.position, to: destination)
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
                let node = buildingNode(buildingID, miniature: true)
                node.alpha = 0.82; node.zPosition = 40; world.addChild(node); ghost = node
            }
            let touchPoint = touch.location(in:world)
            let center = CGPoint(x: touchPoint.x + dragOffset.x, y: touchPoint.y + dragOffset.y)
            let unit = VillageCartoMap.subcellSide
            let snapped = CGPoint(x: round(center.x / unit) * unit, y: round(center.y / unit) * unit)
            ghost?.position = snapped
            world.childNode(withName:"dropSlot")?.removeFromParent()
            if let (subColumn, subRow) = buildingSubcell(id: buildingID, centeredAt: snapped),
               let rect = buildingRect(id: buildingID, centeredAt: snapped) {
                let slot = SKShapeNode(rectOf: rect.size, cornerRadius: 9)
                slot.name = "dropSlot"; slot.position = snapped
                slot.strokeColor = layout.canPlaceBuilding(id: buildingID, subColumn: subColumn, subRow: subRow) ? .systemGreen : .systemRed
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
            let unit = VillageCartoMap.subcellSide
            let snapped = CGPoint(x: round(q.x / unit) * unit, y: round(q.y / unit) * unit)
            if let (subColumn, subRow) = buildingSubcell(id: buildingID, centeredAt: snapped),
               layout.placeBuilding(id: buildingID, subColumn: subColumn, subRow: subRow) {
                save()
                rebuild("Bangunan ditempatkan di gabungan keping.")
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
