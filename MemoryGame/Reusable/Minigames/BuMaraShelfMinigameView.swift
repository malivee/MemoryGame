// Penjelasan file: BuMaraShelfMinigameView.swift
// Minigame SwiftUI untuk menolong Bu Mara: Mengangkat rak kayu tembikar yang ambles,
// dan mengganjal kaki kanannya dengan Batu Bata Merah & Pasak Kayu Pengganjal agar berdiri kokoh.

import SwiftUI
import CoreHaptics

// MARK: - Game States & Models

public enum ShelfGameState {
    case lifting        // Tahap 1: Angkat rak ke posisi seimbang (Level)
    case wedging        // Tahap 2: Seret pengganjal (Batu Bata & Pasak) ke bawah kaki
    case hammering      // Tahap 3: Ketuk pengganjal untuk menguncinya rapat (2 ketukan palu)
    case won            // Menang: Rak kokoh seimbang
    case failed         // Gagal: Pot jatuh pecah
}

public enum ShelfFailReason {
    case dropped
    case liftedTooHigh
}

public struct PotDebris: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var rotation: Double
    public var scale: CGFloat
}

// MARK: - Main Minigame View (Landscape)

public struct BuMaraShelfMinigameView: View {
    public var onComplete: ((Bool) -> Void)?
    public var onDismiss: (() -> Void)?
    
