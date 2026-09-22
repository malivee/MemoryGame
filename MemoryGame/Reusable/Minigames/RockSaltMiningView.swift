import SwiftUI
import CoreHaptics

// MARK: - Enums & Models

public enum MineralDepositType: Int, CaseIterable, Identifiable {
    case spire = 1
    case cubic = 2
    case geode = 3
    case twin = 4
    case block = 5
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .spire: return "Monolit Runcing"
        case .cubic: return "Kubus Halit"
        case .geode: return "Geoda Garam"
        case .twin: return "Kristal Kembar"
        case .block: return "Prisma Garam"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .spire: return "Pilar kristal tajam mengkilap"
        case .cubic: return "Bongkah kubus isometrik murni"
        case .geode: return "Gugusan kristal bersudut banyak"
        case .twin: return "Sepasang kristal bersilangan"
        case .block: return "Bongkah faset prisma bertingkat"
        }
    }
    
    // Warna tunggal seragam (Pure Crystalline Rock Salt)
    public static let unifiedSaltColor = Color(red: 0.72, green: 0.90, blue: 1.0)
    public static let unifiedGlowColor = Color(red: 0.60, green: 0.85, blue: 1.0)
}

public struct HarvestableDeposit: Identifiable {
    public let id = UUID()
    public let type: MineralDepositType
    public var position: CGPoint
    public var hitCount: Int = 0
    public let maxHits: Int = 3
    public var isHarvested: Bool = false
    public var crackSegments: [CrackSegment] = []
}

public struct SaltDustParticle: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var velocity: CGPoint
    public var scale: CGFloat = CGFloat.random(in: 0.6...1.6)
    public var opacity: Double = 1.0
    public var color: Color = .white
}

public struct CrackSegment: Identifiable {
    public let id = UUID()
    public var start: CGPoint
    public var end: CGPoint
    public var width: CGFloat
}

public struct RockImpactMark: Identifiable {
    public let id = UUID()
    public var center: CGPoint
    public var segments: [CrackSegment] = []
}

public struct FlyingSaltChunk: Identifiable {
    public let id = UUID()
    public let type: MineralDepositType
    public var position: CGPoint
    public var target: CGPoint
    public var scale: CGFloat = 1.0
    public var rotation: Double = 0.0
    public var opacity: Double = 1.0
}

// MARK: - Main View (Landscape)
public typealias RockSaltMiningView = RockSaltCarvingView

public struct RockSaltCarvingView: View {
    public var onComplete: (() -> Void)?
    public var onDismiss: (() -> Void)?
    
