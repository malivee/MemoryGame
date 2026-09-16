// Penjelasan file: PlayerState.swift
// Model dasar untuk mencatat ID keping yang terbuka dan sudah dipasang.
// Progres puzzle dan cerita yang aktif saat ini dikelola oleh JigsawProgress dan PrologueProgress.

//
//  PlayerState.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import Foundation

struct PlayerState: Equatable {
    var unlockedPieceIDs: Set<Int> = []
    var placedPieceIDs: Set<Int> = []
}
