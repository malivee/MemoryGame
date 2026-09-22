import SwiftUI
import SpriteKit
import CoreHaptics

// MARK: - Game Phases

public enum EliasDiscoveryPhase: Int, CaseIterable {
    case clearingMud = 0       // Fase 1: Membersihkan lapisan lumpur tebal dengan kuas/usapan jari
    case pryingRoots = 1       // Fase 2: Mendongkrak jepitan akar purba dengan tuas besi
    case cuttingStraps = 2     // Fase 3: Memotong tali lapuk & memecahkan segel lilin merah
    case unlockingClasp = 3    // Fase 4: Menggeser gerendel gesper kuningan antik
    case readingJournal = 4    // Fase 5: Membaca buku jurnal asli menggunakan BookScene game
    case horrorReveal = 5      // Fase 6: Pengungkapan misteri The Boundary & penyelesaian quest
}

// Sel petak lumpur organik untuk pembersihan taktil
public struct MudCell: Identifiable {
    public let id: Int
    public var center: CGPoint
    public var size: CGSize
    public var opacity: Double = 1.0
    public var isCleaned: Bool = false
    public var sludgeVariant: Int = Int.random(in: 0...3)
    public var rotation: Double = Double.random(in: -25...25)
}

// Partikel percikan & remah lumpur yang beterbangan
public struct MudSplashParticle: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var velocity: CGPoint
    public var scale: CGFloat
    public var opacity: Double = 1.0
    public var rotation: Double = Double.random(in: 0...360)
}

// MARK: - Main View

public struct EliasJournalDiscoveryView: View {
    public var onComplete: (() -> Void)?
    public var onDismiss: (() -> Void)?
    public var onOpenBook: (() -> Void)?
    
