// Quest 5: Tambang Garam & Batas yang Menipis.
import SpriteKit

private final class VillageQuest5Runtime {
    static let shared = VillageQuest5Runtime()

    var progress = VillageQuest5Progress.load()
    weak var activeQTE: RockSaltQuickTimeEventNode?
}

extension VillageCartoScene {
    var quest5: VillageQuest5Progress {
        get { VillageQuest5Runtime.shared.progress }
        set { VillageQuest5Runtime.shared.progress = newValue }
    }

    var activeQuest5QTE: RockSaltQuickTimeEventNode? {
        get { VillageQuest5Runtime.shared.activeQTE }
        set { VillageQuest5Runtime.shared.activeQTE = newValue }
    }

    var quest5Objective: String {
        VillageQuestEngine.quest5Objective(for: villageQuestSnapshot)
    }

    func saveQuest5() {
        quest5.save()
    }

    var quest5RockSaltMinePosition: CGPoint? {
        guard layout.placements.contains(where: { $0.id == VillageQuestCatalog.PieceID.rockSaltMinePath }) else {
            return nil
        }
        let source = CGPoint(
            x: (8.5 * VillageCartoMap.side),
            y: (7.5 * VillageCartoMap.side)
        )
        return layout.world(source)
    }

    var quest5CrossroadsPosition: CGPoint {
        let source = CGPoint(
            x: VillageCartoMap.spawn.x + 1.25 * VillageCartoMap.side,
            y: VillageCartoMap.spawn.y + 0.25 * VillageCartoMap.side
        )
        return layout.world(source) ?? CGPoint(x: actor.position.x + 55, y: actor.position.y + 10)
    }

    func renderQuest5World() {
        guard !quest5.completed else { return }

        if let mine = quest5RockSaltMinePosition {
            renderQuest5SaltMine(at: mine)
            let miner = CGPoint(x: mine.x + 44, y: mine.y - 8)
            questNPC(at: miner, name: "Penambang Tua", color: .systemGray)
            if !quest5.minedSalt {
                questMarker(at: CGPoint(x: mine.x, y: mine.y + 32), name: "quest5-mine", color: .systemOrange, symbol: "!")
            }
        }

        if let house = quest4AnnethHousePosition {
            renderAnnethKitchen(at: house)
            let mother = quest4MotherPosition(from: house)
            if quest5.minedSalt && !quest5.deliveredSalt {
                questMarker(at: CGPoint(x: mother.x, y: mother.y + 25), name: "quest5-mother", color: .systemYellow, symbol: "!")
            }
        }

        if quest5.deliveredSalt && !quest5.completed {
            let child = quest5CrossroadsPosition
            renderQuest5Crossroads(at: child)
            questNPC(at: child, name: "Anak Kecil", color: .systemGreen)
            questMarker(at: CGPoint(x: child.x, y: child.y + 25), name: "quest5-child", color: .systemYellow, symbol: "!")
        }
    }

