// Penjelasan file: MemoryCharacter.swift
// Membuat karakter bergaya storybook 2.5D Carto (Arthur, teman, dan warga).
// Menampilkan tubuh tegak (billboard), bayangan tanah, pakaian khas, animasi melangkah (bobbing), dan arah hadap kiri/kanan.
// MemoryPatrol mengelola rute patroli, bidang pandang visual, dan tingkat kecurigaan.

import SpriteKit

final class MemoryCharacter: SKNode {
    let title: String
    var route: [CGPoint] = []

    // Node legacy untuk kompatibilitas properti
    let body = SKShapeNode()

    // Komponen visual 2.5D bergaya Carto
    let visualRoot = SKNode()
    private let shadowNode: SKShapeNode
    private let characterBodyNode: SKNode
    private let headNode: SKNode

    private var walkPhase: CGFloat = 0
    private var idlePhase: CGFloat = 0
    private var isWalking: Bool = false

    private(set) var isSitting: Bool = false
    private(set) var isSleeping: Bool = false
    private var sleepParticlesNode: SKNode?

    private var holdingBookNode: SKNode?
    private var statusBadgeNode: SKNode?

    init(title: String, color: SKColor) {
        self.title = title

        // Bayangan lembut di atas tanah
        shadowNode = SKShapeNode(ellipseOf: CGSize(width: 22, height: 9))
        shadowNode.fillColor = SKColor(red: 0.16, green: 0.22, blue: 0.14, alpha: 0.28)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: 0)
        shadowNode.zPosition = 0

        characterBodyNode = SKNode()
        headNode = SKNode()

        super.init()

        // Pasang bayangan dan visual root
        addChild(shadowNode)
        addChild(visualRoot)

        // Sembunyikan body legacy tapi tetap aktif untuk rotasi internal bila diakses
        body.fillColor = .clear
        body.strokeColor = .clear
        addChild(body)

        setupCartoIllustration(title: title, tintColor: color)

        // Label nama karakter di atas kepala
        let nameTag = storyLabel(title, at: CGPoint(x: 0, y: 44), size: 10, color: SKColor(white: 0.96, alpha: 0.95))
        nameTag.zPosition = 10

