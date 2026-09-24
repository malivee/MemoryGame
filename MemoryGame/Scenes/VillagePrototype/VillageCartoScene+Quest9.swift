// Quest 9: Arthur dan teman-temannya meninggalkan desa lalu masuk ke Hutan Berkabut.
import SpriteKit
import UIKit

final class VillageQuest9Runtime {
    static let shared = VillageQuest9Runtime()

    var progress = VillageQuest9Progress.load()
    var choiceCompletion: ((Bool) -> Void)?
    var investigationTimerScheduled = false
    var presentingSequence = false
    var detectionCooldown: TimeInterval = 0
}

extension VillageCartoScene {
    var quest9: VillageQuest9Progress {
        get { VillageQuest9Runtime.shared.progress }
        set { VillageQuest9Runtime.shared.progress = newValue }
    }

    func saveQuest9() {
        quest9.save()
    }

    func resetQuest9RuntimeFlags() {
        removeAction(forKey: "quest9-forest-voice-timer")
        let runtime = VillageQuest9Runtime.shared
        runtime.choiceCompletion = nil
        runtime.investigationTimerScheduled = false
        runtime.presentingSequence = false
        runtime.detectionCooldown = 0
    }

    var quest9HomePosition: CGPoint {
        let proposed = quest8GrandpaPosition
        return nearestSafePoint(proposed) ?? layout.world(VillageCartoMap.spawn) ?? actor.position
    }

    var quest9BoundaryPosition: CGPoint {
        if let forest = quest7ForestPiecePosition {
            return nearestSafePoint(forest) ?? forest
        }
        let spawn = layout.world(VillageCartoMap.spawn) ?? actor.position
        return CGPoint(x: spawn.x + 160, y: spawn.y + 80)
    }

    var quest9InvestigationCenter: CGPoint {
        quest7LandslidePosition ?? quest9BoundaryPosition
    }

    var quest9CluePositions: (rock: CGPoint, bark: CGPoint, soil: CGPoint) {
        let center = quest9InvestigationCenter
        return (
            CGPoint(x: center.x - 28, y: center.y - 12),
            CGPoint(x: center.x + 24, y: center.y + 17),
            CGPoint(x: center.x + 5, y: center.y - 28)
        )
    }

    var quest9DeepWoodsPosition: CGPoint {
        let center = quest9InvestigationCenter
        let forest = quest9BoundaryPosition
        let dx = center.x - forest.x
        let dy = center.y - forest.y
        let length = max(1, hypot(dx, dy))
        let proposed = CGPoint(x: center.x + dx / length * 72, y: center.y + dy / length * 72)
        return nearestSafePoint(proposed) ?? proposed
    }

    private var quest9Watchers: [(position: CGPoint, direction: CGVector, name: String)] {
        let start = quest9HomePosition
        let target = quest9BoundaryPosition
        let dx = target.x - start.x
        let dy = target.y - start.y
        let length = max(1, hypot(dx, dy))
        let forward = CGVector(dx: dx / length, dy: dy / length)
        let side = CGVector(dx: -forward.dy, dy: forward.dx)

        func point(_ fraction: CGFloat, _ offset: CGFloat) -> CGPoint {
            CGPoint(
                x: start.x + dx * fraction + side.dx * offset,
                y: start.y + dy * fraction + side.dy * offset
            )
        }

        return [
            (point(0.18, 22), CGVector(dx: side.dx, dy: side.dy), "Kakek"),
            (point(0.42, -24), CGVector(dx: -side.dx, dy: -side.dy), "Warga"),
            (point(0.66, 20), CGVector(dx: side.dx, dy: side.dy), "Warga")
        ]
    }

    // MARK: - World

