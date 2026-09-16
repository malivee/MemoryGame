// Penjelasan file: GameScene+Physics.swift
// Menyediakan fungsi untuk menonaktifkan gravitasi pada dunia fisika GameScene.
// Ini adalah helper konfigurasi; peletakan keping di papan ditangani oleh input dan model puzzle.

//
//  GameScene+Physics.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import SpriteKit

extension GameScene {
    func configurePhysicsWorld() {
        physicsWorld.gravity = .zero
    }
}
