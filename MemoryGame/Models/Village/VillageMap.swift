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
    var approach: CGPoint { VillageMap.approach(for: id) }
}

// Koordinat dipetakan ke gambar Desa Arthur.png (1672 × 941), tanpa distorsi.
// point/rect menerima koordinat dari sudut kiri atas gambar referensi.
enum VillageMap {
    static let bounds = CGRect(x: 0, y: 0, width: 1672, height: 941)
    static func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x:x,y:bounds.height-y) }
    static func rect(_ x: CGFloat,_ y: CGFloat,_ w: CGFloat,_ h: CGFloat) -> CGRect {
        CGRect(x:x,y:bounds.height-y-h,width:w,height:h)
    }
    static let spawn = point(575,460)
    static let grandpa = point(558,445)
    static let mara = point(775,478)
    static let rack = point(794,459)
    static let rackApproach = point(795,490)
    static let wellApproach = point(846,550)
    static let wellResidents = [point(792,547),point(895,545),point(907,500)]
    static let storyPositions: [Int:CGPoint] = [
        1:mara, 2:grandpa, 3:point(1200,334), 4:point(1215,565),
        5:point(646,603), 7:point(646,603), 9:point(1160,806),
        11:point(600,716), 12:point(902,550)
    ]
    static func approach(for id: String) -> CGPoint {
        switch id {
        case "arthur": return grandpa
        case "mara": return mara
        case "barn": return storyPositions[3]!
        case "anneth": return storyPositions[5]!
        case "beryn": return storyPositions[9]!
        case "base": return storyPositions[11]!
        case "pen": return storyPositions[4]!
        default: return spawn
        }
    }
    static let landmarks: [VillageLandmark] = [
        .init(id:"arthur",name:"Rumah Arthur & Kakek",rect:rect(430,325,128,102),stage:.opening,detail:"Rumah beratap merah di barat sumur."),
        .init(id:"mara",name:"Rumah Bu Mara",rect:rect(674,355,121,105),stage:.opening,detail:"Rumah di sebelah barat sumur; tempat membantu Bu Mara."),
        .init(id:"barn",name:"Lumbung Desa",rect:rect(1182,194,156,125),stage:.barnRoute,detail:"Lumbung Keneth di ujung jalan utara."),
        .init(id:"anneth",name:"Rumah Anneth",rect:rect(494,483,132,98),stage:.annethRoute,detail:"Rumah beratap biru dengan kebun sayur."),
        .init(id:"beryn",name:"Rumah Kakek Beryn",rect:rect(1145,639,138,116),stage:.berynRoute,detail:"Rumah di tenggara dengan batu pertemuan di halaman."),
        .init(id:"base",name:"Gudang Kosong",rect:rect(465,637,91,78),stage:.storehouseRoute,detail:"Gudang kecil di samping sungai dan jembatan."),
        .init(id:"pen",name:"Kandang Roland",rect:rect(1148,443,185,99),stage:.rolandRoute,detail:"Kandang ternak di timur sumur.")
    ]
    static let well = rect(821,478,51,49)
    static let meetingStone = rect(1124,754,63,29)
    static let kitchen = rect(530,576,75,35)
    static let roads: [[CGPoint]] = [
        [point(530,437),point(650,477),point(766,505),point(799,535),point(750,590),point(705,659),point(620,732),point(577,762),point(459,814)],
        [point(766,505),point(861,462),point(963,419),point(1062,375),point(1136,331),point(1210,341),point(1340,347),point(1440,296),point(1485,204),point(1517,119)],
        [point(799,535),point(869,552),point(956,582),point(1043,596),point(1158,588),point(1240,603),point(1372,554),point(1431,488),point(1477,411)],
        [point(646,603),point(750,590)],
        [point(775,478),point(795,490),point(799,535),point(846,550),point(907,500)],
        [point(1210,341),point(1200,334)],
        [point(1215,565),point(1240,603)],
        [point(1240,603),point(1301,658),point(1303,765),point(1213,806),point(1160,806)],
        [point(620,732),point(600,716)],
        [point(530,437),point(558,445),point(575,460)]
    ]
    static let river = [point(169,413),point(273,660),point(430,717),point(633,777),point(980,914)]
    static var solids: [CGRect] {
        landmarks.map(\.rect) + [well,meetingStone,kitchen,rect(911,319,72,65)]
    }
    // Jalan mengikuti gambar. Daerah di luar koridor/halaman adalah lereng atau sungai.
    static func onWalkableGround(_ p: CGPoint) -> Bool {
        for road in roads {
            for (a,b) in zip(road,road.dropFirst()) {
                let dx=b.x-a.x,dy=b.y-a.y
                let t=max(0,min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/max(1,dx*dx+dy*dy)))
                if hypot(p.x-a.x-t*dx,p.y-a.y-t*dy) < 40 { return true }
            }
        }
        return (Array(storyPositions.values)+wellResidents+[spawn,wellApproach]).contains {
            hypot(p.x-$0.x,p.y-$0.y) < 48
        }
    }
    static func accessible(_ p: CGPoint,stage: VillageAccess) -> Bool {
        accessibleAreas(stage:stage).contains { $0.contains(p) }
    }
    static func accessibleAreas(stage: VillageAccess) -> [CGRect] {
        if stage == .wholeVillage { return [bounds.insetBy(dx:24,dy:24)] }
        var areas = [rect(365,290,585,295)]
        if stage.rawValue >= VillageAccess.barnRoute.rawValue {
            areas += [rect(855,360,270,200),rect(1025,175,475,240)]
        }
        if stage.rawValue >= VillageAccess.rolandRoute.rawValue { areas += [rect(882,408,550,235)] }
        if stage.rawValue >= VillageAccess.annethRoute.rawValue { areas += [rect(440,475,345,207)] }
        if stage.rawValue >= VillageAccess.berynRoute.rawValue { areas += [rect(1060,570,307,285)] }
        if stage.rawValue >= VillageAccess.storehouseRoute.rawValue { areas += [rect(418,635,365,175)] }
        return areas
    }
}
