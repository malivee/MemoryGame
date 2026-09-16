//
//  PuzzlePieceData.swift
//  MemoryGame
//
//  Ported from PuzzleGame1 by kleryjohansen.
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
    public static let canvasWidth: CGFloat = 2484.9
    public static let canvasHeight: CGFloat = 1392.5

    public static let pieces: [PuzzlePieceData] = [
        PuzzlePieceData(id: "piece_r1_c1", row: 1, col: 1, assetName: "piece_r1_c1", width: 457, height: 298, targetX: 0.0, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r1_c2", row: 1, col: 2, assetName: "piece_r1_c2", width: 452, height: 301, targetX: 305.1, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r1_c3", row: 1, col: 3, assetName: "piece_r1_c3", width: 391, height: 355, targetX: 610.2, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r1_c4", row: 1, col: 4, assetName: "piece_r1_c4", width: 451, height: 298, targetX: 853.4, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r1_c5", row: 1, col: 5, assetName: "piece_r1_c5", width: 530, height: 296, targetX: 1154.5, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r1_c6", row: 1, col: 6, assetName: "piece_r1_c6", width: 457, height: 339, targetX: 1530.6, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r1_c7", row: 1, col: 7, assetName: "piece_r1_c7", width: 445, height: 302, targetX: 1839.8, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r1_c8", row: 1, col: 8, assetName: "piece_r1_c8", width: 384, height: 348, targetX: 2137.9, targetY: 0.0, isEdge: true),
        PuzzlePieceData(id: "piece_r2_c1", row: 2, col: 1, assetName: "piece_r2_c1", width: 376, height: 355, targetX: 0.0, targetY: 167.5, isEdge: true),
        PuzzlePieceData(id: "piece_r2_c2", row: 2, col: 2, assetName: "piece_r2_c2", width: 535, height: 391, targetX: 231.1, targetY: 173.5, isEdge: false),
        PuzzlePieceData(id: "piece_r2_c3", row: 2, col: 3, assetName: "piece_r2_c3", width: 450, height: 348, targetX: 607.2, targetY: 218.5, isEdge: false),
        PuzzlePieceData(id: "piece_r2_c4", row: 2, col: 4, assetName: "piece_r2_c4", width: 391, height: 410, targetX: 914.4, targetY: 169.5, isEdge: false),
        PuzzlePieceData(id: "piece_r2_c5", row: 2, col: 5, assetName: "piece_r2_c5", width: 531, height: 414, targetX: 1152.5, targetY: 169.5, isEdge: false),
        PuzzlePieceData(id: "piece_r2_c6", row: 2, col: 6, assetName: "piece_r2_c6", width: 381, height: 361, targetX: 1527.6, targetY: 217.5, isEdge: false),
        PuzzlePieceData(id: "piece_r2_c7", row: 2, col: 7, assetName: "piece_r2_c7", width: 468, height: 400, targetX: 1835.8, targetY: 172.5, isEdge: false),
        PuzzlePieceData(id: "piece_r2_c8", row: 2, col: 8, assetName: "piece_r2_c8", width: 444, height: 312, targetX: 2062.9, targetY: 221.5, isEdge: true),
        PuzzlePieceData(id: "piece_r3_c1", row: 3, col: 1, assetName: "piece_r3_c1", width: 387, height: 361, targetX: 0.0, targetY: 397.0, isEdge: true),
        PuzzlePieceData(id: "piece_r3_c2", row: 3, col: 2, assetName: "piece_r3_c2", width: 444, height: 347, targetX: 237.1, targetY: 404.0, isEdge: false),
        PuzzlePieceData(id: "piece_r3_c3", row: 3, col: 3, assetName: "piece_r3_c3", width: 459, height: 361, targetX: 545.2, targetY: 405.0, isEdge: false),
        PuzzlePieceData(id: "piece_r3_c4", row: 3, col: 4, assetName: "piece_r3_c4", width: 525, height: 360, targetX: 845.4, targetY: 445.0, isEdge: false),
        PuzzlePieceData(id: "piece_r3_c5", row: 3, col: 5, assetName: "piece_r3_c5", width: 448, height: 302, targetX: 1220.5, targetY: 445.0, isEdge: false),
        PuzzlePieceData(id: "piece_r3_c6", row: 3, col: 6, assetName: "piece_r3_c6", width: 464, height: 301, targetX: 1528.6, targetY: 447.0, isEdge: false),
        PuzzlePieceData(id: "piece_r3_c7", row: 3, col: 7, assetName: "piece_r3_c7", width: 448, height: 304, targetX: 1834.8, targetY: 450.0, isEdge: false),
        PuzzlePieceData(id: "piece_r3_c8", row: 3, col: 8, assetName: "piece_r3_c8", width: 386, height: 397, targetX: 2120.9, targetY: 409.0, isEdge: true),
        PuzzlePieceData(id: "piece_r4_c1", row: 4, col: 1, assetName: "piece_r4_c1", width: 438, height: 397, targetX: 0.0, targetY: 635.5, isEdge: true),
        PuzzlePieceData(id: "piece_r4_c2", row: 4, col: 2, assetName: "piece_r4_c2", width: 389, height: 363, targetX: 299.1, targetY: 624.5, isEdge: false),
        PuzzlePieceData(id: "piece_r4_c3", row: 4, col: 3, assetName: "piece_r4_c3", width: 531, height: 292, targetX: 538.2, targetY: 631.5, isEdge: false),
        PuzzlePieceData(id: "piece_r4_c4", row: 4, col: 4, assetName: "piece_r4_c4", width: 459, height: 306, targetX: 915.4, targetY: 630.5, isEdge: false),
        PuzzlePieceData(id: "piece_r4_c5", row: 4, col: 5, assetName: "piece_r4_c5", width: 458, height: 351, targetX: 1221.5, targetY: 624.5, isEdge: false),
        PuzzlePieceData(id: "piece_r4_c6", row: 4, col: 6, assetName: "piece_r4_c6", width: 465, height: 354, targetX: 1527.6, targetY: 624.5, isEdge: false),
        PuzzlePieceData(id: "piece_r4_c7", row: 4, col: 7, assetName: "piece_r4_c7", width: 391, height: 365, targetX: 1834.8, targetY: 624.5, isEdge: false),
        PuzzlePieceData(id: "piece_r4_c8", row: 4, col: 8, assetName: "piece_r4_c8", width: 447, height: 355, targetX: 2059.9, targetY: 675.5, isEdge: true),
        PuzzlePieceData(id: "piece_r5_c1", row: 5, col: 1, assetName: "piece_r5_c1", width: 382, height: 300, targetX: 0.0, targetY: 904.0, isEdge: true),
        PuzzlePieceData(id: "piece_r5_c2", row: 5, col: 2, assetName: "piece_r5_c2", width: 514, height: 352, targetX: 231.1, targetY: 908.0, isEdge: false),
        PuzzlePieceData(id: "piece_r5_c3", row: 5, col: 3, assetName: "piece_r5_c3", width: 393, height: 362, targetX: 606.2, targetY: 856.0, isEdge: false),
        PuzzlePieceData(id: "piece_r5_c4", row: 5, col: 4, assetName: "piece_r5_c4", width: 510, height: 396, targetX: 846.4, targetY: 860.0, isEdge: false),
        PuzzlePieceData(id: "piece_r5_c5", row: 5, col: 5, assetName: "piece_r5_c5", width: 391, height: 363, targetX: 1220.5, targetY: 857.0, isEdge: false),
        PuzzlePieceData(id: "piece_r5_c6", row: 5, col: 6, assetName: "piece_r5_c6", width: 540, height: 368, targetX: 1461.6, targetY: 852.0, isEdge: false),
        PuzzlePieceData(id: "piece_r5_c7", row: 5, col: 7, assetName: "piece_r5_c7", width: 388, height: 399, targetX: 1835.8, targetY: 860.0, isEdge: false),
        PuzzlePieceData(id: "piece_r5_c8", row: 5, col: 8, assetName: "piece_r5_c8", width: 450, height: 348, targetX: 2056.9, targetY: 903.0, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c1", row: 6, col: 1, assetName: "piece_r6_c1", width: 384, height: 352, targetX: 0.0, targetY: 1077.5, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c2", row: 6, col: 2, assetName: "piece_r6_c2", width: 519, height: 298, targetX: 231.1, targetY: 1131.5, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c3", row: 6, col: 3, assetName: "piece_r6_c3", width: 390, height: 348, targetX: 605.2, targetY: 1081.5, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c4", row: 6, col: 4, assetName: "piece_r6_c4", width: 457, height: 303, targetX: 849.4, targetY: 1126.5, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c5", row: 6, col: 5, assetName: "piece_r6_c5", width: 502, height: 342, targetX: 1165.5, targetY: 1087.5, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c6", row: 6, col: 6, assetName: "piece_r6_c6", width: 455, height: 341, targetX: 1516.6, targetY: 1088.5, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c7", row: 6, col: 7, assetName: "piece_r6_c7", width: 465, height: 300, targetX: 1831.8, targetY: 1129.5, isEdge: true),
        PuzzlePieceData(id: "piece_r6_c8", row: 6, col: 8, assetName: "piece_r6_c8", width: 381, height: 299, targetX: 2125.9, targetY: 1132.5, isEdge: true)
    ]
}