    public init(onComplete: ((Bool) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }
    
    // Game States
    @State private var gameState: ShelfGameState = .lifting
    @State private var failReason: ShelfFailReason = .dropped
    
    // Physics: 14 derajat kemiringan awal ambles ke tanah
    @State private var shelfAngle: Double = 14.0
    @State private var isShelfHeld: Bool = false
    @State private var isShelfLockedUp: Bool = false
    
    // Pengganjal (Wedge / Brick) Drag & Lock States
    @State private var wedgeDragTranslation: CGSize = .zero
    @State private var isDraggingWedge: Bool = false
    @State private var isWedgePlaced: Bool = false
    @State private var hammerTaps: Int = 0 // Butuh 2x ketukan palu untuk mengunci rapat
    
    // Visual FX & Pot Physics
    @State private var potSlideOffset: CGFloat = 8.0
    @State private var potOpacity: Double = 1.0
    @State private var shatteredPieces: [PotDebris] = []
    @State private var plantRustle: Double = 0.0
    @State private var hammerWiggle: CGFloat = 0.0
    
    // Screen Feedback & Ambient
    @State private var screenShake: CGFloat = 0.0
    @State private var warningFlash: Double = 0.0
    @State private var lastHapticAngle: Int = 14
    @State private var herbSway: Double = 0.0
    
    // Haptics
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let errorNotify = UINotificationFeedbackGenerator()
    private let successNotify = UINotificationFeedbackGenerator()
    
    // Angle limits
    private let balancedRange: ClosedRange<Double> = -2.5...2.5
    private let failAngleUp: Double = -13.0
    
    // Precise Furniture Dimensions
    private let shelfWidth: CGFloat = 330
    private let legWidth: CGFloat = 24
    private let legHeight: CGFloat = 110
    private let plankHeight: CGFloat = 20
    private let potsHeight: CGFloat = 55
    
    public var body: some View {
        GeometryReader { proxy in
            let screenSize = CGSize(
                width: proxy.size.width > 50 ? proxy.size.width : 844,
                height: proxy.size.height > 50 ? proxy.size.height : 390
            )
            
            // Posisi tumpuan kaki kiri di tanah rata
            let groundY = screenSize.height * 0.70
            let pivotX = screenSize.width * 0.22
            let pivotY = groundY
            
            // Titik tumpuan kaki kanan (tepat di bawah kaki kanan saat lurus)
            let rightFootTarget = CGPoint(x: pivotX + shelfWidth - legWidth / 2, y: groundY)
            
            // Posisi awal tumpukan pengganjal (Batu bata & pasak di samping kanan)
            let initialWedgePos = CGPoint(x: min(rightFootTarget.x + 85, screenSize.width - 65), y: groundY + 28)
            
            ZStack {
                // 1. Dinding Pondok Kayu & Tanah Pekarangan Bu Mara
                CottageGardenBackground(herbSway: herbSway)
                    .ignoresSafeArea()
                
                // Cahaya Matahari Miring
                SunlightRayOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // Flash Merah saat Gagal
                Color.red
                    .opacity(warningFlash)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // 2. Lubang Lumpur Ambles di Kaki Kanan
                MudSinkholePit(isWedgePlaced: isWedgePlaced)
                    .position(x: rightFootTarget.x, y: groundY + 16)
                
                // Batu Landasan Kokoh Kaki Kiri
                LeftFootStonePaver()
                    .position(x: pivotX + legWidth / 2, y: groundY + 6)
                
                // 3. PENGGANJAL (Batu Bata Merah & Pasak Kayu) - SELALU KELIHATAN DARI AWAL!
                let wedgeCurrentX = isWedgePlaced ? rightFootTarget.x : (initialWedgePos.x + wedgeDragTranslation.width)
                let wedgeCurrentY = isWedgePlaced ? (groundY + 2) : (initialWedgePos.y + wedgeDragTranslation.height)
                
                InteractivePengganjalView(
                    isPlaced: isWedgePlaced,
                    hammerTaps: hammerTaps,
                    isDragging: isDraggingWedge,
                    onTapToHammer: {
                        handleHammerTap()
                    }
                )
                .offset(x: hammerWiggle)
                .position(x: wedgeCurrentX, y: wedgeCurrentY)
                .allowsHitTesting(!isWedgePlaced || (isWedgePlaced && hammerTaps < 2))
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            guard !isWedgePlaced, isShelfLockedUp || balancedRange.contains(shelfAngle) else {
                                // Jika rak belum diangkat seimbang
                                if !isWedgePlaced {
                                    lightImpact.impactOccurred(intensity: 0.4)
                                    triggerShake(intensity: 2.0)
                                }
                                return
                            }
                            isDraggingWedge = true
                            wedgeDragTranslation = val.translation
                        }
                        .onEnded { val in
                            guard isDraggingWedge else { return }
                            isDraggingWedge = false
                            
                            let dropPos = CGPoint(
                                x: initialWedgePos.x + val.translation.width,
                                y: initialWedgePos.y + val.translation.height
                            )
                            let dist = hypot(dropPos.x - rightFootTarget.x, dropPos.y - groundY)
                            
                            // Jika dilepas di dekat lubang kaki kanan
                            if dist < 65 {
                                snapWedgeInPlace()
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                    wedgeDragTranslation = .zero
                                }
                            }
                        }
                )
                
                // 4. RAK KAYU & TEMBIKAR UTUH (Satu Kesatuan Rangka Terhubung 100%)
                SinglePieceShelfFurniture(
                    shelfWidth: shelfWidth,
                    legWidth: legWidth,
                    legHeight: legHeight,
                    plankHeight: plankHeight,
                    potsHeight: potsHeight,
                    isLockedUp: isShelfLockedUp,
                    isWedgePlaced: isWedgePlaced,
                    potSlideOffset: potSlideOffset,
                    potOpacity: potOpacity,
                    plantRustle: plantRustle,
                    onTapPot: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            plantRustle = Double.random(in: -10...10)
                        }
                        lightImpact.impactOccurred(intensity: 0.5)
                    }
                )
                // Rotasi sempurna berpusat di alas kaki kiri (UnitPoint: x = legWidth/2 / shelfWidth, y = 1.0)
                .rotationEffect(
                    .degrees(shelfAngle),
                    anchor: UnitPoint(x: (legWidth / 2) / shelfWidth, y: 1.0)
                )
                // Posisi tepat di atas batu tumpuan kiri (pivotX, pivotY)
                .position(x: pivotX + shelfWidth / 2 - legWidth / 2, y: pivotY - (legHeight + plankHeight + potsHeight) / 2)
                
                // 5. Handle Mengangkat Rak (Di Ujung Kanan Papan)
                if !isWedgePlaced && gameState != .won && gameState != .failed {
                    let angleRad = shelfAngle * .pi / 180.0
                    let handleX = pivotX + cos(angleRad) * (shelfWidth - legWidth / 2)
                    let handleY = pivotY - legHeight + sin(angleRad) * (shelfWidth - legWidth / 2)
                    let isBalanced = balancedRange.contains(shelfAngle)
                    
                    LiftHandleControl(
                        isBalanced: isBalanced,
                        isHeld: isShelfHeld,
                        isLocked: isShelfLockedUp
                    )
                    .position(x: handleX + 28, y: handleY - 14)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                handleShelfDrag(val: val)
                            }
                            .onEnded { _ in
                                handleShelfRelease()
                            }
                    )
                }
                
                // 6. Tombol Kunci Penopang Sementara (Saat Rak Seimbang)
                if balancedRange.contains(shelfAngle) && !isShelfLockedUp && !isWedgePlaced {
                    Button(action: lockShelfInAir) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("TAHAN RAK DI SINI")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.88, blue: 0.45), Color(red: 1.0, green: 0.68, blue: 0.20)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.7), radius: 10, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                    }
                    .position(x: screenSize.width * 0.5, y: screenSize.height - 48)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 7. Tombol Palu Cepat (Jika pengganjal sudah masuk)
                if isWedgePlaced && hammerTaps < 2 {
                    Button(action: handleHammerTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("KETUK PALU MENGUNCI RAPAT (\(hammerTaps)/2)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.82, blue: 0.35), Color(red: 0.95, green: 0.62, blue: 0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.6), radius: 8, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                    }
                    .position(x: screenSize.width * 0.5, y: screenSize.height - 48)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 8. Pecahan Pot jika Gagal
                ForEach(shatteredPieces) { piece in
                    PotShardShape()
                        .fill(Color(red: 0.68, green: 0.38, blue: 0.20))
                        .frame(width: 18 * piece.scale, height: 18 * piece.scale)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
                
                // 9. TOP NAVIGATION & PROGRESS HUD (Clean & Safe Area Respecting)
                StorybookTopNavigationHUD(
                    gameState: gameState,
                    isWedgePlaced: isWedgePlaced,
                    hammerTaps: hammerTaps,
                    currentAngle: shelfAngle,
                    isBalanced: balancedRange.contains(shelfAngle),
                    instruction: hudInstruction,
                    onDismiss: onDismiss
                )
                
                // 10. Modal Pop-up Gagal
                if gameState == .failed {
                    FailurePopupModal(
                        reason: failReason,
                        onRetry: resetGame
                    )
                }
                
                // 11. Modal Pop-up Menang
                if gameState == .won {
                    VictoryPopupModal(
                        onContinue: {
                            onComplete?(true)
                            onDismiss?()
                        }
                    )
                }
            }
            .offset(x: screenShake)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    herbSway = 4.0
                }
            }
        }
    }
    
    // MARK: - Instruction Strings
    
    private var hudInstruction: String {
        switch gameState {
        case .lifting:
            if balancedRange.contains(shelfAngle) {
                return "Rak seimbang! Ketuk 'TAHAN RAK DI SINI' atau langsung seret Batu Bata Pengganjal ke bawah kaki!"
            } else if isShelfHeld {
                return "Tarik perlahan ke atas sampai waterpass hijau lurus."
            } else {
                return "Tarik bulatan pegangan oranye ke atas untuk mengangkat kaki rak yang ambles!"
            }
        case .wedging:
            return "Rak sudah terangkat! Seret BATU BATA PENGGANJAL di kanan ke bawah kaki rak!"
        case .hammering:
            return "Batu bata terpasang! Ketuk pengganjal 2x untuk memalu dan menguncinya rapat! (\(hammerTaps)/2)"
        case .won:
            return "Sempurna! Rak Bu Mara berdiri kokoh dan pot-pot ramuan terselamatkan!"
        case .failed:
            return "Pot Bu Mara hancur! Ketuk 'Coba Lagi' untuk mengulang."
        }
    }
    
    // MARK: - Handlers & Physics
    
    private func handleShelfDrag(val: DragGesture.Value) {
        guard gameState != .won, gameState != .failed else { return }
        isShelfHeld = true
        
        let dragY = val.translation.height
        var targetAngle = 14.0 + (Double(dragY) * 0.16)
        
        if targetAngle < -15.0 { targetAngle = -15.0 }
        if targetAngle > 20.0 { targetAngle = 20.0 }
        
        shelfAngle = targetAngle
        
        let intAngle = Int(shelfAngle)
        if intAngle != lastHapticAngle {
            lastHapticAngle = intAngle
            if balancedRange.contains(shelfAngle) {
                rigidImpact.impactOccurred(intensity: 0.8)
            } else {
                lightImpact.impactOccurred(intensity: 0.3)
            }
        }
        
        // Geseran pot di atas papan mengikuti kemiringan
        if shelfAngle > 5.0 {
            potSlideOffset = CGFloat((shelfAngle - 5.0) * 1.6)
        } else if shelfAngle < -4.0 {
            potSlideOffset = CGFloat((shelfAngle + 4.0) * 2.0)
        } else {
            potSlideOffset = 0.0
        }
        
        // Terangkat melampaui batas
        if shelfAngle <= failAngleUp {
            handleFail(reason: .liftedTooHigh)
        }
    }
    
    private func handleShelfRelease() {
        guard gameState != .won, gameState != .failed else { return }
        isShelfHeld = false
        
        if isWedgePlaced {
            // Sudah diganjal: rak aman berdiri di atas ganjalan
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                shelfAngle = 0.0
                potSlideOffset = 0.0
            }
        } else if isShelfLockedUp {
            // Sudah dikunci sementara: tetap tertahan di 0 derajat
            shelfAngle = 0.0
            potSlideOffset = 0.0
        } else {
            // Dilepas sebelum diganjal/dikunci: anjlok ke lubang
            withAnimation(.easeIn(duration: 0.28)) {
                shelfAngle = 14.0
                potSlideOffset = CGFloat(9.0 * 1.6)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                handleFail(reason: .dropped)
            }
        }
    }
    
    private func lockShelfInAir() {
        isShelfLockedUp = true
        shelfAngle = 0.0
        potSlideOffset = 0.0
        gameState = .wedging
        
        rigidImpact.impactOccurred(intensity: 1.0)
        mediumImpact.impactOccurred(intensity: 0.8)
        triggerShake(intensity: 3.0)
    }
    
    private func snapWedgeInPlace() {
        isWedgePlaced = true
        isShelfLockedUp = false
        shelfAngle = 0.0
        potSlideOffset = 0.0
        gameState = .hammering
        
        rigidImpact.impactOccurred(intensity: 1.0)
        heavyImpact.impactOccurred(intensity: 0.8)
        triggerShake(intensity: 4.0)
    }
    
    private func handleHammerTap() {
        guard isWedgePlaced, hammerTaps < 2 else { return }
        hammerTaps += 1
        
        // Haptic bantingan palu
        heavyImpact.impactOccurred(intensity: hammerTaps == 2 ? 1.0 : 0.7)
        triggerShake(intensity: hammerTaps == 2 ? 6.0 : 3.0)
        
        // Efek goyang ganjalan saat dipalu
        withAnimation(.default) { hammerWiggle = 3.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.default) { hammerWiggle = -3.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) { hammerWiggle = 0 }
        }
        
        if hammerTaps >= 2 {
            // Kunci sempurna & menang
            successNotify.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                gameState = .won
            }
        }
    }
    
    private func handleFail(reason: ShelfFailReason) {
        guard gameState != .won, gameState != .failed else { return }
        gameState = .failed
        failReason = reason
        errorNotify.notificationOccurred(.error)
        triggerShake(intensity: 12.0)
        
        withAnimation(.easeOut(duration: 0.1)) { warningFlash = 0.5 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.3)) { warningFlash = 0.0 }
        }
        
        triggerShatter(at: CGPoint(x: 480, y: 260))
    }
    
    private func triggerShatter(at point: CGPoint) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            potOpacity = 0.0
            heavyImpact.impactOccurred()
            
            shatteredPieces.removeAll()
            for _ in 0..<16 {
                let p = PotDebris(
                    position: CGPoint(
                        x: point.x + CGFloat.random(in: -15...15),
                        y: point.y + CGFloat.random(in: -15...15)
                    ),
                    rotation: Double.random(in: 0...360),
                    scale: CGFloat.random(in: 0.7...1.3)
                )
                shatteredPieces.append(p)
            }
            
            withAnimation(.easeOut(duration: 0.45)) {
                for i in shatteredPieces.indices {
                    shatteredPieces[i].position.x += CGFloat.random(in: -70...70)
                    shatteredPieces[i].position.y += CGFloat.random(in: -35...35)
                    shatteredPieces[i].rotation += Double.random(in: -180...180)
                }
            }
        }
    }
    
    private func resetGame() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            gameState = .lifting
            shelfAngle = 14.0
            isShelfHeld = false
            isShelfLockedUp = false
            
            isWedgePlaced = false
            wedgeDragTranslation = .zero
            isDraggingWedge = false
            hammerTaps = 0
            
            potSlideOffset = 8.0
            potOpacity = 1.0
            shatteredPieces.removeAll()
            warningFlash = 0.0
        }
    }
    
    private func triggerShake(intensity: CGFloat) {
        withAnimation(.default) { screenShake = intensity }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.default) { screenShake = -intensity }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) { screenShake = 0 }
        }
    }
}

