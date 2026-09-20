import CoreGraphics
import Foundation

/// Map B Tahap 3 — Lereng Hutan / Jalur Pencari Kayu (Panel 6 Storyboard & Foto 2)
/// Setelah peristiwa Hollow, Arthur mencari kayu bakar di lereng hutan.
/// Mekanisme investigasi tanah longsor & akar pohon tua terbuka untuk menemukan Buku Elias.
/// Area yang dapat diakses: Jalur pencari kayu, bekas roda gerobak, tunggul tebangan,
/// gelondongan kayu pinus, tebing tanah longsor kecil, dan jalinan akar pohon tua raksasa.
enum WoodcutterSlopeLevel {
    static func make(region: MemoryRegion, progress: PrologueProgress) -> PrologueLevel {
        let obstacles: [WorldObstacle] = [
            // 1. Lereng berbatu dan lereng atas di utara
            WorldObstacle(rect: CGRect(x: 0, y: 380, width: 960, height: 100), kind: "Dinding batu"),

            // 2. Pohon Tua Berakar Terbuka Raksasa di Kiri (Panel 6)
            WorldObstacle(rect: CGRect(x: 90, y: 200, width: 150, height: 180), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 180, y: 170, width: 90, height: 75), kind: "Batu"),

            // 3. Tanah Longsor Kecil di Kanan (Panel 6)
            WorldObstacle(rect: CGRect(x: 540, y: 170, width: 135, height: 95), kind: "Dinding batu"),

            // 4. Tunggul bekas tebangan pohon & gelondongan kayu pinus (kiri bawah)
            WorldObstacle(rect: CGRect(x: 110, y: 110, width: 45, height: 45), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 230, y: 125, width: 45, height: 45), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 150, y: 80, width: 100, height: 35), kind: "Peti"), // Gelondongan kayu 1
            WorldObstacle(rect: CGRect(x: 310, y: 140, width: 85, height: 30), kind: "Peti"),  // Gelondongan kayu 2

            // 5. Hutan lebat di selatan (menutup lereng bawah)
            WorldObstacle(rect: CGRect(x: 0, y: 0, width: 500, height: 75), kind: "Pohon"),

            // 6. Jalur menuju gerbang The Boundary ke arah timur masih terkunci sebelum tahap 4
            WorldObstacle(rect: CGRect(x: 690, y: 0, width: 270, height: 170), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 770, y: 170, width: 190, height: 210), kind: "Batu")
        ]

        let patrols = [
            // Penjaga warga yang memeriksa jalur penebangan
            PatrolDefinition(title: "Warga", points: [CGPoint(x: 240, y: 240), CGPoint(x: 390, y: 240)], speed: 40, range: 120)
        ]

        return PrologueLevel(
            region: region,
            zones: [MemoryZone(piece: .boundary, rect: PrologueLevel.bounds)],
            obstacles: obstacles,
            patrols: patrols,
            // Titik Buku: Buku Elias di sela-sela akar pohon tua pada tanah longsor (Panel 6 X)
            book: CGPoint(x: 480, y: 220),
            friends: [:],
            // Titik tumpukan kayu tebangan yang bisa dikumpulkan
            marker: CGPoint(x: 180, y: 140),
            gathering: nil,
            // Titik keluar kembali ke desa
            exit: CGPoint(x: 45, y: 210)
        )
    }
}
