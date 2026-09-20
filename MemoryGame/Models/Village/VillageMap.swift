// Penjelasan file: VillageMap.swift
// Denah desa mandiri berdasarkan Story.docx. Koordinat memakai titik kiri bawah.
// Tahap hanya membatasi ruang berjalan; semua bangunan tetap terlihat sejak awal.
import Foundation
import CoreGraphics

enum VillageAccess: Int, CaseIterable {
    case opening = 1
    case barnRoute
    case rolandRoute
    case annethRoute
    case berynRoute
    case storehouseRoute
    case wholeVillage
    var title: String {
        switch self {
        case .opening: return "Rumah & sumur"
        case .barnRoute: return "Jalur lumbung"
        case .rolandRoute: return "Kandang Roland"
        case .annethRoute: return "Rumah Anneth"
        case .berynRoute: return "Rumah Kakek Beryn"
        case .storehouseRoute: return "Gudang dekat sungai"
        case .wholeVillage: return "Seluruh desa"
        }
    }
}
struct VillageLandmark {
    let id: String
    let name: String
    let rect: CGRect
    let stage: VillageAccess
    let detail: String
    var approach: CGPoint {
        if id == "beryn" { return CGPoint(x: rect.maxX + 45, y: rect.minY + 40) }
        if id == "pen" { return CGPoint(x: rect.midX, y: rect.maxY + 45) }
        return CGPoint(x: rect.midX, y: rect.minY - 40)
    }
}
enum VillageMap {
    static let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1440)
    static let spawn = CGPoint(x: 640, y: 650)
    static let landmarks: [VillageLandmark] = [
        .init(id: "arthur", name: "Rumah Arthur & Kakek", rect: CGRect(x: 280, y: 570, width: 260, height: 195), stage: .opening,
              detail: "Teras kayu, meja, tungku, dan ambang pintu tempat Kakek memantau jalan."),
        .init(id: "mara", name: "Rumah Bu Mara", rect: CGRect(x: 1160, y: 570, width: 230, height: 185), stage: .opening,
              detail: "Halaman dekat sumur: pot tanah liat, rak miring, genangan cucian, dan pecahan bata."),
        .init(id: "barn", name: "Lumbung Desa", rect: CGRect(x: 1020, y: 1060, width: 300, height: 205), stage: .barnRoute,
              detail: "Lumbung Keneth: karung panen, dinding lembap, papan lapuk, dan engsel pintu miring."),
        .init(id: "anneth", name: "Rumah Anneth", rect: CGRect(x: 290, y: 1050, width: 260, height: 205), stage: .annethRoute,
              detail: "Dapur belakang yang rapi: stok umbi, papan inventori, panci, dan lumpang."),
        .init(id: "beryn", name: "Rumah Kakek Beryn", rect: CGRect(x: 800, y: 230, width: 260, height: 185), stage: .berynRoute,
              detail: "Batu pipih besar di depan rumah menjadi tempat pertemuan warga."),
        .init(id: "base", name: "Gudang Kosong", rect: CGRect(x: 1580, y: 980, width: 220, height: 170), stage: .storehouseRoute,
              detail: "Gudang dekat sungai kecil; lokasi secret base Arthur dan teman-teman."),
        .init(id: "pen", name: "Kandang & pagar Roland", rect: CGRect(x: 1340, y: 130, width: 245, height: 140), stage: .rolandRoute,
              detail: "Kandang di ujung permukiman dengan tiang dan pagar kayu yang perlu diperbaiki.")
    ]
    static let well = CGRect(x: 865, y: 765, width: 80, height: 85)
    static let meetingStone = CGRect(x: 865, y: 135, width: 130, height: 55)
    static let kitchen = CGRect(x: 320, y: 1280, width: 200, height: 55)
    // Jaringan jalan utuh: simpang sumur, cabang rumah, lumbung, dan batas hutan.
    static let roads: [[CGPoint]] = [
        [CGPoint(x: 0, y: 480), CGPoint(x: 580, y: 480), CGPoint(x: 775, y: 600), CGPoint(x: 790, y: 850), CGPoint(x: 700, y: 1020), CGPoint(x: 740, y: 1440)],
        [CGPoint(x: 0, y: 900), CGPoint(x: 710, y: 900), CGPoint(x: 1000, y: 900), CGPoint(x: 1500, y: 880), CGPoint(x: 1710, y: 920)],
        [CGPoint(x: 775, y: 600), CGPoint(x: 1090, y: 490), CGPoint(x: 1510, y: 380), CGPoint(x: 1920, y: 290)],
        [CGPoint(x: 410, y: 535), CGPoint(x: 440, y: 480)],
        [CGPoint(x: 1275, y: 535), CGPoint(x: 1240, y: 490)],
        [CGPoint(x: 1170, y: 1020), CGPoint(x: 1120, y: 900)],
        [CGPoint(x: 420, y: 1010), CGPoint(x: 470, y: 900)],
        [CGPoint(x: 930, y: 420), CGPoint(x: 1030, y: 490)],
        [CGPoint(x: 1600, y: 880), CGPoint(x: 1690, y: 940)],
        [CGPoint(x: 1460, y: 305), CGPoint(x: 1510, y: 380)]
    ]
    static let river: [CGPoint] = [CGPoint(x: 1470, y: 1440), CGPoint(x: 1500, y: 1330), CGPoint(x: 1620, y: 1270), CGPoint(x: 1750, y: 1240), CGPoint(x: 1920, y: 1180)]
    // Collision sesuai bangunan dan properti besar; dekorasi tanah tidak menghalangi.
    static var solids: [CGRect] {
        landmarks.map(\.rect) + [well, meetingStone, kitchen,
            CGRect(x: 1420, y: 1320, width: 150, height: 120),
            CGRect(x: 1500, y: 1250, width: 190, height: 90),
            CGRect(x: 1650, y: 1200, width: 270, height: 100),
            CGRect(x: 1720, y: 0, width: 22, height: 265),
            CGRect(x: 1720, y: 390, width: 22, height: 380),
            CGRect(x: 1450, y: 600, width: 70, height: 85)]
    }
    // Gabungan area akses bertahap mencegah pemain memutari ujung sebuah invisible wall.
    static func accessible(_ point: CGPoint, stage: VillageAccess) -> Bool {
        accessibleAreas(stage: stage).contains { $0.contains(point) }
    }
    static func accessibleAreas(stage: VillageAccess) -> [CGRect] {
        if stage == .wholeVillage { return [bounds.insetBy(dx: 36, dy: 36)] }
        // Termasuk Rumah Arthur, Kakek, sumur, dan Rumah Bu Mara pada progresi awal.
        let opening = CGRect(x: 250, y: 445, width: 1300, height: 495)
        let barn = CGRect(x: 690, y: 820, width: 770, height: 570)
        let roland = CGRect(x: 1050, y: 285, width: 580, height: 270)
        let anneth = CGRect(x: 250, y: 880, width: 520, height: 520)
        let beryn = CGRect(x: 760, y: 180, width: 390, height: 380)
        let storehouse = CGRect(x: 1450, y: 850, width: 430, height: 430)
        switch stage {
        case .opening: return [opening]
        case .barnRoute: return [opening, barn]
        case .rolandRoute: return [opening, barn, roland]
        case .annethRoute: return [opening, barn, roland, anneth]
        case .berynRoute: return [opening, barn, roland, anneth, beryn]
        case .storehouseRoute: return [opening, barn, roland, anneth, beryn, storehouse]
        case .wholeVillage: return [bounds.insetBy(dx: 36, dy: 36)]
        }
    }
}
