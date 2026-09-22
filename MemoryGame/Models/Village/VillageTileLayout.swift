// Four source cells move, rotate, and collide as one Carto piece.
import Foundation
import CoreGraphics

struct VillageTileLayout {
    static let side = VillageCartoMap.side
    static let sourceColumns = VillageCartoMap.columns, sourceRows = VillageCartoMap.rows
    static let columns = 28, rows = 20
    static let count = VillageCartoMap.pieces.count
    static let bounds = CGRect(x: 0, y: 0, width: CGFloat(columns)*side, height: CGFloat(rows)*side)

    struct Placement: Codable, Equatable {
        let id: Int
        var column: Int
        var row: Int
        var turns: Int
        var origin: CGPoint { CGPoint(x: CGFloat(column)*VillageTileLayout.side, y: CGFloat(row)*VillageTileLayout.side) }
        var center: CGPoint { CGPoint(x: origin.x+VillageTileLayout.side/2, y: origin.y+VillageTileLayout.side/2) }
    }
    struct BuildingPlacement: Codable, Equatable {
        let id: String
        var subColumn: Int
        var subRow: Int
    }
    private struct Save: Codable {
        let version: Int
        let placements: [Placement]
        let buildingPlacements: [BuildingPlacement]?
    }
    private(set) var placements: [Placement]
    private(set) var buildingPlacements: [BuildingPlacement]
    static var initial: Placement {
        Placement(id: tileID(VillageCartoMap.spawn)!, column: 12, row: 10, turns: 0)
    }
    init() {
        placements = [Self.initial]
        buildingPlacements = []
    }
    init(data: Data?) {
        placements = [Self.initial]
        buildingPlacements = []
        if let data, let saved = try? JSONDecoder().decode(Save.self, from: data),
           (3...4).contains(saved.version), Self.valid(saved.placements) {
            placements = saved.placements
            let savedBuildings = saved.buildingPlacements ?? []
            for building in savedBuildings {
                if Self.validBuilding(building, pieces: placements, otherBuildings: buildingPlacements) {
                    buildingPlacements.append(building)
                }
            }
        }
    }
    var encoded: Data? {
        try? JSONEncoder().encode(Save(version: 4, placements: placements, buildingPlacements: buildingPlacements))
    }
    var inventory: [Int] { (0..<Self.count).filter { id in !placements.contains { $0.id == id } } }
    var buildingInventory: [VillageCartoMap.Building] {
        VillageCartoMap.buildings.filter { building in
            !buildingPlacements.contains { $0.id == building.id }
        }
    }

    static func tileID(_ p: CGPoint) -> Int? {
        guard p.x >= 0, p.y >= 0, p.x < CGFloat(sourceColumns)*side, p.y < CGFloat(sourceRows)*side else { return nil }
        let cell = VillageCartoMap.Cell(x: Int(p.x/side), y: Int(p.y/side))
        return VillageCartoMap.pieces.firstIndex { $0.contains(cell) }
    }
    static func sourceOrigin(_ id: Int) -> CGPoint {
        let anchor = VillageCartoMap.pieces[id][0]
        return CGPoint(x: CGFloat(anchor.x)*side, y: CGFloat(anchor.y)*side)
    }
    private static func cellOrigin(_ id: Int) -> CGPoint {
        CGPoint(x: CGFloat(id%sourceColumns)*side, y: CGFloat(id/sourceColumns)*side)
    }
    static func cell(_ p: CGPoint) -> (Int, Int)? {
        guard p.x >= 0, p.y >= 0, p.x < bounds.width, p.y < bounds.height else { return nil }
        return (Int(p.x/side), Int(p.y/side))
    }

