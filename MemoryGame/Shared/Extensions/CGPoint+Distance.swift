// Penjelasan file: CGPoint+Distance.swift
// Menambahkan operasi bantu untuk CGPoint: penjumlahan dua titik dan jarak lurus antartitik.
// Perhitungan jarak memakai hypot agar pemanggil tidak perlu menulis rumus berulang.

//
//  CGPoint+Distance.swift
//  MemoryGame
//
//  Created by Codex on 16/09/26.
//

import CoreGraphics

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
