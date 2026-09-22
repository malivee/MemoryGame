// Penjelasan file: SeedSortingMinigame.swift
// Komponen Minigame Fisik "Tampah" (Winnowing Basket) menggunakan Sensor CoreMotion.
// Mekanik:
// 1. Pemain memiringkan dan menggoyangkan HP untuk memisahkan biji gandum.
// 2. Goyangan menghasilkan "Sorting Progress".
// 3. Semakin tinggi progres, biji hitam (busuk) akan terlempar ke pinggir, dan biji bagus mengumpul di tengah.
// 4. Komponen mandiri (Self-contained physics), tidak merusak gravitasi Scene utama.

import SpriteKit
import CoreMotion
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Configuration

public struct SeedSortingConfig: Sendable {
    public var goodSeedCount: Int
    public var badSeedCount: Int
    public var basketRadius: CGFloat
    public var shakeThresholdTotal: CGFloat // Total akumulasi goyangan untuk menang
    public var headingText: String
    public var instructionText: String
    
    public init(
        goodSeedCount: Int = 50,
        badSeedCount: Int = 20,
        basketRadius: CGFloat = 135,
        shakeThresholdTotal: CGFloat = 120.0, // Durasi diperpanjang agar sortir terasa nyata & berirama
        headingText: String = "PISAHKAN GANDUM",
        instructionText: String = "GOYANGKAN PERANGKAT BERIRAMA UNTUK MENYORTIR BIJI"
    ) {
        self.goodSeedCount = goodSeedCount
        self.badSeedCount = badSeedCount
        self.basketRadius = basketRadius
        self.shakeThresholdTotal = shakeThresholdTotal
        self.headingText = headingText
        self.instructionText = instructionText
    }
}

// MARK: - SpriteKit Node

public final class SeedSortingMinigameNode: SKNode {
    
    public var onProgress: ((_ progress: CGFloat) -> Void)?
    public var onComplete: (() -> Void)?
    public var onDismiss: (() -> Void)?
    
    private let config: SeedSortingConfig
    private var isRunning: Bool = false
    private var isCompleted: Bool = false
    
    private var currentProgress: CGFloat = 0.0
    private var accumulatedShake: CGFloat = 0.0
    private var lastAcceleration: CMAcceleration?
    
    private let motionManager = CMMotionManager()
    
    // Fallback for Simulator (Touch to Tilt & Shake)
    private var simulatedTilt: CGVector = .zero
    private var lastTouchLocation: CGPoint?
    private var simulatedShakeIntensity: CGFloat = 0.0
    
    // Hierarchy nodes
    private let container = SKNode()
    private let backdrop = SKSpriteNode()
    private let basketNode = SKNode()
    private let progressRing = SKShapeNode()
    
    // Visual Target Guides
    private let centerGoldGuide = SKShapeNode()
    private let outerRimGuide = SKShapeNode()
    
    private let headingLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    
    // Arrays untuk referensi sorting
    private var goodSeeds: [SKNode] = []
    private var badSeeds: [SKNode] = []
    
