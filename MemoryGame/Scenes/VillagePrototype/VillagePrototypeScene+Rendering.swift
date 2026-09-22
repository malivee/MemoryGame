// Membuat tampilan desa, HUD, penanda interaksi,
// serta menghubungkan scene dengan node kabut.

import SpriteKit
import UIKit

extension VillagePrototypeScene {
    @discardableResult
    func label(
        _ text: String,
        at point: CGPoint,
        size: CGFloat,
        on parent: SKNode,
        color: SKColor = .white
    ) -> SKLabelNode {
        parent.storyLabel(
            text,
            at: point,
            size: size,
            color: color
        )
    }

    func button(
        _ text: String,
        name: String,
        at point: CGPoint,
        width: CGFloat = 140
    ) {
        let node = hud.storyButton(
            text,
            name: name,
            at: point,
            width: width
        )

        node.fillColor = SKColor(
            red: 0.12,
            green: 0.16,
            blue: 0.14,
            alpha: 0.88
        )

        node.strokeColor = SKColor(
            red: 0.88,
            green: 0.80,
            blue: 0.55,
            alpha: 0.5
        )
    }

    func buildMap() {
        // Aset asli digunakan utuh; ukuran dunia mengikuti rasio gambar.
        let terrain = SKSpriteNode(texture: SKTexture(imageNamed: "DesaArthur"))
        terrain.anchorPoint = .zero
        terrain.size = VillageMap.bounds.size
        terrain.zPosition = -10
        mapNode.addChild(terrain)

        for place in VillageMap.landmarks {
            label(
                place.name,
                at: CGPoint(
                    x: place.rect.midX,
                    y: place.rect.maxY + 35
                ),
                size: 12,
                on: mapNode,
                color: SKColor(white: 1, alpha: 0.4)
            )
        }

        label(
            "SUMUR",
            at: CGPoint(x: VillageMap.well.midX, y: VillageMap.well.maxY + 18),
            size: 14,
            on: mapNode
        )

        label(
            "Sungai kecil",
            at: VillageMap.point(390, 718),
            size: 16,
            on: mapNode
        )

        label(
            "Ke pinggiran hutan →",
            at: VillageMap.point(1490, 135),
            size: 14,
            on: mapNode
        )

        // NPC dekoratif. NPC cerita aktif dibangun oleh refreshStory().
        for (name, position, color) in [
            (
                "Kakek",
                VillageMap.grandpa,
                SKColor.brown
            ),
            (
                "Bu Mara",
                VillageMap.mara,
                SKColor(
                    red: 0.67,
                    green: 0.42,
                    blue: 0.33,
                    alpha: 1
                )
            ),
            (
                "Keneth",
                VillageMap.approach(for: "barn"),
                SKColor.orange
            ),
            (
                "Anneth",
                VillageMap.approach(for: "anneth"),
                SKColor.systemTeal
            ),
            (
                "Roland",
                VillageMap.approach(for: "pen"),
                SKColor.systemYellow
            )
        ] {
            if storyProgress == nil || name == "Kakek" {
                let node = MemoryCharacter(
                    title: name,
                    color: color
                )

                node.position = position
                node.zPosition = 12

                mapNode.addChild(node)
            }
        }

        mapNode.addChild(storyNPCs)
        storyNPCs.zPosition = 25
        storyNPCs.isHidden = false

        // Penanda QTE rak Bu Mara yang sudah ada.
        let rackPrompt = SKShapeNode(circleOfRadius: 15)

        rackPrompt.fillColor = SKColor(
            red: 0.30,
            green: 0.55,
            blue: 0.28,
            alpha: 0.95
        )

        rackPrompt.strokeColor = .white
        rackPrompt.lineWidth = 2
        rackPrompt.name = "mara-rack"

        rackPrompt.storyLabel(
            "!",
            at: .zero,
            size: 17,
            color: .white
        )

        rackInteraction.addChild(rackPrompt)
        rackInteraction.position = VillageMap.rack
        rackInteraction.zPosition = 28

        mapNode.addChild(rackInteraction)

        actor.zPosition = 20
        mapNode.addChild(actor)

        // Kabut menutupi dunia tetapi tetap berada di bawah HUD.
        memoryFog.zPosition = 30
        mapNode.addChild(memoryFog)
        updateMemoryFog()

        mapNode.addChild(collisionOverlay)
        collisionOverlay.zPosition = 40
    }

