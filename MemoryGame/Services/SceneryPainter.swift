// Penjelasan file: SceneryPainter.swift
// Melukis latar dunia dalam perspektif 3/4 oblique bergaya storybook Carto dengan CoreGraphics:
// Interior kabin kayu hangat (dinding balok, untaian kalung taring/bulu, kapak tertancap, karpet Aztec,
// Ibu merajut, bantal tunggul kayu, meja sup mengepul, matras tidur wol, tanaman hias, cahaya pintu),
// serta lanskap luar ruangan (rumput kertas sage/lime dengan arsir pensil vertikal rapat,
// pondok panggung beratap jerami tebal dengan tunggul kapak & jemuran kulit hewan,
// pohon cemara kerucut ramping ber-chevron putih, semak beri oranye, dan pantai bertebing).
// Menjaga kotak tabrakan PrologueLevel tetap 100% konsisten tanpa mengubah aturan fisika/navigasi.

import CoreGraphics
import Foundation

final class SceneryPainter {
    private var seed: UInt64 = 1937
    private var c: CGContext!

    // Palet warna hangat khas Carto (paper-cutout storybook)
    private let grassBase  = CGColor(red: 0.76, green: 0.84, blue: 0.49, alpha: 1) // #C2D67D sage-lime
    private let grassLight = CGColor(red: 0.83, green: 0.90, blue: 0.58, alpha: 1)
    private let grassDark  = CGColor(red: 0.65, green: 0.75, blue: 0.40, alpha: 1)
    private let woodDark   = CGColor(red: 0.29, green: 0.20, blue: 0.14, alpha: 1)
    private let woodWarm   = CGColor(red: 0.54, green: 0.39, blue: 0.25, alpha: 1)
    private let woodLight  = CGColor(red: 0.74, green: 0.59, blue: 0.41, alpha: 1)
    private let oceanNavy  = CGColor(red: 0.08, green: 0.16, blue: 0.24, alpha: 1)