    public init(config: SeedSortingConfig = SeedSortingConfig()) {
        self.config = config
        super.init()
        isUserInteractionEnabled = true
        zPosition = 800
        buildVisuals()
        setupPhysicsBoundary()
        spawnSeeds()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Geometry & Visual Generators
    
    private func createSeedPath() -> CGPath {
        let path = CGMutablePath()
        let w: CGFloat = 4.5
        let h: CGFloat = 10.0
        // Bentuk biji gandum (kapsul meruncing)
        path.move(to: CGPoint(x: 0, y: h/2))
        path.addQuadCurve(to: CGPoint(x: w/2, y: 0), control: CGPoint(x: w/2 + 1, y: h/4))
        path.addQuadCurve(to: CGPoint(x: 0, y: -h/2), control: CGPoint(x: w/2 + 1, y: -h/4))
        path.addQuadCurve(to: CGPoint(x: -w/2, y: 0), control: CGPoint(x: -w/2 - 1, y: -h/4))
        path.addQuadCurve(to: CGPoint(x: 0, y: h/2), control: CGPoint(x: -w/2 - 1, y: h/4))
        return path
    }
    
    private func buildVisuals() {
        addChild(container)
        
        // 1. Redup Layar (Lumbung yang hangat)
        backdrop.color = SKColor(red: 0.08, green: 0.06, blue: 0.05, alpha: 0.88)
        backdrop.size = CGSize(width: 5000, height: 5000)
        backdrop.zPosition = -10
        container.addChild(backdrop)
        
        // 2. Tampah Anyaman (Winnowing Basket)
        basketNode.zPosition = 1
        container.addChild(basketNode)
        
        // Dasar Tampah (Shadow & Base Kayu/Anyaman)
        let baseBasket = SKShapeNode(circleOfRadius: config.basketRadius)
        baseBasket.fillColor = SKColor(red: 0.26, green: 0.19, blue: 0.11, alpha: 1.0)
        baseBasket.strokeColor = SKColor(red: 0.14, green: 0.09, blue: 0.05, alpha: 1.0)
        baseBasket.lineWidth = 14.0
        basketNode.addChild(baseBasket)
        
        // Tekstur Anyaman Bambu (Lingkaran serat konsentris)
        let ringCount = 8
        for i in 1...ringCount {
            let r = (config.basketRadius / CGFloat(ringCount)) * CGFloat(i)
            let ring = SKShapeNode(circleOfRadius: r)
            ring.strokeColor = SKColor(red: 0.38, green: 0.27, blue: 0.15, alpha: 0.35)
            ring.lineWidth = 2.0
            
            let dashLen: [NSNumber] = [NSNumber(value: Float.random(in: 4...8)), NSNumber(value: Float.random(in: 2...4))]
            let dashedPath = ring.path?.copy(dashingWithPhase: 0, lengths: [CGFloat(truncating: dashLen[0]), CGFloat(truncating: dashLen[1])])
            ring.path = dashedPath
            basketNode.addChild(ring)
        }
        
        // Panduan Visual Zona Sortir (Target tengah & pinggir)
        centerGoldGuide.path = CGPath(ellipseIn: CGRect(
            x: -config.basketRadius * 0.38,
            y: -config.basketRadius * 0.38,
            width: config.basketRadius * 0.76,
            height: config.basketRadius * 0.76
        ), transform: nil)
        centerGoldGuide.strokeColor = SKColor(red: 0.92, green: 0.75, blue: 0.35, alpha: 0.18)
        centerGoldGuide.lineWidth = 1.5
        centerGoldGuide.fillColor = SKColor(red: 0.92, green: 0.75, blue: 0.35, alpha: 0.04)
        centerGoldGuide.zPosition = 0.5
        basketNode.addChild(centerGoldGuide)
        
        outerRimGuide.path = CGPath(ellipseIn: CGRect(
            x: -config.basketRadius + 16,
            y: -config.basketRadius + 16,
            width: (config.basketRadius - 16) * 2,
            height: (config.basketRadius - 16) * 2
        ), transform: nil)
        outerRimGuide.strokeColor = SKColor(red: 0.6, green: 0.25, blue: 0.2, alpha: 0.15)
        outerRimGuide.lineWidth = 2.0
        outerRimGuide.fillColor = .clear
        outerRimGuide.zPosition = 0.5
        basketNode.addChild(outerRimGuide)
        
        // 3. Cincin Progres (Luar Tampah)
        progressRing.lineWidth = 6.0
        progressRing.strokeColor = SKColor(red: 0.95, green: 0.75, blue: 0.32, alpha: 1.0) // Emas Gandum
        progressRing.lineCap = .round
        progressRing.fillColor = .clear
        progressRing.zPosition = 5
        container.addChild(progressRing)
        
        let trackRing = SKShapeNode(circleOfRadius: config.basketRadius + 15)
        trackRing.strokeColor = SKColor(red: 0.35, green: 0.24, blue: 0.14, alpha: 0.5)
        trackRing.lineWidth = 6.0
        trackRing.fillColor = .clear
        trackRing.zPosition = 4.9
        container.addChild(trackRing)
        
        // 4. Label & Teks
        headingLabel.text = config.headingText
        headingLabel.fontSize = 23
        headingLabel.fontColor = SKColor(red: 0.95, green: 0.88, blue: 0.72, alpha: 1.0)
        headingLabel.position = CGPoint(x: 0, y: config.basketRadius + 50)
        headingLabel.zPosition = 6
        container.addChild(headingLabel)
        
        instructionLabel.text = config.instructionText
        instructionLabel.fontSize = 12
        instructionLabel.fontColor = SKColor(red: 0.78, green: 0.68, blue: 0.56, alpha: 0.9)
        instructionLabel.position = CGPoint(x: 0, y: config.basketRadius + 28)
        instructionLabel.zPosition = 6
        container.addChild(instructionLabel)
        
        // Label instruksi ekstra untuk Simulator
        #if targetEnvironment(simulator)
        let simLabel = SKLabelNode(fontNamed: "AvenirNext-Italic")
        simLabel.text = "(Simulator: Putar/Goyang kursor untuk menyortir)"
        simLabel.fontSize = 10
        simLabel.fontColor = SKColor(red: 0.65, green: 0.55, blue: 0.45, alpha: 0.8)
        simLabel.position = CGPoint(x: 0, y: -config.basketRadius - 40)
        simLabel.zPosition = 6
        container.addChild(simLabel)
        #endif
    }
    
    private func setupPhysicsBoundary() {
        let boundaryPath = CGPath(ellipseIn: CGRect(
            x: -config.basketRadius,
            y: -config.basketRadius,
            width: config.basketRadius * 2,
            height: config.basketRadius * 2
        ), transform: nil)
        
        basketNode.physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryPath)
        basketNode.physicsBody?.isDynamic = false
        basketNode.physicsBody?.friction = 0.5
        basketNode.physicsBody?.restitution = 0.2
    }
    