// MARK: - Single Piece Shelf Furniture (Plank, Legs, Braces, Pots)

public struct SinglePieceShelfFurniture: View {
    public let shelfWidth: CGFloat
    public let legWidth: CGFloat
    public let legHeight: CGFloat
    public let plankHeight: CGFloat
    public let potsHeight: CGFloat
    public let isLockedUp: Bool
    public let isWedgePlaced: Bool
    public let potSlideOffset: CGFloat
    public let potOpacity: Double
    public let plantRustle: Double
    public var onTapPot: (() -> Void)?
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Tiga Pot Bu Mara (Duduk tepat menempel di atas papan)
            HStack(spacing: 36) {
                // Pot 1: Terracotta Herbal Jar dengan Tanaman Chamomile
                TerracottaHerbalPot(plantRustle: plantRustle, onTap: onTapPot)
                
                // Pot 2: Guci Keramik Glasir Hijau Laut
                GlazedCeramicJar(onTap: onTapPot)
                
                // Pot 3: Mangkuk Gerabah Tradisional
                FolkEarthenwareBowl(onTap: onTapPot)
            }
            .frame(width: shelfWidth, height: potsHeight, alignment: .bottom)
            .offset(x: potSlideOffset)
            .opacity(potOpacity)
            
            // 2. Papan Meja Kayu Tebal (Table Top Plank)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.58, green: 0.38, blue: 0.22), Color(red: 0.40, green: 0.24, blue: 0.14)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: shelfWidth + 20, height: plankHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(red: 0.72, green: 0.52, blue: 0.32).opacity(0.4), lineWidth: 1)
                    )
                
                // Serat Kayu
                Path { p in
                    p.move(to: CGPoint(x: 10, y: 7))
                    p.addQuadCurve(to: CGPoint(x: shelfWidth + 10, y: 7), control: CGPoint(x: shelfWidth * 0.5, y: 5))
                }
                .stroke(Color.black.opacity(0.35), lineWidth: 1.5)
                
                // Plat Besi Sudut
                HStack {
                    CornerIronBracket()
                    Spacer()
                    CornerIronBracket()
                }
                .frame(width: shelfWidth + 12)
                .padding(.horizontal, 4)
            }
            .frame(width: shelfWidth, height: plankHeight)
            
            // 3. Kaki-kaki dan Rangka Penyangga (Langsung menempel di bawah papan)
            ZStack(alignment: .topLeading) {
                // Palang Penyangga Horizontal Tengah
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.46, green: 0.30, blue: 0.17), Color(red: 0.32, green: 0.20, blue: 0.11)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: shelfWidth - 40, height: 12)
                    .position(x: shelfWidth / 2, y: legHeight * 0.48)
                
                // Skur Penguat Sudut (Diagonal Corner Braces)
                Path { p in
                    // Kiri
                    p.move(to: CGPoint(x: legWidth, y: 32))
                    p.addLine(to: CGPoint(x: legWidth + 30, y: 0))
                    // Kanan
                    p.move(to: CGPoint(x: shelfWidth - legWidth, y: 32))
                    p.addLine(to: CGPoint(x: shelfWidth - legWidth - 30, y: 0))
                }
                .stroke(Color(red: 0.42, green: 0.26, blue: 0.15), lineWidth: 8)
                
                // Penopang Kayu Sementara (Jika dikunci)
                if isLockedUp {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.72, green: 0.48, blue: 0.25), Color(red: 0.50, green: 0.30, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 18, height: legHeight + 10)
                            .rotationEffect(.degrees(-18), anchor: .top)
                        
                        Text("TERTAHAN")
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(red: 1.0, green: 0.85, blue: 0.45))
                            .cornerRadius(4)
                            .offset(x: -8, y: 15)
                    }
                    .position(x: shelfWidth - legWidth - 12, y: legHeight / 2)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Kaki Kiri (Menempel langsung di bawah papan)
                TimberLeg(width: legWidth, height: legHeight)
                    .position(x: legWidth / 2, y: legHeight / 2)
                
                // Kaki Kanan (Menempel langsung di bawah papan)
                TimberLeg(width: legWidth, height: legHeight)
                    .position(x: shelfWidth - legWidth / 2, y: legHeight / 2)
            }
            .frame(width: shelfWidth, height: legHeight)
        }
        .frame(width: shelfWidth, height: potsHeight + plankHeight + legHeight)
    }
}

