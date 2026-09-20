// Penjelasan file: ItemSortingMinigame.swift
// Komponen Minigame Naratif berbasis Drag & Drop (Membantu Anneth Menyortir Umbi).
// Visual Upgrade V4 (Landscape Optimized & AAA Storybook):
// - Layout Kiri-ke-Kanan: Keranjang (Kiri) ➔ Baskom (Tengah) ➔ Kain (Kanan).
// - Objek diperbesar menyesuaikan aspek rasio landscape agar sangat "clickable" dan "juicy".
// - Hitbox detection disempurnakan menggunakan konversi koordinat Node lokal (Sangat akurat).
// - Meja papan horizontal super lebar dengan shadow dan serat kayu dinamis.
// - UI Cinematic Dialog memanjang di bagian bawah layar ala Visual Novel.

import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration

public struct ItemSortingConfig: Sendable {
    public var requiredItems: Int
    public var headingText: String
    public var instructionText: String
    public var allowTouchAnywhere: Bool
    public var autoDismissDelay: TimeInterval
    
    public init(
        requiredItems: Int = 4,
        headingText: String = "TUGAS DARI ANNETH",
        instructionText: String = "AMBIL UMBI KOTOR ➔ CUCI DI BASKOM ➔ TARUH DI KAIN",
        allowTouchAnywhere: Bool = true,
        autoDismissDelay: TimeInterval = 1.2
    ) {
        self.requiredItems = requiredItems
        self.headingText = headingText
        self.instructionText = instructionText
        self.allowTouchAnywhere = allowTouchAnywhere
        self.autoDismissDelay = autoDismissDelay
    }
}

// MARK: - SpriteKit Node

public final class ItemSortingMinigameNode: SKNode {
    
    public var onProgress: ((_ current: Int, _ total: Int) -> Void)?
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    
    private let config: ItemSortingConfig
    private var isRunning: Bool = false
    private var isCompleted: Bool = false
    
    private var sortedCount: Int = 0
    
    // Drag State
    private var activeTuber: SKNode?
    private var isActiveTuberWashed: Bool = false
    private var originalTuberPosition: CGPoint = .zero
    
    // Hierarchy nodes
    private let container = SKNode()
    private let workspaceNode = SKNode()
    
    // Parent Nodes untuk tiap zona
    private let basketNode = SKNode()
    private let basinNode = SKNode()
    private let clothNode = SKNode()
    
    // Hitbox Area
    private let dirtyBasketZone = SKShapeNode()
    private let washBasinZone = SKShapeNode()
    private let cleanClothZone = SKShapeNode()
    
    private let activeItemsNode = SKNode()
    private let sortedItemsNode = SKNode()
    
