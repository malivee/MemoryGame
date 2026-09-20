// Penjelasan file: ShelfBalanceMinigame.swift
// Komponen Minigame "Event 1: Menolong Bu Mara" (Shelf Leg Balance & Precision Brick Wedge QTE).
// Konteks Cerita:
// Di halaman Bu Mara dekat sumur desa, rak kayu tempat menaruh pot tanah liat salah satu kakinya miring dan ambles ke tanah.
// Akibatnya, rak miring berbahaya dan pot-pot tanah liat di atasnya terancam merosot jatuh pecah!
// Mekanik Sesuai User:
// 1. CoreMotion Lift & Balance: Pemain memiringkan HP untuk MENGANGKAT kaki rak yang miring dan MENYEIMBANGKAN rak hingga lurus.
// 2. Dead by Daylight (DBD) Slider: Saat kaki rak terangkat dan rak seimbang, celah di bawah kaki rak terbuka dan slider batu bata bergerak.
// 3. Precision Tap: Pemain tap layar tepat saat bata di zona hijau untuk menyelipkan ganjalan di bawah kaki rak.
// 4. Fail State:
//    - Jika terlalu miring / lepas: Rak terguling, pot tanah liat meluncur jatuh pecah!
//    - Jika timing meleset: Kaki rak anjlok kembali ke tanah ambles dengan benturan keras.
// 5. Success State: Batu bata mengganjal kaki rak dengan kokoh, rak berdiri tegak sempurna dan pot aman.

import SpriteKit
import CoreMotion
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration

public struct ShelfBalanceConfig: Sendable {
    public var balanceTolerance: CGFloat // Batas kemiringan (radian) yang dianggap lurus/seimbang
    public var failAngle: CGFloat // Batas kemiringan maksimal sebelum pot jatuh pecah
    public var dbdSliderSpeed: CGFloat // Kecepatan ayunan slider batu bata
    public var dbdTargetStart: CGFloat // Posisi awal zona hijau (0.0 - 1.0)
    public var dbdTargetEnd: CGFloat // Posisi akhir zona hijau (0.0 - 1.0)
    public var headingText: String
    public var instructionText: String
    
    public init(
        balanceTolerance: CGFloat = 0.14,
        failAngle: CGFloat = 0.60,
        dbdSliderSpeed: CGFloat = 1.25,
        dbdTargetStart: CGFloat = 0.62,
        dbdTargetEnd: CGFloat = 0.78,
        headingText: String = "ANGKAT & SEIMBANGKAN RAK!",
        instructionText: String = "MIRINGKAN HP UNTUK MENGANGKAT KAKI RAK, LALU TAP SAAT BATA PAS MENGGANJAL!"
    ) {
        self.balanceTolerance = balanceTolerance
        self.failAngle = failAngle
        self.dbdSliderSpeed = dbdSliderSpeed
        self.dbdTargetStart = dbdTargetStart
        self.dbdTargetEnd = dbdTargetEnd
        self.headingText = headingText
        self.instructionText = instructionText
    }
}

// MARK: - SpriteKit Node

public final class ShelfBalanceMinigameNode: SKNode {
    
