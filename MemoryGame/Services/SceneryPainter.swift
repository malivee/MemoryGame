// Penjelasan file: SceneryPainter.swift
// Menggambar latar bergaya lukisan dengan CoreGraphics: tanah, rumah, pepohonan, air, dan perabot.
// Mengikuti posisi rintangan dari PrologueLevel. Detail dekoratif tidak menambah aturan tabrakan.
// Angka acak memakai seed tetap agar detail latar konsisten saat dibuat ulang.

import CoreGraphics
import Foundation

/// Painted scenery in world coordinates. Solid silhouettes use the level's exact
/// collision rectangles; grass, flowers and worn paths are walkable surface detail.
final class SceneryPainter {
    private var seed: UInt64 = 1937
    private var c: CGContext!
    private let grass = CGColor(red: 0.38, green: 0.43, blue: 0.25, alpha: 1)
    private let cream = CGColor(red: 0.85, green: 0.78, blue: 0.59, alpha: 1)
    private let dark = CGColor(red: 0.20, green: 0.24, blue: 0.17, alpha: 1)

    // Membuat bitmap peta, melukis permukaan serta rintangan, lalu menambahkan pencahayaan dekoratif.
    func image(level: PrologueLevel, progress: PrologueProgress, scale: CGFloat = 2) -> CGImage? {
        seed = 1937
        guard let context = CGContext(data: nil, width: Int(960 * scale), height: Int(480 * scale),
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        c = context
        c.scaleBy(x: scale, y: scale)
        fill(PrologueLevel.bounds, grass)
        if level.region == .house { interior() }
        else { landscape(level: level, progress: progress) }
        for obstacle in level.obstacles { paint(obstacle) }
        if level.region != .house { borderStones() }
        // Soft warm light, without affecting stealth visibility or collision.
        c.saveGState()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
            color(1, 0.90, 0.61, 0.12), color(0.14, 0.23, 0.23, 0.05)
        ] as CFArray, locations: [0, 1])!
        c.drawLinearGradient(gradient, start: CGPoint(x: 90, y: 460), end: CGPoint(x: 840, y: 0), options: [])
        c.restoreGState()
        return c.makeImage()
    }
    // Menghasilkan variasi deterministik agar posisi detail kecil tidak berubah setiap kunjungan.
    private func random() -> CGFloat {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((seed >> 32) & 0xffff) / 65535
    }
    private func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }
    private func fill(_ rect: CGRect, _ color: CGColor) { c.setFillColor(color); c.fill(rect) }
    private func ellipse(_ rect: CGRect, _ color: CGColor) { c.setFillColor(color); c.fillEllipse(in: rect) }
    private func line(_ points: [CGPoint], _ color: CGColor, _ width: CGFloat = 1) {
        guard let first = points.first else { return }
        c.beginPath(); c.move(to: first)
        for p in points.dropFirst() { c.addLine(to: p) }
        c.setStrokeColor(color); c.setLineWidth(width); c.setLineCap(.round); c.setLineJoin(.round); c.strokePath()
    }
    private func rounded(_ rect: CGRect, radius: CGFloat, color: CGColor) {
        c.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        c.setFillColor(color); c.fillPath()
    }
    // Melukis dasar wilayah luar ruangan, jalur tanah, dan detail tumbuhan.
    private func landscape(level: PrologueLevel, progress: PrologueProgress) {
        // Broad pigment patches and fine broken strokes give the ground a painted texture.
        for _ in 0..<2200 {
            let x = random() * 960, y = random() * 480
            let value = random()
            ellipse(CGRect(x: x, y: y, width: 8 + random() * 38, height: 3 + random() * 12),
                    color(0.32 + value * 0.24, 0.36 + value * 0.20, 0.19 + value * 0.12, 0.15))
        }
        if level.region == .village {
            trail([CGPoint(x: 0, y: 72), CGPoint(x: 220, y: 82), CGPoint(x: 455, y: 125), CGPoint(x: 740, y: 150), CGPoint(x: 960, y: 145)], width: 52)
            trail([CGPoint(x: 140, y: 0), CGPoint(x: 160, y: 80), CGPoint(x: 245, y: 275), CGPoint(x: 170, y: 365), CGPoint(x: 210, y: 480)], width: 38)
            trail([CGPoint(x: 465, y: 80), CGPoint(x: 470, y: 255), CGPoint(x: 510, y: 420), CGPoint(x: 550, y: 480)], width: 42)
            trail([CGPoint(x: 670, y: 110), CGPoint(x: 700, y: 280), CGPoint(x: 830, y: 310), CGPoint(x: 960, y: 330)], width: 34)
            // Kitchen-garden beds: low soil and flowers, not false cover.
            for row in 0..<4 {
                let rect = CGRect(x: 760, y: 140 + row * 13, width: 136, height: 7)
                rounded(rect, radius: 3, color: color(0.31, 0.28, 0.17, 0.5))
                for col in 0..<12 { flower(CGPoint(x: 766 + col * 11, y: 144 + row * 13), size: 1.7) }
            }
        } else {
            trail([CGPoint(x: 30, y: 100), CGPoint(x: 140, y: 150), CGPoint(x: 245, y: 200), CGPoint(x: 280, y: 370)], width: 42)
            trail([CGPoint(x: 640, y: 65), CGPoint(x: 710, y: 105), CGPoint(x: 790, y: 205), CGPoint(x: 810, y: 370), CGPoint(x: 960, y: 400)], width: 46)
            if progress.lakeVariant == .dryLake {
                rounded(CGRect(x: 343, y: 38, width: 244, height: 135), radius: 30, color: color(0.63, 0.53, 0.34))
                for _ in 0..<42 {
                    let x = 353 + random() * 217, y = 45 + random() * 115
                    line([CGPoint(x: x, y: y), CGPoint(x: x + 8, y: y + 7), CGPoint(x: x + 6, y: y + 15)], color(0.38, 0.32, 0.22, 0.4), 0.8)
                }
            }
        }
        for zone in level.zones where zone.piece == .oldPath || zone.piece == .villageRoad {
            c.saveGState(); c.clip(to: zone.rect)
            c.translateBy(x: zone.rect.midX, y: zone.rect.midY)
            c.rotate(by: -CGFloat(progress.placement(of: zone.piece)?.turns ?? 0) * .pi / 2)
            trail([CGPoint(x: -zone.rect.width / 2, y: 0), CGPoint(x: zone.rect.width / 2, y: 0)], width: 67)
            c.restoreGState()
        }
        for _ in 0..<2900 {
            let x = random() * 960, y = random() * 480
            let v = random()
            line([CGPoint(x: x, y: y), CGPoint(x: x - 1 + random() * 3, y: y + 2 + random() * 3)],
                 color(0.36 + v * 0.25, 0.42 + v * 0.18, 0.22 + v * 0.13, 0.24), 0.7)
        }
        for _ in 0..<270 {
            let p = CGPoint(x: random() * 960, y: random() * 480)
            if level.obstacles.contains(where: { $0.rect.insetBy(dx: -12, dy: -12).contains(p) }) { continue }
            flower(p, size: 1.1 + random() * 1.0)
        }
    }
    private func trail(_ points: [CGPoint], width: CGFloat) {
        line(points, color(0.30, 0.32, 0.19, 0.33), width + 10)
        line(points, color(0.64, 0.57, 0.39), width)
        line(points, color(0.76, 0.68, 0.48, 0.65), width * 0.70)
        for i in 1..<points.count {
            let a = points[i - 1], b = points[i]
            for _ in 0..<Int(hypot(b.x - a.x, b.y - a.y) / 4) {
                let t = random(), side = (random() - 0.5) * width * 0.8
                let p = CGPoint(x: a.x + (b.x - a.x) * t + side * 0.5, y: a.y + (b.y - a.y) * t + side)
                ellipse(CGRect(x: p.x, y: p.y, width: 1 + random() * 3, height: 1.3), color(0.43, 0.39, 0.28, 0.35))
            }
        }
    }
    private func flower(_ p: CGPoint, size: CGFloat) {
        let hue = random()
        let petals = hue > 0.65 ? color(0.93, 0.77, 0.34, 0.85) : color(0.92, 0.89, 0.70, 0.8)
        for i in 0..<5 {
            let a = CGFloat(i) * .pi * 2 / 5
            ellipse(CGRect(x: p.x + cos(a) * size, y: p.y + sin(a) * size, width: size, height: size), petals)
        }
        ellipse(CGRect(x: p.x + size * 0.3, y: p.y + size * 0.3, width: size * 0.8, height: size * 0.8), color(0.79, 0.53, 0.18))
    }
    private func interior() {
        fill(PrologueLevel.bounds, color(0.58, 0.44, 0.29))
        for row in 0..<20 {
            let y = CGFloat(row) * 25
            for col in 0..<9 {
                let x = CGFloat(col) * 128 - (row % 2 == 0 ? 0 : 64)
                let v = random()
                fill(CGRect(x: x + 1, y: y + 1, width: 126, height: 23), color(0.53 + v * 0.11, 0.40 + v * 0.10, 0.26 + v * 0.07))
                for _ in 0..<6 {
                    let gy = y + 3 + random() * 19
                    line([CGPoint(x: x + 8, y: gy), CGPoint(x: x + 35 + random() * 85, y: gy + random() * 1.5)], color(0.3, 0.23, 0.15, 0.16), 0.6)
                }
            }
        }
        // Plaster perimeter and low window sills stay inside the impassable map edge.
        fill(CGRect(x: 0, y: 466, width: 960, height: 14), cream)
        fill(CGRect(x: 0, y: 0, width: 960, height: 10), color(0.28, 0.23, 0.18))
        fill(CGRect(x: 0, y: 0, width: 10, height: 480), cream)
        fill(CGRect(x: 950, y: 0, width: 10, height: 480), cream)
        for x: CGFloat in [90, 340, 620, 845] {
            fill(CGRect(x: x, y: 466, width: 60, height: 10), color(0.23, 0.34, 0.29))
            fill(CGRect(x: x + 3, y: 468, width: 54, height: 6), color(0.66, 0.79, 0.67))
            c.saveGState()
            c.move(to: CGPoint(x: x + 3, y: 466)); c.addLine(to: CGPoint(x: x + 57, y: 466))
            c.addLine(to: CGPoint(x: x + 110, y: 390)); c.addLine(to: CGPoint(x: x + 5, y: 390)); c.closePath()
            c.setFillColor(color(1, 0.9, 0.57, 0.13)); c.fillPath(); c.restoreGState()
        }
        rounded(CGRect(x: 620, y: 270, width: 245, height: 170), radius: 6, color: color(0.43, 0.27, 0.22, 0.65))
        c.setStrokeColor(color(0.78, 0.64, 0.41, 0.6)); c.setLineWidth(3)
        c.stroke(CGRect(x: 628, y: 278, width: 229, height: 154))
        for i in 0..<15 {
            line([CGPoint(x: 634 + i * 15, y: 285), CGPoint(x: 634 + i * 15, y: 425)], color(0.66, 0.49, 0.32, 0.23), 1)
        }
    }
    // Memilih cara menggambar rintangan berdasarkan jenisnya pada data level.
    private func paint(_ obstacle: WorldObstacle) {
        let r = obstacle.rect
        c.saveGState()
        // Shadows are ground effects; all substantial objects keep their solid footprint.
        rounded(r.offsetBy(dx: 5, dy: -5), radius: 5, color: color(0.12, 0.19, 0.15, 0.24))
        c.clip(to: r)
        switch obstacle.kind {
        case "Rumah": cottage(r)
        case "Pagar tanaman", "Pohon": foliage(r, tree: obstacle.kind == "Pohon")
        case "Batu", "Dinding batu": rocks(r, wall: obstacle.kind == "Dinding batu")
        case "Air": water(r)
        case "Tempat tidur": bed(r)
        case "Lemari": cabinet(r)
        case "Meja": table(r)
        default: crate(r)
        }
        c.restoreGState()
    }
    private func cottage(_ r: CGRect) {
        fill(r, color(0.39, 0.29, 0.20))
        fill(r.insetBy(dx: 3, dy: 3), cream)
        let roof = CGRect(x: r.minX + 3, y: r.minY + 18, width: r.width - 6, height: r.height - 21)
        fill(roof, color(0.65, 0.32, 0.18))
        for row in 0..<Int(roof.height / 7 + 1) {
            for col in 0..<Int(roof.width / 11 + 1) {
                let x = roof.minX + CGFloat(col) * 11 - CGFloat(row % 2) * 5
                let y = roof.minY + CGFloat(row) * 7
                let v = random()
                rounded(CGRect(x: x, y: y, width: 10, height: 6), radius: 2, color: color(0.63 + v * 0.22, 0.31 + v * 0.16, 0.16 + v * 0.10))
                line([CGPoint(x: x + 2, y: y + 5), CGPoint(x: x + 8, y: y + 5)], color(0.98, 0.71, 0.4, 0.25), 0.7)
            }
        }
        line([CGPoint(x: roof.minX, y: roof.midY), CGPoint(x: roof.maxX, y: roof.midY)], color(0.39, 0.21, 0.14, 0.7), 3)
        fill(CGRect(x: r.midX - 8, y: r.minY + 1, width: 16, height: 16), color(0.22, 0.29, 0.23))
        for x in [r.minX + 18, r.maxX - 31] {
            fill(CGRect(x: x, y: r.minY + 4, width: 13, height: 9), color(0.30, 0.41, 0.30))
            line([CGPoint(x: x + 6, y: r.minY + 4), CGPoint(x: x + 6, y: r.minY + 13)], cream, 1)
        }
        fill(CGRect(x: r.maxX - 26, y: r.maxY - 26, width: 13, height: 20), color(0.77, 0.69, 0.52))
        fill(CGRect(x: r.maxX - 28, y: r.maxY - 9, width: 17, height: 5), color(0.42, 0.33, 0.24))
    }
    private func foliage(_ r: CGRect, tree: Bool) {
        fill(r, color(0.23, 0.31, 0.18))
        for _ in 0..<Int(r.width * r.height / 25) {
            let x = r.minX + random() * r.width, y = r.minY + random() * r.height
            let light = random()
            let size: CGFloat = tree ? 12 + random() * 16 : 7 + random() * 12
            ellipse(CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size * 0.8),
                    color(0.25 + light * 0.25, 0.33 + light * 0.22, 0.17 + light * 0.12, 0.85))
            ellipse(CGRect(x: x, y: y + 1, width: size * 0.5, height: size * 0.35), color(0.70, 0.70, 0.31, 0.24))
        }
        if tree {
            line([CGPoint(x: r.midX, y: r.minY), CGPoint(x: r.midX, y: r.midY), CGPoint(x: r.midX - 10, y: r.midY + 16)], color(0.36, 0.28, 0.17, 0.5), 4)
        }
    }
    private func rocks(_ r: CGRect, wall: Bool) {
        fill(r, color(0.35, 0.37, 0.31))
        if !wall {
            let points = [CGPoint(x: r.minX + 2, y: r.midY),
                          CGPoint(x: r.minX + r.width * 0.13, y: r.maxY - 9),
                          CGPoint(x: r.midX, y: r.maxY - 2),
                          CGPoint(x: r.maxX - 4, y: r.maxY - r.height * 0.22),
                          CGPoint(x: r.maxX - 1, y: r.minY + r.height * 0.22),
                          CGPoint(x: r.midX, y: r.minY + 2),
                          CGPoint(x: r.minX + 4, y: r.minY + 8)]
            c.beginPath(); c.move(to: points[0])
            for p in points.dropFirst() { c.addLine(to: p) }
            c.closePath(); c.setFillColor(color(0.57, 0.59, 0.51)); c.fillPath()
            let center = CGPoint(x: r.midX + 3, y: r.midY + 9)
            for i in 0..<points.count {
                c.beginPath(); c.move(to: center); c.addLine(to: points[i]); c.addLine(to: points[(i + 1) % points.count]); c.closePath()
                let v = CGFloat(i % 4) / 4
                c.setFillColor(color(0.42 + v * 0.32, 0.45 + v * 0.30, 0.40 + v * 0.25)); c.fillPath()
                line([center, points[i]], color(0.88, 0.86, 0.71, 0.25), 1.3)
            }
            for _ in 0..<32 {
                let x = r.minX + random() * r.width, y = r.minY + random() * r.height
                ellipse(CGRect(x: x, y: y, width: 3 + random() * 9, height: 2 + random() * 5), color(0.40, 0.46, 0.23, 0.55))
            }
            return
        }
        let height: CGFloat = 11
        for row in 0..<Int(r.height / height + 1) {
            for col in 0..<Int(r.width / 26 + 2) {
                let x = r.minX + CGFloat(col) * 26 - CGFloat(row % 2) * 13
                let y = r.minY + CGFloat(row) * height
                let v = random()
                rounded(CGRect(x: x + 1, y: y + 1, width: 24, height: height - 2), radius: 3,
                        color: color(0.45 + v * 0.20, 0.47 + v * 0.18, 0.40 + v * 0.16))
                line([CGPoint(x: x + 4, y: y + height - 3), CGPoint(x: x + 22, y: y + height - 3)], color(0.90, 0.86, 0.69, 0.34), 1)
                if random() > 0.55 { ellipse(CGRect(x: x + 7, y: y + 2, width: 11, height: 4), color(0.40, 0.44, 0.18, 0.7)) }
            }
        }
    }
    private func water(_ r: CGRect) {
        fill(r, color(0.26, 0.46, 0.42))
        rounded(r.insetBy(dx: 3, dy: 3), radius: 12, color: color(0.24, 0.52, 0.56))
        for _ in 0..<360 {
            let x = r.minX + random() * r.width, y = r.minY + random() * r.height
            let v = random()
            line([CGPoint(x: x, y: y), CGPoint(x: x + 2 + random() * 12, y: y)], color(0.45 + v * 0.28, 0.70 + v * 0.15, 0.66 + v * 0.20, 0.20), 1)
        }
        for i in 0..<Int(r.width / 14) {
            let x = r.minX + CGFloat(i) * 14
            ellipse(CGRect(x: x, y: r.minY + random() * 5, width: 10, height: 6), color(0.57, 0.57, 0.40))
            ellipse(CGRect(x: x, y: r.maxY - 5 - random() * 4, width: 11, height: 7), color(0.55, 0.58, 0.41))
        }
    }
    private func crate(_ r: CGRect) {
        if r.width > 70 && r.height > 70 {
            let width = r.width / 2, height = r.height / 2
            for row in 0..<2 {
                for col in 0..<2 {
                    let rect = CGRect(x: r.minX + CGFloat(col) * width, y: r.minY + CGFloat(row) * height, width: width - 1, height: height - 1)
                    smallCrate(rect)
                }
            }
        } else { smallCrate(r) }
    }
    private func smallCrate(_ r: CGRect) {
        fill(r, color(0.38, 0.27, 0.16))
        for row in 0..<Int(r.height / 13 + 1) {
            fill(CGRect(x: r.minX + 3, y: r.minY + CGFloat(row) * 13 + 2, width: r.width - 6, height: 11), color(0.58, 0.41, 0.23))
        }
        line([CGPoint(x: r.minX + 6, y: r.minY + 6), CGPoint(x: r.maxX - 6, y: r.maxY - 6)], color(0.70, 0.53, 0.32), 6)
        line([CGPoint(x: r.minX + 6, y: r.maxY - 6), CGPoint(x: r.maxX - 6, y: r.minY + 6)], color(0.62, 0.45, 0.26), 6)
        for x in [r.minX + 7, r.maxX - 10] {
            fill(CGRect(x: x, y: r.minY, width: 3, height: r.height), color(0.23, 0.25, 0.20, 0.8))
        }
    }
    private func cabinet(_ r: CGRect) {
        fill(r, color(0.30, 0.23, 0.15))
        for i in 0..<2 {
            let door = CGRect(x: r.minX + 5 + CGFloat(i) * (r.width / 2 - 3), y: r.minY + 6, width: r.width / 2 - 8, height: r.height - 12)
            fill(door, color(0.52, 0.38, 0.23))
            c.setStrokeColor(color(0.7, 0.53, 0.32)); c.setLineWidth(2); c.stroke(door.insetBy(dx: 5, dy: 6))
            ellipse(CGRect(x: door.midX, y: door.minY + 17, width: 4, height: 4), color(0.88, 0.69, 0.35))
        }
    }
    private func table(_ r: CGRect) {
        fill(r, color(0.37, 0.27, 0.17)); fill(r.insetBy(dx: 4, dy: 4), color(0.64, 0.49, 0.30))
        for i in 1..<5 { line([CGPoint(x: r.minX + 5, y: r.minY + CGFloat(i) * r.height / 5), CGPoint(x: r.maxX - 5, y: r.minY + CGFloat(i) * r.height / 5)], color(0.35, 0.28, 0.18, 0.45), 1) }
        ellipse(CGRect(x: r.midX - 12, y: r.midY - 12, width: 24, height: 24), cream)
        ellipse(CGRect(x: r.midX - 7, y: r.midY - 7, width: 14, height: 14), color(0.66, 0.40, 0.22))
    }
    private func bed(_ r: CGRect) {
        fill(r, color(0.32, 0.24, 0.16))
        rounded(r.insetBy(dx: 5, dy: 8), radius: 6, color: cream)
        fill(CGRect(x: r.minX + 6, y: r.minY + 9, width: r.width - 12, height: r.height * 0.6), color(0.43, 0.53, 0.45))
        for x in stride(from: r.minX + 10, to: r.maxX - 7, by: 12) {
            line([CGPoint(x: x, y: r.minY + 10), CGPoint(x: x, y: r.minY + r.height * 0.63)], color(0.67, 0.71, 0.55, 0.4), 3)
        }
        rounded(CGRect(x: r.minX + 12, y: r.maxY - 38, width: r.width - 24, height: 25), radius: 8, color: color(0.93, 0.87, 0.69))
    }
    private func borderStones() {
        // Thin worn stones along the world boundary are outside actor clearance.
        for x in stride(from: CGFloat(0), to: 960, by: 23) {
            rounded(CGRect(x: x, y: 472, width: 21, height: 8), radius: 3, color: color(0.47, 0.49, 0.37))
            ellipse(CGRect(x: x, y: 1, width: 17, height: 6), color(0.44, 0.45, 0.32, 0.6))
        }
    }
}
