//
//  Level.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import Foundation

struct Level: Identifiable, Equatable {
    let id: String
    let name: String
    let columns: Int
    let rows: Int
}