public struct TimberLeg: View {
    public let width: CGFloat
    public let height: CGFloat
    
    public var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.44, green: 0.28, blue: 0.16), Color(red: 0.28, green: 0.16, blue: 0.09)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: height)
            
            // Baut Logam Hitam
            Circle()
                .fill(Color(white: 0.2))
                .frame(width: 5, height: 5)
                .offset(y: 8)
        }
    }
}

public struct CornerIronBracket: View {
    public var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(white: 0.25))
            .frame(width: 20, height: 8)
            .overlay(
                HStack(spacing: 8) {
                    Circle().fill(Color.black).frame(width: 2.5, height: 2.5)
                    Circle().fill(Color.black).frame(width: 2.5, height: 2.5)
                }
            )
    }
}

// MARK: - PENGGANJAL (Batu Bata Merah & Pasak Kayu Pengganjal)

public struct InteractivePengganjalView: View {
    public let isPlaced: Bool
    public let hammerTaps: Int
    public let isDragging: Bool
    public var onTapToHammer: (() -> Void)?
    
    public var body: some View {
        Button(action: {
            if isPlaced && hammerTaps < 2 {
                onTapToHammer?()
            }
        }) {
            VStack(spacing: 4) {
                // Label Penanda Pengganjal (Muncul jelas dari awal)
                if !isPlaced {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("PENGGANJAL")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.9, blue: 0.4), Color(red: 1.0, green: 0.68, blue: 0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(7)
                    .shadow(color: .orange.opacity(0.8), radius: 3, y: 1)
                }
                
                // Batu Bata Merah Utama
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.82, green: 0.32, blue: 0.20), Color(red: 0.56, green: 0.18, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black.opacity(0.35), lineWidth: 1)
                        )
                    
                    // Cap Bata & Tekstur
                    HStack(spacing: 4) {
                        Circle().fill(Color.black.opacity(0.2)).frame(width: 6, height: 6)
                        Text("BATA GANJAL")
                            .font(.system(size: 6.5, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                        Circle().fill(Color.black.opacity(0.2)).frame(width: 6, height: 6)
                    }
                }
                
                // Pasak Kayu Pengganjal di Bawah Bata
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.44, blue: 0.22), Color(red: 0.42, green: 0.26, blue: 0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 12)
                    
                    Text("PASAK KAYU")
                        .font(.system(size: 6, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .scaleEffect(isDragging ? 1.15 : (isPlaced && hammerTaps == 2 ? 1.0 : (isPlaced ? 1.05 : 1.0)))
            .shadow(color: .black.opacity(isDragging ? 0.7 : 0.4), radius: isDragging ? 10 : 3, y: 3)
            .overlay(
                // Efek animasi berkedip jika belum dipasang
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isPlaced ? (hammerTaps >= 2 ? Color.green : Color.yellow) : Color.orange, lineWidth: 1.5)
                    .padding(-4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mud Sinkhole & Stone Pavers

public struct MudSinkholePit: View {
    public let isWedgePlaced: Bool
    
    public var body: some View {
        ZStack {
            // Cekungan lumpur basah
            Ellipse()
                .fill(Color(red: 0.11, green: 0.08, blue: 0.05))
                .frame(width: 95, height: 32)
            
            Ellipse()
                .fill(Color(red: 0.16, green: 0.12, blue: 0.08).opacity(0.85))
                .frame(width: 68, height: 18)
                .offset(x: -2, y: 2)
            
            // Indikator celah hijau tempat menaruh pengganjal
            if !isWedgePlaced {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .background(Color.green.opacity(0.12))
                    .frame(width: 58, height: 36)
                    .offset(y: -4)
                
                Text("PASANG GANJAL")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(.green)
                    .offset(y: -28)
            }
        }
    }
}

public struct LeftFootStonePaver: View {
    public var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.42), Color(white: 0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 38, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Handle Control

public struct LiftHandleControl: View {
    public let isBalanced: Bool
    public let isHeld: Bool
    public let isLocked: Bool
    
    public var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(isBalanced || isLocked ? Color.green.opacity(0.35) : (isHeld ? Color.yellow.opacity(0.3) : Color.orange.opacity(0.25)))
                    .frame(width: 58, height: 58)
                
                Circle()
                    .stroke(
                        isBalanced || isLocked ? Color.green : Color(red: 1.0, green: 0.82, blue: 0.35),
                        lineWidth: 2.5
                    )
                    .frame(width: 58, height: 58)
                
                Image(systemName: isBalanced || isLocked ? "checkmark" : "hand.point.up.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(isBalanced || isLocked ? "SEIMBANG!" : "TARIK KE ATAS")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.85))
                .cornerRadius(8)
        }
    }
}

// MARK: - Artisan Pots

public struct TerracottaHerbalPot: View {
    public let plantRustle: Double
    public var onTap: (() -> Void)?
    
    public var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .bottom) {
                // Daun Mint & Bunga Chamomile
                ZStack {
                    HerbLeaf(color: Color(red: 0.32, green: 0.62, blue: 0.26))
                        .frame(width: 14, height: 22)
                        .rotationEffect(.degrees(-30 + plantRustle))
                        .offset(x: -12, y: -38)
                    
                    HerbLeaf(color: Color(red: 0.40, green: 0.72, blue: 0.32))
                        .frame(width: 14, height: 22)
                        .rotationEffect(.degrees(25 + plantRustle))
                        .offset(x: 12, y: -40)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().fill(Color.yellow).frame(width: 3.5, height: 3.5))
                        .offset(x: 1, y: -43)
                }
                
                // Badan Pot
                TerracottaShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.76, green: 0.42, blue: 0.22), Color(red: 0.52, green: 0.25, blue: 0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 50)
                    .overlay(
                        Path { p in
                            p.move(to: CGPoint(x: 8, y: 22))
                            p.addLine(to: CGPoint(x: 50, y: 22))
                        }
                        .stroke(Color(red: 0.92, green: 0.72, blue: 0.52).opacity(0.6), lineWidth: 1.5)
                    )
                
                // Mulut Pot
                Ellipse()
                    .fill(Color(red: 0.35, green: 0.16, blue: 0.09))
                    .frame(width: 38, height: 8)
                    .offset(y: -48)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct GlazedCeramicJar: View {
    public var onTap: (() -> Void)?
    
    public var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .bottom) {
                GlazedPotShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.68, blue: 0.62), Color(red: 0.12, green: 0.44, blue: 0.38)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 44)
                    .overlay(
                        Path { p in
                            p.move(to: CGPoint(x: 12, y: 12))
                            p.addQuadCurve(to: CGPoint(x: 16, y: 34), control: CGPoint(x: 8, y: 22))
                        }
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                
                // Tali Jerami
                Rectangle()
                    .fill(Color(red: 0.82, green: 0.68, blue: 0.45))
                    .frame(width: 28, height: 3.5)
                    .offset(y: -38)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct FolkEarthenwareBowl: View {
    public var onTap: (() -> Void)?
    
    public var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .bottom) {
                ClayBowlMiniShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.84, green: 0.60, blue: 0.32), Color(red: 0.60, green: 0.38, blue: 0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 26)
                
                Image(systemName: "circle.dotted")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.3))
                    .offset(y: -8)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Storybook Top Navigation HUD

public struct StorybookTopNavigationHUD: View {
    public let gameState: ShelfGameState
    public let isWedgePlaced: Bool
    public let hammerTaps: Int
    public let currentAngle: Double
    public let isBalanced: Bool
    public let instruction: String
    public var onDismiss: (() -> Void)?
    
    public var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 12) {
                // Quest Title Pill
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.45))
                    Text("BANTU BU MARA: GANJAL RAK")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(red: 0.18, green: 0.13, blue: 0.09).opacity(0.9))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
                
                // Status Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(isBalanced ? Color.green : (isWedgePlaced ? Color.yellow : Color.orange))
                        .frame(width: 8, height: 8)
                    
                    Text(statusText)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                
                Spacer()
                
                // Waterpass Kuningan Ramping
                HStack(spacing: 6) {
                    ZStack {
                        Capsule()
                            .fill(Color(red: 0.08, green: 0.18, blue: 0.12))
                            .frame(width: 72, height: 16)
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        
                        Rectangle()
                            .fill(Color.green.opacity(0.45))
                            .frame(width: 16, height: 16)
                        
                        let bubbleOffset = min(28, max(-28, CGFloat(-currentAngle * 2.2)))
                        Circle()
                            .fill(isBalanced ? Color.green : Color.yellow)
                            .frame(width: 12, height: 12)
                            .offset(x: bubbleOffset)
                            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: bubbleOffset)
                    }
                    
                    Text(String(format: "%+.1f°", currentAngle))
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(isBalanced ? .green : .white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.75))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.85, green: 0.68, blue: 0.35), lineWidth: 1.2))
                
                // Close Button
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            
            // Subtitle Speech Bubble Card (Floating)
            HStack(spacing: 8) {
                Text("👵")
                    .font(.system(size: 14))
                Text(instruction)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.92, blue: 0.82))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(red: 0.12, green: 0.09, blue: 0.07).opacity(0.85))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
            
            Spacer()
        }
        .padding(.horizontal, 48) // Safe margin from Dynamic Island
        .padding(.top, 10)
    }
    
    private var statusText: String {
        if isWedgePlaced {
            return hammerTaps >= 2 ? "TERKUNCI KOKOH!" : "KETUK PALU MENGUNCI RAPAT"
        } else if isBalanced {
            return "SEIMBANG! SERET PENGGANJAL"
        } else {
            return "AMBLES 14° - TARIK KE ATAS"
        }
    }
}

