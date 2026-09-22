// Penjelasan file: VillageNavigation.swift
// Navigasi preview tanpa ketergantungan pada puzzle, save, atau quest utama.
// Collision bangunan dan invisible wall dipakai baik untuk stik maupun pencarian jalan.
import Foundation
import CoreGraphics
struct VillageNavigation {
    var stage: VillageAccess
    let radius: CGFloat = 13
    let step: CGFloat = 24
    func walkable(_ p: CGPoint) -> Bool {
        guard VillageMap.bounds.insetBy(dx: 24, dy: 24).contains(p),
              VillageMap.onWalkableGround(p),
              !VillageMap.solids.contains(where: { $0.insetBy(dx: -radius, dy: -radius).contains(p) }) else { return false }
        return [CGPoint(x: p.x-radius, y: p.y), CGPoint(x: p.x+radius, y: p.y),
                CGPoint(x: p.x, y: p.y-radius), CGPoint(x: p.x, y: p.y+radius)].allSatisfy { VillageMap.accessible($0, stage: stage) }
    }
    // Substep mencegah karakter menembus penghalang tipis saat frame melambat.
    func moved(from start: CGPoint, by delta: CGVector) -> CGPoint {
        let steps = max(1, Int(ceil(hypot(delta.dx, delta.dy) / 6)))
        var p = start
        for _ in 0..<steps {
            let x = CGPoint(x: p.x + delta.dx / CGFloat(steps), y: p.y)
            if walkable(x) { p = x }
            let y = CGPoint(x: p.x, y: p.y + delta.dy / CGFloat(steps))
            if walkable(y) { p = y }
        }
        return p
    }
    func route(from start: CGPoint, to goal: CGPoint) -> [CGPoint] {
        guard walkable(goal) else { return [] }
        let cols = Int(VillageMap.bounds.width / step), rows = Int(VillageMap.bounds.height / step)
        func point(_ id: Int) -> CGPoint { CGPoint(x: (CGFloat(id % cols)+0.5)*step, y: (CGFloat(id / cols)+0.5)*step) }
        func nearest(_ p: CGPoint) -> Int? {
            (0..<(cols*rows)).filter { walkable(point($0)) }.min {
                hypot(point($0).x-p.x, point($0).y-p.y) < hypot(point($1).x-p.x, point($1).y-p.y)
            }
        }
        guard let first = nearest(start), let last = nearest(goal) else { return [] }
        var queue = [first], head = 0, previous = [first:first]
        while head < queue.count {
            let current = queue[head]; head += 1
            if current == last { break }
            let col = current % cols
            for next in [col > 0 ? current-1 : -1, col < cols-1 ? current+1 : -1, current-cols, current+cols] {
                guard next >= 0, next < cols*rows, previous[next] == nil, walkable(point(next)) else { continue }
                let a = point(current), b = point(next)
                let reached = moved(from: a, by: CGVector(dx: b.x-a.x, dy: b.y-a.y))
                guard hypot(reached.x-b.x, reached.y-b.y) < 0.1 else { continue }
                previous[next] = current; queue.append(next)
            }
        }
        guard previous[last] != nil else { return [] }
        var ids = [last], current = last
        while current != first { current = previous[current]!; ids.append(current) }
        return ids.reversed().map(point)
    }
}
