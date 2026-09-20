import CoreGraphics
import Foundation

/// Map B Tahap 1 — Tambang Rock Salt (Panel 4 Storyboard & Foto 1 Cardona Salt Mountain)
/// Arthur mendapat tugas dari Anneth untuk mengambil rock salt untuk dapur.
/// Player mengakses: Jalur sempit dari desa, lereng berbatu, area kerja penambang,
/// peneduh kain, peti-peti kayu, rel kayu tambang, batuan garam, dan bagian depan Mulut Tambang.
/// Lorong dalam tambang gelap gulita dan tertutup balok kayu.
enum RockSaltMineLevel {
    static func make(region: MemoryRegion, progress: PrologueProgress) -> PrologueLevel {
        let obstacles: [WorldObstacle] = [
            // 1. Tebing gunung garam raksasa Cardona di utara (membatasi lereng atas)
            WorldObstacle(rect: CGRect(x: 0, y: 360, width: 270, height: 120), kind: "Dinding batu"),
            WorldObstacle(rect: CGRect(x: 390, y: 360, width: 570, height: 120), kind: "Dinding batu"),

            // 2. Mulut Tambang Garam (Pintu masuk kayu di x: 270...390, y: 340...420)
            // Lorong dalam tambang diblokir agar player hanya bisa berada di bibir gua
            WorldObstacle(rect: CGRect(x: 270, y: 400, width: 120, height: 80), kind: "Dinding batu"),
            WorldObstacle(rect: CGRect(x: 265, y: 340, width: 25, height: 70), kind: "Dinding batu"), // Kusen balok kiri
            WorldObstacle(rect: CGRect(x: 370, y: 340, width: 25, height: 70), kind: "Dinding batu"), // Kusen balok kanan

            // 3. Peneduh Kain / Tenda Kanvas Penambang (x: 230...295, y: 235...285)
            WorldObstacle(rect: CGRect(x: 230, y: 235, width: 65, height: 50), kind: "Peti"),

            // 4. Peti-peti kayu tambang & gerobak kayu di rel (x: 410...480, y: 260...310)
            WorldObstacle(rect: CGRect(x: 415, y: 265, width: 65, height: 45), kind: "Peti"),
            WorldObstacle(rect: CGRect(x: 335, y: 230, width: 45, height: 35), kind: "Batu"),

            // 5. Tebing Kecil di kiri bawah yang mengapit jalur sempit (Panel 4)
            WorldObstacle(rect: CGRect(x: 0, y: 0, width: 150, height: 95), kind: "Dinding batu"),
            WorldObstacle(rect: CGRect(x: 0, y: 175, width: 85, height: 140), kind: "Dinding batu"),

            // 6. Batas lereng selatan & tebing garam masif timur (mengunci akses ke timur/hutan pada tahap 1)
            WorldObstacle(rect: CGRect(x: 150, y: 0, width: 810, height: 60), kind: "Dinding batu"),
            WorldObstacle(rect: CGRect(x: 560, y: 60, width: 400, height: 320), kind: "Dinding batu"),

            // 7. Pohon mineral kering berkerak garam di pinggir jalur
            WorldObstacle(rect: CGRect(x: 180, y: 65, width: 55, height: 75), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 500, y: 150, width: 50, height: 70), kind: "Pohon")
        ]

        let patrols = [
            // Penambang yang sedang beristirahat/bekerja di sekitar peneduh kain
            PatrolDefinition(title: "Penambang", points: [CGPoint(x: 300, y: 270), CGPoint(x: 420, y: 270)], speed: 32, range: 100)
        ]

        return PrologueLevel(
            region: region,
            zones: [MemoryZone(piece: .boundary, rect: PrologueLevel.bounds)],
            obstacles: obstacles,
            patrols: patrols,
            book: nil,
            friends: [:],
            // Titik deposit bongkahan rock salt yang masih bisa dijangkau dekat mulut tambang
            marker: CGPoint(x: 330, y: 350),
            gathering: nil,
            // Titik keluar kembali ke arah desa di ujung kiri bawah jalur sempit
            exit: CGPoint(x: 40, y: 120)
        )
    }
}
