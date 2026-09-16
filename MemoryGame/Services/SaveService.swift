// Penjelasan file: SaveService.swift
// Kerangka layanan penyimpanan PlayerState yang belum diimplementasikan.
// save masih kosong dan loadPlayerState mengembalikan data awal. Penyimpanan aktif memakai PrologueStore.

//
//  SaveService.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
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