        updateDepth()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    // Membangun ilustrasi karakter bertumpuk bergaya paper-cutout Carto
    private func setupCartoIllustration(title: String, tintColor: SKColor) {
        visualRoot.addChild(characterBodyNode)

        // 1. Kaki / Sepatu
        let leftShoe = SKShapeNode(ellipseOf: CGSize(width: 5.5, height: 4))
        leftShoe.fillColor = SKColor(red: 0.32, green: 0.24, blue: 0.18, alpha: 1)
        leftShoe.strokeColor = .clear
        leftShoe.position = CGPoint(x: -3.5, y: 2)
        characterBodyNode.addChild(leftShoe)

        let rightShoe = SKShapeNode(ellipseOf: CGSize(width: 5.5, height: 4))
        rightShoe.fillColor = SKColor(red: 0.32, green: 0.24, blue: 0.18, alpha: 1)
        rightShoe.strokeColor = .clear
        rightShoe.position = CGPoint(x: 3.5, y: 2)
        characterBodyNode.addChild(rightShoe)

        // 2. Celana / Rok
        let legs = SKShapeNode(rectOf: CGSize(width: 9, height: 6), cornerRadius: 2)
        legs.fillColor = SKColor(red: 0.22, green: 0.26, blue: 0.28, alpha: 1)
        legs.strokeColor = .clear
        legs.position = CGPoint(x: 0, y: 6)
        characterBodyNode.addChild(legs)

        // 3. Jubah / Tunik (Baju Poncho ala Carto)
        let tunicColor: SKColor
        let trimColor: SKColor
        let scarfColor: SKColor?

        switch title {
        case "Arthur":
            // Carto poncho: warna krem hangat dengan syal leher toska cerah
            tunicColor = SKColor(red: 0.94, green: 0.92, blue: 0.83, alpha: 1)
            trimColor = SKColor(red: 0.58, green: 0.38, blue: 0.22, alpha: 1)
            scarfColor = SKColor(red: 0.24, green: 0.65, blue: 0.72, alpha: 1)
        case "Keneth":
            tunicColor = SKColor(red: 0.78, green: 0.40, blue: 0.26, alpha: 1)
            trimColor = SKColor(red: 0.44, green: 0.23, blue: 0.14, alpha: 1)
            scarfColor = SKColor(red: 0.92, green: 0.80, blue: 0.58, alpha: 1)
        case "Roland":
            tunicColor = SKColor(red: 0.89, green: 0.68, blue: 0.27, alpha: 1)
            trimColor = SKColor(red: 0.48, green: 0.35, blue: 0.16, alpha: 1)
            scarfColor = SKColor(red: 0.75, green: 0.35, blue: 0.22, alpha: 1)
        case "Anneth":
            tunicColor = SKColor(red: 0.35, green: 0.55, blue: 0.76, alpha: 1)
            trimColor = SKColor(red: 0.20, green: 0.36, blue: 0.52, alpha: 1)
            scarfColor = SKColor(red: 0.96, green: 0.91, blue: 0.78, alpha: 1)
        default:
            // Warga / Patroli
            tunicColor = tintColor
            trimColor = SKColor(red: 0.30, green: 0.24, blue: 0.18, alpha: 1)
            scarfColor = SKColor(red: 0.88, green: 0.76, blue: 0.50, alpha: 1)
        }

        // Bentuk jubah melingkar sedikit melebar ke bawah
        let tunicPath = CGMutablePath()
        tunicPath.move(to: CGPoint(x: -6, y: 20))
        tunicPath.addLine(to: CGPoint(x: 6, y: 20))
        tunicPath.addLine(to: CGPoint(x: 8.5, y: 8))
        tunicPath.addLine(to: CGPoint(x: -8.5, y: 8))
        tunicPath.closeSubpath()

        let tunic = SKShapeNode(path: tunicPath)
        tunic.fillColor = tunicColor
        tunic.strokeColor = SKColor(white: 0.15, alpha: 0.3)
        tunic.lineWidth = 1
        characterBodyNode.addChild(tunic)

        // Sabuk & detail bawah tunik
        let hem = SKShapeNode(rectOf: CGSize(width: 17, height: 2.5), cornerRadius: 1)
        hem.fillColor = trimColor
        hem.strokeColor = .clear
        hem.position = CGPoint(x: 0, y: 9.5)
        characterBodyNode.addChild(hem)

        // Syal / kerah leher jika ada
        if let scarf = scarfColor {
            let collar = SKShapeNode(ellipseOf: CGSize(width: 8, height: 4.5))
            collar.fillColor = scarf
            collar.strokeColor = .clear
            collar.position = CGPoint(x: 0, y: 19)
            characterBodyNode.addChild(collar)
        }

        // Tas selempang kecil di punggung / samping (khas Carto)
        if title == "Arthur" {
            let satchel = SKShapeNode(rectOf: CGSize(width: 4.5, height: 6), cornerRadius: 1.5)
            satchel.fillColor = SKColor(red: 0.52, green: 0.33, blue: 0.19, alpha: 1)
            satchel.strokeColor = .clear
            satchel.position = CGPoint(x: -7, y: 13)
            characterBodyNode.addChild(satchel)

            let strap = SKShapeNode(rectOf: CGSize(width: 1.5, height: 12))
            strap.fillColor = SKColor(red: 0.38, green: 0.24, blue: 0.14, alpha: 0.8)
            strap.strokeColor = .clear
            strap.zRotation = -0.55
            strap.position = CGPoint(x: -2, y: 15)
            characterBodyNode.addChild(strap)
        }

        // 4. Kepala & Wajah (HeadNode)
        headNode.position = CGPoint(x: 0, y: 23)
        characterBodyNode.addChild(headNode)

        // Kulit kepala hangat khas Carto
        let skin = SKShapeNode(ellipseOf: CGSize(width: 16, height: 14.5))
        skin.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.79, alpha: 1)
        skin.strokeColor = .clear
        headNode.addChild(skin)