    private func spawnSeeds() {
        let seedPath = createSeedPath()
        
        // Spawn Good Seeds (Gandum Emas Bersih)
        let goldShades: [SKColor] = [
            SKColor(red: 0.90, green: 0.72, blue: 0.38, alpha: 1.0),
            SKColor(red: 0.84, green: 0.65, blue: 0.30, alpha: 1.0),
            SKColor(red: 0.93, green: 0.77, blue: 0.44, alpha: 1.0),
            SKColor(red: 0.88, green: 0.68, blue: 0.34, alpha: 1.0)
        ]
        
        for _ in 0..<config.goodSeedCount {
            let color = goldShades.randomElement()!
            let seed = createSeedNode(path: seedPath, isBad: false, fillColor: color)
            goodSeeds.append(seed)
            basketNode.addChild(seed)
        }
        
        // Spawn Bad Seeds (Biji Hitam / Busuk / Sekam Rusak)
        for _ in 0..<config.badSeedCount {
            let darkColor = SKColor(red: 0.17, green: 0.13, blue: 0.14, alpha: 1.0)
            let seed = createSeedNode(path: seedPath, isBad: true, fillColor: darkColor)
            badSeeds.append(seed)
            basketNode.addChild(seed)
        }
    }
    
    private func createSeedNode(path: CGPath, isBad: Bool, fillColor: SKColor) -> SKNode {
        let seed = SKShapeNode(path: path)
        seed.fillColor = fillColor
        seed.strokeColor = isBad ? SKColor(red: 0.35, green: 0.18, blue: 0.18, alpha: 1.0) : SKColor(red: 0.65, green: 0.48, blue: 0.20, alpha: 1.0)
        seed.lineWidth = isBad ? 0.8 : 0.5
        
        // Posisi acak awal di dalam tampah
        let randomAngle = CGFloat.random(in: 0...(2 * .pi))
        let randomRadius = CGFloat.random(in: 0...(config.basketRadius - 20))
        seed.position = CGPoint(x: cos(randomAngle) * randomRadius, y: sin(randomAngle) * randomRadius)
        seed.zRotation = CGFloat.random(in: 0...(2 * .pi))
        seed.zPosition = isBad ? 2.1 : 2.0
        
        // Konfigurasi Fisika Biji
        seed.physicsBody = SKPhysicsBody(polygonFrom: path)
        seed.physicsBody?.isDynamic = true
        seed.physicsBody?.allowsRotation = true
        seed.physicsBody?.friction = 0.55
        seed.physicsBody?.restitution = 0.15
        seed.physicsBody?.linearDamping = 0.9 // Redaman gesekan anyaman
        seed.physicsBody?.angularDamping = 0.9
        
        // Gravitasi scene global tidak dipakai; didorong manual via sensor
        seed.physicsBody?.affectedByGravity = false
        
        // Biji busuk lebih ringan (sekam hampa) sehingga cepat terlempar ke pinggir
        seed.physicsBody?.mass = isBad ? 0.012 : 0.030
        
        return seed
    }
    
