// Quest 2: Arthur membantu Keneth di lumbung.
// State, dialog, world event, dan pemanggilan SeedSortingMinigame sengaja
// disimpan di file sendiri agar quest lain dapat dikerjakan paralel.
import SpriteKit

struct VillageQuest2Progress: Codable {
    static let saveKey = "village.carto.quest2.v1"

    var spokeToGrandpa = false
    var hasBasket = false
    var metKeneth = false
    var washedHands = false
    var sortedSeeds = false
    var doorWedged = false
    var completed = false

    static func load(defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self()
        }
        return saved
    }

    func save(defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }
}

private final class VillageQuest2Runtime {
    static let shared = VillageQuest2Runtime()

    var progress = VillageQuest2Progress.load()
    weak var activeMinigame: SeedSortingMinigameNode?
}

extension VillageCartoScene {
    var quest2: VillageQuest2Progress {
        get { VillageQuest2Runtime.shared.progress }
        set { VillageQuest2Runtime.shared.progress = newValue }
    }

    var activeQuest2Minigame: SeedSortingMinigameNode? {
        get { VillageQuest2Runtime.shared.activeMinigame }
        set { VillageQuest2Runtime.shared.activeMinigame = newValue }
    }

    var quest2Objective: String {
        if quest2.completed {
            return "Quest 2 selesai: keping menuju peternakan telah terbuka."
        }
        if quest2.sortedSeeds {
            return "Selesaikan percakapan dengan Keneth."
        }
        if quest2.washedHands {
            return "Goyangkan perangkat untuk memisahkan gandum dan biji hitam."
        }
        if quest2.metKeneth {
            return "Cuci tangan menggunakan ember di pojok lumbung."
        }
        if quest2.hasBasket {
            return layout.buildingPlacements.contains(where: { $0.id == "village-barn" })
                ? "Temui Keneth di Lumbung Desa dan berikan keranjang."
                : "Tempatkan Lumbung Desa (9×15) di area kuning."
        }
        if quest2.spokeToGrandpa {
            return layout.buildingPlacements.contains(where: { $0.id == "bu-mara-house" })
                ? "Temui Bu Mara untuk mengambil keranjang tampah."
                : "Tempatkan kembali Rumah Bu Mara untuk mengambil keranjang."
        }
        return "Bicara dengan Kakek di Rumah Arthur untuk membuka Lumbung Desa."
    }

    func saveQuest2() {
        quest2.save()
    }

    var quest2MaraPosition: CGPoint? {
        questPosition(for: "bu-mara-house").map { CGPoint(x: $0.x + 28, y: $0.y) }
    }

    var quest2BarnPosition: CGPoint? {
        questPosition(for: "village-barn")
    }

    func renderQuest2World() {
        if let grandpa = grandpaQuestPosition {
            renderGrandpaPorch(at: grandpa)
            questNPC(at: grandpa, name: "Kakek", color: .systemBrown)
            if !quest2.spokeToGrandpa {
                questMarker(
                    at: CGPoint(x: grandpa.x, y: grandpa.y + 25),
                    name: "quest2-grandpa",
                    color: .systemYellow,
                    symbol: "!"
                )
            }
        }

        if let maraHouse = questPosition(for: "bu-mara-house") {
            renderMaraBackyard(at: CGPoint(x: maraHouse.x - 28, y: maraHouse.y))
            let mara = CGPoint(x: maraHouse.x + 28, y: maraHouse.y)
            questNPC(at: mara, name: "Bu Mara", color: .systemTeal)
            if quest2.spokeToGrandpa && !quest2.hasBasket {
                questMarker(
                    at: CGPoint(x: mara.x, y: mara.y + 25),
                    name: "quest2-basket",
                    color: .systemOrange,
                    symbol: "!"
                )
            }
        }

        guard quest2.spokeToGrandpa, let barn = quest2BarnPosition else { return }
        renderQuest2BarnEnvironment(at: barn)
        let keneth = CGPoint(x: barn.x + 28, y: barn.y)
        questNPC(at: keneth, name: "Keneth", color: .systemIndigo)

        if quest2.hasBasket && !quest2.metKeneth {
            questMarker(
                at: CGPoint(x: keneth.x, y: keneth.y + 25),
                name: "quest2-keneth",
                color: .systemYellow,
                symbol: "!"
            )
        } else if quest2.metKeneth && !quest2.washedHands {
            let bucket = quest2WashBucketPosition(from: barn)
            questMarker(
                at: CGPoint(x: bucket.x, y: bucket.y + 18),
                name: "quest2-wash",
                color: .systemTeal,
                symbol: "!"
            )
        } else if quest2.completed && !quest2.doorWedged {
            let door = quest2DoorPosition(from: barn)
            questMarker(
                at: CGPoint(x: door.x, y: door.y + 18),
                name: "quest2-door",
                color: .systemOrange,
                symbol: "?"
            )
        }
    }

