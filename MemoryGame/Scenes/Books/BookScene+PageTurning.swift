import SpriteKit
import UIKit

// PageTurning adapter. Gameplay rules live in Models and Systems.
extension BookScene {
    func flipPageUp() { beginTurn(.forward) }

    func flipPageBack() { beginTurn(.backward) }

    func beginTurn(_ direction: BookFlipDirection) {
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

    func finishTurn() {
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
