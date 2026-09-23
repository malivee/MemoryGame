import Foundation

struct GridPosition: Codable, Hashable {
    var x: Int
    var y: Int

    var key: String { "\(x),\(y)" }
}

enum BiomeType: String, Codable, Hashable {
    case rockSalt
    case villageSoil
    case naturalGrass
    case darkGreenForest
    case hillSoil
    case water
}

enum SideType: String, Codable, Hashable {
    case open
    case path
    case blocked
    case forest
    case cliff
    case rockSalt
    case villageSoil
    case naturalGrass
    case darkGreenForest
    case hillSoil
    case water

    var biome: BiomeType? {
        switch self {
        case .rockSalt:
            return .rockSalt
        case .villageSoil:
            return .villageSoil
        case .naturalGrass:
            return .naturalGrass
        case .darkGreenForest:
            return .darkGreenForest
        case .hillSoil:
            return .hillSoil
        case .water:
            return .water
        default:
            return nil
        }
    }

    static func biome(_ biome: BiomeType) -> SideType {
        switch biome {
        case .rockSalt:
            return .rockSalt
        case .villageSoil:
            return .villageSoil
        case .naturalGrass:
            return .naturalGrass
        case .darkGreenForest:
            return .darkGreenForest
        case .hillSoil:
            return .hillSoil
        case .water:
            return .water
        }
    }

    func canConnect(to other: SideType) -> Bool {
        if let biome, let otherBiome = other.biome {
            return biome == otherBiome
        }

        switch (self, other) {
        case (.open, .open), (.open, .path), (.path, .open), (.path, .path):
            return true
        default:
            return false
        }
    }
}

enum GridRotation: Int, Codable, Hashable, CaseIterable {
    case degrees0 = 0
    case degrees90 = 90
    case degrees180 = 180
    case degrees270 = 270

    var quarterTurns: Int { rawValue / 90 }

    func rotated(position: GridPosition) -> GridPosition {
        switch self {
        case .degrees0:
            return position
        case .degrees90:
            return GridPosition(x: -position.y, y: position.x)
        case .degrees180:
            return GridPosition(x: -position.x, y: -position.y)
        case .degrees270:
            return GridPosition(x: position.y, y: -position.x)
        }
    }

    func rotatedSides(west: SideType, north: SideType, east: SideType, south: SideType) -> (west: SideType, north: SideType, east: SideType, south: SideType) {
        switch self {
        case .degrees0:
            return (west, north, east, south)
        case .degrees90:
            return (south, west, north, east)
        case .degrees180:
            return (east, south, west, north)
        case .degrees270:
            return (north, east, south, west)
        }
    }
}

struct GridCell: Codable, Hashable {
    let id: String
    var x: Int
    var y: Int
    var biome: BiomeType
    var isFilled: Bool
    var isWalkable: Bool
}

struct SquarePlace: Codable, Hashable, Identifiable {
    let id: String
    var image: String
    var localX: Int
    var localY: Int
    var westSide: SideType
    var northSide: SideType
    var eastSide: SideType
    var southSide: SideType
    var grid: [GridCell]

    var localPosition: GridPosition {
        GridPosition(x: localX, y: localY)
    }
}

enum TetrominoShape: String, Codable, Hashable, CaseIterable {
    case i
    case o
    case t
    case j
    case l
    case s
    case z

    var baseSquares: [GridPosition] {
        switch self {
        case .i:
            return [GridPosition(x: 0, y: 0), GridPosition(x: 1, y: 0), GridPosition(x: 2, y: 0), GridPosition(x: 3, y: 0)]
        case .o:
            return [GridPosition(x: 0, y: 0), GridPosition(x: 1, y: 0), GridPosition(x: 0, y: 1), GridPosition(x: 1, y: 1)]
        case .t:
            return [GridPosition(x: -1, y: 0), GridPosition(x: 0, y: 0), GridPosition(x: 1, y: 0), GridPosition(x: 0, y: 1)]
        case .j:
            return [GridPosition(x: 1, y: 0), GridPosition(x: 1, y: 1), GridPosition(x: 1, y: 2), GridPosition(x: 0, y: 2)]
        case .l:
            return [GridPosition(x: 0, y: 0), GridPosition(x: 0, y: 1), GridPosition(x: 0, y: 2), GridPosition(x: 1, y: 2)]
        case .s:
            return [GridPosition(x: 1, y: 0), GridPosition(x: 2, y: 0), GridPosition(x: 0, y: 1), GridPosition(x: 1, y: 1)]
        case .z:
            return [GridPosition(x: 0, y: 0), GridPosition(x: 1, y: 0), GridPosition(x: 1, y: 1), GridPosition(x: 2, y: 1)]
        }
    }
}

