//
//  PlayerState.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import Foundation

struct PlayerState: Equatable {
    var unlockedPieceIDs: Set<Int> = []
    var placedPieceIDs: Set<Int> = []
}
