//
//  GameScene.swift
//  MemoryGame
//
//  SpriteKit port of kleryjohansen/PuzzleGame1.
//

import SpriteKit

final class GameScene: SKScene {

    let world = ECSWorld()
    let dragSystem = DragSystem()
    let snapSystem = SnapSystem()
    let renderSystem = RenderSystem()
    let progressSystem = PuzzleProgressSystem()

    var activeDragEntity: EntityID?
    var boardRect = CGRect.zero
    var boardScale: CGFloat = 1.0
    var topZPosition: CGFloat = 10

    private var hudCountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var completionOverlay: SKNode?
    private var finalPhotoNode: SKSpriteNode?

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = GameConstants.Colors.tableBackground
        configurePhysicsWorld()
        buildPuzzleGame()
    }

    override func update(_ currentTime: TimeInterval) {
        renderSystem.update(world: world)
    }

    func buildPuzzleGame() {
        removeAllChildren()
        world.removeAll()
        activeDragEntity = nil
        completionOverlay = nil
        finalPhotoNode = nil
        topZPosition = 10

        updateCanvas(size: size)
        addDottedGridCanvas()
        addBoardBracket()
        createPuzzleTargets()
        createPuzzlePieces()
        addHUD()
        updateHUD()
        renderSystem.update(world: world)
    }

    func updateCanvas(size: CGSize) {
        guard size.width > 50, size.height > 50 else { return }

        let aspect = PuzzleCatalog.canvasWidth / PuzzleCatalog.canvasHeight
        let isLandscape = size.width > size.height
        var targetWidth: CGFloat
        var targetHeight: CGFloat

        if isLandscape {
            targetWidth = size.width * 0.44
            targetHeight = targetWidth / aspect

            if targetHeight > size.height * 0.56 {
                targetHeight = size.height * 0.56
                targetWidth = targetHeight * aspect
            }
        } else {
            targetWidth = size.width * 0.88
            targetHeight = targetWidth / aspect

            if targetHeight > size.height * 0.38 {
                targetHeight = size.height * 0.38
                targetWidth = targetHeight * aspect
            }
        }

        boardRect = CGRect(x: -targetWidth / 2, y: -targetHeight / 2, width: targetWidth, height: targetHeight)
        boardScale = targetWidth / PuzzleCatalog.canvasWidth
    }

    func createPuzzleTargets() {
        for (index, data) in PuzzleCatalog.pieces.enumerated() {
            let entity = world.createEntity()
            let marker = SKNode()
            marker.name = "target-\(entity)"
            addChild(marker)

            let target = targetCenter(for: data)
            world.transforms[entity] = TransformComponent(position: target, scale: 1.0, zPosition: 0)
            world.renders[entity] = RenderComponent(node: marker)
            world.puzzlePieces[entity] = PuzzlePieceComponent(
                puzzleID: index,
                column: data.col,
                row: data.row,
                title: data.id,
                data: data,
                isSnapped: true
            )
            world.snapTargets[entity] = SnapTargetComponent(position: target, radius: effectiveSnapThreshold)
        }
    }

    func createPuzzlePieces() {
        for (index, data) in PuzzleCatalog.pieces.enumerated() {
            let entity = world.createEntity()
            let node = makePieceNode(entity: entity, data: data)
            addChild(node)

            let startPosition = scatteredPosition(index: index)
            world.transforms[entity] = TransformComponent(position: startPosition, scale: 1.0, zPosition: 0)
            world.renders[entity] = RenderComponent(node: node)
            world.puzzlePieces[entity] = PuzzlePieceComponent(
                puzzleID: index,
                column: data.col,
                row: data.row,
                title: data.id,
                data: data,
                isSnapped: false
            )
            world.draggables[entity] = DraggableComponent(
                homePosition: startPosition,
                currentLoosePosition: startPosition,
                dragOffset: .zero,
                dragStartTouch: .zero,
                dragStartPosition: startPosition,
                wasSnappedAtDragStart: false,
                isDragging: false
            )
        }
    }

    func makePieceNode(entity: EntityID, data: PuzzlePieceData) -> SKSpriteNode {
        let node = SKSpriteNode(imageNamed: data.assetName)
        node.name = "entity-\(entity)"
        node.size = CGSize(width: data.width * boardScale, height: data.height * boardScale)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 0
        return node
    }

    func targetCenter(for data: PuzzlePieceData) -> CGPoint {
        let scaledTargetX = (data.targetX - 18.0) * boardScale
        let scaledTargetY = (data.targetY - 18.0) * boardScale
        let scaledWidth = data.width * boardScale
        let scaledHeight = data.height * boardScale

        return CGPoint(
            x: boardRect.minX + scaledTargetX + scaledWidth / 2,
            y: boardRect.maxY - scaledTargetY - scaledHeight / 2
        )
    }

    func scatteredPosition(index: Int) -> CGPoint {
        var pieces = PuzzleCatalog.pieces.indices.map { $0 }
        var randomGenerator = StableRandom(seed: 42)
        pieces.shuffle(using: &randomGenerator)
        let shuffledIndex = pieces[index]
        let data = PuzzleCatalog.pieces[shuffledIndex]
        let pieceWidth = data.width * boardScale
        let pieceHeight = data.height * boardScale
        let isLandscape = size.width > size.height

        if isLandscape {
            return landscapeScatteredPosition(index: index, pieceWidth: pieceWidth, pieceHeight: pieceHeight)
        } else {
            return portraitScatteredPosition(index: index)
        }
    }

    private func landscapeScatteredPosition(index: Int, pieceWidth: CGFloat, pieceHeight: CGFloat) -> CGPoint {
        let topCount = min(12, PuzzleCatalog.pieces.count)
        let bottomCount = min(12, PuzzleCatalog.pieces.count - topCount)
        let leftCount = min(12, PuzzleCatalog.pieces.count - topCount - bottomCount)
        let topCols = 6
        let bottomCols = 6
        let sideCols = 2
        let referencePieceWidth = 380 * boardScale

        if index < topCount {
            let column = index % topCols
            let row = index / topCols
            let x = boardRect.minX + (CGFloat(column) + 0.5) * (boardRect.width / CGFloat(topCols))
            let availableTopHeight = boardRect.minY + size.height / 2
            let y = max(-size.height / 2 + pieceHeight / 2 + 10, -size.height / 2 + availableTopHeight / 2 + (row == 0 ? -10 : 12))
            return CGPoint(x: x, y: y)
        }

        if index < topCount + bottomCount {
            let localIndex = index - topCount
            let column = localIndex % bottomCols
            let row = localIndex / bottomCols
            let x = boardRect.minX + (CGFloat(column) + 0.5) * (boardRect.width / CGFloat(bottomCols))
            let remainingHeight = size.height / 2 - boardRect.maxY
            let y = boardRect.maxY + remainingHeight / 2 + (row == 0 ? -12 : 12)
            return CGPoint(x: x, y: min(size.height / 2 - pieceHeight / 2 - 8, y))
        }

        if index < topCount + bottomCount + leftCount {
            let localIndex = index - topCount - bottomCount
            let column = localIndex % sideCols
            let row = localIndex / sideCols
            let rows = max(1, (leftCount + sideCols - 1) / sideCols)
            let x = boardRect.minX / 2 + (column == 0 ? -referencePieceWidth * 0.28 : referencePieceWidth * 0.28)
            let y = boardRect.maxY - (CGFloat(row) + 0.5) * (boardRect.height / CGFloat(rows))
            return CGPoint(x: max(-size.width / 2 + pieceWidth / 2 + 6, x), y: y)
        }

        let localIndex = index - topCount - bottomCount - leftCount
        let rightCount = PuzzleCatalog.pieces.count - topCount - bottomCount - leftCount
        let column = localIndex % sideCols
        let row = localIndex / sideCols
        let rows = max(1, (rightCount + sideCols - 1) / sideCols)
        let remainingWidth = size.width / 2 - boardRect.maxX
        let x = boardRect.maxX + remainingWidth / 2 + (column == 0 ? -referencePieceWidth * 0.28 : referencePieceWidth * 0.28)
        let y = boardRect.maxY - (CGFloat(row) + 0.5) * (boardRect.height / CGFloat(rows))
        return CGPoint(x: min(size.width / 2 - pieceWidth / 2 - 6, x), y: y)
    }

    private func portraitScatteredPosition(index: Int) -> CGPoint {
        let topCount = PuzzleCatalog.pieces.count / 2
        let columns = 6

        if index < topCount {
            let column = index % columns
            let row = index / columns
            let rows = max(1, (topCount + columns - 1) / columns)
            let topAvailableHeight = max(boardRect.minY + size.height / 2 - 50, 100)
            return CGPoint(
                x: -size.width / 2 + (CGFloat(column) + 0.5) * (size.width / CGFloat(columns)),
                y: -size.height / 2 + 55 + (CGFloat(row) + 0.5) * (topAvailableHeight / CGFloat(rows))
            )
        }

        let bottomIndex = index - topCount
        let bottomCount = PuzzleCatalog.pieces.count - topCount
        let column = bottomIndex % columns
        let row = bottomIndex / columns
        let rows = max(1, (bottomCount + columns - 1) / columns)
        let bottomAvailableHeight = max(size.height / 2 - boardRect.maxY - 30, 100)
        return CGPoint(
            x: -size.width / 2 + (CGFloat(column) + 0.5) * (size.width / CGFloat(columns)),
            y: boardRect.maxY + 15 + (CGFloat(row) + 0.5) * (bottomAvailableHeight / CGFloat(rows))
        )
    }

    func addDottedGridCanvas() {
        let step: CGFloat = 26
        let radius: CGFloat = 1.1
        var x = -size.width / 2 + step / 2

        while x < size.width / 2 {
            var y = -size.height / 2 + step / 2
            while y < size.height / 2 {
                let dot = SKShapeNode(circleOfRadius: radius)
                dot.fillColor = SKColor(white: 1.0, alpha: 0.12)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: x, y: y)
                dot.zPosition = -20
                addChild(dot)
                y += step
            }
            x += step
        }
    }

    func addBoardBracket() {
        let backing = SKShapeNode(rectOf: boardRect.size, cornerRadius: 6)
        backing.fillColor = SKColor(white: 1.0, alpha: 0.025)
        backing.strokeColor = .clear
        backing.position = CGPoint(x: boardRect.midX, y: boardRect.midY)
        backing.zPosition = -3
        addChild(backing)
        addDashedBoardBorder()
    }

    func addDashedBoardBorder() {
        let dashLength: CGFloat = 8
        let gapLength: CGFloat = 8
        let halfWidth = boardRect.width / 2
        let halfHeight = boardRect.height / 2
        let corners = [
            CGPoint(x: -halfWidth, y: halfHeight),
            CGPoint(x: halfWidth, y: halfHeight),
            CGPoint(x: halfWidth, y: -halfHeight),
            CGPoint(x: -halfWidth, y: -halfHeight)
        ]

        for index in 0..<corners.count {
            let start = corners[index]
            let end = corners[(index + 1) % corners.count]
            let vector = CGPoint(x: end.x - start.x, y: end.y - start.y)
            let length = hypot(vector.x, vector.y)
            let direction = CGPoint(x: vector.x / length, y: vector.y / length)
            var traveled: CGFloat = 0

            while traveled < length {
                let segmentLength = min(dashLength, length - traveled)
                let segmentStart = CGPoint(x: start.x + direction.x * traveled, y: start.y + direction.y * traveled)
                let segmentEnd = CGPoint(x: segmentStart.x + direction.x * segmentLength, y: segmentStart.y + direction.y * segmentLength)
                let path = CGMutablePath()
                path.move(to: segmentStart)
                path.addLine(to: segmentEnd)

                let dash = SKShapeNode(path: path)
                dash.strokeColor = SKColor(white: 1.0, alpha: 0.32)
                dash.lineWidth = 1.5
                dash.position = CGPoint(x: boardRect.midX, y: boardRect.midY)
                dash.zPosition = -2
                addChild(dash)

                traveled += dashLength + gapLength
            }
        }
    }

    func addHUD() {
        let title = makeLabel(text: "Puzzle Prologue", fontSize: 13, position: CGPoint(x: -size.width / 2 + 20, y: size.height / 2 - 26))
        title.fontColor = SKColor(white: 1.0, alpha: 0.60)
        title.horizontalAlignmentMode = .left
        title.zPosition = 101
        addChild(title)

        hudCountLabel = makeLabel(text: "0 / 48", fontSize: 13, position: CGPoint(x: size.width / 2 - 130, y: size.height / 2 - 26))
        hudCountLabel.fontColor = SKColor(white: 1.0, alpha: 0.85)
        hudCountLabel.zPosition = 101
        addChild(hudCountLabel)

        addButton(name: "hintButton", text: "Hint", position: CGPoint(x: size.width / 2 - 74, y: size.height / 2 - 26))
        addButton(name: "resetButton", text: "Reset", position: CGPoint(x: size.width / 2 - 25, y: size.height / 2 - 26))
    }

    func addButton(name: String, text: String, position: CGPoint) {
        let button = SKShapeNode(rectOf: CGSize(width: 44, height: 30), cornerRadius: 15)
        button.name = name
        button.fillColor = SKColor(white: 1.0, alpha: 0.08)
        button.strokeColor = SKColor(white: 1.0, alpha: 0.10)
        button.position = position
        button.zPosition = 101
        addChild(button)

        let label = makeLabel(text: text, fontSize: 10, position: .zero)
        label.name = name
        label.fontColor = SKColor(white: 1.0, alpha: 0.86)
        button.addChild(label)
    }

    func solveOneHint() {
        guard let entity = world.draggables.keys.sorted().first(where: { world.puzzlePieces[$0]?.isSnapped == false }),
              let target = snapSystem.target(for: entity, world: world) else { return }
        topZPosition += 1
        world.transforms[entity]?.zPosition = topZPosition
        snapSystem.snap(entity: entity, to: target, world: world)
        addSnapFeedback(at: target.position)
        updateHUD()
        checkCompletion()
    }

    func resetGame() {
        HapticsService.shared.playNotification(.warning)
        completionOverlay?.removeFromParent()
        completionOverlay = nil
        finalPhotoNode?.removeFromParent()
        finalPhotoNode = nil
        topZPosition = 10

        for (index, entity) in world.draggables.keys.sorted().enumerated() {
            let startPosition = scatteredPosition(index: index)
            world.transforms[entity]?.position = startPosition
            world.transforms[entity]?.scale = 1.0
            world.transforms[entity]?.zPosition = 0
            world.puzzlePieces[entity]?.isSnapped = false
            world.draggables[entity]?.homePosition = startPosition
            world.draggables[entity]?.currentLoosePosition = startPosition
        }

        updateHUD()
        renderSystem.update(world: world)
    }

    func updateHUD() {
        hudCountLabel.text = "\(progressSystem.placedCount(world: world)) / \(progressSystem.totalCount(world: world))"
    }

    func checkCompletion() {
        guard progressSystem.isCompleted(world: world), completionOverlay == nil else { return }
        HapticsService.shared.playNotification(.success)
        AudioService.shared.playSystemSound(id: 1025)
        addFinalPhoto()
        addCompletionOverlay()
    }

    func addFinalPhoto() {
        let photo = SKSpriteNode(imageNamed: "final photo")
        photo.size = boardRect.size
        photo.position = CGPoint(x: boardRect.midX, y: boardRect.midY)
        photo.zPosition = 100
        photo.alpha = 0
        addChild(photo)
        photo.run(SKAction.fadeIn(withDuration: 1.0))
        finalPhotoNode = photo
    }

    func addCompletionOverlay() {
        let overlay = SKNode()
        overlay.zPosition = 102

        let shade = SKShapeNode(rectOf: CGSize(width: size.width * 1.2, height: size.height * 1.2))
        shade.fillColor = SKColor(white: 0.0, alpha: 0.60)
        shade.strokeColor = .clear
        overlay.addChild(shade)

        let panel = SKShapeNode(rectOf: CGSize(width: 300, height: 170), cornerRadius: 20)
        panel.fillColor = SKColor(red: 0.14, green: 0.16, blue: 0.22, alpha: 1.0)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        overlay.addChild(panel)

        let badge = makeLabel(text: "✓", fontSize: 42, position: CGPoint(x: 0, y: 50))
        badge.fontColor = GameConstants.Colors.snapHighlight
        overlay.addChild(badge)

        let title = makeLabel(text: "Teka-Teki Selesai!", fontSize: 22, position: CGPoint(x: 0, y: 18))
        overlay.addChild(title)

        let subtitle = makeLabel(text: "Semua 48 kepingan telah terpasang.", fontSize: 13, position: CGPoint(x: 0, y: -12))
        subtitle.fontColor = SKColor(white: 1.0, alpha: 0.75)
        overlay.addChild(subtitle)

        let resetButton = SKShapeNode(rectOf: CGSize(width: 92, height: 34), cornerRadius: 17)
        resetButton.name = "resetButton"
        resetButton.fillColor = GameConstants.Colors.snapHighlight
        resetButton.strokeColor = .clear
        resetButton.position = CGPoint(x: 0, y: -54)
        overlay.addChild(resetButton)

        let resetLabel = makeLabel(text: "Main Lagi", fontSize: 13, position: .zero)
        resetLabel.name = "resetButton"
        resetLabel.fontColor = .black
        resetButton.addChild(resetLabel)

        overlay.alpha = 0
        overlay.setScale(0.92)
        completionOverlay = overlay
        addChild(overlay)
        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.9),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
        ]))
    }

    func addSnapFeedback(at position: CGPoint) {
        HapticsService.shared.playImpact(style: .medium)
        AudioService.shared.playSystemSound(id: 1104)

        let ring = SKShapeNode(circleOfRadius: 22)
        ring.position = position
        ring.strokeColor = GameConstants.Colors.snapHighlight
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.zPosition = 80
        addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.35, duration: 0.26),
                SKAction.fadeOut(withDuration: 0.26)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func makeLabel(text: String, fontSize: CGFloat, position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = position
        return label
    }

    var effectiveSnapThreshold: CGFloat {
        max(45.0, 120.0 * boardScale)
    }
}

struct StableRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}
