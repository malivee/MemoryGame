// Mengendalikan dunia desa, karakter, kamera, dan akses wilayah.
// Progres cerita tersimpan menentukan tahap kabut yang ditampilkan.

import SpriteKit

final class VillagePrototypeScene: SKScene {
    let mapNode = SKNode()
    let hud = SKNode()

    let actor = MemoryCharacter(
        title: "Arthur",
        color: SKColor(
            red: 0.49,
            green: 0.59,
            blue: 0.35,
            alpha: 1
        )
    )

    // Host menentukan scene tujuan ketika pemain kembali.
    var onExit: (() -> Void)?
    var isLeaving = false

    var access: VillageAccess = .opening
    var storyProgress: PrologueProgress?

    let storyNPCs = SKNode()
    var activeStoryStep: StoryProgressionStep?
    var dialogueIndex: Int?
    var isWellConversation = false
    var wellResidentIndex = 0

    let storyPanel = SKNode()
    let rackInteraction = SKNode()


    weak var activeQTE: TapQuickTimeEventNode?

    // Navigasi memakai tahap yang sama dengan visual kabut.
    var navigation: VillageNavigation {
        VillageNavigation(stage: access)
    }

    var route: [CGPoint] = []
    var overview = false
    var showBounds = false
    var lastTime: TimeInterval = 0

    var stickTouch: UITouch?
    var stick = CGVector.zero
    var knob = SKShapeNode(circleOfRadius: 18)

    var stickCenter: CGPoint {
        CGPoint(x: 88, y: 88)
    }

    var info = SKLabelNode()
    var stageLabel = SKLabelNode()
    var hintUntil: TimeInterval = 0

    var collisionOverlay = SKNode()

    // Node khusus untuk kabut bertahap.
    let memoryFog = VillageFogNode()

    override func didMove(to view: SKView) {
        guard mapNode.parent == nil else { return }

        if storyProgress == nil {
            storyProgress = PrologueStore.shared.progress
        }

        backgroundColor = SKColor(
            red: 0.10,
            green: 0.16,
            blue: 0.13,
            alpha: 1
        )

        addChild(mapNode)
        addChild(hud)
        hud.zPosition = 1000

        if let storyProgress {
            access = StoryProgression.villageAccess(
                for: storyProgress
            )
        }

        buildMap()
        buildHUD()
        actor.position = VillageMap.spawn

        refreshStory()
        updateCamera(immediate: true)
    }

    func setAccess(_ value: VillageAccess) {
        // Dialog yang tidak mengubah tahap tidak perlu
        // membangun ulang kabut atau mereset kamera.
        guard access != value else { return }

        access = value
        route = []
        stick = .zero
        stickTouch = nil
        knob.position = stickCenter

        if !navigation.walkable(actor.position) {
            actor.position = VillageMap.spawn
        }

        stageLabel.text = "Desa di lembah"

        updateMemoryFog()
        updateCollisionOverlay()
        updateCamera(immediate: true)
    }

    // Zoom tetap mengikuti ExplorationScene bawaan proyek.
    var worldScale: CGFloat {
        max(1.45, min(1.85, size.height / 250))
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard mapNode.parent != nil else { return }

        stickTouch = nil
        stick = .zero

        buildHUD()
        renderStoryDialogue()
        updateCamera(immediate: true)
    }

    func updateCamera(
        dt: CGFloat = 0,
        immediate: Bool = false
    ) {
        let bounds = VillageMap.bounds

        let scale = overview
            ? min(
                size.width / bounds.width,
                size.height / bounds.height
            ) * 0.94
            : worldScale

        mapNode.setScale(scale)

        func offset(
            _ actor: CGFloat,
            _ extent: CGFloat,
            _ screen: CGFloat
        ) -> CGFloat {
            let length = extent * scale

            if overview || length <= screen {
                return (screen - length) / 2
            }

            return min(
                0,
                max(
                    screen - length,
                    screen / 2 - actor * scale
                )
            )
        }

        let target = CGPoint(
            x: offset(
                actor.position.x,
                bounds.width,
                size.width
            ),
            y: offset(
                actor.position.y,
                bounds.height,
                size.height
            )
        )

        let blend: CGFloat = immediate
            ? 1
            : min(1, dt * 7.5)

        mapNode.position.x +=
            (target.x - mapNode.position.x) * blend

        mapNode.position.y +=
            (target.y - mapNode.position.y) * blend
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = CGFloat(
            min(
                0.04,
                max(
                    0,
                    lastTime == 0
                        ? 0
                        : currentTime - lastTime
                )
            )
        )

        lastTime = currentTime

        if !overview &&
            dialogueIndex == nil &&
            activeQTE == nil {

            var delta = CGVector(
                dx: stick.dx * 140 * dt,
                dy: stick.dy * 140 * dt
            )

            if hypot(stick.dx, stick.dy) < 0.05,
               let target = route.first {

                let dx = target.x - actor.position.x
                let dy = target.y - actor.position.y
                let distance = hypot(dx, dy)

                if distance < 5 {
                    route.removeFirst()
                } else {
                    let amount = min(distance, 140 * dt)

                    delta = CGVector(
                        dx: dx / distance * amount,
                        dy: dy / distance * amount
                    )
                }
            }

            let next = navigation.moved(
                from: actor.position,
                by: delta
            )

            if hypot(delta.dx, delta.dy) > 0.01 {
                let movedDistance = hypot(
                    next.x - actor.position.x,
                    next.y - actor.position.y
                )

                if movedDistance < 0.01 {
                    route = []
                }
            }

            actor.applyMovement(
                dx: next.x - actor.position.x,
                dy: next.y - actor.position.y,
                dt: dt
            )

            actor.position = next
            actor.zPosition = 20

            updateCamera(dt: dt)
        }

        if currentTime > hintUntil {
            if !rackInteraction.isHidden,
               hypot(
                    rackInteraction.position.x - actor.position.x,
                    rackInteraction.position.y - actor.position.y
               ) < 150 {

                info.text = "Ketuk rak miring untuk membantu Bu Mara"
                return
            }

            let nearest = VillageMap.landmarks.min {
                hypot(
                    $0.approach.x - actor.position.x,
                    $0.approach.y - actor.position.y
                ) <
                hypot(
                    $1.approach.x - actor.position.x,
                    $1.approach.y - actor.position.y
                )
            }

            info.text = activeStoryStep?.title ?? nearest.map {
                let distance = hypot(
                    $0.approach.x - actor.position.x,
                    $0.approach.y - actor.position.y
                )

                return distance < 110
                    ? $0.name
                    : "Jelajahi jalan desa · ketuk tanah atau gunakan stik"
            }
        }
    }

    func hint(_ text: String) {
        info.text = text
        hintUntil = lastTime + 4
    }
}
