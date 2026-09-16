import CoreGraphics
import Foundation

/// The same obstacle set drives collision, pathfinding and clipped guard sight.
struct MemoryNavigation {
    let bounds: CGRect
    let solids: [CGRect]
    let fog: [CGRect]
    let radius: CGFloat = 12
    private let step: CGFloat = 20

    func walkable(_ point: CGPoint) -> Bool {
        bounds.insetBy(dx: radius, dy: radius).contains(point)
            && !solids.contains { $0.insetBy(dx: -radius, dy: -radius).contains(point) }
            && !fog.contains { $0.insetBy(dx: -radius + 1, dy: -radius + 1).contains(point) }
    }
    func moved(from: CGPoint, by delta: CGVector) -> CGPoint {
        var result = from
        let x = CGPoint(x: result.x + delta.dx, y: result.y)
        if walkable(x) { result.x = x.x }
        let y = CGPoint(x: result.x, y: result.y + delta.dy)
        if walkable(y) { result.y = y.y }
        return result
    }
    /// First intersection with an AABB, in normalized segment coordinates.
    private func intersection(from: CGPoint, to: CGPoint, rect: CGRect) -> CGFloat? {
        var near: CGFloat = 0
        var far: CGFloat = 1
        for (origin, delta, low, high) in [(from.x, to.x - from.x, rect.minX, rect.maxX), (from.y, to.y - from.y, rect.minY, rect.maxY)] {
            if abs(delta) < 0.0001 {
                if origin < low || origin > high { return nil }
            } else {
                let a = (low - origin) / delta
                let b = (high - origin) / delta
                near = max(near, min(a, b)); far = min(far, max(a, b))
                if near > far { return nil }
            }
        }
        return near
    }
    func sightEnd(from: CGPoint, to: CGPoint) -> CGPoint {
        let t = (solids + fog).compactMap { intersection(from: from, to: to, rect: $0) }.min() ?? 1
        return CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t)
    }
    func visible(from: CGPoint, to: CGPoint) -> Bool {
        let end = sightEnd(from: from, to: to)
        return hypot(end.x - to.x, end.y - to.y) < 0.5
    }
    func nearestOpen(to point: CGPoint) -> CGPoint {
        if walkable(point) { return point }
        return gridPoints.min(by: { distance($0, point) < distance($1, point) }) ?? point
    }
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
    private var columns: Int { Int(bounds.width / step) }
    private var rows: Int { Int(bounds.height / step) }
    private func point(_ id: Int) -> CGPoint {
        CGPoint(x: CGFloat(id % columns) * step + step / 2, y: CGFloat(id / columns) * step + step / 2)
    }
    private var gridPoints: [CGPoint] { (0..<(columns * rows)).map(point).filter(walkable) }

    func route(from start: CGPoint, to destination: CGPoint) -> [CGPoint] {
        let allowed = Set((0..<(columns * rows)).filter { walkable(point($0)) })
        guard let first = allowed.min(by: { distance(point($0), start) < distance(point($1), start) }),
              let last = allowed.min(by: { distance(point($0), destination) < distance(point($1), destination) }) else { return [] }
        var queue = [first]
        var head = 0
        var cameFrom: [Int: Int] = [first: first]
        while head < queue.count {
            let current = queue[head]; head += 1
            if current == last { break }
            let col = current % columns
            let candidates = [col > 0 ? current - 1 : -1, col < columns - 1 ? current + 1 : -1, current - columns, current + columns]
            for next in candidates where allowed.contains(next) && cameFrom[next] == nil {
                // Inflate obstacles for actor radius before testing movement.
                let blocked = (solids + fog).contains { intersection(from: point(current), to: point(next), rect: $0.insetBy(dx: -radius, dy: -radius)) != nil }
                if blocked { continue }
                cameFrom[next] = current
                queue.append(next)
            }
        }
        guard cameFrom[last] != nil else { return [] }
        var ids = [last]
        var current = last
        while current != first, let previous = cameFrom[current] { current = previous; ids.append(current) }
        return ids.reversed().map(point)
    }
}
