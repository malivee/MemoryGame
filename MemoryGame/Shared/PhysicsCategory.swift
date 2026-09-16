// Penjelasan file: PhysicsCategory.swift
// Mendefinisikan kategori bitmask untuk membedakan objek dalam fisika SpriteKit.
// Setiap kategori memakai bit berbeda agar dapat digabungkan sebagai mask tabrakan atau kontak.

//
//  PhysicsCategory.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import Foundation

enum PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let enemy: UInt32 = 1 << 1
    static let projectile: UInt32 = 1 << 2
    static let puzzlePiece: UInt32 = 1 << 3
}
