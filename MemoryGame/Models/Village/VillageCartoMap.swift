import Foundation
import CoreGraphics

/// Geometry and terrain for the independent Carto map, not the story village.
enum VillageCartoMap {
    static let imageName = "VillageCartoMap"
    static let columns = 18, rows = 10
    static let side: CGFloat = 96
    static let size = CGSize(width: CGFloat(columns) * side, height: CGFloat(rows) * side)
    struct Cell: Hashable {
        let x: Int
        let y: Int
    }

    struct Building: Identifiable, Equatable {
        let id: String
        let title: String
        let width: Int
        let height: Int
        let kind: Kind

        enum Kind: String, Codable {
            case house
            case barn
            case well
            case pen
        }
    }

    // Building dimensions are measured in the 3 x 3 subgrid inside each map cell.
    // Example: width 6 and height 4 spans two full cells horizontally and more
    // than one cell vertically, so every covered subcell must belong to placed pieces.
    static let buildings: [Building] = [
        .init(id: "housePlaceholder", title: "Rumah 1", width: 6, height: 4, kind: .house)
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

    // Reference coordinates use the supplied 1672 x 941 image's top-left corner.
    static func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * size.width / 1672, y: (941 - y) * size.height / 941)
    }
    static let spawn = point(825, 359)
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
