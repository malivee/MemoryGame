// Quest 10: Tidak Ada Jalan Pulang.
import SpriteKit

final class VillageQuest10Runtime {
    static let shared = VillageQuest10Runtime()

    var progress = VillageQuest10Progress.load()
    var choiceCompletion: ((Bool) -> Void)?
    weak var activeQTE: TapQuickTimeEventNode?
    var hollowPosition: CGPoint?
    var catchCooldown: TimeInterval = 0
}

extension VillageCartoScene {
    var quest10: VillageQuest10Progress {
        get { VillageQuest10Runtime.shared.progress }
        set { VillageQuest10Runtime.shared.progress = newValue }
    }

    var activeQuest10QTE: TapQuickTimeEventNode? {
        get { VillageQuest10Runtime.shared.activeQTE }
        set { VillageQuest10Runtime.shared.activeQTE = newValue }
    }

    func saveQuest10() {
        quest10.save()
    }

    func resetQuest10RuntimeFlags() {
        hud.childNode(withName: "quest10-choice-panel")?.removeFromParent()
        VillageQuest10Runtime.shared.choiceCompletion = nil
        VillageQuest10Runtime.shared.hollowPosition = nil
        VillageQuest10Runtime.shared.catchCooldown = 0
        activeQuest10QTE?.removeFromParent()
        activeQuest10QTE = nil
    }

    func prepareQuest10BoardIfNeeded() {
        guard quest9.completed, !quest10.boardPrepared else { return }

        layout.replaceAll(placements: [
            .init(
                id: VillageQuestCatalog.PieceID.noWayHomeO,
                column: 12,
                row: 10,
                turns: VillageCartoMap.preferredTurns(forPieceID: VillageQuestCatalog.PieceID.noWayHomeO)
            )
        ])

        if let safe = quest10NearestSafePoint() {
            sourcePosition = layout.source(safe) ?? sourcePosition
            actor.position = safe
        }

        selected = nil
        selectedBuilding = nil
        draftTurns = 0
        page = 0
        quest10.boardPrepared = true
        saveQuest10()
        save()
    }

    func renderQuest10World() {
        renderQuest10ForestOnlyMap()
        renderQuest10Party()

        guard quest10PuzzleReady else {
            questMarker(at: actor.position, name: "quest10-need-map", color: .systemGray, symbol: "...")
            return
        }

        let event = quest10EventPosition
        if !quest10.sawIllusion {
            questMarker(at: event, name: "quest10-illusion", color: .systemYellow, symbol: "!")
        } else if !quest10.routeChoiceMade {
            questMarker(at: event, name: "quest10-choice", color: .systemOrange, symbol: "?")
        } else if !quest10.chaseCompleted {
            renderQuest10Hollow(at: quest10HollowPosition)
            questMarker(at: quest10EscapePosition, name: "quest10-escape", color: .systemGreen, symbol: "!")
        }
    }

    func handleQuest10Interaction(at point: CGPoint) -> Bool {
        guard questDialogue.isEmpty, quest10PuzzleReady, !quest10.completed else { return false }
        let event = quest10EventPosition
        guard hypot(point.x - event.x, point.y - event.y) < 72 ||
              hypot(actor.position.x - event.x, actor.position.y - event.y) < 86 else {
            return false
        }

        if !quest10.sawIllusion {
            approachOrInteract(event, message: "Dekati celah hutan yang tersisa.") { [weak self] in
                self?.startQuest10IllusionSequence()
            }
            return true
        }

        if !quest10.routeChoiceMade {
            presentQuest10Choice()
            return true
        }

        return false
    }

    func handleQuest10ChoiceTap(actions: Set<String>) -> Bool {
        guard let completion = VillageQuest10Runtime.shared.choiceCompletion else { return false }
        let forest = actions.contains("quest10-choice-forest")
        guard forest || actions.contains("quest10-choice-village") else { return false }
        hud.childNode(withName: "quest10-choice-panel")?.removeFromParent()
        VillageQuest10Runtime.shared.choiceCompletion = nil
        completion(forest)
        return true
    }

