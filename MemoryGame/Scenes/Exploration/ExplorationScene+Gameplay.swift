import SpriteKit
import UIKit

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
        objective.text = progress.objective
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
        worldLocations.contains(location) && progress.installed(location)
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
}
