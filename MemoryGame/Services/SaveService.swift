//
//  SaveService.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import Foundation

final class SaveService {
    static let shared = SaveService()

    private init() {}

    func save(playerState: PlayerState) {
        // Persist player progress here.
    }

    func loadPlayerState() -> PlayerState {
        PlayerState()
    }
}