    // Efek dan cache kabut ditangani VillageFogNode.
    func updateMemoryFog() {
        memoryFog.setAccess(access)
    }

    func buildHUD() {
        // HUD memakai koordinat layar agar tidak ikut zoom kamera.
        hud.removeAllChildren()

        let width = min(size.width * 0.52, 460)

        let pill = SKShapeNode(
            rectOf: CGSize(width: width, height: 36),
            cornerRadius: 18
        )

        pill.position = CGPoint(
            x: size.width / 2,
            y: size.height - 34
        )

        pill.fillColor = SKColor(
            red: 0.12,
            green: 0.16,
            blue: 0.14,
            alpha: 0.88
        )

        pill.strokeColor = SKColor(
            red: 0.88,
            green: 0.80,
            blue: 0.55,
            alpha: 0.45
        )

        pill.lineWidth = 1.2
        hud.addChild(pill)

        stageLabel = label(
            "Desa di lembah",
            at: pill.position,
            size: 13,
            on: hud,
            color: SKColor(
                red: 0.98,
                green: 0.94,
                blue: 0.82,
                alpha: 1
            )
        )

        if onExit != nil {
            button(
                "Kembali ke foto",
                name: "exitVillage",
                at: CGPoint(
                    x: size.width - 92,
                    y: size.height - 34
                ),
                width: 145
            )
        }

        button(
            overview ? "Jelajahi" : "Peta",
            name: "overview",
            at: CGPoint(
                x: size.width - 65,
                y: 55
            ),
            width: 90
        )

        info = label(
            "Geser stik atau ketuk tanah untuk bergerak",
            at: CGPoint(
                x: size.width / 2,
                y: 18
            ),
            size: 11,
            on: hud,
            color: SKColor(white: 1, alpha: 0.5)
        )

        info.preferredMaxLayoutWidth = max(
            100,
            size.width - 230
        )
        info.numberOfLines = 2

        let base = SKShapeNode(circleOfRadius: 44)
        base.position = stickCenter
        base.fillColor = SKColor(white: 0.08, alpha: 0.45)
        base.strokeColor = SKColor(white: 1, alpha: 0.28)
        base.lineWidth = 1.5

        hud.addChild(base)

        knob.position = stickCenter
        knob.fillColor = SKColor(white: 1, alpha: 0.45)
        knob.strokeColor = .clear

        hud.addChild(knob)
    }

    func updateCollisionOverlay() {
        collisionOverlay.removeAllChildren()

        guard showBounds else { return }

        for rect in VillageMap.solids {
            let shape = SKShapeNode(rect: rect)
            shape.fillColor = SKColor.red.withAlphaComponent(0.12)
            shape.strokeColor = .systemRed

            collisionOverlay.addChild(shape)
        }

        if access != .wholeVillage {
            for x in stride(
                from: CGFloat(36),
                to: VillageMap.bounds.maxX - 24,
                by: 48
            ) {
                for y in stride(
                    from: CGFloat(36),
                    to: VillageMap.bounds.maxY - 24,
                    by: 48
                ) where !VillageMap.accessible(
                    CGPoint(x: x, y: y),
                    stage: access
                ) {
                    let dot = SKShapeNode(circleOfRadius: 3)
                    dot.position = CGPoint(x: x, y: y)
                    dot.fillColor = .systemOrange
                    dot.strokeColor = .clear

                    collisionOverlay.addChild(dot)
                }
            }
        }
    }
}