    public var onComplete: ((_ isSuccess: Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    
    private let config: ShelfBalanceConfig
    private var isRunning: Bool = false
    private var isCompleted: Bool = false
    private var isSuccess: Bool = false
    
    // Physics & State
    private let motionManager = CMMotionManager()
    private var currentTilt: CGFloat = 0.44 // Mulai dalam keadaan kaki kanan miring/ambles ke tanah
    private var simulatedTilt: CGFloat = 0.44 // Fallback untuk Simulator
    private var isBalanced: Bool = false
    
    // DBD Slider State
    private var sliderProgress: CGFloat = 0.0
    private var sliderDirection: CGFloat = 1.0
    private var lastUpdateTime: TimeInterval = 0
    
    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    
    // Ground & Mud Elements
    private let groundNode = SKNode()
    private let sunkenPitNode = SKShapeNode() // Lubang ambles tempat kaki kanan terperosok
    
    // Shelf Structure with Legs
    private let shelfPivotNode = SKNode() // Pivot rotasi di kaki kiri (tumpuan utama)
    private let shelfBodyNode = SKNode()
    private let leftLeg = SKShapeNode() // Kaki kiri (kokoh di tanah rata)
    private let rightLeg = SKShapeNode() // Kaki kanan (yang ambles dan miring)
    private let shelfPlank = SKShapeNode() // Papan rak tempat pot
    private let pot1 = SKNode() // Pot tanah liat Bu Mara 1
    private let pot2 = SKNode() // Pot tanah liat Bu Mara 2
    private let brickWedgeUnderLeg = SKShapeNode() // Bata yang berhasil diselipkan di bawah kaki kanan
    
    // Visual Height / Balance Level Indicator
    private let balanceIndicatorNode = SKNode()
    private let balanceBubble = SKShapeNode()
    
    // DBD QTE Track Elements
    private let dbdTrackNode = SKNode()
    private let dbdCursor = SKShapeNode() // Pecahan batu bata merah
    private let dbdTargetZone = SKShapeNode()
    private let dbdTrackWidth: CGFloat = 380
    
    // Header & Feedback UI
    private let headerBanner = SKNode()
    private let headingLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let legNoticeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    public init(config: ShelfBalanceConfig = ShelfBalanceConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = true
        zPosition = 800
        buildVisuals()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Setup
    
    private func buildVisuals() {
        addChild(container)
        
        // 1. Redup Layar (Suasana Halaman Pekarangan Bu Mara)
        backdrop.color = SKColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 0.90)
        backdrop.size = CGSize(width: 5000, height: 5000)
        backdrop.zPosition = -10
        container.addChild(backdrop)
        
        // 2. Header Banner Informasi
        headerBanner.position = CGPoint(x: 0, y: 145)
        headerBanner.zPosition = 10
        container.addChild(headerBanner)
        
        let bannerBg = SKShapeNode(rectOf: CGSize(width: 550, height: 62), cornerRadius: 14)
        bannerBg.fillColor = SKColor(red: 0.16, green: 0.11, blue: 0.08, alpha: 0.95)
        bannerBg.strokeColor = SKColor(red: 0.70, green: 0.45, blue: 0.28, alpha: 1.0)
        bannerBg.lineWidth = 3.0
        headerBanner.addChild(bannerBg)
        
        headingLabel.text = config.headingText
        headingLabel.fontSize = 20
        headingLabel.fontColor = SKColor(red: 0.98, green: 0.88, blue: 0.70, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: 5)
        headerBanner.addChild(headingLabel)
        
        instructionLabel.text = config.instructionText
        instructionLabel.fontSize = 10.5
        instructionLabel.fontColor = SKColor(red: 0.80, green: 0.72, blue: 0.65, alpha: 0.9)
        instructionLabel.position = CGPoint(x: 0, y: -16)
        headerBanner.addChild(instructionLabel)
        
        // 3. Tanah Pekarangan & Lubang Kaki Ambles
        buildGround()
        
        // 4. Struktur Rak Kayu Ber-Kaki & Pot Tanah Liat
        buildShelfWithLegs()
        
        // 5. Waterpass / Balance Level Indicator
        buildBalanceIndicator()
        
        // 6. Track DBD QTE (Slider Batu Bata di Celah Bawah Kaki Rak)
        buildDBDTrack()
        
        // 7. Label Status Feedback
        statusLabel.text = "MIRINGKAN HP KE ATAS UNTUK MENGANGKAT KAKI RAK!"
        statusLabel.fontSize = 13.5
        statusLabel.fontColor = SKColor(red: 0.95, green: 0.60, blue: 0.40, alpha: 1.0)
        statusLabel.position = CGPoint(x: 0, y: -135)
        statusLabel.zPosition = 8
        container.addChild(statusLabel)
        
        legNoticeLabel.text = "⚠️ KAKI KANAN AMBLES & MIRING!"
        legNoticeLabel.fontSize = 11
        legNoticeLabel.fontColor = SKColor(red: 0.95, green: 0.45, blue: 0.35, alpha: 0.9)
        legNoticeLabel.position = CGPoint(x: 120, y: -55)
        legNoticeLabel.zPosition = 8
        container.addChild(legNoticeLabel)
    }
    
    private func buildGround() {
        groundNode.position = CGPoint(x: 0, y: -50)
        groundNode.zPosition = 1
        container.addChild(groundNode)
        
        // Kontur tanah halaman: rata di kiri (kaki kokoh), tapi cekung ambles di kanan (kaki miring)
        let groundPath = CGMutablePath()
        groundPath.move(to: CGPoint(x: -280, y: -20))
        groundPath.addLine(to: CGPoint(x: 20, y: -20))
        // Cekungan ambles di bawah kaki kanan (x: 80 sampai 170)
        groundPath.addQuadCurve(to: CGPoint(x: 180, y: -42), control: CGPoint(x: 110, y: -48))
        groundPath.addLine(to: CGPoint(x: 280, y: -30))
        groundPath.addLine(to: CGPoint(x: 280, y: -80))
        groundPath.addLine(to: CGPoint(x: -280, y: -80))
        groundPath.closeSubpath()
        
        let groundShape = SKShapeNode(path: groundPath)
        groundShape.fillColor = SKColor(red: 0.24, green: 0.17, blue: 0.11, alpha: 1.0)
        groundShape.strokeColor = SKColor(red: 0.15, green: 0.10, blue: 0.06, alpha: 1.0)
        groundShape.lineWidth = 2.0
        groundNode.addChild(groundShape)
        
        // Celah tanah gembur/ambles di bawah kaki kanan
        sunkenPitNode.path = CGPath(ellipseIn: CGRect(x: 75, y: -46, width: 85, height: 22), transform: nil)
        sunkenPitNode.fillColor = SKColor(red: 0.14, green: 0.10, blue: 0.07, alpha: 0.95)
        sunkenPitNode.strokeColor = SKColor(red: 0.30, green: 0.20, blue: 0.12, alpha: 0.6)
        sunkenPitNode.lineWidth = 1.5
        groundNode.addChild(sunkenPitNode)
    }
    
    private func buildShelfWithLegs() {
        // Pivot rotasi berada di titik tumpu kaki kiri yang kokoh di tanah
        shelfPivotNode.position = CGPoint(x: -110, y: -70)
        shelfPivotNode.zPosition = 3
        container.addChild(shelfPivotNode)
        
        shelfBodyNode.position = CGPoint(x: 0, y: 0)
        shelfPivotNode.addChild(shelfBodyNode)
        
        let legW: CGFloat = 16
        let legH: CGFloat = 85
        let shelfSpan: CGFloat = 230 // Jarak antara kaki kiri dan kaki kanan
        
        // 1. KAKI KIRI (Kaki tumpuan yang kokoh)
        let leftLegRect = CGRect(x: -legW/2, y: 0, width: legW, height: legH)
        leftLeg.path = CGPath(roundedRect: leftLegRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        leftLeg.fillColor = SKColor(red: 0.38, green: 0.24, blue: 0.14, alpha: 1.0)
        leftLeg.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.07, alpha: 1.0)
        leftLeg.lineWidth = 2.0
        shelfBodyNode.addChild(leftLeg)
        
        // 2. KAKI KANAN (Kaki yang miring dan ambles ke tanah)
        let rightLegRect = CGRect(x: shelfSpan - legW/2, y: 0, width: legW, height: legH)
        rightLeg.path = CGPath(roundedRect: rightLegRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        rightLeg.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1.0)
        rightLeg.strokeColor = SKColor(red: 0.20, green: 0.11, blue: 0.06, alpha: 1.0)
        rightLeg.lineWidth = 2.0
        shelfBodyNode.addChild(rightLeg)
        
        // Palang kayu penguat horizontal di antara dua kaki
        let crossBarRect = CGRect(x: -legW/2, y: legH * 0.35, width: shelfSpan + legW, height: 12)
        let crossBar = SKShapeNode(rect: crossBarRect, cornerRadius: 2)
        crossBar.fillColor = SKColor(red: 0.34, green: 0.21, blue: 0.12, alpha: 1.0)
        crossBar.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.05, alpha: 1.0)
        crossBar.lineWidth = 1.5
        shelfBodyNode.addChild(crossBar)
        
        // 3. PAPAN RAK ATAS (Tempat pot tanah liat)
        let plankOverhang: CGFloat = 30
        let plankW = shelfSpan + (plankOverhang * 2)
        let plankH: CGFloat = 18
        let plankRect = CGRect(x: -plankOverhang, y: legH, width: plankW, height: plankH)
        shelfPlank.path = CGPath(roundedRect: plankRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        shelfPlank.fillColor = SKColor(red: 0.46, green: 0.29, blue: 0.17, alpha: 1.0) // Kayu jati desa
        shelfPlank.strokeColor = SKColor(red: 0.25, green: 0.15, blue: 0.08, alpha: 1.0)
        shelfPlank.lineWidth = 2.5
        shelfBodyNode.addChild(shelfPlank)
        
        // Serat serat kayu di papan
        for offset in [0.25, 0.55, 0.80] {
            let grain = SKShapeNode()
            let path = CGMutablePath()
            let startX = -plankOverhang + (plankW * offset) - 30
            path.move(to: CGPoint(x: startX, y: legH + plankH * 0.5))
            path.addQuadCurve(to: CGPoint(x: startX + 50, y: legH + plankH * 0.4), control: CGPoint(x: startX + 25, y: legH + plankH * 0.8))
            grain.path = path
            grain.strokeColor = SKColor(red: 0.30, green: 0.18, blue: 0.09, alpha: 0.5)
            grain.lineWidth = 1.5
            shelfBodyNode.addChild(grain)
        }
        
        // 4. POT TANAH LIAT BU MARA (Di atas papan rak)
        // Pot 1: Pot gerabah sedang di sebelah kiri
        pot1.position = CGPoint(x: 35, y: legH + plankH)
        pot1.addChild(createClayPot(width: 50, height: 60, color: SKColor(red: 0.72, green: 0.42, blue: 0.25, alpha: 1.0)))
        shelfBodyNode.addChild(pot1)
        
        // Pot 2: Pot gerabah besar di sebelah kanan (dekat kaki yang ambles)
        pot2.position = CGPoint(x: shelfSpan - 35, y: legH + plankH)
        pot2.addChild(createClayPot(width: 62, height: 72, color: SKColor(red: 0.68, green: 0.38, blue: 0.22, alpha: 1.0)))
        shelfBodyNode.addChild(pot2)
        
        // 5. BATU BATA MERAH (Pengganjal di bawah kaki kanan saat sukses)
        let brickRect = CGRect(x: shelfSpan - 22, y: -16, width: 44, height: 20)
        brickWedgeUnderLeg.path = CGPath(roundedRect: brickRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        brickWedgeUnderLeg.fillColor = SKColor(red: 0.75, green: 0.30, blue: 0.22, alpha: 1.0) // Merah bata
        brickWedgeUnderLeg.strokeColor = SKColor(red: 0.45, green: 0.15, blue: 0.10, alpha: 1.0)
        brickWedgeUnderLeg.lineWidth = 2.0
        brickWedgeUnderLeg.alpha = 0 // Tersembunyi sampai berhasil diganjal
        shelfBodyNode.addChild(brickWedgeUnderLeg)
    }
    
    private func createClayPot(width: CGFloat, height: CGFloat, color: SKColor) -> SKNode {
        let pot = SKNode()
        
        // Bayangan pot di atas papan
        let shadow = SKShapeNode(ellipseOf: CGSize(width: width * 0.9, height: 8))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.35)
        shadow.strokeColor = .clear
        pot.addChild(shadow)
        
        // Badan pot gerabah
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width * 0.28, y: 3))
        path.addQuadCurve(to: CGPoint(x: -width * 0.5, y: height * 0.45), control: CGPoint(x: -width * 0.6, y: height * 0.15))
        path.addQuadCurve(to: CGPoint(x: -width * 0.28, y: height * 0.85), control: CGPoint(x: -width * 0.45, y: height * 0.7))
        path.addLine(to: CGPoint(x: -width * 0.35, y: height))
        path.addLine(to: CGPoint(x: width * 0.35, y: height))
        path.addLine(to: CGPoint(x: width * 0.28, y: height * 0.85))
        path.addQuadCurve(to: CGPoint(x: width * 0.5, y: height * 0.45), control: CGPoint(x: width * 0.45, y: height * 0.7))
        path.addQuadCurve(to: CGPoint(x: width * 0.28, y: 3), control: CGPoint(x: width * 0.6, y: height * 0.15))
        path.closeSubpath()
        
        let body = SKShapeNode(path: path)
        body.fillColor = color
        body.strokeColor = SKColor(red: 0.40, green: 0.20, blue: 0.10, alpha: 1.0)
        body.lineWidth = 2.0
        pot.addChild(body)
        
        // Bibir pot
        let rim = SKShapeNode(ellipseOf: CGSize(width: width * 0.75, height: 10))
        rim.position = CGPoint(x: 0, y: height)
        rim.fillColor = SKColor(red: 0.58, green: 0.32, blue: 0.18, alpha: 1.0)
        rim.strokeColor = SKColor(red: 0.35, green: 0.18, blue: 0.08, alpha: 1.0)
        rim.lineWidth = 1.5
        pot.addChild(rim)
        
        // Garis hiasan motif gerabah melingkar
        let ringPath = CGMutablePath()
        ringPath.move(to: CGPoint(x: -width * 0.42, y: height * 0.5))
        ringPath.addQuadCurve(to: CGPoint(x: width * 0.42, y: height * 0.5), control: CGPoint(x: 0, y: height * 0.45))
        let ring = SKShapeNode(path: ringPath)
        ring.strokeColor = SKColor(red: 0.48, green: 0.25, blue: 0.12, alpha: 0.7)
        ring.lineWidth = 2.0
        pot.addChild(ring)
        
        return pot
    }
    