        // Rambut biru tua / gelap khas Carto
        let hairColor = (title == "Keneth") ? SKColor(red: 0.28, green: 0.20, blue: 0.15, alpha: 1) :
                        (title == "Roland") ? SKColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1) :
                        SKColor(red: 0.14, green: 0.19, blue: 0.28, alpha: 1)

        let hairCap = CGMutablePath()
        hairCap.addArc(center: CGPoint(x: 0, y: 2), radius: 8.2, startAngle: 0, endAngle: .pi, clockwise: false)
        hairCap.closeSubpath()
        let hair = SKShapeNode(path: hairCap)
        hair.fillColor = hairColor
        hair.strokeColor = .clear
        headNode.addChild(hair)

        // Poni rambut di samping
        let sideHair = SKShapeNode(ellipseOf: CGSize(width: 4, height: 6))
        sideHair.fillColor = hairColor
        sideHair.strokeColor = .clear
        sideHair.position = CGPoint(x: -7, y: 2)
        headNode.addChild(sideHair)

        // Kuncir atas (topknot tuft khas Carto)
        let topknot = SKShapeNode(ellipseOf: CGSize(width: 5, height: 6.5))
        topknot.fillColor = hairColor
        topknot.strokeColor = .clear
        topknot.position = CGPoint(x: 0, y: 10.5)
        headNode.addChild(topknot)

        let knotBand = SKShapeNode(rectOf: CGSize(width: 3.5, height: 1.5))
        knotBand.fillColor = SKColor(red: 0.85, green: 0.45, blue: 0.28, alpha: 1)
        knotBand.strokeColor = .clear
        knotBand.position = CGPoint(x: 0, y: 8)
        headNode.addChild(knotBand)

        // Mata lucu (dua titik hitam khas ekspresif Carto)
        let leftEye = SKShapeNode(ellipseOf: CGSize(width: 1.8, height: 2.2))
        leftEye.fillColor = SKColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1)
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: 1.5, y: 0.5)
        headNode.addChild(leftEye)

        let rightEye = SKShapeNode(ellipseOf: CGSize(width: 1.8, height: 2.2))
        rightEye.fillColor = SKColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1)
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 5.5, y: 0.5)
        headNode.addChild(rightEye)

        // Pipi merona lembut (blush)
        let blush = SKShapeNode(ellipseOf: CGSize(width: 2.6, height: 1.5))
        blush.fillColor = SKColor(red: 0.94, green: 0.60, blue: 0.56, alpha: 0.55)
        blush.strokeColor = .clear
        blush.position = CGPoint(x: 6.0, y: -2.2)
        headNode.addChild(blush)

        // Mulut senyum kecil
        let smile = SKShapeNode(ellipseOf: CGSize(width: 2.0, height: 1.0))
        smile.fillColor = SKColor(red: 0.65, green: 0.35, blue: 0.30, alpha: 0.8)
        smile.strokeColor = .clear
        smile.position = CGPoint(x: 3.5, y: -3)
        headNode.addChild(smile)
    }

    // Perbarui urutan zPosition berdasarkan posisi Y (depth sorting 2.5D)
    func updateDepth() {
        // Objek dengan koordinat Y lebih rendah berada lebih di depan (nilai zPosition lebih tinggi)
        zPosition = 30 + (480 - position.y) * 0.08
    }

    // Animasi melompat gembira saat bersedia ikut / merayakan keberhasilan cerita
    func celebrate() {
        let jumpUp = SKAction.moveBy(x: 0, y: 15, duration: 0.18)
        jumpUp.timingMode = .easeOut
        let fallDown = SKAction.moveBy(x: 0, y: -15, duration: 0.18)
        fallDown.timingMode = .easeIn
        let squash = SKAction.scaleX(to: 1.18, y: 0.82, duration: 0.08)
        let stretch = SKAction.scaleX(to: 0.88, y: 1.18, duration: 0.12)
        let restore = SKAction.scale(to: 1.0, duration: 0.10)

        let jumpSeq = SKAction.sequence([squash, stretch, jumpUp, fallDown, squash, restore])
        visualRoot.run(SKAction.sequence([jumpSeq, SKAction.wait(forDuration: 0.05), jumpSeq]))

        // Semburan partikel bintang perayaan kecil di atas kepala
        let sparks = ["✨", "⭐", "🎉"]
        for i in 0..<5 {
            let spark = SKLabelNode(text: sparks[i % sparks.count])
            spark.fontSize = 12
            spark.position = CGPoint(x: CGFloat(i - 2) * 8, y: 35)
            spark.zPosition = 50
            addChild(spark)
            let driftX = (CGFloat(i) - 2.0) * 12
            let driftY = 22 + CGFloat(i * 5)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: driftX, y: driftY, duration: 0.65),
                    SKAction.scale(to: 1.3, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.65)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // Animasi lambaian ramah saat disapa
    func wave() {
        let hop = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.13),
            SKAction.moveBy(x: 0, y: -5, duration: 0.13)
        ])
        visualRoot.run(SKAction.sequence([hop, hop]))
    }

    // Menampilkan buku kuno di tangan karakter saat memperlihatkan sketsa peta
    func setHoldingBook(visible: Bool) {
        if !visible {
            holdingBookNode?.removeFromParent()
            holdingBookNode = nil
            return
        }
        guard holdingBookNode == nil else { return }
        let book = SKNode()
        book.position = CGPoint(x: 8, y: 14)
        book.zPosition = 15

        let cover = SKShapeNode(rectOf: CGSize(width: 14, height: 11), cornerRadius: 2)
        cover.fillColor = SKColor(red: 0.55, green: 0.20, blue: 0.16, alpha: 1.0)
        cover.strokeColor = SKColor(red: 0.96, green: 0.84, blue: 0.42, alpha: 1.0)
        cover.lineWidth = 1.0
        book.addChild(cover)

        let page = SKShapeNode(rectOf: CGSize(width: 11, height: 8), cornerRadius: 1)
        page.fillColor = SKColor(red: 0.96, green: 0.92, blue: 0.80, alpha: 1.0)
        page.strokeColor = .clear
        book.addChild(page)

        let sketch = SKShapeNode(rectOf: CGSize(width: 6, height: 1.5), cornerRadius: 0.5)
        sketch.fillColor = SKColor(red: 0.40, green: 0.30, blue: 0.22, alpha: 0.8)
        sketch.strokeColor = .clear
        book.addChild(sketch)

        let glow = SKShapeNode(circleOfRadius: 10)
        glow.fillColor = SKColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 0.3)
        glow.strokeColor = .clear
        book.addChild(glow)
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.6),
            SKAction.scale(to: 0.95, duration: 0.6)
        ])))

        visualRoot.addChild(book)
        holdingBookNode = book
    }

    // Menampilkan lencana status mengambang di atas karakter
    func setStatusBadge(icon: String, text: String, color: SKColor) {
        statusBadgeNode?.removeFromParent()
        statusBadgeNode = nil

        let badge = SKNode()
        badge.position = CGPoint(x: 0, y: 56)
        badge.zPosition = 25

        let bg = SKShapeNode(rectOf: CGSize(width: 76, height: 18), cornerRadius: 9)
        bg.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.92)
        bg.strokeColor = color
        bg.lineWidth = 1.2
        badge.addChild(bg)

        let label = SKLabelNode(text: "\(icon) \(text)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 9.5
        label.fontColor = color
        label.verticalAlignmentMode = .center
        bg.addChild(label)

        badge.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.9),
            SKAction.moveBy(x: 0, y: -3, duration: 0.9)
        ])))

        addChild(badge)
        statusBadgeNode = badge
    }

    // Duduk santai di atas bantalan batang kayu (tree plate)
    func sit(at point: CGPoint) {
        isSitting = true
        isSleeping = false
        sleepParticlesNode?.removeFromParent()
        sleepParticlesNode = nil
        position = point
        visualRoot.removeAllActions()
        characterBodyNode.removeAllActions()
        characterBodyNode.zRotation = 0
        characterBodyNode.position = CGPoint(x: 0, y: -3)
        characterBodyNode.setScale(1.0)
        shadowNode.setScale(0.85)
        visualRoot.run(SKAction.sequence([
            SKAction.scaleX(to: 1.12, y: 0.82, duration: 0.18),
            SKAction.scaleX(to: 1.05, y: 0.88, duration: 0.14)
        ]))
        updateDepth()
    }

    // Bangun dari posisi duduk
    func standUp() {
        guard isSitting else { return }
        isSitting = false
        visualRoot.removeAllActions()
        characterBodyNode.position = .zero
        characterBodyNode.zRotation = 0
        shadowNode.setScale(1.0)
        visualRoot.run(SKAction.sequence([
            SKAction.scaleX(to: 0.90, y: 1.15, duration: 0.12),
            SKAction.scale(to: 1.0, duration: 0.12)
        ]))
        updateDepth()
    }

    // Berbaring tidur di atas kasur anyaman wol hangat
    func sleep(at point: CGPoint) {
        isSleeping = true
        isSitting = false
        position = point
        visualRoot.removeAllActions()
        characterBodyNode.removeAllActions()
        characterBodyNode.zRotation = -.pi / 2
        characterBodyNode.position = CGPoint(x: 0, y: 4)
        visualRoot.setScale(0.92)
        shadowNode.setScale(0.7)

        // Efek partikel Zzz mengambang
        let zContainer = SKNode()
        zContainer.name = "sleepZzz"
        zContainer.position = CGPoint(x: 8, y: 22)
        zContainer.zPosition = 60
        addChild(zContainer)
        sleepParticlesNode = zContainer

        for i in 0..<3 {
            let zLabel = SKLabelNode(text: "z")
            zLabel.fontName = "AvenirNext-Bold"
            zLabel.fontSize = CGFloat(10 + i * 3)
            zLabel.fontColor = SKColor(red: 0.98, green: 0.92, blue: 0.72, alpha: 0.9)
            zLabel.position = CGPoint(x: CGFloat(i * 6), y: CGFloat(i * 8))
            zLabel.alpha = 0
            zContainer.addChild(zLabel)
            zLabel.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.45),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.4),
                    SKAction.moveBy(x: 6, y: 14, duration: 1.2),
                    SKAction.scale(to: 1.2, duration: 1.2)
                ]),
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.moveBy(x: -6, y: -14, duration: 0),
                SKAction.scale(to: 0.8, duration: 0),
                SKAction.wait(forDuration: 0.8)
            ])))
        }
        updateDepth()
    }

    // Bangun dari tidur
    func wakeUp() {
        guard isSleeping else { return }
        isSleeping = false
        sleepParticlesNode?.removeFromParent()
        sleepParticlesNode = nil
        visualRoot.removeAllActions()
        characterBodyNode.removeAllActions()
        characterBodyNode.position = .zero
        characterBodyNode.zRotation = 0
        visualRoot.setScale(1.0)
        shadowNode.setScale(1.0)
        visualRoot.run(SKAction.sequence([
            SKAction.scaleX(to: 0.88, y: 1.22, duration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.14)
        ]))
        updateDepth()
    }

    // Memperbarui arah pandang dan animasi langkah/diam
    func applyMovement(dx: CGFloat, dy: CGFloat, dt: CGFloat) {
        let speed = hypot(dx, dy)
        if speed > 0.5 {
            if isSitting { standUp() }
            if isSleeping { wakeUp() }
            isWalking = true
            walkPhase += dt * 14

            // Arah hadap kiri / kanan (flip xScale)
            if dx > 0.3 {
                visualRoot.xScale = 1.0
            } else if dx < -0.3 {
                visualRoot.xScale = -1.0
            }

            // Animasi langkah: waddle naik-turun dan sedikit bergoyang
            characterBodyNode.position.y = abs(sin(walkPhase)) * 2.5
            characterBodyNode.zRotation = sin(walkPhase) * 0.07
            shadowNode.setScale(1.0 - (abs(sin(walkPhase)) * 0.1))
        } else {
            isWalking = false
            idlePhase += dt * 3
            // Animasi bernapas santai saat diam
            characterBodyNode.position.y = sin(idlePhase) * 0.6
            characterBodyNode.zRotation = 0
            shadowNode.setScale(1.0)
        }
        updateDepth()
    }

    // Mengikuti rute dengan navigasi dan memperbarui visual 2.5D
    func walk(dt: CGFloat, speed: CGFloat, navigation: MemoryNavigation) {
        if isSitting { standUp() }
        if isSleeping { wakeUp() }
        guard let next = route.first else {
            applyMovement(dx: 0, dy: 0, dt: dt)
            return
        }
        let dx = next.x - position.x, dy = next.y - position.y
        let length = hypot(dx, dy)
        if length < 5 {
            route.removeFirst()
            applyMovement(dx: 0, dy: 0, dt: dt)
            return
        }
        let amount = min(length, speed * dt)
        let stepX = dx / length * amount
        let stepY = dy / length * amount
        let previous = position
        position = navigation.moved(from: position, by: CGVector(dx: stepX, dy: stepY))
        if hypot(position.x - previous.x, position.y - previous.y) < 0.01 {
            route.removeAll()
            applyMovement(dx: 0, dy: 0, dt: dt)
        } else {
            applyMovement(dx: stepX, dy: stepY, dt: dt)
        }
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
        character = MemoryCharacter(title: definition.title, color: SKColor(red: 0.65, green: 0.44, blue: 0.32, alpha: 1))
        character.position = definition.points[0]
        field.fillColor = SKColor(red: 0.98, green: 0.81, blue: 0.42, alpha: 0.14)
        field.strokeColor = SKColor(white: 1, alpha: 0.07)
        field.zPosition = 8
    }

    // Menggerakkan patroli, memperbarui animasi dan arah hadap Carto, serta menguji bidang pandang
    func update(dt: CGFloat, player: CGPoint, navigation: MemoryNavigation) -> Bool {
        let goal = definition.points[waypoint]
        let dx = goal.x - character.position.x, dy = goal.y - character.position.y
        let length = hypot(dx, dy)
        var movedDelta = CGVector.zero

        if pause > 0 {
            pause -= dt
            character.applyMovement(dx: 0, dy: 0, dt: dt)
        } else if length < 6 {
            waypoint = (waypoint + 1) % definition.points.count
            pause = 1.1
            character.applyMovement(dx: 0, dy: 0, dt: dt)
        } else {
            angle = atan2(dy, dx)
            let delta = CGVector(dx: cos(angle) * definition.speed * dt, dy: sin(angle) * definition.speed * dt)
            let next = navigation.moved(from: character.position, by: delta)
            if hypot(next.x - character.position.x, next.y - character.position.y) < 0.01 {
                waypoint = (waypoint + 1) % definition.points.count
                pause = 0.8
                character.applyMovement(dx: 0, dy: 0, dt: dt)
            } else {
                movedDelta = CGVector(dx: next.x - character.position.x, dy: next.y - character.position.y)
                character.position = next
                character.applyMovement(dx: movedDelta.dx, dy: movedDelta.dy, dt: dt)
            }
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
