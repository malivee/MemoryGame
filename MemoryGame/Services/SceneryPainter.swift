// Penjelasan file: SceneryPainter.swift
// Melukis latar dunia dalam perspektif 3/4 oblique bergaya storybook Carto dengan CoreGraphics:
// Rumput kertas hangat (sage/lime), pondok panggung beratap jerami, pohon cemara berlapis,
// semak rimbun dengan buah beri/bunga, pantai & laut biru dalam, serta interior kabin kayu yang kaya detail.
// Menjaga kotak tabrakan PrologueLevel tetap konsisten tanpa mengubah aturan fisika/navigasi.

import CoreGraphics
import Foundation

final class SceneryPainter {
    private var seed: UInt64 = 1937
    private var c: CGContext!

    // Palet warna hangat khas Carto (paper-cutout storybook)
    private let grassLight = CGColor(red: 0.82, green: 0.89, blue: 0.60, alpha: 1)
    private let grassBase  = CGColor(red: 0.77, green: 0.85, blue: 0.53, alpha: 1)
    private let grassDark  = CGColor(red: 0.67, green: 0.77, blue: 0.44, alpha: 1)
    private let creamPath  = CGColor(red: 0.91, green: 0.87, blue: 0.75, alpha: 1)
    private let woodDark   = CGColor(red: 0.32, green: 0.23, blue: 0.16, alpha: 1)
    private let woodWarm   = CGColor(red: 0.56, green: 0.42, blue: 0.26, alpha: 1)
    private let oceanNavy  = CGColor(red: 0.08, green: 0.18, blue: 0.26, alpha: 1)
    private let waterTeal  = CGColor(red: 0.26, green: 0.58, blue: 0.62, alpha: 1)

