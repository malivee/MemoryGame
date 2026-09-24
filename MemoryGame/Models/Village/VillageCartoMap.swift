import Foundation
import CoreGraphics

/// Geometry and terrain for the independent Carto map, not the story village.
enum VillageCartoMap {
    static let imageName = "VillageCartoMap"
    static let columns = 18, rows = 10
    static let side: CGFloat = 96
    static let size = CGSize(width: CGFloat(columns) * side, height: CGFloat(rows) * side)
    // The asset contour owns eligibility; an independent ID list would clip it.
    static let grassBuildPieceIDs: Set<Int> = Set(pieces.indices.filter { id in
        pieces[id].contains { cell in
            buildableSourceSubcells.contains {
                $0.x / subdivisions == cell.x && $0.y / subdivisions == cell.y
            }
        }
    })
    static let grassBuildPieceNumbers = Set(grassBuildPieceIDs.map { $0 + 1 })
    static let subdivisions = 6
    static let subcellSide = side / CGFloat(subdivisions)
    struct Cell: Hashable {
        let x: Int
        let y: Int
    }

    enum TerrainSplit: Equatable {
        case diagonal
        case centeredRightTriangle
        case centeredLeftTriangle
        case centeredTopTriangle
        case lowerRightTriangle
    }

    struct Building: Identifiable, Equatable {
        let id: String
        let title: String
        let width: Int
        let height: Int
        let explorationWidth: Int
        let explorationHeight: Int
        let kind: Kind

        func displaySize(inExploration: Bool) -> CGSize {
            CGSize(
                width: inExploration ? explorationWidth : width,
                height: inExploration ? explorationHeight : height
            )
        }

        enum Kind: String, Codable {
            case house
            case barn
            case well
            case pen
        }
    }

    // Ukuran width x height adalah footprint subgrid di layer peta. Versi
    // eksplorasi memakai skala 1:3: 6x9 menjadi 2x3 dan 3x3 menjadi 1x1.
    static let buildings: [Building] = [
        .init(
            id: "arthur-house",
            title: "Rumah Arthur",
            width: 6,
            height: 9,
            explorationWidth: 2,
            explorationHeight: 3,
            kind: .house
        ),
        .init(
            id: "village-well",
            title: "Sumur",
            width: 3,
            height: 3,
            explorationWidth: 1,
            explorationHeight: 1,
            kind: .well
        ),
        .init(
            id: "bu-mara-house",
            title: "Rumah Bu Mara",
            width: 6,
            height: 6,
            explorationWidth: 2,
            explorationHeight: 2,
            kind: .house
        ),
        .init(
            id: "village-barn",
            title: "Lumbung Desa",
            width: 9,
            height: 15,
            explorationWidth: 3,
            explorationHeight: 5,
            kind: .barn
        ),
        .init(
            id: "roland-pen",
            title: "Kandang Roland",
            width: 12,
            height: 9,
            explorationWidth: 4,
            explorationHeight: 3,
            kind: .pen
        ),
        .init(
            id: "anneth-house",
            title: "Rumah Anneth",
            width: 6,
            height: 9,
            explorationWidth: 2,
            explorationHeight: 3,
            kind: .house
        ),
        .init(
            id: "beryn-house",
            title: "Rumah Kakek Beryn",
            width: 9,
            height: 9,
            explorationWidth: 3,
            explorationHeight: 3,
            kind: .house
        ),
        .init(
            id: "empty-warehouse",
            title: "Gudang Kosong",
            width: 9,
            height: 9,
            explorationWidth: 3,
            explorationHeight: 3,
            kind: .barn
        )
    ]

