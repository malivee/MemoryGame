// Penjelasan file: EnemyNode.swift
// Kerangka node musuh yang menyimpan jenis EnemyType. Belum memiliki tampilan atau perilaku serangan.
// Warga yang berpatroli dalam prolog menggunakan MemoryPatrol, bukan node ini.

//
//  EnemyNode.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
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