    func renderQuest2BarnEnvironment(at position: CGPoint) {
        let environment = SKNode()
        environment.position = position
        environment.zPosition = 54

        let dampWall = SKShapeNode(rectOf: CGSize(width: 72, height: 48), cornerRadius: 4)
        dampWall.position = CGPoint(x: -19, y: 13)
        dampWall.fillColor = SKColor(red: 0.24, green: 0.18, blue: 0.13, alpha: 0.78)
        dampWall.strokeColor = SKColor(red: 0.15, green: 0.26, blue: 0.21, alpha: 0.9)
        dampWall.lineWidth = 3
        environment.addChild(dampWall)

        for offset in [CGPoint(x: -28, y: -11), CGPoint(x: -10, y: -14), CGPoint(x: 8, y: -11)] {
            let sack = SKShapeNode(ellipseOf: CGSize(width: 21, height: 14))
            sack.position = offset
            sack.fillColor = SKColor(red: 0.66, green: 0.52, blue: 0.31, alpha: 1)
            sack.strokeColor = SKColor(red: 0.32, green: 0.23, blue: 0.13, alpha: 1)
            sack.lineWidth = 1.5
            environment.addChild(sack)
        }

        let coconut = SKShapeNode(circleOfRadius: 6)
        coconut.position = CGPoint(x: 22, y: -15)
        coconut.fillColor = SKColor(red: 0.38, green: 0.21, blue: 0.11, alpha: 1)
        coconut.strokeColor = .black.withAlphaComponent(0.45)
        environment.addChild(coconut)

        let bucket = SKShapeNode(circleOfRadius: 8)
        bucket.position = CGPoint(x: -38, y: -23)
        bucket.fillColor = SKColor(red: 0.26, green: 0.58, blue: 0.66, alpha: 1)
        bucket.strokeColor = .white.withAlphaComponent(0.65)
        bucket.lineWidth = 1.5
        environment.addChild(bucket)

        let door = SKShapeNode(rectOf: CGSize(width: 21, height: 36), cornerRadius: 2)
        door.position = CGPoint(x: 37, y: -10)
        door.zRotation = -0.10
        door.fillColor = SKColor(red: 0.39, green: 0.23, blue: 0.12, alpha: 1)
        door.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.06, alpha: 1)
        door.lineWidth = 2
        environment.addChild(door)

        let father = MemoryCharacter(title: "Ayah Keneth", color: .systemBrown)
        father.position = CGPoint(x: -48, y: 1)
        father.setScale(0.24)
        father.zPosition = 2
        environment.addChild(father)
        father.run(.repeatForever(.sequence([
            .moveBy(x: 8, y: 0, duration: 1.2),
            .moveBy(x: -8, y: 0, duration: 1.2)
        ])))