    // Four edge-connected source cells form one indivisible piece.
    static let pieces: [[Cell]] = [
        [.init(x: 16, y: 9), .init(x: 17, y: 9), .init(x: 16, y: 8), .init(x: 17, y: 8)],
        [.init(x: 15, y: 8), .init(x: 15, y: 7), .init(x: 15, y: 6), .init(x: 16, y: 6)],
        [.init(x: 11, y: 8), .init(x: 12, y: 8), .init(x: 11, y: 7), .init(x: 12, y: 7)],
        [.init(x: 13, y: 8), .init(x: 13, y: 7), .init(x: 13, y: 6), .init(x: 13, y: 5)],
        [.init(x: 16, y: 7), .init(x: 17, y: 7), .init(x: 17, y: 6), .init(x: 17, y: 5)],
        [.init(x: 5, y: 8), .init(x: 6, y: 8), .init(x: 6, y: 7), .init(x: 7, y: 7)],
        [.init(x: 7, y: 8), .init(x: 8, y: 8), .init(x: 8, y: 7), .init(x: 8, y: 6)],
        [.init(x: 5, y: 6), .init(x: 5, y: 5), .init(x: 5, y: 4), .init(x: 6, y: 4)],
        [.init(x: 0, y: 8), .init(x: 0, y: 7), .init(x: 0, y: 6), .init(x: 0, y: 5)],
        [.init(x: 1, y: 7), .init(x: 1, y: 6), .init(x: 1, y: 5), .init(x: 2, y: 5)],
        [.init(x: 14, y: 7), .init(x: 14, y: 6), .init(x: 14, y: 5), .init(x: 15, y: 5)],
        [.init(x: 6, y: 6), .init(x: 7, y: 6), .init(x: 6, y: 5), .init(x: 7, y: 5)],
        [.init(x: 9, y: 6), .init(x: 10, y: 6), .init(x: 11, y: 6), .init(x: 10, y: 5)],
        [.init(x: 12, y: 6), .init(x: 11, y: 5), .init(x: 12, y: 5), .init(x: 12, y: 4)],
        [.init(x: 0, y: 9), .init(x: 1, y: 9), .init(x: 2, y: 9), .init(x: 1, y: 8)],
        [.init(x: 3, y: 7), .init(x: 4, y: 7), .init(x: 5, y: 7), .init(x: 4, y: 6)],
        [.init(x: 9, y: 9), .init(x: 9, y: 8), .init(x: 9, y: 7), .init(x: 10, y: 7)],
        [.init(x: 3, y: 5), .init(x: 3, y: 4), .init(x: 3, y: 3), .init(x: 3, y: 2)],
        [.init(x: 4, y: 5), .init(x: 4, y: 4), .init(x: 4, y: 3), .init(x: 5, y: 3)],
        [.init(x: 2, y: 8), .init(x: 2, y: 7), .init(x: 2, y: 6), .init(x: 3, y: 6)],
        [.init(x: 8, y: 5), .init(x: 9, y: 5), .init(x: 9, y: 4), .init(x: 10, y: 4)],
        [.init(x: 16, y: 5), .init(x: 15, y: 4), .init(x: 16, y: 4), .init(x: 16, y: 3)],
        [.init(x: 0, y: 4), .init(x: 1, y: 4), .init(x: 0, y: 3), .init(x: 1, y: 3)],
        [.init(x: 3, y: 9), .init(x: 4, y: 9), .init(x: 3, y: 8), .init(x: 4, y: 8)],
        [.init(x: 5, y: 9), .init(x: 6, y: 9), .init(x: 7, y: 9), .init(x: 8, y: 9)],
        [.init(x: 2, y: 4), .init(x: 2, y: 3), .init(x: 2, y: 2), .init(x: 2, y: 1)],
        [.init(x: 10, y: 9), .init(x: 11, y: 9), .init(x: 12, y: 9), .init(x: 10, y: 8)],
        [.init(x: 13, y: 9), .init(x: 14, y: 9), .init(x: 15, y: 9), .init(x: 14, y: 8)],
        [.init(x: 7, y: 4), .init(x: 8, y: 4), .init(x: 8, y: 3), .init(x: 8, y: 2)],
        [.init(x: 11, y: 4), .init(x: 10, y: 3), .init(x: 11, y: 3), .init(x: 10, y: 2)],
        [.init(x: 13, y: 4), .init(x: 12, y: 3), .init(x: 13, y: 3), .init(x: 13, y: 2)],
        [.init(x: 14, y: 4), .init(x: 14, y: 3), .init(x: 15, y: 3), .init(x: 14, y: 2)],
        [.init(x: 17, y: 4), .init(x: 17, y: 3), .init(x: 17, y: 2), .init(x: 17, y: 1)],
        [.init(x: 6, y: 3), .init(x: 4, y: 2), .init(x: 5, y: 2), .init(x: 6, y: 2)],
        [.init(x: 7, y: 3), .init(x: 7, y: 2), .init(x: 7, y: 1), .init(x: 8, y: 1)],
        [.init(x: 9, y: 3), .init(x: 9, y: 2), .init(x: 9, y: 1), .init(x: 10, y: 1)],
        [.init(x: 0, y: 2), .init(x: 1, y: 2), .init(x: 0, y: 1), .init(x: 1, y: 1)],
        [.init(x: 11, y: 2), .init(x: 12, y: 2), .init(x: 11, y: 1), .init(x: 12, y: 1)],
        [.init(x: 15, y: 2), .init(x: 13, y: 1), .init(x: 14, y: 1), .init(x: 15, y: 1)],
        [.init(x: 16, y: 2), .init(x: 16, y: 1), .init(x: 16, y: 0), .init(x: 17, y: 0)],
        [.init(x: 3, y: 1), .init(x: 4, y: 1), .init(x: 5, y: 1), .init(x: 4, y: 0)],
        [.init(x: 6, y: 1), .init(x: 5, y: 0), .init(x: 6, y: 0), .init(x: 7, y: 0)],
        [.init(x: 0, y: 0), .init(x: 1, y: 0), .init(x: 2, y: 0), .init(x: 3, y: 0)],
        [.init(x: 8, y: 0), .init(x: 9, y: 0), .init(x: 10, y: 0), .init(x: 11, y: 0)],
        [.init(x: 12, y: 0), .init(x: 13, y: 0), .init(x: 14, y: 0), .init(x: 15, y: 0)],
    ]