    // Membuat bitmap peta dalam sudut pandang 3/4 oblique
    func image(level: PrologueLevel, progress: PrologueProgress, scale: CGFloat = 2) -> CGImage? {
        seed = 1937
        guard let context = CGContext(data: nil, width: Int(level.mapBounds.width * scale), height: Int(level.mapBounds.height * scale),
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        c = context
        c.scaleBy(x: scale, y: scale)

        if level.region == .house {
            interior()
        } else {
            fill(level.mapBounds, grassBase)
            landscape(level: level, progress: progress)

            // Urutkan rintangan dari atas ke bawah (Y tertinggi ke terendah) untuk depth sorting 3/4
            let sortedObstacles = level.obstacles.sorted { $0.rect.maxY > $1.rect.maxY }
            for obstacle in sortedObstacles {
                paint(obstacle)
            }
            borderStones()

            // Pencahayaan lembut hangat matahari khas Carto
            c.saveGState()
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
                color(1.0, 0.97, 0.84, 0.10),
                color(0.35, 0.55, 0.45, 0.02)
            ] as CFArray, locations: [0, 1])!
            c.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 470), end: CGPoint(x: 880, y: 10), options: [])
            c.restoreGState()
        }

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

    private func polygon(_ points: [CGPoint], _ color: CGColor) {
        guard let first = points.first else { return }
        let path = CGMutablePath()
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()
        c.setFillColor(color); c.addPath(path); c.fillPath()
    }

    // =========================================================================
    // MARK: - 1. INTERIOR KABIN KAYU CARTO (PERSIS SEPERTI SCREENSHOT 1)
    // =========================================================================
    private func interior() {
        // 1. Latar luar ruangan cutaway: slate navy/charcoal gelap (#152026)
        fill(PrologueLevel.bounds, color(0.08, 0.12, 0.15))

        // 2. Lantai papan kayu hangat dengan bentuk cutaway bersudut
        let floorPoints: [CGPoint] = [
            CGPoint(x: 90, y: 380),   // Kiri atas bawah dinding
            CGPoint(x: 895, y: 380),  // Kanan atas
            CGPoint(x: 910, y: 15),   // Kanan bawah
            CGPoint(x: 65, y: 15)     // Kiri bawah
        ]
        polygon(floorPoints, color(0.91, 0.84, 0.72)) // Dasar kayu pinus hangat

        // Garis papan lantai horizontal dan serat halus kayu
        let plankRows = 22
        for r in 0..<plankRows {
            let t = CGFloat(r) / CGFloat(plankRows)
            let y = 15 + t * (380 - 15)
            let lx = 65 + t * (90 - 65)
            let rx = 910 + t * (895 - 910)

            // Garis pembatas papan
            line([CGPoint(x: lx, y: y), CGPoint(x: rx, y: y)], color(0.76, 0.68, 0.54, 0.65), 1.1)

            // Garis goresan serat kayu alami di sepanjang papan
            for _ in 0..<6 {
                let gx = lx + random() * (rx - lx - 40)
                let gw = 15 + random() * 35
                line([CGPoint(x: gx, y: y + 4 + random() * 8), CGPoint(x: gx + gw, y: y + 4 + random() * 8)],
                     color(0.68, 0.59, 0.45, 0.28), 0.8)
            }
        }

        // Tepi kertas potong / cutaway agak bergerigi di sisi kanan & bawah
        for s in stride(from: CGFloat(15), to: 380, by: 16) {
            let rx = 910 + (s / 380) * (895 - 910)
            line([CGPoint(x: rx - 2, y: s), CGPoint(x: rx + 3, y: s + 8)], color(0.18, 0.22, 0.22, 0.5), 1.5)
        }

        // 3. Dinding kayu tegak di bagian atas (balok kayu vertikal Carto)
        let wallTop: CGFloat = 465
        let wallBottom: CGFloat = 375
        let wallLeft: CGFloat = 80
        let wallRight: CGFloat = 905

        // Balok-balok kayu vertikal dinding dengan variasi warna kayu hangat alami
        let logWidth: CGFloat = 28
        var currentX = wallLeft
        while currentX < wallRight {
            let w = min(logWidth, wallRight - currentX)
            let v = random()
            let logColor = color(0.48 + v * 0.12, 0.38 + v * 0.10, 0.26 + v * 0.08)
            fill(CGRect(x: currentX, y: wallBottom, width: w, height: wallTop - wallBottom), logColor)

            // Garis alur vertikal pada balok
            line([CGPoint(x: currentX + 1, y: wallBottom), CGPoint(x: currentX + 1, y: wallTop)],
                 color(0.24, 0.18, 0.12, 0.75), 1.4)
            for _ in 0..<2 {
                let gLineX = currentX + 6 + random() * (w - 12)
                line([CGPoint(x: gLineX, y: wallBottom + random() * 20),
                      CGPoint(x: gLineX, y: wallTop - random() * 20)],
                     color(0.32, 0.24, 0.16, 0.35), 0.9)
            }
            currentX += w
        }

        // Balok kayu penyangga miring (diagonal timber braces)
        line([CGPoint(x: wallLeft + 40, y: wallBottom), CGPoint(x: wallLeft + 160, y: wallTop)], woodDark, 9)
        line([CGPoint(x: wallRight - 40, y: wallBottom), CGPoint(x: wallRight - 160, y: wallTop)], woodDark, 9)
        line([CGPoint(x: 235, y: wallBottom), CGPoint(x: 235, y: wallTop)], woodDark, 10)

        // Kapak tangan penebang kayu tertancap di balok kayu vertikal (seperti screenshot 1)
        let axeX: CGFloat = 242
        let axeY: CGFloat = 385
        // Mata kapak perak tertancap
        let axeHead = CGMutablePath()
        axeHead.move(to: CGPoint(x: axeX - 4, y: axeY + 6))
        axeHead.addLine(to: CGPoint(x: axeX + 10, y: axeY + 12))
        axeHead.addLine(to: CGPoint(x: axeX + 8, y: axeY - 6))
        axeHead.closeSubpath()
        c.setFillColor(color(0.82, 0.86, 0.88)); c.addPath(axeHead); c.fillPath()
        // Gagang kayu miring ke bawah
        line([CGPoint(x: axeX + 6, y: axeY + 8), CGPoint(x: axeX + 26, y: axeY - 14)], woodWarm, 3.5)

        // Untaian kalung bulu/taring putih menggantung di dinding dalam 2 lengkungan U (seperti screenshot 1)
        let garlands = [
            (startX: CGFloat(330), midX: CGFloat(430), endX: CGFloat(530), topY: CGFloat(445), dipY: CGFloat(395)),
            (startX: CGFloat(480), midX: CGFloat(585), endX: CGFloat(690), topY: CGFloat(445), dipY: CGFloat(400))
        ]
        for g in garlands {
            let rope = CGMutablePath()
            rope.move(to: CGPoint(x: g.startX, y: g.topY))
            rope.addQuadCurve(to: CGPoint(x: g.endX, y: g.topY), control: CGPoint(x: g.midX, y: g.dipY))
            c.setStrokeColor(color(0.88, 0.78, 0.52, 0.9)); c.setLineWidth(2.0)
            c.addPath(rope); c.strokePath()

            // Liontin taring/bulu putih menggantung di sepanjang tali kalung
            let teethCount = 9
            for i in 0..<teethCount {
                let t = CGFloat(i + 1) / CGFloat(teethCount + 1)
                // Posisi kurva kuadratik Bezier
                let tx = (1 - t) * (1 - t) * g.startX + 2 * (1 - t) * t * g.midX + t * t * g.endX
                let ty = (1 - t) * (1 - t) * g.topY + 2 * (1 - t) * t * g.dipY + t * t * g.topY

                // Manik-manik emas kecil
                ellipse(CGRect(x: tx - 2, y: ty - 1, width: 4, height: 4), color(0.92, 0.78, 0.38))

                // Gigi/bulu putih melengkung runcing
                let tooth = CGMutablePath()
                tooth.move(to: CGPoint(x: tx - 3.5, y: ty - 1))
                tooth.addLine(to: CGPoint(x: tx + 3.5, y: ty - 1))
                tooth.addQuadCurve(to: CGPoint(x: tx, y: ty - 14), control: CGPoint(x: tx + 4, y: ty - 8))
                tooth.addQuadCurve(to: CGPoint(x: tx - 3.5, y: ty - 1), control: CGPoint(x: tx - 2, y: ty - 8))
                tooth.closeSubpath()
                c.setFillColor(color(0.96, 0.95, 0.90)); c.addPath(tooth); c.fillPath()
            }
        }

        // 4. Bukaan pintu kiri dengan sorot cahaya luar ruangan (seperti screenshot 1)
        let doorPath = CGMutablePath()
        doorPath.move(to: CGPoint(x: 95, y: 340))
        doorPath.addLine(to: CGPoint(x: 75, y: 190))
        doorPath.addLine(to: CGPoint(x: 110, y: 195))
        doorPath.addLine(to: CGPoint(x: 120, y: 340))
        doorPath.closeSubpath()
        // Pemandangan rumput hijau terang di luar pintu
        c.setFillColor(color(0.72, 0.84, 0.45)); c.addPath(doorPath); c.fillPath()

        // Sorot sinar matahari hangat masuk ke dalam ruangan
        let beamPath = CGMutablePath()
        beamPath.move(to: CGPoint(x: 105, y: 330))
        beamPath.addLine(to: CGPoint(x: 195, y: 285))
        beamPath.addLine(to: CGPoint(x: 165, y: 180))
        beamPath.addLine(to: CGPoint(x: 90, y: 190))
        beamPath.closeSubpath()
        c.setFillColor(color(0.98, 0.95, 0.75, 0.35)); c.addPath(beamPath); c.fillPath()

        // 5. Lemari rak sudut kayu bertingkat di kiri atas (seperti screenshot 1)
        let shelfRect = CGRect(x: 140, y: 300, width: 85, height: 115)
        rounded(shelfRect, radius: 4, color: color(0.38, 0.28, 0.18))
        rounded(shelfRect.insetBy(dx: 3, dy: 3), radius: 3, color: color(0.60, 0.46, 0.32))
        // Rak bertingkat
        let sH = shelfRect.height / 3
        for s in 0..<3 {
            let sy = shelfRect.minY + CGFloat(s) * sH
            line([CGPoint(x: shelfRect.minX + 3, y: sy), CGPoint(x: shelfRect.maxX - 3, y: sy)], woodDark, 2.5)
            // Kain gulung / anyaman bermotif
            if s == 1 {
                rounded(CGRect(x: shelfRect.minX + 8, y: sy + 4, width: shelfRect.width - 16, height: sH - 9),
                        radius: 3, color: color(0.85, 0.76, 0.60))
            } else if s == 0 {
                rounded(CGRect(x: shelfRect.minX + 10, y: sy + 4, width: 28, height: sH - 9),
                        radius: 3, color: color(0.75, 0.65, 0.50))
                rounded(CGRect(x: shelfRect.minX + 44, y: sy + 4, width: 24, height: sH - 9),
                        radius: 3, color: color(0.50, 0.40, 0.32))
            }
        }
        // Topeng / tengkorak hewan buruan berukir di atas rak paling atas (seperti screenshot 1)
        let skullCenter = CGPoint(x: shelfRect.midX, y: shelfRect.maxY + 10)
        ellipse(CGRect(x: skullCenter.x - 14, y: skullCenter.y - 12, width: 28, height: 24), color(0.24, 0.20, 0.18))
        ellipse(CGRect(x: skullCenter.x - 10, y: skullCenter.y - 8, width: 20, height: 18), color(0.72, 0.68, 0.62))
        // Lubang mata hitam topeng
        ellipse(CGRect(x: skullCenter.x - 7, y: skullCenter.y - 2, width: 5, height: 5), color(0.15, 0.15, 0.15))
        ellipse(CGRect(x: skullCenter.x + 2, y: skullCenter.y - 2, width: 5, height: 5), color(0.15, 0.15, 0.15))

        // 6. Lemari laci kayu di sisi kanan dinding (seperti screenshot 1)
        let chestRect = CGRect(x: 595, y: 315, width: 95, height: 80)
        rounded(chestRect, radius: 5, color: color(0.38, 0.28, 0.18))
        rounded(chestRect.insetBy(dx: 4, dy: 4), radius: 4, color: color(0.68, 0.54, 0.38))
        // Garis laci dan kenop laci bulat
        for d in 1...2 {
            let dy = chestRect.minY + CGFloat(d) * (chestRect.height / 3)
            line([CGPoint(x: chestRect.minX + 6, y: dy), CGPoint(x: chestRect.maxX - 6, y: dy)], woodDark, 1.8)
            ellipse(CGRect(x: chestRect.midX - 3, y: dy + 8, width: 6, height: 6), color(0.30, 0.22, 0.15))
        }

        // 6b. Meja pajangan buku kuno di pojok kanan atas (sejajar dengan posisi level.book di 870, 360)
        let bookDesk = CGRect(x: 840, y: 335, width: 60, height: 48)
        rounded(bookDesk, radius: 4, color: color(0.38, 0.28, 0.18))
        rounded(bookDesk.insetBy(dx: 3, dy: 3), radius: 3, color: color(0.68, 0.54, 0.38))
        line([CGPoint(x: bookDesk.minX + 4, y: bookDesk.minY + 6), CGPoint(x: bookDesk.maxX - 4, y: bookDesk.minY + 6)], woodDark, 1.4)

        // 7. Karpet anyaman suku Aztec besar di tengah ruangan (seperti screenshot 1)
        let rugRect = CGRect(x: 165, y: 105, width: 280, height: 215)
        // Rumbai-rumbai benang wol putih/krem di sekeliling luar karpet
        for fx in stride(from: rugRect.minX - 4, to: rugRect.maxX + 4, by: 6) {
            line([CGPoint(x: fx, y: rugRect.maxY), CGPoint(x: fx + random() * 2 - 1, y: rugRect.maxY + 7)],
                 color(0.92, 0.88, 0.76), 1.2)
            line([CGPoint(x: fx, y: rugRect.minY), CGPoint(x: fx + random() * 2 - 1, y: rugRect.minY - 7)],
                 color(0.92, 0.88, 0.76), 1.2)
        }
        for fy in stride(from: rugRect.minY - 4, to: rugRect.maxY + 4, by: 6) {
            line([CGPoint(x: rugRect.minX, y: fy), CGPoint(x: rugRect.minX - 7, y: fy + random() * 2 - 1)],
                 color(0.92, 0.88, 0.76), 1.2)
            line([CGPoint(x: rugRect.maxX, y: fy), CGPoint(x: rugRect.maxX + 7, y: fy + random() * 2 - 1)],
                 color(0.92, 0.88, 0.76), 1.2)
        }

        // Lapisan perbatasan luar oker/mustard hangat (#C89D48)
        rounded(rugRect, radius: 8, color: color(0.82, 0.64, 0.35))
        rounded(rugRect.insetBy(dx: 14, dy: 14), radius: 6, color: color(0.93, 0.86, 0.70)) // Bagian tengah linen

        // Motif chevron panah Aztec pada border karpet (> > >, < < <, ^ ^ ^, v v v)
        let cBorder = color(0.96, 0.94, 0.88)
        // Kiri & Kanan
        for cy in stride(from: rugRect.minY + 20, to: rugRect.maxY - 20, by: 18) {
            // Sisi kiri panah ke kanan
            line([CGPoint(x: rugRect.minX + 5, y: cy - 5),
                  CGPoint(x: rugRect.minX + 11, y: cy),
                  CGPoint(x: rugRect.minX + 5, y: cy + 5)], cBorder, 1.8)
            // Sisi kanan panah ke kiri
            line([CGPoint(x: rugRect.maxX - 5, y: cy - 5),
                  CGPoint(x: rugRect.maxX - 11, y: cy),
                  CGPoint(x: rugRect.maxX - 5, y: cy + 5)], cBorder, 1.8)
        }
        // Atas & Bawah
        for cx in stride(from: rugRect.minX + 22, to: rugRect.maxX - 22, by: 18) {
            // Sisi atas panah ke bawah
            line([CGPoint(x: cx - 5, y: rugRect.maxY - 5),
                  CGPoint(x: cx, y: rugRect.maxY - 11),
                  CGPoint(x: cx + 5, y: rugRect.maxY - 5)], cBorder, 1.8)
            // Sisi bawah panah ke atas
            line([CGPoint(x: cx - 5, y: rugRect.minY + 5),
                  CGPoint(x: cx, y: rugRect.minY + 11),
                  CGPoint(x: cx + 5, y: rugRect.minY + 5)], cBorder, 1.8)
        }

        // 8. Figur Ibu yang sedang duduk bersila merajut benang hijau di tengah karpet (seperti screenshot 1)
        paintKnittingMother(at: CGPoint(x: rugRect.midX, y: rugRect.midY - 8))

        // 9. Bantal bundar potongan batang kayu (Tree-stump cushions di sekitar karpet seperti screenshot 1)
        let stumpCushions = [
            CGPoint(x: rugRect.midX, y: rugRect.maxY + 15),     // Atas
            CGPoint(x: rugRect.maxX + 20, y: rugRect.midY),    // Kanan
            CGPoint(x: rugRect.midX - 10, y: rugRect.minY - 14), // Bawah
            CGPoint(x: rugRect.minX - 14, y: rugRect.midY + 10)  // Kiri
        ]
        for sp in stumpCushions {
            // Bayangan bantal di lantai
            ellipse(CGRect(x: sp.x - 22, y: sp.y - 15, width: 44, height: 26), color(0.18, 0.14, 0.10, 0.28))
            // Kulit kayu luar cokelat tua pekat
            ellipse(CGRect(x: sp.x - 20, y: sp.y - 13, width: 40, height: 26), color(0.32, 0.22, 0.14))
            // Permukaan potong kayu hangat
            ellipse(CGRect(x: sp.x - 17, y: sp.y - 10, width: 34, height: 20), color(0.58, 0.44, 0.30))
            // Cincin spiral lingkar tahun kayu (tree growth rings)
            c.setStrokeColor(color(0.25, 0.16, 0.10, 0.7)); c.setLineWidth(1.2)
            c.strokeEllipse(in: CGRect(x: sp.x - 12, y: sp.y - 7, width: 24, height: 14))
            c.strokeEllipse(in: CGRect(x: sp.x - 6, y: sp.y - 3.5, width: 12, height: 7))
        }

        // 10. Meja makan ukir rendah dengan panci sup panas mengepul (seperti screenshot 1)
        let tableRect = CGRect(x: 540, y: 155, width: 135, height: 75)
        // Bayangan meja
        ellipse(CGRect(x: tableRect.minX - 4, y: tableRect.minY - 6, width: tableRect.width + 8, height: 24),
                color(0.18, 0.14, 0.10, 0.30))
        // Meja kayu ukir
        rounded(tableRect, radius: 8, color: color(0.56, 0.42, 0.28))
        rounded(tableRect.insetBy(dx: 4, dy: 4), radius: 6, color: color(0.78, 0.64, 0.45))
        // Ukiran tribal segitiga pada lis meja
        let cTableDeco = color(0.42, 0.30, 0.20, 0.8)
        for tx in stride(from: tableRect.minX + 12, to: tableRect.maxX - 12, by: 12) {
            line([CGPoint(x: tx, y: tableRect.minY + 4),
                  CGPoint(x: tx + 5, y: tableRect.minY + 11),
                  CGPoint(x: tx + 10, y: tableRect.minY + 4)], cTableDeco, 1.3)
        }
        // Alas saji anyaman di atas meja
        rounded(CGRect(x: tableRect.midX - 35, y: tableRect.midY - 14, width: 70, height: 36),
                radius: 4, color: color(0.48, 0.36, 0.25))

        // Panci kuali besi hitam Carto dengan kaldu sup oranye panas
        let potRect = CGRect(x: tableRect.midX - 18, y: tableRect.midY - 8, width: 36, height: 26)
        // Pegangan kuping panci
        line([CGPoint(x: potRect.minX - 4, y: potRect.midY), CGPoint(x: potRect.minX, y: potRect.midY)], color(0.18, 0.22, 0.25), 2.5)
        line([CGPoint(x: potRect.maxX, y: potRect.midY), CGPoint(x: potRect.maxX + 4, y: potRect.midY)], color(0.18, 0.22, 0.25), 2.5)
        // Badan kuali besi
        ellipse(potRect, color(0.18, 0.24, 0.28))
        // Rebusan sup oranye keemasan dengan taburan bumbu hijau
        ellipse(potRect.insetBy(dx: 4, dy: 4), color(0.95, 0.58, 0.16))
        ellipse(CGRect(x: potRect.midX - 3, y: potRect.midY + 1, width: 4, height: 3), color(0.24, 0.62, 0.32))
        ellipse(CGRect(x: potRect.midX + 4, y: potRect.midY - 2, width: 3, height: 2.5), color(0.24, 0.62, 0.32))
        // Uap putih mengepul lembut dari sup
        line([CGPoint(x: potRect.midX - 6, y: potRect.maxY + 2),
              CGPoint(x: potRect.midX - 4, y: potRect.maxY + 10),
              CGPoint(x: potRect.midX - 8, y: potRect.maxY + 18)], color(1, 1, 1, 0.45), 1.2)
        line([CGPoint(x: potRect.midX + 5, y: potRect.maxY + 3),
              CGPoint(x: potRect.midX + 7, y: potRect.maxY + 11),
              CGPoint(x: potRect.midX + 4, y: potRect.maxY + 20)], color(1, 1, 1, 0.45), 1.2)

        // Dua mangkuk kecil di samping panci
        ellipse(CGRect(x: potRect.minX - 16, y: potRect.midY - 3, width: 12, height: 10), color(0.18, 0.24, 0.28))
        ellipse(CGRect(x: potRect.maxX + 4, y: potRect.midY - 3, width: 12, height: 10), color(0.18, 0.24, 0.28))

        // 11. Matras tidur anyaman dengan selimut kotak & rumbai wol putih (seperti screenshot 1)
        let bedRect = CGRect(x: 480, y: 30, width: 215, height: 110)
        // Bayangan kasur
        ellipse(CGRect(x: bedRect.minX - 3, y: bedRect.minY - 5, width: bedRect.width + 6, height: 22),
                color(0.18, 0.14, 0.10, 0.25))
        // Matras anyaman dasar
        rounded(bedRect, radius: 8, color: color(0.42, 0.32, 0.22))

        // Selimut berpola kotak-kotak / berlian cokelat Carto
        let quiltRect = CGRect(x: bedRect.minX + 16, y: bedRect.minY + 12, width: bedRect.width - 48, height: bedRect.height - 24)
        rounded(quiltRect, radius: 5, color: color(0.62, 0.48, 0.32))
        // Garis-garis pola kotak rajut selimut
        for row in 0..<5 {
            let qy = quiltRect.minY + CGFloat(row) * (quiltRect.height / 5)
            line([CGPoint(x: quiltRect.minX, y: qy), CGPoint(x: quiltRect.maxX, y: qy)], color(0.48, 0.36, 0.24, 0.6), 1.2)
        }
        for col in 0..<7 {
            let qx = quiltRect.minX + CGFloat(col) * (quiltRect.width / 7)
            line([CGPoint(x: qx, y: quiltRect.minY), CGPoint(x: qx, y: quiltRect.maxY)], color(0.48, 0.36, 0.24, 0.6), 1.2)
        }
        // Titik-titik panah kecil di tengah kotak selimut
        for r in 0..<4 {
            for c in 0..<6 {
                let px = quiltRect.minX + CGFloat(c) * (quiltRect.width / 7) + 8
                let py = quiltRect.minY + CGFloat(r) * (quiltRect.height / 5) + 6
                line([CGPoint(x: px - 2, y: py - 2), CGPoint(x: px, y: py + 2), CGPoint(x: px + 2, y: py - 2)],
                     color(0.82, 0.74, 0.60, 0.7), 1.0)
            }
        }

        // Rumbai wol bulu domba putih lembut di sekeliling selimut (scalloped fleece trim)
        let fleecePoints = stride(from: quiltRect.minX - 4, to: quiltRect.maxX + 4, by: 7)
        for fx in fleecePoints {
            ellipse(CGRect(x: fx - 4, y: quiltRect.minY - 4, width: 8, height: 7), color(0.96, 0.95, 0.90))
            ellipse(CGRect(x: fx - 4, y: quiltRect.maxY - 3, width: 8, height: 7), color(0.96, 0.95, 0.90))
        }
        for fy in stride(from: quiltRect.minY, to: quiltRect.maxY, by: 7) {
            ellipse(CGRect(x: quiltRect.minX - 4, y: fy - 3.5, width: 7, height: 7), color(0.96, 0.95, 0.90))
        }

        // Bantal guling kepala empuk di sisi kanan kasur
        let pillowRect = CGRect(x: bedRect.maxX - 34, y: bedRect.minY + 14, width: 22, height: bedRect.height - 28)
        rounded(pillowRect, radius: 6, color: color(0.92, 0.88, 0.80))
        // Garis lipatan kain bantal
        for py in stride(from: pillowRect.minY + 8, to: pillowRect.maxY - 8, by: 12) {
            line([CGPoint(x: pillowRect.minX + 3, y: py), CGPoint(x: pillowRect.maxX - 3, y: py)],
                 color(0.72, 0.68, 0.60, 0.6), 1.1)
        }

        // 12. Tanaman hias berdaun hijau lebar dalam pot anyaman rotan di sudut kiri bawah (seperti screenshot 1)
        let potBase = CGRect(x: 95, y: 28, width: 34, height: 28)
        // Bayangan pot
        ellipse(CGRect(x: potBase.minX - 3, y: potBase.minY - 4, width: potBase.width + 6, height: 12),
                color(0.18, 0.14, 0.10, 0.35))
        // Pot anyaman cokelat
        rounded(potBase, radius: 5, color: color(0.48, 0.34, 0.22))
        // Motif jalinan anyaman rotan
        for row in 0..<3 {
            let ry = potBase.minY + CGFloat(row) * 8 + 4
            line([CGPoint(x: potBase.minX + 2, y: ry), CGPoint(x: potBase.maxX - 2, y: ry)], color(0.32, 0.22, 0.14), 1.2)
        }
        // Daun-daun hijau lebar tegak meruncing Carto (fan-like broad leaves)
        let leafAngles: [CGFloat] = [.pi * 0.72, .pi * 0.58, .pi * 0.50, .pi * 0.42, .pi * 0.28]
        let leafLengths: [CGFloat] = [28, 38, 44, 37, 27]
        for (i, angle) in leafAngles.enumerated() {
            let len = leafLengths[i]
            let root = CGPoint(x: potBase.midX, y: potBase.maxY - 2)
            let tip = CGPoint(x: root.x + cos(angle) * len, y: root.y + sin(angle) * len)

            // Bentuk daun lebar meruncing
            let leafPath = CGMutablePath()
            leafPath.move(to: root)
            let perpAngle = angle + .pi / 2
            let sideOffset: CGFloat = 6.5
            let mid1 = CGPoint(x: root.x + cos(angle) * (len * 0.5) + cos(perpAngle) * sideOffset,
                               y: root.y + sin(angle) * (len * 0.5) + sin(perpAngle) * sideOffset)
            let mid2 = CGPoint(x: root.x + cos(angle) * (len * 0.5) - cos(perpAngle) * sideOffset,
                               y: root.y + sin(angle) * (len * 0.5) - sin(perpAngle) * sideOffset)
            leafPath.addQuadCurve(to: tip, control: mid1)
            leafPath.addQuadCurve(to: root, control: mid2)
            leafPath.closeSubpath()

            c.setFillColor(color(0.20, 0.44, 0.26)); c.addPath(leafPath); c.fillPath()
            // Tulang daun tengah hijau muda
            line([root, tip], color(0.38, 0.65, 0.42), 1.2)
        }
    }

    // Melukis figur Ibu yang sedang duduk bersila merajut di karpet Aztec
    private func paintKnittingMother(at p: CGPoint) {
        c.saveGState()
        // Bayangan lembut tubuh di karpet
        ellipse(CGRect(x: p.x - 22, y: p.y - 14, width: 44, height: 22), color(0.25, 0.20, 0.12, 0.35))

        // Kaki bersila / jubah biru toska tua
        let legsRect = CGRect(x: p.x - 20, y: p.y - 10, width: 40, height: 18)
        rounded(legsRect, radius: 8, color: color(0.22, 0.45, 0.62))

        // Badan / rompi bulu cokelat hangat
        let bodyRect = CGRect(x: p.x - 14, y: p.y - 4, width: 28, height: 26)
        rounded(bodyRect, radius: 7, color: color(0.55, 0.38, 0.24))

        // Kepala Ibu
        let headCenter = CGPoint(x: p.x, y: p.y + 26)
        ellipse(CGRect(x: headCenter.x - 11, y: headCenter.y - 11, width: 22, height: 22),
                color(0.98, 0.82, 0.70)) // Kulit peach hangat

        // Rambut biru tua & ikatan bandana khas suku Carto
        ellipse(CGRect(x: headCenter.x - 12, y: headCenter.y - 4, width: 24, height: 17),
                color(0.18, 0.32, 0.52))
        // Sanggul ikat rambut di belakang/atas
        ellipse(CGRect(x: headCenter.x - 6, y: headCenter.y + 9, width: 12, height: 9),
                color(0.18, 0.32, 0.52))

        // Wajah Ibu yang tersenyum tenang memejamkan mata (^ ^)
        let eyeY = headCenter.y - 2
        line([CGPoint(x: headCenter.x - 7, y: eyeY), CGPoint(x: headCenter.x - 4, y: eyeY + 2), CGPoint(x: headCenter.x - 1, y: eyeY)],
             color(0.25, 0.20, 0.18), 1.2)
        line([CGPoint(x: headCenter.x + 2, y: eyeY), CGPoint(x: headCenter.x + 5, y: eyeY + 2), CGPoint(x: headCenter.x + 8, y: eyeY)],
             color(0.25, 0.20, 0.18), 1.2)
        // Senyum kecil ramah
        line([CGPoint(x: headCenter.x - 2, y: eyeY - 4), CGPoint(x: headCenter.x, y: eyeY - 5), CGPoint(x: headCenter.x + 3, y: eyeY - 4)],
             color(0.65, 0.35, 0.30), 1.1)

        // Jarum rajut tipis dari kayu
        line([CGPoint(x: p.x - 15, y: p.y + 6), CGPoint(x: p.x + 6, y: p.y + 16)], color(0.90, 0.85, 0.72), 1.4)
        line([CGPoint(x: p.x + 15, y: p.y + 6), CGPoint(x: p.x - 6, y: p.y + 16)], color(0.90, 0.85, 0.72), 1.4)

        // Rajutan syal benang wol hijau zamrud yang sedang dibuat (#2A8452)
        let scarfPath = CGMutablePath()
        scarfPath.move(to: CGPoint(x: p.x - 8, y: p.y + 8))
        scarfPath.addQuadCurve(to: CGPoint(x: p.x + 18, y: p.y - 6), control: CGPoint(x: p.x + 8, y: p.y + 1))
        scarfPath.addLine(to: CGPoint(x: p.x + 22, y: p.y - 4))
        scarfPath.addQuadCurve(to: CGPoint(x: p.x - 4, y: p.y + 12), control: CGPoint(x: p.x + 10, y: p.y + 4))
        scarfPath.closeSubpath()
        c.setFillColor(color(0.18, 0.58, 0.34)); c.addPath(scarfPath); c.fillPath()

        // Bola gulungan benang wol hijau di karpet
        ellipse(CGRect(x: p.x + 16, y: p.y - 12, width: 14, height: 12), color(0.18, 0.58, 0.34))
        c.restoreGState()
    }

    // =========================================================================
    // MARK: - 2. LANSKAP PADANG RUMPUT & LUAR RUANGAN (SCREENSHOT 2)
    // =========================================================================
    private func landscape(level: PrologueLevel, progress: PrologueProgress) {
        // 1. Sapuan warna air lembut pada kertas rumput sage/lime hangat
        for _ in 0..<1200 {
            let x = random() * 960, y = random() * 480
            let v = random()
            ellipse(CGRect(x: x, y: y, width: 22 + random() * 55, height: 10 + random() * 25),
                    color(0.72 + v * 0.12, 0.82 + v * 0.10, 0.46 + v * 0.10, 0.22))
        }

        // 2. Garis pantai tebing dan laut biru tua Carto (jika di region pesisir)
        if level.region != .village && level.region != .house {
            if progress.lakeVariant == .dryLake {
                rounded(CGRect(x: 343, y: 38, width: 244, height: 135), radius: 35, color: color(0.83, 0.76, 0.60))
                for _ in 0..<60 {
                    let x = 353 + random() * 217, y = 45 + random() * 115
                    line([CGPoint(x: x, y: y), CGPoint(x: x + 10, y: y + 8)], color(0.66, 0.58, 0.44, 0.4), 1.2)
                }
            } else {
                cartoOceanCliff(CGRect(x: 830, y: 0, width: 130, height: 480))
            }
        }

        // 3. Jalur jalan tanah berpasir lembut khas Carto
        if level.region == .echoes {
            trail([CGPoint(x: 30, y: 240), CGPoint(x: level.mapBounds.maxX, y: 240)], width: 78)
        } else if level.region == .village {
            trail([CGPoint(x: 0, y: 72), CGPoint(x: 220, y: 82), CGPoint(x: 455, y: 125), CGPoint(x: 740, y: 150), CGPoint(x: 960, y: 145)], width: 44)
            trail([CGPoint(x: 140, y: 0), CGPoint(x: 160, y: 80), CGPoint(x: 245, y: 275), CGPoint(x: 170, y: 365), CGPoint(x: 210, y: 480)], width: 32)
            trail([CGPoint(x: 465, y: 80), CGPoint(x: 470, y: 255), CGPoint(x: 510, y: 420), CGPoint(x: 550, y: 480)], width: 36)
            trail([CGPoint(x: 670, y: 110), CGPoint(x: 700, y: 280), CGPoint(x: 830, y: 310), CGPoint(x: 960, y: 330)], width: 30)
        } else {
            trail([CGPoint(x: 30, y: 100), CGPoint(x: 140, y: 150), CGPoint(x: 245, y: 200), CGPoint(x: 280, y: 370)], width: 38)
            trail([CGPoint(x: 640, y: 65), CGPoint(x: 710, y: 105), CGPoint(x: 790, y: 205), CGPoint(x: 810, y: 370), CGPoint(x: 960, y: 400)], width: 40)
        }

        // Zona jalan modular puzzle
        for zone in level.zones where zone.piece == .oldPath || zone.piece == .villageRoad {
            c.saveGState(); c.clip(to: zone.rect)
            c.translateBy(x: zone.rect.midX, y: zone.rect.midY)
            c.rotate(by: -CGFloat(progress.placement(of: zone.piece)?.turns ?? 0) * .pi / 2)
            trail([CGPoint(x: -zone.rect.width / 2, y: 0), CGPoint(x: zone.rect.width / 2, y: 0)], width: 50)
            c.restoreGState()
        }

        // 4. ARSIR PENSIL VERTIKAL RAPAT KHAS CARTO (DENSE VERTICAL PENCIL HATCHING - SCREENSHOT 2)
        // Ini adalah ciri khas visual utama Carto: goresan pensil tegak di seluruh permukaan padang rumput
        for _ in 0..<2400 {
            let x = random() * 960
            let y = random() * 480
            let h: CGFloat = 5 + random() * 10
            let v = random()
            let pencilColor = color(0.52 + v * 0.12, 0.65 + v * 0.10, 0.32 + v * 0.08, 0.42)
            line([CGPoint(x: x, y: y), CGPoint(x: x + (random() - 0.5) * 1.5, y: y + h)], pencilColor, 0.85)
        }

        // 5. Tanda panah / chevron rumput kapur putih Carto (^ ^ dan v v - seperti screenshot 2)
        let chevronSpots = [
            CGPoint(x: 45, y: 310), CGPoint(x: 65, y: 325), CGPoint(x: 40, y: 280),
            CGPoint(x: 320, y: 160), CGPoint(x: 340, y: 175),
            CGPoint(x: 620, y: 340), CGPoint(x: 640, y: 355),
            CGPoint(x: 880, y: 210), CGPoint(x: 900, y: 225)
        ]
        for sp in chevronSpots {
            let whiteChalk = color(0.96, 0.98, 0.92, 0.65)
            line([CGPoint(x: sp.x - 7, y: sp.y - 8), CGPoint(x: sp.x, y: sp.y), CGPoint(x: sp.x + 7, y: sp.y - 8)],
                 whiteChalk, 1.5)
        }

        // 6. Rumpun bunga liar putih bertangkai tegak (seperti di screenshot 2)
        for _ in 0..<90 {
            let p = CGPoint(x: random() * 960, y: random() * 480)
            if level.obstacles.contains(where: { $0.rect.insetBy(dx: -15, dy: -15).contains(p) }) { continue }
            flowerStalk(at: p)
        }
    }

    // Tangkai bunga liar tegak Carto dengan kuncup bunga putih (seperti screenshot 2)
    private func flowerStalk(at p: CGPoint) {
        let stalkHeight: CGFloat = 14 + random() * 10
        // Batang hijau
        line([p, CGPoint(x: p.x, y: p.y + stalkHeight)], color(0.42, 0.58, 0.30), 1.2)
        // Kuncup-kuncup bunga putih kecil di puncak tangkai
        let petalColor = color(0.98, 0.98, 0.95, 0.95)
        for b in 0..<4 {
            let by = p.y + stalkHeight - CGFloat(b) * 3
            let bx = p.x + (b % 2 == 0 ? -3 : 3)
            ellipse(CGRect(x: bx - 2, y: by - 2, width: 4, height: 4), petalColor)
        }
        ellipse(CGRect(x: p.x - 2.5, y: p.y + stalkHeight - 1, width: 5, height: 5), petalColor)
    }

    // Melukis jalan tanah dengan transisi lembut ke rumput
    private func trail(_ points: [CGPoint], width: CGFloat) {
        line(points, color(0.72, 0.74, 0.48, 0.35), width + 14)
        line(points, color(0.88, 0.83, 0.70, 0.95), width)
        line(points, color(0.94, 0.90, 0.79, 0.85), width * 0.65)
        for i in 1..<points.count {
            let a = points[i - 1], b = points[i]
            for _ in 0..<Int(hypot(b.x - a.x, b.y - a.y) / 5) {
                let t = random(), side = (random() - 0.5) * width * 0.8
                let p = CGPoint(x: a.x + (b.x - a.x) * t + side * 0.5, y: a.y + (b.y - a.y) * t + side)
                ellipse(CGRect(x: p.x, y: p.y, width: 1.8 + random() * 2.2, height: 1.5), color(0.72, 0.65, 0.50, 0.45))
            }
        }
    }

    // Tebing pantai dan laut biru Carto
    private func cartoOceanCliff(_ r: CGRect) {
        rounded(r, radius: 15, color: color(0.88, 0.84, 0.70))
        let sea = r.offsetBy(dx: 16, dy: 0)
        rounded(sea, radius: 10, color: oceanNavy)
        for i in 0..<22 {
            let y = r.minY + CGFloat(i) * 22 + random() * 8
            let x = sea.minX + 6 + random() * 70
            line([CGPoint(x: x, y: y), CGPoint(x: x + 8, y: y + 2), CGPoint(x: x + 16, y: y)], color(0.45, 0.75, 0.78, 0.5), 1.6)
            line([CGPoint(x: x + 2, y: y + 1), CGPoint(x: x + 8, y: y + 2.5)], color(1, 1, 1, 0.55), 1.0)
        }
    }

    // =========================================================================
    // MARK: - 3. RINTANGAN & PROPS CARTO (SCREENSHOT 2)
    // =========================================================================
    private func paint(_ obstacle: WorldObstacle) {
        let r = obstacle.rect
        c.saveGState()

        // Bayangan lembut di bawah kaki rintangan
        let shadowRect = CGRect(x: r.minX - 4, y: r.minY - 5, width: r.width + 8, height: min(20, r.height * 0.45))
        ellipse(shadowRect, color(0.18, 0.24, 0.14, 0.26))

        switch obstacle.kind {
        case "Rumah", "Rumah ilusi":
            cottage(r)
        case "Pohon", "Pohon tua":
            pineTree(r)
        case "Pagar tanaman":
            bushHedge(r)
        case "Batu", "Dinding batu":
            rocks(r, wall: obstacle.kind == "Dinding batu")
        case "Air":
            water(r)
        default:
            crate(r)
        }
        c.restoreGState()
    }

    // Pondok panggung kayu A-frame beratap jerami tebal Carto + Tunggul Kapak + Kayu Bakar + Jemuran Kulit (Screenshot 2)
    private func cottage(_ r: CGRect) {
        let groundY = r.minY
        let wallHeight: CGFloat = r.height * 0.45

        // 1. Tiang panggung kayu di bawah rumah panggung
        let stiltH = wallHeight * 0.65
        fill(CGRect(x: r.minX + 10, y: groundY, width: 8, height: stiltH), woodDark)
        fill(CGRect(x: r.maxX - 18, y: groundY, width: 8, height: stiltH), woodDark)
        fill(CGRect(x: r.midX - 4, y: groundY, width: 8, height: stiltH), woodDark)

        // Tangga kayu kecil di depan menuju pintu (persis seperti di Carto)
        let ladderX = r.minX + r.width * 0.38
        line([CGPoint(x: ladderX, y: groundY), CGPoint(x: ladderX + 8, y: groundY + stiltH + 4)], woodWarm, 3.0)
        line([CGPoint(x: ladderX + 14, y: groundY), CGPoint(x: ladderX + 22, y: groundY + stiltH + 4)], woodWarm, 3.0)
        for s in 0..<4 {
            let sy = groundY + CGFloat(s) * (stiltH / 3.5) + 3
            let sx = ladderX + CGFloat(s) * 2.2
            line([CGPoint(x: sx, y: sy), CGPoint(x: sx + 14, y: sy)], woodWarm, 2.2)
        }

        // 2. Dinding papan kayu rumah panggung
        let wallRect = CGRect(x: r.minX + 6, y: groundY + stiltH * 0.7, width: r.width - 12, height: wallHeight)
        rounded(wallRect, radius: 4, color: color(0.68, 0.54, 0.38))
        for col in 1..<6 {
            let px = wallRect.minX + CGFloat(col) * (wallRect.width / 6)
            line([CGPoint(x: px, y: wallRect.minY), CGPoint(x: px, y: wallRect.maxY)], color(0.48, 0.36, 0.24, 0.5), 1.4)
        }

        // Pintu masuk anyaman bermotif toska Carto
        let door = CGRect(x: r.midX - 12, y: wallRect.minY + 2, width: 22, height: wallHeight * 0.88)
        rounded(door, radius: 6, color: color(0.24, 0.55, 0.52))
        line([CGPoint(x: door.midX, y: door.maxY - 4), CGPoint(x: door.minX + 2, y: door.minY + 4)], color(0.85, 0.82, 0.55), 1.4)
        line([CGPoint(x: door.midX, y: door.maxY - 4), CGPoint(x: door.maxX - 2, y: door.minY + 4)], color(0.85, 0.82, 0.55), 1.4)

        // 3. Atap Jerami Tebal Berlapis (Thatched Roof Carto - Screenshot 2)
        let roofBottom = wallRect.maxY - 6
        let roofTop = r.maxY + 24
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: r.minX - 14, y: roofBottom))
        roofPath.addLine(to: CGPoint(x: r.midX, y: roofTop))
        roofPath.addLine(to: CGPoint(x: r.maxX + 14, y: roofBottom))
        roofPath.closeSubpath()

        c.setFillColor(color(0.82, 0.65, 0.38))
        c.addPath(roofPath); c.fillPath()

        // Ranting bubungan atap bersilangan di puncak atap (ridge twigs Carto)
        line([CGPoint(x: r.midX - 10, y: roofTop - 4), CGPoint(x: r.midX + 12, y: roofTop + 14)], woodDark, 2.5)
        line([CGPoint(x: r.midX + 10, y: roofTop - 4), CGPoint(x: r.midX - 12, y: roofTop + 14)], woodDark, 2.5)
        line([CGPoint(x: r.midX - 4, y: roofTop - 2), CGPoint(x: r.midX + 6, y: roofTop + 18)], woodDark, 2.0)

        // Lapisan jerami berumbai bertingkat
        let strawDark = color(0.58, 0.44, 0.24, 0.85)
        let strawLight = color(0.94, 0.82, 0.56, 0.9)

        for row in 0..<5 {
            let progress = CGFloat(row) / 5.0
            let y = roofBottom + progress * (roofTop - roofBottom) * 0.88
            let w = (r.width + 28) * (1.0 - progress * 0.68)
            let x = r.midX - w / 2

            line([CGPoint(x: x, y: y), CGPoint(x: x + w, y: y)], strawDark, 3.0)
            for i in 0..<Int(w / 6) {
                let sx = x + CGFloat(i) * 6 + random() * 2
                line([CGPoint(x: sx, y: y - 2), CGPoint(x: sx + random() * 3 - 1.5, y: y + 11)], strawLight, 1.2)
            }
        }

        // Ukiran kayu ornamen segitiga di fasad segitiga depan (gable tribal carving)
        let gableX = r.midX
        let gableY = wallRect.maxY + 10
        let gableP = CGMutablePath()
        gableP.move(to: CGPoint(x: gableX - 14, y: gableY))
        gableP.addLine(to: CGPoint(x: gableX, y: gableY + 22))
        gableP.addLine(to: CGPoint(x: gableX + 14, y: gableY))
        c.setStrokeColor(color(0.94, 0.90, 0.78, 0.9)); c.setLineWidth(2.2)
        c.addPath(gableP); c.strokePath()

        // 4. Props khas desa di samping pondok: Tunggul Kapak, Tumpukan Kayu Bakar, & Jemuran Kulit Hewan (Screenshot 2)
        if r.width >= 110 {
            // A. Tunggul pohon dengan kapak tertancap
            let stumpCenter = CGPoint(x: r.maxX + 18, y: groundY + 8)
            ellipse(CGRect(x: stumpCenter.x - 12, y: stumpCenter.y - 8, width: 24, height: 16), color(0.38, 0.28, 0.18))
            ellipse(CGRect(x: stumpCenter.x - 9, y: stumpCenter.y - 6, width: 18, height: 12), color(0.68, 0.54, 0.38))
            // Kapak miring tertancap
            line([CGPoint(x: stumpCenter.x - 3, y: stumpCenter.y + 4), CGPoint(x: stumpCenter.x + 14, y: stumpCenter.y + 20)],
                 woodWarm, 2.5)
            let axeBlade = CGMutablePath()
            axeBlade.move(to: CGPoint(x: stumpCenter.x - 7, y: stumpCenter.y + 2))
            axeBlade.addLine(to: CGPoint(x: stumpCenter.x + 2, y: stumpCenter.y + 7))
            axeBlade.addLine(to: CGPoint(x: stumpCenter.x - 2, y: stumpCenter.y - 1))
            axeBlade.closeSubpath()
            c.setFillColor(color(0.85, 0.88, 0.90)); c.addPath(axeBlade); c.fillPath()

            // B. Tumpukan balok kayu bakar (firewood pile)
            let woodPileCenter = CGPoint(x: r.maxX + 46, y: groundY + 6)
            for row in 0..<3 {
                let count = 4 - row
                let py = woodPileCenter.y + CGFloat(row) * 6
                for col in 0..<count {
                    let px = woodPileCenter.x + CGFloat(col) * 7 - CGFloat(count) * 3.5
                    ellipse(CGRect(x: px, y: py, width: 7, height: 7), color(0.55, 0.40, 0.26))
                    ellipse(CGRect(x: px + 1, y: py + 1, width: 5, height: 5), color(0.78, 0.62, 0.42))
                }
            }

            // C. Tiang jemuran kulit hewan (pelt drying rack)
            let rackX = r.maxX + 82
            let rackY = groundY + 4
            // Dua tiang kayu bercabang
            line([CGPoint(x: rackX - 14, y: rackY), CGPoint(x: rackX - 14, y: rackY + 36)], woodDark, 2.5)
            line([CGPoint(x: rackX + 14, y: rackY), CGPoint(x: rackX + 14, y: rackY + 36)], woodDark, 2.5)
            // Palang kayu horizontal
            line([CGPoint(x: rackX - 18, y: rackY + 30), CGPoint(x: rackX + 18, y: rackY + 30)], woodDark, 2.5)
            // Kulit hewan cokelat yang dijemur
            let pelt = CGMutablePath()
            pelt.move(to: CGPoint(x: rackX - 12, y: rackY + 28))
            pelt.addLine(to: CGPoint(x: rackX + 12, y: rackY + 28))
            pelt.addLine(to: CGPoint(x: rackX + 9, y: rackY + 10))
            pelt.addLine(to: CGPoint(x: rackX + 2, y: rackY + 6))
            pelt.addLine(to: CGPoint(x: rackX - 9, y: rackY + 10))
            pelt.closeSubpath()
            c.setFillColor(color(0.68, 0.48, 0.28)); c.addPath(pelt); c.fillPath()
        }
    }

    // Pohon Cemara / Pinus Kerucut Ramping dengan Motif Chevron Putih (Persis Screenshot 2)
    private func pineTree(_ r: CGRect) {
        let groundY = r.minY
        let trunkWidth: CGFloat = 8
        let trunkHeight: CGFloat = r.height * 0.25

        // Batang pohon cokelat di dasar
        rounded(CGRect(x: r.midX - trunkWidth / 2, y: groundY, width: trunkWidth, height: trunkHeight),
                radius: 2, color: woodDark)

        // Bentuk kerucut ramping cemara Carto yang tinggi meruncing
        let treeTopY = r.maxY + 22
        let treeBottomY = groundY + trunkHeight * 0.65
        let treeWidth = r.width * 0.85
        let treeLeft = r.midX - treeWidth / 2
        let treeRight = r.midX + treeWidth / 2

        // Siluet pohon kerucut utama hijau hutan pekat (#2D5824)
        let pinePath = CGMutablePath()
        pinePath.move(to: CGPoint(x: treeLeft, y: treeBottomY))
        pinePath.addQuadCurve(to: CGPoint(x: r.midX, y: treeTopY), control: CGPoint(x: treeLeft + 4, y: (treeBottomY + treeTopY) * 0.55))
        pinePath.addQuadCurve(to: CGPoint(x: treeRight, y: treeBottomY), control: CGPoint(x: treeRight - 4, y: (treeBottomY + treeTopY) * 0.55))
        pinePath.closeSubpath()

        c.setFillColor(color(0.20, 0.42, 0.18))
        c.addPath(pinePath); c.fillPath()

        // Tekstur jarum vertikal di seluruh pohon
        let needleColor = color(0.28, 0.54, 0.24, 0.8)
        let linesCount = Int(treeWidth / 3.5)
        for i in 0..<linesCount {
            let nx = treeLeft + CGFloat(i) * 3.5 + 1.5
            let distFromCenter = abs(nx - r.midX) / (treeWidth / 2)
            let topForX = treeTopY - distFromCenter * (treeTopY - treeBottomY) * 0.95
            line([CGPoint(x: nx, y: treeBottomY), CGPoint(x: nx, y: topForX)], needleColor, 1.1)
        }

        // MOTIF CHEVRON JARUM CEMARA PUTIH/KAPUR CARTO (^ ^ ^ - PERSIS SCREENSHOT 2)
        // Ini adalah detail paling khas dari pohon pinus di Carto!
        let chevronRows = 7
        for row in 0..<chevronRows {
            let t = CGFloat(row + 1) / CGFloat(chevronRows + 1)
            let cy = treeBottomY + t * (treeTopY - treeBottomY) * 0.82
            let wAtRow = (treeWidth * 0.55) * (1.0 - t * 0.65)
            let whiteChalk = color(0.95, 0.98, 0.90, 0.85)

            // Chevron tengah
            line([CGPoint(x: r.midX - 5, y: cy - 4), CGPoint(x: r.midX, y: cy + 3), CGPoint(x: r.midX + 5, y: cy - 4)],
                 whiteChalk, 1.4)
            // Chevron kiri & kanan jika pohon cukup lebar di tingkat ini
            if wAtRow > 10 {
                line([CGPoint(x: r.midX - wAtRow - 3, y: cy - 7),
                      CGPoint(x: r.midX - wAtRow, y: cy - 2),
                      CGPoint(x: r.midX - wAtRow + 3, y: cy - 7)], whiteChalk, 1.1)
                line([CGPoint(x: r.midX + wAtRow - 3, y: cy - 7),
                      CGPoint(x: r.midX + wAtRow, y: cy - 2),
                      CGPoint(x: r.midX + wAtRow + 3, y: cy - 7)], whiteChalk, 1.1)
            }
        }
    }

    // Semak Rimbun Bundar dengan Buah Beri Oranye & Pagar Pasak Kayu (Screenshot 2)
    private func bushHedge(_ r: CGRect) {
        // Pasak kayu pagar pembatas di belakang semak
        let stakeCount = max(2, Int(r.width / 22))
        for i in 0..<stakeCount {
            let sx = r.minX + CGFloat(i) * (r.width / CGFloat(stakeCount - 1))
            rounded(CGRect(x: sx - 2, y: r.minY, width: 4, height: r.height * 0.5), radius: 1, color: woodDark)
            if i > 0 {
                let prevX = r.minX + CGFloat(i - 1) * (r.width / CGFloat(stakeCount - 1))
                line([CGPoint(x: prevX, y: r.minY + r.height * 0.35), CGPoint(x: sx, y: r.minY + r.height * 0.35)],
                     color(0.25, 0.20, 0.15, 0.7), 1.2)
            }
        }

        // Gundukan semak bulat hijau berlapis khas Carto
        let clumpCount = max(2, Int(r.width / 18))
        for i in 0..<clumpCount {
            let cx = r.minX + CGFloat(i) * (r.width / CGFloat(clumpCount)) + 8
            let cy = r.minY + r.height * 0.22
            let cw: CGFloat = 22 + random() * 8
            let ch: CGFloat = r.height * 0.78 + random() * 6

            let bushRect = CGRect(x: cx - cw / 2, y: cy, width: cw, height: ch)
            ellipse(bushRect, color(0.26, 0.48, 0.22, 0.95))

            // Garis-garis kontur daun vertikal Carto
            let cLine = color(0.38, 0.62, 0.30, 0.85)
            for step in 1...3 {
                let inset = CGFloat(step) * 2.8
                let inner = bushRect.insetBy(dx: inset, dy: inset * 0.8)
                c.setStrokeColor(cLine); c.setLineWidth(1.1)
                c.strokeEllipse(in: inner)
            }

            // Buah beri oranye cerah Carto (#F26822) dan bunga bintang putih kecil (Screenshot 2)
            let berryColor = color(0.95, 0.48, 0.14)
            for _ in 0..<4 {
                let bx = cx + (random() - 0.5) * (cw * 0.6)
                let by = cy + ch * 0.55 + random() * (ch * 0.35)
                ellipse(CGRect(x: bx - 2, y: by - 2, width: 4, height: 4), berryColor)
                // Titik kilap kecil
                ellipse(CGRect(x: bx - 0.5, y: by + 0.5, width: 1.5, height: 1.5), color(1, 1, 1, 0.8))
            }
            if random() > 0.4 {
                let fx = cx + (random() - 0.5) * (cw * 0.5)
                let fy = cy + ch * 0.4 + random() * (ch * 0.3)
                ellipse(CGRect(x: fx - 2, y: fy - 2, width: 4, height: 4), color(0.98, 0.98, 0.94))
            }
        }
    }

    // Bebatuan sungai lembut berbatu & dinding batu mortar Carto
    private func rocks(_ r: CGRect, wall: Bool) {
        if !wall {
            let rockRect = CGRect(x: r.minX + 2, y: r.minY, width: r.width - 4, height: r.height * 0.85)
            rounded(rockRect, radius: min(rockRect.width, rockRect.height) * 0.45, color: color(0.58, 0.60, 0.54))
            rounded(rockRect.insetBy(dx: 4, dy: 4).offsetBy(dx: -2, dy: 3), radius: 6, color: color(0.72, 0.74, 0.68, 0.8))
            // Tutupan lumut hijau di puncak batu
            rounded(CGRect(x: rockRect.minX + 4, y: rockRect.maxY - 8, width: rockRect.width - 8, height: 7),
                    radius: 3, color: color(0.42, 0.58, 0.30, 0.85))
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
        rounded(r, radius: 14, color: color(0.24, 0.52, 0.58))
        rounded(r.insetBy(dx: 3, dy: 3), radius: 11, color: color(0.30, 0.60, 0.64))
        for _ in 0..<18 {
            let x = r.minX + 6 + random() * (r.width - 24)
            let y = r.minY + 4 + random() * (r.height - 8)
            line([CGPoint(x: x, y: y), CGPoint(x: x + 8, y: y + 1.5), CGPoint(x: x + 16, y: y)], color(1, 1, 1, 0.45), 1.2)
        }
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
            rounded(CGRect(x: x, y: 472, width: 20, height: 7), radius: 3, color: color(0.58, 0.64, 0.46))
            ellipse(CGRect(x: x, y: 1, width: 18, height: 5), color(0.56, 0.60, 0.44, 0.65))
        }
    }
}