    public init(onComplete: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    // 5 Formasi Kristal Garam Satu Warna yang Tertanam di Tebing Gunung
    @State private var deposits: [HarvestableDeposit] = [
        HarvestableDeposit(type: .spire, position: CGPoint(x: 180, y: 110)),
        HarvestableDeposit(type: .cubic, position: CGPoint(x: 420, y: 115)),
        HarvestableDeposit(type: .geode, position: CGPoint(x: 300, y: 205)),
        HarvestableDeposit(type: .twin, position: CGPoint(x: 170, y: 300)),
        HarvestableDeposit(type: .block, position: CGPoint(x: 430, y: 295))
    ]
    
    // Pukulan batu biasa di tebing (di luar kristal)
    @State private var normalRockMarks: [RockImpactMark] = []
    
    // Status Animasi & Efek
    @State private var flyingChunks: [FlyingSaltChunk] = []
    @State private var particles: [SaltDustParticle] = []
    @State private var pickaxePosition: CGPoint = CGPoint(x: 460, y: 190)
    @State private var pickaxeRotation: Double = -20
    @State private var isGameCompleted: Bool = false
    @State private var screenShake: CGFloat = 0.0
    @State private var feedbackHint: String? = nil
    
    // Target tas di panel kiri
    private let bagPosition = CGPoint(x: 135, y: 180)
    
    // Haptics
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let successNotify = UINotificationFeedbackGenerator()
    
    private var harvestedCount: Int {
        deposits.filter { $0.isHarvested }.count
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background Gelap Tambang
                Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // PANEL KIRI: UI Quest & Kantong Khusus 5 Kristal
                    leftQuestPanel
                        .frame(width: 290)
                        .background(
                            ZStack {
                                Color(red: 0.11, green: 0.12, blue: 0.14)
                                LinearGradient(
                                    colors: [Color.black.opacity(0.6), Color.clear],
                                    startPoint: .trailing,
                                    endPoint: .leading
                                )
                            }
                        )
                        .zIndex(2)
                    
                    // PANEL KANAN: Dinding Tebing Gunung Garam dengan 5 Kristal Garam
                    ZStack {
                        // 1. Tekstur Tebing Pegunungan Garam Karst (Sesuai Foto)
                        SaltMountainKarstTexture()
                            .clipped()
                        
                        // 2. Retakan Pukulan pada Batu Tebing Biasa
                        Canvas { context, _ in
                            for mark in normalRockMarks {
                                for seg in mark.segments {
                                    var path = Path()
                                    path.move(to: seg.start)
                                    path.addLine(to: seg.end)
                                    context.stroke(
                                        path,
                                        with: .color(Color(white: 0.85).opacity(0.7)),
                                        style: StrokeStyle(lineWidth: seg.width, lineCap: .round)
                                    )
                                }
                            }
                        }
                        
                        // 3. Formasi 5 Kristal Garam yang Tertanam di Tebing (Satu Warna Seragam)
                        ForEach(deposits) { deposit in
                            ZStack {
                                if deposit.isHarvested {
                                    // Rongga tambang setelah kristal terangkat
                                    cleavedHoleView(at: deposit.position)
                                } else {
                                    // Kristal garam satu warna tertanam di batuan
                                    UniqueCrystalOutcropView(
                                        deposit: deposit,
                                        pulseAnimation: deposit.hitCount == 0
                                    )
                                    .position(deposit.position)
                                    
                                    // Retakan urat kristal putih murni saat dipukul
                                    Canvas { context, _ in
                                        for seg in deposit.crackSegments {
                                            var path = Path()
                                            path.move(to: seg.start)
                                            path.addLine(to: seg.end)
                                            
                                            // Glow kristal seragam
                                            context.stroke(
                                                path,
                                                with: .color(MineralDepositType.unifiedGlowColor.opacity(0.95)),
                                                style: StrokeStyle(lineWidth: seg.width, lineCap: .round, lineJoin: .round)
                                            )
                                            // Inti putih
                                            context.stroke(
                                                path,
                                                with: .color(.white),
                                                style: StrokeStyle(lineWidth: max(1.2, seg.width * 0.4), lineCap: .round)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 4. Partikel Debu & Serpihan Mineral Putih Bersinar
                        ForEach(particles) { pt in
                            Circle()
                                .fill(pt.color.opacity(pt.opacity))
                                .frame(width: 5 * pt.scale, height: 5 * pt.scale)
                                .position(pt.position)
                        }
                        
                        // 5. Kristal Terbang Menuju Kantong Sesuai Bentuknya
                        ForEach(flyingChunks) { chunk in
                            CrystalIconView(type: chunk.type, isCollected: true, size: 38)
                                .shadow(color: MineralDepositType.unifiedGlowColor.opacity(0.85), radius: 10)
                                .rotationEffect(.degrees(chunk.rotation))
                                .scaleEffect(chunk.scale)
                                .opacity(chunk.opacity)
                                .position(chunk.position)
                        }
                        
                        // 6. Beliung Tambang (Pickaxe)
                        PickaxeToolView()
                            .rotationEffect(.degrees(pickaxeRotation), anchor: .bottomLeading)
                            .position(pickaxePosition)
                            .animation(.easeOut(duration: 0.12), value: pickaxeRotation)
                            .allowsHitTesting(false)
                        
                        // 7. Notifikasi / Hint Melayang
                        if let hint = feedbackHint {
                            Text(hint)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(12)
                                .position(x: 320, y: 35)
                                .transition(.opacity)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                handlePickaxeStrike(at: value.location)
                            }
                    )
                    .offset(x: screenShake)
                }
                
                // Tombol Batal/Tutup
                if let onDismiss = onDismiss {
                    VStack {
                        HStack {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.75))
                                    .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .zIndex(10)
                }
                
                // Banner Kemenangan
                if isGameCompleted {
                    victoryModal
                        .zIndex(20)
                }
            }
        }
    }
    
    // MARK: - Left Quest Panel
    
    private var leftQuestPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.7))
                        .font(.system(size: 14))
                    Text("TAMBANG GARAM GUNUNG")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(Color(red: 0.95, green: 0.9, blue: 0.85))
                }
                
                Text("Panen 5 bongkah kristal garam putih murni di dinding tebing. Ayunkan beliung untuk memecahkan kerak batunya!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.65))
                    .lineSpacing(2)
            }
            
            // Daftar 5 Kristal Garam
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Kantong Ibu Anneth")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.75))
                    Spacer()
                    Text("\(harvestedCount)/\(deposits.count)")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                
                VStack(spacing: 6) {
                    ForEach(deposits) { deposit in
                        DepositQuestRowView(deposit: deposit)
                    }
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Petunjuk Alat
            HStack(spacing: 12) {
                Label {
                    Text("Beliung Baja")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                } icon: {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
                
                Label {
                    Text("3x Pukulan/Kristal")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                } icon: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                }
            }
            
            Spacer()
        }
        .padding(18)
    }
    