    // Enam keping pertama mengikuti storyboard. Keping ketujuh adalah hadiah
    // Quest 6 berupa tetromino I yang seluruhnya biome hutan hijau tua.
    // ID tetap menunjuk empat sel unik pada atlas sumber, sedangkan nomor yang
    // dilihat pemain berasal dari posisi ID di array ini.
    static let playablePieceIDs: [Int] = [5, 26, 20, 38, 6, 12, 8, 0, 1, 3]

    static func displayNumber(forPieceID id: Int) -> Int? {
        playablePieceIDs.firstIndex(of: id).map { $0 + 1 }
    }

    // Keping keempat dan keenam memakai bentuk atlas yang orientasi sumbernya
    // terbalik 180° dari storyboard.
    static func preferredTurns(forPieceID id: Int) -> Int {
        id == 38 || id == 12 ? 2 : 0
    }

    // Storyboard memberi warna per kotak: rumput desa (kuning), rumput yang
    // tidak bisa dibangun (hijau muda), hutan (hijau tua), dan rock salt
    // (abu-abu). Setiap pasangan adalah dua segitiga pada satu kotak 6 x 6.
    // Koordinat pola dinormalisasi dari kiri-bawah bentuk tetromino.
    private static let playableTerrain: [Cell: (primary: BiomeType, secondary: BiomeType)] = {
        typealias Paint = (x: Int, y: Int, primary: BiomeType, secondary: BiomeType)
        let patterns: [(id: Int, paint: [Paint])] = [
            (5, [
                // Sesuai storyboard, kedua bidang hijau berada pada segitiga
                // kiri-bawah di masing-masing kotak diagonal.
                (0, 1, .naturalGrass, .villageSoil),
                (1, 1, .villageSoil, .villageSoil),
                (1, 0, .naturalGrass, .villageSoil),
                (2, 0, .villageSoil, .villageSoil)
            ]),
            (26, [
                (0, 1, .villageSoil, .villageSoil),
                (1, 1, .villageSoil, .naturalGrass),
                (2, 1, .naturalGrass, .naturalGrass),
                (0, 0, .villageSoil, .darkGreenForest)
            ]),
            (20, [
                (0, 1, .villageSoil, .villageSoil),
                (1, 1, .villageSoil, .villageSoil),
                (1, 0, .villageSoil, .villageSoil),
                (2, 0, .villageSoil, .rockSalt)
            ]),
            (38, [
                (0, 0, .naturalGrass, .villageSoil),
                (1, 0, .villageSoil, .villageSoil),
                (2, 0, .villageSoil, .villageSoil),
                (2, 1, .villageSoil, .darkGreenForest)
            ]),
            (6, [
                (0, 2, .villageSoil, .rockSalt),
                (1, 2, .rockSalt, .rockSalt),
                (1, 1, .rockSalt, .rockSalt),
                (1, 0, .rockSalt, .rockSalt)
            ]),
            (12, [
                (0, 1, .darkGreenForest, .darkGreenForest),
                (1, 1, .darkGreenForest, .darkGreenForest),
                (2, 1, .darkGreenForest, .darkGreenForest),
                (1, 0, .darkGreenForest, .villageSoil)
            ]),
            (8, [
                (0, 3, .darkGreenForest, .darkGreenForest),
                (0, 2, .darkGreenForest, .darkGreenForest),
                (0, 1, .darkGreenForest, .darkGreenForest),
                (0, 0, .darkGreenForest, .darkGreenForest)
            ]),
            (0, [
                (0, 1, .darkGreenForest, .hillSoil),
                (1, 1, .hillSoil, .darkGreenForest),
                (0, 0, .darkGreenForest, .darkGreenForest),
                (1, 0, .hillSoil, .darkGreenForest)
            ]),
            (1, [
                (0, 2, .darkGreenForest, .hillSoil),
                (0, 1, .darkGreenForest, .darkGreenForest),
                (0, 0, .hillSoil, .darkGreenForest),
                (1, 0, .darkGreenForest, .darkGreenForest)
            ]),
            (3, [
                (0, 3, .hillSoil, .darkGreenForest),
                (0, 2, .darkGreenForest, .darkGreenForest),
                (0, 1, .darkGreenForest, .hillSoil),
                (0, 0, .darkGreenForest, .darkGreenForest)
            ])
        ]

        var result: [Cell: (primary: BiomeType, secondary: BiomeType)] = [:]
        for entry in patterns {
            let shape = pieces[entry.id]
            guard let minX = shape.map(\.x).min(), let minY = shape.map(\.y).min() else { continue }
            for paint in entry.paint {
                let cell = Cell(x: minX + paint.x, y: minY + paint.y)
                guard shape.contains(cell) else { continue }
                result[cell] = (paint.primary, paint.secondary)
            }
        }
        return result
    }()

