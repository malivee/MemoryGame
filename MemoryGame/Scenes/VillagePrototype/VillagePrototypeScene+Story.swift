// Alur awal wajib: sumur, Bu Mara, Kakek, lalu lumbung.

import SpriteKit

extension VillagePrototypeScene {
    func refreshStory() {
        guard let storyProgress else { return }

        setAccess(
            StoryProgression.villageAccess(for: storyProgress)
        )

        rackInteraction.isHidden =
            !StoryProgression.canStartMaraQTE(storyProgress)

        mapNode.childNode(
            withName: "well-water-prompt"
        )?.removeFromParent()

        if StoryProgression.needsWellWater(storyProgress) {
            let prompt = SKShapeNode(circleOfRadius: 17)
            prompt.name = "well-water-prompt"
            prompt.fillColor = .systemTeal
            prompt.strokeColor = .white

            prompt.position = CGPoint(
                x: VillageMap.well.midX,
                y: VillageMap.well.maxY + 18
            )

            prompt.zPosition = 28
            prompt.storyLabel("!", at: .zero, size: 19)

            mapNode.addChild(prompt)
        }

        storyNPCs.removeAllChildren()

        if StoryProgression.showsWellResidents(
            for: storyProgress
        ) {
            let positions = VillageMap.wellResidents
            let colors: [SKColor] = [
                .brown, .systemGray, .systemTeal
            ]

            for (index, position) in positions.enumerated() {
                let node = MemoryCharacter(
                    title: "",
                    color: colors[index]
                )

                node.name = "well-resident-\(index)"
                node.position = position
                node.zPosition = 22

                storyNPCs.addChild(node)
            }
        }

        activeStoryStep = StoryProgression.currentStep(
            for: storyProgress
        )

        if activeStoryStep?.world != .villagePrototype {
            activeStoryStep = StoryProgression.steps.last {
                $0.world == .villagePrototype &&
                $0.id <= storyProgress.storyProgress
            }
        }

        if StoryProgression.needsWellWater(storyProgress) {
            // Tujuan tutorial untuk HUD saja.
            // Tidak menambah reward atau mengubah ID cerita.
            activeStoryStep = StoryProgression.step(
                0,
                "Ambil air di sumur: dekati dan ketuk sumur",
                .villagePrototype,
                "Sumur",
                0,
                [],
                []
            )

            return
        }

        guard let step = activeStoryStep,
              step.world == .villagePrototype else {
            return
        }

        // Kakek sudah dibuat oleh buildMap.
        // Gunakan tokoh yang sama agar tidak muncul dua Kakek.
        if step.id == 2 {
            return
        }

        let positions = VillageMap.storyPositions
        guard let position = positions[step.id] else {
            return
        }

        for (index, npc) in step.npcs.enumerated() {
            let visibleName = step.id == 12 ? "" : npc.name

            let node = MemoryCharacter(
                title: visibleName,
                color: .systemTeal
            )

            node.name = npc.id

            let offsets: [(CGFloat, CGFloat)] = [
                (-24, 0),
                (0, -22),
                (24, 0)
            ]

            let delta: (CGFloat, CGFloat) =
                step.npcs.count == 1
                ? (0, 0)
                : offsets[min(index, offsets.count - 1)]

            node.position = CGPoint(
                x: position.x + delta.0,
                y: position.y + delta.1
            )

            node.zPosition = 22
            storyNPCs.addChild(node)
        }
    }

    // Mengembalikan true jika ketukan sudah ditangani tutorial.
    func handleOpeningInteraction(
        at destination: CGPoint
    ) -> Bool {
        guard let progress = storyProgress else {
            return false
        }

        if StoryProgression.needsWellWater(progress),
           VillageMap.well.insetBy(
               dx: -25,
               dy: -40
           ).contains(destination) {

            let approach = VillageMap.wellApproach

            let distance = hypot(
                actor.position.x - approach.x,
                actor.position.y - approach.y
            )

            guard distance <= 100 else {
                route = navigation.route(
                    from: actor.position,
                    to: approach
                )

                hint(
                    "Dekati sumur, lalu ketuk lagi untuk mengambil air."
                )

                return true
            }

            route = []
            stick = .zero
            stickTouch = nil
            knob.position = stickCenter

            if StoryProgression.collectWellWater(in: progress) {
                PrologueStore.shared.save()
                refreshStory()

                hint(
                    "Air sudah diambil. Temui Bu Mara di halaman rumahnya."
                )
            }

            return true
        }

        let grandpa = VillageMap.grandpa

        if progress.storyProgress == 1,
           hypot(
               destination.x - grandpa.x,
               destination.y - grandpa.y
           ) < 65 {

            let distance = hypot(
                actor.position.x - grandpa.x,
                actor.position.y - grandpa.y
            )

            guard distance <= 145 else {
                route = navigation.route(
                    from: actor.position,
                    to: VillageMap.grandpa
                )

                hint(
                    "Dekati Kakek di depan rumah, lalu ketuk untuk berbicara."
                )

                return true
            }

            route = []
            stick = .zero
            stickTouch = nil
            knob.position = stickCenter

            isWellConversation = false
            dialogueIndex = 0
            renderStoryDialogue()

            return true
        }

        return false
    }

