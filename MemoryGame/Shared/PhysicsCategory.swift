//
//  PhysicsCategory.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import Foundation

enum PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let enemy: UInt32 = 1 << 1
    static let projectile: UInt32 = 1 << 2
    static let puzzlePiece: UInt32 = 1 << 3
}
