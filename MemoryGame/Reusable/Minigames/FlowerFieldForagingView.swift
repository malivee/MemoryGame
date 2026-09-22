import SwiftUI
import CoreHaptics

// MARK: - Data Models

public enum PlantSpecies: CaseIterable {
    case silverleaf     // Daun Perak Asli (Target Quest Kakek Beryn)
    case wildNettle     // Jelatang Berduri Liar (Pengecoh)
    case goldenBloom    // Bunga Emas Alpine (Bonus)
}

public struct HiddenHerbPatch: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var species: PlantSpecies
    public var isRevealed: Bool = false      // Terbuka setelah disibak semak
    public var isCollected: Bool = false     // Berhasil dipanen
    public var stemBend: CGFloat = 0.0       // Ketegangan/Lengkungan batang (0.0 ... 1.0)
    public var dragVector: CGSize = .zero
    public var isInspected: Bool = false     // Menampilkan sisi bawah daun
}

public struct WildFlowerCluster: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var petalColor: Color
    public var centerColor: Color
    public var scale: CGFloat
    public var swayOffset: CGFloat = 0.0     // Defleksi horizontal mahkota (Batang bawah tetap stay di tanah!)
    public var flowerType: Int               // 0: Daisy, 1: Bluebell, 2: Buttercup, 3: Lavender
}

public struct AmbientSpore: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var scale: CGFloat
    public var opacity: Double
    public var velocity: CGPoint
}

public struct FloatingHarvestLeaf: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var target: CGPoint
    public var scale: CGFloat = 1.0
    public var rotation: Double = 0.0
    public var opacity: Double = 1.0
}

// MARK: - Main View

public struct FlowerFieldForagingView: View {
    public var onComplete: (() -> Void)?
    public var onDismiss: (() -> Void)?
    
