//
//  GameScene+Input.swift
//  MemoryGame
//
//  SpriteKit port of kleryjohansen/PuzzleGame1 input flow.
//

import SpriteKit

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        if touchedNodes.contains(where: { $0.name == "resetButton" || $0.parent?.name == "resetButton" }) {
            resetGame()
            return
        }

        if touchedNodes.contains(where: { $0.name == "hintButton" || $0.parent?.name == "hintButton" }) {
            solveOneHint()
            return
        }

        let touchedEntity = touchedNodes
            .compactMap { world.entity(named: $0.name) }
            .first { entity in
                world.draggables[entity] != nil && world.puzzlePieces[entity]?.isSnapped == false
            }

        guard let entity = touchedEntity else { return }
        activeDragEntity = entity
        topZPosition += 1
        world.transforms[entity]?.zPosition = topZPosition
        HapticsService.shared.playImpact(style: .light)
        dragSystem.beginDrag(entity: entity, touchLocation: location, world: world)
        renderSystem.update(world: world)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let activeDragEntity else { return }
        dragSystem.updateDrag(entity: activeDragEntity, touchLocation: touch.location(in: self), world: world)
        renderSystem.update(world: world)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endActiveDrag()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endActiveDrag()
    }

    private func endActiveDrag() {
        guard let activeDragEntity else { return }
        defer {
            self.activeDragEntity = nil
            updateHUD()
            checkCompletion()
            renderSystem.update(world: world)
        }

        if let target = snapSystem.nearestTarget(for: activeDragEntity, world: world) {
            snapSystem.snap(entity: activeDragEntity, to: target, world: world)
            addSnapFeedback(at: target.position)
        } else {
            snapSystem.keepLoose(entity: activeDragEntity, world: world)
        }

        dragSystem.endDrag(entity: activeDragEntity, world: world)
    }
}
