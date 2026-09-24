import SpriteKit
import UIKit

// Rendering adapter. Gameplay rules live in Models and Systems.
extension ExplorationScene {
    func targetCameraPosition(for actorPos: CGPoint) -> CGPoint {
        let scale = worldScale
        let targetX = size.width / 2 - actorPos.x * scale
        let targetY = size.height / 2 - actorPos.y * scale

        let worldW = (level?.mapBounds.width ?? PrologueLevel.bounds.width) * scale
        let worldH = (level?.mapBounds.height ?? PrologueLevel.bounds.height) * scale

        let clampedX: CGFloat
        if worldW > size.width {
            let minX = size.width - worldW
            let maxX: CGFloat = 0
            clampedX = min(maxX, max(minX, targetX))
        } else {
            clampedX = (size.width - worldW) / 2
        }

        let clampedY: CGFloat
        if worldH > size.height {
            let minY = size.height - worldH
            let maxY: CGFloat = 0
            clampedY = min(maxY, max(minY, targetY))
        } else {
            clampedY = (size.height - worldH) / 2
        }
        return CGPoint(x: clampedX, y: clampedY)
    }

    func updateCamera(dt: CGFloat, immediate: Bool = false) {
        let scale = worldScale
        world.setScale(scale)
        let target = targetCameraPosition(for: arthur.position)
        if immediate {
            world.position = target
        } else {
            let lerpSpeed = min(1.0, dt * 7.5)
            world.position.x += (target.x - world.position.x) * lerpSpeed
            world.position.y += (target.y - world.position.y) * lerpSpeed
        }
    }

    func animateArrival() {
        let reduced = UIAccessibility.isReduceMotionEnabled
        let duration: TimeInterval = reduced ? 0.22 : 0.85
        MemoryPortal.play(on: self, origin: CGPoint(x: size.width / 2, y: size.height / 2), inward: false, duration: duration)
        hud.alpha = 0
        updateCamera(dt: 0, immediate: true)
        let finalPosition = world.position
        world.alpha = reduced ? 0 : 0.35
        if !reduced {
            world.setScale(worldScale * 1.10)
            world.position = CGPoint(x: finalPosition.x - 24, y: finalPosition.y - 12)
        }
        let settle = SKAction.group([
            .scale(to: worldScale, duration: duration), .move(to: finalPosition, duration: duration),
            .fadeIn(withDuration: duration * 0.8)
        ])
        settle.timingMode = .easeOut
        world.run(settle)
        if entry.region == .boundary {
            let stage = progress.mapBStage
            let card = SKNode()
            card.zPosition = 350
            card.position = CGPoint(x: size.width / 2, y: size.height / 2)
            card.alpha = 0

            let stageTitle: String
            let stageSubtitle: String
            let stageIcon: String
            let stageColor: SKColor

            switch stage {
            case .rockSalt:
                stageIcon = "🧂"
                stageTitle = "TAMBANG ROCK SALT"
                stageSubtitle = "Tahap I · Lereng Penambang & Mulut Gua"
                stageColor = SKColor(red: 0.45, green: 0.88, blue: 0.98, alpha: 1.0)
            case .herbalHills:
                stageIcon = "🌿"
                stageTitle = "PERBUKITAN HERBAL"
                stageSubtitle = "Tahap II · Tepi Kebun & Puncak Menhir Batas Aman"
                stageColor = SKColor(red: 0.55, green: 0.92, blue: 0.45, alpha: 1.0)
            case .woodcutterSlope:
                stageIcon = "🪵"
                stageTitle = "LERENG PENEBANG KAYU"
                stageSubtitle = "Tahap III · Teras Hutan & Rahasia Catatan Elias"
                stageColor = SKColor(red: 0.95, green: 0.75, blue: 0.38, alpha: 1.0)
            case .theBoundary:
                stageIcon = "🎗️"
                stageTitle = "THE BOUNDARY"
                stageSubtitle = "Tahap IV · Titik Kumpul & Gerbang Deep Woods"
                stageColor = SKColor(red: 0.98, green: 0.45, blue: 0.25, alpha: 1.0)
            }

            let cardW: CGFloat = min(size.width - 60, 460)
            let cardH: CGFloat = 88

            let shadow = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 20)
            shadow.fillColor = SKColor(white: 0, alpha: 0.45)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -4)
            card.addChild(shadow)