    // MARK: - Strike Logic
    
    private func handlePickaxeStrike(at tapLocation: CGPoint) {
        guard !isGameCompleted else { return }
        
        // Animasi Beliung
        pickaxePosition = CGPoint(x: tapLocation.x + 35, y: tapLocation.y - 45)
        pickaxeRotation = -50
        
        withAnimation(.easeIn(duration: 0.08)) {
            pickaxeRotation = 18
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            executeStrikeAt(tapLocation)
            
            withAnimation(.easeOut(duration: 0.15)) {
                pickaxeRotation = -15
            }
        }
    }
    
    private func executeStrikeAt(_ point: CGPoint) {
        // Cek apakah mengenai salah satu dari 5 formasi kristal garam (radius toleransi 50pt)
        if let index = deposits.firstIndex(where: { hypot($0.position.x - point.x, $0.position.y - point.y) < 50 && !$0.isHarvested }) {
            // Pukul Kristal Garam!
            heavyImpact.impactOccurred(intensity: 0.95)
            triggerShake(intensity: 6.0)
            spawnSparks(at: deposits[index].position, count: 22)
            
            deposits[index].hitCount += 1
            addCrackBranches(to: &deposits[index].crackSegments, center: deposits[index].position, intensity: deposits[index].hitCount)
            
            showHint("Menghantam \(deposits[index].type.title)! (\(deposits[index].hitCount)/\(deposits[index].maxHits))")
            
            if deposits[index].hitCount >= deposits[index].maxHits {
                harvestDeposit(at: index)
            }
        } else {
            // Memukul batuan tebing biasa
            mediumImpact.impactOccurred(intensity: 0.7)
            triggerShake(intensity: 3.5)
            spawnSparks(at: point, count: 12)
            
            var newMark = RockImpactMark(center: point)
            addCrackBranches(to: &newMark.segments, center: point, intensity: 1)
            normalRockMarks.append(newMark)
            if normalRockMarks.count > 15 {
                normalRockMarks.removeFirst()
            }
            
            showHint("Batuan tebing biasa. Incar formasi kristal garam putih!")
        }
    }
    