    func renderQuest9World() {
        guard !quest9.completed else { return }

        renderQuest9PredawnAtmosphere()

        if !quest9.departureChoiceMade {
            renderQuest9DepartureChoice()
            renderQuest9GrandpaAndVillagers()
            return
        }

        if quest9.stealthStarted && !quest9.stealthCompleted {
            renderQuest9GrandpaAndVillagers()
            renderQuest9StealthTarget()
            return
        }

        if quest9.stealthCompleted && !quest9.metPartyAtBoundary {
            renderQuest9Party(at: quest9BoundaryPosition)
            questMarker(at: quest9BoundaryPosition, name: "quest9-party", color: .systemYellow, symbol: "!")
            return
        }

        if quest9.metPartyAtBoundary && !quest9.inspectedSoil {
            renderQuest9InvestigationArea()
            return
        }

        if quest9.inspectedSoil && !quest9.heardForestVoices {
            renderQuest9InvestigationArea()
            renderQuest9DisabledTurnBack()
            scheduleQuest9ForestVoicesIfNeeded()
            return
        }

        if quest9.heardForestVoices && !quest9.markedTree {
            renderQuest9Party(at: quest9InvestigationCenter)
            questMarker(at: quest9InvestigationCenter, name: "quest9-voices-followup", color: .systemPurple, symbol: "!")
            return
        }

        if quest9.markedTree && !quest9.enteredDeepWoods {
            renderQuest9MarkedTree()
            renderQuest9FogGate()
        }
    }

    private func renderQuest9PredawnAtmosphere() {
        let tint = SKShapeNode(rectOf: CGSize(width: VillageTileLayout.bounds.width * 2, height: VillageTileLayout.bounds.height * 2))
        tint.position = CGPoint(x: VillageTileLayout.bounds.midX, y: VillageTileLayout.bounds.midY)
        tint.fillColor = SKColor(red: 0.12, green: 0.22, blue: 0.38, alpha: 0.20)
        tint.strokeColor = .clear
        tint.zPosition = 45
        tint.name = "quest9-dawn-tint"
        world.addChild(tint)
    }

