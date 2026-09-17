// Penjelasan file: ExplorationScene.swift
// Mengendalikan permainan di dalam kenangan: membangun dunia, HUD, karakter, dan patroli.
// Menangani stik, ketuk untuk berjalan, dialog, interaksi misi, teman pengikut, dan kembali ke foto.
// Memakai PrologueLevel untuk peta, MemoryNavigation untuk gerak, serta PrologueStore untuk progres.

import SpriteKit
import UIKit

final class ExplorationScene: SKScene {
    private var enteringMemory = true
    private let entry: MemoryPiece
    private let worldLocations: Set<MemoryPiece>
    private var progress: PrologueProgress { PrologueStore.shared.progress }
    private var level: PrologueLevel!
    private var navigation: MemoryNavigation!
    private let stage = SKNode()
    private let world = SKNode()
    private let hud = SKNode()
    private let arthur = MemoryCharacter(title: "Arthur", color: SKColor(red: 0.49, green: 0.59, blue: 0.35, alpha: 1))
    private var companions: [MemoryCharacter] = []
    private var patrols: [MemoryPatrol] = []
    private var checkpoint = CGPoint.zero
    private var lastTime: TimeInterval = 0
    private var followerTimer: CGFloat = 0
    private var warningCooldown: CGFloat = 0
    private var catchGrace: CGFloat = 0
    private var watched = false
    private var dialogue: [StoryLine] = []
    private var dialogueIndex = 0
    private var dialogueCompletion: (() -> Void)?
    private var dialoguePanel: SKNode?
    private var toast: SKLabelNode?
    private var stickTouch: UITouch?
    private var stickVector = CGVector.zero
    private var stickCenter: CGPoint { CGPoint(x: 88, y: 88) }
    private var stickKnob = SKShapeNode(circleOfRadius: 18)
    private var objective = SKLabelNode()
    private var suspicionLabel = SKLabelNode()
    private var bag: BagOverlay?
    private var readingBook = false
    private var bookPickupNode: SKNode?
    private var friendNodes: [FriendID: MemoryCharacter] = [:]
    private var markerNode: SKNode?
    private var nearbyInteraction: MemoryInteractionTarget?
    private var nearbyPrompt: SKNode?

