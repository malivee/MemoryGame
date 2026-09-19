import Foundation
import CoreGraphics

/// Ground footprints used by navigation, independent of SpriteKit rendering.
enum ExplorationCollisionGeometry {
    static func solids(for level: PrologueLevel) -> [CGRect] {
        if level.region == .echoes {
            // Echoes is a single-road map: the forest bands are fully blocked.
            return level.obstacles.map(\.rect)
        }
        if level.region == .house {
            var solids: [CGRect] = []
            // 1. Dinding Atas (Top Wall Barrier)
            // Dinding balok kayu tegak di y >= 368. Pemain TIDAK BISA menginjak atau menembus dinding ini!
            solids.append(CGRect(x: 0, y: 368, width: 960, height: 112))

            // 2. Dinding Bawah (Bottom Perimeter Barrier)
            // Membatasi lantai agar pemain tidak melangkah keluar dari papan kayu bawah
            solids.append(CGRect(x: 0, y: 0, width: 960, height: 26))

            // 3. Dinding Samping Kiri (Left Wall Barrier)
            // Di atas pintu (y: 335 ke atas):
            solids.append(CGRect(x: 0, y: 335, width: 90, height: 145))
            // Di bawah pintu (y: 195 ke bawah):
            solids.append(CGRect(x: 0, y: 0, width: 75, height: 195))

            // 4. Dinding Samping Kanan (Right Wall Barrier)
            // Membatasi lantai kanan di x >= 895
            solids.append(CGRect(x: 895, y: 0, width: 65, height: 480))

            // 5. Perabotan Kabin (Mengikuti Aset Visual Game Secara Akurat):
            // A. Lemari Rak Sudut Kayu Bertingkat + Topeng Buruan di Kiri Atas:
            // Aset digambar di CGRect(x: 140, y: 300, width: 85, height: 115)
            solids.append(CGRect(x: 140, y: 298, width: 85, height: 75))

            // B. Lemari Laci Kayu di Dinding Kanan:
            // Aset digambar di CGRect(x: 595, y: 315, width: 95, height: 80)
            solids.append(CGRect(x: 595, y: 312, width: 95, height: 60))

            // C. Meja Pajangan Buku Kuno di Sudut Kanan:
            // Aset digambar di CGRect(x: 840, y: 335, width: 60, height: 48)
            solids.append(CGRect(x: 838, y: 332, width: 60, height: 40))

            // D. Meja Makan Ukir Rendah + Panci Sup Panas Mengepul:
            // Aset digambar di CGRect(x: 540, y: 155, width: 135, height: 75)
            solids.append(CGRect(x: 540, y: 152, width: 135, height: 68))

            // E. Matras Tidur Anyaman Wol / Kasur:
            // Aset digambar di CGRect(x: 480, y: 30, width: 215, height: 110)
            solids.append(CGRect(x: 480, y: 28, width: 215, height: 95))

            // F. Pot Tanaman Hias Daun Lebar di Sudut Kiri Bawah:
            // Aset digambar di CGRect(x: 95, y: 28, width: 34, height: 28)
            solids.append(CGRect(x: 90, y: 24, width: 44, height: 35))

            // G. Figur Ibu Duduk Bersila Merajut di Tengah Karpet:
            // Posisi di (305, 204)
            solids.append(CGRect(x: 288, y: 188, width: 34, height: 32))

            return solids
        }

        return level.obstacles.compactMap { obstacle in
            let r = obstacle.rect
            switch obstacle.kind {
            case "Pohon":
                // Batang pohon di dasar (tapak di tanah). Arthur bisa lewat di belakang/samping kanopi daun.
                let trunkW: CGFloat = max(14, min(22, r.width * 0.35))
                let trunkH: CGFloat = max(16, min(24, r.height * 0.28))
                return CGRect(x: r.midX - trunkW / 2, y: r.minY, width: trunkW, height: trunkH)

            case "Batu":
                // Alas batu yang menyentuh tanah (lower 45%)
                let rockW = max(18, r.width * 0.72)
                let rockH = max(16, r.height * 0.44)
                return CGRect(x: r.midX - rockW / 2, y: r.minY, width: rockW, height: rockH)

            case "Rumah":
                // Pondasi tiang panggung pondok di tanah (lower 52%)
                let houseW = max(30, r.width * 0.88)
                let houseH = max(24, r.height * 0.52)
                return CGRect(x: r.midX - houseW / 2, y: r.minY, width: houseW, height: houseH)

            case "Pagar tanaman":
                // Semak pagar pembatas di tanah (lower 55%)
                let hedgeH = max(18, r.height * 0.55)
                return CGRect(x: r.minX + 2, y: r.minY, width: max(12, r.width - 4), height: hedgeH)

            case "Peti":
                // Peti kayu di tanah (lower 60%)
                let crateH = max(16, r.height * 0.60)
                return CGRect(x: r.minX + 2, y: r.minY, width: max(12, r.width - 4), height: crateH)

            case "Dinding batu", "Air":
                // Dinding tebing dan danau air tetap solid penuh
                return r

            default:
                return r
            }
        }
    }
}