    public init(
        onComplete: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        onOpenBook: (() -> Void)? = nil
    ) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        self.onOpenBook = onOpenBook
    }
    
    // Alur Fase
    @State private var currentPhase: EliasDiscoveryPhase = .clearingMud
    
    // FASE 1: Grid Lumpur Organik, Pembersihan Taktil, & Partikel
    @State private var mudCells: [MudCell] = []
    @State private var cleanedCellsCount: Int = 0
    @State private var totalMudCells: Int = 140
    @State private var mudSplashes: [MudSplashParticle] = []
    @State private var cleanPercentage: Int = 0
    @State private var isAutoWipingFinished: Bool = false
    @State private var activeScrubPosition: CGPoint? = nil
    @State private var scrubGleamOffset: CGFloat = -200
    @State private var lastHapticPercentage: Int = 0
    
    // FASE 2: Menarik Buku Langsung dari Jepitan Akar Purba
    @State private var bookPullOffset: CGSize = .zero
    @State private var bookPullProgress: CGFloat = 0.0
    @State private var rootSpread: CGFloat = 0.0
    @State private var bookEscapeOffsetY: CGFloat = 0.0
    @State private var isBookFreed: Bool = false
    @State private var fallingDirtParticles: [MudSplashParticle] = []
    @State private var lastTensionHapticThreshold: Int = 0
    
    // FASE 3: Pemotongan Tali & Segel Lilin
    @State private var isHorizontalStrapCut: Bool = false
    @State private var isVerticalStrapCut: Bool = false
    @State private var waxSealHealth: Int = 2 // 2: Utuh, 1: Retak, 0: Pecah
    
    // FASE 4: Gesper Kuningan Antik (Antique Brass Clasp)
    @State private var claspSlideOffset: CGFloat = 0.0
    @State private var isClaspUnlocked: Bool = false
    @State private var isBookCoverOpen: Bool = false
    
    // FASE 5: UI BUKU ASLI DARI GAME (BookScene via SpriteKit)
    @State private var embeddedBookScene: BookScene?
    
    // FASE 6: Horor & Getaran Layar
    @State private var horrorAmbientFactor: Double = 0.0
    @State private var screenShakeOffset: CGFloat = 0.0
    @State private var heartbeatTimer: Timer?
    @State private var screenPulse: CGFloat = 1.0
    
    // Taktil Haptics
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid) // SNAP & CLACK
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let successNotify = UINotificationFeedbackGenerator()
    
    public var body: some View {
        GeometryReader { proxy in
            let rawSize = proxy.size
            let screenSize = CGSize(
                width: rawSize.width > 50 ? rawSize.width : 844,
                height: rawSize.height > 50 ? rawSize.height : 390
            )
            
            ZStack {
                // 1. Latar Belakang Ceruk Tebing Tanah Longsor
                LandslideCavityBackground(horrorFactor: horrorAmbientFactor)
                    .ignoresSafeArea()
                
                // Cahaya Lentera Hangat
                LanternLightAura()
                    .opacity(max(0.12, 1.0 - horrorAmbientFactor * 0.8))
                    .allowsHitTesting(false)
                
                // 2. KONTEN UTAMA SESUAI FASE
                ZStack {
                    if currentPhase == .clearingMud || currentPhase == .pryingRoots {
                        // FASE 1 & 2: BUKU TERJEPIT AKAR DI TANAH LONGSOR
                        cakedBookInRootsScene(screenSize: screenSize)
                    } else {
                        // FASE 3, 4, 5, 6: CLOSE-UP BUKU & PEMBACA BUKU ASLI (BookScene)
                        closeUpJournalInspectionScene(screenSize: screenSize)
                    }
                }
                .offset(x: screenShakeOffset)
                
                // 3. MINIMALIST STORYBOOK TOP BAR HUD
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        // Badge Judul & Indikator 5 Langkah Progres
                        HStack(spacing: 12) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))
                            
                            Text("BUKU CATATAN ELIAS")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            // 5 Pip Langkah Progres
                            HStack(spacing: 5) {
                                ForEach(0..<5, id: \.self) { step in
                                    Circle()
                                        .fill(step <= currentPhase.rawValue ? Color(red: 0.95, green: 0.82, blue: 0.45) : Color.white.opacity(0.2))
                                        .frame(width: 7, height: 7)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Meteran Kebersihan Lumpur saat di Fase 1
                        if currentPhase == .clearingMud {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(cleanPercentage >= 80 ? .yellow : .cyan)
                                Text("Lumpur Bersih: \(cleanPercentage)%")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: cleanPercentage >= 80
                                        ? [Color.orange.opacity(0.7), Color.black.opacity(0.7)]
                                        : [Color.black.opacity(0.7), Color.black.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(cleanPercentage >= 80 ? Color.yellow.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Meteran Regangan Tarikan Buku di Fase 2
                        if currentPhase == .pryingRoots {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(bookPullProgress >= 0.85 ? .green : .orange)
                                Text("Regangan Akar: \(Int(bookPullProgress * 100))%")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: bookPullProgress >= 0.85
                                        ? [Color.green.opacity(0.7), Color.black.opacity(0.7)]
                                        : [Color.black.opacity(0.7), Color.black.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(bookPullProgress >= 0.85 ? Color.green.opacity(0.6) : Color.orange.opacity(0.4), lineWidth: 1)
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                        
                        // Tombol Tutup / Batal
                        if let onDismiss = onDismiss, currentPhase != .horrorReveal {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white.opacity(0.85))
                                    .frame(width: 34, height: 34)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    
                    Spacer()
                    
                    // Floating Subtle Hint di Bagian Bawah
                    if currentPhase != .horrorReveal {
                        HStack(spacing: 8) {
                            Image(systemName: hintIconForPhase)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.5))
                            
                            Text(hintTextForPhase)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // 4. KLIMAKS HOROR & KONEKSI KE BOOKSCENE
                if currentPhase == .horrorReveal {
                    horrorCinematicOverlay(screenSize: screenSize)
                        .transition(.opacity)
                }
            }
            .scaleEffect(screenPulse)
            .onAppear {
                initMudGrid()
                setupEmbeddedBookScene(screenSize: screenSize)
            }
            .onDisappear {
                heartbeatTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Scene 1: Lumpur & Dongkrak Akar (Fase 1 & 2)
    
    @ViewBuilder
    private func cakedBookInRootsScene(screenSize: CGSize) -> some View {
        let centerX = screenSize.width * 0.52
        let centerY = screenSize.height * 0.54
        let bookW: CGFloat = 155
        let bookH: CGFloat = 200
        let bookOriginX = centerX - bookW / 2
        let bookOriginY = centerY - bookH / 2 + bookEscapeOffsetY
        
        ZStack {
            // A. Bungkusan Buku Bersampul Kulit Kuno Khas Game (Dengan Posisi Tarikan & Kemiringan Fisik)
            BundledJournalCoverView(isCakedInMud: currentPhase == .clearingMud && cleanPercentage < 60)
                .rotationEffect(.degrees(isBookFreed ? 0 : Double(bookPullOffset.width * 0.07)))
                .position(
                    x: centerX + (isBookFreed ? 0 : bookPullOffset.width),
                    y: centerY + bookEscapeOffsetY + (isBookFreed ? 0 : bookPullOffset.height)
                )
                .scaleEffect(isBookFreed ? 1.25 : (1.0 + rootSpread * 0.04))
                .shadow(color: .black.opacity(0.7), radius: 14, y: 8)
                .allowsHitTesting(false)
            
            // B. LAPISAN LUMPUR ORGANIK (Visual Saja)
            if currentPhase == .clearingMud {
                ZStack {
                    // 1. Lapisan Dasar Lumpur Basah dan Lengket (Dark Viscous Clay)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.14, blue: 0.08),
                                    Color(red: 0.14, green: 0.09, blue: 0.05),
                                    Color(red: 0.10, green: 0.07, blue: 0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(max(0, 1.0 - Double(cleanPercentage) / 80.0))
                    
                    // 2. Sel-Sel Gumpalan Lumpur Organik (Peelable Organic Mud Patches)
                    Canvas { context, size in
                        for cell in mudCells where !cell.isCleaned {
                            let rect = CGRect(
                                x: cell.center.x - cell.size.width / 2,
                                y: cell.center.y - cell.size.height / 2,
                                width: cell.size.width,
                                height: cell.size.height
                            )
                            
                            // Variasi Warna Lumpur (Lumpur hitam, tanah liat cokelat, lumut basah)
                            let sludgeColor: Color
                            switch cell.sludgeVariant {
                            case 0:
                                sludgeColor = Color(red: 0.24, green: 0.17, blue: 0.10)
                            case 1:
                                sludgeColor = Color(red: 0.18, green: 0.12, blue: 0.07)
                            case 2:
                                sludgeColor = Color(red: 0.15, green: 0.10, blue: 0.06)
                            default:
                                sludgeColor = Color(red: 0.22, green: 0.16, blue: 0.11)
                            }
                            
                            context.opacity = cell.opacity
                            // Gambar gumpalan oval lumpur
                            context.fill(Path(ellipseIn: rect), with: .color(sludgeColor))
                            
                            // Bintik tekstur tanah / kerikil kecil pada sebagian sel
                            if cell.id % 4 == 0 {
                                let speckRect = CGRect(x: cell.center.x - 2, y: cell.center.y - 2, width: 4, height: 3)
                                context.fill(Path(ellipseIn: speckRect), with: .color(Color.black.opacity(0.35)))
                            }
                        }
                    }
                    .frame(width: bookW, height: bookH)
                    .allowsHitTesting(false)
                    
                    // 3. Efek Kilau Lumpur Basah yang Masih Melekat
                    Canvas { context, size in
                        for cell in mudCells where !cell.isCleaned && cell.id % 5 == 0 {
                            let gleamRect = CGRect(x: cell.center.x - 3, y: cell.center.y - 3, width: 6, height: 4)
                            context.fill(Path(ellipseIn: gleamRect), with: .color(Color.white.opacity(0.18 * cell.opacity)))
                        }
                    }
                    .frame(width: bookW, height: bookH)
                    .allowsHitTesting(false)
                    
                    // 4. Efek Sapuan Kilau Pembersihan (Auto-wiping Shimmer Ray saat Bersih)
                    if isAutoWipingFinished {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color.yellow.opacity(0.6), Color.white.opacity(0.8), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 260)
                            .rotationEffect(.degrees(25))
                            .offset(x: scrubGleamOffset)
                    }
                }
                .frame(width: bookW, height: bookH)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .position(x: centerX, y: centerY + bookEscapeOffsetY)
                .allowsHitTesting(false)
            }
            
            // C. Akar Purba Menjepit (Atas & Bawah) - Hit testing dimatikan agar tidak memblokir swipe
            AncientRootArmShape(isTop: true)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.16, blue: 0.11), Color(red: 0.14, green: 0.10, blue: 0.07)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 320, height: 140)
                .offset(y: -rootSpread * 52)
                .position(x: centerX, y: centerY - 65)
                .shadow(color: .black.opacity(0.8), radius: 8, y: 5)
                .allowsHitTesting(false)
            
            AncientRootArmShape(isTop: false)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.18, green: 0.13, blue: 0.09), Color(red: 0.12, green: 0.08, blue: 0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 340, height: 150)
                .offset(y: rootSpread * 38)
                .position(x: centerX, y: centerY + 70)
                .shadow(color: .black.opacity(0.8), radius: 10, y: -4)
                .allowsHitTesting(false)
            
            // D. AREA SENTUHAN & GESTURE SWIPE MEMBERSIHKAN LUMPUR PADA BUKU
            if currentPhase == .clearingMud && !isAutoWipingFinished {
                Color.clear
                    .frame(width: bookW + 40, height: bookH + 40)
                    .contentShape(Rectangle())
                    .position(x: centerX, y: centerY + bookEscapeOffsetY)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("CakedRootsScene"))
                            .onChanged { val in
                                guard currentPhase == .clearingMud && !isAutoWipingFinished else { return }
                                let touchPos = val.location
                                activeScrubPosition = touchPos
                                
                                let localX = touchPos.x - bookOriginX
                                let localY = touchPos.y - bookOriginY
                                let localPoint = CGPoint(x: localX, y: localY)
                                
                                handleMudScrubTouch(localPoint: localPoint, globalPoint: touchPos)
                            }
                            .onEnded { _ in
                                activeScrubPosition = nil
                            }
                    )
            }
            
            // E. Sparkle & Brush Glow Mengikuti Jari Player Persis di Posisi Touch
            if let scrubPos = activeScrubPosition, currentPhase == .clearingMud {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        .frame(width: 46, height: 46)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 26
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .position(scrubPos)
                .allowsHitTesting(false)
            }
            
            // F. Percikan Butiran Lumpur Beterbangan
            if currentPhase == .clearingMud {
                ForEach(mudSplashes) { splash in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.28, green: 0.20, blue: 0.12), Color(red: 0.18, green: 0.12, blue: 0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 7 * splash.scale, height: 5 * splash.scale)
                        .rotationEffect(.degrees(splash.rotation))
                        .position(splash.position)
                        .opacity(splash.opacity)
                        .allowsHitTesting(false)
                }
            }
            
            // G. Serat Akar Menegang Saat Buku Ditarik Kuat (Root Tension Tendrils)
            if currentPhase == .pryingRoots && !isBookFreed && bookPullOffset.width > 6 {
                RootTensionTendrilsView(
                    startPoint: CGPoint(x: centerX - 35, y: centerY),
                    endPoint: CGPoint(x: centerX - 35 + bookPullOffset.width, y: centerY + bookPullOffset.height),
                    tension: bookPullProgress
                )
                .allowsHitTesting(false)
            }
            
            // H. Serpihan Tanah & Debu yang Runtuh Saat Akar Meregang
            if currentPhase == .pryingRoots {
                ForEach(fallingDirtParticles) { crumb in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.28, green: 0.20, blue: 0.12), Color(red: 0.16, green: 0.10, blue: 0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 5 * crumb.scale, height: 5 * crumb.scale)
                        .position(crumb.position)
                        .opacity(crumb.opacity)
                        .allowsHitTesting(false)
                }
            }
            
            // I. AREA SENTUHAN & GESTURE TARIK BUKU DARI AKAR (Fase 2)
            if currentPhase == .pryingRoots && !isBookFreed {
                Color.clear
                    .frame(width: bookW + 60, height: bookH + 60)
                    .contentShape(Rectangle())
                    .position(
                        x: centerX + bookPullOffset.width,
                        y: centerY + bookPullOffset.height
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("CakedRootsScene"))
                            .onChanged { val in
                                handleBookPullDrag(val: val, screenSize: screenSize)
                            }
                            .onEnded { val in
                                handleBookPullRelease(val: val, screenSize: screenSize)
                            }
                    )
            }
            
            // J. Petunjuk Visual Tarikan Buku (Animated Pull Prompt)
            if currentPhase == .pryingRoots && !isBookFreed {
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("TARIK BUKU KE KANAN")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 13, weight: .black))
                }
                .foregroundColor(Color(red: 1.0, green: 0.90, blue: 0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.82))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.95, green: 0.85, blue: 0.45), lineWidth: 1.5)
                )
                .shadow(color: .orange.opacity(0.5), radius: 8)
                .position(x: centerX + 115 + bookPullOffset.width * 0.35, y: centerY - 110)
                .opacity(bookPullProgress > 0.85 ? 0.0 : max(0.25, 1.0 - Double(bookPullProgress) * 0.9))
                .allowsHitTesting(false)
            }
        }
        .coordinateSpace(name: "CakedRootsScene")
    }
    
    // MARK: - Scene 2: Close-up Buku Elias & Integrasi BookScene (Fase 3, 4, 5 & 6)
    
    @ViewBuilder
    private func closeUpJournalInspectionScene(screenSize: CGSize) -> some View {
        let center = CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.52)
        
        ZStack {
            if !isBookCoverOpen {
                // SAMPUL KULIT TERTUTUP (TALI, SEGEL, DAN GESPER KUNINGAN)
                ZStack {
                    BundledJournalCoverView(isCakedInMud: false)
                        .scaleEffect(1.65)
                        .shadow(color: .black.opacity(0.85), radius: 25, y: 12)
                    
                    // Tali Ramin Horizontal
                    if !isHorizontalStrapCut {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.75, green: 0.62, blue: 0.44), Color(red: 0.50, green: 0.38, blue: 0.24)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 260, height: 11)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                    }
                    
                    // Tali Ramin Vertikal
                    if !isVerticalStrapCut {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.75, green: 0.62, blue: 0.44), Color(red: 0.50, green: 0.38, blue: 0.24)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 11, height: 320)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                    }
                    
                    // Segel Lilin Merah Kuno Elias (Fase 3)
                    if currentPhase == .cuttingStraps || waxSealHealth > 0 {
                        EliasWaxSealView(health: waxSealHealth)
                            .scaleEffect(1.25)
                            .onTapGesture {
                                handleWaxSealTap()
                            }
                    }
                    
                    // GESPER KUNINGAN ANTIK (Fase 4: Geser untuk Membuka Kunci)
                    if currentPhase == .unlockingClasp {
                        AntiqueBrassClaspLatchView(
                            slideOffset: claspSlideOffset,
                            isUnlocked: isClaspUnlocked
                        )
                        .offset(x: 105, y: 0)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    handleClaspSlide(val: val)
                                }
                                .onEnded { val in
                                    handleClaspRelease(val: val)
                                }
                        )
                    }
                }
                .position(center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 25)
                        .onChanged { val in
                            guard currentPhase == .cuttingStraps else { return }
                            handleStrapSlash(val: val)
                        }
                )
            } else {
                // BUKU TERBUKA: MEMAKAI VIEW BUKU ASLI GAME KITA (BookScene via SpriteView!)
                VStack(spacing: 8) {
                    if let scene = embeddedBookScene {
                        ZStack {
                            // Meja Kayu Tua & Alas Naskah
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.16, green: 0.12, blue: 0.08), Color(red: 0.10, green: 0.07, blue: 0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: max(320, min(screenSize.width - 40, 800)), height: max(200, min(screenSize.height - 100, 420)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(red: 0.55, green: 0.42, blue: 0.22), lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.9), radius: 25, y: 10)
                            
                            // SpriteView dari BookScene Asli Game
                            SpriteView(scene: scene, options: [.allowsTransparency])
                                .frame(width: max(300, min(screenSize.width - 50, 780)), height: max(180, min(screenSize.height - 110, 410)))
                                .cornerRadius(12)
                        }
                    } else {
                        Color.clear
                            .frame(height: 380)
                            .onAppear {
                                setupEmbeddedBookScene(screenSize: screenSize)
                            }
                    }
                    
                    // Bar Navigasi Pembaca Jurnal Elias
                    HStack(spacing: 16) {
                        Button(action: {
                            lightImpact.impactOccurred(intensity: 0.6)
                            onOpenBook?()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                Text("BACA LAYAR PENUH")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                        }
                        
                        Button(action: {
                            lightImpact.impactOccurred(intensity: 0.6)
                            triggerHorrorRevealClimax()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("SELESAIKAN INVESTIGASI")
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(colors: [Color(red: 0.98, green: 0.86, blue: 0.45), Color.orange], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(14)
                            .shadow(color: .orange.opacity(0.5), radius: 6)
                        }
                    }
                    .padding(.bottom, 6)
                }
                .position(center)
            }
        }
    }
    
    // MARK: - Game Mechanics Handlers
    
    // Inisialisasi 140 Petak Gumpalan Lumpur Organik
    private func initMudGrid() {
        mudCells.removeAll()
        let cols = 10
        let rows = 14
        let cellW: CGFloat = 155.0 / CGFloat(cols)
        let cellH: CGFloat = 200.0 / CGFloat(rows)
        
        var id = 0
        for r in 0..<rows {
            for c in 0..<cols {
                let jitterX = CGFloat.random(in: -3.5...3.5)
                let jitterY = CGFloat.random(in: -3.5...3.5)
                let center = CGPoint(
                    x: CGFloat(c) * cellW + cellW/2 + jitterX,
                    y: CGFloat(r) * cellH + cellH/2 + jitterY
                )
                let size = CGSize(
                    width: cellW * CGFloat.random(in: 1.25...1.65),
                    height: cellH * CGFloat.random(in: 1.25...1.65)
                )
                mudCells.append(MudCell(id: id, center: center, size: size))
                id += 1
            }
        }
        totalMudCells = mudCells.count
    }
    
    // FASE 1: Usap Lumpur Organik dengan Radius Halus, Partikel & Taktil Memuaskan
    private func handleMudScrubTouch(localPoint: CGPoint, globalPoint: CGPoint) {
        var newlyCleaned = 0
        let scrubRadius: CGFloat = 44.0
        
        for i in mudCells.indices {
            guard !mudCells[i].isCleaned else { continue }
            let dist = hypot(localPoint.x - mudCells[i].center.x, localPoint.y - mudCells[i].center.y)
            
            if dist < scrubRadius {
                let strength = max(0.3, 1.0 - (dist / scrubRadius))
                mudCells[i].opacity -= 0.45 * strength
                
                if mudCells[i].opacity <= 0.12 {
                    mudCells[i].isCleaned = true
                    mudCells[i].opacity = 0
                    cleanedCellsCount += 1
                    newlyCleaned += 1
                }
            }
        }
        
        if newlyCleaned > 0 || (Int.random(in: 0...3) == 0) {
            cleanPercentage = min(100, Int((Double(cleanedCellsCount) / Double(totalMudCells)) * 100))
            
            // Haptic getaran taktil berkala setiap kenaikan persentase
            if cleanPercentage - lastHapticPercentage >= 2 {
                lastHapticPercentage = cleanPercentage
                lightImpact.impactOccurred(intensity: 0.55)
            }
            
            // Buat partikel percikan lumpur beterbangan
            if mudSplashes.count < 22 {
                let angle = Double.random(in: -Double.pi...Double.pi)
                let speed = CGFloat.random(in: 3...9)
                let splash = MudSplashParticle(
                    position: globalPoint,
                    velocity: CGPoint(x: cos(angle) * speed, y: sin(angle) * speed - 2.5),
                    scale: CGFloat.random(in: 0.8...1.5),
                    opacity: 1.0
                )
                mudSplashes.append(splash)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                    if !mudSplashes.isEmpty { mudSplashes.removeFirst() }
                }
            }
            
            // Jika sudah mencapai >= 82%, sapuan kilau emas otomatis membersihkan sisa kotoran
            if cleanPercentage >= 82 && !isAutoWipingFinished {
                isAutoWipingFinished = true
                activeScrubPosition = nil
                mediumImpact.impactOccurred(intensity: 0.9)
                
                // Animasi kilau cahaya menyapu seluruh buku
                scrubGleamOffset = -180
                withAnimation(.easeInOut(duration: 0.65)) {
                    scrubGleamOffset = 220
                }
                
                withAnimation(.easeOut(duration: 0.5)) {
                    for i in mudCells.indices {
                        mudCells[i].isCleaned = true
                        mudCells[i].opacity = 0
                    }
                    cleanPercentage = 100
                }
                
                successNotify.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPhase = .pryingRoots
                    }
                }
            }
        }
    }
    
    // FASE 2: Menarik Buku Langsung dari Jepitan Akar Purba
    private func handleBookPullDrag(val: DragGesture.Value, screenSize: CGSize) {
        let pullX = max(0, val.translation.width)
        let pullY = val.translation.height * 0.22 // sedikit kemiringan vertikal dinamis
        
        let maxPullDistance: CGFloat = 130.0
        let dampedX = min(maxPullDistance + 22.0, pullX * 0.72)
        let progress = min(1.0, dampedX / maxPullDistance)
        
        bookPullProgress = progress
        bookPullOffset = CGSize(width: dampedX, height: pullY)
        rootSpread = progress * 1.15
        
        // Haptic kayu berderit bertahap setiap kenaikan tarikan
        let currentHapticStage = Int(progress * 10)
        if currentHapticStage > lastTensionHapticThreshold {
            lastTensionHapticThreshold = currentHapticStage
            let intensity = CGFloat(0.35 + progress * 0.6)
            if currentHapticStage % 2 == 0 {
                rigidImpact.impactOccurred(intensity: intensity)
            } else {
                mediumImpact.impactOccurred(intensity: intensity)
            }
            triggerScreenShake(intensity: CGFloat(1.5 + progress * 2.0))
            let origin = CGPoint(x: screenSize.width * 0.52 + dampedX, y: screenSize.height * 0.54)
            spawnCreviceDirt(around: origin)
        }
    }
    
    private func handleBookPullRelease(val: DragGesture.Value, screenSize: CGSize) {
        if bookPullProgress >= 0.85 {
            // BERHASIL TERLEPAS DARI HIMPITAN AKAR!
            rigidImpact.impactOccurred(intensity: 1.0)
            heavyImpact.impactOccurred(intensity: 1.0)
            triggerScreenShake(intensity: 7.0)
            successNotify.notificationOccurred(.success)
            
            let origin = CGPoint(x: screenSize.width * 0.52, y: screenSize.height * 0.54)
            for _ in 0..<5 {
                spawnCreviceDirt(around: origin)
            }
            
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                rootSpread = 1.35
                bookPullOffset = .zero
                isBookFreed = true
                bookEscapeOffsetY = 190
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentPhase = .cuttingStraps
                }
            }
        } else {
            // GAGAL LEPAS: AKAR MEMBAL KEMBALI DENGAN HENTAKAN
            rigidImpact.impactOccurred(intensity: 0.85)
            triggerScreenShake(intensity: 4.0)
            lastTensionHapticThreshold = 0
            
            withAnimation(.spring(response: 0.30, dampingFraction: 0.48)) {
                bookPullOffset = .zero
                bookPullProgress = 0.0
                rootSpread = 0.0
            }
        }
    }
    
    private func spawnCreviceDirt(around point: CGPoint) {
        guard fallingDirtParticles.count < 22 else { return }
        for _ in 0..<3 {
            let angle = Double.random(in: Double.pi * 0.3...Double.pi * 0.7) // Runtuh ke bawah
            let speed = CGFloat.random(in: 2...6)
            let particle = MudSplashParticle(
                position: CGPoint(x: point.x + CGFloat.random(in: -25...25), y: point.y + CGFloat.random(in: -30...30)),
                velocity: CGPoint(x: cos(angle) * speed, y: sin(angle) * speed + 3.0),
                scale: CGFloat.random(in: 0.6...1.2),
                opacity: 1.0
            )
            fallingDirtParticles.append(particle)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                if !fallingDirtParticles.isEmpty {
                    fallingDirtParticles.removeFirst()
                }
            }
        }
    }
    
    // FASE 3: Potong Tali & Segel Lilin
    private func handleStrapSlash(val: DragGesture.Value) {
        let dx = abs(val.translation.width)
        let dy = abs(val.translation.height)
        
        if dx > 70 && !isVerticalStrapCut {
            rigidImpact.impactOccurred(intensity: 0.8)
            triggerScreenShake(intensity: 2.5)
            withAnimation(.easeOut(duration: 0.2)) {
                isVerticalStrapCut = true
            }
        } else if dy > 70 && !isHorizontalStrapCut {
            rigidImpact.impactOccurred(intensity: 0.8)
            triggerScreenShake(intensity: 2.5)
            withAnimation(.easeOut(duration: 0.2)) {
                isHorizontalStrapCut = true
            }
        }
    }
    
    private func handleWaxSealTap() {
        guard isHorizontalStrapCut && isVerticalStrapCut else {
            lightImpact.impactOccurred(intensity: 0.4)
            return
        }
        
        if waxSealHealth == 2 {
            waxSealHealth = 1
            rigidImpact.impactOccurred(intensity: 0.7)
            triggerScreenShake(intensity: 3.0)
        } else if waxSealHealth == 1 {
            waxSealHealth = 0
            heavyImpact.impactOccurred(intensity: 1.0)
            triggerScreenShake(intensity: 5.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPhase = .unlockingClasp
                }
            }
        }
    }
    
    // FASE 4: Geser Gesper Kuningan Antik (Antique Brass Clasp)
    private func handleClaspSlide(val: DragGesture.Value) {
        let dragX = max(0, val.translation.width)
        claspSlideOffset = min(60, dragX)
        if Int(dragX) % 15 == 0 && claspSlideOffset < 55 {
            lightImpact.impactOccurred(intensity: 0.5)
        }
    }
    
    private func handleClaspRelease(val: DragGesture.Value) {
        if claspSlideOffset >= 50 {
            rigidImpact.impactOccurred(intensity: 1.0)
            triggerScreenShake(intensity: 4.0)
            isClaspUnlocked = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.68)) {
                    isBookCoverOpen = true
                    currentPhase = .readingJournal
                }
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                claspSlideOffset = 0
            }
        }
    }
    
    // FASE 5: Setup Pembaca Buku Asli Game (BookScene)
    private func setupEmbeddedBookScene(screenSize: CGSize) {
        guard embeddedBookScene == nil else { return }
        let safeW = screenSize.width > 50 ? screenSize.width : 844
        let safeH = screenSize.height > 50 ? screenSize.height : 390
        let sceneW = max(320, min(safeW - 50, 780))
        let sceneH = max(200, min(safeH - 110, 410))
        let scene = BookScene(size: CGSize(width: sceneW, height: sceneH))
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
        scene.flipCount = 5 // Langsung membuka pada halaman catatan Elias (Entri 11: Kekalahan Elias)
        embeddedBookScene = scene
    }
    
    // FASE 6: Transisi Horor The Hollow
    private func triggerHorrorRevealClimax() {
        currentPhase = .horrorReveal
        
        heavyImpact.impactOccurred(intensity: 1.0)
        triggerScreenShake(intensity: 10.0)
        
        withAnimation(.easeInOut(duration: 2.5)) {
            horrorAmbientFactor = 1.0
        }
        
        var beats = 0
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 1.1, repeats: true) { timer in
            heavyImpact.impactOccurred(intensity: 0.85)
            withAnimation(.easeInOut(duration: 0.12)) { screenPulse = 1.02 }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                heavyImpact.impactOccurred(intensity: 1.0)
                withAnimation(.easeInOut(duration: 0.12)) { screenPulse = 1.0 }
            }
            
            beats += 1
            if beats > 8 {
                timer.invalidate()
            }
        }
    }
    
    private func triggerScreenShake(intensity: CGFloat) {
        withAnimation(.interactiveSpring(response: 0.08, dampingFraction: 0.3)) {
            screenShakeOffset = intensity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.interactiveSpring(response: 0.08, dampingFraction: 0.3)) {
                screenShakeOffset = -intensity
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                screenShakeOffset = 0.0
            }
        }
    }
    
    // MARK: - Texts & Icons
    
    private var hintIconForPhase: String {
        switch currentPhase {
        case .clearingMud: return "sparkles"
        case .pryingRoots: return "hand.draw.fill"
        case .cuttingStraps:
            if !isHorizontalStrapCut || !isVerticalStrapCut { return "scissors" }
            return "hand.tap.fill"
        case .unlockingClasp: return "lock.open.fill"
        case .readingJournal: return "book.pages.fill"
        case .horrorReveal: return "exclamationmark.triangle.fill"
        }
    }
    
    private var hintTextForPhase: String {
        switch currentPhase {
        case .clearingMud: return "GOSOK lumpur tebal yang menutupi bungkusan buku hingga bersih"
        case .pryingRoots: return "SENTUH BUKU & TARIK kuat ke kanan untuk melepaskannya dari himpitan akar!"
        case .cuttingStraps:
            if !isHorizontalStrapCut || !isVerticalStrapCut { return "SWIPE untuk menyayat dan memutus tali ramin tua" }
            return "KETUK segel lilin merah Elias untuk memecahkannya"
        case .unlockingClasp: return "GESER gerendel kuningan antik ke kanan untuk membuka sampul buku"
        case .readingJournal: return "GESER HALAMAN untuk membalik lembaran naskah asli buku Elias"
        case .horrorReveal: return "..."
        }
    }
    
    // MARK: - Horror Overlay Card & Direct Connection to BookScene
    
    @ViewBuilder
    private func horrorCinematicOverlay(screenSize: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.92)],
                center: .center,
                startRadius: 100,
                endRadius: 440
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.45))
                    
                    Text("BUKU CATATAN ELIAS TELAH DIUNGKAP!")
                        .font(.system(size: 17, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 6) {
                    Text("\"...Makhluk kabut itu bukan binatang biasa. Ia mengambil wujud dari rasa takutmu.\"")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.78))
                        .multilineTextAlignment(.center)
                    
                    Text("Peta jalur ekspedisi dan naskah catatan Elias kini berada di tangan Arthur.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // PILIHAN AKSI: BUKA LANGSUNG DI BOOKSCENE ATAU SIMPAN KE KANTONG
                HStack(spacing: 14) {
                    Button(action: {
                        onOpenBook?()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "character.book.closed.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("BACA DI BOOKSCENE")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.25, green: 0.45, blue: 0.65), Color(red: 0.15, green: 0.28, blue: 0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.blue.opacity(0.4), radius: 8)
                    }
                    
                    Button(action: {
                        onComplete?()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("SIMPAN KE KANTONG")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.86, blue: 0.45), Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .orange.opacity(0.7), radius: 10)
                    }
                }
                .padding(.top, 8)
            }
            .padding(26)
            .background(Color(red: 0.12, green: 0.10, blue: 0.13).opacity(0.95))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(red: 0.95, green: 0.82, blue: 0.45).opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.9), radius: 25)
        }
    }
}

