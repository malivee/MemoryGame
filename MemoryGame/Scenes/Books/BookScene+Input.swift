//
//  BookScene+Input.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import SpriteKit

extension BookScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStartPoint = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let endPoint = touch.location(in: self)
        let deltaY = endPoint.y - touchStartPoint.y
        let deltaX = endPoint.x - touchStartPoint.x
        let startedOnLeftPage = touchStartPoint.x < bookNode.position.x
        let startedOnRightPage = touchStartPoint.x >= bookNode.position.x
        let tappedLeftPage = abs(deltaX) < 20 && abs(deltaY) < 20 && endPoint.x < bookNode.position.x
        let tappedRightPage = abs(deltaX) < 20 && abs(deltaY) < 20 && endPoint.x >= bookNode.position.x
        let swipedTowardLeftPage = deltaX > 36 || (startedOnLeftPage && deltaY > 36)
        let swipedTowardRightPage = deltaX < -36 || (startedOnRightPage && deltaY > 36)

        if tappedLeftPage || swipedTowardLeftPage {
            flipPageBack()
        } else if tappedRightPage || swipedTowardRightPage {
            flipPageUp()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPoint = .zero
    }
}