    // Pada keping 2, kotak kanan sepenuhnya hijau muda. Warnanya masuk ke
    // kotak tengah sebagai segitiga sama kaki sejauh 3/6 subgrid. Kotak bawah
    // memakai diagonal kebalikan agar hijau tua berada di kanan bawah.
    // Keping 5 dan keping T memakai segitiga beralas satu sisi penuh.
    static func terrainSplit(for cell: Cell) -> TerrainSplit {
        switch cell {
        case Cell(x: 11, y: 9),
             Cell(x: 8, y: 8), Cell(x: 8, y: 7), Cell(x: 8, y: 6):
            return .centeredRightTriangle
        case Cell(x: 10, y: 5):
            return .centeredLeftTriangle
        case Cell(x: 10, y: 8):
            return .lowerRightTriangle
        // Keping 4 diputar 180° saat ditampilkan. Segitiga atas pada sumber
        // menjadi segitiga hijau tua beralas di bawah pada tampilan pemain.
        case Cell(x: 15, y: 2):
            return .centeredTopTriangle
        default:
            return .diagonal
        }
    }

    static func biome(for cell: Cell) -> BiomeType {
        if hasWater(in: cell) {
            return .water
        }
        if cell.x <= 4 && cell.y >= 1 {
            return .darkGreenForest
        }
        if cell.x >= 14 || (cell.x >= 13 && cell.y >= 5) {
            return .rockSalt
        }
        if cell.y >= 8 || cell.x >= 16 {
            return .hillSoil
        }
        if (8...13).contains(cell.x) && (3...6).contains(cell.y) {
            return .villageSoil
        }
        return .naturalGrass
    }