// MARK: - Subviews & Visual Components

public struct LandslideCavityBackground: View {
    public let horrorFactor: Double
    
    public var body: some View {
        Canvas { context, size in
            guard size.width > 10 && size.height > 10 else { return }
            let rect = CGRect(origin: .zero, size: size)
            let colTop = blendColor(from: (0.18, 0.14, 0.10), to: (0.08, 0.07, 0.09), factor: horrorFactor)
            let colBot = blendColor(from: (0.11, 0.08, 0.06), to: (0.04, 0.04, 0.05), factor: horrorFactor)
            context.fill(Path(rect), with: .linearGradient(Gradient(colors: [colTop, colBot]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            
            for _ in 0..<35 {
                let rx = CGFloat.random(in: 0...size.width)
                let ry = CGFloat.random(in: 0...size.height)
                let stoneRect = CGRect(x: rx, y: ry, width: CGFloat.random(in: 12...35), height: CGFloat.random(in: 8...24))
                let stoneColor = blendColor(from: (0.24, 0.19, 0.14), to: (0.10, 0.10, 0.11), factor: horrorFactor)
                context.fill(Path(ellipseIn: stoneRect), with: .color(stoneColor.opacity(0.45)))
            }
        }
    }
    
    private func blendColor(from: (Double, Double, Double), to: (Double, Double, Double), factor: Double) -> Color {
        let r = from.0 + (to.0 - from.0) * factor
        let g = from.1 + (to.1 - from.1) * factor
        let b = from.2 + (to.2 - from.2) * factor
        return Color(red: r, green: g, blue: b)
    }
}

public struct LanternLightAura: View {
    public var body: some View {
        RadialGradient(
            colors: [Color.yellow.opacity(0.18), Color.orange.opacity(0.08), .clear],
            center: .center,
            startRadius: 30,
            endRadius: 380
        )
    }
}

public struct BundledJournalCoverView: View {
    public let isCakedInMud: Bool
    
    public var body: some View {
        ZStack {
            // Bayangan Buku
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.65))
                .frame(width: 158, height: 204)
                .offset(y: 4)
                .blur(radius: 6)

            // Lembaran Kertas Kuno Bertumpuk di Sisi Kanan (Parchment Pages Block)
            VStack(spacing: 2) {
                ForEach(0..<18, id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color(red: 0.94, green: 0.88, blue: 0.74) : Color(red: 0.86, green: 0.78, blue: 0.62))
                        .frame(width: 12, height: 8)
                }
            }
            .offset(x: 74, y: 0)
            .shadow(color: .black.opacity(0.4), radius: 2)

            // Pita Merah Pembatas Menjuntai di Bawah (Authentic Silk Ribbon)
            VStack {
                Spacer()
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: 10, y: 0))
                    p.addLine(to: CGPoint(x: 10, y: 24))
                    p.addLine(to: CGPoint(x: 5, y: 19))
                    p.addLine(to: CGPoint(x: 0, y: 24))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.82, green: 0.18, blue: 0.18), Color(red: 0.55, green: 0.10, blue: 0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 10, height: 24)
                .offset(x: -8, y: 16)
                .shadow(color: .black.opacity(0.4), radius: 2)
            }
            .frame(width: 155, height: 200)

            // Sampul Kulit Marun Tua Kuno (Authentic Worn Leather Binding)
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.38, green: 0.20, blue: 0.12),
                            Color(red: 0.26, green: 0.14, blue: 0.08),
                            Color(red: 0.18, green: 0.10, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 155, height: 200)
                .overlay(
                    // Tekstur Guratan Kulit Kuno
                    Canvas { ctx, size in
                        for i in 0..<35 {
                            let y = CGFloat(i) * 5.8
                            var p = Path()
                            p.move(to: CGPoint(x: 6, y: y))
                            p.addLine(to: CGPoint(x: size.width - 6, y: y))
                            ctx.stroke(p, with: .color(Color.black.opacity(0.06)), lineWidth: 1)
                        }
                    }
                )
                .overlay(
                    // Garis Bingkai Emas Antik
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.82, blue: 0.45), Color(red: 0.65, green: 0.48, blue: 0.22)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .overlay(
                    // Lis Emas Bagian Dalam (Inner Inset Filigree Border)
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color(red: 0.92, green: 0.80, blue: 0.42).opacity(0.4), lineWidth: 1)
                        .padding(6)
                )
            
            // Punggung Buku Kiri (Spine Line)
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.4), Color.clear, Color.white.opacity(0.12)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 14, height: 196)
                    .padding(.leading, 2)
                Spacer()
            }
            .frame(width: 155, height: 200)

            // Ornamen 4 Sudut Kuningan Antik (Corner Brass Brackets)
            VStack {
                HStack {
                    BrassCornerOrnament(angle: 0)
                    Spacer()
                    BrassCornerOrnament(angle: 90)
                }
                Spacer()
                HStack {
                    BrassCornerOrnament(angle: -90)
                    Spacer()
                    BrassCornerOrnament(angle: 180)
                }
            }
            .frame(width: 147, height: 192)

            // Simbol Bintang & Kompas Emas Khas Game di Tengah
            if !isCakedInMud {
                ZStack {
                    // Lingkaran Medali Emas
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.96, green: 0.84, blue: 0.45), Color(red: 0.65, green: 0.48, blue: 0.22)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .fill(Color(red: 0.22, green: 0.12, blue: 0.08).opacity(0.8))
                        .frame(width: 38, height: 38)
                    
                    // Lambang Bintang ✦ (Identik dengan Icon Buku di Tas Arthur & Map)
                    Text("✦")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.92, blue: 0.65), Color(red: 0.92, green: 0.72, blue: 0.32)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.yellow.opacity(0.5), radius: 4)
                }
            }
        }
    }
}