    private func addCrackBranches(to segments: inout [CrackSegment], center: CGPoint, intensity: Int) {
        let branchCount = Int.random(in: 4...6)
        let baseRadius: CGFloat = CGFloat(intensity) * 16.0
        
        for _ in 0..<branchCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let length = CGFloat.random(in: 14...baseRadius + 14)
            
            let mid = CGPoint(
                x: center.x + cos(angle) * (length * 0.5) + CGFloat.random(in: -3...3),
                y: center.y + sin(angle) * (length * 0.5) + CGFloat.random(in: -3...3)
            )
            let end = CGPoint(
                x: center.x + cos(angle) * length,
                y: center.y + sin(angle) * length
            )
            
            segments.append(CrackSegment(start: center, end: mid, width: CGFloat.random(in: 2.2...3.5)))
            segments.append(CrackSegment(start: mid, end: end, width: CGFloat.random(in: 1.2...2.2)))
        }
    }
    
    private func harvestDeposit(at index: Int) {
        deposits[index].isHarvested = true
        let deposit = deposits[index]
        
        heavyImpact.impactOccurred(intensity: 1.0)
        triggerShake(intensity: 9.0)
        spawnSparks(at: deposit.position, count: 35)
        
        let chunk = FlyingSaltChunk(
            type: deposit.type,
            position: deposit.position,
            target: bagPosition,
            scale: 1.2,
            rotation: Double.random(in: -30...30),
            opacity: 1.0
        )
        flyingChunks.append(chunk)
        
        guard let chunkIndex = flyingChunks.firstIndex(where: { $0.id == chunk.id }) else { return }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            flyingChunks[chunkIndex].position = CGPoint(x: deposit.position.x - 30, y: deposit.position.y - 45)
            flyingChunks[chunkIndex].rotation += 45
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                if chunkIndex < flyingChunks.count {
                    flyingChunks[chunkIndex].position = bagPosition
                    flyingChunks[chunkIndex].scale = 0.5
                    flyingChunks[chunkIndex].opacity = 0.0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            flyingChunks.removeAll(where: { $0.id == chunk.id })
            lightImpact.impactOccurred(intensity: 0.8)
            
            if harvestedCount >= deposits.count {
                successNotify.notificationOccurred(.success)
                withAnimation(.spring()) {
                    isGameCompleted = true
                }
                onComplete?()
            }
        }
    }
    
    private func showHint(_ text: String) {
        withAnimation { feedbackHint = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if feedbackHint == text {
                withAnimation { feedbackHint = nil }
            }
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
    
    private func spawnSparks(at origin: CGPoint, count: Int) {
        let colors: [Color] = [.white, MineralDepositType.unifiedSaltColor, Color(red: 0.88, green: 0.95, blue: 1.0)]
        for _ in 0..<count {
            let p = SaltDustParticle(
                position: origin,
                velocity: CGPoint(x: CGFloat.random(in: -45...45), y: CGFloat.random(in: -50...40)),
                scale: CGFloat.random(in: 0.6...2.0),
                color: colors.randomElement() ?? .white
            )
            particles.append(p)
        }
        
        withAnimation(.easeOut(duration: 0.45)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            particles.removeAll()
        }
    }
    
    private func cleavedHoleView(at center: CGPoint) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.02), Color(white: 0.08)],
                        center: .center,
                        startRadius: 6,
                        endRadius: 32
                    )
                )
                .frame(width: 62, height: 62)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.9), lineWidth: 8)
                        .blur(radius: 4)
                )
                .clipShape(Circle())
            
            ForEach(0..<6, id: \.self) { i in
                let angle = Double(i) * (.pi / 3.0)
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3.5, height: 3.5)
                    .offset(x: cos(angle) * 30, y: sin(angle) * 30)
            }
        }
        .position(center)
    }
    
    private var victoryModal: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 58))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 12)
                
                Text("TAMBANG SELESAI!")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("5 Bongkah Kristal Garam Pegunungan Murni Berhasil Dikumpulkan Lengkap Untuk Ibu Anneth.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Button(action: {
                    onDismiss?()
                }) {
                    Text("SIMPAN KE KANTONG")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .cornerRadius(10)
                        .shadow(color: .yellow.opacity(0.4), radius: 6)
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(Color(red: 0.14, green: 0.15, blue: 0.18))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.85), radius: 24)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Quest Row View