    func renderQuest5SaltMine(at position: CGPoint) {
        let mine = SKNode()
        mine.position = position
        mine.zPosition = 54

        let dust = SKShapeNode(ellipseOf: CGSize(width: 116, height: 58))
        dust.position = CGPoint(x: 5, y: -17)
        dust.fillColor = SKColor(red: 0.72, green: 0.70, blue: 0.63, alpha: 0.52)
        dust.strokeColor = .clear
        mine.addChild(dust)

        let slope = SKShapeNode(rectOf: CGSize(width: 120, height: 34), cornerRadius: 5)
        slope.position = CGPoint(x: 2, y: -6)
        slope.zRotation = -0.06
        slope.fillColor = SKColor(red: 0.78, green: 0.76, blue: 0.70, alpha: 1)
        slope.strokeColor = SKColor(red: 0.46, green: 0.44, blue: 0.40, alpha: 1)
        slope.lineWidth = 2
        mine.addChild(slope)

        let cave = SKShapeNode(ellipseOf: CGSize(width: 48, height: 52))
        cave.position = CGPoint(x: -22, y: 4)
        cave.fillColor = SKColor(white: 0.02, alpha: 0.96)
        cave.strokeColor = SKColor(red: 0.58, green: 0.56, blue: 0.51, alpha: 1)
        cave.lineWidth = 3
        mine.addChild(cave)

        let saltDeposits: [(position: CGPoint, size: CGSize, rotation: CGFloat)] = [
            (CGPoint(x: 16, y: 11), CGSize(width: 16, height: 13), -0.12),
            (CGPoint(x: 32, y: 4), CGSize(width: 19, height: 14), 0.08),
            (CGPoint(x: 48, y: -8), CGSize(width: 15, height: 12), -0.05),
            (CGPoint(x: 18, y: -18), CGSize(width: 22, height: 15), 0.14),
            (CGPoint(x: 40, y: -24), CGSize(width: 17, height: 13), -0.16),
            (CGPoint(x: -2, y: -24), CGSize(width: 14, height: 11), 0.10)
        ]

        for deposit in saltDeposits {
            let salt = SKShapeNode(rectOf: CGSize(width: 16, height: 13), cornerRadius: 2)
            salt.path = CGPath(
                roundedRect: CGRect(
                    x: -deposit.size.width / 2,
                    y: -deposit.size.height / 2,
                    width: deposit.size.width,
                    height: deposit.size.height
                ),
                cornerWidth: 2,
                cornerHeight: 2,
                transform: nil
            )
            salt.position = deposit.position
            salt.zRotation = deposit.rotation
            salt.fillColor = SKColor(red: 0.90, green: 0.91, blue: 0.86, alpha: 1)
            salt.strokeColor = SKColor(red: 0.62, green: 0.62, blue: 0.58, alpha: 1)
            salt.lineWidth = 1.5
            mine.addChild(salt)
        }

        world.addChild(mine)
    }

    func renderQuest5Crossroads(at position: CGPoint) {
        let path = SKShapeNode(rectOf: CGSize(width: 74, height: 18), cornerRadius: 4)
        path.position = CGPoint(x: position.x, y: position.y - 18)
        path.zPosition = 53
        path.zRotation = -0.10
        path.fillColor = SKColor(red: 0.48, green: 0.38, blue: 0.22, alpha: 0.65)
        path.strokeColor = SKColor(red: 0.28, green: 0.22, blue: 0.13, alpha: 0.8)
        path.lineWidth = 2
        world.addChild(path)
    }

    func handleQuest5Interaction(at point: CGPoint) -> Bool {
        if !quest5.minedSalt,
           let mine = quest5RockSaltMinePosition,
           hypot(point.x - mine.x, point.y - mine.y) <= 58 {
            approachOrInteract(mine, message: "Dekati mulut tambang garam.") { [weak self] in
                self?.startQuest5RockSaltQTE()
            }
            return true
        }

        if quest5.minedSalt,
           !quest5.deliveredSalt,
           let house = quest4AnnethHousePosition {
            let mother = quest4MotherPosition(from: house)
            if hypot(point.x - mother.x, point.y - mother.y) <= 50 {
                approachOrInteract(mother, message: "Serahkan rock salt ke Ibu Anneth.") { [weak self] in
                    self?.startQuest5DeliveryDialogue()
                }
                return true
            }
        }

        if quest5.deliveredSalt && !quest5.completed {
            let child = quest5CrossroadsPosition
            if hypot(point.x - child.x, point.y - child.y) <= 50 {
                approachOrInteract(child, message: "Dekati Anak Kecil di persimpangan.") { [weak self] in
                    self?.startQuest5ChildDialogue()
                }
                return true
            }
        }

        return false
    }

