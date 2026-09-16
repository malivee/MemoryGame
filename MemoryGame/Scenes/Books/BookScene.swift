import SpriteKit

/// A bound manuscript. Page artwork is kept separate from the binding so each
/// leaf can bend around the gutter without moving the rest of the book.
final class BookScene: SKScene {
    let maximumFlipCount = 5
    var onClose: (() -> Void)?
    private(set) var flipCount = 0
    var touchStartPoint: CGPoint?
    var trackedTouch: UITouch?
    let bookNode = SKNode()
    private var leftPageNode = SKSpriteNode()
    private var rightPageNode = SKSpriteNode()
    private var turningPage: SKSpriteNode?
    private var turnShadow: SKSpriteNode?
    private var turnDirection: BookFlipDirection?
    private var turnStartTime: TimeInterval?
    private let turnDuration: TimeInterval = 1.15
    private let counterLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let promptLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let closeButtonName = "bookClose"
    private lazy var pageAtlas = SKTexture(imageNamed: "ManuscriptPages")
    private let turnAmount = SKUniform(name: "u_turn", float: 0)
    private lazy var paperShader = SKShader(source: """
        void main() {
            vec4 paper = SKDefaultShading();
            float lift = sin(u_turn * 3.14159265);
            float across = v_tex_coord.x;
            float roll = 0.5 + 0.5 * cos(across * 3.14159265);
            float light = 1.0 - lift * (0.12 + 0.22 * roll);
            gl_FragColor = vec4(paper.rgb * light, paper.a);
        }
        """, uniforms: [turnAmount])

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.075, green: 0.065, blue: 0.05, alpha: 1)
        buildScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        // Finish the logical turn before rebuilding for a new viewport.
        finishTurn()
        buildScene()
    }

    private func buildScene() {
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

    private var pageSize: CGSize {
        let book = currentBookSize()
        return CGSize(width: book.width / 2, height: book.height)
    }

    func containsBookPoint(_ point: CGPoint) -> Bool {
        let book = currentBookSize()
        return CGRect(x: bookNode.position.x - book.width / 2,
                      y: bookNode.position.y - book.height / 2,
                      width: book.width, height: book.height).contains(point)
    }

    private func pageTexture(side: BookPageSide, spread: Int) -> SKTexture {
        // Alternate text and illumination across the existing five spreads.
        let illustrated = (side == .right) != (spread % 2 == 1)
        let texture = SKTexture(rect: CGRect(x: illustrated ? 0.5 : 0, y: 0, width: 0.5, height: 1), in: pageAtlas)
        texture.filteringMode = .linear
        return texture
    }

    private func makePage(side: BookPageSide, spread: Int) -> SKSpriteNode {
        let page = SKSpriteNode(texture: pageTexture(side: side, spread: spread), size: pageSize)
        page.anchorPoint = CGPoint(x: 0, y: 0.5)
        page.position = .zero
        page.zPosition = 10
        page.subdivisionLevels = 2
        page.warpGeometry = PaperTurnGeometry.grid(progress: 0, direction: side == .right ? .forward : .backward)
        return page
    }

    private func refreshPages() {
        leftPageNode.removeFromParent()
        rightPageNode.removeFromParent()
        leftPageNode = makePage(side: .left, spread: flipCount)
        rightPageNode = makePage(side: .right, spread: flipCount)
        bookNode.addChild(leftPageNode)
        bookNode.addChild(rightPageNode)
    }

    private func addBinding() {
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

    private func addGutter() {
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

    private func addHUD() {
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

    private func addCloseButton() {
        let safe = view?.safeAreaInsets ?? .zero
        let button = SKShapeNode(rectOf: CGSize(width: 94, height: 34), cornerRadius: 10)
        button.name = closeButtonName
        button.position = CGPoint(x: -size.width / 2 + safe.left + 70, y: size.height / 2 - max(36, safe.top + 18))
        button.fillColor = SKColor(red: 0.17, green: 0.12, blue: 0.07, alpha: 0.88)
        button.strokeColor = SKColor(red: 0.72, green: 0.57, blue: 0.28, alpha: 0.68)
        button.lineWidth = 1.2
        button.zPosition = 200
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.name = closeButtonName
        label.text = "Kembali"
        label.fontSize = 12
        label.fontColor = SKColor(red: 0.86, green: 0.78, blue: 0.58, alpha: 1)
        label.verticalAlignmentMode = .center
        button.addChild(label)
        addChild(button)
    }

    func closeBookIfNeeded(at point: CGPoint) -> Bool {
        guard onClose != nil else { return false }
        let tappedClose = nodes(at: point).contains { node in
            var current: SKNode? = node
            while let inspected = current {
                if inspected.name == closeButtonName { return true }
                current = inspected.parent
            }
            return false
        }
        if tappedClose {
            onClose?()
        }
        return tappedClose
    }

    private func updateHUD() {
        counterLabel.text = "MANUSCRIPT   ·   \(flipCount) / \(maximumFlipCount)"
        promptLabel.text = flipCount == maximumFlipCount
            ? "Last leaf · Tap the left page to return"
            : "Tap a page or swipe to turn"
    }

    func flipPageUp() { beginTurn(.forward) }
    func flipPageBack() { beginTurn(.backward) }

    private func beginTurn(_ direction: BookFlipDirection) {
        guard turningPage == nil else { return }
        let next = flipCount + (direction == .forward ? 1 : -1)
        guard (0...maximumFlipCount).contains(next) else { return }
        HapticsService.shared.playSelection()
        let side: BookPageSide = direction == .forward ? .right : .left
        let page = makePage(side: side, spread: flipCount)
        page.zPosition = 30
        page.shader = paperShader
        turningPage = page
        turnDirection = direction
        turnStartTime = nil
        bookNode.addChild(page)
        // The next leaf is already underneath the moving sheet.
        let revealed = direction == .forward ? rightPageNode : leftPageNode
        revealed.texture = pageTexture(side: side, spread: next)
        let shadow = SKSpriteNode(color: .black, size: pageSize)
        shadow.anchorPoint = CGPoint(x: 0, y: 0.5)
        shadow.zPosition = 20
        shadow.alpha = 0
        bookNode.addChild(shadow)
        turnShadow = shadow
    }

    override func update(_ currentTime: TimeInterval) {
        guard let page = turningPage, let direction = turnDirection else { return }
        if turnStartTime == nil { turnStartTime = currentTime }
        let elapsed = currentTime - (turnStartTime ?? currentTime)
        let linear = min(1, max(0, elapsed / turnDuration))
        // Gentle lift, a quicker crossing, then a slow paper settling phase.
        let progress = CGFloat(linear * linear * (3 - 2 * linear))
        let next = flipCount + (direction == .forward ? 1 : -1)
        let showingBack = progress >= 0.5
        let side: BookPageSide = (direction == .forward) != showingBack ? .right : .left
        page.texture = pageTexture(side: side, spread: showingBack ? next : flipCount)
        page.warpGeometry = PaperTurnGeometry.grid(progress: progress, direction: direction)
        turnAmount.floatValue = Float(progress)
        turnShadow?.warpGeometry = PaperTurnGeometry.grid(progress: progress, direction: direction, shadow: true)
        turnShadow?.alpha = 0.19 * sin(progress * .pi)
        if linear >= 1 { finishTurn() }
    }

    private func finishTurn() {
        guard let direction = turnDirection else { return }
        flipCount += direction == .forward ? 1 : -1
        turningPage?.removeFromParent()
        turnShadow?.removeFromParent()
        turningPage = nil
        turnShadow = nil
        turnDirection = nil
        turnStartTime = nil
        refreshPages()
        updateHUD()
    }
}

enum BookPageSide { case left, right }
enum BookFlipDirection { case forward, backward }