public struct DepositQuestRowView: View {
    public let deposit: HarvestableDeposit
    
    public init(deposit: HarvestableDeposit) {
        self.deposit = deposit
    }
    
    private var statusText: String {
        if deposit.isHarvested {
            return "Telah Berhasil Dipanen"
        } else if deposit.hitCount > 0 {
            return "Retak (\(deposit.hitCount)/\(deposit.maxHits))"
        } else {
            return deposit.type.subtitle
        }
    }
    
    private var statusColor: Color {
        if deposit.isHarvested {
            return .cyan
        } else if deposit.hitCount > 0 {
            return .yellow
        } else {
            return Color.white.opacity(0.4)
        }
    }
    
    private var backgroundColor: Color {
        deposit.isHarvested ? MineralDepositType.unifiedSaltColor.opacity(0.12) : Color.black.opacity(0.25)
    }
    
    private var borderColor: Color {
        deposit.isHarvested ? MineralDepositType.unifiedSaltColor.opacity(0.5) : Color.white.opacity(0.08)
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            CrystalIconView(type: deposit.type, isCollected: deposit.isHarvested, size: 30)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(deposit.type.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(deposit.isHarvested ? .white : Color.white.opacity(0.75))
                
                Text(statusText)
                    .font(.system(size: 9))
                    .foregroundColor(statusColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if deposit.isHarvested {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 14))
            } else if deposit.hitCount > 0 {
                Text("\(deposit.hitCount)/\(deposit.maxHits)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - 5 Crystal Shapes (Unified Pure Salt Color)

/// Tampilan formasi kristal di dinding tebing
public struct UniqueCrystalOutcropView: View {
    public let deposit: HarvestableDeposit
    public let pulseAnimation: Bool
    
    public var body: some View {
        ZStack {
            // Kerak mineral luar
            Circle()
                .fill(Color(white: 0.35).opacity(0.6))
                .frame(width: 68, height: 68)
                .blur(radius: 6)
            
            // Aura pendar kristal putih seragam
            Circle()
                .fill(MineralDepositType.unifiedGlowColor.opacity(0.28))
                .frame(width: 62, height: 62)
                .blur(radius: 8)
            
            // Bentuk fisik kristal garam sesuai tipenya (Satu Warna)
            switch deposit.type {
            case .spire:
                PrismaticSpireView(size: 46)
            case .cubic:
                CubicHaliteView(size: 42)
            case .geode:
                SaltGeodeView(size: 44)
            case .twin:
                TwinSpireView(size: 44)
            case .block:
                SteppedPrismView(size: 42)
            }
            
            // Indikator kilauan kristal
            Image(systemName: "sparkle")
                .font(.system(size: 13))
                .foregroundColor(.white)
                .offset(x: -14, y: -14)
                .shadow(color: .white, radius: 4)
        }
    }
}

/// 1. Monolit Runcing (Prismatic Spire)
public struct PrismaticSpireView: View {
    public let size: CGFloat
    
    public var body: some View {
        ZStack {
            PrismaticSpireShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.75, green: 0.90, blue: 0.98)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.55, height: size)
                .rotationEffect(.degrees(-15))
                .offset(x: -size * 0.18)
            
            PrismaticSpireShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.82, green: 0.93, blue: 0.98), Color(red: 0.65, green: 0.86, blue: 0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.65, height: size * 1.15)
                .shadow(color: Color.cyan.opacity(0.6), radius: 6)
            
            PrismaticSpireShape()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.3, height: size * 0.8)
                .rotationEffect(.degrees(20))
                .offset(x: size * 0.22, y: size * 0.1)
        }
    }
}