    func startQuest5RockSaltQTE() {
        guard activeQuest5QTE == nil, !quest5.minedSalt else { return }
        route = []
        stick = .zero

        let qte = RockSaltQuickTimeEventNode(config: QuickTimeEventConfig(
            radius: 82,
            stage1Duration: 1.35,
            stage2Duration: 1.10,
            stage1Zone: QTETargetZone(start: 0.58, end: 0.85, greatStart: 0.70, greatEnd: 0.75),
            stage2Zone: QTETargetZone(start: 0.20, end: 0.45, greatStart: 0.28, greatEnd: 0.33),
            buttonPrompt: "PAHAT GARAM",
            allowTouchAnywhere: true,
            autoDismissDelay: 0.65
        ))
        qte.position = CGPoint(x: size.width / 2, y: size.height / 2)
        qte.zPosition = 3100
        qte.onComplete = { [weak self] success in
            guard let self, success else { return }
            self.quest5.minedSalt = true
            self.quest5.heardSeaLegend = true
            let progress = PrologueStore.shared.progress
            progress.hasRockSalt = true
            PrologueStore.shared.save()
            self.saveQuest5()
        }
        qte.onDismiss = { [weak self, weak qte] in
            guard let self else { return }
            if self.activeQuest5QTE === qte { self.activeQuest5QTE = nil }
            guard self.quest5.minedSalt else {
                self.rebuild("Kristal garam retak. Coba pahat lagi dari tepi.")
                return
            }
            self.startQuest5SeaDialogue()
        }
        activeQuest5QTE = qte
        addChild(qte)
        qte.start()
    }

    func startQuest5SeaDialogue() {
        presentQuestDialogue([
            .init(speaker: "Arthur", text: "These pieces... they're smaller than they used to be."),
            .init(speaker: "Penambang Tua", text: "The spots near the entrance are picked clean. The easy hits are gone."),
            .init(speaker: "Penambang Tua", text: "My father used to say there’s an old legend about a place far away with white earth."),
            .init(speaker: "Penambang Tua", text: "They say the water is salty. Even the wind tastes like salt."),
            .init(speaker: "Penambang Tua", text: "If that’s true, we’re a bunch of fools hitting rocks here every day.")
        ]) { [weak self] in
            self?.rebuild("Rock salt didapat. Kembali ke Rumah Anneth.")
        }
    }

    func startQuest5DeliveryDialogue() {
        presentQuestDialogue([
            .init(speaker: "Ibu Anneth", text: "It’s not just the salt. The fever-leaves are getting scarce."),
            .init(speaker: "Ibu Anneth", text: "Dry wood has to be scavenged further out. And the tubers... many are rotting."),
            .init(speaker: "Arthur", text: "The old miner told me a story... about a place with salty wind. Why hasn't anyone tried looking for it?"),
            .init(speaker: "Ibu Anneth", text: "Because humans stay alive by knowing their limits, Arthur."),
            .init(speaker: "Ibu Anneth", text: "Beyond the boundaries, there are things that hunt us.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest5.deliveredSalt = true
            let progress = PrologueStore.shared.progress
            progress.deliveredRockSalt = true
            PrologueStore.shared.save()
            self.saveQuest5()
            self.rebuild("Di jalan pulang, seseorang memanggil Arthur.")
        }
    }

    func startQuest5ChildDialogue() {
        presentQuestDialogue([
            .init(speaker: "Anak Kecil", text: "Brother Arthur! Grandpa Beryn’s knees are hurting. Can you find some of these leaves?"),
            .init(speaker: "Arthur", text: "Daun perak? Aku akan mencarinya." )
        ]) { [weak self] in
            guard let self else { return }
            self.quest5.receivedSilverLeafMission = true
            self.quest5.completed = true
            let progress = PrologueStore.shared.progress
            progress.storyProgress = max(progress.storyProgress, 6)
            progress.isHerbalUnlocked = true
            progress.mapBStage = .herbalHills
            PrologueStore.shared.save()
            self.saveQuest5()
            self.rebuild("Quest 5 selesai. Misi Daun Perak terbuka.")
        }
    }
}