public struct BrassCornerOrnament: View {
    public let angle: Double
    public var body: some View {
        Path { p in
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: 18, y: 0))
            p.addLine(to: CGPoint(x: 0, y: 18))
            p.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.72, blue: 0.38), Color(red: 0.55, green: 0.42, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .rotationEffect(.degrees(angle))
        .frame(width: 18, height: 18)
    }
}

public struct AncientRootArmShape: Shape {
    public let isTop: Bool
    
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        if isTop {
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.45))
            p.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height * 0.55),
                control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.95)
            )
        } else {
            p.move(to: CGPoint(x: 0, y: rect.height))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.55))
            p.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height * 0.45),
                control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.05)
            )
        }
        p.closeSubpath()
        return p
    }
}

public struct RootTensionTendrilsView: View {
    public let startPoint: CGPoint
    public let endPoint: CGPoint
    public let tension: CGFloat // 0.0 ... 1.0
    
    public var body: some View {
        Canvas { context, _ in
            let strands = 4
            for i in 0..<strands {
                let yJitter = CGFloat((i - 2) * 16)
                let p1 = CGPoint(x: startPoint.x, y: startPoint.y + yJitter)
                let p2 = CGPoint(x: endPoint.x, y: endPoint.y + yJitter * 0.7)
                let ctrl = CGPoint(
                    x: (p1.x + p2.x) * 0.5,
                    y: (p1.y + p2.y) * 0.5 + (i % 2 == 0 ? 12 : -12) * (1.0 - tension)
                )
                
                var path = Path()
                path.move(to: p1)
                path.addQuadCurve(to: p2, control: ctrl)
                
                let width = max(1.2, (3.5 - tension * 2.0))
                let strandColor = tension > 0.65 ? Color(red: 0.42, green: 0.24, blue: 0.16) : Color(red: 0.28, green: 0.18, blue: 0.11)
                context.stroke(path, with: .color(strandColor.opacity(Double(1.0 - tension * 0.3))), lineWidth: width)
            }
        }
    }
}