    public init(onComplete: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    // Quest Progress
    @State private var collectedCount: Int = 0
    private let targetQuota: Int = 3
    
    // Scenery & Interactive Plants
    @State private var wildFlowers: [WildFlowerCluster] = []
    @State private var herbPatches: [HiddenHerbPatch] = []
    @State private var ambientSpores: [AmbientSpore] = []
    @State private var floatingLeaves: [FloatingHarvestLeaf] = []
    
    // Active Interaction State
    @State private var activeHerbId: UUID? = nil
    @State private var toastMessage: String? = "Sibak bunga & tarik daun untuk memeriksa sisi peraknya"
    @State private var isShowingToast: Bool = true
    
    // The Hollow Horror Climax States
    @State private var isHorrorMode: Bool = false
    @State private var horrorFactor: Double = 0.0
    @State private var fogHeight: Double = 0.0
    @State private var heartbeatTimer: Timer?
    @State private var screenPulse: CGFloat = 1.0
    
    // Timers
    @State private var ambientTimer: Timer?
    
    // Taktil Haptics
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid) // SNAP!
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let successNotify = UINotificationFeedbackGenerator()
    
    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack {
                // 1. Latar Belakang Panorama Alam Pegunungan (100% Full Bleed Landscape)
                AlpinePanoramicBackground(horrorFactor: horrorFactor)
                    .ignoresSafeArea()
                
                // Cahaya Sore / Sunburst
                SunlightShimmerView()
                    .opacity(max(0.0, 1.0 - horrorFactor * 1.3))
                    .allowsHitTesting(false)
                
                // 2. Hamparan Rerumputan Lembah & Bunga Liar yang Menutup Tanaman Herbal
                ZStack {
                    // A. Siluet Rerumputan Belakang
                    RealisticAlpineGrassBed(horrorFactor: horrorFactor)
                        .allowsHitTesting(false)
                    
                    // B. Titik-Titik Tanaman Herbal Tersembunyi (Hidden Herb Stems)
                    ForEach(herbPatches) { patch in
                        if !patch.isCollected {
                            InteractiveHerbPlantNode(
                                patch: patch,
                                horrorFactor: horrorFactor,
                                isBeingPulled: activeHerbId == patch.id,
                                onCollectClick: {
                                    if let idx = herbPatches.firstIndex(where: { $0.id == patch.id }) {
                                        harvestSilverleaf(at: idx)
                                    }
                                }
                            )
                            .position(patch.position)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { val in
                                        handleHerbPull(patchId: patch.id, value: val)
                                    }
                                    .onEnded { val in
                                        handleHerbRelease(patchId: patch.id, value: val)
                                    }
                            )
                        }
                    }
                    
                    // C. Hamparan Bunga Liar yang Batangnya Tetap Tertanam dan Meliuk saat Digeser
                    ForEach(wildFlowers) { flower in
                        InteractiveWildflowerNode(flower: flower, horrorFactor: horrorFactor)
                            .position(flower.position)
                    }
                    
                    // D. Partikel Spora Bunga & Dandelion yang Melayang Lembut
                    ForEach(ambientSpores) { spore in
                        Circle()
                            .fill(Color.white.opacity(spore.opacity * (1.0 - horrorFactor * 0.8)))
                            .frame(width: 3.5 * spore.scale, height: 3.5 * spore.scale)
                            .position(spore.position)
                            .blur(radius: 0.5)
                    }
                    
                    // E. Animasi Daun yang Berhasil Dipetik Terbang ke HUD
                    ForEach(floatingLeaves) { leaf in
                        FloatingSilverleafEffect()
                            .scaleEffect(leaf.scale)
                            .rotationEffect(.degrees(leaf.rotation))
                            .opacity(leaf.opacity)
                            .position(leaf.position)
                    }
                }
                // Gestur Sentuh & Sibak Rumput (Swiping/Brushing to bend stalks and part the grass)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            brushMeadow(at: val.location)
                        }
                        .onEnded { _ in
                            returnMeadowToRest()
                        }
                )
                
                // 3. CLEAN & MINIMALIST FLOATING HUD
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    HStack(alignment: .center, spacing: 14) {
                        // Badge Koleksi Daun Perak (Sleek Glassmorphic Pill)
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(red: 0.95, green: 0.88, blue: 0.4))
                                
                                Text("DAUN PERAK")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            // Slot Indikator Daun
                            HStack(spacing: 6) {
                                ForEach(0..<targetQuota, id: \.self) { i in
                                    ZStack {
                                        Circle()
                                            .fill(i < collectedCount ? Color(red: 0.2, green: 0.5, blue: 0.4) : Color.black.opacity(0.35))
                                            .frame(width: 26, height: 26)
                                            .overlay(
                                                Circle()
                                                    .stroke(i < collectedCount ? Color.white.opacity(0.85) : Color.white.opacity(0.2), lineWidth: 1.2)
                                            )
                                        
                                        if i < collectedCount {
                                            Image(systemName: "leaf.fill")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color(red: 0.85, green: 0.98, blue: 1.0))
                                                .shadow(color: .white, radius: 4)
                                        } else {
                                            Circle()
                                                .fill(Color.white.opacity(0.12))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                            }
                            
                            Text("\(collectedCount)/\(targetQuota)")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundColor(Color(red: 0.88, green: 0.95, blue: 1.0))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 4)
                        
                        Spacer()
                        
                        // Tombol Tutup / Batal
                        if let onDismiss = onDismiss, !isHorrorMode {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 36, height: 36)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .opacity(isHorrorMode ? max(0.0, 1.0 - horrorFactor * 1.5) : 1.0)
                    
                    Spacer()
                    
                    // Floating Subtle Hint Chip di Bagian Bawah
                    if let msg = toastMessage, isShowingToast, !isHorrorMode {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.5))
                            
                            Text(msg)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .allowsHitTesting(!isHorrorMode)
                
                // 4. ATMOSFER HOROR: THE HOLLOW BERBURU
                if isHorrorMode {
                    TheHollowAtmosphericEncounter(
                        horrorFactor: horrorFactor,
                        fogHeight: fogHeight
                    )
                    .allowsHitTesting(false)
                    
                    TheHollowCinematicCard(
                        fogHeight: fogHeight,
                        onFlee: {
                            onComplete?()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(screenPulse)
            .onAppear {
                setupMeadow(in: size)
                startSporeDrift(in: size)
            }
            .onDisappear {
                ambientTimer?.invalidate()
                heartbeatTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Game Setup & Positioning
    
    private func setupMeadow(in size: CGSize) {
        let fieldWidth = max(size.width, 700)
        let fieldHeight = max(size.height, 350)
        
        // 1. Buat Bunga Liar Padang Rumput
        wildFlowers.removeAll()
        let flowerColors: [(Color, Color)] = [
            (Color(red: 0.96, green: 0.94, blue: 0.88), Color(red: 0.95, green: 0.8, blue: 0.2)), // Daisy Putih
            (Color(red: 0.98, green: 0.82, blue: 0.35), Color(red: 0.85, green: 0.65, blue: 0.1)), // Buttercup Emas
            (Color(red: 0.55, green: 0.72, blue: 0.96), Color(red: 0.35, green: 0.50, blue: 0.85)), // Bluebell Biru
            (Color(red: 0.78, green: 0.58, blue: 0.92), Color(red: 0.55, green: 0.35, blue: 0.75))  // Lavender Ungu
        ]
        
        let count = 48
        for i in 0..<count {
            let ftype = i % 4
            let colorPair = flowerColors[ftype]
            let fw = WildFlowerCluster(
                position: CGPoint(
                    x: CGFloat.random(in: 40...(fieldWidth - 40)),
                    y: CGFloat.random(in: (fieldHeight * 0.42)...(fieldHeight * 0.88))
                ),
                petalColor: colorPair.0,
                centerColor: colorPair.1,
                scale: CGFloat.random(in: 0.8...1.25),
                swayOffset: 0.0,
                flowerType: ftype
            )
            wildFlowers.append(fw)
        }
        
        // 2. Buat Titik-Titik Tanaman Herbal Tersembunyi (3 Daun Perak, 2 Jelatang Liar)
        herbPatches = [
            HiddenHerbPatch(position: CGPoint(x: fieldWidth * 0.22, y: fieldHeight * 0.65), species: .silverleaf),
            HiddenHerbPatch(position: CGPoint(x: fieldWidth * 0.38, y: fieldHeight * 0.52), species: .wildNettle),
            HiddenHerbPatch(position: CGPoint(x: fieldWidth * 0.52, y: fieldHeight * 0.72), species: .silverleaf),
            HiddenHerbPatch(position: CGPoint(x: fieldWidth * 0.70, y: fieldHeight * 0.58), species: .wildNettle),
            HiddenHerbPatch(position: CGPoint(x: fieldWidth * 0.82, y: fieldHeight * 0.68), species: .silverleaf)
        ]
    }
    
    // MARK: - Swiping & Rustling Mechanics (Batang Bunga Stay di Tanah, Mahkota Meliuk)
    
    private func brushMeadow(at touchLocation: CGPoint) {
        guard !isHorrorMode else { return }
        
        // 1. Lengkungkan batang bunga di dekat sentuhan jari (Pangkal tetap di tanah!)
        for i in wildFlowers.indices {
            let dx = touchLocation.x - wildFlowers[i].position.x
            let dy = touchLocation.y - wildFlowers[i].position.y
            let dist = hypot(dx, dy)
            
            if dist < 85 {
                let factor = 1.0 - (dist / 85.0)
                let pushDir: CGFloat = dx > 0 ? -1.0 : 1.0
                let targetDeflection = pushDir * (factor * 34.0)
                
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.55)) {
                    wildFlowers[i].swayOffset = targetDeflection
                }
                
                if Int(dist) % 18 == 0 {
                    lightImpact.impactOccurred(intensity: 0.25)
                }
            }
        }
        
        // 2. Sibak semak untuk membuka tanaman herbal tersembunyi
        for i in herbPatches.indices {
            guard !herbPatches[i].isRevealed else { continue }
            let dist = hypot(touchLocation.x - herbPatches[i].position.x, touchLocation.y - herbPatches[i].position.y)
            if dist < 55 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    herbPatches[i].isRevealed = true
                }
                mediumImpact.impactOccurred(intensity: 0.6)
                
                if herbPatches[i].species == .silverleaf {
                    showToast("Tangkai terungkap! Tarik untuk periksa sisi perak.")
                }
            }
        }
    }
    
    private func returnMeadowToRest() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.45)) {
            for i in wildFlowers.indices {
                wildFlowers[i].swayOffset = 0.0
            }
        }
    }
    
    // MARK: - Precision Pull & Sweet-Spot Harvest Mechanic
    
    private func handleHerbPull(patchId: UUID, value: DragGesture.Value) {
        guard !isHorrorMode else { return }
        guard let index = herbPatches.firstIndex(where: { $0.id == patchId }) else { return }
        
        activeHerbId = patchId
        
        let drag = value.translation
        let dragDist = hypot(drag.width, drag.height)
        
        // Batang dapat ditarik dengan batas natural (maksimal 70pt)
        let tensionRatio = min(1.2, dragDist / 65.0)
        herbPatches[index].stemBend = tensionRatio
        
        // Batang melengkung mengikuti tarikan jari
        let clampedX = max(-45, min(45, drag.width * 0.7))
        let clampedY = max(-50, min(50, drag.height * 0.7))
        herbPatches[index].dragVector = CGSize(width: clampedX, height: clampedY)
        
        // Mengintip sisi bawah daun ketika ditarik sedikit (> 0.25)
        if tensionRatio > 0.22 && !herbPatches[index].isInspected {
            herbPatches[index].isInspected = true
            lightImpact.impactOccurred(intensity: 0.5)
            
            if herbPatches[index].species == .silverleaf {
                showToast("✨ Berkilau perak! Ketuk 'PETIK' atau lepas di zona emas!")
            } else {
                showToast("Ini jelatang liar kusam tanpa kilau perak...")
            }
        }
        
        // Taktil detak saat memasuki Golden Sweet Spot (0.60 ... 0.95)
        if tensionRatio >= 0.60 && tensionRatio <= 0.95 {
            if Int(dragDist) % 8 == 0 {
                lightImpact.impactOccurred(intensity: 0.7)
            }
        } else if tensionRatio > 0.95 {
            if Int(dragDist) % 10 == 0 {
                heavyImpact.impactOccurred(intensity: 0.8)
            }
        }
    }
    
    private func handleHerbRelease(patchId: UUID, value: DragGesture.Value) {
        guard !isHorrorMode else { return }
        guard let index = herbPatches.firstIndex(where: { $0.id == patchId }) else { return }
        
        let tension = herbPatches[index].stemBend
        activeHerbId = nil
        
        // Cek apakah dilepas tepat di SWEET SPOT ZONE (0.60 ... 0.95)
        if tension >= 0.60 && tension <= 0.95 {
            rigidImpact.impactOccurred(intensity: 1.0)
            
            if herbPatches[index].species == .silverleaf {
                harvestSilverleaf(at: index)
            } else {
                showToast("Jelatang liar hancur. Bukan daun perak!")
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    herbPatches[index].stemBend = 0
                    herbPatches[index].dragVector = .zero
                    herbPatches[index].isInspected = false
                }
            }
        } else if tension > 0.95 {
            heavyImpact.impactOccurred(intensity: 0.8)
            showToast("Tarikan terlalu kasar! Daun terlepas sembarangan.")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                herbPatches[index].stemBend = 0
                herbPatches[index].dragVector = .zero
                herbPatches[index].isInspected = false
            }
        } else {
            // Ditarik kurang kuat: Batang membal kembali seperti senar elastis
            lightImpact.impactOccurred(intensity: 0.4)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) {
                herbPatches[index].stemBend = 0
                herbPatches[index].dragVector = .zero
                // Biarkan isInspected tetap terbuka sebentar agar pemain bisa melihat tombol petik
            }
        }
    }
    
    private func harvestSilverleaf(at index: Int) {
        let pos = herbPatches[index].position
        
        withAnimation(.easeInOut(duration: 0.2)) {
            herbPatches[index].isCollected = true
        }
        
        // Daun melayang masuk ke HUD Top Left
        let targetHUD = CGPoint(x: 100, y: 35)
        let flight = FloatingHarvestLeaf(
            position: pos,
            target: targetHUD,
            scale: 1.2,
            rotation: Double.random(in: -30...30),
            opacity: 1.0
        )
        floatingLeaves.append(flight)
        
        guard let flightIdx = floatingLeaves.firstIndex(where: { $0.id == flight.id }) else { return }
        
        withAnimation(.easeOut(duration: 0.35)) {
            floatingLeaves[flightIdx].position = CGPoint(x: pos.x - 20, y: pos.y - 45)
            floatingLeaves[flightIdx].scale = 1.35
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.45)) {
                if flightIdx < floatingLeaves.count {
                    floatingLeaves[flightIdx].position = targetHUD
                    floatingLeaves[flightIdx].scale = 0.4
                    floatingLeaves[flightIdx].opacity = 0.1
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            floatingLeaves.removeAll(where: { $0.id == flight.id })
            collectedCount += 1
            successNotify.notificationOccurred(.success)
            
            if collectedCount >= targetQuota {
                showToast("Semua Daun Perak terkumpul! Namun udara mendadak mencekam...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    triggerHorrorTransition()
                }
            } else {
                showToast("Daun Perak berhasil dipetik! (\(collectedCount)/\(targetQuota))")
            }
        }
    }
    
    // MARK: - Horror Sequence
    
    private func triggerHorrorTransition() {
        withAnimation(.easeInOut(duration: 0.4)) {
            isHorrorMode = true
        }
        
        withAnimation(.easeInOut(duration: 3.2)) {
            horrorFactor = 1.0
        }
        
        withAnimation(.easeOut(duration: 4.0)) {
            fogHeight = 1.0
        }
        
        var pulseCount = 0
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 1.15, repeats: true) { timer in
            heavyImpact.impactOccurred(intensity: 0.85)
            withAnimation(.easeInOut(duration: 0.12)) { screenPulse = 1.025 }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                heavyImpact.impactOccurred(intensity: 1.0)
                withAnimation(.easeInOut(duration: 0.12)) { screenPulse = 1.0 }
            }
            
            pulseCount += 1
            if pulseCount > 10 {
                timer.invalidate()
            }
        }
    }
    
    private func showToast(_ text: String) {
        toastMessage = text
        withAnimation { isShowingToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if toastMessage == text {
                withAnimation { isShowingToast = false }
            }
        }
    }
    
    private func startSporeDrift(in size: CGSize) {
        let safeW = max(size.width, 300)
        let safeH = max(size.height, 200)
        ambientSpores.removeAll()
        for _ in 0..<22 {
            ambientSpores.append(
                AmbientSpore(
                    position: CGPoint(x: CGFloat.random(in: 0...safeW), y: CGFloat.random(in: 0...safeH)),
                    scale: CGFloat.random(in: 0.6...1.4),
                    opacity: Double.random(in: 0.3...0.75),
                    velocity: CGPoint(x: CGFloat.random(in: 0.5...1.1), y: CGFloat.random(in: -0.2...0.2))
                )
            )
        }
        
        ambientTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in ambientSpores.indices {
                ambientSpores[i].position.x += ambientSpores[i].velocity.x
                ambientSpores[i].position.y += ambientSpores[i].velocity.y
                if ambientSpores[i].position.x > safeW + 20 {
                    ambientSpores[i].position.x = -10
                    ambientSpores[i].position.y = CGFloat.random(in: 0...safeH)
                }
            }
        }
    }
}

