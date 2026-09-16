// Penjelasan file: JigsawOutline.swift
// Membentuk garis tepi jigsaw menggunakan kurva Bezier.
// Bentuk yang sama dipakai untuk memotong tekstur, mengenali sentuhan pada keping, dan memeriksa geometri foto.

import CoreGraphics
import Foundation

/// Shared by rendering, alpha-aware hit testing and geometry validation.
enum JigsawOutline {
    static func path(for piece: PuzzlePieceData) -> CGPath {
        let row = piece.row - 1
        let col = piece.col - 1
        let x = CGFloat(col) * PuzzleCatalog.cellWidth - piece.targetX
        let y = CGFloat(row) * PuzzleCatalog.cellHeight - piece.targetY
        let width = PuzzleCatalog.cellWidth
        let height = PuzzleCatalog.cellHeight
        let topLeft = CGPoint(x: x, y: y)
        let topRight = CGPoint(x: x + width, y: y)
        let bottomRight = CGPoint(x: x + width, y: y + height)
        let bottomLeft = CGPoint(x: x, y: y + height)
        let path = CGMutablePath()
        path.move(to: topLeft)

        // Neighbours share a boundary, with opposite outward tab directions.
        edge(path, from: topLeft, to: topRight,
             sign: row == 0 ? 0 : -direction(row: row - 1, col: col))
        edge(path, from: topRight, to: bottomRight,
             sign: col == PuzzleCatalog.columns - 1 ? 0 : direction(row: row, col: col))
        edge(path, from: bottomRight, to: bottomLeft,
             sign: row == PuzzleCatalog.rows - 1 ? 0 : direction(row: row, col: col))
        edge(path, from: bottomLeft, to: topLeft,
             sign: col == 0 ? 0 : -direction(row: row, col: col - 1))
        path.closeSubpath()
        return path
    }

    private static func direction(row: Int, col: Int) -> CGFloat {
        (row + col).isMultiple(of: 2) ? 1 : -1
    }

    private static func edge(_ path: CGMutablePath, from start: CGPoint, to end: CGPoint, sign: CGFloat) {
        guard sign != 0 else {
            path.addLine(to: end)
            return
        }
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        let depth = PuzzleCatalog.tabDepth * sign
        // A clockwise path in UIKit has its outward normal on the right.
        func point(_ along: CGFloat, _ outward: CGFloat) -> CGPoint {
            CGPoint(x: start.x + dx * along + dy / length * depth * outward,
                    y: start.y + dy * along - dx / length * depth * outward)
        }
        path.addLine(to: point(0.35, 0))
        path.addCurve(to: point(0.40, 0.35), control1: point(0.45, 0), control2: point(0.45, 0.10))
        path.addCurve(to: point(0.50, 1), control1: point(0.30, 0.80), control2: point(0.38, 1))
        path.addCurve(to: point(0.60, 0.35), control1: point(0.62, 1), control2: point(0.70, 0.80))
        path.addCurve(to: point(0.65, 0), control1: point(0.55, 0.10), control2: point(0.55, 0))
        path.addLine(to: end)
    }
}