public struct PryingIronCrowbarView: View {
    public let progress: CGFloat
    public let isActive: Bool
    
    public var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.45), Color(white: 0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 260)
                .rotationEffect(.degrees(Double(-15 + progress * 28)))
            
            Circle()
                .fill(isActive ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                .frame(width: 72, height: 72)
                .overlay(
                    Circle()
                        .stroke(isActive ? Color.green : Color(red: 0.95, green: 0.85, blue: 0.45), lineWidth: 3)
                )
                .offset(x: -progress * 25, y: -90 + progress * 80)
            
            Image(systemName: "hand.point.down.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .offset(x: -progress * 25, y: -90 + progress * 80)
        }
    }
}

public struct EliasWaxSealView: View {
    public let health: Int
    
    public var body: some View {
        ZStack {
            if health > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.85, green: 0.22, blue: 0.22), Color(red: 0.55, green: 0.12, blue: 0.12)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 28
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.6), radius: 5)
                
                Image(systemName: "seal.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(red: 0.98, green: 0.4, blue: 0.4))
                
                if health == 1 {
                    Path { p in
                        p.move(to: CGPoint(x: 10, y: 15))
                        p.addLine(to: CGPoint(x: 28, y: 28))
                        p.addLine(to: CGPoint(x: 44, y: 38))
                    }
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 54, height: 54)
                }
            }
        }
    }
}

public struct AntiqueBrassClaspLatchView: View {
    public let slideOffset: CGFloat
    public let isUnlocked: Bool
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.85, green: 0.72, blue: 0.38), Color(red: 0.55, green: 0.42, blue: 0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 42)
                .shadow(color: .black.opacity(0.7), radius: 4)
            
            Capsule()
                .fill(Color(red: 0.25, green: 0.18, blue: 0.08))
                .frame(width: 54, height: 8)
            
            HStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white, Color(red: 0.95, green: 0.85, blue: 0.45), Color(red: 0.6, green: 0.45, blue: 0.2)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 16
                        )
                    )
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 3)
                    .offset(x: -20 + slideOffset)
                
                Spacer()
            }
            .frame(width: 60)
            
            if !isUnlocked {
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                    .offset(x: -20 + slideOffset)
            }
        }
    }
}

// MARK: - Previews

#Preview("Elias Journal Discovery", traits: .landscapeLeft) {
    EliasJournalDiscoveryView()
}