    // Membuat bitmap peta dalam sudut pandang 3/4 oblique
    func image(level: PrologueLevel, progress: PrologueProgress, scale: CGFloat = 2) -> CGImage? {
        seed = 1937
        guard let context = CGContext(data: nil, width: Int(960 * scale), height: Int(480 * scale),
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        c = context
        c.scaleBy(x: scale, y: scale)

        // Dasar rumput cerah bertekstur kertas
        fill(PrologueLevel.bounds, grassBase)

        if level.region == .house {
            interior()
        } else {
            landscape(level: level, progress: progress)
        }

        // Urutkan rintangan dari atas ke bawah (Y tertinggi ke terendah) untuk depth sorting 3/4
        let sortedObstacles = level.obstacles.sorted { $0.rect.maxY > $1.rect.maxY }
        for obstacle in sortedObstacles {
            paint(obstacle)
        }

        if level.region != .house {
            borderStones()
        }

        // Pencahayaan lembut hangat matahari khas Carto
        c.saveGState()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
            color(1.0, 0.96, 0.82, 0.12),
            color(0.35, 0.55, 0.45, 0.03)
        ] as CFArray, locations: [0, 1])!
        c.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 470), end: CGPoint(x: 880, y: 10), options: [])
        c.restoreGState()

        return c.makeImage()
    }

    private func random() -> CGFloat {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((seed >> 32) & 0xffff) / 65535
    }

    private func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }

    private func fill(_ rect: CGRect, _ color: CGColor) {
        c.setFillColor(color); c.fill(rect)
    }

    private func ellipse(_ rect: CGRect, _ color: CGColor) {
        c.setFillColor(color); c.fillEllipse(in: rect)
    }

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

    // Melukis dasar padang rumput cerah Carto, guratan pensil rumput, jalan tanah, dan bunga liar
    private func landscape(level: PrologueLevel, progress: PrologueProgress) {
        // 1. Sapuan pigmen cat air dan tekstur serat kertas rumput
        for _ in 0..<1800 {
            let x = random() * 960, y = random() * 480
            let v = random()
            ellipse(CGRect(x: x, y: y, width: 14 + random() * 45, height: 6 + random() * 20),
                    color(0.72 + v * 0.16, 0.82 + v * 0.12, 0.49 + v * 0.14, 0.18))
        }

        // 2. Garis pantai tebing dan laut biru tua Carto (seperti screenshot 2)
        if level.region != .village && level.region != .house {
            if progress.lakeVariant == .dryLake {
                // Danau kering / cekungan tanah berpasir
                rounded(CGRect(x: 343, y: 38, width: 244, height: 135), radius: 35, color: color(0.83, 0.76, 0.60))
                for _ in 0..<60 {
                    let x = 353 + random() * 217, y = 45 + random() * 115
                    line([CGPoint(x: x, y: y), CGPoint(x: x + 10, y: y + 8)], color(0.66, 0.58, 0.44, 0.4), 1.2)
                }
            } else {
                // Tebing pesisir dan laut biru Carto (persis seperti screenshot 2)
                cartoOceanCliff(CGRect(x: 830, y: 0, width: 130, height: 480))
            }
        }

        // 3. Jalur jalan tanah berpasir lembut khas Carto
        if level.region == .village {
            trail([CGPoint(x: 0, y: 72), CGPoint(x: 220, y: 82), CGPoint(x: 455, y: 125), CGPoint(x: 740, y: 150), CGPoint(x: 960, y: 145)], width: 46)
            trail([CGPoint(x: 140, y: 0), CGPoint(x: 160, y: 80), CGPoint(x: 245, y: 275), CGPoint(x: 170, y: 365), CGPoint(x: 210, y: 480)], width: 34)
            trail([CGPoint(x: 465, y: 80), CGPoint(x: 470, y: 255), CGPoint(x: 510, y: 420), CGPoint(x: 550, y: 480)], width: 38)
            trail([CGPoint(x: 670, y: 110), CGPoint(x: 700, y: 280), CGPoint(x: 830, y: 310), CGPoint(x: 960, y: 330)], width: 30)

            // Kebun sayur kecil desa dengan pagar pasak kayu
            for row in 0..<3 {
                let rect = CGRect(x: 760, y: 140 + row * 16, width: 136, height: 9)
                rounded(rect, radius: 4, color: color(0.55, 0.46, 0.33, 0.6))
                for col in 0..<11 {
                    flower(CGPoint(x: 768 + col * 12, y: 144 + row * 16), size: 2.0, isBlue: false)
                }
            }
        } else {
            trail([CGPoint(x: 30, y: 100), CGPoint(x: 140, y: 150), CGPoint(x: 245, y: 200), CGPoint(x: 280, y: 370)], width: 38)
            trail([CGPoint(x: 640, y: 65), CGPoint(x: 710, y: 105), CGPoint(x: 790, y: 205), CGPoint(x: 810, y: 370), CGPoint(x: 960, y: 400)], width: 42)
        }

        // Zona jalan modular puzzle
        for zone in level.zones where zone.piece == .oldPath || zone.piece == .villageRoad {
            c.saveGState(); c.clip(to: zone.rect)
            c.translateBy(x: zone.rect.midX, y: zone.rect.midY)
            c.rotate(by: -CGFloat(progress.placement(of: zone.piece)?.turns ?? 0) * .pi / 2)
            trail([CGPoint(x: -zone.rect.width / 2, y: 0), CGPoint(x: zone.rect.width / 2, y: 0)], width: 55)
            c.restoreGState()
        }

        // 4. Guratan rumput krayon kecil (V-shapes dan blade strokes khas Carto)
        for _ in 0..<1200 {
            let x = random() * 960, y = random() * 480
            grassTuft(at: CGPoint(x: x, y: y))
        }

        // 5. Bunga liar mungil (putih dan biru muda seperti di screenshot Carto)
        for _ in 0..<240 {
            let p = CGPoint(x: random() * 960, y: random() * 480)
            if level.obstacles.contains(where: { $0.rect.insetBy(dx: -10, dy: -10).contains(p) }) { continue }
            flower(p, size: 1.4 + random() * 1.2, isBlue: random() > 0.65)
        }
    }

    // Melukis rumpun rumput krayon mungil
    private func grassTuft(at p: CGPoint) {
        let h: CGFloat = 3.5 + random() * 3.0
        let cGrass = color(0.52 + random() * 0.15, 0.68 + random() * 0.12, 0.32 + random() * 0.10, 0.45)
        line([CGPoint(x: p.x - 2.5, y: p.y + h), CGPoint(x: p.x, y: p.y), CGPoint(x: p.x + 2.5, y: p.y + h)], cGrass, 0.9)
    }

    // Melukis jalan tanah dengan transisi lembut ke rumput
    private func trail(_ points: [CGPoint], width: CGFloat) {
        line(points, color(0.70, 0.72, 0.46, 0.4), width + 14)
        line(points, color(0.86, 0.81, 0.68, 0.95), width)
        line(points, color(0.93, 0.89, 0.77, 0.85), width * 0.65)
        for i in 1..<points.count {
            let a = points[i - 1], b = points[i]
            for _ in 0..<Int(hypot(b.x - a.x, b.y - a.y) / 5) {
                let t = random(), side = (random() - 0.5) * width * 0.8
                let p = CGPoint(x: a.x + (b.x - a.x) * t + side * 0.5, y: a.y + (b.y - a.y) * t + side)
                ellipse(CGRect(x: p.x, y: p.y, width: 1.8 + random() * 2.2, height: 1.5), color(0.72, 0.65, 0.50, 0.45))
            }
        }
    }

    // Bunga liar mungil khas Carto (putih dandelion atau biru langit)
    private func flower(_ p: CGPoint, size: CGFloat, isBlue: Bool) {
        let petalColor = isBlue ? color(0.46, 0.68, 0.88, 0.9) : color(0.98, 0.98, 0.94, 0.9)
        line([p, CGPoint(x: p.x, y: p.y - size * 1.8)], color(0.48, 0.62, 0.32, 0.75), 0.9)
        for i in 0..<4 {
            let a = CGFloat(i) * .pi / 2
            ellipse(CGRect(x: p.x + cos(a) * size * 0.8 - size * 0.4,
                           y: p.y + sin(a) * size * 0.8 - size * 0.4,
                           width: size * 0.8, height: size * 0.8), petalColor)
        }
        ellipse(CGRect(x: p.x - size * 0.3, y: p.y - size * 0.3, width: size * 0.6, height: size * 0.6), color(0.95, 0.82, 0.36, 1))
    }

    // Tebing pantai dan laut biru tua Carto (persis seperti screenshot 2)
    private func cartoOceanCliff(_ r: CGRect) {
        // Tepi tebing berpasir krem tipis
        rounded(r, radius: 15, color: color(0.88, 0.84, 0.70))
        // Laut biru dalam Carto
        let sea = r.offsetBy(dx: 16, dy: 0)
        rounded(sea, radius: 10, color: oceanNavy)
        // Riak air toska dan gelombang putih
        for i in 0..<22 {
            let y = r.minY + CGFloat(i) * 22 + random() * 8
            let x = sea.minX + 6 + random() * 70
            line([CGPoint(x: x, y: y), CGPoint(x: x + 8, y: y + 2), CGPoint(x: x + 16, y: y)], color(0.45, 0.75, 0.78, 0.5), 1.6)
            line([CGPoint(x: x + 2, y: y + 1), CGPoint(x: x + 8, y: y + 2.5)], color(1, 1, 1, 0.55), 1.0)
        }
    }

    // Interior kabin kayu Carto (persis seperti screenshot 3):
    // Dinding balok kayu dengan untaian kalung bulu/taring, karpet anyaman Aztec, bantal kayu, dan pot sup
    private func interior() {
        // Latar gelap di luar ruangan kabin (seperti screenshot 3)
        fill(PrologueLevel.bounds, color(0.12, 0.16, 0.20))

        // Lantai kayu papan hangat
        let floorRect = CGRect(x: 60, y: 15, width: 840, height: 410)
        rounded(floorRect, radius: 14, color: color(0.91, 0.83, 0.68))

        // Garis-garis papan lantai horizontal
        for row in 0..<18 {
            let y = floorRect.minY + CGFloat(row) * (floorRect.height / 18)
            line([CGPoint(x: floorRect.minX + 2, y: y), CGPoint(x: floorRect.maxX - 2, y: y)], color(0.72, 0.62, 0.46, 0.5), 1.0)
        }

        // Pintu masuk di sebelah kiri dengan sorot cahaya luar
        let doorPath = CGMutablePath()
        doorPath.move(to: CGPoint(x: floorRect.minX - 10, y: 280))
        doorPath.addLine(to: CGPoint(x: floorRect.minX + 35, y: 240))
        doorPath.addLine(to: CGPoint(x: floorRect.minX + 35, y: 120))
        doorPath.addLine(to: CGPoint(x: floorRect.minX - 10, y: 100))
        doorPath.closeSubpath()
        c.setFillColor(color(0.98, 0.94, 0.78, 0.45))
        c.addPath(doorPath); c.fillPath()

        // Dinding belakang kayu tegak (balok kayu vertikal Carto)
        let wallHeight: CGFloat = 85
        let wallY = floorRect.maxY - 15
        let wallRect = CGRect(x: floorRect.minX - 8, y: wallY, width: floorRect.width + 16, height: wallHeight)
        rounded(wallRect, radius: 8, color: color(0.48, 0.38, 0.26))

        // Tiang kayu vertikal di dinding
        let beamCount = 16
        for b in 0..<beamCount {
            let bx = wallRect.minX + CGFloat(b) * (wallRect.width / CGFloat(beamCount))
            fill(CGRect(x: bx, y: wallRect.minY, width: 6, height: wallHeight), woodDark)
        }

        // Balok kayu penyangga miring (diagonal timber braces)
        line([CGPoint(x: wallRect.minX + 120, y: wallRect.minY), CGPoint(x: wallRect.minX + 220, y: wallRect.maxY)], woodDark, 8)
        line([CGPoint(x: wallRect.maxX - 120, y: wallRect.minY), CGPoint(x: wallRect.maxX - 220, y: wallRect.maxY)], woodDark, 8)

        // Untaian kalung hiasan bulu/taring putih menggantung di dinding (seperti screenshot 3)
        for g in 0..<2 {
            let startX = wallRect.minX + 240 + CGFloat(g) * 220
            let endX = startX + 180
            let midY = wallRect.minY + 25
            let topY = wallRect.minY + 60

            let garlandPath = CGMutablePath()
            garlandPath.move(to: CGPoint(x: startX, y: topY))
            garlandPath.addQuadCurve(to: CGPoint(x: endX, y: topY), control: CGPoint(x: (startX + endX) / 2, y: midY))
            c.setStrokeColor(color(0.85, 0.75, 0.50, 0.8)); c.setLineWidth(1.8)
            c.addPath(garlandPath); c.strokePath()

            // Liontin bulu putih segitiga
            for p in 0..<7 {
                let px = startX + CGFloat(p) * 24 + 12
                let py = midY + CGFloat(abs(p - 3)) * 4 + 4
                let tooth = CGMutablePath()
                tooth.move(to: CGPoint(x: px - 3, y: py))
                tooth.addLine(to: CGPoint(x: px + 3, y: py))
                tooth.addLine(to: CGPoint(x: px, y: py - 9))
                tooth.closeSubpath()
                c.setFillColor(color(0.96, 0.95, 0.90)); c.addPath(tooth); c.fillPath()
            }
        }

        // Karpet anyaman suku Aztec besar di tengah (seperti screenshot 3)
        let rug = CGRect(x: 330, y: 135, width: 280, height: 185)
        rounded(rug, radius: 10, color: color(0.88, 0.71, 0.40))
        rounded(rug.insetBy(dx: 12, dy: 12), radius: 6, color: color(0.96, 0.91, 0.78))
        // Motif rumbai karpet di sekeliling
        c.setStrokeColor(color(0.68, 0.48, 0.25, 0.8)); c.setLineWidth(2.5)
        c.stroke(rug.insetBy(dx: 6, dy: 6))

        // Bantal bulat potongan kayu (tree-stump cushions di sekitar karpet seperti screenshot 3)
        let stoolPositions = [
            CGPoint(x: 290, y: 220),
            CGPoint(x: 295, y: 130),
            CGPoint(x: 645, y: 235),
            CGPoint(x: 640, y: 140)
        ]
        for sp in stoolPositions {
            ellipse(CGRect(x: sp.x - 14, y: sp.y - 10, width: 28, height: 20), color(0.35, 0.25, 0.17))
            ellipse(CGRect(x: sp.x - 12, y: sp.y - 8, width: 24, height: 16), color(0.55, 0.40, 0.26))
            // Cincin kayu konsentris
            ellipse(CGRect(x: sp.x - 6, y: sp.y - 4, width: 12, height: 8), color(0.40, 0.28, 0.18))
        }

        // Tanaman hias dalam pot anyaman di sudut kiri bawah (seperti screenshot 3)
        let plantPot = CGRect(x: 95, y: 40, width: 28, height: 24)
        rounded(plantPot, radius: 5, color: color(0.56, 0.40, 0.24))
        // Daun-daun hijau runcing
        for leaf in 0..<5 {
            let la = CGFloat(leaf) * .pi / 4 + .pi / 8
            line([CGPoint(x: plantPot.midX, y: plantPot.maxY),
                  CGPoint(x: plantPot.midX + cos(la) * 22, y: plantPot.maxY + sin(la) * 26)], color(0.24, 0.52, 0.32), 4)
        }
    }

    // Melukis rintangan dalam perspektif 3/4 front projection Carto
    private func paint(_ obstacle: WorldObstacle) {
        let r = obstacle.rect
        c.saveGState()

        // Bayangan lembut di bawah kaki rintangan
        let shadowRect = CGRect(x: r.minX - 3, y: r.minY - 4, width: r.width + 6, height: min(16, r.height * 0.4))
        ellipse(shadowRect, color(0.18, 0.24, 0.14, 0.24))

        switch obstacle.kind {
        case "Rumah":
            cottage(r)
        case "Pohon":
            pineTree(r)
        case "Pagar tanaman":
            bushHedge(r)
        case "Batu", "Dinding batu":
            rocks(r, wall: obstacle.kind == "Dinding batu")
        case "Air":
            water(r)
        case "Tempat tidur":
            bed(r)
        case "Lemari":
            cabinet(r)
        case "Meja":
            table(r)
        default:
            crate(r)
        }
        c.restoreGState()
    }

    // Pondok panggung beratap jerami tebal khas Carto (seperti screenshot 1)
    private func cottage(_ r: CGRect) {
        let groundY = r.minY
        let wallHeight: CGFloat = r.height * 0.45

        // 1. Tiang panggung kayu di bagian bawah
        let stiltColor = woodDark
        fill(CGRect(x: r.minX + 8, y: groundY, width: 6, height: wallHeight * 0.65), stiltColor)
        fill(CGRect(x: r.maxX - 14, y: groundY, width: 6, height: wallHeight * 0.65), stiltColor)
        fill(CGRect(x: r.midX - 3, y: groundY, width: 6, height: wallHeight * 0.65), stiltColor)

        // Tangga kayu kecil di depan menuju pintu (persis seperti di Carto)
        let ladderX = r.midX + 16
        line([CGPoint(x: ladderX, y: groundY), CGPoint(x: ladderX + 6, y: groundY + wallHeight * 0.7)], woodWarm, 2.5)
        line([CGPoint(x: ladderX + 10, y: groundY), CGPoint(x: ladderX + 16, y: groundY + wallHeight * 0.7)], woodWarm, 2.5)
        for s in 0..<3 {
            let sy = groundY + CGFloat(s) * 6 + 3
            line([CGPoint(x: ladderX + CGFloat(s) * 2, y: sy), CGPoint(x: ladderX + 10 + CGFloat(s) * 2, y: sy)], woodWarm, 2)
        }

        // Guci tanah liat kecil di sebelah kiri tiang
        ellipse(CGRect(x: r.minX - 4, y: groundY, width: 12, height: 14), color(0.42, 0.35, 0.30))
        ellipse(CGRect(x: r.minX - 2, y: groundY + 11, width: 8, height: 4), color(0.28, 0.22, 0.18))

        // 2. Dinding papan kayu rumah panggung
        let wallRect = CGRect(x: r.minX + 4, y: groundY + wallHeight * 0.4, width: r.width - 8, height: wallHeight)
        rounded(wallRect, radius: 4, color: color(0.68, 0.54, 0.38))
        for col in 1..<5 {
            let px = wallRect.minX + CGFloat(col) * (wallRect.width / 5)
            line([CGPoint(x: px, y: wallRect.minY), CGPoint(x: px, y: wallRect.maxY)], color(0.48, 0.36, 0.24, 0.5), 1.2)
        }

        // Pintu masuk anyaman bermotif toska (seperti Carto)
        let door = CGRect(x: r.midX - 10, y: wallRect.minY + 2, width: 18, height: wallHeight * 0.9)
        rounded(door, radius: 5, color: color(0.24, 0.55, 0.52))
        line([CGPoint(x: door.midX, y: door.maxY - 4), CGPoint(x: door.minX + 2, y: door.minY + 4)], color(0.85, 0.82, 0.55), 1.2)
        line([CGPoint(x: door.midX, y: door.maxY - 4), CGPoint(x: door.maxX - 2, y: door.minY + 4)], color(0.85, 0.82, 0.55), 1.2)

        // 3. Atap Jerami Tebal (Thatched Roof Carto)
        let roofBottom = wallRect.maxY - 4
        let roofTop = r.maxY + 12
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: r.minX - 8, y: roofBottom))
        roofPath.addLine(to: CGPoint(x: r.midX, y: roofTop))
        roofPath.addLine(to: CGPoint(x: r.maxX + 8, y: roofBottom))
        roofPath.closeSubpath()

        c.setFillColor(color(0.82, 0.66, 0.40))
        c.addPath(roofPath); c.fillPath()

        let strawDark = color(0.60, 0.46, 0.26, 0.8)
        let strawLight = color(0.92, 0.80, 0.55, 0.8)

        for row in 0..<4 {
            let progress = CGFloat(row) / 4.0
            let y = roofBottom + progress * (roofTop - roofBottom) * 0.85
            let w = (r.width + 16) * (1.0 - progress * 0.65)
            let x = r.midX - w / 2

            line([CGPoint(x: x, y: y), CGPoint(x: x + w, y: y)], strawDark, 2.5)
            for i in 0..<Int(w / 7) {
                let sx = x + CGFloat(i) * 7 + random() * 2
                line([CGPoint(x: sx, y: y - 1), CGPoint(x: sx + random() * 3 - 1.5, y: y + 9)], strawLight, 1.0)
            }
        }
    }

    // Pohon Cemara / Pinus berlapis khas Carto (seperti screenshot 2)
    private func pineTree(_ r: CGRect) {
        let trunkWidth: CGFloat = 8
        let trunkHeight: CGFloat = r.height * 0.32
        rounded(CGRect(x: r.midX - trunkWidth / 2, y: r.minY, width: trunkWidth, height: trunkHeight),
                radius: 2, color: woodDark)

        let layers = 4
        let topY = r.maxY + 18
        let bottomY = r.minY + trunkHeight * 0.65
        let totalH = topY - bottomY

        for layer in 0..<layers {
            let lProgress = CGFloat(layer) / CGFloat(layers)
            let ly = bottomY + lProgress * totalH * 0.72
            let lh = totalH * 0.45
            let lw = (r.width + 12) * (1.0 - lProgress * 0.24)
            let lx = r.midX - lw / 2

            let tierPath = CGMutablePath()
            tierPath.move(to: CGPoint(x: lx, y: ly))
            tierPath.addLine(to: CGPoint(x: r.midX, y: ly + lh))
            tierPath.addLine(to: CGPoint(x: lx + lw, y: ly))
            tierPath.closeSubpath()

            let v = CGFloat(layer) * 0.05
            c.setFillColor(color(0.20 + v, 0.38 + v * 1.2, 0.22 + v, 0.95))
            c.addPath(tierPath); c.fillPath()

            let needleColor = color(0.35 + v * 1.1, 0.56 + v * 1.1, 0.30 + v, 0.85)
            for s in 0..<Int(lw / 4.5) {
                let nx = lx + CGFloat(s) * 4.5 + 2
                line([CGPoint(x: nx, y: ly + 1), CGPoint(x: nx, y: ly + lh * 0.65)], needleColor, 1.1)
            }
        }
    }

    // Semak rimbun Carto dengan tekstur garis vertikal dan buah beri/bunga (seperti screenshot 1 & 2)
    private func bushHedge(_ r: CGRect) {
        // Pasak kayu pagar pembatas
        let stakeCount = max(2, Int(r.width / 22))
        for i in 0..<stakeCount {
            let sx = r.minX + CGFloat(i) * (r.width / CGFloat(stakeCount - 1))
            rounded(CGRect(x: sx - 2, y: r.minY, width: 4, height: r.height * 0.5), radius: 1, color: woodDark)
            if i > 0 {
                let prevX = r.minX + CGFloat(i - 1) * (r.width / CGFloat(stakeCount - 1))
                line([CGPoint(x: prevX, y: r.minY + r.height * 0.35), CGPoint(x: sx, y: r.minY + r.height * 0.35)], color(0.25, 0.20, 0.15, 0.7), 1.2)
            }
        }

        // Gundukan semak bulat hijau berlapis khas Carto
        let clumpCount = max(2, Int(r.width / 18))
        for i in 0..<clumpCount {
            let cx = r.minX + CGFloat(i) * (r.width / CGFloat(clumpCount)) + 8
            let cy = r.minY + r.height * 0.25
            let cw: CGFloat = 20 + random() * 8
            let ch: CGFloat = r.height * 0.75 + random() * 6

            let bushRect = CGRect(x: cx - cw / 2, y: cy, width: cw, height: ch)
            ellipse(bushRect, color(0.30, 0.52, 0.26, 0.95))

            // Garis-garis kontur daun vertikal Carto
            let cLine = color(0.44, 0.66, 0.34, 0.85)
            for step in 1...3 {
                let inset = CGFloat(step) * 2.8
                let inner = bushRect.insetBy(dx: inset, dy: inset * 0.8)
                c.setStrokeColor(cLine); c.setLineWidth(1.1)
                c.strokeEllipse(in: inner)
            }

            // Buah beri oranye cerah atau bunga putih (seperti screenshot 2)
            if random() > 0.4 {
                let berryColor = random() > 0.5 ? color(0.95, 0.55, 0.18) : color(0.98, 0.98, 0.94)
                for _ in 0..<3 {
                    ellipse(CGRect(x: cx + random() * 10 - 5, y: cy + ch * 0.6 + random() * (ch * 0.3), width: 3.5, height: 3.5), berryColor)
                }
            }
        }
    }

    // Bebatuan sungai lembut berbatu & dinding batu mortar Carto
    private func rocks(_ r: CGRect, wall: Bool) {
        if !wall {
            let rockRect = CGRect(x: r.minX + 2, y: r.minY, width: r.width - 4, height: r.height * 0.85)
            rounded(rockRect, radius: min(rockRect.width, rockRect.height) * 0.45, color: color(0.60, 0.62, 0.56))
            rounded(rockRect.insetBy(dx: 4, dy: 4).offsetBy(dx: -2, dy: 3), radius: 6, color: color(0.74, 0.76, 0.70, 0.8))
            rounded(CGRect(x: rockRect.minX + 4, y: rockRect.maxY - 8, width: rockRect.width - 8, height: 7),
                    radius: 3, color: color(0.48, 0.62, 0.35, 0.85))
        } else {
            let rowH: CGFloat = 11
            for row in 0..<Int(r.height / rowH + 1) {
                for col in 0..<Int(r.width / 22 + 1) {
                    let x = r.minX + CGFloat(col) * 22 - CGFloat(row % 2) * 11
                    let y = r.minY + CGFloat(row) * rowH
                    let v = random()
                    rounded(CGRect(x: x + 1, y: y + 1, width: 20, height: rowH - 2), radius: 3,
                            color: color(0.55 + v * 0.12, 0.57 + v * 0.10, 0.52 + v * 0.08))
                }
            }
        }
    }

    // Air danau / sungai tenang dengan riak busa
    private func water(_ r: CGRect) {
        rounded(r, radius: 14, color: color(0.28, 0.58, 0.62))
        rounded(r.insetBy(dx: 3, dy: 3), radius: 11, color: color(0.34, 0.66, 0.68))
        for _ in 0..<18 {
            let x = r.minX + 6 + random() * (r.width - 24)
            let y = r.minY + 4 + random() * (r.height - 8)
            line([CGPoint(x: x, y: y), CGPoint(x: x + 8, y: y + 1.5), CGPoint(x: x + 16, y: y)], color(1, 1, 1, 0.45), 1.2)
        }
    }

    // Tempat tidur kabin kayu Carto
    private func bed(_ r: CGRect) {
        rounded(r, radius: 6, color: woodDark)
        let mattress = r.insetBy(dx: 4, dy: 6)
        rounded(mattress, radius: 4, color: color(0.96, 0.94, 0.88))
        // Selimut bermotif toska berlipat
        let blanket = CGRect(x: mattress.minX, y: mattress.minY, width: mattress.width, height: mattress.height * 0.65)
        rounded(blanket, radius: 3, color: color(0.35, 0.60, 0.58))
        // Bantal putih lembut di atas
        rounded(CGRect(x: mattress.minX + 4, y: mattress.maxY - 14, width: mattress.width - 8, height: 12),
                radius: 4, color: color(0.98, 0.98, 0.98))
    }

    // Lemari rak kayu sudut bertingkat (seperti screenshot 3)
    private func cabinet(_ r: CGRect) {
        rounded(r, radius: 4, color: woodDark)
        // Rak terbuka 3 tingkat
        let shelfH = r.height / 3
        for i in 0..<3 {
            let shelfRect = CGRect(x: r.minX + 4, y: r.minY + CGFloat(i) * shelfH + 3, width: r.width - 8, height: shelfH - 5)
            rounded(shelfRect, radius: 2, color: woodWarm)
            // Gulungan kain / selimut di rak
            rounded(CGRect(x: shelfRect.minX + 3, y: shelfRect.minY + 2, width: shelfRect.width - 6, height: shelfRect.height - 4),
                    radius: 2, color: color(0.78, 0.68, 0.52))
        }
    }

    // Meja rendah dengan panci rebusan sup Carto (seperti screenshot 3)
    private func table(_ r: CGRect) {
        rounded(r, radius: 6, color: woodWarm)
        rounded(r.insetBy(dx: 4, dy: 4), radius: 4, color: color(0.72, 0.56, 0.38))

        // Panci rebusan sup panas (cooking pot) di atas meja
        let pot = CGRect(x: r.midX - 16, y: r.midY - 12, width: 32, height: 24)
        ellipse(pot, color(0.24, 0.32, 0.38))
        // Kaldu sup oranye keemasan di dalam panci
        ellipse(pot.insetBy(dx: 4, dy: 4), color(0.92, 0.55, 0.18))

        // Dua mangkuk kecil di samping panci
        ellipse(CGRect(x: pot.minX - 12, y: pot.midY - 4, width: 10, height: 8), color(0.24, 0.32, 0.38))
        ellipse(CGRect(x: pot.maxX + 2, y: pot.midY - 4, width: 10, height: 8), color(0.24, 0.32, 0.38))
    }

    // Peti kayu
    private func crate(_ r: CGRect) {
        rounded(r, radius: 3, color: woodDark)
        rounded(r.insetBy(dx: 3, dy: 3), radius: 2, color: woodWarm)
        line([CGPoint(x: r.minX + 4, y: r.minY + 4), CGPoint(x: r.maxX - 4, y: r.maxY - 4)], woodDark, 2)
        line([CGPoint(x: r.minX + 4, y: r.maxY - 4), CGPoint(x: r.maxX - 4, y: r.minY + 4)], woodDark, 2)
    }

    private func borderStones() {
        for x in stride(from: CGFloat(0), to: 960, by: 25) {
            rounded(CGRect(x: x, y: 472, width: 20, height: 7), radius: 3, color: color(0.60, 0.65, 0.48))
            ellipse(CGRect(x: x, y: 1, width: 18, height: 5), color(0.58, 0.62, 0.46, 0.65))
        }
    }
}
