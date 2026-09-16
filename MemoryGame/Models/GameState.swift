// Penjelasan file: GameState.swift
// Daftar status umum permainan: menu, bermain, jeda, dan game over.
// Ini merupakan model status dasar; progres misi prolog disimpan terpisah di PrologueProgress.

//
//  GameState.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import Foundation

enum GameState: Equatable {
    case menu
    case playing
    case paused
    case gameOver
}