    init(size: CGSize, entry: MemoryPiece, worldLocations: Set<MemoryPiece>) {
        self.entry = entry
        // Satu kunjungan hanya membuka satu wilayah, tanpa pilihan dunia kedua.
        self.worldLocations = Set(worldLocations.filter { $0.region == entry.region })
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    private var worldScale: CGFloat {
        // Skala kamera zoom-in dekat bergaya Carto (~15% tinggi layar untuk karakter)
        return max(1.45, min(1.85, size.height / 250))
    }

    private func targetCameraPosition(for actorPos: CGPoint) -> CGPoint {
        let scale = worldScale
        let targetX = size.width / 2 - actorPos.x * scale
        let targetY = size.height / 2 - actorPos.y * scale

        let worldW = 960 * scale
        let worldH = 480 * scale

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

    private func updateCamera(dt: CGFloat, immediate: Bool = false) {
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

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.16, blue: 0.18, alpha: 1)
        if stage.parent != nil {
            readingBook = false
            lastTime = 0
            buildHUD()
            updateCamera(dt: 0, immediate: true)
            updateBookAccess()
            return
        }
        addChild(stage)
        stage.addChild(world)
        addChild(hud)
        hud.zPosition = 100
        buildWorld()
        buildHUD()
        updateCamera(dt: 0, immediate: true)
        animateArrival()
    }
    override func didChangeSize(_ oldSize: CGSize) {
        buildHUD()
        updateCamera(dt: 0, immediate: true)
        bag?.resize(to: size)
    }
    // Menampilkan animasi masuk dan menunda input sampai transisi selesai; mengikuti pengaturan Reduce Motion.
    private func animateArrival() {
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
        let title = storyLabel(entry.region == .house ? "Rumah di lembah" : (entry.region == .village ? "Desa di lembah" : "Kaki perbukitan"),
                               at: CGPoint(x: size.width / 2, y: size.height / 2), size: 28,
                               color: SKColor(red: 0.98, green: 0.91, blue: 0.72, alpha: 1))
        title.zPosition = 350
        title.alpha = 0
        title.run(.sequence([.fadeIn(withDuration: duration * 0.35), .wait(forDuration: duration * 0.35),
                             .fadeOut(withDuration: duration * 0.35), .removeFromParent()]))
        hud.run(.sequence([.wait(forDuration: duration * 0.55), .fadeIn(withDuration: duration * 0.45)]))
        run(.sequence([.wait(forDuration: duration), .run { [weak self] in
            guard let self else { return }
            self.enteringMemory = false
            self.catchGrace = 2
            self.say("Geser stik atau ketuk tanah untuk bergerak. Dekati benda/teman, lalu ketuk Interaksi.", duration: 5)
        }]), withKey: "memoryArrival")
    }
    // Membuat peta, kabut, objek interaksi, karakter, dan patroli dari progres yang sedang tersimpan.
    private func buildWorld() {
        let local = PrologueProgress()
        local.placements = progress.placements.filter { worldLocations.contains($0.value.piece) }
        level = PrologueLevel.make(region: entry.region, progress: local)
        navigation = MemoryNavigation(bounds: PrologueLevel.bounds, solids: level.obstacles.map(\.rect), fog: level.fog(progress: local))
        if let texture = SceneryTextures.texture(level: level, progress: local) {
            let scenery = SKSpriteNode(texture: texture)
            scenery.anchorPoint = .zero
            scenery.size = PrologueLevel.bounds.size
            scenery.zPosition = -10
            world.addChild(scenery)
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
        }
        if let marker = level.marker, worldInstalled(.oldPath) {
            let post = SKShapeNode(rectOf: CGSize(width: 13, height: 31), cornerRadius: 2)
            post.fillColor = SKColor(red: 0.73, green: 0.61, blue: 0.40, alpha: 1)
            post.position = marker; post.zPosition = 15; world.addChild(post)
            post.storyLabel("Penanda", at: CGPoint(x: 0, y: 32), size: 11)
            markerNode = post
        }
        if worldInstalled(.boundary) {
            if let gathering = level.gathering {
                let ring = SKShapeNode(circleOfRadius: 54)
                ring.position = gathering
                ring.strokeColor = SKColor(red: 0.84, green: 0.80, blue: 0.50, alpha: 0.8)
                ring.fillColor = SKColor(white: 1, alpha: 0.05)
                world.addChild(ring)
                ring.storyLabel("Titik kumpul", at: CGPoint(x: 0, y: -65), size: 11)
            }
            if let exit = level.exit {
                let arch = SKShapeNode(rectOf: CGSize(width: 65, height: 85), cornerRadius: 8)
                arch.position = exit; arch.fillColor = SKColor(white: 1, alpha: 0.08)
                arch.strokeColor = SKColor(red: 0.88, green: 0.80, blue: 0.57, alpha: 1)
                world.addChild(arch)
                arch.storyLabel("Luar desa", at: CGPoint(x: 0, y: 55), size: 12)
            }
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
    private func color(_ friend: FriendID) -> SKColor {
        switch friend {
        case .keneth: return SKColor(red: 0.73, green: 0.39, blue: 0.24, alpha: 1)
        case .roland: return SKColor(red: 0.87, green: 0.65, blue: 0.28, alpha: 1)
        case .anneth: return SKColor(red: 0.36, green: 0.55, blue: 0.72, alpha: 1)
        }
    }
    private func addBook(at point: CGPoint) {
        let book = SKShapeNode(rectOf: CGSize(width: 32, height: 24), cornerRadius: 2)
        book.fillColor = SKColor(red: 0.84, green: 0.76, blue: 0.56, alpha: 1)
        book.name = "bookPickup"
        book.position = point; book.zPosition = 15
        world.addChild(book)
        bookPickupNode = book
        book.storyLabel("Buku lama", at: CGPoint(x: 0, y: 30), size: 11)
    }
    // Membuat tujuan misi, tombol kembali, indikator kecurigaan, stik, dan tombol interaksi dalam layout responsif Carto.
    private func buildHUD() {
        hud.removeAllChildren()

        // 1. Kapsul tujuan misi melayang di atas tengah (Carto floating pill)
        let objWidth = min(size.width * 0.52, 460)
        let objBg = SKShapeNode(rectOf: CGSize(width: objWidth, height: 36), cornerRadius: 18)
        objBg.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.88)
        objBg.strokeColor = SKColor(red: 0.88, green: 0.80, blue: 0.55, alpha: 0.45)
        objBg.lineWidth = 1.2
        objBg.position = CGPoint(x: size.width / 2, y: size.height - 34)
        hud.addChild(objBg)

        objective = hud.storyLabel(progress.objective, at: CGPoint(x: size.width / 2, y: size.height - 34), size: 13, width: objWidth - 28)
        objective.fontColor = SKColor(red: 0.98, green: 0.94, blue: 0.82, alpha: 1)

        // 2. Tombol kembali ke foto floating di kanan atas
        let photoBtn = hud.storyButton("Kembali ke foto", name: "photo", at: CGPoint(x: size.width - 92, y: size.height - 34), width: 145)
        photoBtn.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.88)
        photoBtn.strokeColor = SKColor(red: 0.88, green: 0.80, blue: 0.55, alpha: 0.5)

        // 3. Tombol tas floating di kanan bawah
        let bagBtn = hud.storyButton("Tas", name: "bag", at: CGPoint(x: size.width - 65, y: 55), width: 90)
        bagBtn.fillColor = SKColor(red: 0.12, green: 0.16, blue: 0.14, alpha: 0.88)
        bagBtn.strokeColor = SKColor(red: 0.88, green: 0.80, blue: 0.55, alpha: 0.5)

        // 4. Stik analog floating di kiri bawah
        let stick = SKShapeNode(circleOfRadius: 44)
        stick.position = stickCenter
        stick.fillColor = SKColor(white: 0.08, alpha: 0.45)
        stick.strokeColor = SKColor(white: 1, alpha: 0.28)
        stick.lineWidth = 1.5
        hud.addChild(stick)

        stickKnob = SKShapeNode(circleOfRadius: 18)
        stickKnob.position = stickCenter
        stickKnob.fillColor = SKColor(white: 1, alpha: 0.45)
        stickKnob.strokeColor = .clear
        hud.addChild(stickKnob)

        // 5. Indikator kecurigaan di bawah kapsul misi
        suspicionLabel = hud.storyLabel("Aman", at: CGPoint(x: size.width / 2, y: size.height - 58), size: 11, color: .lightGray)

        // 6. Petunjuk kontrol halus di bagian bawah
        let hint = hud.storyLabel("Berlindung di balik benda • Bidang kuning = pandangan warga",
                                  at: CGPoint(x: size.width / 2, y: 18), size: 11, color: SKColor(white: 1, alpha: 0.5))
        hint.zPosition = 10
        updateBookAccess()
    }
    private func updateBookAccess() {
        if progress.hasBook {
            bookPickupNode?.removeFromParent()
            bookPickupNode = nil
            if nearbyInteraction == .book { clearNearbyInteraction() }
        }
    }
    private func say(_ text: String, duration: TimeInterval = 4) {
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
    // Menghentikan gerak pemain dan menyiapkan urutan dialog beserta aksi ketika selesai.
    private func startDialogue(_ lines: [StoryLine], completion: (() -> Void)? = nil) {
        guard dialoguePanel == nil else { return }
        clearNearbyInteraction()
        arthur.route.removeAll(); stickVector = .zero; stickTouch = nil; stickKnob.position = stickCenter
        dialogue = lines; dialogueIndex = 0; dialogueCompletion = completion
        showDialoguePage()
    }
    // Mencari posisi karakter pembicara di koordinat dunia (world space)
    private func resolveSpeakerPosition(named speaker: String) -> CGPoint {
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

    private func showDialoguePage() {
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
    // Melanjutkan halaman; setelah halaman terakhir, menjalankan hadiah atau perubahan cerita lalu menyimpan.
    private func advanceDialogue() {
        dialogueIndex += 1
        if dialogueIndex < dialogue.count { showDialoguePage(); return }
        dialoguePanel?.removeFromParent(); dialoguePanel = nil
        let finish = dialogueCompletion; dialogueCompletion = nil
        finish?()
        objective.text = progress.objective
        PrologueStore.shared.save()
        // Reading pauses the world; resume with time to regain control.
        catchGrace = 1.2
    }
    // Menjalankan aksi pada objek yang sedang disorot di dekat Arthur.
    private func interact() {
        guard !watched && patrols.allSatisfy({ $0.suspicion < 0.25 }) else { say("Cari tempat berlindung sebelum berinteraksi."); return }
        guard let target = nearbyInteraction else { return }
        switch target {
        case .book:
            guard let book = bookPickupNode, !progress.hasBook else { return }
            progress.readBook()
            PrologueStore.shared.save()
            clearNearbyInteraction()
            book.removeAllActions()
            book.run(.sequence([
                .group([.move(to: arthur.position, duration: 0.22),
                        .scale(to: 0.15, duration: 0.22),
                        .fadeOut(withDuration: 0.22)]),
                .removeFromParent()
            ]))
            bookPickupNode = nil
            HapticsService.shared.playNotification(.success)
            objective.text = progress.objective
            startDialogue(PrologueDialogue.book) { [weak self] in
                self?.say("Buku masuk ke tas. 3 keping Desa terbuka! Kembali ke puzzle dan susun rangkaiannya.", duration: 6)
            }
        case .friend(let friend):
            guard progress.hasBook else {
                startDialogue([.init(speaker: friend.rawValue, text: "Sampai nanti, Arthur. Aku masih di desa.")])
                return
            }
            if progress.joined.contains(friend) {
                startDialogue([.init(speaker: friend.rawValue, text: "Aku sudah bersedia ikut! (\(progress.joined.count)/3)")])
                return
            }
            progress.shownBook.insert(friend)
            PrologueStore.shared.save()
            startDialogue(PrologueDialogue.friend(friend)) { [weak self] in
                guard let self else { return }
                self.progress.finishConversation(with: friend)
                if self.progress.joined.count == 3 {
                    self.say("Semua bersedia ikut. 3 keping Bukit terbuka! Susun di puzzle untuk menuju penanda.", duration: 6)
                } else { self.say("\(friend.rawValue) bersedia ikut.") }
            }
        case .marker:
            guard progress.joined.count == 3 else {
                startDialogue([.init(speaker: "Arthur", text: "Aku ingin membicarakan temuan ini dengan ketiga temanku dulu.")])
                return
            }
            if progress.foundMarker {
                startDialogue([.init(speaker: "Arthur", text: "Penanda mengarah ke batas desa. Berkumpul bersama di sana.")])
                return
            }
            startDialogue(PrologueDialogue.marker) { [weak self] in
                guard let self else { return }
                self.progress.readMarker()
                self.say("3 keping Batas Desa terbuka! Kembali ke puzzle dan susun untuk melanjutkan.", duration: 6)
            }
        }
    }

    // Memilih objek terdekat, memberi highlight, lalu memasang tombol tepat di atasnya.
    private func updateNearbyInteraction() {
        var candidates: [(MemoryInteractionTarget, SKNode, CGFloat)] = []
        if !progress.hasBook, let node = bookPickupNode, node.parent != nil {
            candidates.append((.book, node, distance(arthur.position, node.position)))
        }
        for friend in FriendID.allCases {
            guard let node = friendNodes[friend],
                  !navigation.fog.contains(where: { $0.contains(node.position) }) else { continue }
            candidates.append((.friend(friend), node, distance(arthur.position, node.position)))
        }
        if progress.installed(.oldPath), let node = markerNode {
            candidates.append((.marker, node, distance(arthur.position, node.position)))
        }
        guard let nearest = candidates.filter({ $0.2 <= 72 }).min(by: { $0.2 < $1.2 }) else {
            clearNearbyInteraction()
            return
        }
        guard nearbyInteraction != nearest.0 else {
            nearbyPrompt?.position = nearest.1.position
            return
        }
        clearNearbyInteraction()
        nearbyInteraction = nearest.0
        let prompt = makeInteractionPrompt(for: nearest.0)
        prompt.position = nearest.1.position
        world.addChild(prompt)
        nearbyPrompt = prompt
    }

    private func makeInteractionPrompt(for target: MemoryInteractionTarget) -> SKNode {
        let root = SKNode()
        root.zPosition = 90
        let radius: CGFloat = target == .book ? 24 : 29
        let highlight = SKShapeNode(circleOfRadius: radius)
        highlight.name = "contextInteract"
        highlight.strokeColor = SKColor(red: 1, green: 0.83, blue: 0.36, alpha: 0.95)
        highlight.fillColor = SKColor(red: 1, green: 0.78, blue: 0.25, alpha: 0.10)
        highlight.lineWidth = 3
        root.addChild(highlight)
        highlight.run(.repeatForever(.sequence([
            .group([.scale(to: 1.16, duration: 0.55), .fadeAlpha(to: 0.45, duration: 0.55)]),
            .group([.scale(to: 1, duration: 0.55), .fadeAlpha(to: 1, duration: 0.55)])
        ])))

        let title = target == .book ? "Ambil" : "Interaksi"
        let width: CGFloat = target == .book ? 82 : 112
        let button = root.storyButton(title, name: "contextInteract", at: CGPoint(x: 0, y: 58), width: width)
        button.fillColor = SKColor(red: 0.24, green: 0.18, blue: 0.09, alpha: 0.97)
        button.strokeColor = SKColor(red: 1, green: 0.82, blue: 0.38, alpha: 1)
        button.lineWidth = 2
        let pointer = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -6, y: 35))
            path.addLine(to: CGPoint(x: 6, y: 35))
            path.addLine(to: CGPoint(x: 0, y: 27))
            path.closeSubpath()
            return path
        }())
        pointer.name = "contextInteract"
        pointer.fillColor = button.fillColor
        pointer.strokeColor = button.strokeColor
        root.addChild(pointer)
        return root
    }