// MARK: - Subviews: Interactive Herb Plant Node (Daun Tetap Terhubung 100% ke Ujung Batang!)

public struct InteractiveHerbPlantNode: View {
    public let patch: HiddenHerbPatch
    public let horrorFactor: Double
    public let isBeingPulled: Bool
    public var onCollectClick: () -> Void
    
    public var body: some View {
        let frameW: CGFloat = 130
        let frameH: CGFloat = 130
        
        // 1. Titik Geometris Batang (Pangkal Tetap di Tanah!)
        let baseX: CGFloat = frameW / 2
        let baseY: CGFloat = frameH - 18
        
        // Ujung Batang (Tip) yang bergerak mengikuti tarikan
        let tipX: CGFloat = baseX + patch.dragVector.width
        let tipY: CGFloat = 46 + patch.dragVector.height
        
        // Titik Kontrol Lengkungan Bezier
        let ctrlX: CGFloat = baseX + patch.dragVector.width * 0.45
        let ctrlY: CGFloat = (baseY + tipY) * 0.55
        
        // Sudut Tangensial di Ujung Batang
        let dx = tipX - ctrlX
        let dy = tipY - ctrlY
        let stemAngle = Angle(radians: atan2(Double(dy), Double(dx))) + .degrees(90)
        
        ZStack {
            if patch.isRevealed {
                // A. Pendar Aura Indikator saat Tanaman Ditemukan
                Circle()
                    .fill(
                        patch.species == .silverleaf
                            ? RadialGradient(colors: [Color.white.opacity(0.4), Color.clear], center: .center, startRadius: 4, endRadius: 38)
                            : RadialGradient(colors: [Color.green.opacity(0.2), Color.clear], center: .center, startRadius: 4, endRadius: 30)
                    )
                    .frame(width: 80, height: 80)
                    .position(x: baseX, y: baseY - 35)
                    .scaleEffect(isBeingPulled ? 1.25 : 1.0)
                
                // B. Batang Tanaman yang Melengkung Mulus (Dynamic Curved Bezier Stem)
                Path { p in
                    p.move(to: CGPoint(x: baseX, y: baseY))
                    p.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: ctrlX, y: ctrlY))
                }
                .stroke(
                    horrorFactor > 0.5 ? Color(white: 0.15) : Color(red: 0.32, green: 0.52, blue: 0.22),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                
                // C. Daun Utama: DIKUNCI MATEMATIS 100% PADA UJUNG BATANG (tipX, tipY)
                // Tinggi daun 46pt -> Center ditaruh di tipY - 23, sehingga bagian bawah daun (petiole) persis di (tipX, tipY)
                ZStack {
                    // Sisi Depan: Hijau Segar
                    BotanicalLeafShape()
                        .fill(
                            LinearGradient(
                                colors: horrorFactor > 0.5
                                    ? [Color(white: 0.2), Color(white: 0.1)]
                                    : [Color(red: 0.35, green: 0.62, blue: 0.3), Color(red: 0.22, green: 0.45, blue: 0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotation3DEffect(.degrees(patch.isInspected ? 170 : 0), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.6)
                    
                    // Sisi Bawah: Mengkilap Perak Kristal jika Daun Perak Asli
                    if patch.species == .silverleaf {
                        BotanicalLeafShape()
                            .fill(
                                LinearGradient(
                                    colors: [.white, Color(red: 0.85, green: 0.94, blue: 1.0), Color(white: 0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(patch.isInspected ? 1.0 : 0.0)
                            .rotation3DEffect(.degrees(patch.isInspected ? 170 : 0), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.6)
                            .overlay(
                                Image(systemName: "sparkle")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .shadow(color: .white, radius: 6)
                                    .opacity(patch.isInspected ? 1.0 : 0.0)
                            )
                    }
                }
                .frame(width: 32, height: 46)
                .rotationEffect(stemAngle, anchor: .bottom)
                .position(x: tipX, y: tipY - 23)
                
                // D. TENSION & SWEET SPOT GAUGE ARC (Muncul Melingkari Ujung Batang saat Ditarik)
                if isBeingPulled {
                    ZStack {
                        // Background Arc
                        Circle()
                            .trim(from: 0.1, to: 0.9)
                            .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(90))
                        
                        // Golden Sweet Spot Zone (0.60 ... 0.95)
                        Circle()
                            .trim(from: 0.1 + (0.8 * 0.60), to: 0.1 + (0.8 * 0.95))
                            .stroke(Color(red: 0.98, green: 0.85, blue: 0.35).opacity(0.85), style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(90))
                            .shadow(color: Color.yellow.opacity(0.6), radius: 4)
                        
                        // Current Pull Needle
                        Circle()
                            .trim(from: 0.1, to: 0.1 + (0.8 * min(1.0, Double(patch.stemBend))))
                            .stroke(
                                patch.stemBend > 0.95
                                    ? Color.red
                                    : (patch.stemBend >= 0.60 ? Color.green : Color.white),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(90))
                    }
                    .position(x: tipX, y: tipY - 23)
                }
                
                // E. TOMBOL "CLICK TO COLLECT" (Muncul Saat Diperiksa & Terbukti Daun Perak!)
                if patch.isInspected && patch.species == .silverleaf && !patch.isCollected {
                    Button(action: onCollectClick) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                            Text("PETIK")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.22, green: 0.68, blue: 0.52), Color(red: 0.12, green: 0.48, blue: 0.36)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(14)
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.75), lineWidth: 1.2)
                        )
                        .shadow(color: Color(red: 0.22, green: 0.68, blue: 0.52).opacity(0.8), radius: 8)
                    }
                    .position(x: tipX, y: tipY - 58)
                    .transition(.scale.combined(with: .opacity))
                }
            } else {
                // Saat belum disibak: Hanya kilau pendar misterius di dasar semak
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 14, height: 14)
                    .position(x: baseX, y: baseY - 20)
                    .blur(radius: 4)
            }
        }
        .frame(width: frameW, height: frameH)
    }
}

