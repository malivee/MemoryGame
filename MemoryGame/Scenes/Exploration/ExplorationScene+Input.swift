import SpriteKit
import UIKit

// Input adapter. Gameplay rules live in Models and Systems.
extension ExplorationScene {
    func updateStick(_ touch: UITouch) {
        if arthur.isSitting { arthur.standUp() }
        if arthur.isSleeping {
            arthur.wakeUp()
            arthur.position = navigation.nearestOpen(to: CGPoint(x: 450, y: 78))
        }
        let point = touch.location(in: hud)
        let center = stickCenter
        let dx = point.x - center.x, dy = point.y - center.y
        let length = max(1, hypot(dx, dy))
        let magnitude = min(1, length / 40)
        stickVector = CGVector(dx: dx / length * magnitude, dy: dy / length * magnitude)
        stickKnob.position = CGPoint(x: center.x + stickVector.dx * 30, y: center.y + stickVector.dy * 30)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Jika QTE sedang aktif, alihkan sentuhan ke QTE
        if let qte = activeQTE as? RockSaltQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if let qte = activeQTE as? QuickTimeEventNode {
            qte.handleTap()
            return
        }
        if let qte = activeQTE as? HollowQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if let qte = activeQTE as? ClassicTapQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if let qte = activeQTE as? MudTapQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if let qte = activeQTE as? HollowChaseTapQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if let qte = activeQTE as? TapQuickTimeEventNode {
            qte.handleTap()
            return
        }
        if activeQTE != nil {
            return
        }

        let hudPoint = touch.location(in: hud)
        let names = Set(hud.nodes(at: hudPoint).compactMap(\.name))
        if handleDebugWarpTouch(hudPoint: hudPoint, names: names) { return }
        let isDebugHit = names.contains("debugWarp") || (hud.childNode(withName: "debugWarp").map { hypot(hudPoint.x - $0.position.x, hudPoint.y - $0.position.y) < 55 } ?? false)
        if isDebugHit { toggleDebugWarp(); return }
        if names.contains("unlockCard") || names.contains("unlockCardDismiss") {
            dismissUnlockCard()
            return
        }
        guard !enteringMemory, !readingBook, bag == nil else { return }
        if dialoguePanel != nil { advanceDialogue(); return }
        if names.contains("photo") { returnToPhoto(); return }
        if names.contains("bag") { openBag(); return }
        if names.contains("hudInteract") { interact(); return }

        // Jika Arthur sedang duduk atau tidur, bangun/berdiri saat layar disentuh
        if arthur.isSitting {
            arthur.standUp()
            clearNearbyInteraction()
        }
        if arthur.isSleeping {
            arthur.wakeUp()
            arthur.position = navigation.nearestOpen(to: CGPoint(x: 450, y: 78))
            clearNearbyInteraction()
        }

        let worldPoint = touch.location(in: world)
        let worldNodes = world.nodes(at: worldPoint)
        let worldNames = Set(worldNodes.compactMap { $0.namedAncestor(prefix: "contextInteract") ?? $0.name })

        if worldNames.contains("contextInteract") {
            interact()
            return
        }

        // Cek jika ketukan berada di dekat target interaksi aktif (jarak toleran 75pt)
        if let target = nearbyInteraction {
            let targetPos: CGPoint
            switch target {
            case .book: targetPos = bookPickupNode?.position ?? (level.book ?? .zero)
            case .friend(let f): targetPos = friendNodes[f]?.position ?? (level.friends[f] ?? .zero)
            case .marker: targetPos = markerNode?.position ?? (level.marker ?? .zero)
            case .sitStump(let p): targetPos = p
            case .standUp, .wakeUp: targetPos = arthur.position
            case .sleepBed: targetPos = houseBedSpot
            case .rockSalt: targetPos = rockSaltNode?.position ?? (level.marker ?? .zero)
            case .darkMineEntrance: targetPos = mineShaftNode?.position ?? CGPoint(x: 330, y: 395)
            case .herbalPlant: targetPos = herbalNode?.position ?? (level.marker ?? .zero)
            case .boundaryStone: targetPos = boundaryStoneNodes.first?.position ?? CGPoint(x: 730, y: 120)
            case .hollowEncounter: targetPos = hollowNode?.position ?? (level.gathering ?? .zero)
            case .firewood: targetPos = firewoodNode?.position ?? (level.marker ?? .zero)
            case .landslideEliasBook: targetPos = eliasBookNode?.position ?? (level.book ?? .zero)
            case .boundaryTreeMarker: targetPos = boundaryTreeNode?.position ?? (level.marker ?? .zero)
            case .deepWoodsGate: targetPos = deepWoodsGateNode?.position ?? (level.exit ?? .zero)
            }
            if distance(worldPoint, targetPos) < 75 || (nearbyPrompt != nil && distance(worldPoint, nearbyPrompt!.position) < 75) {
                interact()
                return
            }
        }

        // Cek jika mengetuk langsung pada bantalan batang kayu atau kasur
        if entry.region == .house {
            if distance(worldPoint, houseBedSpot) < 65 && distance(arthur.position, houseBedSpot) <= 90 {
                nearbyInteraction = .sleepBed
                interact()
                return
            }
            for stump in houseStumpCushions {
                if distance(worldPoint, stump) < 36 && distance(arthur.position, stump) <= 85 {
                    nearbyInteraction = .sitStump(stump)
                    interact()
                    return
                }
            }
        }

        // Cek jika mengetuk langsung pada karakter teman, buku, atau penanda saat Arthur berada di dekatnya
        for friend in FriendID.allCases {
            if let fNode = friendNodes[friend] {
                if worldNodes.contains(where: { $0 == fNode || $0.inParentHierarchy(fNode) }) {
                    if distance(arthur.position, fNode.position) <= 95 {
                        nearbyInteraction = .friend(friend)
                        interact()
                        return
                    }
                }
            }
        }
        if let bookNode = bookPickupNode, !progress.hasBook {
            if worldNodes.contains(where: { $0 == bookNode || $0.inParentHierarchy(bookNode) }) {
                if distance(arthur.position, bookNode.position) <= 95 {
                    nearbyInteraction = .book
                    interact()
                    return
                }
            }
        }
        if let mNode = markerNode, progress.installed(.oldPath) {
            if worldNodes.contains(where: { $0 == mNode || $0.inParentHierarchy(mNode) }) {
                if distance(arthur.position, mNode.position) <= 95 {
                    nearbyInteraction = .marker
                    interact()
                    return
                }
            }
        }

        if distance(hudPoint, stickCenter) < 70 {
            stickTouch = touch; arthur.route.removeAll(); updateStick(touch); return
        }
        let destination = worldPoint
        guard level.mapBounds.contains(destination) else { return }
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
