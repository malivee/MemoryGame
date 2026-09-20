//
//  VillageFogNode.swift.swift
//  MemoryGame
//
//  Created by Daffa Burane Nugraha on 20/09/26.
//

// Menggambar kabut progres desa dengan batas lembut.
// Wilayah terbuka berasal dari VillageMap, sama dengan navigasi.
// Tekstur kabut memakai MemoryPortal yang sudah ada di proyek.

import SpriteKit
import UIKit

final class VillageFogNode: SKNode {
    private var currentAccess: VillageAccess?
    private var currentLayer: SKCropNode?

    // Mask dibuat sekali per tahap, lalu digunakan kembali.
    private static var masks: [VillageAccess: SKTexture] = [:]

    func setAccess(_ access: VillageAccess) {
        guard currentAccess != access else { return }

        let firstAppearance = currentAccess == nil
        currentAccess = access

        // Bersihkan sisa transisi agar lapisan tidak menumpuk
        // ketika progres berubah beberapa kali dengan cepat.
        for child in children where child !== currentLayer {
            child.removeFromParent()
        }

        let previous = currentLayer
        previous?.removeAllActions()
        previous?.alpha = 1

        currentLayer = nil

        if access != .wholeVillage {
            let layer = makeLayer(access)

            // Lapisan baru langsung menutup area yang tetap
            // terkunci selama kabut lama memudar.
            insertChild(layer, at: 0)
            currentLayer = layer
        }

        guard let previous else { return }

        if firstAppearance {
            previous.removeFromParent()
            return
        }

        let duration: TimeInterval =
            UIAccessibility.isReduceMotionEnabled ? 0.2 : 1.2

        previous.run(
            .sequence([
                .fadeOut(withDuration: duration),
                .removeFromParent()
            ])
        )
    }

    private func makeLayer(
        _ access: VillageAccess
    ) -> SKCropNode {
        let bounds = VillageMap.bounds
        let layer = SKCropNode()

        let mask = SKSpriteNode(
            texture: Self.mask(for: access)
        )

        mask.anchorPoint = .zero
        mask.size = bounds.size
        layer.maskNode = mask

        // Lapisan dasar membuat wilayah terkunci tetap tertutup.
        let veil = SKSpriteNode(
            color: SKColor(
                red: 0.83,
                green: 0.87,
                blue: 0.78,
                alpha: 1
            ),
            size: bounds.size
        )

        veil.anchorPoint = .zero
        layer.addChild(veil)

        // Noise bertumpuk memberi bentuk kabut tidak beraturan.
        for (index, texture) in MemoryPortal.mist.enumerated() {
            let cloud = SKSpriteNode(texture: texture)

            cloud.size = CGSize(
                width: bounds.width + 180,
                height: bounds.height + 180
            )

            cloud.position = CGPoint(
                x: bounds.midX,
                y: bounds.midY
            )

            cloud.alpha = 0.55
            layer.addChild(cloud)

            guard !UIAccessibility.isReduceMotionEnabled else {
                continue
            }

            let dx: CGFloat = index.isMultiple(of: 2)
                ? 42
                : -42

            cloud.run(
                .repeatForever(
                    .sequence([
                        .moveBy(
                            x: dx,
                            y: 16,
                            duration: 8 + Double(index)
                        ),
                        .moveBy(
                            x: -dx,
                            y: -16,
                            duration: 8 + Double(index)
                        )
                    ])
                )
            )
        }

        return layer
    }

    private static func mask(
        for access: VillageAccess
    ) -> SKTexture {
        if let texture = masks[access] {
            return texture
        }

        // Resolusi rendah cukup untuk tepi kabut lembut,
        // sehingga penggunaan memori tetap kecil.
        let width = 480
        let height = 360

        let bounds = VillageMap.bounds
        let areas = VillageMap.accessibleAreas(stage: access)

        var pixels = [UInt8](
            repeating: 255,
            count: width * height * 4
        )

        for y in 0..<height {
            for x in 0..<width {
                // Bitmap dihitung dari atas, sedangkan
                // koordinat dunia SpriteKit dari bawah.
                let point = CGPoint(
                    x: (CGFloat(x) + 0.5)
                        * bounds.width
                        / CGFloat(width),
                    y: bounds.height
                        - (CGFloat(y) + 0.5)
                        * bounds.height
                        / CGFloat(height)
                )

                var depth: CGFloat = 0

                for area in areas where area.contains(point) {
                    let distanceToEdge = min(
                        point.x - area.minX,
                        area.maxX - point.x,
                        point.y - area.minY,
                        area.maxY - point.y
                    )

                    depth = max(depth, distanceToEdge)
                }

                // Feather hanya masuk ke sisi wilayah terbuka.
                // Wilayah terkunci tetap tertutup penuh.
                let feather: CGFloat =
                    28
                    + 7
                    * sin(point.x * 0.025)
                    * cos(point.y * 0.031)

                let t = min(
                    1,
                    max(0, depth / feather)
                )

                // Smoothstep untuk transisi alpha yang lembut.
                let alpha = UInt8(
                    (1 - t * t * (3 - 2 * t)) * 255
                )

                let offset = (y * width + x) * 4

                // RGB dipremultiply dengan alpha.
                for channel in 0..<4 {
                    pixels[offset + channel] = alpha
                }
            }
        }

        let provider = CGDataProvider(
            data: Data(pixels) as CFData
        )!

        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(
                rawValue:
                    CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!

        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear

        masks[access] = texture
        return texture
    }
}