// MARK: - Subviews: Interactive Wildflower (Batang Stay di Tanah & Meliuk Elastis saat Digeser)

public struct InteractiveWildflowerNode: View {
    public let flower: WildFlowerCluster
    public let horrorFactor: Double
    
    public var body: some View {
        let frameW: CGFloat = 70
        let frameH: CGFloat = 85
        
        // Pangkal Batang Tetap Tertanam di Tanah!
        let baseX: CGFloat = frameW / 2
        let baseY: CGFloat = frameH - 12
        
        // Mahkota Bunga Meliuk Mengikuti Defleksi
        let headX: CGFloat = baseX + flower.swayOffset
        let headY: CGFloat = 20 + abs(flower.swayOffset) * 0.12
        let ctrlX: CGFloat = baseX + flower.swayOffset * 0.55
        let ctrlY: CGFloat = 50
        
        let petCol = horrorFactor > 0.5 ? Color(white: 0.12) : flower.petalColor
        let stemCol = horrorFactor > 0.5 ? Color(white: 0.08) : Color(red: 0.28, green: 0.44, blue: 0.22)
        
        // Sudut kemiringan mahkota bunga sesuai lengkungan
        let crownAngle = Angle(degrees: Double(flower.swayOffset) * 1.1)
        
        ZStack {
            // A. Batang Melengkung Organik (Pangkal tetap di tanah, atas meliuk)
            Path { p in
                p.move(to: CGPoint(x: baseX, y: baseY))
                p.addQuadCurve(to: CGPoint(x: headX, y: headY), control: CGPoint(x: ctrlX, y: ctrlY))
            }
            .stroke(stemCol, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            
            // B. Mahkota Bunga Sesuai Spesies (Terkunci pada Ujung Batang headX, headY)
            Group {
                switch flower.flowerType {
                case 0:
                    // Daisy
                    ZStack {
                        ForEach(0..<8, id: \.self) { i in
                            Capsule()
                                .fill(petCol)
                                .frame(width: 4.2, height: 15)
                                .rotationEffect(.degrees(Double(i) * 22.5))
                        }
                        Circle().fill(flower.centerColor).frame(width: 7.5, height: 7.5)
                    }
                case 1:
                    // Bluebell
                    Circle()
                        .fill(petCol)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                case 2:
                    // Buttercup
                    ZStack {
                        ForEach(0..<5, id: \.self) { i in
                            Circle().fill(petCol).frame(width: 9.5, height: 9.5).offset(y: -4.8).rotationEffect(.degrees(Double(i) * 72))
                        }
                        Circle().fill(flower.centerColor).frame(width: 5.5, height: 5.5)
                    }
                default:
                    // Lavender
                    VStack(spacing: 2.2) {
                        Circle().fill(petCol).frame(width: 5, height: 5)
                        Circle().fill(petCol).frame(width: 6.5, height: 6.5)
                        Circle().fill(petCol).frame(width: 7.5, height: 7.5)
                    }
                }
            }
            .rotationEffect(crownAngle)
            .position(x: headX, y: headY)
        }
        .frame(width: frameW, height: frameH)
        .scaleEffect(flower.scale)
    }
}

// MARK: - Scenery & Shapes

public struct AlpinePanoramicBackground: View {
    public let horrorFactor: Double
    
