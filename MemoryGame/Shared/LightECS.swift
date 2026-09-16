//
//  LightECS.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import SpriteKit

typealias EntityID = Int

struct TransformComponent {
    var position: CGPoint
    var scale: CGFloat
    var zPosition: CGFloat
}

struct RenderComponent {
    let node: SKNode
}

struct PuzzlePieceComponent {
    let puzzleID: Int
    let column: Int
    let row: Int
    let title: String
    let data: PuzzlePieceData
    var isSnapped: Bool
}

struct DraggableComponent {
    var homePosition: CGPoint
    var currentLoosePosition: CGPoint
    var dragOffset: CGPoint
    var dragStartTouch: CGPoint
    var dragStartPosition: CGPoint
    var wasSnappedAtDragStart: Bool
    var isDragging: Bool
}

struct SnapTargetComponent {
    let position: CGPoint
    let radius: CGFloat
}

final class ECSWorld {
    private var nextEntityID: EntityID = 1

    private(set) var entities: Set<EntityID> = []
    var transforms: [EntityID: TransformComponent] = [:]
    var renders: [EntityID: RenderComponent] = [:]
    var puzzlePieces: [EntityID: PuzzlePieceComponent] = [:]
    var draggables: [EntityID: DraggableComponent] = [:]
    var snapTargets: [EntityID: SnapTargetComponent] = [:]

    func createEntity() -> EntityID {
        let entity = nextEntityID
        nextEntityID += 1
        entities.insert(entity)
        return entity
    }

    func removeAll() {
        nextEntityID = 1
        entities.removeAll()
        transforms.removeAll()
        renders.removeAll()
        puzzlePieces.removeAll()
        draggables.removeAll()
        snapTargets.removeAll()
    }

    func entity(named name: String?) -> EntityID? {
        guard let name, name.hasPrefix("entity-") else { return nil }
        return Int(name.replacingOccurrences(of: "entity-", with: ""))
    }

    func applyTransforms() {
        for entity in entities {
            guard let transform = transforms[entity], let render = renders[entity] else { continue }
            render.node.position = transform.position
            render.node.setScale(transform.scale)
            render.node.zPosition = transform.zPosition
        }
    }
}