// MARK: - Cottage Background & Atmosphere

public struct CottageGardenBackground: View {
    public let herbSway: Double
    
    public var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.12, blue: 0.08)
            
            // Dinding Papan Kayu Vertikal
            Canvas { context, size in
                guard size.width > 10 && size.height > 10 else { return }
                let plankW: CGFloat = 52
                let count = Int(size.width / plankW) + 3
                for i in 0..<count {
                    let x = CGFloat(i) * plankW
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 0))
                    line.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(line, with: .color(Color.black.opacity(0.35)), lineWidth: 2)
                }
            }
            
            // Ikatan Herba Kering Bergoyang
            HStack(spacing: 45) {
                DriedHerbsView(color: Color(red: 0.55, green: 0.40, blue: 0.65))
                    .rotationEffect(.degrees(herbSway), anchor: .top)
                DriedHerbsView(color: Color(red: 0.45, green: 0.60, blue: 0.35))
                    .rotationEffect(.degrees(-herbSway * 0.8), anchor: .top)
                Spacer()
            }
            .padding(.leading, 80)
            .padding(.top, 65)
            
            // Tanah Pekarangan
            Canvas { context, size in
                guard size.width > 10 && size.height > 10 else { return }
                let groundRect = CGRect(x: 0, y: size.height * 0.66, width: size.width, height: size.height * 0.34)
                context.fill(Path(groundRect), with: .color(Color(red: 0.13, green: 0.09, blue: 0.06)))
            }
        }
    }
}