    private func clearNearbyInteraction() {
        nearbyPrompt?.removeFromParent()
        nearbyPrompt = nil
        nearbyInteraction = nil
    }
    // Memperbarui gerak dan kecurigaan setiap frame; kamera mengikuti Arthur secara halus ala Carto.
    override func update(_ currentTime: TimeInterval) {
        let dt = CGFloat(min(0.04, max(0, lastTime == 0 ? 0 : currentTime - lastTime)))
        lastTime = currentTime
        updateCamera(dt: dt)
        guard navigation != nil, dialoguePanel == nil, !enteringMemory, !readingBook, bag == nil else { return }
        warningCooldown = max(0, warningCooldown - dt)
        catchGrace = max(0, catchGrace - dt)
        if hypot(stickVector.dx, stickVector.dy) > 0.05 {
            let movement = CGVector(dx: stickVector.dx * 140 * dt, dy: stickVector.dy * 140 * dt)
            let attempted = CGPoint(x: arthur.position.x + movement.dx, y: arthur.position.y + movement.dy)
            let previous = arthur.position
            arthur.position = navigation.moved(from: arthur.position, by: movement)
            let stepX = arthur.position.x - previous.x
            let stepY = arthur.position.y - previous.y
            arthur.applyMovement(dx: stepX, dy: stepY, dt: dt)
            arthur.body.zRotation = atan2(movement.dy, movement.dx) - .pi / 2
            checkFog(at: attempted)
        } else { arthur.walk(dt: dt, speed: 140, navigation: navigation) }
        updateCompanions(dt: dt)
        watched = false
        for patrol in patrols {
            let seen = patrol.update(dt: dt, player: arthur.position, navigation: navigation)
            watched = watched || seen
            if catchGrace > 0 { patrol.suspicion = 0 }
        }
        let suspicion = patrols.map(\.suspicion).max() ?? 0
        suspicionLabel.text = suspicion > 0 ? "Warga mulai curiga  \(Int(suspicion * 100))%" : "Aman · kembali ke foto tersedia"
        suspicionLabel.fontColor = suspicion > 0 ? .yellow : .lightGray
        if suspicion >= 1 { caught(); return }
        updateNearbyInteraction()
        if progress.joined.count == 3 && !progress.noticedChangedRoute && entry.region == .foothills,
           worldInstalled(.oldPath), distance(arthur.position, CGPoint(x: 465, y: 350)) < 150 && !watched {
            progress.noticedChangedRoute = true
            startDialogue(PrologueDialogue.changedRoute)
            return
        }
        checkGroupProgress()
    }
    // Menghitung ulang rute teman secara berkala agar mengikuti Arthur sambil menghindari rintangan.
    private func updateCompanions(dt: CGFloat) {
        guard !companions.isEmpty else { return }
        followerTimer -= dt
        if followerTimer <= 0 {
            followerTimer = 0.55
            for (index, actor) in companions.enumerated() {
                let angle = CGFloat(index) * 2 * .pi / 3
                var destination = navigation.nearestOpen(to: CGPoint(x: arthur.position.x + cos(angle) * 25, y: arthur.position.y + sin(angle) * 25))
                var route = navigation.route(from: actor.position, to: destination)
                if route.isEmpty { destination = arthur.position; route = navigation.route(from: actor.position, to: destination) }
                if distance(actor.position, destination) > 15 { actor.route = route }
            }
        }
        for actor in companions { actor.walk(dt: dt, speed: 152, navigation: navigation) }
    }
    // Memastikan keempat anak berkumpul dan berada di pintu keluar sebelum melanjutkan misi.
    private func checkGroupProgress() {
        guard progress.foundMarker, !progress.leftVillage, companions.count == 3,
              worldInstalled(.boundary), let gathering = level.gathering, let exit = level.exit else { return }
        let actors = [arthur] + companions
        if !progress.groupGathered && actors.allSatisfy({ distance($0.position, gathering) < 70 }) && !watched {
            startDialogue(PrologueDialogue.gathering) { [weak self] in
                self?.progress.groupGathered = true
                self?.checkpoint = gathering
                self?.say("Kelompok lengkap. Cari kesempatan melewati penjaga bersama.")
            }
            return
        }
        let atExit = Set(actors.filter { distance($0.position, exit) < 64 }.map(\.title))
        if distance(arthur.position, exit) < 64 && !progress.groupGathered {
            if warningCooldown == 0 { say("Arthur: Kita berkumpul dulu. Pastikan tak ada yang tertinggal."); warningCooldown = 5 }
            return
        }
        if atExit.count == 4 && progress.groupGathered && !watched {
            progress.leaveVillage(childrenAtExit: atExit)
            PrologueStore.shared.save()
            startDialogue([
                .init(speaker: "Roland", text: "Kita semua di sini. Sekarang ke mana?"),
                .init(speaker: "Arthur", text: "Kita cari tahu bersama. Ini baru awal.")
            ]) { [weak self] in
                self?.say("Keempat map selesai. Kembali ke puzzle untuk melihat kenangan utuh.", duration: 7)
            }
        } else if atExit.contains("Arthur") && warningCooldown == 0 {
            say("Tunggu teman merapat di titik keluar (\(atExit.count)/4).")
            warningCooldown = 4
        }
    }
    private func checkFog(at point: CGPoint) {
        guard warningCooldown == 0, navigation.fog.contains(where: { $0.insetBy(dx: -20, dy: -20).contains(point) }) else { return }
        say("Arthur: Aku belum ingat apa yang ada di sana…")
        warningCooldown = 5
    }
    // Mengembalikan kelompok ke checkpoint dan mereset kecurigaan sambil mempertahankan progres misi.
    private func caught() {
        clearNearbyInteraction()
        arthur.position = checkpoint; arthur.route.removeAll()
        stickVector = .zero; stickTouch = nil; stickKnob.position = stickCenter
        arthur.applyMovement(dx: 0, dy: 0, dt: 0.1)
        updateCamera(dt: 0, immediate: true)
        for (index, actor) in companions.enumerated() {
            actor.position = navigation.nearestOpen(to: CGPoint(x: checkpoint.x + CGFloat(index) * 16, y: checkpoint.y + 18))
            actor.route.removeAll()
            actor.applyMovement(dx: 0, dy: 0, dt: 0.1)
        }
        for patrol in patrols { patrol.suspicion = 0 }
        catchGrace = 3; watched = false
        PrologueStore.shared.save()
        say(entry.region == .house ? "Orang tua: Jangan menyelinap. Kami hanya ingin kamu tetap aman di rumah." : "Warga: Pulang dulu, Arthur. Di luar desa berbahaya; kami tak mau kalian terluka.", duration: 6)
    }
    // Menyimpan progres lalu kembali ke papan ketika warga sudah tidak memperhatikan Arthur.
    private func returnToPhoto(selectedPiece: Int? = nil) {
        guard !watched && patrols.allSatisfy({ $0.suspicion == 0 }) else {
            say("Arthur masih diperhatikan. Berlindung sampai warga tenang."); return
        }
        PrologueStore.shared.save()
        let photo = GameScene(size: size)
        photo.bagSelectedPiece = selectedPiece
        photo.scaleMode = .resizeFill
        view?.presentScene(photo, transition: .fade(withDuration: 0.35))
    }
    private func openBag() {
        guard bag == nil else { return }
        arthur.route.removeAll()
        stickTouch = nil; stickVector = .zero; stickKnob.position = stickCenter
        let overlay = BagOverlay(progress: progress, sceneSize: size)
        overlay.onClose = { [weak self] in self?.closeBag() }
        overlay.onUse = { [weak self] item in
            guard let self else { return }
            self.closeBag()
            switch item {
            case .book: self.openBook()
            case .fragment(let id): self.returnToPhoto(selectedPiece: id)
            }
        }
        bag = overlay
        addChild(overlay)
    }
    private func closeBag() {
        bag?.removeFromParent()
        bag = nil
        lastTime = 0
    }
    private func openBook() {
        guard progress.hasBook, !readingBook, let view else { return }
        readingBook = true
        PrologueStore.shared.save()
        arthur.route.removeAll()
        stickVector = .zero
        stickTouch = nil
        stickKnob.position = stickCenter
        let book = BookScene(size: size)
        book.scaleMode = .resizeFill
        // The book retains its return scene; an offscreen scene has no view.
        // Capture the presenting view weakly to avoid a view/scene retain cycle.
        book.onClose = { [self, weak view] in
            guard let view else { return }
            view.presentScene(self, transition: .fade(withDuration: 0.30))
        }
        view.presentScene(book, transition: .fade(withDuration: 0.30))
    }
    // Area dari rangkaian lain tetap tertutup walaupun sudah terpasang di papan.
    private func worldInstalled(_ location: MemoryPiece) -> Bool {
        worldLocations.contains(location) && progress.installed(location)
    }
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
    // Mengubah jarak sentuhan dari pusat stik menjadi arah dan kekuatan gerak terbatas.
    private func updateStick(_ touch: UITouch) {
        let point = touch.location(in: hud)
        let center = stickCenter
        let dx = point.x - center.x, dy = point.y - center.y
        let length = max(1, hypot(dx, dy))
        let magnitude = min(1, length / 40)
        stickVector = CGVector(dx: dx / length * magnitude, dy: dy / length * magnitude)
        stickKnob.position = CGPoint(x: center.x + stickVector.dx * 30, y: center.y + stickVector.dy * 30)
    }
    // Mengarahkan sentuhan ke dialog, tombol, stik, atau pencarian rute menuju tanah yang diketuk.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, !readingBook, bag == nil, let touch = touches.first else { return }
        if dialoguePanel != nil { advanceDialogue(); return }
        let hudPoint = touch.location(in: hud)
        let names = Set(hud.nodes(at: hudPoint).compactMap(\.name))
        let worldNames = Set(world.nodes(at: touch.location(in: world)).compactMap { $0.namedAncestor(prefix: "contextInteract") })
        if names.contains("photo") { returnToPhoto(); return }
        if names.contains("bag") { openBag(); return }
        if worldNames.contains("contextInteract") { interact(); return }
        if distance(hudPoint, stickCenter) < 70 {
            stickTouch = touch; arthur.route.removeAll(); updateStick(touch); return
        }
        let destination = touch.location(in: world)
        guard PrologueLevel.bounds.contains(destination) else { return }
        if navigation.fog.contains(where: { $0.contains(destination) }) { checkFog(at: destination); return }
        arthur.route = navigation.route(from: arthur.position, to: destination)
        if arthur.route.isEmpty { say("Arthur: Belum ada jalan yang bisa kulewati dari sini.") }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let stickTouch, touches.contains(stickTouch) else { return }
        updateStick(stickTouch)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let stickTouch, touches.contains(stickTouch) else { return }
        self.stickTouch = nil; stickVector = .zero; stickKnob.position = stickCenter
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stickTouch = nil; stickVector = .zero; stickKnob.position = stickCenter; arthur.route.removeAll()
    }
}

private enum MemoryInteractionTarget: Equatable {
    case book
    case friend(FriendID)
    case marker
}
