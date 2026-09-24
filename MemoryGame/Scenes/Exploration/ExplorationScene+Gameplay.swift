import SpriteKit
import UIKit
import SwiftUI

// Gameplay adapter. Gameplay rules live in Models and Systems.
extension ExplorationScene {
    func startDialogue(_ lines: [StoryLine], completion: (() -> Void)? = nil) {
        guard dialoguePanel == nil else { return }
        clearNearbyInteraction()
        arthur.route.removeAll(); stickVector = .zero; stickTouch = nil; stickKnob.position = stickCenter
        dialogue = lines; dialogueIndex = 0; dialogueCompletion = completion
        showDialoguePage()
    }

    func advanceDialogue() {
        dialogueIndex += 1
        if dialogueIndex < dialogue.count { showDialoguePage(); return }
        dialoguePanel?.removeFromParent(); dialoguePanel = nil
        let finish = dialogueCompletion; dialogueCompletion = nil
        finish?()
        objective.text = progress.currentObjective(for: entry.region)
        PrologueStore.shared.save()
        // Reading pauses the world; resume with time to regain control.
        catchGrace = 1.2
    }

    func interact() {
        guard !watched && patrols.allSatisfy({ $0.suspicion < 0.25 }) else { say("Cari tempat berlindung sebelum berinteraksi."); return }
        guard let target = nearbyInteraction else { return }
        switch target {
        case .book:
            guard let book = bookPickupNode, !progress.hasBook else { return }
            clearNearbyInteraction()
            HapticsService.shared.playNotification(.success)

            animateBookPickup(book)

            progress.readBook()
            PrologueStore.shared.save()
            bookPickupNode = nil
            objective.text = progress.objective

            // Aktifkan lencana status teman di desa menjadi "Ajak Ikut"
            for friend in FriendID.allCases {
                if !progress.joined.contains(friend) {
                    friendNodes[friend]?.setStatusBadge(icon: "💬", text: "Ajak Ikut", color: SKColor(red: 0.95, green: 0.82, blue: 0.42, alpha: 1.0))
                }
            }

            // Arthur memegang buku saat dialog bercerita
            arthur.setHoldingBook(visible: true)

            run(.sequence([
                .wait(forDuration: 0.65),
                .run { [weak self] in
                    guard let self else { return }
                    self.startDialogue(PrologueDialogue.book) { [weak self] in
                        guard let self else { return }
                        self.arthur.setHoldingBook(visible: false)
                        self.showUnlockCard(
                            title: "✨ 3 KEPING DESA TERBUKA!",
                            body: "Buku telah tersimpan di Tas! Tekan 'Tas' kapan saja untuk membacanya. Sekarang kembalilah ke puzzle foto untuk menyusun kepingan jalan menuju Desa!"
                        )
                    }
                }
            ]))

        case .friend(let friend):
            guard progress.hasBook else {
                startDialogue([.init(speaker: friend.rawValue, text: "Sampai nanti, Arthur. Aku masih di desa.")])
                return
            }
            if progress.joined.contains(friend) {
                if let node = friendNodes[friend] {
                    node.wave()
                }
                startDialogue([.init(speaker: friend.rawValue, text: "Aku sudah bersedia ikut! (\(progress.joined.count)/3)")])
                return
            }

            // Arthur dan teman saling berhadapan
            let fNode = friendNodes[friend]
            if let fNode = fNode {
                let dx = fNode.position.x - arthur.position.x
                arthur.visualRoot.xScale = dx >= 0 ? 1.0 : -1.0
                fNode.visualRoot.xScale = dx >= 0 ? -1.0 : 1.0
            }

            // Arthur memperlihatkan buku peta
            arthur.setHoldingBook(visible: true)

            progress.shownBook.insert(friend)
            PrologueStore.shared.save()

            startDialogue(PrologueDialogue.friend(friend)) { [weak self] in
                guard let self else { return }
                self.arthur.setHoldingBook(visible: false)
                self.progress.finishConversation(with: friend)
                PrologueStore.shared.save()

                // Teman melompat gembira merayakan kesediaan ikut
                if let fNode = self.friendNodes[friend] {
                    fNode.celebrate()
                    fNode.setStatusBadge(icon: "✓", text: "Siap Ikut", color: SKColor(red: 0.42, green: 0.82, blue: 0.45, alpha: 1.0))
                }

                HapticsService.shared.playNotification(.success)
                self.showAnnouncementBanner(
                    icon: "🎉",
                    title: "\(friend.rawValue) Bersedia Ikut!",
                    subtitle: "Sekarang sudah ada \(self.progress.joined.count) dari 3 teman yang siap bertualang bersama."
                )

                // Jika ketiga teman sudah bergabung semuanya (3/3)
                if self.progress.joined.count == 3 {
                    self.run(.sequence([
                        .wait(forDuration: 1.2),
                        .run { [weak self] in
                            guard let self else { return }
                            for f in self.friendNodes.values { f.celebrate() }
                            self.arthur.celebrate()
                            self.showUnlockCard(
                                title: "🎉 SEMUA TEMAN BERGABUNG! (3/3)",
                                body: "Keneth, Roland, dan Anneth telah bersedia ikut! 3 keping Kaki Perbukitan terbuka. Susun keping bukit di puzzle foto untuk membuka jalur menuju penanda rahasia!"
                            )
                        }
                    ]))
                }
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
                self.showUnlockCard(
                    title: "✨ 3 KEPING BATAS DESA TERBUKA!",
                    body: "Penanda mengarah ke gerbang batas desa! Susun keping batas di puzzle foto, lalu berkumpullah bersama ketiga temanmu di titik kumpul."
                )
            }

        case .sitStump(let point):
            clearNearbyInteraction()
            HapticsService.shared.playSelection()
            arthur.route.removeAll()
            stickVector = .zero
            stickKnob.position = stickCenter
            arthur.sit(at: point)
            showHUDInteractButton(for: .standUp)
            say("Arthur duduk santai di atas bantalan batang kayu.", duration: 3)

        case .standUp:
            clearNearbyInteraction()
            HapticsService.shared.playSelection()
            arthur.standUp()
            say("Arthur kembali berdiri.", duration: 2)

        case .sleepBed:
            clearNearbyInteraction()
            HapticsService.shared.playSelection()
            arthur.route.removeAll()
            stickVector = .zero
            stickKnob.position = stickCenter
            arthur.sleep(at: houseBedSpot)
            showHUDInteractButton(for: .wakeUp)
            say("Arthur berbaring di kasur wol hangat... Zzz", duration: 4)

        case .wakeUp:
            clearNearbyInteraction()
            HapticsService.shared.playSelection()
            arthur.wakeUp()
            arthur.position = navigation.nearestOpen(to: CGPoint(x: 450, y: 78))
            say("Arthur bangun dengan segar!", duration: 2)

        case .rockSalt:
            clearNearbyInteraction()
            startRockSaltQTE()

        case .darkMineEntrance:
            clearNearbyInteraction()
            HapticsService.shared.playSelection()
            startDialogue([
                .init(speaker: "Arthur", text: "Lorong tambang menusuk jauh ke perut tebing garam. Di dalam gelap gulita dan bersuhu dingin pekat."),
                .init(speaker: "Arthur", text: "Balok-balok kayu penyangga tampak rapuh. Sesuai pesan Anneth, aku hanya boleh mengambil garam di dekat pintu masuk."),
                .init(speaker: "Arthur", text: "Masuk lebih jauh tanpa obor dan perlengkapan penambang sama saja mencari bahaya.")
            ])

        case .herbalPlant:
            clearNearbyInteraction()
            startQuest6Foraging()

        case .boundaryStone:
            clearNearbyInteraction()
            HapticsService.shared.playSelection()
            startDialogue([
                .init(speaker: "Arthur", text: "Batu pembatas kuno terukir simbol spiral. Lumut tebal menyelimuti permukaannya."),
                .init(speaker: "Arthur", text: "Kakek Beryn selalu mengingatkan: deretan batu ini adalah batas aman desa."),
                .init(speaker: "Arthur", text: "Di seberang batu ini, hutan liar membentang tanpa perlindungan desa. Jangan pernah melangkah sendirian.")
            ])

        case .hollowEncounter:
            clearNearbyInteraction()
            startQuest6HollowEncounter()

        case .firewood:
            clearNearbyInteraction()
            HapticsService.shared.playNotification(.success)
            progress.gatheredWood = true
            PrologueStore.shared.save()
            objective.text = progress.currentObjective(for: entry.region)
            startDialogue([
                .init(speaker: "Arthur", text: "Tumpukan kayu pinus kering ini cukup untuk persediaan musim dingin."),
                .init(speaker: "Arthur", text: "Tebangan kayu warga di lereng ini rapi, tapi... ada bekas longsoran baru di dekat akar pohon tua."),
                .init(speaker: "Arthur", text: "Akar pohon raksasa itu mencengkeram tebing yang runtuh. Tampak ada sesuatu yang terselip di sana! Mari kita periksa.")
            ]) { [weak self] in
                self?.showAnnouncementBanner(
                    icon: "🪵",
                    title: "Kayu Bakar Dikumpulkan!",
                    subtitle: "Tanah longsor & akar pohon tua di timur kini bisa diperiksa!"
                )
            }

        case .landslideEliasBook:
            clearNearbyInteraction()
            guard progress.gatheredWood else {
                startDialogue([
                    .init(speaker: "Arthur", text: "Tanah longsor kecil di dekat akar pohon tua ini tampak gembur dan rapuh."),
                    .init(speaker: "Arthur", text: "Aku sebaiknya menyelesaikan mengumpulkan kayu bakar dulu sebelum menyelidikinya.")
                ])
                return
            }
            presentEliasJournalDiscoveryMinigame()

        case .boundaryTreeMarker:
            clearNearbyInteraction()
            HapticsService.shared.playNotification(.success)
            progress.boundaryMarked = true
            PrologueStore.shared.save()
            objective.text = progress.currentObjective(for: entry.region)
            startDialogue([
                .init(speaker: "Anneth", text: "Ini pohon terbesar di tepi hutan perbatasan. Aku akan menorehkan tanda 'X' dengan pisauku di kulit kayunya."),
                .init(speaker: "Roland", text: "Bagus! Dan aku mengikatkan pita kain jingga terang ini pada dahan terendah."),
                .init(speaker: "Keneth", text: "Dengan tanda sayatan dan kain terang ini, kita punya patokan pasti untuk pulang nanti."),
                .init(speaker: "Arthur", text: "Sekarang batas telah ditandai. Tidak ada keraguan lagi, mari kita masuki Deep Woods!")
            ]) { [weak self] in
                self?.showAnnouncementBanner(
                    icon: "🎗️",
                    title: "Batas Ditandai!",
                    subtitle: "Torehan pisau 'X' dan pita kain terpasang! Gerbang ke Deep Woods (Map C) terbuka."
                )
            }

        case .deepWoodsGate:
            clearNearbyInteraction()
            guard progress.boundaryMarked else {
                startDialogue([
                    .init(speaker: "Arthur", text: "Kabut di depan sangat tebal. Kita tidak boleh masuk tanpa menandai pohon perbatasan dulu agar tidak tersesat!"),
                    .init(speaker: "Anneth", text: "Arthur benar. Mari kita torehkan tanda 'X' dan ikat pita pada pohon penanda terlebih dahulu.")
                ])
                return
            }
            HapticsService.shared.playNotification(.success)
            startDialogue([
                .init(speaker: "Arthur", text: "Kain penanda telah terikat. Semuanya siap?"),
                .init(speaker: "Anneth", text: "Bekal dan pisauku siap. Aku di belakangmu, Arthur."),
                .init(speaker: "Roland", text: "Formasi siap, tongkat kayu di tangan. Apapun yang ada di balik kabut, kita hadapi bersama!"),
                .init(speaker: "Keneth", text: "Aku memegang Buku Elias untuk memandu rute."),
                .init(speaker: "Arthur", text: "Melangkah bersama... Masuki Deep Woods!")
            ]) { [weak self] in
                self?.showUnlockCard(
                    title: "🌲 MENUJU MAP C: DEEP WOODS!",
                    body: "Arthur dan ketiga sahabatnya berhasil menembus perbatasan! Wilayah yang dikenal warga kini tertinggal di belakang. Babak Prolog Selesai — Petualangan di Hutan Luar Segera Dimulai!"
                )
            }
        }
    }