    // MARK: - Logic & Update Loop
    
    public func start() {
        guard !isRunning && !isCompleted else { return }
        isRunning = true
        
        container.setScale(0.8)
        container.alpha = 0
        container.run(.group([
            .fadeIn(withDuration: 0.3),
            .scale(to: 1.0, duration: 0.4).applyTimingMode(.easeOut)
        ]))
        
        #if canImport(UIKit)
        HapticsService.shared.playSelection()
        #endif
        
        // Mulai sensor kemiringan
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 60.0
            motionManager.startAccelerometerUpdates()
        }
        
        // Update Loop Manual
        let loop = SKAction.customAction(withDuration: 1000.0) { [weak self] _, _ in
            self?.updatePhysics()
        }
        run(loop, withKey: "seedSortLoop")
    }
    
    private func updatePhysics() {
        guard isRunning, !isCompleted else { return }
        
        var tiltVector = CGVector.zero
        var shakeIntensity: CGFloat = 0.0
        
        // 1. Ambil Data Accelerometer (Device Nyata)
        if let accel = motionManager.accelerometerData?.acceleration {
            let rawDx = CGFloat(accel.x)
            let rawDy = CGFloat(accel.y)
            
            tiltVector = CGVector(dx: rawDx * 140.0, dy: rawDy * 140.0)
            
            if let last = lastAcceleration {
                let dx = abs(accel.x - last.x)
                let dy = abs(accel.y - last.y)
                shakeIntensity = CGFloat(dx + dy)
            }
            lastAcceleration = accel
        } else {
            // Fallback Simulator (Drag / Swirl kursor)
            tiltVector = simulatedTilt
            shakeIntensity = simulatedShakeIntensity
            simulatedShakeIntensity = max(0, simulatedShakeIntensity * 0.90) // Redaman halus
        }
        
        // 2. Akumulasi Progress Goyangan (Sorting Progress)
        // Diatur agar membutuhkan goyangan berirama 8-12 detik
        if shakeIntensity > 0.06 {
            let progressIncrement = min(shakeIntensity, 0.85) * 0.60
            accumulatedShake += progressIncrement
            currentProgress = min(1.0, accumulatedShake / config.shakeThresholdTotal)
            updateProgressArc()
            updateDynamicInstruction()
            onProgress?(currentProgress)
            
            // Efek haptic tipis berirama saat goyangan efektif
            if Int(accumulatedShake * 10) % 6 == 0 {
                #if canImport(UIKit)
                HapticsService.shared.playImpact(style: .light)
                #endif
            }
        }
        
        // 3. Aplikasikan Gaya Fisik Pemisahan (Separation Physics)
        applySortingForces(tiltForce: tiltVector, shakeIntensity: shakeIntensity)
        
        // 4. Cek Selesai
        if currentProgress >= 1.0 {
            completeMinigame()
        }
    }
    
    private func updateDynamicInstruction() {
        if currentProgress < 0.30 {
            instructionLabel.text = "Goyangkan secara berirama untuk memisahkan biji..."
            instructionLabel.fontColor = SKColor(red: 0.78, green: 0.68, blue: 0.56, alpha: 0.9)
        } else if currentProgress < 0.65 {
            instructionLabel.text = "Biji hitam mulai terdorong ke pinggiran tampah..."
            instructionLabel.fontColor = SKColor(red: 0.88, green: 0.76, blue: 0.50, alpha: 0.95)
        } else if currentProgress < 0.98 {
            instructionLabel.text = "Hampir bersih! Gandum emas terkumpul di tengah!"
            instructionLabel.fontColor = SKColor(red: 0.95, green: 0.85, blue: 0.40, alpha: 1.0)
        }
    }
    
    private func applySortingForces(tiltForce: CGVector, shakeIntensity: CGFloat) {
        // Gaya kemiringan tangan pemain (diredam sedikit agar tidak merusak keteraturan sortir)
        let tiltModulation = max(0.25, 1.0 - (currentProgress * 0.65))
        let effectiveTilt = CGVector(dx: tiltForce.dx * tiltModulation, dy: tiltForce.dy * tiltModulation)
        
        // Gaya sortir meningkat kuat seiring bertambahnya progres dan aktivitas goyangan
        let activeShake = max(shakeIntensity, 0.12)
        let sortMultiplier = (currentProgress * 45.0 + 12.0) * min(activeShake, 1.5)
        
        // Pusaran tangensial berirama khas menampi tampah tradisional
        let swirlMagnitude = (0.6 + currentProgress * 0.8) * min(activeShake, 1.4)
        
        let allSeeds = goodSeeds + badSeeds
        for seed in allSeeds {
            guard let body = seed.physicsBody else { continue }
            
            // Terapkan gravitasi miring
            body.applyForce(effectiveTilt)
            
            let pos = seed.position
            let dist = hypot(pos.x, pos.y)
            let angle = atan2(pos.y, pos.x)
            let isBad = badSeeds.contains(seed)
            
            // Arah radial dari pusat tampah
            let dirX = dist > 1.0 ? (pos.x / dist) : cos(angle)
            let dirY = dist > 1.0 ? (pos.y / dist) : sin(angle)
            
            if isBad {
                // ==========================================
                // BIJI HITAM (BUSUK): Didorong kuat ke PINGGIR
                // ==========================================
                let targetRimRadius = config.basketRadius - 18
                if dist < targetRimRadius {
                    // Dorong ke luar menuju pinggiran
                    let pushOutForce = CGVector(
                        dx: dirX * sortMultiplier * 1.35,
                        dy: dirY * sortMultiplier * 1.35
                    )
                    body.applyForce(pushOutForce)
                } else {
                    // Sudah di tepi: jaga di pinggiran dinding
                    let rimKeepForce = CGVector(
                        dx: dirX * sortMultiplier * 0.4,
                        dy: dirY * sortMultiplier * 0.4
                    )
                    body.applyForce(rimKeepForce)
                }
                
                // Pusaran tepi
                let tangentX = -dirY
                let tangentY = dirX
                body.applyForce(CGVector(dx: tangentX * swirlMagnitude * 7.0, dy: tangentY * swirlMagnitude * 7.0))
                
            } else {
                // ==========================================
                // BIJI GANDUM (BAGUS): Ditarik ke TENGAH
                // ==========================================
                let targetCenterRadius = config.basketRadius * 0.35
                if dist > targetCenterRadius {
                    // Tarik ke dalam menuju pusat
                    let pullInForce = CGVector(
                        dx: -dirX * sortMultiplier * 1.15,
                        dy: -dirY * sortMultiplier * 1.15
                    )
                    body.applyForce(pullInForce)
                } else {
                    // Sudah di tengah: jaga tumpukan gandum terpusat
                    let centeringForce = CGVector(
                        dx: -dirX * sortMultiplier * 0.35,
                        dy: -dirY * sortMultiplier * 0.35
                    )
                    body.applyForce(centeringForce)
                }
                
                // Pusaran halus di tengah
                if dist > 6.0 {
                    let tangentX = -dirY
                    let tangentY = dirX
                    body.applyForce(CGVector(dx: tangentX * swirlMagnitude * 4.0, dy: tangentY * swirlMagnitude * 4.0))
                }
            }
        }
    }
    
    private func updateProgressArc() {
        guard currentProgress > 0.01 else {
            progressRing.path = nil
            return
        }
        let r = config.basketRadius + 15
        let startAngle: CGFloat = .pi / 2
        let endAngle = startAngle - (currentProgress * 2 * .pi)
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressRing.path = path
    }
    
    private func completeMinigame() {
        isCompleted = true
        isRunning = false
        motionManager.stopAccelerometerUpdates()
        removeAction(forKey: "seedSortLoop")
        
        #if canImport(UIKit)
        HapticsService.shared.playNotification(.success)
        #endif
        
        // 1. Tampilkan status bahwa biji telah berhasil terpisah
        headingLabel.text = "TERPISAH SEMPURNA!"
        headingLabel.fontColor = SKColor(red: 0.45, green: 0.95, blue: 0.55, alpha: 1.0)
        instructionLabel.text = "Gandum bersih di tengah • Biji hitam di pinggiran"
        instructionLabel.fontColor = SKColor(red: 0.95, green: 0.85, blue: 0.50, alpha: 1.0)
        
        // Hentikan gerak liar biji agar pemain bisa melihat hasil pemisahannya dengan jelas
        for seed in goodSeeds + badSeeds {
            seed.physicsBody?.linearDamping = 4.0
            seed.physicsBody?.angularDamping = 4.0
        }
        
        // Pendar Emas di Pusat (Menyoroti Gandum Bersih)
        let centerGlow = SKShapeNode(circleOfRadius: config.basketRadius * 0.42)
        centerGlow.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 0.35)
        centerGlow.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.6)
        centerGlow.lineWidth = 2.0
        centerGlow.blendMode = .add
        centerGlow.zPosition = 1.5
        basketNode.addChild(centerGlow)
        centerGlow.run(.sequence([
            .scale(to: 1.15, duration: 0.5).applyTimingMode(.easeOut),
            .scale(to: 1.0, duration: 0.4).applyTimingMode(.easeIn)
        ]))
        
        // Pendar Merah/Oranye Halus di Tepi Luar (Biji Hitam yang terisolasi)
        let rimHighlight = SKShapeNode(circleOfRadius: config.basketRadius - 10)
        rimHighlight.strokeColor = SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.6)
        rimHighlight.lineWidth = 3.0
        rimHighlight.fillColor = .clear
        rimHighlight.zPosition = 1.5
        basketNode.addChild(rimHighlight)
        rimHighlight.run(.sequence([
            .fadeIn(withDuration: 0.3),
            .wait(forDuration: 0.6),
            .fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))
        
        // 2. Berikan jeda 1.0 detik agar pemain menikmati pemandangan biji yang sudah terpisah sempurna,
        // lalu Keneth membersihkan biji hitam ke luar tampah
        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in
                guard let self = self else { return }
                
                // Animasi Keneth membuang biji hitam dari pinggiran tampah
                for badSeed in self.badSeeds {
                    badSeed.physicsBody = nil
                    let angle = atan2(badSeed.position.y, badSeed.position.x)
                    let throwTarget = CGPoint(
                        x: cos(angle) * (self.config.basketRadius + 140),
                        y: sin(angle) * (self.config.basketRadius + 140)
                    )
                    let throwOut = SKAction.group([
                        .move(to: throwTarget, duration: 0.45).applyTimingMode(.easeIn),
                        .fadeOut(withDuration: 0.45),
                        .scale(to: 0.2, duration: 0.45)
                    ])
                    badSeed.run(.sequence([throwOut, .removeFromParent()]))
                }
                
                // Gandum bersih berkilau puas
                for goodSeed in self.goodSeeds {
                    goodSeed.run(.sequence([
                        .scale(to: 1.25, duration: 0.2),
                        .scale(to: 1.0, duration: 0.2)
                    ]))
                }
            },
            .wait(forDuration: 1.2),
            .run { [weak self] in
                self?.onComplete?()
            },
            .group([
                .fadeOut(withDuration: 0.4),
                .scale(to: 0.8, duration: 0.4).applyTimingMode(.easeIn)
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
    
    // MARK: - Touch Handling (Simulator Fallback)
    
    #if canImport(UIKit)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else { return }
        if let touch = touches.first {
            lastTouchLocation = touch.location(in: self)
            updateSimulatedTilt(from: touches)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else { return }
        if let touch = touches.first {
            let location = touch.location(in: self)
            if let last = lastTouchLocation {
                let delta = hypot(location.x - last.x, location.y - last.y)
                simulatedShakeIntensity = min(1.4, delta * 0.05)
            }
            lastTouchLocation = location
            updateSimulatedTilt(from: touches)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        simulatedTilt = .zero
        lastTouchLocation = nil
        simulatedShakeIntensity = 0.0
    }
    
    private func updateSimulatedTilt(from touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let dx = location.x * 0.75
        let dy = location.y * 0.75
        simulatedTilt = CGVector(dx: dx, dy: dy)
    }
    #endif
}

// MARK: - SwiftUI Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview("Seed Sorting Winnow Minigame") {
    SpriteView(scene: {
        // Penting: Host Scene harus mengaktifkan physics!
        let scene = SKScene(size: CGSize(width: 500, height: 600))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = SKColor(red: 0.05, green: 0.04, blue: 0.03, alpha: 1.0)
        
        // Gravitasi global dinonaktifkan karena node kita mengatur gravitasinya sendiri (CoreMotion)
        scene.physicsWorld.gravity = .zero
        
        func spawn() {
            let minigame = SeedSortingMinigameNode()
            minigame.position = CGPoint(x: 250, y: 300)
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