    private var quest10PuzzleReady: Bool {
        let pieces = layout.placements.filter { VillageQuestCatalog.quest10PieceOrder.contains($0.id) }
        guard pieces.count == VillageQuestCatalog.quest10PieceOrder.count else { return false }
        var connectedIDs: Set<Int> = [pieces[0].id]
        var changed = true
        while changed {
            changed = false
            for first in pieces where connectedIDs.contains(first.id) {
                for second in pieces where !connectedIDs.contains(second.id) {
                    if VillageTileLayout.linked(first, second) {
                        connectedIDs.insert(second.id)
                        changed = true
                    }
                }
            }
        }
        return connectedIDs.count == pieces.count
    }

    private var quest10EventPosition: CGPoint {
        let placed = layout.placements.filter { VillageQuestCatalog.quest10PieceOrder.contains($0.id) }
        let average = placed.reduce(CGPoint.zero) { partial, placement in
            CGPoint(x: partial.x + placement.center.x, y: partial.y + placement.center.y)
        }
        let count = max(1, CGFloat(placed.count))
        let center = CGPoint(x: average.x / count, y: average.y / count)
        return nearestSafePoint(center) ?? quest10NearestSafePoint() ?? actor.position
    }

    private var quest10EscapePosition: CGPoint {
        let start = quest10EventPosition
        var best: CGPoint?
        var bestScore: CGFloat = -CGFloat.greatestFiniteMagnitude
        for piece in layout.placements where VillageQuestCatalog.quest10PieceOrder.contains(piece.id) {
            for cell in VillageTileLayout.cells(of: piece) {
                for x in stride(from: CGFloat(18), through: VillageTileLayout.side - 18, by: 10) {
                    for y in stride(from: CGFloat(18), through: VillageTileLayout.side - 18, by: 10) {
                        let point = CGPoint(x: cell.origin.x + x, y: cell.origin.y + y)
                        guard layout.walkable(point) else { continue }
                        let distance = hypot(point.x - start.x, point.y - start.y)
                        let uphillBias = (point.y - start.y) * 0.35
                        let score = distance + uphillBias
                        if score > bestScore {
                            bestScore = score
                            best = point
                        }
                    }
                }
            }
        }
        return best ?? start
    }

    private var quest10HollowPosition: CGPoint {
        if let position = VillageQuest10Runtime.shared.hollowPosition {
            return position
        }
        let event = quest10EventPosition
        let position = CGPoint(x: event.x - 76, y: event.y + 54)
        VillageQuest10Runtime.shared.hollowPosition = position
        return position
    }

    private func quest10NearestSafePoint() -> CGPoint? {
        for piece in layout.placements where VillageQuestCatalog.quest10PieceOrder.contains(piece.id) {
            for cell in VillageTileLayout.cells(of: piece) {
                for x in stride(from: CGFloat(18), through: VillageTileLayout.side - 18, by: 10) {
                    for y in stride(from: CGFloat(18), through: VillageTileLayout.side - 18, by: 10) {
                        let point = CGPoint(x: cell.origin.x + x, y: cell.origin.y + y)
                        if layout.walkable(point) { return point }
                    }
                }
            }
        }
        return nil
    }

    private func renderQuest10ForestOnlyMap() {
        let haze = SKShapeNode(rect: VillageTileLayout.bounds)
        haze.fillColor = SKColor(red: 0.03, green: 0.11, blue: 0.08, alpha: 0.24)
        haze.strokeColor = .clear
        haze.zPosition = 45
        world.addChild(haze)

        for (index, piece) in layout.placements.enumerated() {
            let p = piece.center
            let tree = SKNode()
            tree.position = CGPoint(x: p.x - 24 + CGFloat(index % 3) * 18, y: p.y + 18)
            tree.zPosition = 58

            let trunk = SKShapeNode(rectOf: CGSize(width: 9, height: 44), cornerRadius: 3)
            trunk.fillColor = SKColor(red: 0.12, green: 0.07, blue: 0.04, alpha: 0.84)
            trunk.strokeColor = .clear
            tree.addChild(trunk)

            let crown = SKShapeNode(ellipseOf: CGSize(width: 62, height: 78))
            crown.position = CGPoint(x: 0, y: 34)
            crown.fillColor = SKColor(red: 0.03, green: 0.22, blue: 0.12, alpha: 0.78)
            crown.strokeColor = SKColor(red: 0.01, green: 0.07, blue: 0.05, alpha: 0.8)
            crown.lineWidth = 1.5
            tree.addChild(crown)

            world.addChild(tree)
        }
    }