        world.addChild(environment)
    }

    func quest2WashBucketPosition(from barn: CGPoint) -> CGPoint {
        CGPoint(x: barn.x - 38, y: barn.y - 23)
    }

    func quest2DoorPosition(from barn: CGPoint) -> CGPoint {
        CGPoint(x: barn.x + 37, y: barn.y - 10)
    }

    func handleQuest2Interaction(at point: CGPoint) -> Bool {
        if !quest2.spokeToGrandpa,
           let grandpa = grandpaQuestPosition,
           hypot(point.x - grandpa.x, point.y - grandpa.y) <= 45 {
            approachOrInteract(grandpa, message: "Dekati Kakek untuk berbicara.") { [weak self] in
                guard let self else { return }
                self.presentQuestDialogue([
                    .init(speaker: "Kakek", text: "Keneth sedang bekerja di lumbung. Bawakan keranjang dari Bu Mara dan bantulah dia."),
                    .init(speaker: "Arthur", text: "Baik, Kek. Aku akan mengambil keranjangnya lalu pergi ke lumbung.")
                ]) { [weak self] in
                    guard let self else { return }
                    self.quest2.spokeToGrandpa = true
                    self.saveQuest2()
                    self.rebuild("Keping Z dan Lumbung Desa terbuka. Ambil keranjang dari Bu Mara.")
                }
            }
            return true
        }

        if quest2.spokeToGrandpa,
           !quest2.hasBasket,
           let mara = quest2MaraPosition,
           hypot(point.x - mara.x, point.y - mara.y) <= 45 {
            approachOrInteract(mara, message: "Dekati Bu Mara untuk mengambil keranjang.") { [weak self] in
                guard let self else { return }
                self.presentQuestDialogue([
                    .init(speaker: "Bu Mara", text: "Keneth needs this winnowing basket. Take it carefully to the barn."),
                    .init(speaker: "Arthur", text: "I will bring it to him.")
                ]) { [weak self] in
                    guard let self else { return }
                    self.quest2.hasBasket = true
                    self.saveQuest2()
                    self.rebuild("Keranjang didapat. Tempatkan Lumbung Desa lalu temui Keneth.")
                }
            }
            return true
        }

        guard quest2.spokeToGrandpa, let barn = quest2BarnPosition else { return false }
        let keneth = CGPoint(x: barn.x + 28, y: barn.y)
        if hypot(point.x - keneth.x, point.y - keneth.y) <= 45 {
            if !quest2.hasBasket {
                status.text = "Ambil keranjang dari Bu Mara terlebih dahulu."
                return true
            }
            if !quest2.metKeneth {
                approachOrInteract(keneth, message: "Dekati Keneth untuk memberikan keranjang.") { [weak self] in
                    guard let self else { return }
                    self.presentQuestDialogue([
                        .init(speaker: "Arthur", text: "I've got a basket for you."),
                        .init(speaker: "Keneth", text: "Leave it there. Are your hands clean?"),
                        .init(speaker: "Arthur", text: "Clean enough."),
                        .init(speaker: "Keneth", text: "Wash them first.")
                    ]) { [weak self] in
                        guard let self else { return }
                        self.quest2.metKeneth = true
                        self.saveQuest2()
                        self.rebuild("Cuci tangan menggunakan ember di pojok lumbung.")
                    }
                }
            } else if !quest2.washedHands {
                status.text = "Keneth menunjuk ember di pojok: cuci tangan dahulu."
            } else if !quest2.completed && activeQuest2Minigame == nil {
                startQuest2SeedMinigame()
            }
            return true
        }

        let bucket = quest2WashBucketPosition(from: barn)
        if quest2.metKeneth,
           !quest2.washedHands,
           hypot(point.x - bucket.x, point.y - bucket.y) <= 40 {
            approachOrInteract(bucket, message: "Dekati ember untuk mencuci tangan.") { [weak self] in
                guard let self else { return }
                self.quest2Fade { [weak self] in
                    guard let self else { return }
                    self.quest2.washedHands = true
                    self.saveQuest2()
                    self.rebuild("Tangan sudah bersih. Minigame sortir biji dimulai.")
                    self.startQuest2SeedMinigame()
                }
            }
            return true
        }

        let door = quest2DoorPosition(from: barn)
        if quest2.completed,
           !quest2.doorWedged,
           hypot(point.x - door.x, point.y - door.y) <= 40 {
            approachOrInteract(door, message: "Dekati pintu lumbung yang miring.") { [weak self] in
                guard let self else { return }
                self.quest2Fade { [weak self] in
                    guard let self else { return }
                    self.quest2.doorWedged = true
                    self.saveQuest2()
                    self.rebuild("Arthur mengganjal engsel pintu dengan potongan kayu.")
                }
            }
            return true
        }

        return false
    }

    func quest2Fade(completion: @escaping () -> Void) {
        let fade = SKSpriteNode(color: .black, size: size)
        fade.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fade.alpha = 0
        fade.zPosition = 2900
        hud.addChild(fade)
        fade.run(.sequence([
            .fadeAlpha(to: 0.96, duration: 0.28),
            .wait(forDuration: 0.32),
            .fadeOut(withDuration: 0.28),
            .removeFromParent(),
            .run(completion)
        ]))
    }

    func startQuest2SeedMinigame() {
        guard quest2.washedHands,
              !quest2.completed,
              activeQuest2Minigame == nil else { return }

        route = []
        stick = .zero
        let event = SeedSortingMinigameNode(config: .init(
            goodSeedCount: 36,
            badSeedCount: 14,
            shakeThresholdTotal: 90,
            headingText: "PISAHKAN GANDUM",
            instructionText: "GOYANGKAN PERANGKAT BERIRAMA"
        ))
        event.position = CGPoint(x: size.width / 2, y: size.height / 2)
        event.zPosition = 3000
        addQuest2SortingDialogue(to: event)

        event.onComplete = { [weak self] in
            guard let self else { return }
            self.quest2.sortedSeeds = true
            self.saveQuest2()
        }
        event.onDismiss = { [weak self, weak event] in
            guard let self else { return }
            if self.activeQuest2Minigame === event {
                self.activeQuest2Minigame = nil
            }
            guard self.quest2.sortedSeeds else {
                self.rebuild("Sortir biji belum selesai. Temui Keneth untuk mencoba lagi.")
                return
            }
            self.presentQuestDialogue(self.quest2ClosingDialogue) { [weak self] in
                guard let self else { return }
                self.quest2.completed = true
                let progress = PrologueStore.shared.progress
                progress.storyProgress = max(progress.storyProgress, 3)
                PrologueStore.shared.save()
                self.saveQuest2()
                self.rebuild("Quest 2 selesai. Keping menuju peternakan terbuka.")
            }
        }

        activeQuest2Minigame = event
        addChild(event)
        event.start()
    }

    var quest2ClosingDialogue: [VillageQuestDialogueLine] {
        [
            .init(speaker: "Arthur", text: "I wonder if the soil past the hills is like our garden."),
            .init(speaker: "Keneth", text: "Not this again."),
            .init(speaker: "Arthur", text: "I'm just asking."),
            .init(speaker: "Keneth", text: "The soil here is fine."),
            .init(speaker: "Arthur", text: "That's not what I meant. The people who first found this valley must have traveled from somewhere else."),
            .init(speaker: "Keneth", text: "And we have no idea how many of them didn't make it. We have everything we need here. If everyone takes care of what we have and follows the rules, we'll be fine."),
            .init(speaker: "Keneth", text: "You always count what we might find out there, Arthur. Just once... try counting what we could lose."),
            .init(speaker: "Keneth", text: "Roland is at the animal pens. Go bother him.")
        ]
    }

    func addQuest2SortingDialogue(to event: SeedSortingMinigameNode) {
        let lines: [VillageQuestDialogueLine] = [
            .init(speaker: "Arthur", text: "This pile looks smaller than I thought."),
            .init(speaker: "Keneth", text: "We moved some of it. The wall has been damp since the rain. Separate the black seeds or they will ruin the good ones."),
            .init(speaker: "Arthur", text: "Is the harvest enough?"),
            .init(speaker: "Keneth", text: "It's enough. My mother counted.")
        ]

        let panel = SKShapeNode(rectOf: CGSize(width: min(size.width - 50, 650), height: 82), cornerRadius: 10)
        panel.position = CGPoint(x: 0, y: -size.height / 2 + 66)
        panel.fillColor = SKColor(white: 0.05, alpha: 0.90)
        panel.strokeColor = cream.withAlphaComponent(0.70)
        panel.lineWidth = 1.5
        panel.zPosition = 100

        let speaker = SKLabelNode(fontNamed: "AvenirNext-Bold")
        speaker.fontSize = 13
        speaker.fontColor = .systemYellow
        speaker.horizontalAlignmentMode = .left
        speaker.position = CGPoint(x: -panel.frame.width / 2 + 16, y: 21)
        panel.addChild(speaker)

        let body = SKLabelNode(fontNamed: "AvenirNext-Regular")
        body.fontSize = 11
        body.fontColor = .white
        body.horizontalAlignmentMode = .left
        body.verticalAlignmentMode = .top
        body.numberOfLines = 2
        body.preferredMaxLayoutWidth = panel.frame.width - 32
        body.position = CGPoint(x: -panel.frame.width / 2 + 16, y: 5)
        panel.addChild(body)
        event.addChild(panel)

        var actions: [SKAction] = []
        for line in lines {
            actions.append(.run {
                speaker.text = line.speaker
                body.text = line.text
            })
            actions.append(.wait(forDuration: 4.0))
        }
        panel.run(.sequence(actions))
    }
}
