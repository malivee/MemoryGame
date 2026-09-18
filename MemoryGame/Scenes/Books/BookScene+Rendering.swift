import SpriteKit
import UIKit

// Rendering adapter. Gameplay rules live in Models and Systems.
extension BookScene {
    func buildScene() {
        removeAllChildren()
        bookNode.removeAllChildren()
        trackedTouch = nil
        touchStartPoint = nil
        addChild(bookNode)
        bookNode.position = CGPoint(x: 0, y: 2)
        addBinding()
        refreshPages()
        addGutter()
        addHUD()
    }

    func currentBookSize() -> CGSize {
        let safe = view?.safeAreaInsets ?? .zero
        let width = min(size.width - safe.left - safe.right - 52, 1050)
        let height = min(size.height - safe.top - safe.bottom - 84, width / 1.88)
        return CGSize(width: max(100, height * 1.88), height: max(60, height))
    }

    func containsBookPoint(_ point: CGPoint) -> Bool {
        let book = currentBookSize()
        return CGRect(x: bookNode.position.x - book.width / 2,
                      y: bookNode.position.y - book.height / 2,
                      width: book.width, height: book.height).contains(point)
    }

    func pageTexture(side: BookPageSide, spread: Int) -> SKTexture {
        journalArtwork.texture(side: side, spread: spread)
    }

    func makePage(side: BookPageSide, spread: Int) -> SKSpriteNode {
        let page = SKSpriteNode(texture: pageTexture(side: side, spread: spread), size: pageSize)
        page.anchorPoint = CGPoint(x: 0, y: 0.5)
        page.position = .zero
        page.zPosition = 10
        page.subdivisionLevels = 2
        page.warpGeometry = PaperTurnGeometry.grid(progress: 0, direction: side == .right ? .forward : .backward)
        return page
    }

    func refreshPages() {
        leftPageNode.removeFromParent()
        rightPageNode.removeFromParent()
        leftPageNode = makePage(side: .left, spread: flipCount)
        rightPageNode = makePage(side: .right, spread: flipCount)
        bookNode.addChild(leftPageNode)
        bookNode.addChild(rightPageNode)
    }

    func addBinding() {
        let book = currentBookSize()
        for layer in (0..<12).reversed() {
            let shadow = SKShapeNode(rectOf: CGSize(width: book.width + CGFloat(layer) * 4,
                                                   height: book.height + CGFloat(layer) * 2.8), cornerRadius: 12)
            shadow.fillColor = SKColor(white: 0, alpha: 0.018)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -10 - CGFloat(layer) * 0.6)
            shadow.zPosition = -5
            bookNode.addChild(shadow)
        }
        let cover = SKShapeNode(rectOf: CGSize(width: book.width + 28, height: book.height + 15), cornerRadius: 10)
        cover.fillColor = SKColor(red: 0.24, green: 0.18, blue: 0.10, alpha: 1)
        cover.strokeColor = SKColor(red: 0.43, green: 0.34, blue: 0.19, alpha: 1)
        cover.lineWidth = 2
        cover.position.y = -5
        bookNode.addChild(cover)

        for layer in (1...12).reversed() {
            for side in [BookPageSide.left, .right] {
                let page = makePage(side: side, spread: 0)
                page.position = CGPoint(x: (side == .left ? -1 : 1) * CGFloat(layer) * 0.9,
                                        y: -CGFloat(layer) * 0.5)
                page.color = SKColor(red: 0.48, green: 0.40, blue: 0.23, alpha: 1)
                page.colorBlendFactor = layer % 3 == 0 ? 0.50 : 0.28
                page.zPosition = 1 + CGFloat(12 - layer) * 0.1
                bookNode.addChild(page)
            }
        }
    }

    func addGutter() {
        // Many translucent narrow strips give a soft fold without hard outlines.
        for index in 0..<24 {
            let distance = CGFloat(index) / 24
            let strip = SKSpriteNode(color: SKColor(red: 0.17, green: 0.12, blue: 0.055,
                                                   alpha: 0.025 + 0.20 * pow(1 - distance, 2)),
                                     size: CGSize(width: pageSize.width * 0.007 + 0.5, height: pageSize.height))
            for sign: CGFloat in [-1, 1] {
                let node = strip.copy() as! SKSpriteNode
                node.position.x = sign * distance * pageSize.width * 0.16
                node.zPosition = 12
                bookNode.addChild(node)
            }
        }
    }

    func addHUD() {
        let bottom = -size.height / 2 + max(18, view?.safeAreaInsets.bottom ?? 0) + 5
        counterLabel.fontSize = 11
        counterLabel.fontColor = SKColor(red: 0.77, green: 0.72, blue: 0.59, alpha: 0.8)
        counterLabel.position = CGPoint(x: 0, y: size.height / 2 - max(24, view?.safeAreaInsets.top ?? 0) - 3)
        counterLabel.verticalAlignmentMode = .center
        addChild(counterLabel)
        promptLabel.fontSize = 11
        promptLabel.fontColor = SKColor(red: 0.77, green: 0.72, blue: 0.59, alpha: 0.65)
        promptLabel.position = CGPoint(x: 0, y: bottom)
        promptLabel.verticalAlignmentMode = .center
        addChild(promptLabel)
        if onClose != nil {
            addCloseButton()
        }
        updateHUD()
    }

    func addCloseButton() {
        let safe = view?.safeAreaInsets ?? .zero
        let button = SKShapeNode(rectOf: CGSize(width: 104, height: 44), cornerRadius: 10)
        button.name = closeButtonName
        button.position = CGPoint(x: -size.width / 2 + safe.left + 70, y: size.height / 2 - max(36, safe.top + 18))
        button.fillColor = SKColor(red: 0.17, green: 0.12, blue: 0.07, alpha: 0.88)
        button.strokeColor = SKColor(red: 0.72, green: 0.57, blue: 0.28, alpha: 0.68)
        button.lineWidth = 1.2
        button.zPosition = 200
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.name = closeButtonName
        label.text = "‹ Back"
        label.fontSize = 12
        label.fontColor = SKColor(red: 0.86, green: 0.78, blue: 0.58, alpha: 1)
        label.verticalAlignmentMode = .center
        button.addChild(label)
        addChild(button)
    }

    func updateHUD() {
        counterLabel.text = "JOURNAL   ·   \(flipCount + 1) / \(maximumFlipCount + 1)"
        promptLabel.text = flipCount == maximumFlipCount
            ? "Last leaf · Tap the left page to return"
            : "Tap a page or swipe to turn"
    }
}