public struct PrismaticSpireShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.35))
        p.addLine(to: CGPoint(x: rect.width * 0.85, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.maxY * 0.95))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.45))
        p.closeSubpath()
        return p
    }
}

/// 2. Kubus Halit Isometrik (Cubic Halite)
public struct CubicHaliteView: View {
    public let size: CGFloat
    
    public var body: some View {
        ZStack {
            IsometricCubeView(size: size * 0.48, faceColor: Color(red: 0.72, green: 0.88, blue: 0.98))
                .offset(x: size * 0.2, y: size * 0.18)
            
            IsometricCubeView(size: size * 0.52, faceColor: Color(red: 0.85, green: 0.95, blue: 1.0))
                .offset(x: -size * 0.18, y: -size * 0.15)
            
            IsometricCubeView(size: size * 0.65, faceColor: .white)
                .shadow(color: Color.white.opacity(0.8), radius: 6)
        }
    }
}

public struct IsometricCubeView: View {
    public let size: CGFloat
    public let faceColor: Color
    
    public var body: some View {
        ZStack {
            Path { p in
                let w = size
                let h = size * 0.55
                p.move(to: CGPoint(x: w * 0.5, y: 0))
                p.addLine(to: CGPoint(x: w, y: h * 0.5))
                p.addLine(to: CGPoint(x: w * 0.5, y: h))
                p.addLine(to: CGPoint(x: 0, y: h * 0.5))
                p.closeSubpath()
            }
            .fill(faceColor)
            .offset(y: -size * 0.25)
            
            Path { p in
                let w = size * 0.5
                let h = size * 0.55
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: w, y: h * 0.5))
                p.addLine(to: CGPoint(x: w, y: h * 1.5))
                p.addLine(to: CGPoint(x: 0, y: h))
                p.closeSubpath()
            }
            .fill(faceColor.opacity(0.7))
            .offset(x: -size * 0.25, y: size * 0.02)
            
            Path { p in
                let w = size * 0.5
                let h = size * 0.55
                p.move(to: CGPoint(x: 0, y: h * 0.5))
                p.addLine(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: 0, y: h * 1.5))
                p.closeSubpath()
            }
            .fill(faceColor.opacity(0.5))
            .offset(x: size * 0.25, y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

/// 3. Geoda Garam (Salt Geode Cluster)
public struct SaltGeodeView: View {
    public let size: CGFloat
    
    public var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * 45.0
                JaggedSpikeShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(red: 0.72, green: 0.89, blue: 0.98)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.35, height: size * 0.85)
                    .rotationEffect(.degrees(angle))
            }
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(red: 0.80, green: 0.93, blue: 0.99)],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.3
                    )
                )
                .frame(width: size * 0.42, height: size * 0.42)
                .shadow(color: Color.white.opacity(0.8), radius: 6)
        }
        .frame(width: size, height: size)
    }
}

public struct JaggedSpikeShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

/// 4. Kristal Kembar (Twin Crystal Spire)
public struct TwinSpireView: View {
    public let size: CGFloat
    
    public var body: some View {
        ZStack {
            PrismaticSpireShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.70, green: 0.88, blue: 0.98)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.5, height: size * 1.1)
                .rotationEffect(.degrees(-22))
                .offset(x: -size * 0.12)
            
            PrismaticSpireShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.82, green: 0.94, blue: 1.0), Color(red: 0.65, green: 0.86, blue: 0.96)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.48, height: size * 0.95)
                .rotationEffect(.degrees(18))
                .offset(x: size * 0.12, y: size * 0.08)
                .shadow(color: Color.cyan.opacity(0.5), radius: 6)
        }
        .frame(width: size, height: size)
    }
}

