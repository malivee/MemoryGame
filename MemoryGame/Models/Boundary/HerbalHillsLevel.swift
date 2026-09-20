import CoreGraphics
import Foundation

/// Map B Tahap 2 — Tepi Kebun & Perbukitan Herbal (Panel 5 Storyboard & Foto 3 Alpine Meadow)
/// Setelah rock salt dikembalikan, Kakek Beryn membutuhkan tanaman herbal dari perbukitan.
/// Player mengakses: Tepi kebun, parit kering, deretan batu batas aman desa,
/// jalur setapak bercabang di perbukitan, semak-semak herbal alpine melimpah,
/// batu besar menjorok tempat herbal langka, dan pinggir hutan cemara tempat Arthur bertemu The Hollow.
enum HerbalHillsLevel {
    static func make(region: MemoryRegion, progress: PrologueProgress) -> PrologueLevel {
        let obstacles: [WorldObstacle] = [
            // 1. Tebing perbukitan batu di utara dan barat laut
            WorldObstacle(rect: CGRect(x: 0, y: 380, width: 440, height: 100), kind: "Dinding batu"),
            WorldObstacle(rect: CGRect(x: 480, y: 400, width: 480, height: 80), kind: "Dinding batu"),

            // 2. Batu Besar / Batu Menjorok (Panel 5: Boulder raksasa tempat herbal langka di x: 640...780, y: 260...360)
            WorldObstacle(rect: CGRect(x: 640, y: 270, width: 130, height: 85), kind: "Dinding batu"),

            // 3. Parit Kering (Panel 5: Parit dangkal kering di x: 500...670, y: 170...210)
            WorldObstacle(rect: CGRect(x: 510, y: 175, width: 140, height: 35), kind: "Batu"),

            // 4. Deretan Batu Pembatas (Panel 5: Batas Aman Desa di x: 660...890, y: 115...150)
            WorldObstacle(rect: CGRect(x: 670, y: 120, width: 26, height: 36), kind: "Batu"),
            WorldObstacle(rect: CGRect(x: 730, y: 120, width: 26, height: 36), kind: "Batu"),
            WorldObstacle(rect: CGRect(x: 790, y: 120, width: 26, height: 36), kind: "Batu"),
            WorldObstacle(rect: CGRect(x: 850, y: 120, width: 26, height: 36), kind: "Batu"),

            // 5. Pinggir Hutan (Panel 5: Dense tree line di timur menutup akses sebelum tahap 3 & 4)
            WorldObstacle(rect: CGRect(x: 860, y: 160, width: 100, height: 260), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 860, y: 0, width: 100, height: 115), kind: "Pohon"),

            // 6. Tepi kebun dan semak rimbun di barat daya (x: 0...280, y: 0...160)
            WorldObstacle(rect: CGRect(x: 30, y: 30, width: 85, height: 95), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 160, y: 40, width: 75, height: 85), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 270, y: 25, width: 65, height: 60), kind: "Pagar tanaman"),

            // 7. Lereng selatan masih terkunci oleh semak tebal sebelum tahap 3
            WorldObstacle(rect: CGRect(x: 350, y: 0, width: 450, height: 75), kind: "Pagar tanaman")
        ]

        let patrols = [
            // Penjaga warga yang berpatroli di dekat batas aman desa
            PatrolDefinition(title: "Warga", points: [CGPoint(x: 440, y: 210), CGPoint(x: 560, y: 210)], speed: 38, range: 120)
        ]

        return PrologueLevel(
            region: region,
            zones: [MemoryZone(piece: .boundary, rect: PrologueLevel.bounds)],
            obstacles: obstacles,
            patrols: patrols,
            book: nil,
            friends: [:],
            // Posisi tanaman herbal di puncak batu besar menjorok (Panel 5)
            marker: CGPoint(x: 710, y: 340),
            // Posisi encounter penampakan The Hollow di tepi hutan berkabut
            gathering: CGPoint(x: 850, y: 220),
            // Jalur keluar kembali ke desa menemui Kakek Beryn
            exit: CGPoint(x: 50, y: 110)
        )
    }
}