    static func diagonalBiomes(for cell: Cell) -> (primary: BiomeType, secondary: BiomeType) {
        if let curated = playableTerrain[cell] {
            return curated
        }
        let primary = biome(for: cell)
        let diagonalNeighbor = [Cell(x: cell.x + 1, y: cell.y), Cell(x: cell.x, y: cell.y + 1)]
            .first { candidate in
                candidate.x >= 0 && candidate.x < columns &&
                candidate.y >= 0 && candidate.y < rows &&
                biome(for: candidate) != primary
            }
        let secondary = diagonalNeighbor.map { neighbor in
            biome(for: neighbor)
        } ?? primary
        return (primary, secondary)
    }

    static func biomeForSubcell(_ subcell: Cell) -> BiomeType {
        let source = Cell(x: subcell.x / subdivisions, y: subcell.y / subdivisions)
        let localX = CGFloat(subcell.x % subdivisions) + 0.5
        let localY = CGFloat(subcell.y % subdivisions) + 0.5
        return biome(in: source, localX: localX, localY: localY)
    }

    private static func biome(in source: Cell, localX: CGFloat, localY: CGFloat) -> BiomeType {
        let diagonal = diagonalBiomes(for: source)
        switch terrainSplit(for: source) {
        case .centeredRightTriangle:
            let center = CGFloat(subdivisions) / 2
            let depth = localX - center
            return depth >= 0 && abs(localY - center) <= depth ? diagonal.secondary : diagonal.primary
        case .centeredLeftTriangle:
            let center = CGFloat(subdivisions) / 2
            let depth = center - localX
            return depth >= 0 && abs(localY - center) <= depth ? diagonal.secondary : diagonal.primary
        case .centeredTopTriangle:
            let center = CGFloat(subdivisions) / 2
            let depth = localY - center
            return depth >= 0 && abs(localX - center) <= depth ? diagonal.secondary : diagonal.primary
        case .lowerRightTriangle:
            return localY <= localX ? diagonal.secondary : diagonal.primary
        case .diagonal:
            return localX + localY >= CGFloat(subdivisions) ? diagonal.secondary : diagonal.primary
        }
    }

    static func canPlaceObject(onSubcell subcell: Cell) -> Bool {
        let source = Cell(x: subcell.x / subdivisions, y: subcell.y / subdivisions)
        let column = CGFloat(subcell.x % subdivisions)
        let row = CGFloat(subcell.y % subdivisions)
        let epsilon: CGFloat = 0.001
        let samples = [
            (column + epsilon, row + epsilon),
            (column + 1 - epsilon, row + epsilon),
            (column + epsilon, row + 1 - epsilon),
            (column + 1 - epsilon, row + 1 - epsilon),
            (column + 0.5, row + 0.5)
        ]
        return samples.allSatisfy { x, y in
            biome(in: source, localX: x, localY: y) == .villageSoil
        }
    }