    public var body: some View {
        Canvas { context, size in
            guard size.width > 10 && size.height > 10 else { return }
            let rect = CGRect(origin: .zero, size: size)
            
            // 1. Langit Senja Menawan -> Gelap Ashen Horror
            let skyTop = blendRGB(from: (0.95, 0.66, 0.42), to: (0.10, 0.08, 0.15), factor: horrorFactor)
            let skyBottom = blendRGB(from: (0.98, 0.86, 0.68), to: (0.18, 0.16, 0.22), factor: horrorFactor)
            context.fill(Path(rect), with: .linearGradient(Gradient(colors: [skyTop, skyBottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height * 0.6)))
            
            // 2. Siluet Puncak Gunung Jauh
            var farPeaks = Path()
            farPeaks.move(to: CGPoint(x: 0, y: size.height * 0.42))
            farPeaks.addLine(to: CGPoint(x: size.width * 0.25, y: size.height * 0.32))
            farPeaks.addLine(to: CGPoint(x: size.width * 0.45, y: size.height * 0.38))
            farPeaks.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.28))
            farPeaks.addLine(to: CGPoint(x: size.width, y: size.height * 0.36))
            farPeaks.addLine(to: CGPoint(x: size.width, y: size.height))
            farPeaks.addLine(to: CGPoint(x: 0, y: size.height))
            farPeaks.closeSubpath()
            
            let farColor = blendRGB(from: (0.58, 0.68, 0.65), to: (0.14, 0.14, 0.18), factor: horrorFactor)
            context.fill(farPeaks, with: .color(farColor))
            
            // 3. Bukit Rumput Bergelombang (Midground Ridge)
            var midHills = Path()
            midHills.move(to: CGPoint(x: 0, y: size.height * 0.52))
            midHills.addQuadCurve(to: CGPoint(x: size.width * 0.5, y: size.height * 0.46), control: CGPoint(x: size.width * 0.25, y: size.height * 0.54))
            midHills.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.50), control: CGPoint(x: size.width * 0.8, y: size.height * 0.40))
            midHills.addLine(to: CGPoint(x: size.width, y: size.height))
            midHills.addLine(to: CGPoint(x: 0, y: size.height))
            midHills.closeSubpath()
            
