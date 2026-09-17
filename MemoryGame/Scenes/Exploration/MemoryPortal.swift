// Penjelasan file: MemoryPortal.swift
// Kabut prosedural berlapis untuk menutup papan dan menyibak dunia kenangan.
// Fractal noise menghasilkan gumpalan tidak beraturan, bukan partikel lingkaran.
// Tekstur dibuat sekali; Reduce Motion hanya memakai fade tanpa gerak lapisan.
import SpriteKit
import UIKit

enum MemoryPortal {
    // Noise deterministik: variasi kabut konsisten dan tidak membutuhkan aset tambahan.
    private static func random(_ x: Int, _ y: Int, seed: Int) -> Double {
        var value = UInt32(truncatingIfNeeded: x &* 374761393 &+ y &* 668265263 &+ seed &* 1274126177)
        value = (value ^ (value >> 13)) &* 1274126177
        return Double(value ^ (value >> 16)) / Double(UInt32.max)
    }
    private static func noise(_ x: Double, _ y: Double, seed: Int) -> Double {
        let ix = Int(floor(x)), iy = Int(floor(y))
        let dx = x - floor(x), dy = y - floor(y)
        let sx = dx * dx * (3 - 2 * dx), sy = dy * dy * (3 - 2 * dy)
        let top = random(ix, iy, seed: seed) * (1 - sx) + random(ix + 1, iy, seed: seed) * sx
        let bottom = random(ix, iy + 1, seed: seed) * (1 - sx) + random(ix + 1, iy + 1, seed: seed) * sx
        return top * (1 - sy) + bottom * sy
    }
    private static func texture(seed: Int) -> SKTexture {
        let width = 384, height = 192
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let u = Double(x) / Double(width), v = Double(y) / Double(height)
                // Domain warp memecah pola kotak; beberapa skala memberi serat dan gumpalan.
                let warp = noise(u * 4, v * 3, seed: seed + 19)
                var density = 0.0, amplitude = 0.55, frequency = 3.0
                for octave in 0..<5 {
                    density += amplitude * noise(u * frequency + warp * 1.8,
                        v * frequency * 1.6 + warp, seed: seed + octave * 31)
                    amplitude *= 0.5; frequency *= 2
                }
                let alpha = min(0.88, max(0, (density - 0.20) * 1.65))
                let light = 0.78 + density * 0.18
                let index = (y * width + x) * 4
                // RGB dipremultiply dengan alpha sesuai format CGImage.
                pixels[index] = UInt8(min(255, light * 0.97 * alpha * 255))
                pixels[index + 1] = UInt8(min(255, light * alpha * 255))
                pixels[index + 2] = UInt8(min(255, light * 0.94 * alpha * 255))
                pixels[index + 3] = UInt8(alpha * 255)
            }
        }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
        let result = SKTexture(cgImage: image); result.filteringMode = .linear
        return result
    }
    private static let mist = [texture(seed: 17), texture(seed: 83), texture(seed: 149)]

    // Lembaran kabut memenuhi layar dan bergeser silang dengan kecepatan berbeda.
    // Tidak ada gerak radial, tepi lingkaran, atau percikan yang menyerupai gelembung.
    static func play(on scene: SKScene, origin: CGPoint, inward: Bool, duration: TimeInterval) {
        let layer = SKNode(); layer.zPosition = 900; scene.addChild(layer)
        let center = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        let veil = SKSpriteNode(color: SKColor(red: 0.80, green: 0.84, blue: 0.77, alpha: 1), size: scene.size)
        veil.position = center; veil.alpha = inward ? 0 : 1; layer.addChild(veil)
        // Kabut masih terlihat bertekstur sebelum layar tertutup penuh pada akhir transisi.
        veil.run(inward ? .sequence([.wait(forDuration: duration * 0.45),
            .fadeIn(withDuration: duration * 0.55)]) : .fadeOut(withDuration: duration * 0.7))
        if !UIAccessibility.isReduceMotionEnabled {
            for index in 0..<5 {
                let fog = SKSpriteNode(texture: mist[index % mist.count])
                fog.size = CGSize(width: scene.size.width * 1.65, height: scene.size.height * 1.65)
                let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                let offset = CGFloat(index - 2) * scene.size.height * 0.045
                fog.position = CGPoint(x: center.x - direction * scene.size.width * 0.18, y: center.y + offset)
                fog.alpha = inward ? 0 : 0.65
                fog.zRotation = CGFloat(index - 2) * 0.025
                layer.addChild(fog)
                let move = SKAction.moveBy(x: direction * scene.size.width * (inward ? 0.22 : 0.30),
                    y: (origin.y - center.y) * 0.04 + direction * scene.size.height * 0.035, duration: duration)
                move.timingMode = .easeInEaseOut
                let fade = inward ? SKAction.sequence([
                    .wait(forDuration: duration * Double(index) * 0.05),
                    .fadeAlpha(to: 0.65, duration: duration * (1 - Double(index) * 0.05))
                ]) : .fadeOut(withDuration: duration)
                fog.run(.group([move, fade]))
            }
        }
        layer.run(.sequence([.wait(forDuration: duration), .removeFromParent()]))
    }
}