    // Edge indices follow VillageTileLayout: east, north, west, south.
    static func sideBiome(for cell: Cell, edge: Int) -> BiomeType {
        let diagonal = diagonalBiomes(for: cell)
        let normalizedEdge = (edge % 4 + 4) % 4
        switch terrainSplit(for: cell) {
        case .centeredRightTriangle:
            return normalizedEdge == 0 ? diagonal.secondary : diagonal.primary
        case .centeredLeftTriangle:
            return normalizedEdge == 2 ? diagonal.secondary : diagonal.primary
        case .centeredTopTriangle:
            return normalizedEdge == 1 ? diagonal.secondary : diagonal.primary
        case .lowerRightTriangle:
            return normalizedEdge == 0 || normalizedEdge == 3 ? diagonal.secondary : diagonal.primary
        case .diagonal:
            break
        }
        switch normalizedEdge {
        case 0, 1:
            return diagonal.secondary
        default:
            return diagonal.primary
        }
    }

    static func tetromino(id: Int, originX: Int = 0, originY: Int = 0, rotation: GridRotation = .degrees0) -> Tetromino? {
        guard pieces.indices.contains(id) else { return nil }
        let shapeCells = pieces[id]
        let anchor = shapeCells[0]
        let squares = shapeCells.map { cell in
            let diagonal = diagonalBiomes(for: cell)
            let grid = (0..<subdivisions).flatMap { row in
                (0..<subdivisions).map { column in
                    GridCell(
                        id: "\(cell.x)-\(cell.y)-\(column)-\(row)",
                        x: column,
                        y: row,
                        biome: biomeForSubcell(Cell(
                            x: cell.x * subdivisions + column,
                            y: cell.y * subdivisions + row
                        )),
                        isFilled: true,
                        isWalkable: diagonal.primary != .water
                    )
                }
            }
            return SquarePlace(
                id: "\(cell.x),\(cell.y)",
                image: "",
                localX: cell.x - anchor.x,
                localY: cell.y - anchor.y,
                westSide: .biome(sideBiome(for: cell, edge: 2)),
                northSide: .biome(sideBiome(for: cell, edge: 1)),
                eastSide: .biome(sideBiome(for: cell, edge: 0)),
                southSide: .biome(sideBiome(for: cell, edge: 3)),
                grid: grid
            )
        }
        return Tetromino(
            id: "carto-\(id + 1)",
            shape: tetrominoShape(for: shapeCells),
            originX: originX,
            originY: originY,
            squares: squares,
            rotation: rotation
        )
    }

    static var tetrominoes: [Tetromino] {
        pieces.indices.compactMap { tetromino(id: $0) }
    }

    private static func hasWater(in cell: Cell) -> Bool {
        let startX = cell.x * subdivisions
        let startY = cell.y * subdivisions
        for row in 0..<subdivisions {
            for column in 0..<subdivisions {
                let index = (startY + row) * (columns * subdivisions) + startX + column
                if waterSubcellIndices.contains(index) {
                    return true
                }
            }
        }
        return false
    }

    private static func tetrominoShape(for cells: [Cell]) -> TetrominoShape {
        let normalized = normalizedVariants(for: cells)
        for shape in TetrominoShape.allCases where normalized.contains(normalizedShape(shape.baseSquares)) {
            return shape
        }
        return .o
    }

    private static func normalizedVariants(for cells: [Cell]) -> Set<String> {
        let positions = cells.map { GridPosition(x: $0.x, y: $0.y) }
        return Set(GridRotation.allCases.map { rotation in
            normalizedShape(positions.map(rotation.rotated(position:)))
        })
    }

    private static func normalizedShape(_ positions: [GridPosition]) -> String {
        let minX = positions.map(\.x).min() ?? 0
        let minY = positions.map(\.y).min() ?? 0
        let normalized = positions.map { position in
            GridPosition(x: position.x - minX, y: position.y - minY)
        }
        let sorted = normalized.sorted { first, second in
            first.x == second.x ? first.y < second.y : first.x < second.x
        }
        return sorted.map { position in
            "\(position.x),\(position.y)"
        }.joined(separator: "|")
    }

