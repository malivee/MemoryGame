//
//  EnemyNode.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import SpriteKit

final class EnemyNode: SKNode {
    let enemyType: EnemyType

    init(enemyType: EnemyType) {
        self.enemyType = enemyType
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        self.enemyType = .placeholder
        super.init(coder: aDecoder)
    }
}