            let midColor = blendRGB(from: (0.42, 0.60, 0.35), to: (0.11, 0.12, 0.12), factor: horrorFactor)
            context.fill(midHills, with: .color(midColor))
            
            // 4. Lantai Padang Bunga Depan
            let floorRect = CGRect(x: 0, y: size.height * 0.50, width: size.width, height: size.height * 0.50)
            let floorColor = blendRGB(from: (0.32, 0.50, 0.26), to: (0.08, 0.09, 0.08), factor: horrorFactor)
            context.fill(Path(floorRect), with: .color(floorColor))
        }
    }
    
    private func blendRGB(from: (Double, Double, Double), to: (Double, Double, Double), factor: Double) -> Color {
        let r = from.0 + (to.0 - from.0) * factor
        let g = from.1 + (to.1 - from.1) * factor
        let b = from.2 + (to.2 - from.2) * factor
        return Color(red: r, green: g, blue: b)
    }
}

public struct SunlightShimmerView: View {
    public var body: some View {
        Canvas { context, size in
            guard size.width > 10 && size.height > 10 else { return }
            let sunCenter = CGPoint(x: size.width * 0.2, y: 0)
            for i in 0..<6 {
                let angle = Double(i) * 0.22 + 0.35
                var ray = Path()
                ray.move(to: sunCenter)
                ray.addLine(to: CGPoint(x: sunCenter.x + cos(angle) * 750, y: sunCenter.y + sin(angle) * 750))
                ray.addLine(to: CGPoint(x: sunCenter.x + cos(angle + 0.09) * 750, y: sunCenter.y + sin(angle + 0.09) * 750))
                ray.closeSubpath()
                context.fill(ray, with: .color(Color.yellow.opacity(0.1)))
            }
        }
    }
}

