// Penjelasan file: ExplorationScene.swift
// Mengendalikan permainan di dalam kenangan: membangun dunia, HUD, karakter, dan patroli.
// Menangani stik, ketuk untuk berjalan, dialog, interaksi misi, teman pengikut, dan kembali ke foto.
// Memakai PrologueLevel untuk peta, MemoryNavigation untuk gerak, serta PrologueStore untuk progres.

import SpriteKit
import UIKit

final class ExplorationScene: SKScene {
    var enteringMemory = true
    let entry: MemoryPiece
    let worldLocations: Set<MemoryPiece>
    var progress: PrologueProgress { PrologueStore.shared.progress }
    var level: PrologueLevel!
    var navigation: MemoryNavigation!
    let stage = SKNode()
    let world = SKNode()
    let hud = SKNode()
    let arthur = MemoryCharacter(title: "Arthur", color: SKColor(red: 0.49, green: 0.59, blue: 0.35, alpha: 1))
    var companions: [MemoryCharacter] = []
    var patrols: [MemoryPatrol] = []
    var checkpoint = CGPoint.zero
    var lastTime: TimeInterval = 0
    var followerTimer: CGFloat = 0
    var warningCooldown: CGFloat = 0
    var catchGrace: CGFloat = 0
    var watched = false
    var dialogue: [StoryLine] = []
    var dialogueIndex = 0
    var dialogueCompletion: (() -> Void)?
    var dialoguePanel: SKNode?
    var toast: SKLabelNode?
    var stickTouch: UITouch?
    var stickVector = CGVector.zero
    var stickCenter: CGPoint { CGPoint(x: 88, y: 88) }
    var stickKnob = SKShapeNode(circleOfRadius: 18)
    var objective = SKLabelNode()
    var suspicionLabel = SKLabelNode()
    var bag: BagOverlay?
    var readingBook = false
    var bookPickupNode: SKNode?
    var friendNodes: [FriendID: MemoryCharacter] = [:]
    var markerNode: SKNode?
    var nearbyInteraction: MemoryInteractionTarget?
    var nearbyPrompt: SKNode?
    var hudInteractButton: SKShapeNode?
    var hudInteractLabel: SKLabelNode?
    var echoesVillagePassed = false
    var sceneryNode: SKSpriteNode?
    var debugMenuNode: SKNode?
    weak var activeQTE: SKNode?

    let houseStumpCushions: [CGPoint] = [
        CGPoint(x: 305, y: 335), // Atas karpet
        CGPoint(x: 465, y: 212), // Kanan karpet
        CGPoint(x: 295, y: 91),  // Bawah karpet
        CGPoint(x: 151, y: 222)  // Kiri karpet
    ]
    let houseBedSpot = CGPoint(x: 580, y: 78)
    var stumpNodes: [SKNode] = []
    var bedNode: SKNode?
    var rockSaltNode: SKNode?
    var mineShaftNode: SKNode?
    var herbalNode: SKNode?
    var boundaryStoneNodes: [SKNode] = []
    var hollowNode: SKNode?
    var firewoodNode: SKNode?
    var eliasBookNode: SKNode?
    var boundaryTreeNode: SKNode?
    var deepWoodsGateNode: SKNode?

    init(size: CGSize, entry: MemoryPiece, worldLocations: Set<MemoryPiece>) {
        self.entry = entry
        // Satu kunjungan hanya membuka satu wilayah, tanpa pilihan dunia kedua.
        self.worldLocations = Set(worldLocations.filter { $0.region == entry.region })
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    var worldScale: CGFloat {
        // Skala kamera zoom-in dekat bergaya Carto (~15% tinggi layar untuk karakter)
        return max(1.45, min(1.85, size.height / 250))
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

}

enum MemoryInteractionTarget: Equatable {
    case book
    case friend(FriendID)
    case marker
    case sitStump(CGPoint)
    case standUp
    case sleepBed
    case wakeUp
    // Map B (Pinggiran / Zona Transisi)
    case rockSalt
    case darkMineEntrance
    case herbalPlant
    case boundaryStone
    case hollowEncounter
    case firewood
    case landslideEliasBook
    case boundaryTreeMarker
    case deepWoodsGate
}
