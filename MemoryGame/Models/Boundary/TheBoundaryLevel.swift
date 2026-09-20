import CoreGraphics
import Foundation

/// Map B Tahap 4 — Jalur Hutan Berkabut / The Boundary (Panel 7 Storyboard)
/// Arthur dan teman-temannya bersiap melakukan ekspedisi ke hutan luar.
/// Hutan dengan jarak pandang terbatas, pepohonan rapat, dan jalur bercabang.
/// Pohon penanda besar di kiri jalur ditandai goresan silang 'X' pisau Anneth dan pita kain terang.
/// Di ujung timur terdapat jalur keluar menuju Deep Woods (Map C).
enum TheBoundaryLevel {
    static func make(region: MemoryRegion, progress: PrologueProgress) -> PrologueLevel {
        let obstacles: [WorldObstacle] = [
            // 1. Pepohonan rapat di utara hutan berkabut (Panel 7)
            WorldObstacle(rect: CGRect(x: 0, y: 360, width: 960, height: 120), kind: "Pohon"),

            // 2. Pepohonan rapat di selatan hutan (Panel 7)
            WorldObstacle(rect: CGRect(x: 0, y: 0, width: 960, height: 80), kind: "Pohon"),

            // 3. Pepohonan pembatas yang membelah percabangan jalur (Panel 7)
            WorldObstacle(rect: CGRect(x: 180, y: 270, width: 70, height: 90), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 480, y: 260, width: 80, height: 95), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 480, y: 90, width: 85, height: 85), kind: "Pohon"),

            // 4. Penanda Pohon Besar (Panel 7: Pohon ditandai goresan pisau Anneth & pita di x: 310...365, y: 195...255)
            WorldObstacle(rect: CGRect(x: 310, y: 195, width: 55, height: 60), kind: "Pohon"),

            // 5. Pohon rapat di timur laut dan tenggara menyisakan celah kabut di tengah (y: 190...270)
            WorldObstacle(rect: CGRect(x: 650, y: 260, width: 310, height: 110), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 650, y: 80, width: 310, height: 110), kind: "Pohon")
        ]

        let patrols = [
            // Penjaga perbatasan yang berpatroli sebelum rombongan menembus kabut
            PatrolDefinition(title: "Penjaga", points: [CGPoint(x: 580, y: 180), CGPoint(x: 580, y: 300)], speed: 42, range: 140)
        ]

        return PrologueLevel(
            region: region,
            zones: [MemoryZone(piece: .boundary, rect: PrologueLevel.bounds)],
            obstacles: obstacles,
            patrols: patrols,
            book: nil,
            friends: [:],
            // Posisi pohon penanda ekspedisi (torehan sayatan pisau 'X' Anneth & pita kain)
            marker: CGPoint(x: 335, y: 225),
            // Titik kumpul keempat sahabat (Arthur, Anneth, Keneth, Roland)
            gathering: CGPoint(x: 420, y: 200),
            // Titik keluar menembus kabut menuju Deep Woods (Map C) di timur
            exit: CGPoint(x: 920, y: 240)
        )
    }
}