struct Tetromino: Codable, Hashable, Identifiable {
    let id: String
    var shape: TetrominoShape
    var originX: Int
    var originY: Int
    var squares: [SquarePlace]
    var rotation: GridRotation

    var origin: GridPosition {
        GridPosition(x: originX, y: originY)
    }
}

struct ResolvedGridCell: Codable, Hashable {
    let tetrominoID: String
    let squareID: String
    let cellID: String
    let worldX: Int
    let worldY: Int
    let biome: BiomeType
    let isFilled: Bool
    let isWalkable: Bool
}

struct ResolvedSquare: Codable, Hashable {
    let tetrominoID: String
    let squareID: String
    let worldX: Int
    let worldY: Int
    let westSide: SideType
    let northSide: SideType
    let eastSide: SideType
    let southSide: SideType
    let grid: [ResolvedGridCell]

    var position: GridPosition {
        GridPosition(x: worldX, y: worldY)
    }
}

enum TetrominoResolver {
    static func resolve(_ tetromino: Tetromino, cellsPerSquare: Int = 1) -> [ResolvedSquare] {
        tetromino.squares.map { square in
            let rotatedSquare = tetromino.rotation.rotated(position: square.localPosition)
            let worldSquare = GridPosition(
                x: tetromino.originX + rotatedSquare.x,
                y: tetromino.originY + rotatedSquare.y
            )
            let sides = tetromino.rotation.rotatedSides(
                west: square.westSide,
                north: square.northSide,
                east: square.eastSide,
                south: square.southSide
            )
            let resolvedCells = square.grid.map { cell in
                let rotatedCell = tetromino.rotation.rotated(position: GridPosition(x: cell.x, y: cell.y))
                return ResolvedGridCell(
                    tetrominoID: tetromino.id,
                    squareID: square.id,
                    cellID: cell.id,
                    worldX: worldSquare.x * cellsPerSquare + rotatedCell.x,
                    worldY: worldSquare.y * cellsPerSquare + rotatedCell.y,
                    biome: cell.biome,
                    isFilled: cell.isFilled,
                    isWalkable: cell.isWalkable
                )
            }
            return ResolvedSquare(
                tetrominoID: tetromino.id,
                squareID: square.id,
                worldX: worldSquare.x,
                worldY: worldSquare.y,
                westSide: sides.west,
                northSide: sides.north,
                eastSide: sides.east,
                southSide: sides.south,
                grid: resolvedCells
            )
        }
    }
}

enum PlacementValidator {
    static func canPlace(
        tetromino: Tetromino,
        boardColumns: Int,
        boardRows: Int
    ) -> Bool {
        canPlace(
            tetromino: tetromino,
            boardColumns: boardColumns,
            boardRows: boardRows,
            occupiedPositions: Set<GridPosition>()
        )
    }

    static func canPlace(
        tetromino: Tetromino,
        boardColumns: Int,
        boardRows: Int,
        occupiedPositions: Set<GridPosition>
    ) -> Bool {
        for square in TetrominoResolver.resolve(tetromino) {
            let position = square.position
            guard position.x >= 0,
                  position.y >= 0,
                  position.x < boardColumns,
                  position.y < boardRows,
                  !occupiedPositions.contains(position) else {
                return false
            }
        }
        return true
    }

    static func compatible(_ first: ResolvedSquare, _ second: ResolvedSquare) -> Bool {
        let dx = second.worldX - first.worldX
        let dy = second.worldY - first.worldY

        switch (dx, dy) {
        case (-1, 0):
            return first.westSide.canConnect(to: second.eastSide)
        case (1, 0):
            return first.eastSide.canConnect(to: second.westSide)
        case (0, 1):
            return first.northSide.canConnect(to: second.southSide)
        case (0, -1):
            return first.southSide.canConnect(to: second.northSide)
        default:
            return true
        }
    }

    static func hasCompatibleInternalSides(_ tetromino: Tetromino) -> Bool {
        let squares = TetrominoResolver.resolve(tetromino)
        for first in squares {
            for second in squares where first.squareID != second.squareID {
                guard compatible(first, second) else { return false }
            }
        }
        return true
    }
}