    // Reference coordinates use the supplied 1672 x 941 image's top-left corner.
    static func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * size.width / 1672, y: (941 - y) * size.height / 941)
    }
    // Quest pertama dimulai pada keping berbentuk L (ID 26). Keping Z
    // tersedia sesudahnya sebagai keping kedua pada alur tutorial.
    static let spawn = CGPoint(x: 10.5 * side, y: 9.5 * side)
    static let roads: [[CGPoint]] = [
        [point(780,330), point(816,352), point(875,382), point(942,408), point(976,412), point(1005,401)],
        [point(942,408), point(951,448), point(991,476), point(1046,503)],
        [point(734,566), point(778,541), point(819,515), point(859,530), point(890,550), point(944,540), point(995,516), point(1046,503)],
        [point(679,462), point(720,485), point(769,512), point(819,515)],
        [point(202,94), point(222,81), point(246,64)],
        [point(115,818), point(146,800), point(175,782)]
    ]
    private static func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        let bottom = point(x, y + height), top = point(x + width, y)
        return CGRect(x: bottom.x, y: bottom.y, width: top.x - bottom.x, height: top.y - bottom.y)
    }
    // Plateau contours traced on 123.jpg (reference preview 1818 x 1344).
    // Normalize against this asset rather than the previous map's dimensions.
    private static let buildingFields: [CGPath] = [
        field([
            (654,553),(679,498),(686,425),(704,421),(726,439),(752,441),
            (795,421),(811,356),(833,290),(839,280),(902,275),(938,257),
            (958,276),(981,278),(1009,259),(1059,277),(1131,284),
            (1168,261),(1196,265),(1230,291),(1241,318),(1236,351),
            (1278,382),(1300,407),(1300,431),(1323,438),(1354,489),
            (1366,513),(1406,526),(1420,550),(1411,577),(1435,613),
            (1463,664),(1449,688),(1450,735),(1425,767),(1390,820),
            (1355,881),(1321,930),(1296,958),(1254,960),(1213,986),
            (1181,1007),(1120,990),(1105,965),(1122,930),(1120,900),
            (1088,864),(1040,860),(989,824),(936,783),(911,752),
            (892,718),(866,679),(822,656),(780,644),(725,633),
            (683,623),(668,587)
        ]),
        field([
            (659,670),(689,675),(719,695),(746,701),(774,694),
            (803,706),(818,738),(852,775),(877,792),(895,832),
            (925,860),(964,881),(993,900),(1004,923),(1018,969),
            (988,995),(935,1025),(885,1035),(850,1022),(820,1044),
            (767,1047),(716,1051),(675,1055),(635,1043),(586,1021),
            (575,991),(546,978),(518,948),(523,909),(529,869),
            (573,831),(601,802),(617,758),(633,708)
        ])
    ]
    private static func field(_ vertices: [(CGFloat, CGFloat)]) -> CGPath {
        let path = CGMutablePath()
        for (index, vertex) in vertices.enumerated() {
            let p = CGPoint(x: vertex.0 / 1818 * size.width,
                            y: (1 - vertex.1 / 1344) * size.height)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
    private static func insideBuildingZone(_ p: CGPoint) -> Bool {
        buildingFields.contains { $0.contains(p) }
    }
    private static func insideBuildingZoneWithFeather(_ p: CGPoint) -> Bool {
        let radius = subcellSide * 0.75
        let probes = [
            CGPoint.zero,
            CGPoint(x: radius, y: 0), CGPoint(x: -radius, y: 0),
            CGPoint(x: 0, y: radius), CGPoint(x: 0, y: -radius),
            CGPoint(x: radius, y: radius), CGPoint(x: -radius, y: radius),
            CGPoint(x: radius, y: -radius), CGPoint(x: -radius, y: -radius)
        ]
        return probes.contains { delta in
            insideBuildingZone(CGPoint(x: p.x + delta.x, y: p.y + delta.y))
        }
    }
    // Generated from blue pixels in 123.jpg at the former 3 x 3 resolution.
    // Those blocked cells are expanded below to preserve the river contour at 6 x 6.
    private static let waterSubcellIndicesAt3x3: Set<Int> = [
        41, 42, 43, 54, 55, 56, 92, 93, 94, 95, 96, 108, 109, 110, 111, 112, 145, 146, 147, 148, 149, 164, 165, 166, 167, 198, 199, 200, 201, 202, 220, 221, 222, 223, 250, 251, 252, 253, 254, 275, 276, 277, 278, 303, 304, 305, 306, 330, 331, 332, 333, 334, 355, 356, 357, 358, 359, 386, 387, 388, 389, 408, 409, 410, 411, 442, 443, 462, 463, 464, 496, 497, 498, 515, 516, 517, 551, 552, 553, 554, 567, 568, 569, 570, 571, 606, 607, 608, 609, 620, 621, 622, 623, 661, 662, 663, 664, 673, 674, 675, 676, 715, 716, 717, 718, 719, 726, 727, 728, 771, 772, 773, 774, 775, 776, 777, 778, 779, 780, 781, 782, 826, 827, 828, 829, 830, 831, 832, 833, 834, 880, 881, 882, 883, 884, 934, 935, 987, 988, 989, 1041, 1042, 1043, 1094, 1095, 1096, 1147, 1148, 1149, 1200, 1201, 1202, 1203, 1252, 1253, 1254, 1255, 1256, 1305, 1306, 1307, 1308, 1309, 1356, 1357, 1358, 1359, 1360, 1361, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1458, 1459, 1460, 1461, 1462, 1463, 1464, 1465, 1512, 1513, 1514
    ]
    static let waterSubcellIndices: Set<Int> = {
        let oldColumns = columns * 3
        let scale = subdivisions / 3
        return Set(waterSubcellIndicesAt3x3.flatMap { index in
            let oldColumn = index % oldColumns
            let oldRow = index / oldColumns
            return (0..<scale).flatMap { row in
                (0..<scale).map { column in
                    (oldRow * scale + row) * (columns * subdivisions) + oldColumn * scale + column
                }
            }
        })
    }()
    // Stable source-space mask: eligibility follows a tile through every rotation.
    // A feathered center test keeps edge subcells visible when they sit on the contour.
    static let buildableSourceSubcells: Set<Cell> = {
        var result: Set<Cell> = []
        for id in pieces.indices {
            for cell in pieces[id] {
                for row in 0..<subdivisions {
                    for column in 0..<subdivisions {
                        let sub = Cell(x:cell.x*subdivisions+column,y:cell.y*subdivisions+row)
                        let center = CGPoint(x:(CGFloat(sub.x)+0.5)*subcellSide,
                                             y:(CGFloat(sub.y)+0.5)*subcellSide)
                        let waterIndex = sub.y * (columns * subdivisions) + sub.x
                        let allowed = insideBuildingZoneWithFeather(center)
                            && !waterSubcellIndices.contains(waterIndex)
                        if allowed { result.insert(sub) }
                    }
                }
            }
        }
        return result
    }()
    static func walkable(_ p: CGPoint) -> Bool {
        return roads.contains { road in
            zip(road, road.dropFirst()).contains { a, b in
                let dx = b.x - a.x, dy = b.y - a.y
                let t = max(0, min(1, ((p.x-a.x)*dx + (p.y-a.y)*dy) / max(1, dx*dx + dy*dy)))
                return hypot(p.x-a.x-t*dx, p.y-a.y-t*dy) < 23
            }
        }
    }
}
