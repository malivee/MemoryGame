// Penjelasan file: SceneryTextures.swift
// Menyediakan dan menyimpan tekstur latar hasil SceneryPainter.
// Kunci cache memperhitungkan wilayah, rotasi jalan, dan varian danau; cache dibersihkan ketika sudah berisi empat tekstur.

import SpriteKit

/// Keep repeated photo visits smooth without retaining every possible arrangement.
enum SceneryTextures {
    private static var cache: [String: SKTexture] = [:]
    static func texture(level: PrologueLevel, progress: PrologueProgress) -> SKTexture? {
        let key = "\(level.region.rawValue):\(progress.placement(of: .villageRoad)?.turns ?? -1):\(progress.placement(of: .oldPath)?.turns ?? -1):\(progress.lakeVariant?.rawValue ?? "none")"
        if let texture = cache[key] { return texture }
        guard let image = SceneryPainter().image(level: level, progress: progress) else { return nil }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        if cache.count >= 4 { cache.removeAll() }
        cache[key] = texture
        return texture
    }
}