    var currentDialogueLines: [StoryLine] {
        if isWellConversation {
            return [
                StoryProgression.wellConversation[
                    min(
                        wellResidentIndex,
                        StoryProgression.wellConversation.count - 1
                    )
                ]
            ]
        }

        return activeStoryStep?.dialogue ?? []
    }

    func renderStoryDialogue() {
        storyPanel.removeFromParent()
        storyPanel.removeAllChildren()

        guard let index = dialogueIndex,
              currentDialogueLines.indices.contains(index) else {
            return
        }

        let line = currentDialogueLines[index]
        let width = max(180, min(size.width - 40, 620))

        let text = SKLabelNode(fontNamed: "AvenirNext-Regular")
        text.text = line.text
        text.fontSize = 16
        text.fontColor = .white
        text.preferredMaxLayoutWidth = width - 36
        text.numberOfLines = 0
        text.verticalAlignmentMode = .top

        let height = max(115, text.frame.height + 66)

        let background = SKShapeNode(
            rectOf: CGSize(width: width, height: height),
            cornerRadius: 8
        )

        background.fillColor = SKColor(
            white: 0.10,
            alpha: 0.97
        )

        background.strokeColor = SKColor(
            white: 0.8,
            alpha: 0.5
        )

        storyPanel.addChild(background)

        let speaker = label(
            line.speaker,
            at: CGPoint(x: 0, y: height / 2 - 28),
            size: 15,
            on: storyPanel
        )

        speaker.fontColor = .systemYellow

        text.position = CGPoint(
            x: 0,
            y: height / 2 - 45
        )

        storyPanel.addChild(text)

        storyPanel.position = CGPoint(
            x: size.width / 2,
            y: height / 2 + 40
        )

        storyPanel.zPosition = 100
        hud.addChild(storyPanel)
    }

    func advanceStoryDialogue() {
        guard let index = dialogueIndex else { return }

        if index + 1 < currentDialogueLines.count {
            dialogueIndex = index + 1
            renderStoryDialogue()
            return
        }

        dialogueIndex = nil
        renderStoryDialogue()

        // Percakapan warga sumur tidak menyelesaikan quest.
        if isWellConversation {
            isWellConversation = false
            return
        }

        guard let step = activeStoryStep,
              let storyProgress else {
            return
        }

        if step.minigame == .maraShelfQTE {
            guard StoryProgression.finishMaraIntroduction(
                in: storyProgress
            ) else {
                hint("Ambil air di sumur terlebih dahulu.")
                return
            }

            PrologueStore.shared.save()
            refreshStory()

            hint(
                "Sekarang dekati dan ketuk rak miring untuk membantu Bu Mara."
            )

            return
        }

        if step.minigame != nil {
            startProgressionMinigame(for: step)
            return
        }

        if StoryProgression.complete(
            step,
            in: storyProgress
        ) {
            PrologueStore.shared.save()
            refreshStory()
            hint("Bagian kenangan berikutnya terbuka.")
        }
    }

    func startRackQTE() {
        guard activeQTE == nil,
              let storyProgress,
              StoryProgression.canStartMaraQTE(
                  storyProgress
              ) else {
            return
            
        }

        route = []
        stick = .zero
        stickTouch = nil
        knob.position = stickCenter

        let event = TapQuickTimeEventNode(
            config: TapQuickTimeEventConfig(
                requiredTaps: 15,
                buttonPrompt: "ANGKAT",
                heading: "ANGKAT RAK!",
                instruction: "KETUK LAYAR BERULANG KALI UNTUK MENEGAKKAN RAK!",
                style: .classic,
                allowTouchAnywhere: false
            )
        )

        event.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )

