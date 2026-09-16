// Penjelasan file: MenuScene.swift
// Kerangka layar menu yang saat ini hanya mengatur warna latar.
// Alur aplikasi sekarang langsung membuka GameScene dari GameViewController.

//
//  MenuScene.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import SpriteKit

final class MenuScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = GameConstants.Colors.tableBackground
    }
}
