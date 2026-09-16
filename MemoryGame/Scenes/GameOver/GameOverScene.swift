// Penjelasan file: GameOverScene.swift
// Kerangka layar game over yang saat ini hanya mengatur warna latar.
// Dalam eksplorasi prolog, tertangkap warga mengembalikan karakter ke checkpoint melalui ExplorationScene.

//
//  GameOverScene.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import SpriteKit

final class GameOverScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = GameConstants.Colors.tableBackground
    }
}