    private func renderQuest10Party() {
        let base = quest10NearestSafePoint() ?? actor.position
        questNPC(at: CGPoint(x: base.x + 36, y: base.y + 20), name: "Anneth", color: .systemTeal)
        questNPC(at: CGPoint(x: base.x - 34, y: base.y + 24), name: "Keneth", color: .systemPurple)
        questNPC(at: CGPoint(x: base.x + 8, y: base.y - 34), name: "Roland", color: .systemOrange)
    }

    private func renderQuest10Hollow(at point: CGPoint) {
        let hollow = SKNode()
        hollow.name = "quest10-hollow"
        hollow.position = point
        hollow.zPosition = 72

        let body = SKShapeNode(ellipseOf: CGSize(width: 112, height: 150))
        body.fillColor = SKColor(red: 0.01, green: 0.01, blue: 0.015, alpha: 0.86)
        body.strokeColor = SKColor(red: 0.18, green: 0.02, blue: 0.06, alpha: 0.8)
        body.lineWidth = 2
        hollow.addChild(body)

        for x in [-18.0, 18.0] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: 12, height: 7))
            eye.position = CGPoint(x: x, y: 28)
            eye.fillColor = SKColor(red: 0.90, green: 0.08, blue: 0.10, alpha: 0.95)
            eye.strokeColor = .clear
            hollow.addChild(eye)
        }

        world.addChild(hollow)
        hollow.run(.repeatForever(.sequence([
            .scale(to: 1.04, duration: 0.42),
            .scale(to: 0.98, duration: 0.38)
        ])))
    }

    private func startQuest10IllusionSequence() {
        presentQuestDialogue([
            .init(speaker: "Anneth", text: "Step back. Now!"),
            .init(speaker: "Narasi", text: "Arthur membalikkan badan. Batang pohon dengan tanda torehan pisau sudah lenyap ditelan dinding kabut putih."),
            .init(speaker: "Keneth", text: "Where is the tree?! Where is the path?!"),
            .init(speaker: "Narasi", text: "Tidak ada suara desa. Hanya hening yang terlalu rapat."),
            .init(speaker: "Arthur", text: "It didn't set a trap. It just read what we wanted to see... and gave it a shape."),
            .init(speaker: "Narasi", text: "Cahaya tungku di desa ilusi meredup. Atap rumah melipat ke bawah, tersedot ke kabut, lalu menyatu menjadi sosok gelap raksasa.")
        ]) { [weak self] in
            guard let self else { return }
            self.quest10.sawIllusion = true
            self.saveQuest10()
            self.presentQuest10Choice()
        }
    }

    private func presentQuest10Choice() {
        VillageQuest10Runtime.shared.choiceCompletion = { [weak self] choseForest in
            guard let self else { return }
            self.quest10.routeChoiceMade = true
            self.quest10.choseForestGap = choseForest
            self.saveQuest10()
            self.presentQuestDialogue([
                .init(speaker: "Keneth", text: "Arthur, we have to run!"),
                .init(speaker: "Anneth", text: "There! Through that gap! Run!"),
                .init(speaker: "Narasi", text: "The Hollow membaca ragu di langkah Arthur. Map yang tadi disusun kini menjadi satu-satunya jalur kabur.")
            ]) { [weak self] in
                guard let self else { return }
                VillageQuest10Runtime.shared.hollowPosition = self.quest10HollowPosition
                self.rebuild("Lari ke celah hutan. Jika The Hollow menangkap Arthur, ketuk cepat untuk lepas.")
            }
        }

        hud.childNode(withName: "quest10-choice-panel")?.removeFromParent()
        let width = min(size.width - 50, 560)
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: 138), cornerRadius: 14)
        panel.name = "quest10-choice-panel"
        panel.position = CGPoint(x: size.width / 2, y: 122)
        panel.fillColor = SKColor(white: 0.035, alpha: 0.96)
        panel.strokeColor = SKColor.systemRed.withAlphaComponent(0.72)
        panel.lineWidth = 2
        panel.zPosition = 2750

        text("Tidak ada jalan pulang", at: CGPoint(x: 0, y: 46), size: 14, parent: panel, color: .systemRed)
        quest10ChoiceButton("Cari jalan desa", name: "quest10-choice-village", at: CGPoint(x: -width * 0.24, y: -12), parent: panel)
        quest10ChoiceButton("Ikuti celah hutan", name: "quest10-choice-forest", at: CGPoint(x: width * 0.24, y: -12), parent: panel)
        hud.addChild(panel)
    }

    private func quest10ChoiceButton(_ title: String, name: String, at point: CGPoint, parent: SKNode) {
        let node = SKShapeNode(rectOf: CGSize(width: 192, height: 44), cornerRadius: 10)
        node.name = name
        node.position = point
        node.fillColor = SKColor(red: 0.09, green: 0.16, blue: 0.13, alpha: 1)
        node.strokeColor = cream.withAlphaComponent(0.62)
        node.lineWidth = 1.4
        text(title, at: .zero, size: 12, parent: node, color: cream)
        node.children.first?.name = name
        parent.addChild(node)
    }

    func updateQuest10Gameplay(dt: CGFloat) {
        guard quest9.completed,
              quest10.routeChoiceMade,
              !quest10.completed,
              !isMap,
              questDialogue.isEmpty else {
            return
        }

        if hypot(actor.position.x - quest10EscapePosition.x, actor.position.y - quest10EscapePosition.y) < 42 {
            completeQuest10Escape()
            return
        }

        guard activeQuest10QTE == nil else { return }

        let runtime = VillageQuest10Runtime.shared
        runtime.catchCooldown = max(0, runtime.catchCooldown - TimeInterval(dt))

        var hollow = quest10HollowPosition
        let dx = actor.position.x - hollow.x
        let dy = actor.position.y - hollow.y
        let distance = max(1, hypot(dx, dy))
        let speed: CGFloat = quest10.rolandPulledArthur ? 54 : 70
        hollow = CGPoint(
            x: hollow.x + dx / distance * speed * dt,
            y: hollow.y + dy / distance * speed * dt
        )
        VillageQuest10Runtime.shared.hollowPosition = hollow
        world.childNode(withName: "quest10-hollow")?.position = hollow

        if distance < 38, runtime.catchCooldown == 0 {
            startQuest10CaughtQTE()
        }
    }

    private func startQuest10CaughtQTE() {
        guard activeQuest10QTE == nil else { return }
        route = []
        stick = .zero
        startQuest10CaughtEscapeQTE()
    }

    private func startQuest10CaughtEscapeQTE() {
        guard activeQuest10QTE == nil else { return }
        let qte = TapQuickTimeEventNode(config: TapQuickTimeEventConfig(
            requiredTaps: 9,
            buttonPrompt: "PUSH",
            heading: "THE HOLLOW CAUGHT YOU",
            instruction: "Ketuk cepat untuk lepas dan lanjut kabur.",
            style: .hollowChase,
            allowTouchAnywhere: true,
            autoDismissDelay: 0.45,
            decayPerSecond: 0
        ))
        qte.position = CGPoint(x: size.width / 2, y: size.height / 2)
        qte.zPosition = 3200
        qte.onComplete = { [weak self] success in
            guard let self, success else { return }
            self.quest10.rolandPulledArthur = true
            self.saveQuest10()
            HapticsService.shared.playNotification(.warning)
            let hollow = self.quest10HollowPosition
            let dx = self.actor.position.x - hollow.x
            let dy = self.actor.position.y - hollow.y
            let length = max(1, hypot(dx, dy))
            VillageQuest10Runtime.shared.catchCooldown = 2.4
            VillageQuest10Runtime.shared.hollowPosition = CGPoint(
                x: self.actor.position.x - dx / length * 190,
                y: self.actor.position.y - dy / length * 190
            )
        }
        qte.onDismiss = { [weak self, weak qte] in
            guard let self else { return }
            if self.activeQuest10QTE === qte { self.activeQuest10QTE = nil }
            self.rebuild("Roland menarik Arthur lepas. Lanjutkan kabur ke celah hutan.")
        }
        activeQuest10QTE = qte
        addChild(qte)
        qte.start()
    }

    private func completeQuest10Escape() {
        guard !quest10.completed else { return }
        quest10.chaseCompleted = true
        quest10.completed = true
        let progress = PrologueStore.shared.progress
        progress.storyProgress = max(progress.storyProgress, 14)
        PrologueStore.shared.save()
        saveQuest10()
        HapticsService.shared.playNotification(.success)
        route = []
        stick = .zero
        showQuest10ChapterCompleteCutscene()
    }

    private func showQuest10ChapterCompleteCutscene() {
        hud.childNode(withName: "quest10ChapterComplete")?.removeFromParent()

        let overlay = SKNode()
        overlay.name = "quest10ChapterComplete"
        overlay.zPosition = 3400

        let background = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.fillColor = .black
        background.strokeColor = .clear
        background.alpha = 0
        overlay.addChild(background)

        let art = SKSpriteNode(imageNamed: "ArthurOpening6")
        art.position = CGPoint(x: size.width / 2, y: size.height / 2 + 36)
        art.zPosition = 1
        art.alpha = 0
        let targetWidth = size.width * 1.04
        if art.size.width > 0 {
            art.setScale(targetWidth / art.size.width)
        }
        overlay.addChild(art)

        let tint = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        tint.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tint.fillColor = SKColor(white: 0, alpha: 0.42)
        tint.strokeColor = .clear
        tint.zPosition = 2
        tint.alpha = 0
        overlay.addChild(tint)

        let logo = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        logo.text = "ARTHUR ADVENTURES"
        logo.fontSize = min(34, size.width * 0.062)
        logo.fontColor = cream
        logo.position = CGPoint(x: size.width / 2, y: size.height * 0.73)
        logo.zPosition = 3
        logo.alpha = 0
        overlay.addChild(logo)

        let chapter = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        chapter.text = "CHAPTER 1 : COMPLETED"
        chapter.fontSize = min(24, size.width * 0.047)
        chapter.fontColor = .white
        chapter.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
        chapter.zPosition = 3
        chapter.alpha = 0
        overlay.addChild(chapter)

        let voiceover = SKLabelNode(fontNamed: "AvenirNext-Medium")
        voiceover.text = "The path home should have been downhill. I knew that. But when I looked back, there was no path left to choose. There was only the fog, and the dark thing moving inside it. We kept running higher, deeper into the woods, leaving everything we knew behind."
        voiceover.numberOfLines = 0
        voiceover.preferredMaxLayoutWidth = min(size.width - 44, 620)
        voiceover.fontSize = min(15, size.width * 0.032)
        voiceover.fontColor = SKColor(white: 0.90, alpha: 1)
        voiceover.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        voiceover.zPosition = 3
        voiceover.alpha = 0
        overlay.addChild(voiceover)

        hud.addChild(overlay)
        AudioService.shared.playSystemSound(id: 1057)

        background.run(.fadeIn(withDuration: 0.8))
        art.run(.sequence([.wait(forDuration: 0.25), .fadeIn(withDuration: 1.0)]))
        tint.run(.sequence([.wait(forDuration: 0.5), .fadeIn(withDuration: 1.0)]))
        logo.run(.sequence([.wait(forDuration: 1.0), .fadeIn(withDuration: 0.8)]))
        voiceover.run(.sequence([.wait(forDuration: 1.65), .fadeIn(withDuration: 1.0)]))
        chapter.run(.sequence([.wait(forDuration: 7.0), .fadeIn(withDuration: 1.2)]))
        overlay.run(.sequence([
            .wait(forDuration: 9.4),
            .run { [weak self] in
                self?.rebuild("Chapter 1 completed.")
                self?.showQuest10ChapterCompleteBadge()
            }
        ]))
    }

    private func showQuest10ChapterCompleteBadge() {
        let badge = SKNode()
        badge.name = "quest10ChapterCompleteBadge"
        badge.position = CGPoint(x: size.width / 2, y: size.height / 2)
        badge.zPosition = 3400

        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor(white: 0, alpha: 0.72)
        dim.strokeColor = .clear
        dim.name = "quest10ChapterCompleteBadge"
        badge.addChild(dim)

        let panel = SKShapeNode(rectOf: CGSize(width: min(size.width - 48, 470), height: 168), cornerRadius: 18)
        panel.fillColor = SKColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 0.98)
        panel.strokeColor = cream.withAlphaComponent(0.9)
        panel.lineWidth = 2
        panel.name = "quest10ChapterCompleteBadge"
        badge.addChild(panel)

        text("ARTHUR ADVENTURES", at: CGPoint(x: 0, y: 42), size: 17, parent: panel, color: cream)
        text("CHAPTER 1 : COMPLETED", at: CGPoint(x: 0, y: 5), size: 20, parent: panel, color: .white)
        text("Ketuk untuk menutup", at: CGPoint(x: 0, y: -54), size: 11, parent: panel, color: .systemGray)
        panel.children.forEach { $0.name = "quest10ChapterCompleteBadge" }

        hud.addChild(badge)
    }
}
