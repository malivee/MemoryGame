// Input desa: stik, sumur, Kakek, dialog, QTE, dan HUD.

import SpriteKit

extension VillagePrototypeScene {
    func updateStick(_ touch: UITouch) {
        let point = touch.location(in: hud)
        let dx = point.x - stickCenter.x
        let dy = point.y - stickCenter.y
        let length = max(1, hypot(dx, dy))
        let force = min(1, length / 40)

        stick = CGVector(
            dx: dx / length * force,
            dy: dy / length * force
        )

        knob.position = CGPoint(
            x: stickCenter.x + stick.dx * 30,
            y: stickCenter.y + stick.dy * 30
        )
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard !isLeaving,
              let touch = touches.first else {
            return
        }

        if let qte = activeQTE as? TapQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if let qte = activeQTE as? ClassicTapQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if activeQTE != nil {
            return
        }

        let point = touch.location(in: hud)
        let names = Set(
            hud.nodes(at: point).compactMap(\.name)
        )

        if names.contains("exitVillage"),
           let onExit {
            isLeaving = true
            route = []
            stick = .zero
            stickTouch = nil

            onExit()
            return
        }

        if dialogueIndex != nil {
            advanceStoryDialogue()
            return
        }

        if names.contains("overview") {
            let enteringExploration = overview
            let oldScale = mapNode.xScale
            let oldPosition = mapNode.position
            overview.toggle()
            route = []
            stick = .zero
            stickTouch = nil
            knob.position = stickCenter

            buildHUD()
            updateCamera(immediate: true)
            if enteringExploration {
                animateCameraTransition(
                    fromScale: oldScale,
                    fromPosition: oldPosition
                )
            }
            return
        }

        if !overview &&
            hypot(
                point.x - stickCenter.x,
                point.y - stickCenter.y
            ) < 65 {
            stickTouch = touch
            route = []
            updateStick(touch)
            return
        }

        let destination = touch.location(in: mapNode)

        guard VillageMap.accessible(
            destination,
            stage: access
        ) else {
            hint(
                "Wilayah ini masih tertutup kabut. Selesaikan tugas cerita yang aktif."
            )
            return
        }

        // Interaksi tutorial wajib diproses terlebih dahulu.
        if !overview &&
            handleOpeningInteraction(at: destination) {
            return
        }

        if !overview,
           hypot(
               rackInteraction.position.x - destination.x,
               rackInteraction.position.y - destination.y
           ) < 70,
           !rackInteraction.isHidden {

            let distance = hypot(
                rackInteraction.position.x - actor.position.x,
                rackInteraction.position.y - actor.position.y
            )

            if distance <= 150 {
                startRackQTE()
            } else {
                route = navigation.route(
                    from: actor.position,
                    to: VillageMap.rackApproach
                )

                hint("Dekati rak miring di halaman Bu Mara.")
            }

            return
        }

        if !overview,
           let npc = storyNPCs.children.first(where: {
               VillageMap.accessible(
                   $0.position,
                   stage: access
               ) &&
               hypot(
                   $0.position.x - destination.x,
                   $0.position.y - destination.y
               ) < 85
           }) {

            let distance = hypot(
                npc.position.x - actor.position.x,
                npc.position.y - actor.position.y
            )

            if distance <= 145 {
                route = []
                stick = .zero
                stickTouch = nil
                knob.position = stickCenter

                isWellConversation =
                    npc.name?.hasPrefix("well-resident-") == true

                if isWellConversation,
                   let suffix = npc.name?.split(
                       separator: "-"
                   ).last,
                   let index = Int(suffix) {
                    wellResidentIndex = index
                }

                dialogueIndex = 0
                renderStoryDialogue()
            } else {
                route = navigation.route(
                    from: actor.position,
                    to: npc.position
                )

                hint("Dekati lalu ketuk tokoh untuk berbicara.")
            }

            return
        }

        if overview {
            if let place = VillageMap.landmarks.first(where: {
                $0.rect.insetBy(
                    dx: -30,
                    dy: -30
                ).contains(destination)
            }) {
                hint(place.detail)
            }

            return
        }

        guard point.y < size.height - 65,
              point.y > 35 else {
            return
        }

        guard navigation.walkable(destination) else {
            hint(
                "Jalur tertutup bangunan atau batas tahap. Coba jalan lain."
            )
            return
        }

        route = navigation.route(
            from: actor.position,
            to: destination
        )

        if route.isEmpty {
            hint("Belum ada jalur ke tempat itu pada tahap ini.")
        }
    }

    override func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        if let touch = stickTouch,
           touches.contains(touch) {
            updateStick(touch)
        }
    }

    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        if let touch = stickTouch,
           touches.contains(touch) {
            stickTouch = nil
            stick = .zero
            knob.position = stickCenter
        }
    }

    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        stickTouch = nil
        stick = .zero
        knob.position = stickCenter
        route = []
    }
}