        event.zPosition = 2000
        event.onComplete = { [weak self, weak event] success in
            guard success,
                  let self,
                  let event,
                  self.activeQTE === event,
                  let progress = self.storyProgress,
                  let step = StoryProgression.currentStep(
                      for: progress
                  ),
                  step.minigame == .maraShelfQTE else {
                return
            }

            if StoryProgression.complete(step, in: progress) {
                PrologueStore.shared.save()
            }
        }

        event.onDismiss = { [weak self, weak event] in
            guard let self,
                  self.activeQTE === event else {
                return
            }

            self.activeQTE = nil
            self.refreshStory()

            if let progress = self.storyProgress,
               progress.storyProgress >= 1 {
                self.hint(
                    "Rak berhasil ditegakkan. Kembali ke rumah dan bicara dengan Kakek."
                )
            } else {
                self.hint(
                    "Rak belum selesai. Ketuk rak untuk mencoba lagi."
                )
            }
        }

        activeQTE = event
        addChild(event)
        event.start()
    }

    func startProgressionMinigame(
        for step: StoryProgressionStep
    ) {
        guard activeQTE == nil,
              let minigame = step.minigame else { return }

        route = []
        stick = .zero
        stickTouch = nil
        knob.position = stickCenter

        switch minigame {
        case .maraShelfQTE:
            startRackQTE()

        case .basketDeliveryQTE:
            let node = ClassicTapQuickTimeEventNode(
                config: ClassicTapConfig(
                    requiredTaps: 8,
                    buttonPrompt: "ANTAR",
                    heading: "BAWA KERANJANG",
                    instruction: "KETUK UNTUK MEMBAWA KERANJANG KE LUMBUNG"
                )
            )
            present(node, for: step)

        case .seedSorting:
            let node = SeedSortingMinigameNode(
                config: SeedSortingConfig(
                    goodSeedCount: 36,
                    badSeedCount: 14,
                    shakeThresholdTotal: 90
                )
            )
            present(node, for: step)

        case .fencePostQTE:
            let node = ClassicTapQuickTimeEventNode(
                config: ClassicTapConfig(
                    requiredTaps: 12,
                    buttonPrompt: "TAHAN",
                    heading: "TAHAN TIANG!",
                    instruction: "KETUK CEPAT AGAR TIANG TETAP TEGAK"
                )
            )
            present(node, for: step)

        case .tuberSorting:
            let node = ItemSortingMinigameNode(
                config: ItemSortingConfig(requiredItems: 3)
            )
            present(node, for: step)
        }
    }

    private func prepareMinigame(_ node: SKNode) {
        node.position = CGPoint(x: size.width/2, y: size.height/2)
        node.zPosition = 2000
        activeQTE = node
        addChild(node)
    }

    private func completeMinigame(
        _ step: StoryProgressionStep,
        success: Bool
    ) {
        guard success, let progress = storyProgress,
              StoryProgression.currentStep(for: progress)?.id == step.id else { return }
        if StoryProgression.complete(step, in: progress) {
            PrologueStore.shared.save()
        }
    }

    private func dismissMinigame(_ node: SKNode) {
        guard activeQTE === node else { return }
        activeQTE = nil
        refreshStory()
        hint("Tugas selesai. Bagian kenangan berikutnya terbuka.")
    }

    private func present(
        _ node: ClassicTapQuickTimeEventNode,
        for step: StoryProgressionStep
    ) {
        prepareMinigame(node)
        node.onComplete = { [weak self] success in
            self?.completeMinigame(step, success: success)
        }
        node.onDismiss = { [weak self, weak node] in
            guard let node else { return }
            self?.dismissMinigame(node)
        }
        node.start()
    }

    private func present(
        _ node: SeedSortingMinigameNode,
        for step: StoryProgressionStep
    ) {
        prepareMinigame(node)
        node.onComplete = { [weak self] in
            self?.completeMinigame(step, success: true)
        }
        node.onDismiss = { [weak self, weak node] in
            guard let node else { return }
            self?.dismissMinigame(node)
        }
        node.start()
    }

    private func present(
        _ node: ItemSortingMinigameNode,
        for step: StoryProgressionStep
    ) {
        prepareMinigame(node)
        node.onComplete = { [weak self] success in
            self?.completeMinigame(step, success: success)
        }
        node.onDismiss = { [weak self, weak node] in
            guard let node else { return }
            self?.dismissMinigame(node)
        }
        node.start()
    }
}
