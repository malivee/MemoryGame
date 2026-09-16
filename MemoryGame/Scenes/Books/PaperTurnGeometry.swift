import SpriteKit

/// Projects a flexible sheet rotating about its bound edge. Integrating the
/// angle along the leaf keeps its length stable while the free edge lags behind.
enum PaperTurnGeometry {
    static func grid(progress: CGFloat, direction: BookFlipDirection, shadow: Bool = false) -> SKWarpGeometryGrid {
        let columns = 32
        let rows = 12
        let sign: CGFloat = direction == .forward ? 1 : -1
        let back = progress >= 0.5
        var source: [SIMD2<Float>] = []
        var destination: [SIMD2<Float>] = []
        source.reserveCapacity((columns + 1) * (rows + 1))
        destination.reserveCapacity((columns + 1) * (rows + 1))
        let lift = sin(progress * .pi)
        let curl = sin(progress * 2 * .pi)

        for row in 0...rows {
            let v = CGFloat(row) / CGFloat(rows)
            var x: CGFloat = 0
            var depth: CGFloat = 0
            for column in 0...columns {
                let u = CGFloat(column) / CGFloat(columns)
                if column > 0 {
                    let midpoint = (CGFloat(column) - 0.5) / CGFloat(columns)
                    let bend = sin(midpoint * .pi) * 0.48 * curl
                    let twist = (v - 0.5) * 0.12 * curl * midpoint
                    let angle = progress * .pi - bend + twist
                    x += cos(angle) / CGFloat(columns)
                    depth += sin(angle) / CGFloat(columns)
                }
                let perspective = shadow ? 1 : 1 / (1 - depth * 0.16)
                let restingBow = sin(u * .pi) * 0.014 * (1 - lift)
                let projectedX = sign * (x * perspective + (shadow ? depth * 0.13 : 0))
                let projectedY = 0.5 + (v - 0.5) * perspective
                    + (shadow ? -depth * 0.08 : depth * 0.045)
                    + restingBow * (v - 0.5) * 2
                // Reverse UVs on the verso so lettering reads correctly after
                // crossing the spine, including turns in the opposite direction.
                let mirror = (direction == .backward) != back
                source.append(SIMD2(Float(mirror ? 1 - u : u), Float(v)))
                destination.append(SIMD2(Float(projectedX), Float(projectedY)))
            }
        }
        return SKWarpGeometryGrid(columns: columns, rows: rows, sourcePositions: source, destinationPositions: destination)
    }
}