    /// Expanded cells are transient geometry, never independently movable pieces.
    static func cells(of piece: Placement) -> [Placement] {
        guard (0..<count).contains(piece.id) else { return [] }
        let shape = VillageCartoMap.pieces[piece.id], anchor = shape[0]
        return shape.map { cell in
            let offset = rotated(CGPoint(x: cell.x-anchor.x, y: cell.y-anchor.y), turns: piece.turns)
            return Placement(id: cell.x+cell.y*sourceColumns,
                             column: piece.column+Int(offset.x), row: piece.row+Int(offset.y), turns: piece.turns)
        }
    }
    func placement(at p: CGPoint) -> Placement? {
        guard let (col,row) = Self.cell(p) else { return nil }
        return placements.first { Self.cells(of: $0).contains { $0.column == col && $0.row == row } }
    }
    static func rotated(_ p: CGPoint, turns: Int) -> CGPoint {
        switch (turns%4+4)%4 {
        case 1: return CGPoint(x: -p.y, y: p.x)
        case 2: return CGPoint(x: -p.x, y: -p.y)
        case 3: return CGPoint(x: p.y, y: -p.x)
        default: return p
        }
    }
    func world(_ source: CGPoint) -> CGPoint? {
        guard let id = Self.tileID(source), let piece = placements.first(where: { $0.id == id }) else { return nil }
        let a = Self.sourceOrigin(id), half = Self.side/2
        let p = Self.rotated(CGPoint(x: source.x-a.x-half, y: source.y-a.y-half), turns: piece.turns)
        return CGPoint(x: piece.center.x+p.x, y: piece.center.y+p.y)
    }
    func source(_ world: CGPoint) -> CGPoint? {
        guard let piece = placement(at: world) else { return nil }
        let p = Self.rotated(CGPoint(x: world.x-piece.center.x, y: world.y-piece.center.y), turns: -piece.turns)
        let a = Self.sourceOrigin(piece.id)
        return CGPoint(x: a.x+Self.side/2+p.x, y: a.y+Self.side/2+p.y)
    }

    /// One closed perimeter, with no internal cell seams.
    static func outline(_ id: Int) -> CGPath {
        let path = CGMutablePath()
        guard (0..<count).contains(id) else { return path }
        typealias Cell = VillageCartoMap.Cell
        let shape = VillageCartoMap.pieces[id], cells = Set(shape), anchor = shape[0]
        var edges: [Cell: Cell] = [:]
        let offsets = [(0,-1),(1,0),(0,1),(-1,0)]
        for c in shape {
            let corners = [c, Cell(x:c.x+1,y:c.y), Cell(x:c.x+1,y:c.y+1), Cell(x:c.x,y:c.y+1)]
            for edge in 0..<4 {
                let d = offsets[edge]
                if !cells.contains(Cell(x:c.x+d.0,y:c.y+d.1)) { edges[corners[edge]] = corners[(edge+1)%4] }
            }
        }
        func point(_ c: Cell) -> CGPoint {
            CGPoint(x:(CGFloat(c.x-anchor.x)-0.5)*side,y:(CGFloat(c.y-anchor.y)-0.5)*side)
        }
        while let start = edges.keys.first {
            path.move(to:point(start))
            var current = start
            while let next = edges.removeValue(forKey:current) {
                path.addLine(to:point(next)); current = next
                if current == start { break }
            }
            path.closeSubpath()
        }
        return path
    }

    // Cell edges: east, north, west, south. Only exposed edges constrain joins.
    static let roadPorts: [[[CGFloat]]] = (0..<(sourceColumns * sourceRows)).map { id in
        let origin = cellOrigin(id), s = side
        var sides = [[CGFloat]](repeating: [], count: 4)
        for road in VillageCartoMap.roads {
            for (a,b) in zip(road,road.dropFirst()) {
                let dx = b.x-a.x, dy = b.y-a.y
                for edge in 0..<4 {
                    let vertical = edge == 0 || edge == 2
                    let denominator = vertical ? dx : dy
                    guard abs(denominator) > 0.0001 else { continue }
                    let boundary = vertical ? origin.x+(edge == 0 ? s : 0) : origin.y+(edge == 1 ? s : 0)
                    let t = (boundary-(vertical ? a.x : a.y))/denominator
                    guard t >= 0, t <= 1 else { continue }
                    let value = vertical ? a.y+t*dy-origin.y : a.x+t*dx-origin.x
                    if value >= 0 && value <= s && !sides[edge].contains(where: { abs($0-value)<1 }) { sides[edge].append(value) }
                }
            }
        }
        return sides.map { $0.sorted() }
    }
    static func boundaryPorts(_ id: Int) -> [(edge: Int, point: CGPoint)] {
        guard (0..<count).contains(id) else { return [] }
        let shape = Set(VillageCartoMap.pieces[id]), anchor = sourceOrigin(id)
        let offsets = [(1,0),(0,1),(-1,0),(0,-1)]
        var result: [(edge: Int, point: CGPoint)] = []
        for cell in shape {
            for edge in 0..<4 {
                let d = offsets[edge]
                guard !shape.contains(.init(x:cell.x+d.0,y:cell.y+d.1)) else { continue }
                let origin = cellOrigin(cell.x+cell.y*sourceColumns)
                for value in roadPorts[cell.x+cell.y*sourceColumns][edge] {
                    let local: CGPoint
                    switch edge {
                    case 0: local = CGPoint(x:side,y:value)
                    case 1: local = CGPoint(x:value,y:side)
                    case 2: local = CGPoint(x:0,y:value)
                    default: local = CGPoint(x:value,y:0)
                    }
                    result.append((edge,CGPoint(x:origin.x+local.x-anchor.x-side/2,
                                               y:origin.y+local.y-anchor.y-side/2)))
                }
            }
        }
        return result
    }
    private static func ports(_ piece: Placement, edge: Int) -> [CGFloat] {
        var result: [CGFloat] = []
        let h = side/2
        for old in 0..<4 {
            guard (old+piece.turns)%4 == edge else { continue }
            for value in roadPorts[piece.id][old] {
                let p: CGPoint
                switch old {
                case 0: p = CGPoint(x: h, y: value-h)
                case 1: p = CGPoint(x: value-h, y: h)
                case 2: p = CGPoint(x: -h, y: value-h)
                default: p = CGPoint(x: value-h, y: -h)
                }
                let q = rotated(p, turns: piece.turns)
                result.append((edge%2 == 0 ? q.y : q.x)+h)
            }
        }
        return result.sorted()
    }

