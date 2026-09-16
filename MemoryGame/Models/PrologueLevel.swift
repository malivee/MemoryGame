// Penjelasan file: PrologueLevel.swift
// Menyusun peta rumah, desa, dan kaki bukit beserta rintangan, patroli, dan titik interaksi.
// Keping yang terpasang menentukan area berkabut, variasi danau, dan rotasi rintangan jalan.
// Data rintangan ini digunakan bersama oleh gambar latar dan navigasi agar tampilannya sesuai aturan gerak.

import CoreGraphics
import Foundation

struct MemoryZone {
    let piece: MemoryPiece
    let rect: CGRect
}
struct WorldObstacle {
    let rect: CGRect
    let kind: String
}
struct PatrolDefinition {
    let title: String
    let points: [CGPoint]
    let speed: CGFloat
    let range: CGFloat
}
struct PrologueLevel {
    static let bounds = CGRect(x: 0, y: 0, width: 960, height: 480)
    let region: MemoryRegion
    let zones: [MemoryZone]
    var obstacles: [WorldObstacle]
    let patrols: [PatrolDefinition]
    let book: CGPoint?
    let friends: [FriendID: CGPoint]
    let marker: CGPoint?
    let gathering: CGPoint?
    let exit: CGPoint?

    // Membentuk data wilayah dan menyesuaikan jalan serta danau dengan keping yang terpasang.
    static func make(region: MemoryRegion, progress: PrologueProgress) -> PrologueLevel {
        switch region {
        case .house:
            return .init(region: region,
                zones: [.init(piece: .house, rect: bounds)],
                obstacles: [
                    .init(rect: CGRect(x: 300, y: 80, width: 100, height: 100), kind: "Peti"),
                    .init(rect: CGRect(x: 470, y: 250, width: 100, height: 145), kind: "Lemari"),
                    .init(rect: CGRect(x: 680, y: 80, width: 120, height: 65), kind: "Meja"),
                    .init(rect: CGRect(x: 160, y: 280, width: 120, height: 130), kind: "Tempat tidur")],
                patrols: [.init(title: "Orang tua", points: [CGPoint(x: 430, y: 205), CGPoint(x: 800, y: 205), CGPoint(x: 800, y: 415), CGPoint(x: 430, y: 415)], speed: 48, range: 190)],
                book: CGPoint(x: 870, y: 360), friends: [:], marker: nil, gathering: nil, exit: nil)
        case .village:
            let roadZone = CGRect(x: 300, y: 0, width: 360, height: 480)
            let turns = progress.placement(of: .villageRoad)?.turns ?? 0
            func roadObstacle(_ rect: CGRect, kind: String) -> WorldObstacle {
                func rotate(_ p: CGPoint) -> CGPoint {
                    var x = p.x - roadZone.midX, y = p.y - roadZone.midY
                    for _ in 0..<turns { let old = x; x = y; y = -old }
                    return CGPoint(x: roadZone.midX + x, y: roadZone.midY + y)
                }
                let a = rotate(CGPoint(x: rect.minX, y: rect.minY))
                let b = rotate(CGPoint(x: rect.maxX, y: rect.maxY))
                return .init(rect: CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y)).intersection(roadZone), kind: kind)
            }
            return .init(region: region, zones: [
                .init(piece: .yard, rect: CGRect(x: 0, y: 0, width: 300, height: 480)),
                .init(piece: .villageRoad, rect: CGRect(x: 300, y: 0, width: 360, height: 480)),
                .init(piece: .garden, rect: CGRect(x: 660, y: 0, width: 300, height: 480))],
                obstacles: [
                    .init(rect: CGRect(x: 80, y: 150, width: 140, height: 90), kind: "Rumah"),
                    .init(rect: CGRect(x: 45, y: 390, width: 90, height: 70), kind: "Rumah"),
                    .init(rect: CGRect(x: 770, y: 340, width: 155, height: 105), kind: "Rumah"),
                    .init(rect: CGRect(x: 20, y: 270, width: 42, height: 70), kind: "Pohon"),
                    .init(rect: CGRect(x: 870, y: 25, width: 70, height: 85), kind: "Pohon"),
                    .init(rect: CGRect(x: 20, y: 20, width: 32, height: 80), kind: "Pohon"),
                    roadObstacle(CGRect(x: 330, y: 190, width: 115, height: 65), kind: "Pagar tanaman"),
                    roadObstacle(CGRect(x: 525, y: 240, width: 85, height: 80), kind: "Peti"),
                    .init(rect: CGRect(x: 730, y: 200, width: 140, height: 65), kind: "Pagar tanaman")],
                patrols: [.init(title: "Warga", points: [CGPoint(x: 310, y: 130), CGPoint(x: 620, y: 130), CGPoint(x: 620, y: 390), CGPoint(x: 310, y: 390)], speed: 53, range: 165)],
                book: nil, friends: [.keneth: CGPoint(x: 170, y: 350), .roland: CGPoint(x: 580, y: 80), .anneth: CGPoint(x: 520, y: 390)],
                marker: nil, gathering: nil, exit: nil)
        case .foothills:
            let pathRect = CGRect(x: 300, y: 220, width: 330, height: 260)
            let turns = progress.placement(of: .oldPath)?.turns ?? 0
            let center = CGPoint(x: pathRect.midX, y: pathRect.midY)
            func rotate(_ p: CGPoint) -> CGPoint {
                var x = p.x - center.x
                var y = p.y - center.y
                for _ in 0..<turns { let old = x; x = y; y = -old }
                return CGPoint(x: center.x + x, y: center.y + y)
            }
            var obstacles: [WorldObstacle] = [
                .init(rect: CGRect(x: 15, y: 350, width: 70, height: 110), kind: "Batu"),
                .init(rect: CGRect(x: 210, y: 370, width: 75, height: 100), kind: "Batu"),
                .init(rect: CGRect(x: 15, y: 140, width: 40, height: 75), kind: "Pohon"),
                .init(rect: CGRect(x: 650, y: 400, width: 80, height: 65), kind: "Pohon"),
                .init(rect: CGRect(x: 820, y: 20, width: 115, height: 45), kind: "Pohon"),
                .init(rect: CGRect(x: 100, y: 250, width: 95, height: 100), kind: "Batu"),
                .init(rect: CGRect(x: 680, y: 240, width: 75, height: 110), kind: "Batu"),
                .init(rect: CGRect(x: 830, y: 250, width: 65, height: 65), kind: "Pagar tanaman")]
            if progress.installed(.oldPath) {
                for y: CGFloat in [285, 395] {
                    let a = rotate(CGPoint(x: 300, y: y))
                    let b = rotate(CGPoint(x: 630, y: y + 20))
                    let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y)).intersection(pathRect)
                    obstacles.append(.init(rect: rect, kind: "Dinding batu"))
                }
            }
            if progress.lakeVariant == .lake {
                obstacles.append(.init(rect: CGRect(x: 350, y: 45, width: 230, height: 120), kind: "Air"))
            }
            return .init(region: region, zones: [
                .init(piece: .mountain, rect: CGRect(x: 0, y: 0, width: 300, height: 480)),
                .init(piece: .oldPath, rect: pathRect),
                .init(piece: .lake, rect: CGRect(x: 300, y: 0, width: 330, height: 220)),
                .init(piece: .boundary, rect: CGRect(x: 630, y: 0, width: 330, height: 480))],
                obstacles: obstacles,
                patrols: [
                    .init(title: "Warga", points: [CGPoint(x: 330, y: 350), CGPoint(x: 590, y: 350)], speed: 44, range: 140),
                    .init(title: "Penjaga", points: [CGPoint(x: 785, y: 90), CGPoint(x: 785, y: 415)], speed: 48, range: 175)],
                book: nil, friends: [:], marker: rotate(CGPoint(x: 555, y: 350)),
                gathering: CGPoint(x: 710, y: 110), exit: CGPoint(x: 915, y: 390))
        }
    }

    func available(_ zone: MemoryZone, progress: PrologueProgress) -> Bool {
        if zone.piece == .lake { return progress.lakeVariant != nil }
        if zone.piece == .boundary { return progress.installed(.boundary) || progress.installed(.closing) }
        return progress.installed(zone.piece)
    }
    // Menghasilkan persegi area yang belum tersedia untuk visual kabut dan penghalang navigasi.
    func fog(progress: PrologueProgress) -> [CGRect] {
        zones.filter { !available($0, progress: progress) }.map(\.rect)
    }
    // Memilih titik masuk awal berdasarkan lokasi keping; navigasi kemudian mencari posisi terbuka terdekat.
    func spawn(for entry: MemoryPiece, progress: PrologueProgress) -> CGPoint {
        switch entry {
        case .house: return CGPoint(x: 85, y: 90)
        case .yard: return CGPoint(x: 70, y: 70)
        case .villageRoad: return CGPoint(x: 355, y: 80)
        case .garden: return CGPoint(x: 740, y: 80)
        case .mountain: return CGPoint(x: 90, y: 95)
        case .oldPath: return CGPoint(x: 465, y: 350)
        case .lake, .dryLake: return CGPoint(x: 465, y: 25)
        case .boundary, .closing: return CGPoint(x: 710, y: 110)
        }
    }
}