            let bg = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 20)
            bg.fillColor = SKColor(red: 0.08, green: 0.11, blue: 0.13, alpha: 0.96)
            bg.strokeColor = stageColor
            bg.lineWidth = 2.0
            card.addChild(bg)

            let innerLine = SKShapeNode(rectOf: CGSize(width: cardW - 8, height: cardH - 8), cornerRadius: 16)
            innerLine.fillColor = .clear
            innerLine.strokeColor = SKColor(red: 0.92, green: 0.82, blue: 0.52, alpha: 0.35)
            innerLine.lineWidth = 1.0
            card.addChild(innerLine)

            let chapterLbl = SKLabelNode(text: "✦ MAP B · ZONA TRANSISI LEMBAH ✦")
            chapterLbl.fontName = "AvenirNext-Bold"
            chapterLbl.fontSize = 10
            chapterLbl.fontColor = SKColor(red: 0.92, green: 0.82, blue: 0.52, alpha: 0.9)
            chapterLbl.position = CGPoint(x: 0, y: 22)
            card.addChild(chapterLbl)

            let titleLbl = SKLabelNode(text: "\(stageIcon)  \(stageTitle)")
            titleLbl.fontName = "AvenirNext-Heavy"
            titleLbl.fontSize = 19
            titleLbl.fontColor = stageColor
            titleLbl.position = CGPoint(x: 0, y: -2)
            card.addChild(titleLbl)

            let subLbl = SKLabelNode(text: stageSubtitle)
            subLbl.fontName = "AvenirNext-Medium"
            subLbl.fontSize = 11.5
            subLbl.fontColor = SKColor(red: 0.92, green: 0.92, blue: 0.88, alpha: 0.88)
            subLbl.position = CGPoint(x: 0, y: -24)
            card.addChild(subLbl)

            addChild(card)

            let scaleIn = SKAction.group([
                .fadeIn(withDuration: duration * 0.4),
                .scale(to: 1.0, duration: duration * 0.4)
            ])
            scaleIn.timingMode = .easeOut

            let scaleOut = SKAction.group([
                .fadeOut(withDuration: duration * 0.35),
                .moveBy(x: 0, y: 15, duration: duration * 0.35)
            ])
            scaleOut.timingMode = .easeIn

            card.setScale(0.85)
            card.run(.sequence([
                scaleIn,
                .wait(forDuration: 2.0),
                scaleOut,
                .removeFromParent()
            ]))
        } else {
            let title = storyLabel(entry.region == .house ? "Rumah di lembah" : (entry.region == .village ? "Desa di lembah" : "Kaki perbukitan"),
                                   at: CGPoint(x: size.width / 2, y: size.height / 2), size: 28,
                                   color: SKColor(red: 0.98, green: 0.91, blue: 0.72, alpha: 1))
            title.zPosition = 350
            title.alpha = 0
            title.run(.sequence([.fadeIn(withDuration: duration * 0.35), .wait(forDuration: duration * 0.35),
                                 .fadeOut(withDuration: duration * 0.35), .removeFromParent()]))
        }
        hud.run(.sequence([.wait(forDuration: duration * 0.55), .fadeIn(withDuration: duration * 0.45)]))
        run(.sequence([.wait(forDuration: duration), .run { [weak self] in
            guard let self else { return }
            self.enteringMemory = false
            self.catchGrace = 2
            self.say("Geser stik atau ketuk tanah untuk bergerak. Dekati benda/teman, lalu ketuk Interaksi.", duration: 5)
        }]), withKey: "memoryArrival")
    }

    func buildWorld() {
        let local = PrologueProgress()
        local.placements = progress.placements.filter { worldLocations.contains($0.value.piece) }
        for piece in worldLocations {
            if local.placement(of: piece) == nil {
                local.placements[piece.slot] = PhotoPlacement(piece: piece, turns: 0)
            }
        }
        local.mapBStage = progress.mapBStage
        local.hasRockSalt = progress.hasRockSalt
        local.deliveredRockSalt = progress.deliveredRockSalt
        local.hasHerbal = progress.hasHerbal
        local.encounteredHollow = progress.encounteredHollow
        local.metBerynAfterHerbal = progress.metBerynAfterHerbal
        local.gatheredWood = progress.gatheredWood
        local.hasEliasBook = progress.hasEliasBook
        local.boundaryMarked = progress.boundaryMarked
        local.hasBook = progress.hasBook
        local.isRockSaltUnlocked = progress.isRockSaltUnlocked
        local.isHerbalUnlocked = progress.isHerbalUnlocked
        local.joined = progress.joined
        local.shownBook = progress.shownBook
        local.foundMarker = progress.foundMarker
        local.groupGathered = progress.groupGathered
        local.leftVillage = progress.leftVillage
        local.noticedChangedRoute = progress.noticedChangedRoute
        local.assembled = progress.assembled
        level = PrologueLevel.make(region: entry.region, progress: local)
        if entry.region == .echoes && echoesVillagePassed {
            level.obstacles.removeAll { $0.kind == "Rumah ilusi" || $0.kind == "Sumur" }
        }
        let solids = ExplorationCollisionGeometry.solids(for: level)
        navigation = MemoryNavigation(bounds: level.mapBounds, solids: solids, fog: level.fog(progress: local))
        if let texture = SceneryTextures.texture(level: level, progress: local) {
            let scenery = SKSpriteNode(texture: texture)
            scenery.anchorPoint = .zero
            scenery.size = level.mapBounds.size
            scenery.zPosition = -10
            world.addChild(scenery)
            sceneryNode = scenery
        }
        MemoryAtmosphere.add(to: world, level: level)
        for zone in level.zones {
            let available = level.available(zone, progress: local)
            let base = SKShapeNode(rect: zone.rect)
            base.fillColor = .clear
            base.strokeColor = .clear
            world.addChild(base)
            if available {
                world.storyLabel(zone.piece == .lake ? (progress.lakeVariant?.title ?? "") : zone.piece.title,
                                 at: CGPoint(x: zone.rect.midX, y: zone.rect.maxY - 24), size: 12,
                                 color: SKColor(white: 1, alpha: 0.4))

            } else {
                let fog = SKShapeNode(rect: zone.rect.insetBy(dx: 2, dy: 2), cornerRadius: 10)
                fog.fillColor = SKColor(red: 0.83, green: 0.87, blue: 0.78, alpha: 0.90)
                fog.strokeColor = SKColor(red: 0.60, green: 0.68, blue: 0.52, alpha: 0.5)
                fog.lineWidth = 1.5
                fog.zPosition = 30
                world.addChild(fog)
                let label = fog.storyLabel("Kabut kenangan", at: CGPoint(x: zone.rect.midX, y: zone.rect.midY), size: 15, color: SKColor(red: 0.28, green: 0.35, blue: 0.26, alpha: 0.9))
                label.zPosition = 1
                for index in 0..<7 {
                    let cloud = SKShapeNode(ellipseOf: CGSize(width: zone.rect.width * 0.65, height: 42))
                    cloud.fillColor = SKColor(white: 1.0, alpha: 0.38)
                    cloud.strokeColor = .clear
                    cloud.position = CGPoint(x: zone.rect.midX + (index % 2 == 0 ? -12 : 12),
                                            y: zone.rect.minY + 36 + CGFloat(index) * zone.rect.height / 8)
                    fog.addChild(cloud)
                    cloud.run(.repeatForever(.sequence([
                        .moveBy(x: index % 2 == 0 ? 12 : -12, y: 3, duration: 2.2 + Double(index) * 0.2),
                        .moveBy(x: index % 2 == 0 ? -12 : 12, y: -3, duration: 2.2 + Double(index) * 0.2)
                    ])))
                }
            }
        }
        if let book = level.book, !progress.hasBook { addBook(at: book) }
        for (friend, point) in level.friends {
            let npc = MemoryCharacter(title: friend.rawValue, color: color(friend))
            npc.position = point
            friendNodes[friend] = npc
            world.addChild(npc)
            if progress.joined.contains(friend) {
                npc.setStatusBadge(icon: "✓", text: "Siap Ikut", color: SKColor(red: 0.42, green: 0.82, blue: 0.45, alpha: 1.0))
            } else if progress.hasBook {
                npc.setStatusBadge(icon: "💬", text: "Ajak Ikut", color: SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 1.0))
            }
        }
        if let marker = level.marker, worldInstalled(.oldPath) {
            let post = SKShapeNode(rectOf: CGSize(width: 13, height: 31), cornerRadius: 2)
            post.fillColor = SKColor(red: 0.73, green: 0.61, blue: 0.40, alpha: 1)
            post.position = marker; post.zPosition = 15; world.addChild(post)
            post.storyLabel("Penanda", at: CGPoint(x: 0, y: 32), size: 11)
            markerNode = post
        }
        if level.region == .house {
            stumpNodes.removeAll()
            for (i, stump) in houseStumpCushions.enumerated() {
                let node = SKNode()
                node.name = "stump_\(i)"
                node.position = stump
                world.addChild(node)
                stumpNodes.append(node)
            }
            let bedAnchor = SKNode()
            bedAnchor.name = "bedAnchor"
            bedAnchor.position = houseBedSpot
            world.addChild(bedAnchor)
            self.bedNode = bedAnchor
        }
        if entry.region == .boundary {
            buildBoundaryWorldObjects()
        }
        checkpoint = navigation.nearestOpen(to: level.spawn(for: entry, progress: progress))
        arthur.position = checkpoint
        world.addChild(arthur)
        if progress.foundMarker && !progress.leftVillage && entry.region == .foothills {
            for (index, friend) in FriendID.allCases.enumerated() {
                let actor = MemoryCharacter(title: friend.rawValue, color: color(friend))
                actor.position = navigation.nearestOpen(to: CGPoint(x: checkpoint.x - CGFloat(index + 1) * 20, y: checkpoint.y + 12))
                companions.append(actor); world.addChild(actor)
            }
        }
        for definition in level.patrols where navigation.walkable(definition.points[0]) {
            let patrol = MemoryPatrol(definition)
            patrols.append(patrol)
            world.addChild(patrol.field); world.addChild(patrol.character)
        }
    }

    func refreshEchoesScenery() {
        guard entry.region == .echoes else { return }
        sceneryNode?.removeFromParent()
        var map = PrologueLevel.make(region: .echoes, progress: progress)
        map.obstacles.removeAll { $0.kind == "Rumah ilusi" || $0.kind == "Sumur" }
        guard let texture = SceneryTextures.texture(level: map, progress: progress) else { return }
        let scenery = SKSpriteNode(texture: texture)
        scenery.anchorPoint = .zero
        scenery.size = map.mapBounds.size
        scenery.zPosition = -10
        world.addChild(scenery)
        sceneryNode = scenery
    }

    func createWorldBadge(icon: String, title: String, subtitle: String? = nil, accentColor: SKColor) -> SKNode {
        let root = SKNode()
        root.zPosition = 45

        let titleLbl = SKLabelNode(text: title)
        titleLbl.fontName = "AvenirNext-Bold"
        titleLbl.fontSize = 10.0
        titleLbl.fontColor = SKColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)
        titleLbl.verticalAlignmentMode = .center

        let textWidth = titleLbl.frame.width
        let badgeW = max(textWidth + 56, 134)
        let badgeH: CGFloat = subtitle != nil ? 34 : 26

        // 1. Soft ground shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: badgeW, height: badgeH), cornerRadius: badgeH / 2)
        shadow.fillColor = SKColor(white: 0, alpha: 0.42)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -2.5)
        root.addChild(shadow)

        // 2. Glassmorphism backing pill
        let bg = SKShapeNode(rectOf: CGSize(width: badgeW, height: badgeH), cornerRadius: badgeH / 2)
        bg.fillColor = SKColor(red: 0.08, green: 0.11, blue: 0.13, alpha: 0.95)
        bg.strokeColor = accentColor
        bg.lineWidth = 1.6
        root.addChild(bg)

        // Inner subtle golden rim
        let innerRim = SKShapeNode(rectOf: CGSize(width: badgeW - 4, height: badgeH - 4), cornerRadius: (badgeH - 4) / 2)
        innerRim.fillColor = .clear
        innerRim.strokeColor = SKColor(red: 0.95, green: 0.85, blue: 0.50, alpha: 0.25)
        innerRim.lineWidth = 0.8
        root.addChild(innerRim)

        // Left circular icon badge
        let iconCircle = SKShapeNode(circleOfRadius: (badgeH - 8) / 2)
        iconCircle.fillColor = accentColor.withAlphaComponent(0.25)
        iconCircle.strokeColor = accentColor.withAlphaComponent(0.8)
        iconCircle.lineWidth = 1.0
        iconCircle.position = CGPoint(x: -badgeW / 2 + badgeH / 2 + 1, y: 0)
        root.addChild(iconCircle)

        let iconLbl = SKLabelNode(text: icon)
        iconLbl.fontSize = badgeH > 30 ? 12 : 10
        iconLbl.verticalAlignmentMode = .center
        iconLbl.position = .zero
        iconCircle.addChild(iconLbl)

        // Texts offset to the right of icon
        let textCenterX: CGFloat = (iconCircle.position.x + (badgeH / 2) + badgeW / 2) / 2 - 2

        if let sub = subtitle {
            titleLbl.position = CGPoint(x: textCenterX, y: 5.5)
            titleLbl.fontSize = 9.5
            root.addChild(titleLbl)

            let subLbl = SKLabelNode(text: sub)
            subLbl.fontName = "AvenirNext-Medium"
            subLbl.fontSize = 8.0
            subLbl.fontColor = accentColor.withAlphaComponent(0.95)
            subLbl.verticalAlignmentMode = .center
            subLbl.position = CGPoint(x: textCenterX, y: -6.5)
            root.addChild(subLbl)
        } else {
            titleLbl.position = CGPoint(x: textCenterX, y: 0)
            root.addChild(titleLbl)
        }

        // Floating bobbing animation
        root.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3.5, duration: 0.85),
            .moveBy(x: 0, y: -3.5, duration: 0.85)
        ])))

        return root
    }

    func buildBoundaryWorldObjects() {
        switch progress.mapBStage {
        case .rockSalt:
            // 1. Bongkahan Rock Salt di mulut tambang (330, 350)
            if !progress.hasRockSalt {
                let saltContainer = SKNode()
                saltContainer.name = "rockSaltCluster"
                saltContainer.position = CGPoint(x: 330, y: 350)
                saltContainer.zPosition = 35

                // Bayangan tanah
                let shadow = SKShapeNode(ellipseOf: CGSize(width: 38, height: 14))
                shadow.fillColor = SKColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.40)
                shadow.strokeColor = .clear
                shadow.position = CGPoint(x: 0, y: -8)
                saltContainer.addChild(shadow)

                // Halo kristal es biru berdenyut
                let crystalAura = SKShapeNode(circleOfRadius: 26)
                crystalAura.fillColor = SKColor(red: 0.65, green: 0.88, blue: 1.0, alpha: 0.28)
                crystalAura.strokeColor = SKColor(red: 0.75, green: 0.95, blue: 1.0, alpha: 0.75)
                crystalAura.lineWidth = 1.6
                saltContainer.addChild(crystalAura)
                crystalAura.run(.repeatForever(.sequence([
                    .scale(to: 1.25, duration: 0.9),
                    .scale(to: 0.95, duration: 0.9)
                ])))

                // Kristal 1: Prisma tengah
                let c1 = SKShapeNode(rectOf: CGSize(width: 15, height: 22), cornerRadius: 3)
                c1.fillColor = SKColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.98)
                c1.strokeColor = SKColor(red: 0.65, green: 0.85, blue: 0.98, alpha: 1.0)
                c1.lineWidth = 1.4
                c1.zRotation = 0.18
                saltContainer.addChild(c1)

                // Kristal 2: Sayap kanan
                let c2 = SKShapeNode(rectOf: CGSize(width: 12, height: 16), cornerRadius: 2)
                c2.fillColor = SKColor(red: 0.88, green: 0.95, blue: 1.0, alpha: 0.92)
                c2.strokeColor = SKColor(red: 0.60, green: 0.82, blue: 0.96, alpha: 1.0)
                c2.lineWidth = 1.2
                c2.position = CGPoint(x: 10, y: -4)
                c2.zRotation = -0.32
                saltContainer.addChild(c2)

                // Kristal 3: Sayap kiri
                let c3 = SKShapeNode(rectOf: CGSize(width: 10, height: 14), cornerRadius: 2)
                c3.fillColor = SKColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 0.90)
                c3.strokeColor = SKColor(red: 0.60, green: 0.82, blue: 0.96, alpha: 1.0)
                c3.lineWidth = 1.2
                c3.position = CGPoint(x: -9, y: -5)
                c3.zRotation = 0.40
                saltContainer.addChild(c3)

                // 4 Partikel kerlap-kerlip bintang berkilau
                for i in 0..<4 {
                    let sparkle = SKLabelNode(text: "✨")
                    sparkle.fontSize = 11
                    sparkle.position = CGPoint(x: (i % 2 == 0 ? -14 : 14) + CGFloat(i * 3), y: CGFloat(i * 6) - 4)
                    saltContainer.addChild(sparkle)
                    sparkle.run(.repeatForever(.sequence([
                        .wait(forDuration: Double(i) * 0.35),
                        .group([.scale(to: 1.3, duration: 0.4), .fadeIn(withDuration: 0.25)]),
                        .group([.scale(to: 0.7, duration: 0.4), .fadeOut(withDuration: 0.35)])
                    ])))
                }

                // Storybook Badge Melayang Carto
                let badge = createWorldBadge(icon: "💎", title: "Bongkahan Rock Salt", subtitle: "Endapan Murni Mulut Tambang", accentColor: SKColor(red: 0.45, green: 0.88, blue: 0.98, alpha: 1.0))
                badge.position = CGPoint(x: 0, y: 32)
                saltContainer.addChild(badge)

                world.addChild(saltContainer)
                self.rockSaltNode = saltContainer
            }

            // 2. Mulut Gua / Lorong Dalam Gelap (330, 395)
            let shaftContainer = SKNode()
            shaftContainer.name = "mineShaftEntrance"
            shaftContainer.position = CGPoint(x: 330, y: 395)
            shaftContainer.zPosition = 30

            let barrier = SKShapeNode(rectOf: CGSize(width: 60, height: 18), cornerRadius: 4)
            barrier.fillColor = SKColor(red: 0.22, green: 0.16, blue: 0.10, alpha: 0.92)
            barrier.strokeColor = SKColor(red: 0.92, green: 0.52, blue: 0.20, alpha: 0.95)
            barrier.lineWidth = 1.8
            shaftContainer.addChild(barrier)

            let shaftBadge = createWorldBadge(icon: "⛔", title: "Lorong Tambang Gelap", subtitle: "Rawan Runtuh · Akses Ditutup", accentColor: SKColor(red: 0.95, green: 0.55, blue: 0.22, alpha: 1.0))
            shaftBadge.position = CGPoint(x: 0, y: 26)
            shaftContainer.addChild(shaftBadge)

            world.addChild(shaftContainer)
            self.mineShaftNode = shaftContainer

            // 3. Papan Penunjuk Kembali ke Desa di (40, 120)
            let exitNode = SKNode()
            exitNode.position = CGPoint(x: 40, y: 120)
            exitNode.zPosition = 25
            let exitBadge = createWorldBadge(icon: "🏡", title: "Jalur ke Desa", subtitle: "Rumah Anneth", accentColor: SKColor(red: 0.72, green: 0.85, blue: 0.58, alpha: 1.0))
            exitNode.addChild(exitBadge)
            world.addChild(exitNode)

        case .herbalHills:
            // 1. Tanaman herbal di atas batu menjorok (710, 340)
            if !progress.hasHerbal {
                let herbContainer = SKNode()
                herbContainer.name = "herbalPlant"
                herbContainer.position = CGPoint(x: 710, y: 340)
                herbContainer.zPosition = 35

                // Bayangan tanah
                let shadow = SKShapeNode(ellipseOf: CGSize(width: 32, height: 12))
                shadow.fillColor = SKColor(red: 0.12, green: 0.18, blue: 0.10, alpha: 0.35)
                shadow.strokeColor = .clear
                shadow.position = CGPoint(x: 0, y: -6)
                herbContainer.addChild(shadow)

                // Halo zamrud-emas berdenyut
                let aura = SKShapeNode(circleOfRadius: 24)
                aura.fillColor = SKColor(red: 0.45, green: 0.92, blue: 0.35, alpha: 0.22)
                aura.strokeColor = SKColor(red: 0.85, green: 1.0, blue: 0.45, alpha: 0.65)
                aura.lineWidth = 1.5
                herbContainer.addChild(aura)
                aura.run(.repeatForever(.sequence([
                    .scale(to: 1.25, duration: 0.85),
                    .scale(to: 0.95, duration: 0.85)
                ])))

                // Rumpun 7 kuntum chamomile berbunga emas
                for i in 0..<7 {
                    let angle = CGFloat(i) * .pi * 2 / 7
                    let rad: CGFloat = i == 0 ? 0 : 8
                    let flower = SKShapeNode(circleOfRadius: 4.8)
                    flower.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.22, alpha: 1.0)
                    flower.strokeColor = .white
                    flower.lineWidth = 1.2
                    flower.position = CGPoint(x: cos(angle) * rad, y: sin(angle) * (rad * 0.75))
                    herbContainer.addChild(flower)
                }

                // Butir serbuk sari emas melayang
                for i in 0..<3 {
                    let spark = SKLabelNode(text: "✨")
                    spark.fontSize = 10
                    spark.position = CGPoint(x: (i == 0 ? -12 : (i == 1 ? 12 : 0)), y: 8)
                    herbContainer.addChild(spark)
                    spark.run(.repeatForever(.sequence([
                        .wait(forDuration: Double(i) * 0.4),
                        .group([.fadeIn(withDuration: 0.3), .moveBy(x: 0, y: 10, duration: 0.9), .scale(to: 1.2, duration: 0.9)]),
                        .fadeOut(withDuration: 0.3),
                        .moveBy(x: 0, y: -10, duration: 0)
                    ])))
                }

                let badge = createWorldBadge(icon: "🌿", title: "Chamomile Emas Langka", subtitle: "Puncak Batu Menjorok", accentColor: SKColor(red: 0.96, green: 0.88, blue: 0.25, alpha: 1.0))
                badge.position = CGPoint(x: 0, y: 32)
                herbContainer.addChild(badge)

                world.addChild(herbContainer)
                self.herbalNode = herbContainer
            }

            // 2. Batu Pembatas Batas Aman Desa di (670, 730, 790, 850, y: 120)
            boundaryStoneNodes.removeAll()
            for (idx, sx) in [CGFloat(670), CGFloat(730), CGFloat(790), CGFloat(850)].enumerated() {
                let stoneAnchor = SKNode()
                stoneAnchor.position = CGPoint(x: sx, y: 120)
                stoneAnchor.zPosition = 25

                // Ornamen spiral runik bercahaya pada batu
                let rune = SKShapeNode(circleOfRadius: 4.5)
                rune.fillColor = .clear
                rune.strokeColor = SKColor(red: 0.65, green: 0.85, blue: 0.65, alpha: 0.7)
                rune.lineWidth = 1.0
                rune.position = CGPoint(x: 0, y: 8)
                stoneAnchor.addChild(rune)

                if idx == 1 {
                    let badge = createWorldBadge(icon: "🗿", title: "Batu Pembatas Kuno", subtitle: "Batas Aman Desa", accentColor: SKColor(red: 0.65, green: 0.85, blue: 0.65, alpha: 1.0))
                    badge.position = CGPoint(x: 60, y: 35)
                    stoneAnchor.addChild(badge)
                }
                world.addChild(stoneAnchor)
                boundaryStoneNodes.append(stoneAnchor)
            }

            // 3. The Hollow Encounter at tree line (850, 220)
            if !progress.encounteredHollow {
                let hollowContainer = SKNode()
                hollowContainer.name = "hollowPhantom"
                hollowContainer.position = CGPoint(x: 850, y: 220)
                hollowContainer.zPosition = 35

                // Aura bayangan gelap berviolet pekat
                let darkAura = SKShapeNode(circleOfRadius: 28)
                darkAura.fillColor = SKColor(red: 0.08, green: 0.03, blue: 0.16, alpha: 0.75)
                darkAura.strokeColor = SKColor(red: 0.65, green: 0.25, blue: 0.88, alpha: 0.9)
                darkAura.lineWidth = 1.8
                hollowContainer.addChild(darkAura)
                darkAura.run(.repeatForever(.sequence([
                    .scale(to: 1.25, duration: 1.2),
                    .scale(to: 0.90, duration: 1.2)
                ])))

                // Badan bayangan
                let phantomBody = SKShapeNode(rectOf: CGSize(width: 20, height: 42), cornerRadius: 9)
                phantomBody.fillColor = SKColor(red: 0.04, green: 0.02, blue: 0.07, alpha: 0.98)
                phantomBody.strokeColor = SKColor(red: 0.45, green: 0.18, blue: 0.65, alpha: 0.85)
                phantomBody.lineWidth = 1.2
                hollowContainer.addChild(phantomBody)

                // Sepasang mata dingin menyala di kegelapan
                let eyeL = SKShapeNode(circleOfRadius: 2.5)
                eyeL.fillColor = SKColor(red: 0.75, green: 0.90, blue: 1.0, alpha: 0.98)
                eyeL.strokeColor = .clear
                eyeL.position = CGPoint(x: -4.5, y: 11)
                let eyeR = SKShapeNode(circleOfRadius: 2.5)
                eyeR.fillColor = SKColor(red: 0.75, green: 0.90, blue: 1.0, alpha: 0.98)
                eyeR.strokeColor = .clear
                eyeR.position = CGPoint(x: 4.5, y: 11)
                hollowContainer.addChild(eyeL)
                hollowContainer.addChild(eyeR)

                // Kedip misterius pada mata Hollow
                eyeL.run(.repeatForever(.sequence([
                    .wait(forDuration: 2.5),
                    .scaleY(to: 0.1, duration: 0.12),
                    .scaleY(to: 1.0, duration: 0.12)
                ])))
                eyeR.run(.repeatForever(.sequence([
                    .wait(forDuration: 2.5),
                    .scaleY(to: 0.1, duration: 0.12),
                    .scaleY(to: 1.0, duration: 0.12)
                ])))

                // Gerak mengambang di udara
                hollowContainer.run(.repeatForever(.sequence([
                    .moveBy(x: 0, y: 6, duration: 1.3),
                    .moveBy(x: 0, y: -6, duration: 1.3)
                ])))

                let badge = createWorldBadge(icon: "👁️", title: "Sosok Bayangan", subtitle: "The Hollow di Balik Kabut", accentColor: SKColor(red: 0.78, green: 0.45, blue: 0.95, alpha: 1.0))
                badge.position = CGPoint(x: 0, y: 38)
                hollowContainer.addChild(badge)

                world.addChild(hollowContainer)
                self.hollowNode = hollowContainer
            }

            // 4. Exit Sign to Village (50, 110)
            let exitNode = SKNode()
            exitNode.position = CGPoint(x: 50, y: 110)
            exitNode.zPosition = 25
            let exitBadge = createWorldBadge(icon: "🏡", title: "Jalur ke Desa", subtitle: "Kakek Beryn", accentColor: SKColor(red: 0.72, green: 0.85, blue: 0.58, alpha: 1.0))
            exitNode.addChild(exitBadge)
            world.addChild(exitNode)

        case .woodcutterSlope:
            // 1. Tumpukan kayu bakar di (180, 140)
            let woodContainer = SKNode()
            woodContainer.name = "woodcutterLogs"
            woodContainer.position = CGPoint(x: 180, y: 140)
            woodContainer.zPosition = 25

            let logStack = SKShapeNode(rectOf: CGSize(width: 42, height: 24), cornerRadius: 4)
            logStack.fillColor = SKColor(red: 0.48, green: 0.35, blue: 0.22, alpha: 0.95)
            logStack.strokeColor = SKColor(red: 0.85, green: 0.65, blue: 0.42, alpha: 0.95)
            logStack.lineWidth = 1.6
            woodContainer.addChild(logStack)

            // Kapak kecil penebang
            let axe = SKShapeNode(rectOf: CGSize(width: 3, height: 16), cornerRadius: 1)
            axe.fillColor = SKColor(red: 0.65, green: 0.48, blue: 0.30, alpha: 1.0)
            axe.strokeColor = .clear
            axe.zRotation = -0.4
            axe.position = CGPoint(x: 8, y: 6)
            woodContainer.addChild(axe)

            let badge = createWorldBadge(icon: "🪵", title: "Kayu Bakar Kering", subtitle: "Jalur Pencari Kayu", accentColor: SKColor(red: 0.95, green: 0.75, blue: 0.38, alpha: 1.0))
            badge.position = CGPoint(x: 0, y: 28)
            woodContainer.addChild(badge)

            world.addChild(woodContainer)
            self.firewoodNode = woodContainer

            // 2. Tanah Longsor & Akar Pohon Tua (Buku Elias) di (480, 220)
            if !progress.hasEliasBook {
                let eliasContainer = SKNode()
                eliasContainer.name = "eliasBookLandslide"
                eliasContainer.position = CGPoint(x: 480, y: 220)
                eliasContainer.zPosition = 35

                // Suar emas penemuan
                let goldAura = SKShapeNode(circleOfRadius: 24)
                goldAura.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 0.28)
                goldAura.strokeColor = SKColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.85)
                goldAura.lineWidth = 1.6
                eliasContainer.addChild(goldAura)
                goldAura.run(.repeatForever(.sequence([
                    .scale(to: 1.25, duration: 0.85),
                    .scale(to: 0.95, duration: 0.85)
                ])))

                // Buku Elias bersampul kulit tua
                let bookCover = SKShapeNode(rectOf: CGSize(width: 22, height: 16), cornerRadius: 3)
                bookCover.fillColor = SKColor(red: 0.52, green: 0.26, blue: 0.14, alpha: 1.0)
                bookCover.strokeColor = SKColor(red: 0.98, green: 0.88, blue: 0.55, alpha: 1.0)
                bookCover.lineWidth = 1.4
                eliasContainer.addChild(bookCover)

                // Simbol bintang emas di sampul
                let star = SKLabelNode(text: "✦")
                star.fontSize = 11
                star.fontColor = SKColor(red: 0.98, green: 0.90, blue: 0.45, alpha: 1.0)
                star.verticalAlignmentMode = .center
                eliasContainer.addChild(star)

                let eliasBadge = createWorldBadge(
                    icon: "📖",
                    title: progress.gatheredWood ? "Buku Catatan Elias" : "Celah Akar & Longsor",
                    subtitle: progress.gatheredWood ? "Terselip di Sela Akar" : "Bisa Diperiksa",
                    accentColor: SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
                )
                eliasBadge.position = CGPoint(x: 0, y: 32)
                eliasContainer.addChild(eliasBadge)

                world.addChild(eliasContainer)
                self.eliasBookNode = eliasContainer
            }

            // 3. Exit Sign to Village (45, 210)
            let exitNode = SKNode()
            exitNode.position = CGPoint(x: 45, y: 210)
            exitNode.zPosition = 25
            let exitBadge = createWorldBadge(icon: "🏡", title: "Jalur ke Desa", subtitle: "Wilayah Warga", accentColor: SKColor(red: 0.72, green: 0.85, blue: 0.58, alpha: 1.0))
            exitNode.addChild(exitBadge)
            world.addChild(exitNode)

        case .theBoundary:
            // 1. Lingkaran 12 Batu Kumpul Sahabat di (420, 200)
            let ring = SKShapeNode(circleOfRadius: 48)
            ring.position = CGPoint(x: 420, y: 200)
            ring.strokeColor = SKColor(red: 0.88, green: 0.82, blue: 0.55, alpha: 0.9)
            ring.fillColor = SKColor(white: 1, alpha: 0.05)
            ring.lineWidth = 2.0
            world.addChild(ring)

            let councilBadge = createWorldBadge(icon: "⚔️", title: "Titik Kumpul Ekspedisi", subtitle: "Arthur & 3 Sahabat", accentColor: SKColor(red: 0.95, green: 0.88, blue: 0.55, alpha: 1.0))
            councilBadge.position = CGPoint(x: 420, y: 140)
            world.addChild(councilBadge)

            // Sahabat berdiri di titik kumpul
            if companions.isEmpty {
                for (idx, friend) in FriendID.allCases.enumerated() {
                    let actor = MemoryCharacter(title: friend.rawValue, color: color(friend))
                    let angle = CGFloat(idx) * .pi * 2 / 3
                    actor.position = CGPoint(x: 420 + cos(angle) * 30, y: 200 + sin(angle) * 20)
                    actor.zPosition = 25
                    world.addChild(actor)
                    companions.append(actor)
                }
            }

            // 2. Pohon Penanda Batas di (335, 225)
            let treeAnchor = SKNode()
            treeAnchor.name = "boundaryTree"
            treeAnchor.position = CGPoint(x: 335, y: 225)
            treeAnchor.zPosition = 35

            let treeAura = SKShapeNode(circleOfRadius: 26)
            treeAura.fillColor = SKColor(red: 0.96, green: 0.45, blue: 0.20, alpha: 0.25)
            treeAura.strokeColor = SKColor(red: 1.0, green: 0.65, blue: 0.25, alpha: 0.85)
            treeAura.lineWidth = 1.6
            treeAnchor.addChild(treeAura)
            treeAura.run(.repeatForever(.sequence([
                .scale(to: 1.25, duration: 0.95),
                .scale(to: 0.95, duration: 0.95)
            ])))

            // Pita sutra jingga terang berkibar
            let ribbonFlag = SKShapeNode(rectOf: CGSize(width: 16, height: 9), cornerRadius: 2)
            ribbonFlag.fillColor = SKColor(red: 0.98, green: 0.35, blue: 0.15, alpha: 1.0)
            ribbonFlag.strokeColor = .white
            ribbonFlag.lineWidth = 1.0
            ribbonFlag.position = CGPoint(x: 14, y: 14)
            treeAnchor.addChild(ribbonFlag)
            ribbonFlag.run(.repeatForever(.sequence([
                .scaleX(to: 0.65, duration: 0.35),
                .scaleX(to: 1.0, duration: 0.35)
            ])))

            let treeBadge = createWorldBadge(icon: "🎗️", title: "Pohon Batas", subtitle: "Torehan 'X' & Pita Terang", accentColor: SKColor(red: 0.98, green: 0.45, blue: 0.22, alpha: 1.0))
            treeBadge.position = CGPoint(x: 0, y: 36)
            treeAnchor.addChild(treeBadge)

            world.addChild(treeAnchor)
            self.boundaryTreeNode = treeAnchor

            // 3. Gerbang Kabut ke Deep Woods di (920, 240)
            let gateContainer = SKNode()
            gateContainer.name = "deepWoodsGate"
            gateContainer.position = CGPoint(x: 920, y: 240)
            gateContainer.zPosition = 35

            let gateArch = SKShapeNode(rectOf: CGSize(width: 76, height: 105), cornerRadius: 14)
            gateArch.fillColor = SKColor(red: 0.08, green: 0.18, blue: 0.12, alpha: 0.5)
            gateArch.strokeColor = SKColor(red: 0.65, green: 0.95, blue: 0.70, alpha: 0.95)
            gateArch.lineWidth = 2.8
            gateContainer.addChild(gateArch)
            gateArch.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.4, duration: 1.3),
                .fadeAlpha(to: 1.0, duration: 1.3)
            ])))

            let gateBadge = createWorldBadge(icon: "🌲", title: "Gerbang Deep Woods", subtitle: "Menuju Map C (Hutan Luar)", accentColor: SKColor(red: 0.50, green: 0.95, blue: 0.65, alpha: 1.0))
            gateBadge.position = CGPoint(x: 0, y: 70)
            gateContainer.addChild(gateBadge)

            world.addChild(gateContainer)
            self.deepWoodsGateNode = gateContainer
        }
    }

    func color(_ friend: FriendID) -> SKColor {
        switch friend {
        case .keneth: return SKColor(red: 0.73, green: 0.39, blue: 0.24, alpha: 1)
        case .roland: return SKColor(red: 0.87, green: 0.65, blue: 0.28, alpha: 1)
        case .anneth: return SKColor(red: 0.36, green: 0.55, blue: 0.72, alpha: 1)
        }
    }

    func addBook(at point: CGPoint) {
        let bookContainer = SKNode()
        bookContainer.name = "bookPickup"
        bookContainer.position = point
        bookContainer.zPosition = 35

        // 1. Bayangan lembut di bawah buku
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 34, height: 13))
        shadow.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.10, alpha: 0.38)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -6)
        bookContainer.addChild(shadow)

        // 2. Halo cahaya emas lembut berdenyut (pulsing golden aura)
        let aura = SKShapeNode(circleOfRadius: 26)
        aura.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 0.22)
        aura.strokeColor = SKColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.45)
        aura.lineWidth = 1.2
        aura.position = CGPoint(x: 0, y: 6)
        bookContainer.addChild(aura)
        aura.run(.repeatForever(.sequence([
            .group([.scale(to: 1.22, duration: 1.1), .fadeAlpha(to: 0.15, duration: 1.1)]),
            .group([.scale(to: 0.95, duration: 1.1), .fadeAlpha(to: 0.40, duration: 1.1)])
        ])))

        // 3. Badan buku kuno (Ancient Leather Tome Carto)
        let bookBody = SKNode()
        bookBody.position = CGPoint(x: 0, y: 6)
        bookContainer.addChild(bookBody)

        // Sampul kulit merah marun tebal
        let cover = SKShapeNode(rectOf: CGSize(width: 32, height: 24), cornerRadius: 4)
        cover.fillColor = SKColor(red: 0.54, green: 0.18, blue: 0.14, alpha: 1.0)
        cover.strokeColor = SKColor(red: 0.32, green: 0.10, blue: 0.08, alpha: 1.0)
        cover.lineWidth = 1.5
        bookBody.addChild(cover)

        // Tumpukan kertas kuno di tepi buku
        let pages = SKShapeNode(rectOf: CGSize(width: 5, height: 20), cornerRadius: 1.5)
        pages.fillColor = SKColor(red: 0.96, green: 0.92, blue: 0.80, alpha: 1.0)
        pages.strokeColor = .clear
        pages.position = CGPoint(x: 12, y: 0)
        bookBody.addChild(pages)

        // Lambang kompas emas di sampul
        let emblem = SKShapeNode(circleOfRadius: 5)
        emblem.fillColor = SKColor(red: 0.96, green: 0.84, blue: 0.42, alpha: 1.0)
        emblem.strokeColor = SKColor(red: 0.76, green: 0.58, blue: 0.22, alpha: 1.0)
        emblem.lineWidth = 1.0
        bookBody.addChild(emblem)

        // Sudut ornamen kuningan di 4 pojok buku
        for (cx, cy) in [(-12.0, 8.0), (-12.0, -8.0), (9.0, 8.0), (9.0, -8.0)] {
            let corner = SKShapeNode(rectOf: CGSize(width: 3.5, height: 3.5), cornerRadius: 0.8)
            corner.fillColor = SKColor(red: 0.94, green: 0.80, blue: 0.38, alpha: 1.0)
            corner.strokeColor = .clear
            corner.position = CGPoint(x: cx, y: cy)
            bookBody.addChild(corner)
        }

        // Pita pembatas merah menjuntai
        let ribbon = SKShapeNode(rectOf: CGSize(width: 3, height: 8), cornerRadius: 1)
        ribbon.fillColor = SKColor(red: 0.85, green: 0.22, blue: 0.22, alpha: 1.0)
        ribbon.strokeColor = .clear
        ribbon.position = CGPoint(x: 0, y: -14)
        bookBody.addChild(ribbon)

        // 4. Animasi melayang naik-turun lembut (floating bobbing)
        bookBody.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 4.5, duration: 1.2),
            .moveBy(x: 0, y: -4.5, duration: 1.2)
        ])))

        // 5. Partikel kilau bintang kecil melayang
        for i in 0..<3 {
            let spark = SKLabelNode(text: "✨")
            spark.fontSize = 11
            spark.alpha = 0
            spark.position = CGPoint(x: (i == 0 ? -16 : (i == 1 ? 16 : 0)), y: (i == 2 ? 18 : 6))
            bookContainer.addChild(spark)
            spark.run(.repeatForever(.sequence([
                .wait(forDuration: Double(i) * 0.45),
                .group([.fadeIn(withDuration: 0.5), .moveBy(x: 0, y: 8, duration: 0.8), .scale(to: 1.2, duration: 0.8)]),
                .fadeOut(withDuration: 0.4),
                .moveBy(x: 0, y: -8, duration: 0),
                .scale(to: 0.8, duration: 0),
                .wait(forDuration: 1.0)
            ])))
        }

        // 6. Label mengambang bergaya storybook
        let labelBg = SKShapeNode(rectOf: CGSize(width: 96, height: 20), cornerRadius: 10)
        labelBg.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.88)
        labelBg.strokeColor = SKColor(red: 0.92, green: 0.82, blue: 0.52, alpha: 0.6)
        labelBg.lineWidth = 1.0
        labelBg.position = CGPoint(x: 0, y: 32)
        bookContainer.addChild(labelBg)

        let label = SKLabelNode(text: "📖 Buku Tua")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 10
        label.fontColor = SKColor(red: 0.98, green: 0.94, blue: 0.82, alpha: 1.0)
        label.verticalAlignmentMode = .center
        labelBg.addChild(label)

        world.addChild(bookContainer)
        bookPickupNode = bookContainer
    }

    func showAnnouncementBanner(icon: String, title: String, subtitle: String) {
        let banner = SKNode()
        banner.zPosition = 500
        banner.position = CGPoint(x: size.width / 2, y: size.height - 76)

        let bannerWidth = min(size.width - 40, 520)
        let bg = SKShapeNode(rectOf: CGSize(width: bannerWidth, height: 50), cornerRadius: 25)
        bg.fillColor = SKColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 0.96)
        bg.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 0.90)
        bg.lineWidth = 1.6
        banner.addChild(bg)

        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = 22
        iconLabel.position = CGPoint(x: -bannerWidth / 2 + 28, y: -8)
        banner.addChild(iconLabel)

        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 13.5
        titleLabel.fontColor = SKColor(red: 0.98, green: 0.92, blue: 0.65, alpha: 1.0)
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: -bannerWidth / 2 + 54, y: 4)
        banner.addChild(titleLabel)

        let subLabel = SKLabelNode(text: subtitle)
        subLabel.fontName = "AvenirNext-Medium"
        subLabel.fontSize = 10.5
        subLabel.fontColor = SKColor(red: 0.92, green: 0.92, blue: 0.88, alpha: 0.85)
        subLabel.horizontalAlignmentMode = .left
        subLabel.position = CGPoint(x: -bannerWidth / 2 + 54, y: -14)
        banner.addChild(subLabel)

        banner.setScale(0.7)
        banner.alpha = 0
        hud.addChild(banner)

        let popIn = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.35),
            SKAction.fadeIn(withDuration: 0.25)
        ])
        popIn.timingMode = .easeOut

        banner.run(SKAction.sequence([
            popIn,
            SKAction.wait(forDuration: 4.2),
            SKAction.group([
                SKAction.scale(to: 0.85, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func showUnlockCard(title: String, body: String) {
        dismissUnlockCard()

        let card = SKNode()
        card.name = "unlockCard"
        card.zPosition = 600
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)

        let cardWidth = min(size.width - 50, 480)
        let cardHeight: CGFloat = 195

        // Latar redup di belakang kartu
        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor(white: 0, alpha: 0.58)
        dim.strokeColor = .clear
        dim.name = "unlockCard"
        card.addChild(dim)

        // Kartu kertas gaya buku cerita Carto
        let bg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        bg.fillColor = SKColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.98)
        bg.strokeColor = SKColor(red: 0.96, green: 0.84, blue: 0.45, alpha: 1.0)
        bg.lineWidth = 2.2
        bg.name = "unlockCard"
        card.addChild(bg)

        // Garis dekoratif dalam
        let inner = SKShapeNode(rectOf: CGSize(width: cardWidth - 14, height: cardHeight - 14), cornerRadius: 14)
        inner.fillColor = .clear
        inner.strokeColor = SKColor(red: 0.72, green: 0.60, blue: 0.35, alpha: 0.45)
        inner.lineWidth = 1.0
        inner.name = "unlockCard"
        card.addChild(inner)

        // Judul besar berwarna emas
        let titleLabel = SKLabelNode(text: title)
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 17
        titleLabel.fontColor = SKColor(red: 0.98, green: 0.88, blue: 0.48, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: cardHeight / 2 - 38)
        titleLabel.name = "unlockCard"
        card.addChild(titleLabel)

        // Teks penjelasan cerita multiline
        let bodyLabel = card.storyLabel(body, at: CGPoint(x: 0, y: cardHeight / 2 - 72), size: 12.5, color: SKColor(red: 0.95, green: 0.95, blue: 0.90, alpha: 0.95), width: cardWidth - 48)
        bodyLabel.name = "unlockCard"

        // Tombol Lanjutkan di bagian bawah kartu
        let okBtn = card.storyButton("Lanjutkan Petualangan", name: "unlockCardDismiss", at: CGPoint(x: 0, y: -cardHeight / 2 + 32), width: 220)
        okBtn.fillColor = SKColor(red: 0.28, green: 0.22, blue: 0.12, alpha: 1.0)
        okBtn.strokeColor = SKColor(red: 0.96, green: 0.84, blue: 0.45, alpha: 1.0)
        okBtn.lineWidth = 1.8

        card.setScale(0.75)
        card.alpha = 0
        hud.addChild(card)

        let popIn = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.32),
            SKAction.fadeIn(withDuration: 0.22)
        ])
        popIn.timingMode = .easeOut
        card.run(popIn)
    }

    func dismissUnlockCard() {
        guard let card = hud.childNode(withName: "unlockCard") else { return }
        card.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.8, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func spawnCelebrationSparks(at p: CGPoint) {
        let symbols = ["✨", "⭐", "🎉", "🌟"]
        for i in 0..<8 {
            let spark = SKLabelNode(text: symbols[i % symbols.count])
            spark.fontSize = 15
            spark.position = p
            spark.zPosition = 80
            world.addChild(spark)
            let angle = CGFloat(i) * (.pi / 4.0)
            let dist: CGFloat = 28 + CGFloat(i * 3)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.65),
                    SKAction.scale(to: 1.4, duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.65)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    func buildHUD() {
        hud.removeAllChildren()

        if entry.region == .boundary {
            let stage = progress.mapBStage
            let stageColor: SKColor
            let stageIndex: Int

            switch stage {
            case .rockSalt:
                stageColor = SKColor(red: 0.45, green: 0.88, blue: 0.98, alpha: 1.0)
                stageIndex = 1
            case .herbalHills:
                stageColor = SKColor(red: 0.55, green: 0.92, blue: 0.45, alpha: 1.0)
                stageIndex = 2
            case .woodcutterSlope:
                stageColor = SKColor(red: 0.95, green: 0.75, blue: 0.38, alpha: 1.0)
                stageIndex = 3
            case .theBoundary:
                stageColor = SKColor(red: 0.98, green: 0.45, blue: 0.25, alpha: 1.0)
                stageIndex = 4
            }

            // Container header terpadu Map B
            let headerW = min(size.width - 240, 560)
            let headerH: CGFloat = 58
            let headerNode = SKNode()
            headerNode.position = CGPoint(x: size.width / 2, y: size.height - headerH / 2 - 8)
            hud.addChild(headerNode)

            // 1. Latar kaca gelap Carto dengan lis emas
            let headerBg = SKShapeNode(rectOf: CGSize(width: headerW, height: headerH), cornerRadius: 16)
            headerBg.fillColor = SKColor(red: 0.08, green: 0.11, blue: 0.13, alpha: 0.95)
            headerBg.strokeColor = SKColor(red: 0.88, green: 0.78, blue: 0.45, alpha: 0.80)
            headerBg.lineWidth = 1.6
            headerNode.addChild(headerBg)

            // Inner subtle border
            let innerBorder = SKShapeNode(rectOf: CGSize(width: headerW - 6, height: headerH - 6), cornerRadius: 13)
            innerBorder.fillColor = .clear
            innerBorder.strokeColor = stageColor.withAlphaComponent(0.35)
            innerBorder.lineWidth = 1.0
            headerNode.addChild(innerBorder)

            // 2. Baris Atas: Stepper 4 Tahap Terhubung
            let stepperIcons = ["🧂", "🌿", "🪵", "🎗️"]
            let stepperNames = ["Rock Salt", "Herbal", "Kayu", "Boundary"]
            let stepSpacing: CGFloat = min((headerW - 90) / 3.0, 105)
            let stepperStartX: CGFloat = -CGFloat(stepperIcons.count - 1) * stepSpacing / 2

            // Garis rel penghubung antar tahap
            let lineTrack = SKShapeNode(rectOf: CGSize(width: CGFloat(stepperIcons.count - 1) * stepSpacing, height: 2), cornerRadius: 1)
            lineTrack.fillColor = SKColor(white: 1.0, alpha: 0.22)
            lineTrack.strokeColor = .clear
            lineTrack.position = CGPoint(x: 0, y: 12)
            headerNode.addChild(lineTrack)

            for i in 0..<stepperIcons.count {
                let sx = stepperStartX + CGFloat(i) * stepSpacing
                let stepNumber = i + 1
                let isCompleted = stepNumber < stageIndex
                let isCurrent = stepNumber == stageIndex

                let pipW: CGFloat = isCurrent ? 68 : 22
                let pipH: CGFloat = 20
                let pip = SKShapeNode(rectOf: CGSize(width: pipW, height: pipH), cornerRadius: 10)
                pip.position = CGPoint(x: sx, y: 12)
                pip.lineWidth = 1.4

                if isCurrent {
                    pip.fillColor = stageColor.withAlphaComponent(0.35)
                    pip.strokeColor = stageColor

                    // Pulsing glow aura di tahap aktif
                    let aura = SKShapeNode(rectOf: CGSize(width: pipW + 8, height: pipH + 8), cornerRadius: 14)
                    aura.fillColor = .clear
                    aura.strokeColor = stageColor.withAlphaComponent(0.65)
                    aura.lineWidth = 1.2
                    pip.addChild(aura)
                    aura.run(.repeatForever(.sequence([
                        .scale(to: 1.15, duration: 0.8),
                        .scale(to: 0.95, duration: 0.8)
                    ])))

                    let pipLbl = SKLabelNode(text: "\(stepperIcons[i]) \(stepperNames[i])")
                    pipLbl.fontName = "AvenirNext-Bold"
                    pipLbl.fontSize = 9.5
                    pipLbl.fontColor = SKColor(red: 0.98, green: 0.98, blue: 0.96, alpha: 1.0)
                    pipLbl.verticalAlignmentMode = .center
                    pip.addChild(pipLbl)
                } else if isCompleted {
                    pip.fillColor = SKColor(red: 0.25, green: 0.72, blue: 0.35, alpha: 0.45)
                    pip.strokeColor = SKColor(red: 0.45, green: 0.88, blue: 0.52, alpha: 0.95)

                    let pipLbl = SKLabelNode(text: "✓")
                    pipLbl.fontName = "AvenirNext-Bold"
                    pipLbl.fontSize = 11
                    pipLbl.fontColor = SKColor(red: 0.55, green: 0.95, blue: 0.60, alpha: 1.0)
                    pipLbl.verticalAlignmentMode = .center
                    pip.addChild(pipLbl)
                } else {
                    pip.fillColor = SKColor(white: 0.15, alpha: 0.75)
                    pip.strokeColor = SKColor(white: 0.45, alpha: 0.55)

                    let pipLbl = SKLabelNode(text: stepperIcons[i])
                    pipLbl.fontSize = 10
                    pipLbl.verticalAlignmentMode = .center
                    pipLbl.alpha = 0.6
                    pip.addChild(pipLbl)
                }
                headerNode.addChild(pip)
            }

            // 3. Baris Bawah: Misi Aktif dalam Kapsul Emas
            let objPillW = headerW - 28
            let objPill = SKShapeNode(rectOf: CGSize(width: objPillW, height: 22), cornerRadius: 11)
            objPill.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.15, alpha: 0.92)
            objPill.strokeColor = SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 0.55)
            objPill.lineWidth = 1.0
            objPill.position = CGPoint(x: 0, y: -14)
            headerNode.addChild(objPill)

            let questText = "📜 " + progress.currentObjective(for: entry.region)
            objective = headerNode.storyLabel(questText, at: CGPoint(x: 0, y: -14), size: 11, width: objPillW - 20)
            objective.fontColor = SKColor(red: 0.98, green: 0.94, blue: 0.82, alpha: 1.0)

            // Status keamanan zona di bawah header
            suspicionLabel = hud.storyLabel("🛡️ Status: Aman (Zona Transisi Desa)", at: CGPoint(x: size.width / 2, y: size.height - headerH - 18), size: 10, color: SKColor(red: 0.65, green: 0.88, blue: 0.65, alpha: 0.9))
        } else {
            // Standard single-pill HUD
            let objWidth = min(size.width * 0.52, 460)
            let objBg = SKShapeNode(rectOf: CGSize(width: objWidth, height: 36), cornerRadius: 18)
            objBg.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.88)
            objBg.strokeColor = SKColor(red: 0.88, green: 0.80, blue: 0.55, alpha: 0.45)
            objBg.lineWidth = 1.2
            objBg.position = CGPoint(x: size.width / 2, y: size.height - 34)
            hud.addChild(objBg)

            objective = hud.storyLabel(progress.currentObjective(for: entry.region), at: CGPoint(x: size.width / 2, y: size.height - 34), size: 13, width: objWidth - 28)
            objective.fontColor = SKColor(red: 0.98, green: 0.94, blue: 0.82, alpha: 1)

            suspicionLabel = hud.storyLabel("Aman", at: CGPoint(x: size.width / 2, y: size.height - 58), size: 11, color: .lightGray)
        }

        // 6. Petunjuk kontrol halus di bagian bawah
        let hint = hud.storyLabel("Berlindung di balik benda • Bidang kuning = pandangan warga",
                                  at: CGPoint(x: size.width / 2, y: 18), size: 11, color: SKColor(white: 1, alpha: 0.5))
        hint.zPosition = 10

        // 7. Tombol Interaksi Aksi Cepat HUD bergaya Carto di kanan bawah
        let interactBtn = SKShapeNode(rectOf: CGSize(width: 176, height: 46), cornerRadius: 23)
        interactBtn.name = "hudInteract"
        interactBtn.position = CGPoint(x: size.width - 110, y: 115)
        interactBtn.fillColor = SKColor(red: 0.16, green: 0.22, blue: 0.17, alpha: 0.96)
        interactBtn.strokeColor = SKColor(red: 0.98, green: 0.84, blue: 0.42, alpha: 1.0)
        interactBtn.lineWidth = 2.0
        interactBtn.zPosition = 50
        interactBtn.alpha = 0
        interactBtn.isHidden = true
        hud.addChild(interactBtn)

        let interactLbl = SKLabelNode(text: "Interaksi")
        interactLbl.name = "hudInteract"
        interactLbl.fontName = "AvenirNext-Bold"
        interactLbl.fontSize = 13
        interactLbl.fontColor = SKColor(red: 0.98, green: 0.92, blue: 0.70, alpha: 1.0)
        interactLbl.verticalAlignmentMode = .center
        interactBtn.addChild(interactLbl)

        hudInteractButton = interactBtn
        hudInteractLabel = interactLbl

        // Tombol Debug di pojok kanan atas
        addDebugButton()

        updateBookAccess()
    }

    func showHUDInteractButton(for target: MemoryInteractionTarget) {
        guard let btn = hudInteractButton, let lbl = hudInteractLabel else { return }
        let text: String
        switch target {
        case .book:
            text = "📖 Ambil Buku"
        case .friend(let friend):
            if progress.joined.contains(friend) {
                text = "💬 Bicara"
            } else {
                text = "✨ Ajak \(friend.rawValue)"
            }
        case .marker:
            text = "🧭 Penanda"
        case .sitStump:
            text = "🪑 Duduk"
        case .standUp:
            text = "🚶 Berdiri"
        case .sleepBed:
            text = "🛏️ Tidur"
        case .wakeUp:
            text = "☀️ Bangun"
        case .rockSalt:
            text = "💎 Ambil Rock Salt"
        case .darkMineEntrance:
            text = "⛔ Periksa Lorong Gua"
        case .herbalPlant:
            text = "🌿 Petik Daun Herbal"
        case .boundaryStone:
            text = "🗿 Batu Pembatas"
        case .hollowEncounter:
            text = "👁️ Selidiki Bayangan"
        case .firewood:
            text = "🪵 Kumpulkan Kayu"
        case .landslideEliasBook:
            text = "📖 Investigasi Longsor"
        case .boundaryTreeMarker:
            text = "🎗️ Beri Tanda Pohon"
        case .deepWoodsGate:
            text = "🌲 Masuki Deep Woods"
        }
        let accentColor: SKColor
        switch target {
        case .rockSalt: accentColor = SKColor(red: 0.45, green: 0.88, blue: 0.98, alpha: 1.0)
        case .darkMineEntrance: accentColor = SKColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0)
        case .herbalPlant: accentColor = SKColor(red: 0.98, green: 0.88, blue: 0.25, alpha: 1.0)
        case .boundaryStone: accentColor = SKColor(red: 0.65, green: 0.85, blue: 0.65, alpha: 1.0)
        case .hollowEncounter: accentColor = SKColor(red: 0.78, green: 0.45, blue: 0.95, alpha: 1.0)
        case .firewood: accentColor = SKColor(red: 0.95, green: 0.75, blue: 0.38, alpha: 1.0)
        case .landslideEliasBook: accentColor = SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
        case .boundaryTreeMarker: accentColor = SKColor(red: 0.98, green: 0.45, blue: 0.22, alpha: 1.0)
        case .deepWoodsGate: accentColor = SKColor(red: 0.50, green: 0.95, blue: 0.65, alpha: 1.0)
        default: accentColor = SKColor(red: 0.98, green: 0.84, blue: 0.42, alpha: 1.0)
        }
        btn.strokeColor = accentColor
        lbl.text = text
        if btn.isHidden || btn.alpha < 0.1 {
            btn.isHidden = false
            btn.removeAllActions()
            btn.setScale(0.85)
            btn.run(.group([
                .scale(to: 1.0, duration: 0.25),
                .fadeIn(withDuration: 0.20)
            ]))
        }
    }

    func hideHUDInteractButton() {
        guard let btn = hudInteractButton, !btn.isHidden else { return }
        btn.removeAllActions()
        btn.run(.sequence([
            .group([.scale(to: 0.85, duration: 0.16), .fadeOut(withDuration: 0.16)]),
            .run { btn.isHidden = true }
        ]))
    }

    func updateBookAccess() {
        if progress.hasBook {
            bookPickupNode?.removeFromParent()
            bookPickupNode = nil
            if nearbyInteraction == .book { clearNearbyInteraction() }
        }
    }

    func say(_ text: String, duration: TimeInterval = 4) {
        toast?.removeFromParent()
        let toastWidth = min(size.width - 60, 620)
        let label = hud.storyLabel(text, at: CGPoint(x: size.width / 2, y: size.height - 82), size: 14, width: toastWidth - 32)
        label.zPosition = 110
        let background = SKShapeNode(rectOf: CGSize(width: toastWidth, height: 42), cornerRadius: 10)
        background.fillColor = SKColor(white: 0.08, alpha: 0.92)
        background.strokeColor = SKColor(white: 1, alpha: 0.18)
        background.zPosition = -1
        label.addChild(background)
        toast = label
        label.run(.sequence([.wait(forDuration: duration), .fadeOut(withDuration: 0.4), .removeFromParent()]))
    }

    func resolveSpeakerPosition(named speaker: String) -> CGPoint {
        if speaker == "Arthur" {
            return arthur.position
        }
        if speaker == "Buku lama" {
            return level.book ?? arthur.position
        }
        if speaker == "Penanda" {
            return level.marker ?? arthur.position
        }
        // Cek teman yang sudah mengikuti Arthur sebagai companion
        if let companion = companions.first(where: { $0.title == speaker }) {
            return companion.position
        }
        // Cek teman yang masih berdiri di titik level
        for friend in FriendID.allCases where friend.rawValue == speaker {
            if let point = level.friends[friend] {
                return point
            }
        }
        return arthur.position
    }

    func showDialoguePage() {
        dialoguePanel?.removeFromParent()
        let line = dialogue[dialogueIndex]

        // 1. Dapatkan posisi pembicara dalam koordinat layar saat ini (mengikuti pergerakan kamera dunia)
        let speakerWorldPos = resolveSpeakerPosition(named: line.speaker)
        let screenPos = world.convert(speakerWorldPos, to: self)

        // 2. Tentukan posisi Speech Bubble (clamped di dalam batas layar)
        let bubbleX = min(max(screenPos.x, 220), size.width - 220)
        var bubbleY = screenPos.y + 115
        var tailOffsetY: CGFloat = -58

        if bubbleY > size.height - 90 {
            bubbleY = max(screenPos.y - 115, 90)
            tailOffsetY = 58
        }

        let tailOffsetX = min(max(screenPos.x - bubbleX, -130), 130)
        let tailTip = CGPoint(x: tailOffsetX, y: tailOffsetY)

        // 3. Konfigurasi SpeechBubbleNode bergaya krayon lilin hitam Carto
        let config = SpeechBubbleConfig(
            text: line.text,
            speaker: line.speaker,
            pageIndicator: "Ketuk untuk lanjut  ·  \(dialogueIndex + 1)/\(dialogue.count)",
            fontSize: 17,
            padding: CGSize(width: 30, height: 18),
            maxWidth: min(420, size.width - 60)
        )

        let bubble = SpeechBubbleNode(config: config, tailTipOffset: tailTip)
        bubble.position = CGPoint(x: bubbleX, y: bubbleY)
        bubble.zPosition = 350
        hud.addChild(bubble)
        dialoguePanel = bubble
        bubble.popIn()
    }

    func makeInteractionPrompt(for target: MemoryInteractionTarget) -> SKNode {
        let root = SKNode()
        root.name = "contextInteract"
        root.zPosition = 90

        let accentColor: SKColor
        switch target {
        case .rockSalt: accentColor = SKColor(red: 0.45, green: 0.88, blue: 0.98, alpha: 1.0)
        case .darkMineEntrance: accentColor = SKColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0)
        case .herbalPlant: accentColor = SKColor(red: 0.98, green: 0.88, blue: 0.25, alpha: 1.0)
        case .boundaryStone: accentColor = SKColor(red: 0.65, green: 0.85, blue: 0.65, alpha: 1.0)
        case .hollowEncounter: accentColor = SKColor(red: 0.78, green: 0.45, blue: 0.95, alpha: 1.0)
        case .firewood: accentColor = SKColor(red: 0.95, green: 0.75, blue: 0.38, alpha: 1.0)
        case .landslideEliasBook: accentColor = SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
        case .boundaryTreeMarker: accentColor = SKColor(red: 0.98, green: 0.45, blue: 0.22, alpha: 1.0)
        case .deepWoodsGate: accentColor = SKColor(red: 0.50, green: 0.95, blue: 0.65, alpha: 1.0)
        default: accentColor = SKColor(red: 1.0, green: 0.85, blue: 0.42, alpha: 1.0)
        }

        // 1. Area sentuh toleran tak terlihat (radius 65pt) untuk menangkap ketukan di sekitar target
        let hitArea = SKShapeNode(circleOfRadius: 65)
        hitArea.name = "contextInteract"
        hitArea.fillColor = SKColor(white: 1.0, alpha: 0.001)
        hitArea.strokeColor = .clear
        hitArea.zPosition = -1
        root.addChild(hitArea)

        // 2. Lingkaran sorot interaksi berdenyut di tanah (pulsing ground indicator)
        let groundRadius: CGFloat = target == .book ? 26 : 32
        let groundRing = SKShapeNode(circleOfRadius: groundRadius)
        groundRing.name = "contextInteract"
        groundRing.strokeColor = accentColor
        groundRing.fillColor = accentColor.withAlphaComponent(0.20)
        groundRing.lineWidth = 2.4
        groundRing.position = CGPoint(x: 0, y: -4)
        root.addChild(groundRing)
        groundRing.run(.repeatForever(.sequence([
            .group([.scale(to: 1.18, duration: 0.6), .fadeAlpha(to: 0.45, duration: 0.6)]),
            .group([.scale(to: 0.96, duration: 0.6), .fadeAlpha(to: 1.0, duration: 0.6)])
        ])))

        // Cincin aura halus
        let outerAura = SKShapeNode(circleOfRadius: groundRadius + 8)
        outerAura.name = "contextInteract"
        outerAura.strokeColor = accentColor.withAlphaComponent(0.40)
        outerAura.fillColor = .clear
        outerAura.lineWidth = 1.0
        outerAura.position = CGPoint(x: 0, y: -4)
        root.addChild(outerAura)

        // 3. Tombol aksi mengambang Carto dengan bubble speech pointer
        let title: String
        let width: CGFloat
        switch target {
        case .book:
            title = "📖 Ambil Buku"
            width = 126
        case .friend(let friend):
            if progress.joined.contains(friend) {
                title = "💬 \(friend.rawValue)"
                width = 126
            } else {
                title = "✨ Ajak \(friend.rawValue)"
                width = 138
            }
        case .marker:
            title = "🧭 Penanda"
            width = 126
        case .sitStump:
            title = "🪑 Duduk"
            width = 110
        case .standUp:
            title = "🚶 Berdiri"
            width = 110
        case .sleepBed:
            title = "🛏️ Tidur"
            width = 110
        case .wakeUp:
            title = "☀️ Bangun"
            width = 110
        case .rockSalt:
            title = "💎 Ambil Rock Salt"
            width = 148
        case .darkMineEntrance:
            title = "⛔ Periksa Gua"
            width = 132
        case .herbalPlant:
            title = "🌿 Petik Herbal"
            width = 132
        case .boundaryStone:
            title = "🗿 Batu Batas"
            width = 120
        case .hollowEncounter:
            title = "👁️ Sosok Bayangan"
            width = 148
        case .firewood:
            title = "🪵 Ambil Kayu"
            width = 126
        case .landslideEliasBook:
            title = "📖 Celah Akar"
            width = 126
        case .boundaryTreeMarker:
            title = "🎗️ Tandai Pohon"
            width = 136
        case .deepWoodsGate:
            title = "🌲 Ke Deep Woods"
            width = 144
        }

        let bubbleY: CGFloat = target == .book ? 50 : 62
        let button = root.storyButton(title, name: "contextInteract", at: CGPoint(x: 0, y: bubbleY), width: width)
        button.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.96)
        button.strokeColor = accentColor
        button.lineWidth = 2.0

        let pointer = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -6, y: bubbleY - 14))
            path.addLine(to: CGPoint(x: 6, y: bubbleY - 14))
            path.addLine(to: CGPoint(x: 0, y: bubbleY - 22))
            path.closeSubpath()
            return path
        }())
        pointer.name = "contextInteract"
        pointer.fillColor = button.fillColor
        pointer.strokeColor = accentColor
        root.addChild(pointer)

        // Animasi melayang naik-turun lembut (bobbing)
        button.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3.5, duration: 0.75),
            .moveBy(x: 0, y: -3.5, duration: 0.75)
        ])))
        pointer.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3.5, duration: 0.75),
            .moveBy(x: 0, y: -3.5, duration: 0.75)
        ])))

        return root
    }

    func clearNearbyInteraction() {
        nearbyPrompt?.removeFromParent()
        nearbyPrompt = nil
        nearbyInteraction = nil
        hideHUDInteractButton()
    }
    func animateBookPickup(_ book: SKNode) {
    // Arthur berbalik menghadap buku
    let dx = book.position.x - arthur.position.x
    arthur.visualRoot.xScale = dx >= 0 ? 1.0 : -1.0

    let liftPos = CGPoint(x: arthur.position.x + (dx >= 0 ? 16 : -16), y: arthur.position.y + 22)

    // Animasi dramatis pengambilan buku: melayang ke Arthur, berputar, memancarkan bintang
    book.removeAllActions()
    book.run(.sequence([
        .group([
            .move(to: liftPos, duration: 0.40),
            .scale(to: 1.35, duration: 0.40),
            .rotate(byAngle: 0.15, duration: 0.40)
        ]),
        .wait(forDuration: 0.15),
        .group([
            .move(to: CGPoint(x: arthur.position.x, y: arthur.position.y + 12), duration: 0.25),
            .scale(to: 0.2, duration: 0.25),
            .fadeOut(withDuration: 0.25)
        ]),
        .removeFromParent()
    ]))

    spawnCelebrationSparks(at: liftPos)
    showAnnouncementBanner(icon: "📖", title: "BUKU PETA TUA DITEMUKAN!", subtitle: "Sebuah catatan tua berisikan sketsa rute di luar lembah...")
    }

}
