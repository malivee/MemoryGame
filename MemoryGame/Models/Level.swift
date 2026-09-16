// Penjelasan file: Level.swift
// Model data level berisi identitas, nama, serta jumlah kolom dan baris.
// Peta eksplorasi prolog menggunakan PrologueLevel yang juga menyimpan rintangan dan lokasi interaksi.

//
//  Level.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 16/09/26.
//

import Foundation

struct Level: Identifiable, Equatable {
    let id: String
    let name: String
    let columns: Int
    let rows: Int
}
