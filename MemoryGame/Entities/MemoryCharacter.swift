// Penjelasan file: MemoryCharacter.swift
// Membuat karakter sederhana untuk Arthur, teman, dan warga.
// MemoryCharacter berjalan mengikuti rute; MemoryPatrol mengelola patroli, bidang pandang, dan tingkat kecurigaan.

import SpriteKit

final class MemoryCharacter: SKNode {
    let title: String
    var route: [CGPoint] = []
    let body: SKShapeNode
    init(title: String, color: SKColor) {
        self.title = title
        body = SKShapeNode(circleOfRadius: 12)
        super.init()
        body.fillColor = color
        body.strokeColor = SKColor(white: 0.1, alpha: 0.7)
        body.lineWidth = 2
        addChild(body)
        let face = SKShapeNode(circleOfRadius: 3)
        face.fillColor = .white; face.strokeColor = .clear
        face.position = CGPoint(x: 0, y: 6)
        body.addChild(face)
        storyLabel(title, at: CGPoint(x: 0, y: 25), size: 11)
        zPosition = 20
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }
    // Mengikuti titik rute dengan kecepatan berbasis waktu sambil memeriksa tabrakan melalui navigasi.
    func walk(dt: CGFloat, speed: CGFloat, navigation: MemoryNavigation) {
        guard let next = route.first else { return }
        let dx = next.x - position.x, dy = next.y - position.y
        let length = hypot(dx, dy)
        if length < 5 { route.removeFirst(); return }
        let amount = min(length, speed * dt)
        let previous = position
        position = navigation.moved(from: position, by: CGVector(dx: dx / length * amount, dy: dy / length * amount))
        if hypot(position.x - previous.x, position.y - previous.y) < 0.01 { route.removeAll() }
        body.zRotation = atan2(dy, dx) - .pi / 2
    }
}

final class MemoryPatrol {
    let definition: PatrolDefinition
    let character: MemoryCharacter
    let field = SKShapeNode()
    var waypoint = 1
    var angle: CGFloat = 0
    var suspicion: CGFloat = 0
    var pause: CGFloat = 0
    let halfAngle: CGFloat = .pi / 5

    init(_ definition: PatrolDefinition) {
        self.definition = definition
        character = MemoryCharacter(title: definition.title, color: SKColor(red: 0.71, green: 0.48, blue: 0.37, alpha: 1))
        character.position = definition.points[0]
        field.fillColor = SKColor(red: 0.98, green: 0.81, blue: 0.42, alpha: 0.14)
        field.strokeColor = SKColor(white: 1, alpha: 0.07)
        field.zPosition = 8
    }
    // Menggerakkan patroli, menguji jarak dan arah pandang, lalu menaikkan atau menurunkan kecurigaan.
    func update(dt: CGFloat, player: CGPoint, navigation: MemoryNavigation) -> Bool {
        let goal = definition.points[waypoint]
        let dx = goal.x - character.position.x, dy = goal.y - character.position.y
        let length = hypot(dx, dy)
        if pause > 0 { pause -= dt }
        else if length < 6 { waypoint = (waypoint + 1) % definition.points.count; pause = 1.1 }
        else {
            angle = atan2(dy, dx)
            let delta = CGVector(dx: cos(angle) * definition.speed * dt, dy: sin(angle) * definition.speed * dt)
            let next = navigation.moved(from: character.position, by: delta)
            if hypot(next.x - character.position.x, next.y - character.position.y) < 0.01 {
                waypoint = (waypoint + 1) % definition.points.count; pause = 0.8
            } else { character.position = next }
        }
        character.body.zRotation = angle - .pi / 2
        let offset = CGPoint(x: player.x - character.position.x, y: player.y - character.position.y)
        let difference = atan2(sin(atan2(offset.y, offset.x) - angle), cos(atan2(offset.y, offset.x) - angle))
        let seen = hypot(offset.x, offset.y) < definition.range && abs(difference) < halfAngle && navigation.visible(from: character.position, to: player)
        suspicion = max(0, min(1, suspicion + dt * (seen ? 0.65 : -0.6)))
        let path = CGMutablePath()
        path.move(to: character.position)
        for index in 0...40 {
            let ray = angle - halfAngle + 2 * halfAngle * CGFloat(index) / 40
            let end = CGPoint(x: character.position.x + cos(ray) * definition.range, y: character.position.y + sin(ray) * definition.range)
            path.addLine(to: navigation.sightEnd(from: character.position, to: end))
        }
        path.closeSubpath()
        field.path = path
        field.fillColor = SKColor(red: 1, green: 0.80 - suspicion * 0.30, blue: 0.35, alpha: 0.14 + suspicion * 0.2)
        return seen
    }
}