/// 5. Prisma Garam Berundak (Stepped Prism Block)
public struct SteppedPrismView: View {
    public let size: CGFloat
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.74, green: 0.90, blue: 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.9, height: size * 0.65)
                .rotationEffect(.degrees(-10))
                .shadow(color: Color.white.opacity(0.7), radius: 5)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.85, green: 0.95, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.65, height: size * 0.45)
                .rotationEffect(.degrees(15))
        }
        .frame(width: size, height: size)
    }
}

/// Icon kristal untuk slot inventory di panel kiri (Satu Warna)
public struct CrystalIconView: View {
    public let type: MineralDepositType
    public let isCollected: Bool
    public let size: CGFloat
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(isCollected ? MineralDepositType.unifiedSaltColor.opacity(0.18) : Color.white.opacity(0.04))
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isCollected ? MineralDepositType.unifiedSaltColor.opacity(0.8) : Color.white.opacity(0.15), lineWidth: 1.2)
                )
            
            if isCollected {
                switch type {
                case .spire:
                    PrismaticSpireView(size: size * 0.7)
                case .cubic:
                    CubicHaliteView(size: size * 0.65)
                case .geode:
                    SaltGeodeView(size: size * 0.65)
                case .twin:
                    TwinSpireView(size: size * 0.7)
                case .block:
                    SteppedPrismView(size: size * 0.65)
                }
            } else {
                // Siluet redup
                switch type {
                case .spire:
                    PrismaticSpireShape()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                        .frame(width: size * 0.4, height: size * 0.6)
                case .cubic:
                    Rectangle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                        .frame(width: size * 0.45, height: size * 0.45)
                case .geode:
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                        .frame(width: size * 0.45, height: size * 0.45)
                case .twin:
                    Image(systemName: "sparkles")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(Color.white.opacity(0.2))
                case .block:
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                        .frame(width: size * 0.5, height: size * 0.35)
                }
            }
        }
    }
}

// MARK: - Mountain Texture & Pickaxe View

/// Tekstur tebing pegunungan garam dengan guratan vertikal bertingkat (Sesuai foto gunung garam asli)
public struct SaltMountainKarstTexture: View {
    public init() {}
    
    public var body: some View {
        Canvas { context, size in
            guard size.width > 10 && size.height > 10 else { return }
            let hSpan = max(1, Int(size.height))
            
            // 1. Dasar Dinding Batuan Garam (Warna abu-abu kapur & mineral tan muda)
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(Color(red: 0.72, green: 0.72, blue: 0.74)))
            
            // 2. Garis Lapies Karst Vertikal & Miring (Sesuai alur erosi vertikal pada foto)
            let ribsCount = 48
            let step = size.width / CGFloat(ribsCount)
            
            for i in 0...ribsCount {
                let baseX = CGFloat(i) * step
                var darkCrevicePath = Path()
                var lightCrestPath = Path()
                
                let startX = baseX + sin(CGFloat(i) * 0.8) * 18
                let midX = startX - 35 + sin(CGFloat(i) * 1.4) * 22
                let endX = startX - 65 + cos(CGFloat(i) * 0.9) * 15
                
                darkCrevicePath.move(to: CGPoint(x: startX, y: -20))
                darkCrevicePath.addQuadCurve(
                    to: CGPoint(x: endX, y: size.height + 20),
                    control: CGPoint(x: midX, y: size.height * 0.5)
                )
                
                lightCrestPath.move(to: CGPoint(x: startX + 4, y: -20))
                lightCrestPath.addQuadCurve(
                    to: CGPoint(x: endX + 4, y: size.height + 20),
                    control: CGPoint(x: midX + 4, y: size.height * 0.5)
                )
                
                let shadowColor = (i % 3 == 0) ? Color(red: 0.28, green: 0.27, blue: 0.30) : Color(red: 0.42, green: 0.41, blue: 0.44)
                context.stroke(
                    darkCrevicePath,
                    with: .color(shadowColor.opacity(0.65)),
                    lineWidth: (i % 2 == 0) ? 6 : 4
                )
                
                context.stroke(
                    lightCrestPath,
                    with: .color(Color.white.opacity(0.85)),
                    lineWidth: (i % 3 == 0) ? 4.5 : 2.5
                )
            }
            
            // 3. Retakan silang diagonal halus
            for j in 0...16 {
                let y = CGFloat(j) * (size.height / 14)
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y + CGFloat.random(in: -10...10)))
                p.addLine(to: CGPoint(x: size.width, y: y + 25 + CGFloat.random(in: -10...10)))
                context.stroke(p, with: .color(Color.black.opacity(0.12)), lineWidth: 1.5)
            }
            
            // 4. Lapisan endapan mineral garam putih
            for k in stride(from: 40, to: Int(size.width), by: 95) {
                let rectSalt = CGRect(x: CGFloat(k), y: CGFloat((k * 3) % hSpan), width: 75, height: 110)
                context.fill(Path(ellipseIn: rectSalt), with: .color(Color.white.opacity(0.18)))
            }
            
            // 5. Vignette alami
            let vignetteGrad = Gradient(colors: [.clear, Color.black.opacity(0.55)])
            context.fill(
                Path(rect),
                with: .radialGradient(
                    vignetteGrad,
                    center: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                    startRadius: size.width * 0.25,
                    endRadius: size.width * 0.75
                )
            )
        }
    }
}

