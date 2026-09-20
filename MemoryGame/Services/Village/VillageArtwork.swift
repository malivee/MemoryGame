// Penjelasan file: VillageArtwork.swift
// Denah desa memakai bahasa visual SceneryPainter dari main: rumah panggung, jerami, cemara, dan palet storybook.
// Primitive cottage/pineTree/bushHedge/rocks disalin tanpa perubahan agar renderer utama tidak perlu diedit.
// Posisi bangunan dan jalan dibaca dari VillageMap; gambar bisa dirender juga untuk review.
import Foundation
import CoreGraphics
final class VillageArtwork {
    private var c: CGContext!
    private let grassBase = CGColor(red:0.76,green:0.84,blue:0.49,alpha:1)
    private let woodDark = CGColor(red:0.29,green:0.20,blue:0.14,alpha:1)
    private let woodWarm = CGColor(red:0.54,green:0.39,blue:0.25,alpha:1)
    private let woodLight = CGColor(red:0.74,green:0.59,blue:0.41,alpha:1)
    private var seed: UInt64 = 41
    private func rand() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1; return CGFloat((seed >> 32) % 10000) / 10000 }
    private func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(red:r, green:g, blue:b, alpha:a) }
    private func rect(_ r: CGRect, _ color: CGColor) { c.setFillColor(color); c.fill(r) }
    private func oval(_ r: CGRect, _ color: CGColor) { c.setFillColor(color); c.fillEllipse(in:r) }
    private func line(_ points: [CGPoint], _ color: CGColor, _ width: CGFloat = 1) {
        guard let first = points.first else { return }
        c.beginPath(); c.move(to:first); for p in points.dropFirst() { c.addLine(to:p) }
        c.setStrokeColor(color); c.setLineWidth(width); c.setLineCap(.round); c.setLineJoin(.round); c.strokePath()
    }
    func image() -> CGImage? {
        seed = 41
        guard let context = CGContext(data:nil, width:3840, height:2880, bitsPerComponent:8, bytesPerRow:0,
            space:CGColorSpaceCreateDeviceRGB(), bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        c = context
        // Render 2x seperti SceneryPainter agar tekstur tetap tajam pada zoom dekat.
        c.scaleBy(x:2,y:2)
        rect(VillageMap.bounds, grassBase)
        // Sapuan warna air dari SceneryPainter; luas desa enam kali peta asli.
        for _ in 0..<7200 {
            let x=random()*1920,y=random()*1440,v=random()
            ellipse(CGRect(x:x,y:y,width:22+random()*55,height:10+random()*25),
                    color(0.72+v*0.12,0.82+v*0.10,0.46+v*0.10,0.22))
        }
        for landmark in VillageMap.landmarks {
            oval(landmark.rect.insetBy(dx:-75,dy:-65), color(0.80,0.83,0.51,0.30))
        }
        // Sungai berada di timur laut; tepi berbatu memisahkannya dari jalan gudang.
        line(VillageMap.river, color(0.29,0.35,0.26), 125)
        line(VillageMap.river, color(0.69,0.70,0.53), 99)
        line(VillageMap.river, color(0.27,0.48,0.48), 78)
        line(VillageMap.river, color(0.45,0.65,0.59), 35)
        // Gambar semua jalur per lapisan agar simpang menyatu tanpa ujung bulat bertumpuk.
        for road in VillageMap.roads { line(road,color(0.72,0.74,0.48,0.35),88) }
        for road in VillageMap.roads { line(road,color(0.88,0.83,0.70),76) }
        for road in VillageMap.roads { line(road,color(0.94,0.90,0.79),57) }
        // Kerikil jalan, arsiran pensil, dan bunga mengikuti skala renderer main.
        for road in VillageMap.roads {
            for i in 1..<road.count {
                let a=road[i-1],b=road[i]
                for _ in 0..<Int(hypot(b.x-a.x,b.y-a.y)/5) {
                    let t=random(),side=(random()-0.5)*76*0.8
                    ellipse(CGRect(x:a.x+(b.x-a.x)*t+side*0.5,y:a.y+(b.y-a.y)*t+side,
                                   width:1.8+random()*2.2,height:1.5),color(0.72,0.65,0.50,0.45))
                }
            }
        }
        for _ in 0..<14400 {
            let x=random()*1920,y=random()*1440,h=5+random()*10,v=random()
            line([CGPoint(x:x,y:y),CGPoint(x:x+(random()-0.5)*1.5,y:y+h)],
                 color(0.52+v*0.12,0.65+v*0.10,0.32+v*0.08,0.42),0.85)
        }
        for _ in 0..<540 {
            let p=CGPoint(x:random()*1920,y:random()*1440)
            if VillageMap.solids.contains(where: { $0.insetBy(dx:-15,dy:-15).contains(p) }) { continue }
            flowerStalk(at:p)
        }
        // Parit mengiringi sisi selatan jalan keluar, tanpa memotong jalur berjalan.
        line([CGPoint(x:1100,y:423),CGPoint(x:1530,y:306),CGPoint(x:1890,y:220)],color(0.32,0.35,0.24),12)
        line([CGPoint(x:1100,y:423),CGPoint(x:1530,y:306),CGPoint(x:1890,y:220)],color(0.51,0.53,0.36),5)
        garden(CGRect(x:175,y:1080,width:80,height:150))
        garden(CGRect(x:845,y:1280,width:130,height:125))
        for landmark in VillageMap.landmarks { building(landmark) }
        // Pot dan rak miring Bu Mara.
        oval(CGRect(x:1397,y:567,width:110,height:70),color(0.28,0.35,0.29,0.7))
        rect(CGRect(x:1415,y:660,width:83,height:12),color(0.32,0.23,0.15))
        line([CGPoint(x:1420,y:612),CGPoint(x:1425,y:665)],color(0.29,0.21,0.13),7)
        line([CGPoint(x:1489,y:612),CGPoint(x:1480,y:665)],color(0.29,0.21,0.13),7)
        for i in 0..<7 { pot(CGPoint(x:1125+CGFloat(i%2)*27,y:590+CGFloat(i/2)*38),size:20) }
        for i in 0..<3 { pot(CGPoint(x:1432+CGFloat(i)*23,y:684),size:17) }
        rect(CGRect(x:1500,y:610,width:17,height:9),color(0.59,0.29,0.16))
        // Lumbung: karung panen dan kayu lembap di sisi bangunan.
        for i in 0..<8 {
            let x=990-CGFloat(i%2)*26, y=1080+CGFloat(i/2)*35
            oval(CGRect(x:x,y:y,width:26,height:35),color(0.25,0.26,0.18,0.25))
            oval(CGRect(x:x-3,y:y+3,width:25,height:33),color(0.69,0.61,0.41))
            line([CGPoint(x:x+3,y:y+27),CGPoint(x:x+17,y:y+27)],color(0.37,0.32,0.20),2)
        }
        // Dapur terbuka Anneth; titik minigame disiapkan sebagai properti visual saja.
        rect(VillageMap.kitchen,color(0.35,0.25,0.16))
        for i in 0..<6 { pot(CGPoint(x:340+CGFloat(i)*27,y:1305),size:13) }
        oval(CGRect(x:480,y:1285,width:32,height:30),color(0.22,0.24,0.20))
        oval(CGRect(x:485,y:1290,width:22,height:20),color(0.49,0.50,0.39))
        // Batu rapat di depan rumah Beryn, dikelilingi bangku kecil.
        oval(VillageMap.meetingStone.offsetBy(dx:5,dy:-5),color(0.20,0.26,0.18,0.35))
        oval(VillageMap.meetingStone,color(0.65,0.65,0.53))
        oval(VillageMap.meetingStone.insetBy(dx:8,dy:7),color(0.74,0.73,0.60))
        for i in 0..<5 { let a=CGFloat(i)*1.25; oval(CGRect(x:923+cos(a)*94,y:152+sin(a)*58,width:24,height:18),color(0.41,0.31,0.20)) }
        well()
        // Pagar pembatas dan bukaan jalan menuju hutan tetap terbaca di peta.
        fence(CGPoint(x:1730,y:25),CGPoint(x:1730,y:265))
        fence(CGPoint(x:1730,y:390),CGPoint(x:1730,y:765))
        fence(CGPoint(x:1320,y:95),CGPoint(x:1650,y:95))
        fence(CGPoint(x:1650,y:95),CGPoint(x:1650,y:280))
        fence(CGPoint(x:1310,y:280),CGPoint(x:1390,y:280))
        // Tumbuhan tepi membingkai desa tanpa menutup landmark dan jalan utama.
        for i in 0..<90 {
            let side=i%4
            var p=CGPoint(x:rand()*1920,y:rand()*1440)
            if side == 0 { p.x=rand()*90 } else if side == 1 { p.x=1835+rand()*85 }
            else if side == 2 { p.y=rand()*60 } else { p.y=1370+rand()*70 }
            if VillageMap.roads.contains(where: { road in road.contains { hypot($0.x-p.x,$0.y-p.y)<105 } }) { continue }
            tree(p,radius:30+rand()*25)
        }
        for p in [CGPoint(x:170,y:710),CGPoint(x:630,y:1150),CGPoint(x:1430,y:1000),CGPoint(x:640,y:250),CGPoint(x:1650,y:570),CGPoint(x:580,y:1340)] { tree(p,radius:44) }
        return c.makeImage()
    }
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

    private func building(_ b: VillageLandmark) {
        let r=b.rect
        if b.id == "pen" {
            // Kandang berupa halaman berpagar dan naungan kecil, bukan rumah tambahan.
            rect(r,color(0.54,0.51,0.32))
            rect(CGRect(x:r.minX,y:r.maxY-48,width:85,height:48),color(0.34,0.30,0.21))
            for i in 0..<3 {
                let x=r.minX+85+CGFloat(i)*43,y=r.minY+40+CGFloat(i%2)*26
                oval(CGRect(x:x,y:y,width:35,height:19),color(0.80,0.79,0.66))
                oval(CGRect(x:x+25,y:y+8,width:15,height:15),color(0.36,0.32,0.24))
                for dx:CGFloat in [6,24] { line([CGPoint(x:x+dx,y:y),CGPoint(x:x+dx,y:y-7)],color(0.28,0.25,0.18),3) }
            }
            return
        }
        // Bentuk rumah dan aksesori mengikuti renderer yang sudah ada di proyek.
        ellipse(CGRect(x:r.minX-4,y:r.minY-5,width:r.width+8,height:min(20,r.height*0.45)),
                color(0.18,0.24,0.14,0.26))
        cottage(r)
    }
    private func tree(_ p: CGPoint, radius: CGFloat) {
        let r=CGRect(x:p.x-radius*0.5,y:p.y-radius*0.3,width:radius,height:radius*2.3)
        ellipse(CGRect(x:r.minX-4,y:r.minY-5,width:r.width+8,height:20),color(0.18,0.24,0.14,0.26))
        pineTree(r)
    }
    private func garden(_ r: CGRect) {
        rect(r,color(0.33,0.29,0.18))
        for row in stride(from:r.minY+10,to:r.maxY,by:20) {
            line([CGPoint(x:r.minX+5,y:row),CGPoint(x:r.maxX-5,y:row)],color(0.53,0.43,0.27),3)
            for x in stride(from:r.minX+10,to:r.maxX,by:17) { oval(CGRect(x:x,y:row,width:9,height:12),color(0.37,0.49,0.22)) }
        }
    }
    private func fence(_ a: CGPoint, _ b: CGPoint) {
        line([a,b],color(0.29,0.23,0.14),7)
        let length=hypot(b.x-a.x,b.y-a.y), count=max(1,Int(length/22))
        for i in 0...count {
            let t=CGFloat(i)/CGFloat(count), p=CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t)
            rect(CGRect(x:p.x-4,y:p.y-8,width:8,height:19),color(0.65,0.54,0.33))
        }
    }
    private func pot(_ p: CGPoint, size: CGFloat) {
        oval(CGRect(x:p.x-size/2,y:p.y-size/2,width:size,height:size),color(0.64,0.36,0.22))
        oval(CGRect(x:p.x-size*0.35,y:p.y-size*0.23,width:size*0.7,height:size*0.6),color(0.25,0.22,0.15))
    }
    private func well() {
        let r=VillageMap.well
        oval(r.offsetBy(dx:6,dy:-5),color(0.19,0.23,0.16,0.4)); oval(r,color(0.65,0.65,0.51))
        oval(r.insetBy(dx:12,dy:12),color(0.13,0.25,0.26))
        for x in [r.minX+5,r.maxX-12] { rect(CGRect(x:x,y:r.minY,width:8,height:r.height),color(0.38,0.27,0.17)) }
        rect(CGRect(x:r.minX-9,y:r.maxY-20,width:r.width+18,height:31),color(0.45,0.37,0.23))
        line([CGPoint(x:r.midX,y:r.maxY-10),CGPoint(x:r.midX,y:r.midY)],color(0.78,0.68,0.45),3)
    }
    private func random() -> CGFloat { rand() }
    private func fill(_ r: CGRect, _ color: CGColor) { rect(r,color) }
    private func ellipse(_ r: CGRect, _ color: CGColor) { oval(r,color) }
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

}