    private func buildBalanceIndicator() {
        // Waterpass / Level bar di tengah rak
        balanceIndicatorNode.position = CGPoint(x: 0, y: 55)
        balanceIndicatorNode.zPosition = 7
        container.addChild(balanceIndicatorNode)
        
        let tube = SKShapeNode(rectOf: CGSize(width: 140, height: 18), cornerRadius: 9)
        tube.fillColor = SKColor(red: 0.15, green: 0.18, blue: 0.15, alpha: 0.85)
        tube.strokeColor = SKColor(red: 0.45, green: 0.65, blue: 0.45, alpha: 0.8)
        tube.lineWidth = 1.5
        balanceIndicatorNode.addChild(tube)
        
        // Garis tengah seimbang (Target waterpass)
        let centerLine1 = SKShapeNode(rectOf: CGSize(width: 2, height: 18))
        centerLine1.position = CGPoint(x: -12, y: 0)
        centerLine1.fillColor = SKColor(red: 0.5, green: 0.85, blue: 0.5, alpha: 0.7)
        centerLine1.strokeColor = .clear
        balanceIndicatorNode.addChild(centerLine1)
        
        let centerLine2 = SKShapeNode(rectOf: CGSize(width: 2, height: 18))
        centerLine2.position = CGPoint(x: 12, y: 0)
        centerLine2.fillColor = SKColor(red: 0.5, green: 0.85, blue: 0.5, alpha: 0.7)
        centerLine2.strokeColor = .clear
        balanceIndicatorNode.addChild(centerLine2)
        
        // Gelembung penunjuk keseimbangan
        balanceBubble.path = CGPath(ellipseIn: CGRect(x: -8, y: -7, width: 16, height: 14), transform: nil)
        balanceBubble.fillColor = SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 0.9)
        balanceBubble.strokeColor = SKColor.white
        balanceBubble.lineWidth = 1.0
        balanceIndicatorNode.addChild(balanceBubble)
    }
    
    private func buildDBDTrack() {
        // Track diletakkan di bawah kaki kanan tempat batu bata akan diselipkan
        dbdTrackNode.position = CGPoint(x: 0, y: -100)
        dbdTrackNode.zPosition = 6
        container.addChild(dbdTrackNode)
        
        let trackBg = SKShapeNode(rectOf: CGSize(width: dbdTrackWidth, height: 18), cornerRadius: 9)
        trackBg.fillColor = SKColor(red: 0.12, green: 0.09, blue: 0.07, alpha: 0.92)
        trackBg.strokeColor = SKColor(red: 0.35, green: 0.28, blue: 0.22, alpha: 1.0)
        trackBg.lineWidth = 2.0
        dbdTrackNode.addChild(trackBg)
        
        let trackLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        trackLabel.text = "CELAH GANJALAN KAKI KANAN"
        trackLabel.fontSize = 9
        trackLabel.fontColor = SKColor(red: 0.75, green: 0.65, blue: 0.55, alpha: 0.75)
        trackLabel.position = CGPoint(x: 0, y: 14)
        dbdTrackNode.addChild(trackLabel)
        
        // Zona Hijau (Target Area Tempat Bata Pas Mengganjal Kaki)
        let zoneW = dbdTrackWidth * (config.dbdTargetEnd - config.dbdTargetStart)
        let zoneX = (-dbdTrackWidth / 2) + (dbdTrackWidth * config.dbdTargetStart) + (zoneW / 2)
        
        dbdTargetZone.path = CGPath(roundedRect: CGRect(x: -zoneW/2, y: -11, width: zoneW, height: 22), cornerWidth: 5, cornerHeight: 5, transform: nil)
        dbdTargetZone.fillColor = SKColor(red: 0.20, green: 0.82, blue: 0.38, alpha: 0.85) // Hijau zamrud
        dbdTargetZone.strokeColor = SKColor(red: 0.6, green: 1.0, blue: 0.7, alpha: 1.0)
        dbdTargetZone.lineWidth = 2.0
        dbdTargetZone.position = CGPoint(x: zoneX, y: 0)
        dbdTrackNode.addChild(dbdTargetZone)
        
        // Cursor Pecahan Batu Bata Merah
        let brickCursorPath = CGMutablePath()
        brickCursorPath.addRoundedRect(in: CGRect(x: -16, y: -16, width: 32, height: 32), cornerWidth: 4, cornerHeight: 4)
        dbdCursor.path = brickCursorPath
        dbdCursor.fillColor = SKColor(red: 0.75, green: 0.30, blue: 0.22, alpha: 1.0) // Merah bata
        dbdCursor.strokeColor = SKColor(red: 0.95, green: 0.60, blue: 0.45, alpha: 1.0)
        dbdCursor.lineWidth = 2.0
        dbdCursor.position = CGPoint(x: -dbdTrackWidth/2, y: 0)
        dbdTrackNode.addChild(dbdCursor)
        
        let brickDetail = SKShapeNode(rectOf: CGSize(width: 20, height: 2))
        brickDetail.fillColor = SKColor(red: 0.45, green: 0.15, blue: 0.10, alpha: 0.7)
        brickDetail.strokeColor = .clear
        dbdCursor.addChild(brickDetail)
        
        // Awalnya track redup sampai kaki rak berhasil diangkat & seimbang
        dbdTrackNode.alpha = 0.35
    }
    
    // MARK: - Logic & Update Loop
    
    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        lastUpdateTime = 0
        
        container.setScale(0.85)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.3),
            .scale(to: 1.0, duration: 0.4).applyTimingMode(.easeOut)
        ]))
        
        #if canImport(UIKit)
        HapticsService.shared.playSelection()
        #endif
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 60.0
            motionManager.startAccelerometerUpdates()
        }
        
        // Update Loop Keseimbangan
        let loop = SKAction.customAction(withDuration: 1000.0) { [weak self] _, elapsedTime in
            guard let self, self.isRunning else { return }
            let dt = self.lastUpdateTime == 0 ? 1.0/60.0 : min(0.05, Double(elapsedTime) - self.lastUpdateTime)
            self.lastUpdateTime = Double(elapsedTime)
            
            self.updatePhysics(deltaTime: dt)
        }
        run(loop, withKey: "shelfBalanceLoop")
        
        // Efek getaran goyah pada rak yang kakinya ambles
        shelfPivotNode.run(.repeatForever(.sequence([
            .moveBy(x: CGFloat.random(in: -0.6...0.6), y: CGFloat.random(in: -0.4...0.4), duration: 0.05),
            .moveTo(x: -110, duration: 0.05)
        ])), withKey: "wobblyShelfShake")
    }
    
    private func updatePhysics(deltaTime: TimeInterval) {
        // CoreMotion: Memiringkan HP mengangkat kaki rak yang ambles
        var targetTilt: CGFloat = currentTilt
        if let accel = motionManager.accelerometerData?.acceleration {
            // Pada mode landscape, kemiringan vertikal/angkat dibaca dari accel.y
            targetTilt = CGFloat(accel.y) * 1.55
        } else {
            // Fallback simulator (drag mouse kiri-kanan)
            targetTilt = simulatedTilt
        }
        
        // Interpolasi halus gerakan rak saat diangkat pemain
        currentTilt += (targetTilt - currentTilt) * CGFloat(deltaTime * 5.5)
        shelfPivotNode.zRotation = currentTilt
        
        // Update posisi gelembung waterpass
        let bubbleX = max(-55, min(55, currentTilt * 120))
        balanceBubble.position.x = bubbleX
        
        // Cek apakah rak sudah terangkat lurus (seimbang)
        let prevBalanced = isBalanced
        isBalanced = abs(currentTilt) <= config.balanceTolerance
        
        if isBalanced && !prevBalanced {
            // Kaki rak berhasil diangkat tegak dan seimbang!
            dbdTrackNode.run(.fadeAlpha(to: 1.0, duration: 0.2))
            statusLabel.text = "KAKI RAK TERANGKAT SEIMBANG! TAP SAAT BATA DI HIJAU!"
            statusLabel.fontColor = SKColor(red: 0.4, green: 0.92, blue: 0.55, alpha: 1.0)
            balanceBubble.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1.0)
            legNoticeLabel.text = "✨ CELAH GANJALAN TERBUKA!"
            legNoticeLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)
            
            #if canImport(UIKit)
            HapticsService.shared.playImpact(style: .medium)
            #endif
            
        } else if !isBalanced && prevBalanced {
            // Rak kembali miring
            dbdTrackNode.run(.fadeAlpha(to: 0.35, duration: 0.2))
            statusLabel.text = "ANGKAT KEMBALI KAKI RAK SAMPAI SEIMBANG!"
            statusLabel.fontColor = SKColor(red: 0.95, green: 0.45, blue: 0.35, alpha: 1.0)
            balanceBubble.fillColor = SKColor(red: 0.95, green: 0.45, blue: 0.35, alpha: 1.0)
            legNoticeLabel.text = "⚠️ KAKI KANAN AMBLES & MIRING!"
            legNoticeLabel.fontColor = SKColor(red: 0.95, green: 0.45, blue: 0.35, alpha: 0.9)
        }
        
        // Gerakkan DBD Slider Hanya Saat Rak Terangkat Seimbang
        if isBalanced {
            sliderProgress += (config.dbdSliderSpeed * CGFloat(deltaTime)) * sliderDirection
            
            if sliderProgress >= 1.0 {
                sliderProgress = 1.0
                sliderDirection = -1.0
            } else if sliderProgress <= 0.0 {
                sliderProgress = 0.0
                sliderDirection = 1.0
            }
            
            let xPos = (-dbdTrackWidth / 2) + (sliderProgress * dbdTrackWidth)
            dbdCursor.position.x = xPos
        }
        
        // Cek Fail State: Terlalu miring sehingga pot tergelincir jatuh
        if abs(currentTilt) > config.failAngle {
            handleFailShelfTippedOver()
        }
    }
    
    // MARK: - Touch Handling (Tap Ganjal & Simulator Drag)
    
    #if canImport(UIKit)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else { return }
        
        if isBalanced {
            evaluateDBDTap()
        } else {
            statusLabel.run(.sequence([
                .scale(to: 1.15, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]))
            HapticsService.shared.playImpact(style: .rigid)
        }
        
        updateSimulatedTilt(from: touches)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else { return }
        updateSimulatedTilt(from: touches)
    }
    
    private func updateSimulatedTilt(from touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        // Map sentuhan X simulator (-180 ke 180) ke kemiringan angkat
        simulatedTilt = (location.x / 180.0) * -1.0
    }
    #endif
    
    // MARK: - QTE Evaluation
    
    private func evaluateDBDTap() {
        if sliderProgress >= config.dbdTargetStart && sliderProgress <= config.dbdTargetEnd {
            handleSuccess()
        } else {
            handleFailMissedBrick()
        }
    }
    
    private func handleSuccess() {
        isRunning = false
        isCompleted = true
        isSuccess = true
        removeAction(forKey: "shelfBalanceLoop")
        shelfPivotNode.removeAction(forKey: "wobblyShelfShake")
        motionManager.stopAccelerometerUpdates()
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.success)
        #endif
        
        statusLabel.text = "KAKI RAK KOKOH TERGANJAL! POT AMAN!"
        statusLabel.fontColor = SKColor(red: 0.35, green: 0.95, blue: 0.65, alpha: 1.0)
        legNoticeLabel.text = "✨ RAK RATA & KOKOH!"
        legNoticeLabel.fontColor = SKColor(red: 0.5, green: 0.9, blue: 0.6, alpha: 1.0)
        
        dbdTargetZone.fillColor = SKColor.white
        
        // Animasi bata diselipkan kokoh di bawah kaki kanan
        brickWedgeUnderLeg.alpha = 1.0
        brickWedgeUnderLeg.setScale(0.2)
        brickWedgeUnderLeg.run(.scale(to: 1.0, duration: 0.25).applyTimingMode(.easeOut))
        
        // Rak terkunci di posisi lurus horizontal
        shelfPivotNode.run(.rotate(toAngle: 0.0, duration: 0.25).applyTimingMode(.easeOut))
        
        // Pendar rasa lega keemasan di rak
        let winGlow = SKShapeNode(rectOf: CGSize(width: 320, height: 120), cornerRadius: 10)
        winGlow.position = CGPoint(x: 115, y: 50)
        winGlow.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 0.35)
        winGlow.strokeColor = .clear
        winGlow.blendMode = .add
        winGlow.zPosition = 4
        shelfBodyNode.addChild(winGlow)
        winGlow.run(.sequence([
            .scale(to: 1.2, duration: 0.4).applyTimingMode(.easeOut),
            .fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))
        
        finishEvent()
    }
    
    private func handleFailShelfTippedOver() {
        guard isRunning else { return }
        isRunning = false
        isCompleted = true
        isSuccess = false
        removeAction(forKey: "shelfBalanceLoop")
        shelfPivotNode.removeAction(forKey: "wobblyShelfShake")
        motionManager.stopAccelerometerUpdates()
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        
        statusLabel.text = "RAK TERGULING! POT BU MARA PECAH!"
        statusLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        legNoticeLabel.text = "💥 POT MELUNCUR JATUH!"
        legNoticeLabel.fontColor = SKColor.red
        
        let dropDirection: CGFloat = currentTilt > 0 ? 1.0 : -1.0
        
        // Rak roboh miring ekstrim
        shelfPivotNode.run(.rotate(toAngle: dropDirection * 1.15, duration: 0.35).applyTimingMode(.easeIn))
        
        // Pot 1 dan Pot 2 tergelincir jatuh dari papan dan pecah
        pot1.run(.group([
            .moveBy(x: dropDirection * 120, y: -90, duration: 0.35).applyTimingMode(.easeIn),
            .rotate(byAngle: dropDirection * 1.5, duration: 0.35)
        ]))
        
        pot2.run(.group([
            .moveBy(x: dropDirection * 160, y: -100, duration: 0.35).applyTimingMode(.easeIn),
            .rotate(byAngle: dropDirection * 2.0, duration: 0.35)
        ]))
        
        // Pecahan keramik pot di tanah
        triggerPotShatter(at: CGPoint(x: 80, y: -65))
        
        flashRed()
        finishEvent()
    }
    
    private func handleFailMissedBrick() {
        guard isRunning else { return }
        isRunning = false
        isCompleted = true
        isSuccess = false
        removeAction(forKey: "shelfBalanceLoop")
        shelfPivotNode.removeAction(forKey: "wobblyShelfShake")
        motionManager.stopAccelerometerUpdates()
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.error)
        #endif
        
        statusLabel.text = "BATA MELESET! KAKI RAK ANJLOK KEMBALI!"
        statusLabel.fontColor = SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        dbdTargetZone.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.8)
        
        // Bata terpental
        dbdCursor.run(.sequence([
            .moveBy(x: 40, y: -50, duration: 0.25).applyTimingMode(.easeIn),
            .fadeOut(withDuration: 0.15)
        ]))
        
        // Kaki rak anjlok kembali ke dalam tanah ambles dengan hentakan keras
        shelfPivotNode.run(.sequence([
            .rotate(toAngle: 0.48, duration: 0.12).applyTimingMode(.easeIn),
            .run { [weak self] in
                // Pot terguncang hebat
                self?.pot1.run(.rotate(byAngle: -0.4, duration: 0.15))
                self?.pot2.run(.rotate(byAngle: 0.5, duration: 0.15))
            }
        ]))
        
        flashRed()
        finishEvent()
    }
    
    private func triggerPotShatter(at point: CGPoint) {
        for _ in 0..<12 {
            let shard = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 4...10), height: CGFloat.random(in: 3...7)))
            shard.fillColor = SKColor(red: 0.70, green: 0.40, blue: 0.24, alpha: 1.0)
            shard.strokeColor = SKColor(red: 0.40, green: 0.20, blue: 0.10, alpha: 1.0)
            shard.lineWidth = 1.0
            shard.position = point
            shard.zPosition = 8
            container.addChild(shard)
            
            let angle = CGFloat.random(in: .pi * 0.1 ... .pi * 0.9)
            let speed = CGFloat.random(in: 60...140)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            
            shard.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy - 30, duration: 0.4).applyTimingMode(.easeOut),
                    .rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.4),
                    .fadeOut(withDuration: 0.4)
                ]),
                .removeFromParent()
            ]))
        }
    }
    
    private func flashRed() {
        let flash = SKSpriteNode(color: SKColor.red.withAlphaComponent(0.35), size: CGSize(width: 5000, height: 5000))
        flash.zPosition = 100
        flash.blendMode = .add
        container.addChild(flash)
        flash.run(.sequence([
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }
    
    private func finishEvent() {
        onComplete?(isSuccess)
        
        run(.sequence([
            .wait(forDuration: 1.6),
            .group([
                .fadeOut(withDuration: 0.35),
                .scale(to: 0.8, duration: 0.35).applyTimingMode(.easeIn)
            ]),
            .run { [weak self] in
                self?.onDismiss?()
                self?.removeFromParent()
            }
        ]))
    }
    
    public func cancel() {
        isRunning = false
        motionManager.stopAccelerometerUpdates()
        removeAllActions()
        removeFromParent()
    }
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("Shelf Balance & Brick Wedge (Bu Mara)") {
    SpriteView(scene: {
        let scene = SKScene(size: CGSize(width: 844, height: 390)) // Landscape
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0)
        
        func spawn() {
            let qte = ShelfBalanceMinigameNode()
            qte.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
            qte.onDismiss = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { spawn() }
            }
            scene.addChild(qte)
            qte.start()
        }
        
        spawn()
        return scene
    }())
    .ignoresSafeArea()
}
#endif