public struct DriedHerbsView: View {
    public let color: Color
    
    public var body: some View {
        VStack(spacing: 2) {
            Rectangle().fill(Color(red: 0.7, green: 0.55, blue: 0.35)).frame(width: 2, height: 16)
            Capsule().fill(color).frame(width: 12, height: 32)
        }
    }
}

public struct SunlightRayOverlay: View {
    public var body: some View {
        Canvas { context, size in
            guard size.width > 10 && size.height > 10 else { return }
            var beam = Path()
            beam.move(to: CGPoint(x: -40, y: -40))
            beam.addLine(to: CGPoint(x: size.width * 0.42, y: -40))
            beam.addLine(to: CGPoint(x: size.width * 0.80, y: size.height))
            beam.addLine(to: CGPoint(x: size.width * 0.18, y: size.height))
            beam.closeSubpath()
            context.fill(
                beam,
                with: .linearGradient(
                    Gradient(colors: [Color.yellow.opacity(0.15), Color.clear]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width * 0.6, y: size.height)
                )
            )
        }
    }
}

// MARK: - Shapes

public struct HerbLeaf: View {
    public let color: Color
    public var body: some View {
        Ellipse().fill(color)
    }
}

public struct TerracottaShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 12, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX - 5, y: rect.maxY * 0.8))
        p.addQuadCurve(to: CGPoint(x: rect.minX + 10, y: rect.minY), control: CGPoint(x: rect.minX + 2, y: rect.midY * 0.4))
        p.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX - 2, y: rect.midY * 0.4))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 12, y: rect.maxY), control: CGPoint(x: rect.maxX + 5, y: rect.maxY * 0.8))
        p.closeSubpath()
        return p
    }
}