    private static func edge(from a: Placement, to b: Placement) -> Int? {
        switch (b.column-a.column, b.row-a.row) {
        case (1,0): return 0
        case (0,1): return 1
        case (-1,0): return 2
        case (0,-1): return 3
        default: return nil
        }
    }
    private static func cellMatching(_ a: Placement, _ b: Placement, edge: Int) -> Bool {
        let aa = ports(a, edge: edge), bb = ports(b, edge: (edge+2)%4)
        return aa.count == bb.count && zip(aa,bb).allSatisfy { abs($0-$1) <= 12 }
    }
    static func matching(_ a: Placement, _ b: Placement) -> Bool {
        cells(of:a).allSatisfy { first in
            cells(of:b).allSatisfy { second in
                guard let edge = edge(from:first,to:second) else { return true }
                return cellMatching(first,second,edge:edge)
            }
        }
    }
    static func linked(_ a: Placement, _ b: Placement) -> Bool {
        cells(of:a).contains { first in
            cells(of:b).contains { second in
                guard let edge = edge(from:first,to:second) else { return false }
                return !ports(first,edge:edge).isEmpty && cellMatching(first,second,edge:edge)
            }
        }
    }
    static func valid(_ pieces: [Placement]) -> Bool {
        guard pieces.count <= count, Set(pieces.map(\.id)).count == pieces.count else { return false }
        var occupied = Set<Int>()
        for p in pieces {
            guard (0..<count).contains(p.id), (0..<4).contains(p.turns) else { return false }
            for cell in cells(of:p) {
                guard (0..<columns).contains(cell.column), (0..<rows).contains(cell.row),
                      occupied.insert(cell.column+cell.row*columns).inserted else { return false }
            }
        }
        return true
    }
    func canPlace(id: Int, column: Int, row: Int, turns: Int) -> Bool {
        let candidate = Placement(id:id,column:column,row:row,turns:turns)
        let others = placements.filter { $0.id != id }
        return Self.valid(others + [candidate]) && others.allSatisfy { Self.matching(candidate,$0) }
    }
    @discardableResult mutating func place(id: Int, column: Int, row: Int, turns: Int) -> Bool {
        guard canPlace(id:id,column:column,row:row,turns:turns) else { return false }
        placements.removeAll { $0.id == id }
        placements.append(Placement(id:id,column:column,row:row,turns:turns))
        return true
    }
    @discardableResult mutating func remove(id: Int) -> Bool {
        guard placements.contains(where: { $0.id == id }) else { return false }
        placements.removeAll { $0.id == id }
        let currentBuildings = buildingPlacements
        buildingPlacements = currentBuildings.filter { building in
            Self.validBuilding(
                building,
                pieces: placements,
                otherBuildings: currentBuildings.filter { $0.id != building.id }
            )
        }
        return true
    }
    mutating func solveAllPieces() {
        let initialAnchor = VillageCartoMap.pieces[Self.initial.id][0]
        let columnOffset = Self.initial.column - initialAnchor.x
        let rowOffset = Self.initial.row - initialAnchor.y
        let solved = (0..<Self.count).map { id in
            let anchor = VillageCartoMap.pieces[id][0]
            return Placement(
                id: id,
                column: anchor.x + columnOffset,
                row: anchor.y + rowOffset,
                turns: 0
            )
        }
        placements = Self.valid(solved) ? solved : [Self.initial]
        buildingPlacements = buildingPlacements.filter { building in
            Self.validBuilding(
                building,
                pieces: placements,
                otherBuildings: buildingPlacements.filter { $0.id != building.id }
            )
        }
    }
    static func building(_ id: String) -> VillageCartoMap.Building? {
        VillageCartoMap.buildings.first { $0.id == id }
    }
    static func buildingRect(_ placement: BuildingPlacement) -> CGRect? {
        guard let building = building(placement.id) else { return nil }
        let unit = side / 3
        return CGRect(
            x: CGFloat(placement.subColumn) * unit,
            y: CGFloat(placement.subRow) * unit,
            width: CGFloat(building.width) * unit,
            height: CGFloat(building.height) * unit
        )
    }
    func buildingPlacement(at point: CGPoint) -> BuildingPlacement? {
        buildingPlacements.first { placement in
            Self.buildingRect(placement)?.contains(point) == true
        }
    }
    static func validBuildings(_ buildings: [BuildingPlacement], pieces: [Placement]) -> Bool {
        var accepted: [BuildingPlacement] = []
        for building in buildings {
            guard validBuilding(building, pieces: pieces, otherBuildings: accepted) else { return false }
            accepted.append(building)
        }
        return true
    }
    static func validBuilding(
        _ placement: BuildingPlacement,
        pieces: [Placement],
        otherBuildings: [BuildingPlacement]
    ) -> Bool {
        guard let building = building(placement.id),
              placement.subColumn >= 0,
              placement.subRow >= 0,
              placement.subColumn + building.width <= columns * 3,
              placement.subRow + building.height <= rows * 3,
              let rect = buildingRect(placement) else {
            return false
        }

        for subColumn in placement.subColumn..<(placement.subColumn + building.width) {
            for subRow in placement.subRow..<(placement.subRow + building.height) {
                guard buildableSubcell(column: subColumn, row: subRow, pieces: pieces) else {
                    return false
                }
            }
        }

        return otherBuildings.allSatisfy { other in
            guard let otherRect = buildingRect(other) else { return false }
            return !rect.intersects(otherRect.insetBy(dx: -2, dy: -2))
        }
    }
    static func buildableSubcell(column: Int, row: Int, pieces: [Placement]) -> Bool {
        let divisions = VillageCartoMap.subdivisions
        guard column >= 0, row >= 0, column < columns*divisions, row < rows*divisions,
              let piece = pieces.first(where: {
                  cells(of: $0).contains { $0.column == column/divisions && $0.row == row/divisions }
              }) else { return false }
        let unit = VillageCartoMap.subcellSide
        let world = CGPoint(x:(CGFloat(column)+0.5)*unit,y:(CGFloat(row)+0.5)*unit)
        let local = rotated(CGPoint(x:world.x-piece.center.x,y:world.y-piece.center.y),turns:-piece.turns)
        let origin = sourceOrigin(piece.id)
        let source = VillageCartoMap.Cell(x:Int(floor((origin.x+side/2+local.x)/unit)),
                                         y:Int(floor((origin.y+side/2+local.y)/unit)))
        return VillageCartoMap.buildableSourceSubcells.contains(source)
    }
    func canPlaceBuilding(id: String, subColumn: Int, subRow: Int) -> Bool {
        let candidate = BuildingPlacement(id: id, subColumn: subColumn, subRow: subRow)
        let others = buildingPlacements.filter { $0.id != id }
        return Self.validBuilding(candidate, pieces: placements, otherBuildings: others)
    }
    @discardableResult mutating func placeBuilding(id: String, subColumn: Int, subRow: Int) -> Bool {
        guard canPlaceBuilding(id: id, subColumn: subColumn, subRow: subRow) else { return false }
        buildingPlacements.removeAll { $0.id == id }
        buildingPlacements.append(BuildingPlacement(id: id, subColumn: subColumn, subRow: subRow))
        return true
    }
    @discardableResult mutating func removeBuilding(id: String) -> Bool {
        guard buildingPlacements.contains(where: { $0.id == id }) else { return false }
        buildingPlacements.removeAll { $0.id == id }
        return true
    }
    static func canCross(_ a: Placement, _ b: Placement, at point: CGPoint) -> Bool {
        cells(of:a).contains { first in
            cells(of:b).contains { second in
                guard let edge = edge(from:first,to:second) else { return false }
                let boundary: CGFloat
                switch edge {
                case 0: boundary = first.origin.x + side
                case 1: boundary = first.origin.y + side
                case 2: boundary = first.origin.x
                default: boundary = first.origin.y
                }
                guard abs((edge%2 == 0 ? point.x : point.y)-boundary) <= 9 else { return false }
                let t = edge%2 == 0 ? point.y-first.origin.y : point.x-first.origin.x
                return ports(first,edge:edge).contains { abs($0-t) <= 23 }
                    && ports(second,edge:(edge+2)%4).contains { abs($0-t) <= 23 }
            }
        }
    }
    func walkable(_ point: CGPoint) -> Bool {
        let offsets: [CGPoint] = [.zero, CGPoint(x:-8,y:0),CGPoint(x:8,y:0),CGPoint(x:0,y:-8),CGPoint(x:0,y:8)]
        guard let center = placement(at:point) else { return false }
        return offsets.allSatisfy { delta in
            let q = CGPoint(x:point.x+delta.x,y:point.y+delta.y)
            guard let neighbor = placement(at:q) else { return false }
            if center.id != neighbor.id && !Self.matching(center, neighbor) { return false }
            return true
        }
    }
    func moved(from start: CGPoint, by delta: CGVector) -> CGPoint {
        var p = start
        let steps = max(1,Int(ceil(hypot(delta.dx,delta.dy)/3)))
        for _ in 0..<steps {
            let x = CGPoint(x:p.x+delta.dx/CGFloat(steps),y:p.y)
            if walkable(x) { p = x }
            let y = CGPoint(x:p.x,y:p.y+delta.dy/CGFloat(steps))
            if walkable(y) { p = y }
        }
        return p
    }
    func segmentOpen(_ a: CGPoint, _ b: CGPoint) -> Bool {
        let steps = max(1,Int(ceil(hypot(b.x-a.x,b.y-a.y)/3)))
        return (0...steps).allSatisfy { i in
            let t = CGFloat(i)/CGFloat(steps)
            return walkable(CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t))
        }
    }
    // Pencarian jalan hanya melintasi keping yang terpasang, bukan ruang kosong.
    func route(from start: CGPoint, to goal: CGPoint) -> [CGPoint] {
        guard walkable(goal) else { return [] }
        let step: CGFloat = 18, cols = Int(Self.bounds.width/step)+1, rows = Int(Self.bounds.height/step)+1
        func point(_ id: Int) -> CGPoint { CGPoint(x:CGFloat(id%cols)*step+9,y:CGFloat(id/cols)*step+9) }
        let valid = Set((0..<(cols*rows)).filter { walkable(point($0)) })
        func nearest(_ p: CGPoint) -> Int? {
            valid.filter { hypot(point($0).x-p.x,point($0).y-p.y)<30 && segmentOpen(p,point($0)) }
                .min { hypot(point($0).x-p.x,point($0).y-p.y)<hypot(point($1).x-p.x,point($1).y-p.y) }
        }
        guard let first = nearest(start), let last = nearest(goal) else { return [] }
        var queue = [first], head = 0, previous = [first:first]
        while head < queue.count {
            let current = queue[head]; head += 1
            if current == last { break }
            let col = current%cols
            for next in [col>0 ? current-1 : -1,col+1<cols ? current+1 : -1,current-cols,current+cols] {
                guard valid.contains(next),previous[next] == nil,segmentOpen(point(current),point(next)) else { continue }
                previous[next] = current; queue.append(next)
            }
        }
        guard previous[last] != nil else { return [] }
        var ids = [last], current = last
        while current != first { current = previous[current]!; ids.append(current) }
        return ids.reversed().map(point)+[goal]
    }
}