/// Beliung Tambang (Pickaxe) dengan Gagang Kayu & Kepala Baja Melengkung
public struct PickaxeToolView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. Gagang Kayu Beliung
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.28, blue: 0.16),
                            Color(red: 0.32, green: 0.19, blue: 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 110)
                .overlay(
                    Capsule().stroke(Color.black.opacity(0.4), lineWidth: 1)
                )
                .rotationEffect(.degrees(32))
                .offset(x: 28, y: 35)
            
            // 2. Cincin Besi Pengikat Kepala
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color(white: 0.5), Color(white: 0.2)], startPoint: .top, endPoint: .bottom))
                .frame(width: 14, height: 14)
                .offset(x: 0, y: -2)
            
            // 3. Kepala Beliung Baja Melengkung
            PickaxeHeadShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.86, blue: 0.90),
                            Color(red: 0.50, green: 0.52, blue: 0.58),
                            Color(red: 0.28, green: 0.30, blue: 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 90, height: 42)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 2, y: 3)
            
            // 4. Kilauan Tajam di Ujung Penusuk
            Circle()
                .fill(Color.white)
                .frame(width: 3.5, height: 3.5)
                .shadow(color: .white, radius: 4)
                .offset(x: -42, y: 16)
        }
        .frame(width: 120, height: 120)
    }
}

public struct PickaxeHeadShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        
        p.move(to: CGPoint(x: midX, y: rect.minY + 6))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY * 0.85),
            control: CGPoint(x: rect.width * 0.2, y: rect.minY + 2)
        )
        p.addLine(to: CGPoint(x: rect.minX + 3, y: rect.maxY * 0.95))
        p.addQuadCurve(
            to: CGPoint(x: midX - 6, y: rect.midY + 6),
            control: CGPoint(x: rect.width * 0.25, y: rect.maxY * 0.45)
        )
        
        p.addLine(to: CGPoint(x: midX + 6, y: rect.midY + 6))
        
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - 2, y: rect.maxY * 0.7),
            control: CGPoint(x: rect.width * 0.75, y: rect.maxY * 0.4)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.5))
        p.addQuadCurve(
            to: CGPoint(x: midX, y: rect.minY + 6),
            control: CGPoint(x: rect.width * 0.8, y: rect.minY + 4)
        )
        
        p.closeSubpath()
        return p
    }
}

// MARK: - Previews
#Preview("Rock Salt Mining - Mountain Wall", traits: .landscapeLeft) {
    RockSaltMiningView()
}
