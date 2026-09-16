// Penjelasan file: MemoryAtmosphere.swift
// Menambahkan riak air dan partikel debu atau daun untuk menghidupkan latar.
// Efek dipotong mengikuti batas peta dan dinonaktifkan ketika pengaturan Reduce Motion aktif.

import SpriteKit
import UIKit

/// Small ambient motions, kept behind gameplay markers and clipped to the map.
enum MemoryAtmosphere {
    static func add(to world: SKNode, level: PrologueLevel) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let layer = SKCropNode()
        let mask = SKShapeNode(rect: PrologueLevel.bounds)
        mask.fillColor = .white; mask.strokeColor = .clear
        layer.maskNode = mask
        layer.zPosition = 7
        world.addChild(layer)
        if let water = level.obstacles.first(where: { $0.kind == "Air" })?.rect {
            for index in 0..<7 {
                let width = CGFloat(15 + index % 3 * 7)
                let ripple = SKShapeNode(ellipseOf: CGSize(width: width, height: 3))
                ripple.strokeColor = SKColor(red: 0.80, green: 0.94, blue: 0.86, alpha: 0.55)
                ripple.lineWidth = 0.8; ripple.fillColor = .clear
                ripple.position = CGPoint(x: water.minX + 25 + CGFloat(index) * 27, y: water.minY + 24 + CGFloat((index * 29) % 77))
                ripple.alpha = 0
                layer.addChild(ripple)
                ripple.run(.repeatForever(.sequence([
                    .wait(forDuration: Double(index) * 0.22),
                    .group([.fadeAlpha(to: 0.65, duration: 0.8), .scaleX(to: 1.6, duration: 0.8)]),
                    .group([.fadeOut(withDuration: 1.0), .scaleX(to: 2.0, duration: 1.0)]),
                    .scale(to: 1, duration: 0), .wait(forDuration: 1.5)
                ])))
            }
        }
        for index in 0..<9 {
            let particle = SKShapeNode(ellipseOf: CGSize(width: level.region == .house ? 2 : 5, height: 2))
            particle.fillColor = SKColor(red: 0.84, green: 0.77, blue: 0.44, alpha: 0.6)
            particle.strokeColor = .clear; particle.alpha = 0
            let origin = CGPoint(x: 75 + CGFloat(index * 103 % 825), y: 100 + CGFloat(index * 67 % 325))
            particle.position = origin
            layer.addChild(particle)
            particle.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.45),
                .fadeIn(withDuration: 1.0),
                .group([.moveBy(x: 22, y: -28, duration: 4.5), .rotate(byAngle: 1.7, duration: 4.5)]),
                .fadeOut(withDuration: 0.8), .move(to: origin, duration: 0), .wait(forDuration: 2.5)
            ])))
        }
    }
}
