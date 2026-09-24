// Quest 1: Arthur menolong Bu Mara.
// Seluruh state, dialog, world event, interaction, dan minigame Quest 1
// berada di file ini agar quest lain dapat dikerjakan pada file terpisah.
import SpriteKit

struct VillageQuestDialogueLine {
    let speaker: String
    let text: String
}

struct VillageQuest1Progress: Codable {
    static let saveKey = "village.carto.quest1.v4"

    var spokeToGrandpa = false
    var collectedWater = false
    var spokeToMara = false
    var rackFixed = false
    var returnedHome = false

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

private final class VillageQuest1Runtime {
    static let shared = VillageQuest1Runtime()

    var progress = VillageQuest1Progress.load()
    weak var activeMinigame: ShelfBalanceMinigameNode?
}

extension VillageCartoScene {
    var quest1: VillageQuest1Progress {
        get { VillageQuest1Runtime.shared.progress }
        set { VillageQuest1Runtime.shared.progress = newValue }
    }

    var activeQuestMinigame: ShelfBalanceMinigameNode? {
        get { VillageQuest1Runtime.shared.activeMinigame }
        set { VillageQuest1Runtime.shared.activeMinigame = newValue }
    }

    // Quest 0 dimulai dengan satu keping awal, Rumah Arthur, dan Sumur.
    // Quest 1 membuka keping kedua bersama Rumah Bu Mara.
    var quest1PieceOrder: [Int] { [26, 5] }
    var quest1UnlockedPieceIDs: Set<Int> {
        var result: Set<Int> = [26]
        if quest1.collectedWater { result.insert(5) }
        return result
    }

    var quest1UnlockedBuildingIDs: Set<String> {
        var result: Set<String> = ["arthur-house", "village-well"]
        if quest1.collectedWater { result.insert("bu-mara-house") }
        return result
    }

    var quest1Objective: String {
        if quest1.returnedHome { return "Quest 1 selesai: Arthur telah kembali ke rumah." }
        if quest1.rackFixed {
            return layout.buildingPlacements.contains(where: { $0.id == "arthur-house" })
                ? "Kembali ke Rumah Arthur dan bicara dengan Kakek."
                : "Tempatkan Rumah Arthur, lalu kembali menemui Kakek."
        }
        if quest1.spokeToMara { return "Dekati rak miring lalu ketuk [Interact: Periksa Rak]." }
        if quest1.collectedWater {
            return layout.buildingPlacements.contains(where: { $0.id == "bu-mara-house" })
                ? "Temui Bu Mara di depan rumahnya."
                : "Keping kedua dan Rumah Bu Mara terbuka. Tempatkan Rumah Bu Mara (6x6) di area kuning."
        }
        if quest1.spokeToGrandpa {
            return layout.buildingPlacements.contains(where: { $0.id == "village-well" })
                ? "Dekati Sumur dan ambil air."
                : "Tempatkan Sumur (3x3) di area kuning keping awal."
        }
        let hasArthur = layout.buildingPlacements.contains(where: { $0.id == "arthur-house" })
        let hasWell = layout.buildingPlacements.contains(where: { $0.id == "village-well" })
        if hasArthur && hasWell {
            return "Jelajahi dan bicara dengan Kakek di Rumah Arthur."
        }
        return "Tempatkan Rumah Arthur dan Sumur di area kuning keping awal."
    }

    func presentQuestDialogue(
        _ lines: [VillageQuestDialogueLine],
        onFinished: (() -> Void)? = nil
    ) {
        questDialogue = lines
        questDialogueIndex = 0
        questDialogueCompletion = onFinished
        renderQuestDialogue()
    }

    func renderQuestDialogue() {
        hud.childNode(withName: "quest-dialogue")?.removeFromParent()
        guard questDialogue.indices.contains(questDialogueIndex) else { return }
        let line = questDialogue[questDialogueIndex]
        let width = min(size.width - 44, 680)
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: 116), cornerRadius: 12)
        panel.name = "quest-dialogue"
        panel.position = CGPoint(x: size.width / 2, y: 96)
        panel.fillColor = SKColor(white: 0.08, alpha: 0.96)
        panel.strokeColor = cream.withAlphaComponent(0.75)
        panel.lineWidth = 2
        panel.zPosition = 2500

        let speaker = SKLabelNode(fontNamed: "AvenirNext-Bold")
        speaker.text = line.speaker
        speaker.fontSize = 15
        speaker.fontColor = .systemYellow
        speaker.horizontalAlignmentMode = .left
        speaker.position = CGPoint(x: -width / 2 + 20, y: 31)
        panel.addChild(speaker)

