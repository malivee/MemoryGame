//
//  BookScene.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import SpriteKit

final class BookScene: SKScene {

    let maximumFlipCount = 5

    var flipCount = 0
    var touchStartPoint = CGPoint.zero
    var bookNode = SKNode()
    var leftPageNode = SKNode()
    var rightPageNode = SKNode()
    var flippingPageNode: SKNode?
    var counterLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var promptLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    private var currentPagePairIndex = 0
    private let placeholderImages = ["final photo", "piece_r3_c4", "piece_r2_c3", "piece_r4_c5", "piece_r1_c2"]

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.10, green: 0.08, blue: 0.055, alpha: 1.0)
        buildScene()
    }

    func buildScene() {
        removeAllChildren()
        addDeskBackground()
        addBook()
        addHUD()
    }

    func addDeskBackground() {
        let table = SKShapeNode(rectOf: CGSize(width: size.width * 1.2, height: size.height * 1.2))
        table.fillColor = SKColor(red: 0.15, green: 0.105, blue: 0.065, alpha: 1.0)
        table.strokeColor = .clear
        table.zPosition = -30
        addChild(table)

        for index in 0..<16 {
            let plank = SKShapeNode(rectOf: CGSize(width: size.width * 1.15, height: 1.4))
            plank.fillColor = SKColor(white: 1.0, alpha: 0.045)
            plank.strokeColor = .clear
            plank.position = CGPoint(x: 0, y: -size.height / 2 + CGFloat(index) * size.height / 15)
            plank.zRotation = 0.025
            plank.zPosition = -29
            addChild(plank)
        }

        let vignette = SKShapeNode(rectOf: CGSize(width: size.width * 1.05, height: size.height * 1.05), cornerRadius: 38)
        vignette.fillColor = .clear
        vignette.strokeColor = SKColor(white: 0.0, alpha: 0.20)
        vignette.lineWidth = 42
        vignette.zPosition = -28
        addChild(vignette)
    }

    func addBook() {
        bookNode = SKNode()
        bookNode.position = CGPoint(x: 0, y: -size.height * 0.02)
        addChild(bookNode)

        let bookSize = currentBookSize()
        let pageSize = currentPageSize()

        addBookShadow(size: bookSize)
        addPageStack(size: bookSize)

        leftPageNode = makePage(size: pageSize, side: .left, pageIndex: currentPagePairIndex)
        leftPageNode.position = CGPoint(x: -pageSize.width / 2 + 2, y: 0)
        leftPageNode.zPosition = 8
        bookNode.addChild(leftPageNode)

        rightPageNode = makePage(size: pageSize, side: .right, pageIndex: currentPagePairIndex)
        rightPageNode.position = CGPoint(x: pageSize.width / 2 - 2, y: 0)
        rightPageNode.zPosition = 8
        bookNode.addChild(rightPageNode)

        addCenterFold(height: bookSize.height)
    }

    func makePage(size: CGSize, side: BookPageSide, pageIndex: Int) -> SKNode {
        let page = SKNode()

        let paper = SKShapeNode(rectOf: size, cornerRadius: 4)
        paper.fillColor = SKColor(red: 0.78, green: 0.68, blue: 0.46, alpha: 1.0)
        paper.strokeColor = SKColor(red: 0.39, green: 0.26, blue: 0.12, alpha: 0.98)
        paper.lineWidth = 1.5
        page.addChild(paper)

        addAgedPageEdges(to: page, size: size)
        addWaterStains(to: page, size: size)
        addTornCorners(to: page, size: size, side: side)
        addParchmentFlecks(to: page, size: size)
        addPageEdgeLines(to: page, size: size, side: side)
        addMedievalBorder(to: page, size: size)

        if side == .left {
            addManuscriptText(to: page, size: size, columns: 1, side: side, pageIndex: pageIndex)
            addDropCap(to: page, size: size, letter: "A")
        } else {
            addIllumination(to: page, size: size, pageIndex: pageIndex)
            addManuscriptText(to: page, size: size, columns: 2, side: side, pageIndex: pageIndex)
        }

        return page
    }

    func addBookShadow(size: CGSize) {
        let shadow = SKShapeNode(rectOf: CGSize(width: size.width + 40, height: size.height + 30), cornerRadius: 12)
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 5, y: -8)
        shadow.zPosition = 0
        bookNode.addChild(shadow)
    }

    func addPageStack(size: CGSize) {
        let cover = SKShapeNode(rectOf: CGSize(width: size.width + 30, height: size.height + 22), cornerRadius: 10)
        cover.fillColor = SKColor(red: 0.34, green: 0.19, blue: 0.10, alpha: 1.0)
        cover.strokeColor = SKColor(red: 0.55, green: 0.37, blue: 0.18, alpha: 1.0)
        cover.lineWidth = 3
        cover.zPosition = 1
        bookNode.addChild(cover)

        let brassPlate = SKShapeNode(rectOf: CGSize(width: size.width * 0.22, height: size.height * 0.075), cornerRadius: 5)
        brassPlate.fillColor = SKColor(red: 0.65, green: 0.46, blue: 0.16, alpha: 1.0)
        brassPlate.strokeColor = SKColor(red: 0.88, green: 0.68, blue: 0.27, alpha: 1.0)
        brassPlate.lineWidth = 2
        brassPlate.position = CGPoint(x: 0, y: -size.height * 0.56)
        brassPlate.zPosition = 3
        bookNode.addChild(brassPlate)

        for index in 0..<10 {
            let inset = CGFloat(index) * 2
            let stackLine = SKShapeNode(rectOf: CGSize(width: size.width + 12 - inset, height: size.height - inset), cornerRadius: 7)
            stackLine.fillColor = .clear
            stackLine.strokeColor = SKColor(red: 0.67, green: 0.57, blue: 0.39, alpha: 0.38)
            stackLine.lineWidth = 1
            stackLine.position = CGPoint(x: CGFloat(index) * 0.5, y: -CGFloat(index) * 0.7)
            stackLine.zPosition = CGFloat(2 + index)
            bookNode.addChild(stackLine)
        }
    }

    func addCenterFold(height: CGFloat) {
        let foldShadow = SKShapeNode(rectOf: CGSize(width: 20, height: height + 6), cornerRadius: 7)
        foldShadow.fillColor = SKColor(white: 0.0, alpha: 0.16)
        foldShadow.strokeColor = .clear
        foldShadow.zPosition = 12
        bookNode.addChild(foldShadow)

        let foldHighlight = SKShapeNode(rectOf: CGSize(width: 3, height: height - 18), cornerRadius: 2)
        foldHighlight.fillColor = SKColor(white: 1.0, alpha: 0.22)
        foldHighlight.strokeColor = .clear
        foldHighlight.position = CGPoint(x: -6, y: 2)
        foldHighlight.zPosition = 13
        bookNode.addChild(foldHighlight)
    }

    func addParchmentFlecks(to page: SKNode, size: CGSize) {
        for index in 0..<120 {
            let fleck = SKShapeNode(circleOfRadius: CGFloat((index % 4) + 1) * 0.5)
            fleck.fillColor = SKColor(red: 0.30, green: 0.19, blue: 0.08, alpha: 0.16)
            fleck.strokeColor = .clear
            let xSeed = CGFloat((index * 37) % 100) / 100
            let ySeed = CGFloat((index * 61) % 100) / 100
            fleck.position = CGPoint(
                x: -size.width * 0.45 + xSeed * size.width * 0.9,
                y: -size.height * 0.43 + ySeed * size.height * 0.86
            )
            fleck.zPosition = 1
            page.addChild(fleck)
        }
    }

    func addAgedPageEdges(to page: SKNode, size: CGSize) {
        let topBurnish = SKShapeNode(rectOf: CGSize(width: size.width * 0.94, height: size.height * 0.075), cornerRadius: 10)
        topBurnish.fillColor = SKColor(red: 0.31, green: 0.19, blue: 0.08, alpha: 0.26)
        topBurnish.strokeColor = .clear
        topBurnish.position = CGPoint(x: 0, y: size.height * 0.455)
        topBurnish.zPosition = 2
        page.addChild(topBurnish)

        let bottomBurnish = topBurnish.copy() as? SKShapeNode
        bottomBurnish?.position = CGPoint(x: 0, y: -size.height * 0.455)
        if let bottomBurnish {
            page.addChild(bottomBurnish)
        }

        for index in 0..<30 {
            let nib = SKShapeNode(circleOfRadius: CGFloat(2 + (index % 5)))
            nib.fillColor = SKColor(red: 0.23, green: 0.13, blue: 0.05, alpha: 0.22)
            nib.strokeColor = .clear
            let x = -size.width * 0.45 + CGFloat(index) * size.width * 0.031
            let y = index % 2 == 0 ? size.height * 0.46 : -size.height * 0.46
            nib.position = CGPoint(x: x, y: y)
            nib.zPosition = 3
            page.addChild(nib)
        }
    }

    func addWaterStains(to page: SKNode, size: CGSize) {
        let stainSeeds = [
            CGPoint(x: -0.30, y: -0.24),
            CGPoint(x: 0.25, y: 0.14),
            CGPoint(x: 0.34, y: -0.34),
            CGPoint(x: -0.12, y: 0.36)
        ]

        for (index, seed) in stainSeeds.enumerated() {
            let stainSize = CGSize(
                width: size.width * (0.12 + CGFloat(index % 2) * 0.05),
                height: size.height * (0.08 + CGFloat(index % 3) * 0.025)
            )
            let stain = SKShapeNode(ellipseOf: stainSize)
            stain.fillColor = SKColor(red: 0.25, green: 0.14, blue: 0.045, alpha: 0.13)
            stain.strokeColor = SKColor(red: 0.25, green: 0.14, blue: 0.045, alpha: 0.08)
            stain.lineWidth = 4
            stain.position = CGPoint(x: seed.x * size.width, y: seed.y * size.height)
            stain.zRotation = CGFloat(index) * 0.45
            stain.zPosition = 2.5
            page.addChild(stain)
        }
    }

    func addTornCorners(to page: SKNode, size: CGSize, side: BookPageSide) {
        let corners = [
            CGPoint(x: -size.width * 0.47, y: size.height * 0.45),
            CGPoint(x: size.width * 0.47, y: size.height * 0.45),
            CGPoint(x: -size.width * 0.47, y: -size.height * 0.45),
            CGPoint(x: size.width * 0.47, y: -size.height * 0.45)
        ]

        for (index, corner) in corners.enumerated() {
            let bite = SKShapeNode(circleOfRadius: size.width * (index % 2 == 0 ? 0.025 : 0.018))
            bite.fillColor = SKColor(red: 0.15, green: 0.105, blue: 0.065, alpha: 1.0)
            bite.strokeColor = .clear
            bite.position = CGPoint(
                x: corner.x + CGFloat((index + (side == .left ? 1 : 0)) % 2) * 3,
                y: corner.y - CGFloat(index % 2) * 4
            )
            bite.zPosition = 9
            page.addChild(bite)
        }

        for index in 0..<10 {
            let tear = SKShapeNode(rectOf: CGSize(width: size.width * 0.035, height: 1.2))
            tear.fillColor = SKColor(red: 0.34, green: 0.21, blue: 0.08, alpha: 0.22)
            tear.strokeColor = .clear
            tear.position = CGPoint(
                x: (side == .left ? -size.width * 0.455 : size.width * 0.455),
                y: -size.height * 0.35 + CGFloat(index) * size.height * 0.075
            )
            tear.zRotation = CGFloat(index % 3) * 0.18
            tear.zPosition = 4
            page.addChild(tear)
        }
    }

    func addPageEdgeLines(to page: SKNode, size: CGSize, side: BookPageSide) {
        let edgeX = side == .left ? -size.width * 0.48 : size.width * 0.48
        for index in 0..<12 {
            let line = SKShapeNode(rectOf: CGSize(width: 1, height: size.height * 0.90))
            line.fillColor = SKColor(red: 0.47, green: 0.36, blue: 0.20, alpha: 0.12)
            line.strokeColor = .clear
            line.position = CGPoint(x: edgeX - CGFloat(index) * (side == .left ? -1.2 : 1.2), y: 0)
            line.zPosition = 2
            page.addChild(line)
        }
    }

    func addMedievalBorder(to page: SKNode, size: CGSize) {
        let border = SKShapeNode(rectOf: CGSize(width: size.width * 0.86, height: size.height * 0.84), cornerRadius: 2)
        border.fillColor = .clear
        border.strokeColor = SKColor(red: 0.58, green: 0.05, blue: 0.035, alpha: 0.72)
        border.lineWidth = 1.6
        border.zPosition = 4
        page.addChild(border)

        let inset = SKShapeNode(rectOf: CGSize(width: size.width * 0.81, height: size.height * 0.79), cornerRadius: 2)
        inset.fillColor = .clear
        inset.strokeColor = SKColor(red: 0.82, green: 0.60, blue: 0.18, alpha: 0.64)
        inset.lineWidth = 1.1
        inset.zPosition = 4
        page.addChild(inset)

        let cornerPositions = [
            CGPoint(x: -size.width * 0.39, y: size.height * 0.38),
            CGPoint(x: size.width * 0.39, y: size.height * 0.38),
            CGPoint(x: -size.width * 0.39, y: -size.height * 0.38),
            CGPoint(x: size.width * 0.39, y: -size.height * 0.38)
        ]

        for (index, position) in cornerPositions.enumerated() {
            let ornament = makeCornerOrnament(radius: size.width * 0.026)
            ornament.position = position
            ornament.zRotation = CGFloat(index) * .pi / 2
            ornament.zPosition = 5
            page.addChild(ornament)
        }
    }

    func makeCornerOrnament(radius: CGFloat) -> SKNode {
        let ornament = SKNode()
        let colors = [
            SKColor(red: 0.56, green: 0.04, blue: 0.03, alpha: 0.95),
            SKColor(red: 0.05, green: 0.18, blue: 0.44, alpha: 0.95),
            SKColor(red: 0.82, green: 0.61, blue: 0.18, alpha: 0.95)
        ]

        for index in 0..<3 {
            let petal = SKShapeNode(ellipseOf: CGSize(width: radius * 1.8, height: radius * 0.8))
            petal.fillColor = colors[index]
            petal.strokeColor = SKColor(red: 0.22, green: 0.12, blue: 0.05, alpha: 0.45)
            petal.lineWidth = 0.6
            petal.position = CGPoint(x: cos(CGFloat(index) * 2.1) * radius, y: sin(CGFloat(index) * 2.1) * radius)
            petal.zRotation = CGFloat(index) * 2.1
            ornament.addChild(petal)
        }

        return ornament
    }

    func addManuscriptText(to page: SKNode, size: CGSize, columns: Int, side: BookPageSide, pageIndex: Int) {
        let inkColors = [
            SKColor(red: 0.12, green: 0.08, blue: 0.045, alpha: 0.78),
            SKColor(red: 0.45, green: 0.04, blue: 0.035, alpha: 0.85),
            SKColor(red: 0.05, green: 0.18, blue: 0.42, alpha: 0.78)
        ]
        let topY = size.height * 0.34
        let lineSpacing = size.height * 0.055
        let columnWidth = columns == 1 ? size.width * 0.62 : size.width * 0.29

        for column in 0..<columns {
            let columnCenter = columns == 1 ? CGFloat.zero : (column == 0 ? -size.width * 0.19 : size.width * 0.20)
            let start = side == .left && column == 0 ? 2 : 0

            for row in start..<11 {
                let path = CGMutablePath()
                let widthNoise = CGFloat(((row + column + pageIndex) * 17) % 9) / 100
                let lineWidth = columnWidth * (0.78 + widthNoise)
                let startX = columnCenter - lineWidth / 2
                let y = topY - CGFloat(row) * lineSpacing
                path.move(to: CGPoint(x: startX, y: y))

                for step in 1...16 {
                    let x = startX + CGFloat(step) * lineWidth / 16
                    let wave = sin(CGFloat(step + row + pageIndex) * 1.15) * 1.6
                    path.addLine(to: CGPoint(x: x, y: y + wave))
                }

                let scribble = SKShapeNode(path: path)
                scribble.strokeColor = inkColors[(row + column + pageIndex) % inkColors.count]
                scribble.lineWidth = row % 5 == 0 ? 1.7 : 1.2
                scribble.lineCap = .round
                scribble.lineJoin = .round
                scribble.zPosition = 6
                page.addChild(scribble)
            }
        }
    }

    func addDropCap(to page: SKNode, size: CGSize, letter: String) {
        let capBack = SKShapeNode(rectOf: CGSize(width: size.width * 0.16, height: size.height * 0.18), cornerRadius: 2)
        capBack.fillColor = SKColor(red: 0.55, green: 0.08, blue: 0.04, alpha: 0.95)
        capBack.strokeColor = SKColor(red: 0.84, green: 0.66, blue: 0.24, alpha: 1.0)
        capBack.lineWidth = 2
        capBack.position = CGPoint(x: -size.width * 0.31, y: size.height * 0.28)
        capBack.zPosition = 5
        page.addChild(capBack)

        let cap = SKLabelNode(fontNamed: "TimesNewRomanPS-BoldMT")
        cap.text = letter
        cap.fontSize = min(size.width, size.height) * 0.13
        cap.fontColor = SKColor(red: 0.93, green: 0.80, blue: 0.40, alpha: 1.0)
        cap.verticalAlignmentMode = .center
        cap.horizontalAlignmentMode = .center
        cap.position = capBack.position
        cap.zPosition = 7
        page.addChild(cap)

        let jewel = SKShapeNode(circleOfRadius: size.width * 0.018)
        jewel.fillColor = SKColor(red: 0.06, green: 0.20, blue: 0.55, alpha: 1.0)
        jewel.strokeColor = SKColor(red: 0.88, green: 0.68, blue: 0.26, alpha: 1.0)
        jewel.lineWidth = 1
        jewel.position = CGPoint(x: capBack.position.x + size.width * 0.06, y: capBack.position.y + size.height * 0.055)
        jewel.zPosition = 8
        page.addChild(jewel)
    }

    func addIllumination(to page: SKNode, size: CGSize, pageIndex: Int) {
        let frameSize = CGSize(width: size.width * 0.38, height: size.height * 0.36)
        let framePosition = CGPoint(x: -size.width * 0.13, y: size.height * 0.22)

        let outerFrame = SKShapeNode(rectOf: frameSize, cornerRadius: 3)
        outerFrame.fillColor = SKColor(red: 0.52, green: 0.06, blue: 0.035, alpha: 0.96)
        outerFrame.strokeColor = SKColor(red: 0.88, green: 0.68, blue: 0.26, alpha: 1.0)
        outerFrame.lineWidth = 3
        outerFrame.position = framePosition
        outerFrame.zPosition = 5
        page.addChild(outerFrame)

        let imageName = placeholderImages[pageIndex % placeholderImages.count]
        let image = SKSpriteNode(imageNamed: imageName)
        image.size = CGSize(width: frameSize.width * 0.78, height: frameSize.height * 0.72)
        image.position = framePosition
        image.alpha = 0.72
        image.zPosition = 6
        page.addChild(image)

        addDecorativeHalo(to: page, center: framePosition, radius: min(frameSize.width, frameSize.height) * 0.30)
        addGoldLeafDots(to: page, around: framePosition, frameSize: frameSize)
    }

    func addGoldLeafDots(to page: SKNode, around center: CGPoint, frameSize: CGSize) {
        for index in 0..<12 {
            let dot = SKShapeNode(circleOfRadius: 1.7)
            dot.fillColor = SKColor(red: 0.95, green: 0.72, blue: 0.22, alpha: 0.9)
            dot.strokeColor = .clear
            let xSide: CGFloat = index % 2 == 0 ? -1 : 1
            let yOffset = -frameSize.height * 0.42 + CGFloat(index / 2) * frameSize.height * 0.16
            dot.position = CGPoint(x: center.x + xSide * frameSize.width * 0.47, y: center.y + yOffset)
            dot.zPosition = 8
            page.addChild(dot)
        }
    }

    func addDecorativeHalo(to page: SKNode, center: CGPoint, radius: CGFloat) {
        let halo = SKShapeNode(circleOfRadius: radius)
        halo.fillColor = .clear
        halo.strokeColor = SKColor(red: 0.08, green: 0.20, blue: 0.48, alpha: 0.72)
        halo.lineWidth = 3
        halo.position = center
        halo.zPosition = 7
        page.addChild(halo)

        let divider = SKShapeNode(rectOf: CGSize(width: radius * 0.12, height: radius * 1.75), cornerRadius: 2)
        divider.fillColor = SKColor(red: 0.82, green: 0.58, blue: 0.18, alpha: 0.85)
        divider.strokeColor = .clear
        divider.position = center
        divider.zRotation = -0.35
        divider.zPosition = 8
        page.addChild(divider)
    }

    func addHUD() {
        let title = makeLabel(text: "Manuscript", fontSize: 20, position: CGPoint(x: -size.width * 0.42, y: size.height * 0.42))
        title.horizontalAlignmentMode = .left
        title.fontColor = SKColor(red: 0.92, green: 0.82, blue: 0.58, alpha: 0.90)
        addChild(title)

        counterLabel = makeLabel(text: "0 / 5", fontSize: 18, position: CGPoint(x: size.width * 0.40, y: size.height * 0.42))
        counterLabel.fontColor = SKColor(red: 0.92, green: 0.82, blue: 0.58, alpha: 0.90)
        addChild(counterLabel)

        promptLabel = makeLabel(text: "Tap or swipe either page", fontSize: 15, position: CGPoint(x: 0, y: -size.height * 0.42))
        promptLabel.fontColor = SKColor(red: 0.92, green: 0.82, blue: 0.58, alpha: 0.72)
        addChild(promptLabel)
    }

    func flipPageUp() {
        guard flipCount < maximumFlipCount, flippingPageNode == nil else { return }

        flipCount += 1
        currentPagePairIndex += 1
        counterLabel.text = "\(flipCount) / \(maximumFlipCount)"
        HapticsService.shared.playSelection()

        let pageSize = currentPageSize()
        let flipPage = makePage(size: pageSize, side: .right, pageIndex: currentPagePairIndex)
        flipPage.position = rightPageNode.position
        flipPage.zPosition = 20
        flipPage.setScale(1.0)
        addFlipCurlEffects(to: flipPage, direction: .forward, pageSize: pageSize)
        bookNode.addChild(flipPage)
        flippingPageNode = flipPage

        let lift = SKAction.group([
            eased(SKAction.moveBy(x: -pageSize.width * 0.22, y: pageSize.height * 0.10, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleX(to: 0.72, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleY(to: 1.025, duration: 0.18), mode: .easeOut),
            eased(SKAction.rotate(byAngle: -0.10, duration: 0.18), mode: .easeOut)
        ])

        let curlOverSpine = SKAction.group([
            eased(SKAction.moveBy(x: -pageSize.width * 0.34, y: pageSize.height * 0.08, duration: 0.16)),
            eased(SKAction.scaleX(to: 0.08, duration: 0.16)),
            eased(SKAction.scaleY(to: 1.06, duration: 0.16)),
            eased(SKAction.rotate(toAngle: -0.22, duration: 0.16))
        ])

        let unfurl = SKAction.group([
            eased(SKAction.moveBy(x: -pageSize.width * 0.36, y: -pageSize.height * 0.15, duration: 0.20)),
            eased(SKAction.scaleX(to: 0.72, duration: 0.20), mode: .easeOut),
            eased(SKAction.scaleY(to: 1.025, duration: 0.20), mode: .easeOut),
            eased(SKAction.rotate(toAngle: 0.10, duration: 0.20), mode: .easeOut)
        ])

        let settle = SKAction.group([
            eased(SKAction.move(to: leftPageNode.position, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleX(to: 1.0, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleY(to: 1.0, duration: 0.18), mode: .easeOut),
            eased(SKAction.rotate(toAngle: 0, duration: 0.18), mode: .easeOut)
        ])

        flipPage.run(SKAction.sequence([
            lift,
            curlOverSpine,
            unfurl,
            settle,
            SKAction.run { [weak self, weak flipPage] in
                guard let self, let flipPage else { return }
                self.leftPageNode.removeFromParent()
                self.leftPageNode = flipPage
                self.flippingPageNode = nil
                self.refreshRightPage()
                if self.flipCount == self.maximumFlipCount {
                    self.promptLabel.text = "All five pages flipped"
                    self.promptLabel.fontColor = SKColor(red: 0.93, green: 0.67, blue: 0.22, alpha: 1.0)
                }
            }
        ]))
    }

    func flipPageBack() {
        guard flipCount > 0, flippingPageNode == nil else {
            promptLabel.text = "This is the first page"
            return
        }

        flipCount -= 1
        currentPagePairIndex = max(0, currentPagePairIndex - 1)
        counterLabel.text = "\(flipCount) / \(maximumFlipCount)"
        promptLabel.text = "Tap or swipe either page"
        promptLabel.fontColor = SKColor(red: 0.92, green: 0.82, blue: 0.58, alpha: 0.72)
        HapticsService.shared.playSelection()

        let pageSize = currentPageSize()
        let flipPage = makePage(size: pageSize, side: .left, pageIndex: currentPagePairIndex)
        flipPage.position = leftPageNode.position
        flipPage.zPosition = 20
        flipPage.setScale(1.0)
        addFlipCurlEffects(to: flipPage, direction: .backward, pageSize: pageSize)
        bookNode.addChild(flipPage)
        flippingPageNode = flipPage

        let lift = SKAction.group([
            eased(SKAction.moveBy(x: pageSize.width * 0.22, y: pageSize.height * 0.10, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleX(to: 0.72, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleY(to: 1.025, duration: 0.18), mode: .easeOut),
            eased(SKAction.rotate(byAngle: 0.10, duration: 0.18), mode: .easeOut)
        ])

        let curlOverSpine = SKAction.group([
            eased(SKAction.moveBy(x: pageSize.width * 0.34, y: pageSize.height * 0.08, duration: 0.16)),
            eased(SKAction.scaleX(to: 0.08, duration: 0.16)),
            eased(SKAction.scaleY(to: 1.06, duration: 0.16)),
            eased(SKAction.rotate(toAngle: 0.22, duration: 0.16))
        ])

        let unfurl = SKAction.group([
            eased(SKAction.moveBy(x: pageSize.width * 0.36, y: -pageSize.height * 0.15, duration: 0.20)),
            eased(SKAction.scaleX(to: 0.72, duration: 0.20), mode: .easeOut),
            eased(SKAction.scaleY(to: 1.025, duration: 0.20), mode: .easeOut),
            eased(SKAction.rotate(toAngle: -0.10, duration: 0.20), mode: .easeOut)
        ])

        let settle = SKAction.group([
            eased(SKAction.move(to: rightPageNode.position, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleX(to: 1.0, duration: 0.18), mode: .easeOut),
            eased(SKAction.scaleY(to: 1.0, duration: 0.18), mode: .easeOut),
            eased(SKAction.rotate(toAngle: 0, duration: 0.18), mode: .easeOut)
        ])

        flipPage.run(SKAction.sequence([
            lift,
            curlOverSpine,
            unfurl,
            settle,
            SKAction.run { [weak self, weak flipPage] in
                guard let self, let flipPage else { return }
                self.rightPageNode.removeFromParent()
                self.rightPageNode = flipPage
                self.flippingPageNode = nil
                self.refreshLeftPage()
            }
        ]))
    }

    func addFlipCurlEffects(to page: SKNode, direction: BookFlipDirection, pageSize: CGSize) {
        let leadingX = direction == .forward ? -pageSize.width * 0.42 : pageSize.width * 0.42
        let trailingX = direction == .forward ? pageSize.width * 0.34 : -pageSize.width * 0.34

        let foldShade = SKShapeNode(rectOf: CGSize(width: pageSize.width * 0.10, height: pageSize.height * 0.95), cornerRadius: 8)
        foldShade.fillColor = SKColor(white: 0.0, alpha: 0.12)
        foldShade.strokeColor = .clear
        foldShade.position = CGPoint(x: leadingX, y: 0)
        foldShade.zPosition = 18
        page.addChild(foldShade)

        let liftedEdge = SKShapeNode(rectOf: CGSize(width: pageSize.width * 0.055, height: pageSize.height * 0.92), cornerRadius: 8)
        liftedEdge.fillColor = SKColor(red: 0.95, green: 0.86, blue: 0.60, alpha: 0.28)
        liftedEdge.strokeColor = .clear
        liftedEdge.position = CGPoint(x: trailingX, y: 0)
        liftedEdge.zPosition = 19
        page.addChild(liftedEdge)

        let curlLine = SKShapeNode(rectOf: CGSize(width: 1.4, height: pageSize.height * 0.88), cornerRadius: 1)
        curlLine.fillColor = SKColor(red: 0.26, green: 0.15, blue: 0.055, alpha: 0.28)
        curlLine.strokeColor = .clear
        curlLine.position = CGPoint(x: trailingX * 0.82, y: 0)
        curlLine.zPosition = 20
        page.addChild(curlLine)

        let fadeOut = eased(SKAction.fadeAlpha(to: 0.0, duration: 0.62), mode: .easeIn)
        foldShade.run(fadeOut)
        liftedEdge.run(fadeOut.copy() as? SKAction ?? SKAction.fadeOut(withDuration: 0.62))
        curlLine.run(fadeOut.copy() as? SKAction ?? SKAction.fadeOut(withDuration: 0.62))
    }

    func eased(_ action: SKAction, mode: SKActionTimingMode = .easeInEaseOut) -> SKAction {
        action.timingMode = mode
        return action
    }

    func refreshLeftPage() {
        leftPageNode.removeFromParent()
        let pageSize = currentPageSize()
        leftPageNode = makePage(size: pageSize, side: .left, pageIndex: currentPagePairIndex)
        leftPageNode.position = CGPoint(x: -pageSize.width / 2 + 2, y: 0)
        leftPageNode.zPosition = 8
        bookNode.addChild(leftPageNode)
    }

    func refreshRightPage() {
        rightPageNode.removeFromParent()
        let pageSize = currentPageSize()
        rightPageNode = makePage(size: pageSize, side: .right, pageIndex: currentPagePairIndex)
        rightPageNode.position = CGPoint(x: pageSize.width / 2 - 2, y: 0)
        rightPageNode.zPosition = 8
        bookNode.addChild(rightPageNode)
    }

    func currentBookSize() -> CGSize {
        CGSize(width: min(size.width * 0.74, 760), height: min(size.height * 0.66, 390))
    }

    func currentPageSize() -> CGSize {
        let bookSize = currentBookSize()
        return CGSize(width: bookSize.width * 0.48, height: bookSize.height)
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
}

enum BookPageSide {
    case left
    case right
}

enum BookFlipDirection {
    case forward
    case backward
}