public struct GlazedPotShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX - 4, y: rect.maxY * 0.75))
        p.addQuadCurve(to: CGPoint(x: rect.minX + 8, y: rect.minY), control: CGPoint(x: rect.minX + 2, y: rect.midY * 0.4))
        p.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX - 2, y: rect.midY * 0.4))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 8, y: rect.maxY), control: CGPoint(x: rect.maxX + 4, y: rect.maxY * 0.75))
        p.closeSubpath()
        return p
    }
}

public struct ClayBowlMiniShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 6, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY), control: CGPoint(x: rect.minX - 3, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - 6, y: rect.maxY), control: CGPoint(x: rect.maxX + 3, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

public struct PotShardShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 3))
        p.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 2))
        p.closeSubpath()
        return p
    }
}

// MARK: - Modals: Victory & Failure

public struct VictoryPopupModal: View {
    public let onContinue: () -> Void
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.green)
                
                Text("RAK BERDIRI KOKOH!")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Terima kasih Arthur! Berkat ganjalan batu bata dan pasak kayu darimu, rak tembikar Bu Mara tidak akan ambles lagi!")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                HStack(spacing: 16) {
                    HStack(spacing: 5) {
                        Text("🪙")
                        Text("+50 Koin")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    HStack(spacing: 5) {
                        Text("⭐")
                        Text("Reputasi Desa +10")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.45))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text("LANJUTKAN")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(14)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color(red: 0.14, green: 0.18, blue: 0.13))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.6), lineWidth: 1.5))
            .frame(maxWidth: 440)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

public struct FailurePopupModal: View {
    public let reason: ShelfFailReason
    public let onRetry: () -> Void
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.orange)
                
                Text(reason == .liftedTooHigh ? "DIANGKAT TERLALU TINGGI!" : "POT BU MARA JATUH PECAH!")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(reason == .liftedTooHigh
                     ? "Rak terangkat melampaui batas sehingga pot meluncur jatuh ke kiri."
                     : "Rak terlepas sebelum penopang terpasang, menyebabkan benturan keras!")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("COBA LAGI")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 10)
                    .background(Color(red: 1.0, green: 0.85, blue: 0.45))
                    .cornerRadius(14)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color(red: 0.18, green: 0.13, blue: 0.10))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.5), lineWidth: 1.5))
            .frame(maxWidth: 420)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Previews

#Preview("Bu Mara Shelf Minigame", traits: .landscapeLeft) {
    BuMaraShelfMinigameView()
}




