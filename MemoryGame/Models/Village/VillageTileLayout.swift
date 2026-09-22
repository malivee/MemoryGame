// Peta desa modular: 28 keping persegi, rotasi 90°, dan sambungan jalan.
// Semua transformasi visual, collision, serta posisi Arthur memakai data ini.
import Foundation
import CoreGraphics

struct VillageTileLayout {
    static let side: CGFloat = 235.25
    static let sourceColumns = 7, sourceRows = 4
    static let columns = 10, rows = 7
    static let count = sourceColumns * sourceRows
    static let bounds = CGRect(x: 0, y: 0, width: CGFloat(columns)*side, height: CGFloat(rows)*side)
    struct Placement: Codable, Equatable {
        let id: Int
        var column: Int
        var row: Int
        var turns: Int
        var origin: CGPoint { CGPoint(x: CGFloat(column)*VillageTileLayout.side, y: CGFloat(row)*VillageTileLayout.side) }
        var center: CGPoint { CGPoint(x: origin.x+VillageTileLayout.side/2, y: origin.y+VillageTileLayout.side/2) }
    }
    private(set) var placements: [Placement]
    static var initial: Placement { Placement(id: tileID(VillageMap.spawn)!, column: 4, row: 3, turns: 0) }
    init() { placements = [Self.initial] }
    // Save versi baru tidak membaca array empat keping versi lama.
    init(data: Data?) {
        placements = [Self.initial]
        if let data, let saved = try? JSONDecoder().decode([Placement].self, from: data), Self.valid(saved) {
            placements = saved
        }
    }
    var encoded: Data? { try? JSONEncoder().encode(placements) }
    var inventory: [Int] { (0..<Self.count).filter { id in !placements.contains { $0.id == id } } }
    static func tileID(_ p: CGPoint) -> Int? {
        guard p.x >= 0, p.y >= 0, p.x < CGFloat(sourceColumns)*side, p.y < CGFloat(sourceRows)*side else { return nil }
        return Int(p.x/side) + Int(p.y/side)*sourceColumns
    }
    static func sourceOrigin(_ id: Int) -> CGPoint { CGPoint(x: CGFloat(id%sourceColumns)*side, y: CGFloat(id/sourceColumns)*side) }
    static func cell(_ p: CGPoint) -> (Int, Int)? {
        guard bounds.contains(p) else { return nil }
        return (Int(p.x/side), Int(p.y/side))
    }
    func placement(at p: CGPoint) -> Placement? {
        guard let (col,row) = Self.cell(p) else { return nil }
        return placements.first { $0.column == col && $0.row == row }
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

    // Urutan sisi: timur, utara, barat, selatan. Posisi port dihitung dari
    // persilangan garis jalan asli, bukan dari kedekatan dua keping saja.
    static let roadPorts: [[[CGFloat]]] = (0..<count).map { id in
        let origin = sourceOrigin(id), s = side
        var sides = [[CGFloat]](repeating: [], count: 4)
        for road in VillageMap.roads {
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
    static func ports(_ piece: Placement, edge: Int) -> [CGFloat] {
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
    static func edge(from a: Placement, to b: Placement) -> Int? {
        switch (b.column-a.column, b.row-a.row) {
        case (1,0): return 0
        case (0,1): return 1
        case (-1,0): return 2
        case (0,-1): return 3
        default: return nil
        }
    }
    static func matching(_ a: Placement, _ b: Placement) -> Bool {
        guard let edge = edge(from: a, to: b) else { return false }
        let aa = ports(a, edge: edge), bb = ports(b, edge: (edge+2)%4)
        return aa.count == bb.count && zip(aa,bb).allSatisfy { abs($0-$1) <= 12 }
    }
    static func linked(_ a: Placement, _ b: Placement) -> Bool {
        guard let edge = edge(from: a, to: b) else { return false }
        return !ports(a, edge: edge).isEmpty && matching(a,b)
    }
    static func valid(_ pieces: [Placement]) -> Bool {
        guard pieces.count <= count,
              Set(pieces.map(\.id)).count == pieces.count else { return false }
        var cells = Set<Int>()
        for p in pieces {
            guard (0..<count).contains(p.id), (0..<columns).contains(p.column), (0..<rows).contains(p.row),
                  (0..<4).contains(p.turns), cells.insert(p.column+p.row*columns).inserted else { return false }
        }
        // Penempatan bebas: tidak ada target gambar, syarat jalan, atau syarat rangkaian.
        return true
    }

    func canPlace(id: Int, column: Int, row: Int, turns: Int) -> Bool {
        let candidate = Placement(id:id,column:column,row:row,turns:turns)
        let others = placements.filter { $0.id != id }
        guard Self.valid(others + [candidate]) else { return false }
        // Lokasi dan bentuk rangkaian bebas; hanya sisi yang saling menempel diuji.
        return others.allSatisfy { Self.edge(from:candidate,to:$0) == nil || Self.matching(candidate,$0) }
    }
    @discardableResult mutating func place(id: Int, column: Int, row: Int, turns: Int) -> Bool {
        guard canPlace(id:id,column:column,row:row,turns:turns) else { return false }
        placements.removeAll { $0.id == id }
        placements.append(Placement(id:id,column:column,row:row,turns:turns)); return true
    }
    @discardableResult mutating func remove(id: Int) -> Bool {
        guard placements.contains(where: { $0.id == id }) else { return false }
        let result = placements.filter { $0.id != id }
        guard Self.valid(result) else { return false }
        placements = result; return true
    }
    // Rumah sudah hilang dari tekstur. Bekas tapaknya menjadi halaman yang bisa dilalui.
    static let houseClearings: [CGRect] = VillageMap.landmarks.filter { $0.id != "pen" }.map(\.rect)
        + [VillageMap.rect(911,319,72,65)]
    static let terrainObstacles: [CGRect] = [VillageMap.well, VillageMap.meetingStone]
        + VillageMap.landmarks.filter { $0.id == "pen" }.map(\.rect)
    // Kebebasan menyusun dipisahkan dari navigasi. Satu pasang ujung jalan
    // yang bertemu cukup untuk menyeberang, walaupun sisi lain tidak cocok.
    static func canCross(_ a: Placement, _ b: Placement, at point: CGPoint) -> Bool {
        guard let edge = edge(from:a,to:b) else { return false }
        let t = edge % 2 == 0 ? point.y-a.origin.y : point.x-a.origin.x
        return ports(a,edge:edge).contains { abs($0-t) <= 28 }
            && ports(b,edge:(edge+2)%4).contains { abs($0-t) <= 28 }
    }
    func walkable(_ point: CGPoint) -> Bool {
        let offsets: [CGPoint] = [.zero, CGPoint(x:-8,y:0),CGPoint(x:8,y:0),CGPoint(x:0,y:-8),CGPoint(x:0,y:8)]
        guard let center = placement(at: point) else { return false }
        return offsets.allSatisfy { delta in
            let q = CGPoint(x:point.x+delta.x,y:point.y+delta.y)
            guard let p = source(q), let neighbor = placement(at:q) else { return false }
            if center.id != neighbor.id && !Self.canCross(center, neighbor, at: point) { return false }
            let ground = VillageMap.onWalkableGround(p) || Self.houseClearings.contains { $0.contains(p) }
            return ground && !Self.terrainObstacles.contains { $0.contains(p) }
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