    func updateNearbyInteraction() {
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

        // Interaksi khusus interior rumah: bantalan tunggul kayu (duduk) dan kasur (tidur)
        if entry.region == .house {
            if arthur.isSitting {
                if nearbyInteraction != .standUp {
                    clearNearbyInteraction()
                    nearbyInteraction = .standUp
                    showHUDInteractButton(for: .standUp)
                }
                return
            }
            if arthur.isSleeping {
                if nearbyInteraction != .wakeUp {
                    clearNearbyInteraction()
                    nearbyInteraction = .wakeUp
                    showHUDInteractButton(for: .wakeUp)
                }
                return
            }
            if distance(arthur.position, houseBedSpot) <= 68 {
                candidates.append((.sleepBed, bedNode ?? arthur, distance(arthur.position, houseBedSpot)))
            }
            for (i, stump) in houseStumpCushions.enumerated() {
                let d = distance(arthur.position, stump)
                if d <= 52 {
                    let anchor = i < stumpNodes.count ? stumpNodes[i] : arthur
                    candidates.append((.sitStump(stump), anchor, d))
                }
            }
        }

        // Interaksi khusus Map B (Pinggiran / Zona Transisi)
        if entry.region == .boundary {
            if let node = rockSaltNode, node.parent != nil {
                candidates.append((.rockSalt, node, distance(arthur.position, node.position)))
            }
            if let node = mineShaftNode, node.parent != nil {
                candidates.append((.darkMineEntrance, node, distance(arthur.position, node.position)))
            }
            if let node = herbalNode, node.parent != nil {
                candidates.append((.herbalPlant, node, distance(arthur.position, node.position)))
            }
            for stone in boundaryStoneNodes {
                let d = distance(arthur.position, stone.position)
                if d <= 70 {
                    candidates.append((.boundaryStone, stone, d))
                }
            }
            if let node = hollowNode, node.parent != nil {
                candidates.append((.hollowEncounter, node, distance(arthur.position, node.position)))
            }
            if let node = firewoodNode, node.parent != nil {
                candidates.append((.firewood, node, distance(arthur.position, node.position)))
            }
            if let node = eliasBookNode, node.parent != nil {
                candidates.append((.landslideEliasBook, node, distance(arthur.position, node.position)))
            }
            if let node = boundaryTreeNode, node.parent != nil {
                candidates.append((.boundaryTreeMarker, node, distance(arthur.position, node.position)))
            }
            if let node = deepWoodsGateNode, node.parent != nil {
                candidates.append((.deepWoodsGate, node, distance(arthur.position, node.position)))
            }
        }

        // Radius deteksi 85pt agar interaksi mudah terpicu saat mendekati objek/teman
        guard let nearest = candidates.filter({ $0.2 <= 85 }).min(by: { $0.2 < $1.2 }) else {
            clearNearbyInteraction()
            return
        }
        if nearbyInteraction == nearest.0 {
            nearbyPrompt?.position = nearest.1.position
            return
        }
        clearNearbyInteraction()
        nearbyInteraction = nearest.0
        let prompt = makeInteractionPrompt(for: nearest.0)
        prompt.position = nearest.1.position
        world.addChild(prompt)
        nearbyPrompt = prompt
        showHUDInteractButton(for: nearest.0)
    }

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
        if entry.region == .echoes && !echoesVillagePassed && arthur.position.x > 870 {
            echoesVillagePassed = true
            refreshEchoesScenery()
            say("Desa itu lenyap. Yang tersisa hanya hutan.", duration: 3.5)
        }
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
        if entry.region == .boundary, let exit = level.exit, distance(arthur.position, exit) < 60, warningCooldown == 0 {
            warningCooldown = 6
            switch progress.mapBStage {
            case .rockSalt:
                if progress.hasRockSalt {
                    finishQuest5VillageReturn()
                } else {
                    say("Ambil rock salt terlebih dahulu di dekat mulut tambang sebelum kembali.")
                }
            case .herbalHills:
                if progress.encounteredHollow {
                    finishQuest6VillageReturn()
                } else if progress.hasHerbal {
                    say("Selidiki sosok bayangan di pinggir pohon sebelum kembali ke desa.")
                } else {
                    say("Petik daun herbal di atas batu menjorok terlebih dahulu.")
                }
            case .woodcutterSlope:
                if progress.hasEliasBook {
                    say("Arthur kembali ke desa membawa Buku Catatan Elias untuk bertemu teman-teman.")
                } else if progress.gatheredWood {
                    say("Periksa celah tanah longsor dan akar pohon tua terlebih dahulu.")
                } else {
                    say("Kumpulkan kayu bakar terlebih dahulu.")
                }
            case .theBoundary:
                if progress.boundaryMarked {
                    say("Gerbang Deep Woods terbuka! Masuki celah kabut di sebelah timur.")
                } else {
                    say("Kita harus menandai pohon penanda terlebih dahulu sebelum menembus kabut.")
                }
            }
        }
    }

    func updateCompanions(dt: CGFloat) {
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

    func checkGroupProgress() {
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

    func checkFog(at point: CGPoint) {
        guard warningCooldown == 0, navigation.fog.contains(where: { $0.insetBy(dx: -20, dy: -20).contains(point) }) else { return }
        say("Arthur: Aku belum ingat apa yang ada di sana…")
        warningCooldown = 5
    }

    func caught() {
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

    func worldInstalled(_ location: MemoryPiece) -> Bool {
        worldLocations.contains(location) || progress.installed(location)
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    // MARK: - Rock Salt Mining Minigame (QTE)

    func startRockSaltQTE() {
        guard activeQTE == nil else { return }
        // Hentikan pergerakan Arthur dan joystick saat minigame dimulai
        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        let config = QuickTimeEventConfig(
            radius: 82,
            stage1Duration: 1.40,
            stage2Duration: 1.15,
            stage1Zone: QTETargetZone(start: 0.58, end: 0.85, greatStart: 0.70, greatEnd: 0.75),
            stage2Zone: QTETargetZone(start: 0.20, end: 0.45, greatStart: 0.28, greatEnd: 0.33),
            buttonPrompt: "Pahat Garam",
            allowTouchAnywhere: true,
            autoDismissDelay: 0.65
        )

        let qte = RockSaltQuickTimeEventNode(config: config)
        qte.position = CGPoint(x: size.width / 2, y: size.height / 2)
        qte.zPosition = 850
        hud.addChild(qte)
        activeQTE = qte

        qte.onComplete = { [weak self] isSuccess in
            guard let self else { return }
            if isSuccess {
                self.progress.hasRockSalt = true
                PrologueStore.shared.save()
                self.rockSaltNode?.removeFromParent()
                self.rockSaltNode = nil
                self.objective.text = self.progress.currentObjective(for: self.entry.region)
                self.startDialogue([
                    .init(speaker: "Arthur", text: "Berhasil memahat kristal garam batu murni! Berkilau seperti es di bawah sinar matahari lereng."),
                    .init(speaker: "Anneth", text: "Bagus sekali, Arthur! Endapan di dekat mulut tambang ini cukup untuk persediaan garam dapur kita."),
                    .init(speaker: "Arthur", text: "Lorong tambang di baliknya gelap gulita dan berbahaya. Sekarang ayo kita bawa rock salt ini kembali ke rumah Anneth di desa.")
                ]) { [weak self] in
                    self?.showAnnouncementBanner(
                        icon: "💎",
                        title: "Rock Salt Diperoleh!",
                        subtitle: "Bongkahan garam batu terkumpul. Kembali ke Rumah Anneth di Desa!"
                    )
                }
            } else {
                self.say("Pahatan meleset dari rekahan kristal garam! Coba ketuk saat jarum tepat di endapan garam.", duration: 3.5)
            }
        }

        qte.onDismiss = { [weak self] in
            if self?.activeQTE === qte {
                self?.activeQTE = nil
            }
        }

        qte.start()
    }

    // MARK: - Hollow Chase Minigame (Tap-Tap Horor)

    func startHollowChaseQTE() {
        guard activeQTE == nil else { return }
        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        let config = TapQuickTimeEventConfig(
            requiredTaps: 18,
            buttonPrompt: "LARI!",
            heading: "LARI DARI THE HOLLOW!",
            instruction: "DIA MENDEKAT DARI BALIK KABUT... KETUK CEPAT!",
            style: .hollowChase,
            allowTouchAnywhere: true,
            autoDismissDelay: 0.8,
            decayPerSecond: 0.12
        )

        let qte = TapQuickTimeEventNode(config: config)
        qte.position = CGPoint(x: size.width / 2, y: size.height / 2)
        qte.zPosition = 850
        hud.addChild(qte)
        activeQTE = qte

        qte.onComplete = { [weak self] isSuccess in
            guard let self else { return }
            if isSuccess {
                self.progress.encounteredHollow = true
                PrologueStore.shared.save()
                self.objective.text = self.progress.currentObjective(for: self.entry.region)
                if let h = self.hollowNode {
                    h.run(.sequence([
                        .group([.fadeOut(withDuration: 1.2), .moveBy(x: 50, y: 10, duration: 1.2)]),
                        .removeFromParent()
                    ]))
                }
                self.startDialogue([
                    .init(speaker: "Arthur", text: "Hah... hah... nyaris saja! Sosok bayangan tinggi itu terus membuntutiku di sela kabut!"),
                    .init(speaker: "The Hollow", text: "... ... ..."),
                    .init(speaker: "Arthur", text: "Hawa dingin menusuk tulang... matanya memancarkan cahaya merah redup di balik pepohonan!"),
                    .init(speaker: "Arthur", text: "Apakah itu... 'The Hollow' yang sering diceritakan dalam dongeng desa?!"),
                    .init(speaker: "Arthur", text: "Sosok itu memudar ke balik pohon. Aku harus segera kembali ke desa dan melaporkan ini ke Kakek Beryn!")
                ]) { [weak self] in
                    self?.showAnnouncementBanner(
                        icon: "⚠️",
                        title: "Lolos dari The Hollow!",
                        subtitle: "Arthur berhasil melarikan diri! Segera kembali ke desa menemui Kakek Beryn."
                    )
                }
            } else {
                self.say("Arthur: Hawa dingin mencekam membuat kakiku kaku! Cepat ketuk layar berulang kali untuk kabur!", duration: 4.0)
            }
        }

        qte.onDismiss = { [weak self] in
            if self?.activeQTE === qte {
                self?.activeQTE = nil
            }
        }

        qte.start()
    }


    // MARK: - Hollow 2-Stage Dial QTE (Mencekam)

    func startHollow2StageDialQTE() {
        guard activeQTE == nil else { return }
        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        let qte = HollowQuickTimeEventNode()
        qte.position = CGPoint(x: size.width / 2, y: size.height / 2)
        qte.zPosition = 870
        hud.addChild(qte)
        activeQTE = qte

        qte.onComplete = { [weak self] isSuccess in
            guard let self else { return }
            if isSuccess {
                self.progress.encounteredHollow = true
                PrologueStore.shared.save()
                self.objective.text = self.progress.currentObjective(for: self.entry.region)
                if let h = self.hollowNode {
                    h.run(.sequence([
                        .group([.fadeOut(withDuration: 1.2), .moveBy(x: 50, y: 10, duration: 1.2)]),
                        .removeFromParent()
                    ]))
                }
                self.startDialogue([
                    .init(speaker: "Arthur", text: "Hah... nyaris saja! Cakar bayangan The Hollow meleset beberapa jengkal dari tubuhku!"),
                    .init(speaker: "The Hollow", text: "... ... ..."),
                    .init(speaker: "Arthur", text: "Hawa dingin menusuk tulang... matanya memancarkan cahaya merah redup di balik kabut!"),
                    .init(speaker: "Arthur", text: "Sosok itu memudar ke balik pohon. Aku harus segera kembali ke desa dan melaporkan ini ke Kakek Beryn!")
                ]) { [weak self] in
                    self?.showAnnouncementBanner(
                        icon: "⚠️",
                        title: "Lolos dari Sergapan Hollow!",
                        subtitle: "Arthur berhasil meloloskan diri! Segera kembali ke desa menemui Kakek Beryn."
                    )
                }
            } else {
                self.say("Sergapan The Hollow mengenai Arthur! Ketuk tepat di zona kabut/mata merah saat jarum berputar!", duration: 4.0)
            }
        }

        qte.onDismiss = { [weak self] in
            if self?.activeQTE === qte {
                self?.activeQTE = nil
            }
        }

        qte.start()
    }

    // MARK: - Mud Escape Tap QTE (Lumpur)

    func startMudEscapeTapQTE(onComplete: ((Bool) -> Void)? = nil) {
        guard activeQTE == nil else { return }
        arthur.route.removeAll()
        stickVector = .zero
        stickKnob.position = stickCenter

        let qte = MudTapQuickTimeEventNode()
        qte.position = CGPoint(x: size.width / 2, y: size.height / 2)
        qte.zPosition = 860
        hud.addChild(qte)
        activeQTE = qte

        qte.onComplete = { isSuccess in
            onComplete?(isSuccess)
        }

        qte.onDismiss = { [weak self] in
            if self?.activeQTE === qte {
                self?.activeQTE = nil
            }
        }

        qte.start()
    }

    // MARK: - Elias Journal Discovery Minigame

    func presentEliasJournalDiscoveryMinigame() {
        guard let rootVC = view?.window?.rootViewController else {
            finishEliasBookDiscovery(openBookDirectly: false)
            return
        }
        
        var hostingController: UIHostingController<EliasJournalDiscoveryView>?
        let discoveryView = EliasJournalDiscoveryView(
            onComplete: { [weak self] in
                hostingController?.dismiss(animated: true) {
                    self?.finishEliasBookDiscovery(openBookDirectly: false)
                }
            },
            onDismiss: {
                hostingController?.dismiss(animated: true)
            },
            onOpenBook: { [weak self] in
                hostingController?.dismiss(animated: true) {
                    self?.finishEliasBookDiscovery(openBookDirectly: true)
                }
            }
        )
        
        let hc = UIHostingController(rootView: discoveryView)
        hc.modalPresentationStyle = .fullScreen
        hc.modalTransitionStyle = .crossDissolve
        hostingController = hc
        rootVC.present(hc, animated: true)
    }

    func finishEliasBookDiscovery(openBookDirectly: Bool) {
        HapticsService.shared.playNotification(.success)
        progress.hasEliasBook = true
        progress.hasBook = true
        progress.foundMarker = true
        PrologueStore.shared.save()
        eliasBookNode?.removeFromParent()
        eliasBookNode = nil
        objective.text = progress.currentObjective(for: entry.region)
        
        if openBookDirectly {
            openBook()
        } else {
            startDialogue([
                .init(speaker: "Arthur", text: "Tanah longsor mengikis lereng dan menyingkapkan jalinan akar pohon tua..."),
                .init(speaker: "Arthur", text: "Ada sesuatu yang terlindung di rongga akar... Sebuah buku bersampul kulit tua!"),
                .init(speaker: "Arthur", text: "Ini... Buku Catatan Elias! Peta kuno dan catatan jalur perbatasan tersimpan di dalamnya!"),
                .init(speaker: "Arthur", text: "Dengan buku ini, misteri di balik The Boundary bisa kita ungkap! Aku harus membicarakan ekspedisi ini dengan teman-teman.")
            ]) { [weak self] in
                self?.showUnlockCard(
                    title: "📖 BUKU ELIAS DITEMUKAN!",
                    body: "Buku Catatan Elias berhasil diselamatkan dari sela akar pohon tua! Peta perbatasan kini lengkap. Bicarakan rencana ekspedisi ke The Boundary bersama para sahabat."
                )
            }
        }
    }
}
