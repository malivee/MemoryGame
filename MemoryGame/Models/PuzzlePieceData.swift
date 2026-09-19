// Penjelasan file: PuzzlePieceData.swift
// Menentukan ukuran foto sumber serta pembagian landscape 10 kolom × 4 baris.
// Setiap keping menyimpan batas potongan gambar termasuk tonjolan jigsaw; koordinat foto berawal dari kiri atas.

//
//  PuzzlePieceData.swift
//  MemoryGame
//

import Foundation
import CoreGraphics

public struct PuzzlePieceData: Identifiable, Sendable {
    public let id: String
    public let row: Int
    public let col: Int
    public let assetName: String
    public let width: CGFloat
    public let height: CGFloat
    public let targetX: CGFloat
    public let targetY: CGFloat
    public let isEdge: Bool
}

public enum PuzzleCatalog {
    public static let imageName = "final photo"
    public static let canvasWidth: CGFloat = 1536
    public static let canvasHeight: CGFloat = 614.4
    public static let rows = 4
    public static let columns = 10
    public static let boardRows = 12
    public static let boardColumns = 13
    public static let boardSlotCount = boardRows * boardColumns
    public static let cellWidth = canvasWidth / CGFloat(columns)
    public static let cellHeight = canvasHeight / CGFloat(rows)
    public static let boardCanvasWidth = cellWidth * CGFloat(boardColumns)
    public static let boardCanvasHeight = cellHeight * CGFloat(boardRows)
    public static let tabDepth = min(cellWidth, cellHeight) * 0.22

    // Bounds include the tabs. All coordinates use the photo's top-left origin.
    public static let pieces: [PuzzlePieceData] = (0..<rows).flatMap { row in
        (0..<columns).map { col in
            let left = col == 0 ? 0 : tabDepth
            let top = row == 0 ? 0 : tabDepth
            let right = col == columns - 1 ? 0 : tabDepth
            let bottom = row == rows - 1 ? 0 : tabDepth
            let id = "piece_r\(row + 1)_c\(col + 1)"
            return PuzzlePieceData(
                id: id, row: row + 1, col: col + 1, assetName: id,
                width: cellWidth + left + right,
                height: cellHeight + top + bottom,
                targetX: CGFloat(col) * cellWidth - left,
                targetY: CGFloat(row) * cellHeight - top,
                isEdge: row == 0 || col == 0 || row == rows - 1 || col == columns - 1
            )
        }
    }
}