    private let cinematicDialogBox = SKNode()
    private let dialogNameTag = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let dialogText = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    
    private let headerBanner = SKNode()
    private let headingLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    
    public init(config: ItemSortingConfig = ItemSortingConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = config.allowTouchAnywhere
        zPosition = 800
        buildVisuals()
        spawnNewTuber()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Setup (Landscape Full-Screen)
    
    private func buildVisuals() {
        addChild(container)
        
        // 1. Latar Meja Kayu (Horizontal Layout)
        container.addChild(workspaceNode)
        workspaceNode.zPosition = 1
        
        let bg = SKSpriteNode(color: SKColor(red: 0.08, green: 0.05, blue: 0.03, alpha: 0.98), size: CGSize(width: 5000, height: 5000))
        bg.zPosition = -10
        workspaceNode.addChild(bg)
        
        // Papan Meja Memanjang
        let boardW: CGFloat = 1600
        let plankH: CGFloat = 100
        for i in -5...5 {
            let plankY: CGFloat = CGFloat(i) * 102
            let plankRect = CGRect(x: -boardW/2, y: -plankH/2, width: boardW, height: plankH)
            let plank = SKShapeNode(rect: plankRect)
            
            let isDarker = i % 2 == 0
            plank.fillColor = isDarker ? SKColor(red: 0.28, green: 0.18, blue: 0.10, alpha: 1.0) : SKColor(red: 0.32, green: 0.22, blue: 0.14, alpha: 1.0)
            plank.strokeColor = SKColor(red: 0.1, green: 0.05, blue: 0.02, alpha: 0.8)
            plank.lineWidth = 4.0
            plank.position = CGPoint(x: 0, y: plankY)
            
            for _ in 0...4 {
                let grain = SKShapeNode()
                let path = CGMutablePath()
                let startX = CGFloat.random(in: -boardW/2...0)
                path.move(to: CGPoint(x: startX, y: CGFloat.random(in: -plankH/3...plankH/3)))
                path.addQuadCurve(to: CGPoint(x: startX + CGFloat.random(in: 200...500), y: CGFloat.random(in: -plankH/3...plankH/3)),
                                  control: CGPoint(x: startX + 200, y: CGFloat.random(in: -plankH/2...plankH/2)))
                grain.path = path
                grain.strokeColor = SKColor(red: 0.15, green: 0.08, blue: 0.04, alpha: 0.4)
                grain.lineWidth = CGFloat.random(in: 2...6)
                plank.addChild(grain)
            }
            workspaceNode.addChild(plank)
        }
        
        // 2. Banner Instruksi (Atas Tengah)
        headerBanner.position = CGPoint(x: 0, y: 155) // Disesuaikan untuk landscape safe-area
        headerBanner.zPosition = 20
        container.addChild(headerBanner)
        
        let bannerBg = SKShapeNode(rectOf: CGSize(width: 450, height: 60), cornerRadius: 15)
        bannerBg.fillColor = SKColor(red: 0.12, green: 0.08, blue: 0.06, alpha: 0.95)
        bannerBg.strokeColor = SKColor(red: 0.75, green: 0.55, blue: 0.35, alpha: 1.0)
        bannerBg.lineWidth = 3.0
        
        let bannerShadow = SKShapeNode(rectOf: CGSize(width: 450, height: 60), cornerRadius: 15)
        bannerShadow.fillColor = SKColor.black.withAlphaComponent(0.6)
        bannerShadow.strokeColor = .clear
        bannerShadow.position = CGPoint(x: 0, y: -6)
        headerBanner.addChild(bannerShadow)
        headerBanner.addChild(bannerBg)
        
        headingLabel.text = config.headingText
        headingLabel.fontSize = 18
        headingLabel.fontColor = SKColor(red: 0.95, green: 0.85, blue: 0.65, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: 4)
        headerBanner.addChild(headingLabel)
        
        instructionLabel.text = config.instructionText
        instructionLabel.fontSize = 11
        instructionLabel.fontColor = SKColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 0.9)
        instructionLabel.position = CGPoint(x: 0, y: -16)
        headerBanner.addChild(instructionLabel)
        
        // --- ZONA KERJA KIRI-KANAN ---
        let areaOffset: CGFloat = 280 // Jarak rentang antar objek di landscape
        
        // 3. ZONA KIRI (Keranjang Anyaman Umbi Kotor)
        basketNode.position = CGPoint(x: -areaOffset, y: -20)
        basketNode.zPosition = 2
        workspaceNode.addChild(basketNode)
        
        let basketW: CGFloat = 190
        let basketH: CGFloat = 160
        let basketShadow = SKShapeNode(ellipseOf: CGSize(width: basketW + 10, height: basketH + 10))
        basketShadow.fillColor = SKColor.black.withAlphaComponent(0.5)
        basketShadow.strokeColor = .clear
        basketShadow.position = CGPoint(x: -5, y: -10)
        basketNode.addChild(basketShadow)
        
        let basketBase = SKShapeNode(ellipseOf: CGSize(width: basketW, height: basketH))
        basketBase.fillColor = SKColor(red: 0.55, green: 0.40, blue: 0.25, alpha: 1.0)
        basketBase.strokeColor = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1.0)
        basketBase.lineWidth = 8.0
        basketNode.addChild(basketBase)
        