public struct RealisticAlpineGrassBed: View {
    public let horrorFactor: Double
    
    public var body: some View {
        Canvas { context, size in
            guard size.width > 10 && size.height > 10 else { return }
            let blades = 70
            let step = size.width / CGFloat(blades)
            let span = max(1, Int(size.height * 0.32))
            
            for i in 0..<blades {
                let baseX = CGFloat(i) * step + sin(CGFloat(i) * 1.5) * 5
                let baseY = size.height * 0.62 + CGFloat((i * 13) % span)
                let height = CGFloat(32 + (i * 9) % 28)
                
                var blade = Path()
                blade.move(to: CGPoint(x: baseX, y: baseY))
                blade.addQuadCurve(
                    to: CGPoint(x: baseX + CGFloat(i % 2 == 0 ? 8 : -8), y: baseY - height),
                    control: CGPoint(x: baseX + CGFloat(i % 2 == 0 ? 14 : -14), y: baseY - height * 0.5)
                )
                
                let grassCol = horrorFactor > 0.5 ? Color(white: 0.12) : Color(red: 0.28, green: 0.45, blue: 0.22)
                context.stroke(blade, with: .color(grassCol), lineWidth: 2.2)
            }
        }
    }
}

public struct BotanicalLeafShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX - 4, y: rect.maxY * 0.55),
            control2: CGPoint(x: rect.minX + 2, y: rect.minY * 0.25)
        )
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX - 2, y: rect.minY * 0.25),
            control2: CGPoint(x: rect.maxX + 4, y: rect.maxY * 0.55)
        )
        p.closeSubpath()
        return p
    }
}