    private func renderQuest9GrandpaAndVillagers() {
        for watcher in quest9Watchers {
            let node = SKNode()
            node.position = watcher.position
            node.zPosition = 70

            let body = SKShapeNode(circleOfRadius: watcher.name == "Kakek" ? 10 : 8)
            body.fillColor = watcher.name == "Kakek" ? .systemBrown : .systemGray
            body.strokeColor = .white.withAlphaComponent(0.7)
            body.lineWidth = 1
            node.addChild(body)

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = watcher.name
            label.fontSize = 8
            label.fontColor = .white
            label.position = CGPoint(x: 0, y: 14)
            node.addChild(label)

            if quest9.stealthStarted && !quest9.stealthCompleted {
                let direction = atan2(watcher.direction.dy, watcher.direction.dx)
                let range: CGFloat = 76
                let half: CGFloat = 0.48
                let path = CGMutablePath()
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: cos(direction - half) * range, y: sin(direction - half) * range))
                path.addLine(to: CGPoint(x: cos(direction + half) * range, y: sin(direction + half) * range))
                path.closeSubpath()
                let cone = SKShapeNode(path: path)
                cone.fillColor = SKColor.systemRed.withAlphaComponent(0.18)
                cone.strokeColor = SKColor.systemOrange.withAlphaComponent(0.5)
                cone.lineWidth = 1
                cone.zPosition = -1
                node.addChild(cone)
            }
            world.addChild(node)
        }
    }

    private func renderQuest9StealthTarget() {
        let target = quest9BoundaryPosition
        questMarker(at: target, name: "quest9-stealth-target", color: .systemGreen, symbol: "→")
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "Titik kumpul"
        label.fontSize = 9
        label.fontColor = .systemGreen
        label.position = CGPoint(x: target.x, y: target.y + 25)
        label.zPosition = 90
        world.addChild(label)
    }

    private func renderQuest9Party(at position: CGPoint) {
        let members = [("Anneth", SKColor.systemPurple), ("Keneth", SKColor.systemBlue), ("Roland", SKColor.systemOrange)]
        for (index, member) in members.enumerated() {
            let angle = CGFloat(index) * (.pi * 2 / 3) + .pi / 2
            let p = CGPoint(x: position.x + cos(angle) * 30, y: position.y + sin(angle) * 22)
            let body = SKShapeNode(circleOfRadius: 8)
            body.position = p
            body.fillColor = member.1
            body.strokeColor = .white.withAlphaComponent(0.7)
            body.lineWidth = 1
            body.zPosition = 72
            world.addChild(body)

            let name = SKLabelNode(fontNamed: "AvenirNext-Bold")
            name.text = member.0
            name.fontSize = 7.5
            name.fontColor = .white
            name.position = CGPoint(x: p.x, y: p.y + 13)
            name.zPosition = 73
            world.addChild(name)
        }
    }

    private func renderQuest9InvestigationArea() {
        let center = quest9InvestigationCenter
        renderQuest7Landslide(at: center)
        renderQuest9Party(at: CGPoint(x: center.x - 54, y: center.y + 45))
        let clues = quest9CluePositions

        if !quest9.inspectedRock {
            renderQuest9Clue(at: clues.rock, icon: "◆", label: "Cari batu", color: .systemGray, name: "quest9-rock")
        } else if !quest9.inspectedBark {
            renderQuest9Clue(at: clues.bark, icon: "▰", label: "Sisa kulit kayu", color: .systemBrown, name: "quest9-bark")
        } else if !quest9.inspectedSoil {
            renderQuest9Clue(at: clues.soil, icon: "●", label: "Tanah basah", color: SKColor(red: 0.35, green: 0.22, blue: 0.13, alpha: 1), name: "quest9-soil")
        }
    }

    private func renderQuest9Clue(at position: CGPoint, icon: String, label: String, color: SKColor, name: String) {
        let aura = SKShapeNode(circleOfRadius: 16)
        aura.position = position
        aura.fillColor = color.withAlphaComponent(0.35)
        aura.strokeColor = .systemYellow
        aura.lineWidth = 1.2
        aura.zPosition = 82
        aura.name = name
        aura.run(.repeatForever(.sequence([.scale(to: 1.18, duration: 0.65), .scale(to: 0.92, duration: 0.65)])))
        world.addChild(aura)

        let symbol = SKLabelNode(fontNamed: "AvenirNext-Bold")
        symbol.text = icon
        symbol.fontSize = 14
        symbol.verticalAlignmentMode = .center
        symbol.name = name
        aura.addChild(symbol)

        let caption = SKLabelNode(fontNamed: "AvenirNext-Bold")
        caption.text = label
        caption.fontSize = 8
        caption.fontColor = .systemYellow
        caption.position = CGPoint(x: position.x, y: position.y + 22)
        caption.zPosition = 83
        world.addChild(caption)
    }

    private func renderQuest9DisabledTurnBack() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "[ Turn Back ]"
        label.fontSize = 12
        label.fontColor = .systemGray
        label.position = CGPoint(x: size.width / 2, y: 68)
        label.zPosition = 2650
        label.alpha = 0.55
        label.name = "quest9-turn-back-disabled"
        hud.addChild(label)
    }

    private func renderQuest9MarkedTree() {
        let position = quest9InvestigationCenter
        let trunk = SKShapeNode(rectOf: CGSize(width: 16, height: 52), cornerRadius: 4)
        trunk.position = CGPoint(x: position.x + 45, y: position.y + 20)
        trunk.fillColor = .systemBrown
        trunk.strokeColor = SKColor(white: 0.15, alpha: 1)
        trunk.lineWidth = 1.4
        trunk.zPosition = 60
        world.addChild(trunk)

        let mark = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mark.text = "╱╱"
        mark.fontSize = 16
        mark.fontColor = .white
        mark.verticalAlignmentMode = .center
        trunk.addChild(mark)
    }

    private func renderQuest9FogGate() {
        let gate = quest9DeepWoodsPosition
        for index in 0..<5 {
            let fog = SKShapeNode(ellipseOf: CGSize(width: 70, height: 32))
            fog.position = CGPoint(x: gate.x + CGFloat(index - 2) * 18, y: gate.y + CGFloat(index % 2) * 12)
            fog.fillColor = SKColor.white.withAlphaComponent(0.28)
            fog.strokeColor = .clear
            fog.zPosition = 75
            fog.run(.repeatForever(.sequence([.moveBy(x: 9, y: 0, duration: 1.6), .moveBy(x: -9, y: 0, duration: 1.6)])))
            world.addChild(fog)
        }
        questMarker(at: gate, name: "quest9-fog-gate", color: .white, symbol: "?")
    }

    // MARK: - Choice and stealth

    private func renderQuest9DepartureChoice() {
        guard hud.childNode(withName: "quest9-choice-panel") == nil else { return }
        let width = min(size.width - 44, 500)
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: 132), cornerRadius: 14)
        panel.name = "quest9-choice-panel"
        panel.position = CGPoint(x: size.width / 2, y: 118)
        panel.fillColor = SKColor(red: 0.08, green: 0.13, blue: 0.22, alpha: 0.98)
        panel.strokeColor = cream
        panel.lineWidth = 1.4
        panel.zPosition = 2700

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Kakek ada di jalan. Apa yang Arthur lakukan?"
        title.fontSize = 12
        title.fontColor = cream
        title.position = CGPoint(x: 0, y: 40)
        title.name = "quest9-choice-panel"
        panel.addChild(title)

        let options = [("Pamit kepada Kakek", "quest9-choice-goodbye"), ("Pergi diam-diam", "quest9-choice-sneak")]
        for (index, option) in options.enumerated() {
            let button = SKShapeNode(rectOf: CGSize(width: width - 40, height: 34), cornerRadius: 8)
            button.position = CGPoint(x: 0, y: 7 - CGFloat(index) * 42)
            button.fillColor = SKColor(red: 0.13, green: 0.23, blue: 0.29, alpha: 1)
            button.strokeColor = cream.withAlphaComponent(0.55)
            button.name = option.1
            let text = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            text.text = option.0
            text.fontSize = 11
            text.fontColor = .white
            text.verticalAlignmentMode = .center
            text.name = option.1
            button.addChild(text)
            panel.addChild(button)
        }
        hud.addChild(panel)
    }

    func handleQuest9ChoiceTap(actions: Set<String>) -> Bool {
        guard !quest9.departureChoiceMade else { return false }
        let goodbye = actions.contains("quest9-choice-goodbye")
        guard goodbye || actions.contains("quest9-choice-sneak") else { return false }

        hud.childNode(withName: "quest9-choice-panel")?.removeFromParent()
        quest9.departureChoiceMade = true
        quest9.choseToSayGoodbye = goodbye
        quest9.stealthStarted = true
        saveQuest9()

        let lines: [VillageQuestDialogueLine]
        if goodbye {
            lines = [
                .init(speaker: "Arthur", text: "Kakek—"),
                .init(speaker: "Narasi", text: "Arthur melihat Kakek dan para warga sedang menahan pintu kandang yang rusak. Ia takut akan dilarang pergi."),
                .init(speaker: "Arthur", text: "Maaf, Kakek. Aku akan menjelaskannya saat pulang.")
            ]
        } else {
            lines = [
                .init(speaker: "Arthur", text: "Kalau Kakek melihatku, beliau pasti menyuruhku kembali."),
                .init(speaker: "Arthur", text: "Aku harus mencapai titik kumpul tanpa terlihat.")
            ]
        }

        presentQuestDialogue(lines) { [weak self] in
            guard let self else { return }
            let start = self.quest9HomePosition
            self.actor.position = start
            self.sourcePosition = self.layout.source(start) ?? self.sourcePosition
            self.rebuild("Hindari area merah dan capai titik kumpul di perbatasan.")
        }
        return true
    }

    func updateQuest9Gameplay(dt: CGFloat) {
        guard quest8.completed, !quest9.completed else { return }
        let runtime = VillageQuest9Runtime.shared
        runtime.detectionCooldown = max(0, runtime.detectionCooldown - TimeInterval(dt))

        if quest9.stealthStarted && !quest9.stealthCompleted {
            if runtime.detectionCooldown == 0, quest9WatcherSeesArthur() {
                runtime.detectionCooldown = 1.1
                HapticsService.shared.playNotification(.warning)
                let start = quest9HomePosition
                actor.position = start
                sourcePosition = layout.source(start) ?? sourcePosition
                route = []
                stick = .zero
                status.text = "Kakek melihat Arthur. Kembali ke titik awal—cari jalur di luar area merah."
                return
            }

            if hypot(actor.position.x - quest9BoundaryPosition.x, actor.position.y - quest9BoundaryPosition.y) < 36 {
                completeQuest9Stealth()
            }
        }
    }

    private func quest9WatcherSeesArthur() -> Bool {
        for watcher in quest9Watchers {
            let dx = actor.position.x - watcher.position.x
            let dy = actor.position.y - watcher.position.y
            let distance = hypot(dx, dy)
            guard distance > 0, distance < 76 else { continue }
            let dot = (dx / distance) * watcher.direction.dx + (dy / distance) * watcher.direction.dy
            if dot > cos(0.48) { return true }
        }
        return false
    }

    private func completeQuest9Stealth() {
        guard !VillageQuest9Runtime.shared.presentingSequence else { return }
        VillageQuest9Runtime.shared.presentingSequence = true
        quest9.stealthCompleted = true
        saveQuest9()
        route = []
        stick = .zero
        HapticsService.shared.playNotification(.success)

        presentQuestDialogue([
            .init(speaker: "Narasi", text: "Suara aktivitas desa mengecil ketika Arthur mencapai perbatasan. Anneth memeriksa tas, Keneth membawa tali."),
            .init(speaker: "Roland", text: "Just in case you drop your bag, we’ll still have something to eat."),
            .init(speaker: "Narasi", text: "Roland mengambil setengah makanan dari tas Arthur. Arthur hanya tersenyum canggung."),
            .init(speaker: "Arthur", text: "Ayo. Lokasi akar pohon dari Buku Elias ada di depan.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest9.metPartyAtBoundary = true
            self.saveQuest9()
            VillageQuest9Runtime.shared.presentingSequence = false
            self.rebuild("Investigate Mode: cari batu yang tidak pada tempatnya di lokasi akar.")
        }
    }

    // MARK: - Investigation and forest

    func handleQuest9Interaction(at point: CGPoint) -> Bool {
        guard questDialogue.isEmpty, !quest9.completed else { return false }

        if quest9.stealthCompleted && !quest9.metPartyAtBoundary {
            if hypot(point.x - quest9BoundaryPosition.x, point.y - quest9BoundaryPosition.y) < 70 {
                completeQuest9Stealth()
                return true
            }
        }

        if quest9.metPartyAtBoundary && !quest9.inspectedSoil {
            let clues = quest9CluePositions
            if !quest9.inspectedRock, quest9Hit(point, clues.rock) {
                quest9.inspectedRock = true
                saveQuest9()
                presentQuestDialogue([
                    .init(speaker: "Arthur", text: "Cari batu ini. Permukaannya bersih, seolah baru saja bergeser dari bawah akar."),
                    .init(speaker: "Arthur", text: "Sekarang cari sisa kulit kayu yang terkelupas di dekatnya.")
                ]) { [weak self] in self?.rebuild("Petunjuk berikutnya: cari sisa kulit kayu.") }
                return true
            }
            if quest9.inspectedRock && !quest9.inspectedBark, quest9Hit(point, clues.bark) {
                quest9.inspectedBark = true
                saveQuest9()
                presentQuestDialogue([
                    .init(speaker: "Arthur", text: "Kulit kayu ini masih lembap. Akar besar itu bergeser belum lama ini."),
                    .init(speaker: "Arthur", text: "Lihat tanah di bawah akar. Cari bagian yang paling basah.")
                ]) { [weak self] in self?.rebuild("Petunjuk terakhir: periksa tanah basah.") }
                return true
            }
            if quest9.inspectedBark && !quest9.inspectedSoil, quest9Hit(point, clues.soil) {
                quest9.inspectedSoil = true
                saveQuest9()
                presentQuestDialogue([
                    .init(speaker: "Arthur", text: "Tanah ini baru runtuh, tetapi tidak ada jejak atau petunjuk lain yang cocok dengan gambar di buku."),
                    .init(speaker: "Anneth", text: "Arthur. We’re out of time. The sun passed the eastern gap."),
                    .init(speaker: "Keneth", text: "That's it. We saw the place. There’s nothing here. Let’s go back.")
                ]) { [weak self] in
                    self?.rebuild("Waktu habis. Tombol Turn Back tidak merespons...")
                }
                return true
            }
        }

        if quest9.markedTree && !quest9.enteredDeepWoods {
            let gate = quest9DeepWoodsPosition
            if quest9Hit(point, gate, radius: 65) {
                startQuest9FogForestFinale()
                return true
            }
        }

        if quest9.heardForestVoices && !quest9.markedTree,
           quest9Hit(point, quest9InvestigationCenter, radius: 70) {
            startQuest9VoicesDialogue()
            return true
        }
        return false
    }

    private func quest9Hit(_ point: CGPoint, _ target: CGPoint, radius: CGFloat = 48) -> Bool {
        hypot(point.x - target.x, point.y - target.y) < radius ||
        hypot(actor.position.x - target.x, actor.position.y - target.y) < radius + 10
    }

    private func scheduleQuest9ForestVoicesIfNeeded() {
        let runtime = VillageQuest9Runtime.shared
        guard !runtime.investigationTimerScheduled, !quest9.heardForestVoices else { return }
        runtime.investigationTimerScheduled = true
        run(.sequence([
            .wait(forDuration: 4.5),
            .run { [weak self] in self?.playQuest9ForestVoices() }
        ]), withKey: "quest9-forest-voice-timer")
    }

    private func playQuest9ForestVoices() {
        guard !quest9.heardForestVoices else { return }
        quest9.heardForestVoices = true
        saveQuest9()
        AudioService.shared.playSystemSound(id: 1104)
        renderQuest9AudioCue(text: "tawa anak-anak", left: true)

        run(.sequence([
            .wait(forDuration: 0.75),
            .run {
                AudioService.shared.playSystemSound(id: 1155)
                self.renderQuest9AudioCue(text: "tok... tok...", left: false)
            },
            .wait(forDuration: 0.85),
            .run {
                AudioService.shared.playSystemSound(id: 1057)
                self.renderQuest9AudioCue(text: "suara warga berbisik", left: true)
            },
            .wait(forDuration: 0.65),
            .run { [weak self] in self?.startQuest9VoicesDialogue() }
        ]))
    }

    private func renderQuest9AudioCue(text value: String, left: Bool) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Italic")
        label.text = left ? "◀  (value)" : "(value)  ▶"
        label.fontSize = 13
        label.fontColor = .white
        label.position = CGPoint(x: left ? size.width * 0.24 : size.width * 0.76, y: size.height * 0.62)
        label.zPosition = 2900
        hud.addChild(label)
        label.run(.sequence([.fadeIn(withDuration: 0.15), .wait(forDuration: 0.6), .fadeOut(withDuration: 0.4), .removeFromParent()]))
    }

    private func startQuest9VoicesDialogue() {
        presentQuestDialogue([
            .init(speaker: "Arthur", text: "Is there someone out there?"),
            .init(speaker: "Keneth", text: "Maybe it’s our voices echoing... from the village? I don't know."),
            .init(speaker: "Anneth", text: "A sound isn't enough. We don't know what's making it. We are already past our time limit."),
            .init(speaker: "Arthur", text: "We just need to look a little closer. If there are real people out there—"),
            .init(speaker: "Anneth", text: "No more than twenty steps. We have to keep this mark in sight.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest9.markedTree = true
            self.saveQuest9()
            self.rebuild("Tanda Anneth dibuat. Masuk ke kabut, maksimal dua puluh langkah.")
        }
    }

    private func startQuest9FogForestFinale() {
        guard !VillageQuest9Runtime.shared.presentingSequence else { return }
        VillageQuest9Runtime.shared.presentingSequence = true
        route = []
        stick = .zero

        presentQuestDialogue([
            .init(speaker: "Narasi", text: "Mereka berjalan perlahan menembus pepohonan. Kabut putih merayap naik dan suara desa hilang total."),
            .init(speaker: "Keneth", text: "Is that... a village?"),
            .init(speaker: "Narasi", text: "Atap rumah, tiang kayu, dan cahaya tungku muncul dari balik kabut. Sosok-sosok bergerak tanpa suara api atau bau asap."),
            .init(speaker: "Anneth", text: "The ground..."),
            .init(speaker: "Narasi", text: "Tiang-tiang rumah itu menggantung di atas tanah dan ditembus kabut putih."),
            .init(speaker: "Anneth", text: "Step back. Now!"),
            .init(speaker: "Narasi", text: "Mereka berbalik. Pohon bertanda pisau dan jalan pulang sudah hilang di balik putihnya kabut.")
        ]) { [weak self] in
            self?.showQuest9FogIllusion()
        }
    }

    private func showQuest9FogIllusion() {
        let overlay = SKNode()
        overlay.name = "quest9-fog-finale"
        overlay.zPosition = 2950

        let fog = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: size.height * 1.4))
        fog.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fog.fillColor = SKColor(white: 0.94, alpha: 0.84)
        fog.strokeColor = .clear
        overlay.addChild(fog)

        for index in 0..<3 {
            let hut = SKNode()
            hut.position = CGPoint(x: size.width * (0.35 + CGFloat(index) * 0.15), y: size.height * (0.44 + CGFloat(index % 2) * 0.09))
            hut.alpha = 0
            let wall = SKShapeNode(rectOf: CGSize(width: 70, height: 42))
            wall.fillColor = SKColor(red: 0.30, green: 0.24, blue: 0.20, alpha: 0.62)
            wall.strokeColor = .clear
            hut.addChild(wall)
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: -42, y: 21))
            roofPath.addLine(to: CGPoint(x: 0, y: 52))
            roofPath.addLine(to: CGPoint(x: 42, y: 21))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.22, green: 0.18, blue: 0.16, alpha: 0.7)
            roof.strokeColor = .clear
            hut.addChild(roof)
            let post = SKShapeNode(rectOf: CGSize(width: 5, height: 24))
            post.position = CGPoint(x: 0, y: -34)
            post.fillColor = .darkGray
            post.strokeColor = .clear
            hut.addChild(post)
            overlay.addChild(hut)
            hut.run(.sequence([.wait(forDuration: Double(index) * 0.22), .fadeIn(withDuration: 0.65)]))
        }

        hud.addChild(overlay)
        overlay.run(.sequence([
            .wait(forDuration: 2.2),
            .fadeOut(withDuration: 0.8),
            .removeFromParent(),
            .run { [weak self] in self?.completeQuest9() }
        ]))
    }

    private func completeQuest9() {
        quest9.enteredDeepWoods = true
        quest9.completed = true
        saveQuest9()
        let progress = PrologueStore.shared.progress
        progress.storyProgress = max(progress.storyProgress, 13)
        PrologueStore.shared.save()
        VillageQuest9Runtime.shared.presentingSequence = false
        HapticsService.shared.playNotification(.success)
        rebuild("Quest 9 selesai: jalan pulang menghilang di dalam kabut.")
        showQuest9CompletionCard()
    }

    private func showQuest9CompletionCard() {
        let card = SKNode()
        card.name = "quest9CompletionCard"
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 3100

        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor(white: 0, alpha: 0.66)
        dim.strokeColor = .clear
        dim.name = "quest9CompletionCard"
        card.addChild(dim)

        let width = min(size.width - 50, 510)
        let background = SKShapeNode(rectOf: CGSize(width: width, height: 190), cornerRadius: 18)
        background.fillColor = SKColor(red: 0.10, green: 0.14, blue: 0.17, alpha: 0.98)
        background.strokeColor = .white.withAlphaComponent(0.75)
        background.lineWidth = 2
        background.name = "quest9CompletionCard"
        card.addChild(background)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "CHAPTER 1 — THE HOLLOW"
        title.fontSize = 18
        title.fontColor = cream
        title.position = CGPoint(x: 0, y: 52)
        title.name = "quest9CompletionCard"
        card.addChild(title)

        let body = SKLabelNode(fontNamed: "AvenirNext-Medium")
        body.text = "Arthur, Anneth, Keneth, dan Roland memasuki Hutan Berkabut. Ilusi desa membaca harapan Arthur, sementara tanda jalan pulang telah lenyap."
        body.numberOfLines = 0
        body.preferredMaxLayoutWidth = width - 55
        body.fontSize = 12
        body.fontColor = .white
        body.verticalAlignmentMode = .center
        body.position = CGPoint(x: 0, y: 0)
        body.name = "quest9CompletionCard"
        card.addChild(body)

        let close = SKLabelNode(fontNamed: "AvenirNext-Bold")
        close.text = "Ketuk untuk melanjutkan"
        close.fontSize = 11
        close.fontColor = .systemGray
        close.position = CGPoint(x: 0, y: -68)
        close.name = "quest9CompletionCard"
        card.addChild(close)
        hud.addChild(card)
    }
}
