import CoreGraphics

enum EchoesBoundaryLevel {
    static func make(region: MemoryRegion) -> PrologueLevel {
        let forest = [
            WorldObstacle(rect: CGRect(x: 0, y: 0, width: 1800, height: 140), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 0, y: 340, width: 1800, height: 140), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 205, y: 140, width: 120, height: 38), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 350, y: 302, width: 125, height: 38), kind: "Pohon"),
            WorldObstacle(rect: CGRect(x: 805, y: 140, width: 995, height: 38), kind: "Pohon")
        ]
        let illusion = [
            WorldObstacle(rect: CGRect(x: 385, y: 190, width: 95, height: 70), kind: "Rumah ilusi"),
            WorldObstacle(rect: CGRect(x: 495, y: 190, width: 95, height: 70), kind: "Rumah ilusi"),
            WorldObstacle(rect: CGRect(x: 605, y: 190, width: 95, height: 70), kind: "Rumah ilusi"),
            WorldObstacle(rect: CGRect(x: 525, y: 265, width: 42, height: 35), kind: "Sumur")
        ]
        return PrologueLevel(region: region,
                             zones: [],
                             obstacles: forest + illusion, patrols: [], book: nil,
                             friends: [:], marker: nil, gathering: nil,
                             exit: CGPoint(x: 1740, y: 240))
    }
}