public struct FloatingSilverleafEffect: View {
    public var body: some View {
        ZStack {
            BotanicalLeafShape()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.82, green: 0.94, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 26, height: 38)
                .shadow(color: .white, radius: 8)
            
            Image(systemName: "sparkle")
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Subviews: The Hollow Horror Atmosphere

public struct TheHollowAtmosphericEncounter: View {
    public let horrorFactor: Double
    public let fogHeight: Double
    
    public var body: some View {
        ZStack {
            Color.black.opacity(horrorFactor * 0.55).ignoresSafeArea()
            
            LinearGradient(
                colors: [Color(white: 0.85).opacity(0.85), Color(white: 0.65).opacity(0.4), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(fogHeight * 0.85)
            .offset(y: (1.0 - fogHeight) * -220)
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.8)],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

public struct TheHollowCinematicCard: View {
    public let fogHeight: Double
    public let onFlee: () -> Void
    
    public var body: some View {
        VStack(spacing: 16) {
            // Sepasang Mata Merah The Hollow Menyala di Balik Kabut
            HStack(spacing: 32) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 14, height: 14)
                    .shadow(color: .red, radius: 12)
                Circle()
                    .fill(Color.red)
                    .frame(width: 14, height: 14)
                    .shadow(color: .red, radius: 12)
            }
            .opacity(fogHeight > 0.4 ? 1.0 : 0.0)
            .animation(.easeIn(duration: 1.2), value: fogHeight)
            
            VStack(spacing: 6) {
                Text("THE HOLLOW TELAH TIBA!")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.35))
                    .shadow(color: .red.opacity(0.8), radius: 8)
                
                Text("Kabut dingin mencekam turun dari puncak hutan cemara...\nArthur merasakan hawa kematian mengintai dari balik kabut tebal!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(white: 0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
            }
            
            Button(action: onFlee) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 17, weight: .bold))
                    Text("LARI! KEMBALI KE DESA")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.4), Color.orange], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(12)
                .shadow(color: .orange.opacity(0.7), radius: 10)
            }
        }
        .padding(26)
        .background(Color(red: 0.11, green: 0.09, blue: 0.12).opacity(0.92))
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.red.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.9), radius: 24)
    }
}

// MARK: - Previews

#Preview("Flower Field Foraging", traits: .landscapeLeft) {
    FlowerFieldForagingView()
}
