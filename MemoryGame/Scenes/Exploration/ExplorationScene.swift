// Penjelasan file: ExplorationScene.swift
// Mengendalikan permainan di dalam kenangan: membangun dunia, HUD, karakter, dan patroli.
// Menangani stik, ketuk untuk berjalan, dialog, interaksi misi, teman pengikut, dan kembali ke foto.
// Memakai PrologueLevel untuk peta, MemoryNavigation untuk gerak, serta PrologueStore untuk progres.

import SpriteKit
import UIKit

final class ExplorationScene: SKScene {
    private var enteringMemory = true
    private let entry: MemoryPiece
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
    private let stickCenter = CGPoint(x: 98, y: 113)
    private var stickKnob = SKShapeNode(circleOfRadius: 18)
    private var objective = SKLabelNode()
    private var suspicionLabel = SKLabelNode()
    private var interactionButton: SKShapeNode?

    init(size: CGSize, entry: MemoryPiece) {
        self.entry = entry
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.13, blue: 0.14, alpha: 1)
        addChild(stage)
        stage.addChild(world)
        world.position = CGPoint(x: 20, y: 65)
        stage.addChild(hud)
        hud.zPosition = 100
        resizeStage()
        buildWorld()
        buildHUD()
        animateArrival()
    }
    override func didChangeSize(_ oldSize: CGSize) { if stage.parent != nil { resizeStage() } }
    private func resizeStage() {
        stage.setScale(min(size.width / 1000, size.height / 600))
        stage.position = CGPoint(x: (size.width - 1000 * stage.xScale) / 2, y: (size.height - 600 * stage.yScale) / 2)
    }
    // Menampilkan animasi masuk dan menunda input sampai transisi selesai; mengikuti pengaturan Reduce Motion.
    private func animateArrival() {
        let reduced = UIAccessibility.isReduceMotionEnabled
        let duration: TimeInterval = reduced ? 0.22 : 1.0
        hud.alpha = 0
        let finalPosition = world.position
        world.alpha = reduced ? 0 : 0.35
        if !reduced {
            world.setScale(1.10)
            world.position = CGPoint(x: finalPosition.x - 48, y: finalPosition.y - 24)
        }
        let settle = SKAction.group([
            .scale(to: 1, duration: duration), .move(to: finalPosition, duration: duration),
            .fadeIn(withDuration: duration * 0.8)
        ])
        settle.timingMode = .easeOut
        world.run(settle)
        let title = hud.storyLabel(entry.region == .house ? "Rumah di lembah" : (entry.region == .village ? "Desa di lembah" : "Kaki perbukitan"),
                                   at: CGPoint(x: 500, y: 310), size: 30,
                                   color: SKColor(red: 0.98, green: 0.91, blue: 0.72, alpha: 1))
        title.zPosition = 350
        // Title is separate from the fading controls so its reveal remains legible.
        title.removeFromParent(); stage.addChild(title)
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
        level = PrologueLevel.make(region: entry.region, progress: progress)
        navigation = MemoryNavigation(bounds: PrologueLevel.bounds, solids: level.obstacles.map(\.rect), fog: level.fog(progress: progress))
        if let texture = SceneryTextures.texture(level: level, progress: progress) {
            let scenery = SKSpriteNode(texture: texture)
            scenery.anchorPoint = .zero
            scenery.size = PrologueLevel.bounds.size
            scenery.zPosition = -10
            world.addChild(scenery)
        }
        MemoryAtmosphere.add(to: world, level: level)
        for zone in level.zones {
            let available = level.available(zone, progress: progress)
            let base = SKShapeNode(rect: zone.rect)
            base.fillColor = .clear
            base.strokeColor = .clear
            world.addChild(base)
            if available {
                world.storyLabel(zone.piece == .lake ? (progress.lakeVariant?.title ?? "") : zone.piece.title,
                                 at: CGPoint(x: zone.rect.midX, y: zone.rect.maxY - 24), size: 12,
                                 color: SKColor(white: 1, alpha: 0.4))

            } else {
                let fog = SKShapeNode(rect: zone.rect.insetBy(dx: 2, dy: 2), cornerRadius: 8)
                fog.fillColor = SKColor(red: 0.37, green: 0.43, blue: 0.43, alpha: 1)
                fog.strokeColor = .clear
                fog.zPosition = 30
                world.addChild(fog)
                let label = fog.storyLabel("Kabut kenangan", at: CGPoint(x: zone.rect.midX, y: zone.rect.midY), size: 16, color: .white)
                label.zPosition = 1
                for index in 0..<7 {
                    let cloud = SKShapeNode(ellipseOf: CGSize(width: zone.rect.width * 0.72, height: 40))
                    cloud.fillColor = SKColor(white: 0.85, alpha: 0.055)
                    cloud.strokeColor = .clear
                    cloud.position = CGPoint(x: zone.rect.midX, y: zone.rect.minY + 38 + CGFloat(index) * zone.rect.height / 8)
                    fog.addChild(cloud)
                }
            }
        }
        if let book = level.book { addBook(at: book) }
        for (friend, point) in level.friends {
            let npc = MemoryCharacter(title: friend.rawValue, color: color(friend))
            npc.position = point; world.addChild(npc)
        }
        if let marker = level.marker, progress.installed(.oldPath) {
            let post = SKShapeNode(rectOf: CGSize(width: 13, height: 31), cornerRadius: 2)
            post.fillColor = SKColor(red: 0.73, green: 0.61, blue: 0.40, alpha: 1)
            post.position = marker; post.zPosition = 15; world.addChild(post)
            post.storyLabel("Penanda", at: CGPoint(x: 0, y: 32), size: 11)
        }
        if progress.installed(.boundary) {
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
        book.position = point; book.zPosition = 15
        world.addChild(book)
        book.storyLabel("Buku lama", at: CGPoint(x: 0, y: 30), size: 11)
    }
    // Membuat tujuan misi, tombol kembali, indikator kecurigaan, stik, dan tombol interaksi.
    private func buildHUD() {
        let top = SKShapeNode(rect: CGRect(x: 0, y: 548, width: 1000, height: 52))
        top.fillColor = SKColor(white: 0.06, alpha: 0.96); top.strokeColor = .clear
        hud.addChild(top)
        objective = hud.storyLabel(progress.objective, at: CGPoint(x: 450, y: 577), size: 15, width: 710)
        hud.storyButton("Kembali ke foto", name: "photo", at: CGPoint(x: 898, y: 577), width: 165)
        hud.storyLabel("Berlindung di balik benda • Bidang kuning = pandangan warga", at: CGPoint(x: 500, y: 27), size: 12, color: .lightGray)
        suspicionLabel = hud.storyLabel("Aman", at: CGPoint(x: 495, y: 550), size: 12, color: .lightGray)
        let stick = SKShapeNode(circleOfRadius: 47)
        stick.position = stickCenter; stick.fillColor = SKColor(white: 0.05, alpha: 0.34)
        stick.strokeColor = SKColor(white: 1, alpha: 0.22); hud.addChild(stick)
        stickKnob.position = stickCenter; stickKnob.fillColor = SKColor(white: 1, alpha: 0.32)
        stickKnob.strokeColor = .clear; hud.addChild(stickKnob)
        interactionButton = hud.storyButton("Interaksi", name: "interact", at: CGPoint(x: 902, y: 55), width: 145)
    }
    private func say(_ text: String, duration: TimeInterval = 4) {
        toast?.removeFromParent()
        let label = hud.storyLabel(text, at: CGPoint(x: 500, y: 510), size: 16, width: 830)
        label.zPosition = 110
        let background = SKShapeNode(rectOf: CGSize(width: 870, height: 47), cornerRadius: 10)
        background.fillColor = SKColor(white: 0.04, alpha: 0.87); background.strokeColor = .clear
        background.zPosition = -1; label.addChild(background)
        toast = label
        label.run(.sequence([.wait(forDuration: duration), .fadeOut(withDuration: 0.4), .removeFromParent()]))
    }
    // Menghentikan gerak pemain dan menyiapkan urutan dialog beserta aksi ketika selesai.
    private func startDialogue(_ lines: [StoryLine], completion: (() -> Void)? = nil) {
        guard dialoguePanel == nil else { return }
        arthur.route.removeAll(); stickVector = .zero; stickTouch = nil; stickKnob.position = stickCenter
        dialogue = lines; dialogueIndex = 0; dialogueCompletion = completion
        showDialoguePage()
    }
    private func showDialoguePage() {
        dialoguePanel?.removeFromParent()
        let panel = SKShapeNode(rect: CGRect(x: 145, y: 80, width: 710, height: 155), cornerRadius: 15)
        panel.fillColor = SKColor(red: 0.08, green: 0.13, blue: 0.15, alpha: 0.98)
        panel.strokeColor = SKColor(red: 0.76, green: 0.69, blue: 0.49, alpha: 1)
        panel.zPosition = 300
        let line = dialogue[dialogueIndex]
        panel.storyLabel(line.speaker, at: CGPoint(x: 500, y: 207), size: 18, color: SKColor(red: 0.92, green: 0.80, blue: 0.50, alpha: 1))
        panel.storyLabel(line.text, at: CGPoint(x: 500, y: 156), size: 17, width: 640)
        panel.storyLabel("Ketuk untuk lanjut  ·  \(dialogueIndex + 1)/\(dialogue.count)", at: CGPoint(x: 500, y: 102), size: 12, color: .lightGray)
        hud.addChild(panel); dialoguePanel = panel
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
    // Memilih interaksi terdekat yang memenuhi syarat misi dan kondisi aman dari warga.
    private func interact() {
        guard !watched && patrols.allSatisfy({ $0.suspicion < 0.25 }) else { say("Cari tempat berlindung sebelum berinteraksi."); return }
        if let book = level.book, distance(arthur.position, book) < 62 {
            if progress.hasBook { say("Buku sudah dibawa Arthur. Tunjukkan kepada ketiga teman."); return }
            startDialogue(PrologueDialogue.book) { [weak self] in
                self?.progress.readBook()
                self?.say("Keping baru: kebun, pegunungan, cekungan kering. Pasang di foto untuk membuka area.", duration: 6)
            }
            return
        }
        for friend in FriendID.allCases {
            guard let point = level.friends[friend], distance(arthur.position, point) < 62,
                  !navigation.fog.contains(where: { $0.contains(point) }) else { continue }
            guard progress.hasBook else { say("\(friend.rawValue): Sampai nanti, Arthur. Aku masih di desa."); return }
            if progress.joined.contains(friend) { say("\(friend.rawValue) sudah bersedia ikut. (\(progress.joined.count)/3)"); return }
            progress.shownBook.insert(friend)
            PrologueStore.shared.save()
            startDialogue(PrologueDialogue.friend(friend)) { [weak self] in
                guard let self else { return }
                self.progress.finishConversation(with: friend)
                if self.progress.joined.count == 3 {
                    self.say("Semua bersedia ikut. Keping danau dan jalur lama masuk inventori.", duration: 6)
                } else { self.say("\(friend.rawValue) bersedia ikut.") }
            }
            return
        }
        if let marker = level.marker, progress.installed(.oldPath), distance(arthur.position, marker) < 62 {
            guard progress.joined.count == 3 else { say("Arthur: Aku ingin membicarakan temuan ini dengan ketiga temanku dulu."); return }
            if progress.foundMarker { say("Penanda mengarah ke batas desa. Berkumpul bersama di sana."); return }
            startDialogue(PrologueDialogue.marker) { [weak self] in
                guard let self else { return }
                self.progress.readMarker()
                self.say("Keping batas desa diperoleh. Kembali ke foto dan pasang untuk melanjutkan.", duration: 6)
            }
            return
        }
        say("Dekati buku, teman, atau penanda untuk berinteraksi.")
    }
    // Memperbarui gerak dan kecurigaan setiap frame; dunia dijeda selama dialog dan transisi masuk.
    override func update(_ currentTime: TimeInterval) {
        let dt = CGFloat(min(0.04, max(0, lastTime == 0 ? 0 : currentTime - lastTime)))
        lastTime = currentTime
        guard navigation != nil, dialoguePanel == nil, !enteringMemory else { return }
        warningCooldown = max(0, warningCooldown - dt)
        catchGrace = max(0, catchGrace - dt)
        if hypot(stickVector.dx, stickVector.dy) > 0.05 {
            let movement = CGVector(dx: stickVector.dx * 140 * dt, dy: stickVector.dy * 140 * dt)
            let attempted = CGPoint(x: arthur.position.x + movement.dx, y: arthur.position.y + movement.dy)
            arthur.position = navigation.moved(from: arthur.position, by: movement)
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
        if progress.joined.count == 3 && !progress.noticedChangedRoute && entry.region == .foothills,
           progress.installed(.oldPath), distance(arthur.position, CGPoint(x: 465, y: 350)) < 150 && !watched {
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
              progress.installed(.boundary), let gathering = level.gathering, let exit = level.exit else { return }
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
                self?.say("Keping penutup foto diperoleh. Kembali ke foto untuk merangkai kenangan utuh.", duration: 7)
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
        arthur.position = checkpoint; arthur.route.removeAll()
        stickVector = .zero; stickTouch = nil; stickKnob.position = stickCenter
        for (index, actor) in companions.enumerated() {
            actor.position = navigation.nearestOpen(to: CGPoint(x: checkpoint.x + CGFloat(index) * 16, y: checkpoint.y + 18))
            actor.route.removeAll()
        }
        for patrol in patrols { patrol.suspicion = 0 }
        catchGrace = 3; watched = false
        PrologueStore.shared.save()
        say(entry.region == .house ? "Orang tua: Jangan menyelinap. Kami hanya ingin kamu tetap aman di rumah." : "Warga: Pulang dulu, Arthur. Di luar desa berbahaya; kami tak mau kalian terluka.", duration: 6)
    }
    // Menyimpan progres lalu kembali ke papan ketika warga sudah tidak memperhatikan Arthur.
    private func returnToPhoto() {
        guard !watched && patrols.allSatisfy({ $0.suspicion == 0 }) else {
            say("Arthur masih diperhatikan. Berlindung sampai warga tenang."); return
        }
        PrologueStore.shared.save()
        let photo = GameScene(size: size)
        photo.scaleMode = .resizeFill
        view?.presentScene(photo, transition: .fade(withDuration: 0.35))
    }
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
    // Mengubah jarak sentuhan dari pusat stik menjadi arah dan kekuatan gerak terbatas.
    private func updateStick(_ touch: UITouch) {
        let point = touch.location(in: stage)
        let dx = point.x - stickCenter.x, dy = point.y - stickCenter.y
        let length = max(1, hypot(dx, dy))
        let magnitude = min(1, length / 40)
        stickVector = CGVector(dx: dx / length * magnitude, dy: dy / length * magnitude)
        stickKnob.position = CGPoint(x: stickCenter.x + stickVector.dx * 34, y: stickCenter.y + stickVector.dy * 34)
    }
    // Mengarahkan sentuhan ke dialog, tombol, stik, atau pencarian rute menuju tanah yang diketuk.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !enteringMemory, let touch = touches.first else { return }
        if dialoguePanel != nil { advanceDialogue(); return }
        let point = touch.location(in: stage)
        let names = Set(hud.nodes(at: touch.location(in: hud)).compactMap(\.name))
        if names.contains("photo") { returnToPhoto(); return }
        if names.contains("interact") { interact(); return }
        if distance(point, stickCenter) < 70 {
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
