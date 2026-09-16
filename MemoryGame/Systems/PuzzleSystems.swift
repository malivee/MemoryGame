//
//  PuzzleSystems.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import SpriteKit

struct DragSystem {
    func beginDrag(entity: EntityID, touchLocation: CGPoint, world: ECSWorld) {
        guard var draggable = world.draggables[entity], let transform = world.transforms[entity] else { return }
        draggable.isDragging = true
        draggable.wasSnappedAtDragStart = world.puzzlePieces[entity]?.isSnapped ?? false
        draggable.dragStartTouch = touchLocation
        draggable.dragStartPosition = transform.position
        draggable.dragOffset = CGPoint(x: transform.position.x - touchLocation.x, y: transform.position.y - touchLocation.y)
        world.draggables[entity] = draggable

        world.transforms[entity]?.scale = 1.08
        world.renders[entity]?.node.removeAction(forKey: "idleFloat")
    }

    func updateDrag(entity: EntityID, touchLocation: CGPoint, world: ECSWorld) {
        guard let draggable = world.draggables[entity], draggable.isDragging else { return }
        world.transforms[entity]?.position = CGPoint(
            x: touchLocation.x + draggable.dragOffset.x,
            y: touchLocation.y + draggable.dragOffset.y
        )
    }

    func endDrag(entity: EntityID, world: ECSWorld) {
        world.draggables[entity]?.isDragging = false
        world.transforms[entity]?.scale = 1.0
    }
}

struct SnapSystem {
    func nearestTarget(for entity: EntityID, world: ECSWorld) -> SnapTargetComponent? {
        guard let piece = world.puzzlePieces[entity], let transform = world.transforms[entity] else { return nil }

        return world.snapTargets.first { targetEntity, target in
            guard let targetPiece = world.puzzlePieces[targetEntity] else { return false }
            return targetPiece.puzzleID == piece.puzzleID && distance(from: transform.position, to: target.position) <= target.radius
        }?.value
    }

    func target(for entity: EntityID, world: ECSWorld) -> SnapTargetComponent? {
        guard let piece = world.puzzlePieces[entity] else { return nil }

        return world.snapTargets.first { targetEntity, _ in
            world.puzzlePieces[targetEntity]?.puzzleID == piece.puzzleID
        }?.value
    }

    func snap(entity: EntityID, to target: SnapTargetComponent, world: ECSWorld) {
        world.transforms[entity]?.position = target.position
        world.transforms[entity]?.scale = 1.0
        world.transforms[entity]?.zPosition = 1
        world.puzzlePieces[entity]?.isSnapped = true
    }

    func unsnap(entity: EntityID, world: ECSWorld) {
        world.puzzlePieces[entity]?.isSnapped = false
        world.transforms[entity]?.zPosition = 10
    }

    func keepLoose(entity: EntityID, world: ECSWorld) {
        guard let position = world.transforms[entity]?.position else { return }
        world.draggables[entity]?.currentLoosePosition = position
        world.puzzlePieces[entity]?.isSnapped = false
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }
}

struct RenderSystem {
    func update(world: ECSWorld) {
        world.applyTransforms()
    }
}

struct PuzzleProgressSystem {
    func placedCount(world: ECSWorld) -> Int {
        world.draggables.keys.filter { world.puzzlePieces[$0]?.isSnapped == true }.count
    }

    func totalCount(world: ECSWorld) -> Int {
        world.draggables.count
    }

    func isCompleted(world: ECSWorld) -> Bool {
        let total = totalCount(world: world)
        return total > 0 && placedCount(world: world) == total
    }
}