        let body = SKLabelNode(fontNamed: "AvenirNext-Regular")
        body.text = line.text
        body.fontSize = 13
        body.fontColor = .white
        body.horizontalAlignmentMode = .left
        body.verticalAlignmentMode = .top
        body.preferredMaxLayoutWidth = width - 40
        body.numberOfLines = 3
        body.position = CGPoint(x: -width / 2 + 20, y: 13)
        panel.addChild(body)

        let next = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        next.text = questDialogueIndex == questDialogue.count - 1 ? "Ketuk untuk lanjut" : "Ketuk untuk berikutnya"
        next.fontSize = 10
        next.fontColor = cream.withAlphaComponent(0.8)
        next.position = CGPoint(x: width / 2 - 82, y: -43)
        panel.addChild(next)
        hud.addChild(panel)
    }

    func advanceQuestDialogue() {
        guard !questDialogue.isEmpty else { return }
        questDialogueIndex += 1
        if questDialogue.indices.contains(questDialogueIndex) {
            renderQuestDialogue()
            return
        }
        hud.childNode(withName: "quest-dialogue")?.removeFromParent()
        questDialogue = []
        questDialogueIndex = 0
        let completion = questDialogueCompletion
        questDialogueCompletion = nil
        completion?()
    }

    func bucketFade(completion: @escaping () -> Void) {
        let fade = SKSpriteNode(color: .black, size: size)
        fade.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fade.alpha = 0
        fade.zPosition = 2900
        hud.addChild(fade)
        AudioService.shared.playSystemSound(id: 1104)
        fade.run(.sequence([
            .fadeAlpha(to: 0.95, duration: 0.35),
            .wait(forDuration: 0.28),
            .fadeOut(withDuration: 0.35),
            .removeFromParent(),
            .run(completion)
        ]))
    }

    func saveQuest1() {
        quest1.save()
    }

    func questPosition(for buildingID: String, offset: CGPoint = .zero) -> CGPoint? {
        guard let placement = layout.buildingPlacements.first(where: { $0.id == buildingID }),
              let rect = VillageTileLayout.buildingRect(placement) else { return nil }
        return CGPoint(x: rect.midX + offset.x, y: rect.midY + offset.y)
    }

    func questMarker(at position: CGPoint, name: String, color: SKColor, symbol: String) {
        let marker = SKShapeNode(circleOfRadius: 10)
        marker.name = name
        marker.position = position
        marker.fillColor = color
        marker.strokeColor = .white
        marker.lineWidth = 1.5
        marker.zPosition = 70
        text(symbol, at: .zero, size: 10, parent: marker)
        world.addChild(marker)
    }

    func questNPC(at position: CGPoint, name: String, color: SKColor) {
        let npc = MemoryCharacter(title: name, color: color)
        npc.name = "quest-\(name)"
        npc.position = position
        npc.setScale(0.3)
        npc.zPosition = 65
        world.addChild(npc)
    }

    var grandpaQuestPosition: CGPoint? {
        if let house = questPosition(for: "arthur-house") {
            return CGPoint(x: house.x + 30, y: house.y)
        }
        return nil
    }

    func renderGrandpaPorch(at position: CGPoint) {
        let porch = SKShapeNode(rectOf: CGSize(width: 62, height: 25), cornerRadius: 3)
        porch.position = CGPoint(x: position.x, y: position.y - 7)
        porch.fillColor = SKColor(red: 0.38, green: 0.23, blue: 0.12, alpha: 1)
        porch.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.06, alpha: 1)
        porch.lineWidth = 2
        porch.zPosition = 54
        world.addChild(porch)

        for x in stride(from: -24, through: 24, by: 12) {
            let plank = SKShapeNode(rectOf: CGSize(width: 1.5, height: 22))
            plank.position = CGPoint(x: CGFloat(x), y: 0)
            plank.fillColor = cream.withAlphaComponent(0.25)
            plank.strokeColor = .clear
            porch.addChild(plank)
        }
    }

    func renderMaraBackyard(at position: CGPoint) {
        let yard = SKNode()
        yard.position = position
        yard.zPosition = 53

        for offset in [CGPoint(x: -25, y: -14), CGPoint(x: 15, y: -17)] {
            let mud = SKShapeNode(ellipseOf: CGSize(width: 42, height: 18))
            mud.position = offset
            mud.fillColor = SKColor(red: 0.28, green: 0.19, blue: 0.12, alpha: 0.75)
            mud.strokeColor = SKColor(red: 0.16, green: 0.11, blue: 0.08, alpha: 0.8)
            yard.addChild(mud)
        }

        let shelf = SKShapeNode(rectOf: CGSize(width: 46, height: 5), cornerRadius: 1)
        shelf.position = CGPoint(x: -18, y: 4)
        shelf.zRotation = -0.16
        shelf.fillColor = .systemBrown
        shelf.strokeColor = .black.withAlphaComponent(0.45)
        yard.addChild(shelf)
        for x in [-17.0, 17.0] {
            let leg = SKShapeNode(rectOf: CGSize(width: 4, height: 25))
            leg.position = CGPoint(x: x, y: -11)
            leg.fillColor = .systemBrown
            leg.strokeColor = .clear
            shelf.addChild(leg)
        }
        for x in [-31.0, -18.0, -5.0] {
            let pot = SKShapeNode(circleOfRadius: 5)
            pot.position = CGPoint(x: x, y: 13)
            pot.fillColor = SKColor(red: 0.72, green: 0.35, blue: 0.18, alpha: 1)
            pot.strokeColor = .black.withAlphaComponent(0.35)
            yard.addChild(pot)
        }
        let brick = SKShapeNode(rectOf: CGSize(width: 14, height: 7), cornerRadius: 1)
        brick.position = CGPoint(x: 28, y: -9)
        brick.fillColor = .systemRed
        brick.strokeColor = .black.withAlphaComponent(0.4)
        yard.addChild(brick)
        world.addChild(yard)
    }

    func renderQuest1World() {
        if let grandpa = grandpaQuestPosition {
            renderGrandpaPorch(at: grandpa)
            questNPC(at: grandpa, name: "Kakek", color: .systemBrown)
            if !quest1.spokeToGrandpa || quest1.rackFixed {
                questMarker(at: CGPoint(x: grandpa.x, y: grandpa.y + 25),
                            name: "quest-grandpa", color: .systemYellow, symbol: "!")
            }
        }

        if quest1.spokeToGrandpa,
           !quest1.collectedWater,
           let well = questPosition(for: "village-well") {
            questMarker(at: CGPoint(x: well.x, y: well.y + 22),
                        name: "quest-well", color: .systemTeal, symbol: "!")
        }

        if quest1.collectedWater,
           let maraHouse = questPosition(for: "bu-mara-house") {
            renderMaraBackyard(at: CGPoint(x: maraHouse.x - 28, y: maraHouse.y))
            let mara = CGPoint(x: maraHouse.x + 28, y: maraHouse.y)
            questNPC(at: mara, name: "Bu Mara", color: .systemTeal)
            if !quest1.spokeToMara {
                questMarker(at: CGPoint(x: mara.x, y: mara.y + 25),
                            name: "quest-mara", color: .systemYellow, symbol: "!")
            } else if !quest1.rackFixed {
                questMarker(at: CGPoint(x: maraHouse.x - 28, y: maraHouse.y),
                            name: "quest-rack", color: .systemOrange, symbol: "!")
            }
        }
    }

    func closeEnough(_ target: CGPoint) -> Bool {
        hypot(actor.position.x - target.x, actor.position.y - target.y) <= 70
    }

    func approachOrInteract(_ target: CGPoint, message: String, action: () -> Void) {
        if closeEnough(target) {
            route = []
            stick = .zero
            action()
        } else {
            route = [target]
            status.text = message
        }
    }

    func handleQuest1Interaction(at point: CGPoint) -> Bool {
        if let grandpa = grandpaQuestPosition {
            if hypot(point.x - grandpa.x, point.y - grandpa.y) <= 45 {
                approachOrInteract(grandpa, message: "Dekati Kakek untuk berbicara.") { [weak self] in
                    guard let self else { return }
                    if self.quest1.rackFixed {
                        self.presentQuestDialogue([
                            .init(
                                speaker: "Kakek",
                                text: "Did the well move further away today? Half your water is gone."
                            ),
                            .init(
                                speaker: "Arthur",
                                text: "Bu Mara's shelf almost collapsed. I had to fix it."
                            ),
                            .init(
                                speaker: "Kakek",
                                text: "Good thing you saw it before the well collapsed too."
                            ),
                            .init(
                                speaker: "Narasi",
                                text: "Kakek menyodorkan mangkuk sarapan kepada Arthur."
                            ),
                            .init(
                                speaker: "Kakek",
                                text: "Where are you off to next?"
                            ),
                            .init(
                                speaker: "Arthur",
                                text: "The barn. If there's nothing to help with, I'll come straight home."
                            ),
                            .init(
                                speaker: "Kakek",
                                text: "We both know you rarely find a day like that."
                            )
                        ]) { [weak self] in
                            guard let self else { return }
                            self.quest1.returnedHome = true
                            let progress = PrologueStore.shared.progress
                            progress.storyProgress = max(progress.storyProgress, 1)
                            PrologueStore.shared.save()
                            self.saveQuest1()
                            self.rebuild("Quest 1 selesai. Tujuan berikutnya: lumbung.")
                        }
                    } else if !self.quest1.spokeToGrandpa {
                        self.presentQuestDialogue([
                            .init(
                                speaker: "Kakek",
                                text: "Arthur, can you bring me well water? Our water is running out."
                            ),
                            .init(
                                speaker: "Arthur",
                                text: "Sure, Grandpa. I will bring the bucket and get the water."
                            )
                        ]) { [weak self] in
                            guard let self else { return }
                            self.quest1.spokeToGrandpa = true
                            self.saveQuest1()
                            self.rebuild("Dekati Sumur dan ambil air.")
                        }
                    } else {
                        self.status.text = self.quest1Objective
                    }
                }
                return true
            }
        }

        if quest1.spokeToGrandpa,
           !quest1.collectedWater,
           let well = questPosition(for: "village-well"),
           hypot(point.x - well.x, point.y - well.y) <= 45 {
            approachOrInteract(well, message: "Dekati Sumur untuk mengambil air.") { [weak self] in
                guard let self else { return }
                self.quest1.collectedWater = true
                self.saveQuest1()
                self.rebuild("Air diambil. Bu Mara muncul dan Rumah Bu Mara terbuka.")
            }
            return true
        }

        if quest1.collectedWater,
           let maraHouse = questPosition(for: "bu-mara-house") {
            let mara = CGPoint(x: maraHouse.x + 28, y: maraHouse.y)
            if !quest1.spokeToMara,
               hypot(point.x - mara.x, point.y - mara.y) <= 45 {
                approachOrInteract(mara, message: "Dekati Bu Mara untuk berbicara.") { [weak self] in
                    guard let self else { return }
                    self.presentQuestDialogue([
                        .init(
                            speaker: "Narasi",
                            text: "Arthur berjalan membawa ember air. Bu Mara melambai dari halaman belakangnya yang becek."
                        ),
                        .init(
                            speaker: "Bu Mara",
                            text: "Arthur! Just in time. Can you help me move these clay pots? The shelf is about to give out."
                        ),
                        .init(
                            speaker: "Arthur",
                            text: "The ground is sinking under this leg, Bu Mara. Moving the pots won't fix it. Let me wedge this broken brick under it."
                        )
                    ]) { [weak self] in
                        guard let self else { return }
                        self.quest1.spokeToMara = true
                        self.saveQuest1()
                        self.rebuild("Dekati rak dan ketuk [Interact: Periksa Rak].")
                    }
                }
                return true
            }

            let rack = CGPoint(x: maraHouse.x - 28, y: maraHouse.y)
            if quest1.spokeToMara,
               !quest1.rackFixed,
               hypot(point.x - rack.x, point.y - rack.y) <= 45 {
                approachOrInteract(rack, message: "Dekati rak lalu ketuk [Interact: Periksa Rak].") { [weak self] in
                    self?.startQuest1RackMinigame()
                }
                return true
            }
        }
        return false
    }

    func startQuest1RackMinigame() {
        guard activeQuestMinigame == nil else { return }
        let event = ShelfBalanceMinigameNode()
        event.position = CGPoint(x: size.width / 2, y: size.height / 2)
        event.zPosition = 3000
        event.onComplete = { [weak self] success in
            guard success, let self else { return }
            self.quest1.rackFixed = true
            self.saveQuest1()
        }
        event.onDismiss = { [weak self, weak event] in
            guard let self else { return }
            if self.activeQuestMinigame === event {
                self.activeQuestMinigame = nil
            }
            if self.quest1.rackFixed {
                self.presentQuestDialogue([
                    .init(
                        speaker: "Bu Mara",
                        text: "Oh, thank you! I can always count on you, Arthur. Now, since you're already here... help me lift these other two pots anyway."
                    ),
                    .init(
                        speaker: "Narasi",
                        text: "Arthur menghela napas pasrah sambil tersenyum, memindahkan dua pot, lalu mengambil kembali ember yang isinya sudah tumpah separuh."
                    )
                ]) { [weak self] in
                    self?.bucketFade { [weak self] in
                        self?.rebuild("Air tinggal separuh. Kembali ke Rumah Arthur.")
                    }
                }
            } else {
                self.rebuild("Rak belum selesai. Ketuk rak untuk mencoba lagi.")
            }
        }
        activeQuestMinigame = event
        addChild(event)
        event.start()
    }
}