        for i in -5...5 {
            let line1 = SKShapeNode()
            let p1 = CGMutablePath()
            p1.move(to: CGPoint(x: i * 16, y: -65))
            p1.addLine(to: CGPoint(x: i * 16, y: 65))
            line1.path = p1
            line1.strokeColor = SKColor(red: 0.40, green: 0.28, blue: 0.15, alpha: 0.8)
            line1.lineWidth = 4.0
            basketNode.addChild(line1)
            
            let line2 = SKShapeNode()
            let p2 = CGMutablePath()
            p2.move(to: CGPoint(x: -80, y: i * 14))
            p2.addLine(to: CGPoint(x: 80, y: i * 14))
            line2.path = p2
            line2.strokeColor = SKColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 0.8)
            line2.lineWidth = 4.0
            basketNode.addChild(line2)
        }
        
        dirtyBasketZone.path = CGPath(ellipseIn: CGRect(x: -basketW/2, y: -basketH/2, width: basketW, height: basketH), transform: nil)
        dirtyBasketZone.fillColor = .clear
        dirtyBasketZone.strokeColor = .clear
        basketNode.addChild(dirtyBasketZone)
        
        // 4. ZONA TENGAH (Baskom Tanah Liat Raksasa)
        basinNode.position = CGPoint(x: 0, y: 10)
        basinNode.zPosition = 2
        workspaceNode.addChild(basinNode)
        
        let basinW: CGFloat = 260
        let basinH: CGFloat = 200
        let basinShadow = SKShapeNode(ellipseOf: CGSize(width: basinW + 20, height: basinH + 20))
        basinShadow.fillColor = SKColor.black.withAlphaComponent(0.4)
        basinShadow.strokeColor = .clear
        basinShadow.position = CGPoint(x: 0, y: -15)
        basinNode.addChild(basinShadow)
        
        let basinRim = SKShapeNode(ellipseOf: CGSize(width: basinW, height: basinH))
        basinRim.fillColor = SKColor(red: 0.45, green: 0.30, blue: 0.20, alpha: 1.0)
        basinRim.strokeColor = SKColor(red: 0.25, green: 0.15, blue: 0.10, alpha: 1.0)
        basinRim.lineWidth = 14.0
        basinNode.addChild(basinRim)
        
        let basinInner = SKShapeNode(ellipseOf: CGSize(width: basinW - 35, height: basinH - 35))
        basinInner.fillColor = SKColor(red: 0.15, green: 0.10, blue: 0.08, alpha: 1.0)
        basinInner.strokeColor = .clear
        basinInner.position = CGPoint(x: 0, y: -6)
        basinNode.addChild(basinInner)
        
        let basinWater = SKShapeNode(ellipseOf: CGSize(width: basinW - 40, height: basinH - 40))
        basinWater.fillColor = SKColor(red: 0.15, green: 0.50, blue: 0.75, alpha: 0.9)
        basinWater.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 0.6)
        basinWater.lineWidth = 3.0
        basinNode.addChild(basinWater)
        
        let waterGlow = SKShapeNode(ellipseOf: CGSize(width: basinW - 70, height: basinH - 70))
        waterGlow.fillColor = SKColor(red: 0.4, green: 0.85, blue: 1.0, alpha: 0.25)
        waterGlow.strokeColor = .clear
        waterGlow.blendMode = .add
        waterGlow.position = CGPoint(x: -5, y: 5)
        basinNode.addChild(waterGlow)
        waterGlow.run(.repeatForever(.sequence([
            .scale(to: 1.1, duration: 2.0).applyTimingMode(.easeInEaseOut),
            .scale(to: 0.95, duration: 2.0).applyTimingMode(.easeInEaseOut)
        ])))
        
        washBasinZone.path = CGPath(ellipseIn: CGRect(x: -basinW/2, y: -basinH/2, width: basinW, height: basinH), transform: nil)
        washBasinZone.fillColor = .clear
        washBasinZone.strokeColor = .clear
        basinNode.addChild(washBasinZone)
        
        // 5. ZONA KANAN (Kain Linen Bersih yang Lebar)
        clothNode.position = CGPoint(x: areaOffset, y: -20)
        clothNode.zPosition = 2
        workspaceNode.addChild(clothNode)
        
        let clothW: CGFloat = 200
        let clothH: CGFloat = 160
        let clothRect = CGRect(x: -clothW/2, y: -clothH/2, width: clothW, height: clothH)
        
        let clothShadow = SKShapeNode(rect: clothRect, cornerRadius: 10)
        clothShadow.fillColor = SKColor.black.withAlphaComponent(0.3)
        clothShadow.strokeColor = .clear
        clothShadow.position = CGPoint(x: 4, y: -6)
        clothShadow.zRotation = 0.05
        clothNode.addChild(clothShadow)
        
        let clothShape = SKShapeNode(rect: clothRect, cornerRadius: 10)
        clothShape.fillColor = SKColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1.0)
        clothShape.strokeColor = SKColor(red: 0.80, green: 0.75, blue: 0.70, alpha: 1.0)
        clothShape.lineWidth = 3.0
        clothShape.zRotation = 0.05
        clothNode.addChild(clothShape)
        
        // Jahitan
        let stitchRect = CGRect(x: -(clothW/2) + 8, y: -(clothH/2) + 8, width: clothW - 16, height: clothH - 16)
        let stitch = SKShapeNode(rect: stitchRect, cornerRadius: 6)
        let dashed = stitch.path?.copy(dashingWithPhase: 0, lengths: [8, 6])
        stitch.path = dashed
        stitch.strokeColor = SKColor(red: 0.75, green: 0.65, blue: 0.55, alpha: 0.8)
        stitch.lineWidth = 2.0
        stitch.zRotation = 0.05
        clothNode.addChild(stitch)
        
        // Lipatan
        let fold = SKShapeNode()
        let foldPath = CGMutablePath()
        foldPath.move(to: CGPoint(x: -40, y: clothH/2 - 5))
        foldPath.addQuadCurve(to: CGPoint(x: 10, y: -clothH/2 + 5), control: CGPoint(x: 0, y: 0))
        fold.path = foldPath
        fold.strokeColor = SKColor(red: 0.85, green: 0.80, blue: 0.75, alpha: 0.7)
        fold.lineWidth = 4.0
        fold.zRotation = 0.05
        clothNode.addChild(fold)
        
        cleanClothZone.path = CGPath(roundedRect: clothRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        cleanClothZone.fillColor = .clear
        cleanClothZone.strokeColor = .clear
        cleanClothZone.zRotation = 0.05
        clothNode.addChild(cleanClothZone)
        
        // 6. Layer Penempatan Umbi
        sortedItemsNode.zPosition = 3
        activeItemsNode.zPosition = 4
        workspaceNode.addChild(sortedItemsNode)
        workspaceNode.addChild(activeItemsNode)
        
        // 7. Cinematic Subtitle Dialog Box (Melebar di bawah)
        buildCinematicDialogueBox()
    }
    
    private func buildCinematicDialogueBox() {
        cinematicDialogBox.zPosition = 30
        cinematicDialogBox.position = CGPoint(x: 0, y: -250) // Muncul dari bawah
        cinematicDialogBox.alpha = 0
        
        let boxW: CGFloat = 600
        let boxH: CGFloat = 80
        
        let boxBg = SKShapeNode(rectOf: CGSize(width: boxW, height: boxH), cornerRadius: 8)
        boxBg.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.06, alpha: 0.95)
        boxBg.strokeColor = SKColor(red: 0.95, green: 0.35, blue: 0.40, alpha: 1.0)
        boxBg.lineWidth = 2.5
        
        let boxShadow = SKShapeNode(rectOf: CGSize(width: boxW, height: boxH), cornerRadius: 8)
        boxShadow.fillColor = SKColor.black.withAlphaComponent(0.6)
        boxShadow.strokeColor = .clear
        boxShadow.position = CGPoint(x: 0, y: -8)
        cinematicDialogBox.addChild(boxShadow)
        cinematicDialogBox.addChild(boxBg)
        
        let nameTagBg = SKShapeNode(rectOf: CGSize(width: 120, height: 30), cornerRadius: 6)
        nameTagBg.fillColor = SKColor(red: 0.95, green: 0.35, blue: 0.40, alpha: 1.0)
        nameTagBg.strokeColor = .clear
        nameTagBg.position = CGPoint(x: -220, y: 40)
        cinematicDialogBox.addChild(nameTagBg)
        
        dialogNameTag.text = "ANNETH"
        dialogNameTag.fontSize = 15
        dialogNameTag.fontColor = .white
        dialogNameTag.verticalAlignmentMode = .center
        dialogNameTag.position = CGPoint(x: -220, y: 40)
        cinematicDialogBox.addChild(dialogNameTag)
        
        dialogText.fontSize = 16
        dialogText.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0)
        dialogText.verticalAlignmentMode = .center
        dialogText.horizontalAlignmentMode = .left
        dialogText.position = CGPoint(x: -270, y: -5)
        cinematicDialogBox.addChild(dialogText)
        
        container.addChild(cinematicDialogBox)
    }
    
    // MARK: - Tuber Creators
    
    private func createTuberVisual() -> CGPath {
        let path = CGMutablePath()
        let w = CGFloat.random(in: 32...40) // Ukuran besar memuaskan
        let h = CGFloat.random(in: 45...55)
        
        path.move(to: CGPoint(x: 0, y: h/2))
        path.addQuadCurve(to: CGPoint(x: w/2, y: 0), control: CGPoint(x: w/2 + 10, y: h/4))
        path.addQuadCurve(to: CGPoint(x: 0, y: -h/2), control: CGPoint(x: w/2 + 5, y: -h/4))
        path.addQuadCurve(to: CGPoint(x: -w/2, y: 0), control: CGPoint(x: -w/2 - 8, y: -h/4))
        path.addQuadCurve(to: CGPoint(x: 0, y: h/2), control: CGPoint(x: -w/2 - 4, y: h/4))
        
        return path
    }
    
    private func spawnNewTuber() {
        guard sortedCount < config.requiredItems else { return }
        isActiveTuberWashed = false
        
        let tuberNode = SKNode()
        let shape = SKShapeNode(path: createTuberVisual())
        
        shape.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        shape.strokeColor = SKColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1.0)
        shape.lineWidth = 3.0
        shape.name = "tuberShape"
        tuberNode.addChild(shape)
        
        let shadow = SKShapeNode(path: shape.path!)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 4, y: -6)
        shadow.zPosition = -1
        tuberNode.addChild(shadow)
        
        let dirtLayer = SKNode()
        dirtLayer.name = "dirtLayer"
        for _ in 0...7 {
            let dirt = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.0))
            dirt.fillColor = SKColor(red: 0.18, green: 0.10, blue: 0.05, alpha: 0.95)
            dirt.strokeColor = .clear
            dirt.position = CGPoint(x: CGFloat.random(in: -15...15), y: CGFloat.random(in: -22...22))
            dirtLayer.addChild(dirt)
        }
        tuberNode.addChild(dirtLayer)
        
        let glint = SKShapeNode(ellipseOf: CGSize(width: 14, height: 7))
        glint.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.8)
        glint.strokeColor = .clear
        glint.zRotation = .pi / 4
        glint.position = CGPoint(x: -10, y: 15)
        glint.alpha = 0
        glint.name = "glint"
        tuberNode.addChild(glint)
        
        // Spawn di Keranjang Kiri (-280, -20)
        let spawnPos = CGPoint(x: basketNode.position.x + CGFloat.random(in: -30...30),
                               y: basketNode.position.y + CGFloat.random(in: -30...30))
        tuberNode.position = spawnPos
        tuberNode.zRotation = CGFloat.random(in: -0.8...0.8)
        tuberNode.name = "draggableTuber"
        
        activeItemsNode.addChild(tuberNode)
        
        tuberNode.setScale(0)
        tuberNode.run(.sequence([
            .scale(to: 1.15, duration: 0.2).applyTimingMode(.easeOut),
            .scale(to: 1.0, duration: 0.15).applyTimingMode(.easeIn)
        ]))
    }
    
    // MARK: - Lifecycle & Touch Handling
    
    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        container.setScale(0.85)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.3),
            .scale(to: 1.0, duration: 0.4).applyTimingMode(.easeOut)
        ]))
        #if canImport(UIKit)
        HapticsService.shared.playSelection()
        #endif
    }
    
    #if canImport(UIKit)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first else { return }
        let location = touch.location(in: activeItemsNode)
        
        if let touchedNode = activeItemsNode.nodes(at: location).first(where: { $0.name == "draggableTuber" }) {
            activeTuber = touchedNode
            originalTuberPosition = touchedNode.position
            
            touchedNode.run(.group([
                .scale(to: 1.4, duration: 0.15).applyTimingMode(.easeOut),
                .fadeAlpha(to: 0.95, duration: 0.1)
            ]))
            
            HapticsService.shared.playImpact(style: .light)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first, let tuber = activeTuber else { return }
        tuber.position = touch.location(in: activeItemsNode)
        
        // Akurasi Hitbox: Konversi lokasi sentuhan ke koordinat lokal Basin Node
        let locInBasin = touch.location(in: basinNode)
        if !isActiveTuberWashed && washBasinZone.path?.contains(locInBasin) == true {
            washActiveTuber()
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first, let tuber = activeTuber else { return }
        
        let dropLocInCloth = touch.location(in: clothNode)
        let dropLocInBasin = touch.location(in: basinNode)
        let dropLocInBasket = touch.location(in: basketNode)
        let absoluteDropLoc = touch.location(in: workspaceNode)
        
        tuber.run(.group([
            .scale(to: 1.0, duration: 0.15).applyTimingMode(.easeOut),
            .fadeAlpha(to: 1.0, duration: 0.15)
        ]))
        
        // Logic Evaluasi Menggunakan Koordinat Node Lokal (Sangat Akurat)
        if cleanClothZone.path?.contains(dropLocInCloth) == true {
            if isActiveTuberWashed {
                handleSuccessDrop(tuber: tuber, dropLoc: absoluteDropLoc)
            } else {
                handleAnnethScold(message: "Cuci dulu umbinya! Jangan kotori kainku!", tuber: tuber)
            }
        } else if washBasinZone.path?.contains(dropLocInBasin) == true {
            handleAnnethScold(message: "Jangan direndam di situ! Nanti umbinya membusuk!", tuber: tuber)
        } else if dirtyBasketZone.path?.contains(dropLocInBasket) == true {
            tuber.run(.move(to: originalTuberPosition, duration: 0.25).applyTimingMode(.easeOut))
        } else {
            handleAnnethScold(message: "Taruh di atas kain, Arthur! Jangan berantakan!", tuber: tuber)
        }
        
        activeTuber = nil
    }
    #endif
    
    // MARK: - Game Logic
    
    private func washActiveTuber() {
        guard let tuber = activeTuber else { return }
        isActiveTuberWashed = true
        
        #if canImport(UIKit)
        HapticsService.shared.playImpact(style: .medium)
        #endif
        
        if let dirt = tuber.childNode(withName: "dirtLayer") {
            dirt.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        }
        
        if let shape = tuber.childNode(withName: "tuberShape") as? SKShapeNode {
            shape.fillColor = SKColor(red: 0.88, green: 0.72, blue: 0.48, alpha: 1.0)
            shape.strokeColor = SKColor(red: 0.60, green: 0.40, blue: 0.22, alpha: 1.0)
        }
        
        tuber.childNode(withName: "glint")?.run(.fadeIn(withDuration: 0.2))
        
        // Efek cipratan air megah
        for _ in 0...8 {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...10))
            bubble.strokeColor = SKColor(red: 0.6, green: 0.95, blue: 1.0, alpha: 0.9)
            bubble.fillColor = SKColor(red: 0.8, green: 0.98, blue: 1.0, alpha: 0.5)
            bubble.lineWidth = 1.5
            bubble.position = tuber.position
            activeItemsNode.addChild(bubble)
            
            let dx = CGFloat.random(in: -45...45)
            let dy = CGFloat.random(in: 15...55)
            
            bubble.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.5).applyTimingMode(.easeOut),
                    .scale(to: 0.1, duration: 0.5),
                    .fadeOut(withDuration: 0.5)
                ]),
                .removeFromParent()
            ]))
        }
    }
    
    private func handleSuccessDrop(tuber: SKNode, dropLoc: CGPoint) {
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.success)
        #endif
        
        tuber.removeFromParent()
        sortedItemsNode.addChild(tuber)
        tuber.position = dropLoc
        tuber.name = "sortedTuber"
        
        sortedCount += 1
        onProgress?(sortedCount, config.requiredItems)
        
        clothNode.run(.sequence([
            .moveBy(x: 0, y: -4, duration: 0.05),
            .moveBy(x: 0, y: 4, duration: 0.05)
        ]))
        
        if sortedCount >= config.requiredItems {
            finishEvent()
        } else {
            spawnNewTuber()
        }
    }
    
    private func handleAnnethScold(message: String, tuber: SKNode) {
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        
        isActiveTuberWashed = false
        tuber.removeAllChildren()
        
        let shape = SKShapeNode(path: createTuberVisual())
        shape.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        shape.strokeColor = SKColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1.0)
        shape.lineWidth = 3.0
        shape.name = "tuberShape"
        tuber.addChild(shape)
        
        let shadow = SKShapeNode(path: shape.path!)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 4, y: -6)
        shadow.zPosition = -1
        tuber.addChild(shadow)
        
        let dirtLayer = SKNode()
        dirtLayer.name = "dirtLayer"
        for _ in 0...7 {
            let dirt = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.0))
            dirt.fillColor = SKColor(red: 0.18, green: 0.10, blue: 0.05, alpha: 0.95)
            dirt.strokeColor = .clear
            dirt.position = CGPoint(x: CGFloat.random(in: -15...15), y: CGFloat.random(in: -22...22))
            dirtLayer.addChild(dirt)
        }
        tuber.addChild(dirtLayer)
        
        let glint = SKShapeNode(ellipseOf: CGSize(width: 14, height: 7))
        glint.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.8)
        glint.strokeColor = .clear
        glint.zRotation = .pi / 4
        glint.position = CGPoint(x: -10, y: 15)
        glint.alpha = 0
        glint.name = "glint"
        tuber.addChild(glint)
        
        tuber.run(.sequence([
            .move(to: originalTuberPosition, duration: 0.35).applyTimingMode(.easeOut),
            .scale(to: 1.25, duration: 0.1),
            .scale(to: 1.0, duration: 0.1)
        ]))
        
        cinematicDialogBox.removeAllActions()
        dialogText.text = "\"\(message)\""
        
        let slideUp = SKAction.group([
            .move(to: CGPoint(x: 0, y: -120), duration: 0.35).applyTimingMode(.easeOut),
            .fadeAlpha(to: 1.0, duration: 0.25)
        ])
        let wait = SKAction.wait(forDuration: 3.0)
        let slideDown = SKAction.group([
            .move(to: CGPoint(x: 0, y: -250), duration: 0.3).applyTimingMode(.easeIn),
            .fadeOut(withDuration: 0.2)
        ])
        cinematicDialogBox.run(.sequence([slideUp, wait, slideDown]))
        
        container.run(.sequence([
            .moveBy(x: -8, y: 0, duration: 0.04),
            .moveBy(x: 16, y: 0, duration: 0.08),
            .moveBy(x: -8, y: 0, duration: 0.04)
        ]))
    }
    
    private func finishEvent() {
        isCompleted = true
        isRunning = false
        
        headingLabel.text = "MEJA BERSIH!"
        headingLabel.fontColor = SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 1.0)
        instructionLabel.text = "Anneth puas dengan kerapian kerjamu."
        
        let winGlow = SKShapeNode(rectOf: CGSize(width: 1600, height: 800))
        winGlow.fillColor = SKColor(red: 0.9, green: 1.0, blue: 0.7, alpha: 0.35)
        winGlow.strokeColor = .clear
        winGlow.blendMode = .add
        winGlow.zPosition = 25
        container.addChild(winGlow)
        winGlow.run(.sequence([
            .scale(to: 1.2, duration: 0.4).applyTimingMode(.easeOut),
            .fadeOut(withDuration: 0.5),
            .removeFromParent()
        ]))
        
        onComplete?(true)
        
        if config.autoDismissDelay > 0 {
            run(.sequence([
                .wait(forDuration: config.autoDismissDelay + 0.3),
                .group([
                    .fadeOut(withDuration: 0.4),
                    .scale(to: 0.9, duration: 0.4).applyTimingMode(.easeIn)
                ]),
                .run { [weak self] in
                    self?.onDismiss?()
                    self?.removeFromParent()
                }
            ]))
        }
    }
    
    public func cancel() {
        isRunning = false
        removeAllActions()
        removeFromParent()
    }
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("Item Sorting Naratif (Landscape) V4") {
    SpriteView(scene: {
        // Mode Landscape (misal iPhone 14 Pro Max Landscape: 852x393, kita buat 844x390 standar)
        let scene = SKScene(size: CGSize(width: 844, height: 390))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.05, green: 0.03, blue: 0.02, alpha: 1.0)
        
        func spawn() {
            let minigame = ItemSortingMinigameNode(config: ItemSortingConfig(requiredItems: 4))
            minigame.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
            minigame.onDismiss = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { spawn() }
            }
            scene.addChild(minigame)
            minigame.start()
        }
        
        spawn()
        return scene
    }())
    .ignoresSafeArea()
}
#endif
