import SwiftUI
import CoreHaptics

// MARK: - Loadout Item Model

public struct ExpeditionItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let icon: String
    public let description: String
    public let annethQuote: String
    public let slotIndex: Int
    public var isPacked: Bool
}

// MARK: - Party Loadout Minigame View

public struct PartyLoadoutPrepView: View {
    public var onComplete: (() -> Void)?
    public var onDismiss: (() -> Void)?

    @State private var items: [ExpeditionItem] = [
        ExpeditionItem(
            id: "knife",
            name: "Pisau Kecil",
            category: "Alat Utilitas",
            icon: "🗡️",
            description: "Pisau lipat bertangkai tanduk untuk memotong dahan semak duri di lereng.",
            annethQuote: "\"Pisau kecil untuk memotong ranting, bukan untuk sok berani. Paham?\"",
            slotIndex: 0,
            isPacked: false
        ),
        ExpeditionItem(
            id: "rope",
            name: "Tali Rami Kuat",
            category: "Perlengkapan Panjat",
            icon: "🪢",
            description: "Tali serat rami 15 meter dengan simpul pengaman untuk menuruni jurang.",
            annethQuote: "\"Jika tanah di lereng timur licin, kita ikat tali ini di pohon penahan.\"",
            slotIndex: 1,
            isPacked: false
        ),
        ExpeditionItem(
            id: "water",
            name: "Botol Air Minum",
            category: "Perbekalan",
            icon: "🍶",
            description: "Botol labu terbungkus kulit berisi air bersih dari sumur desa.",
            annethQuote: "\"Perbekalan air untuk empat orang. Jangan ada yang minum berlebihan.\"",
            slotIndex: 2,
            isPacked: false
        ),
        ExpeditionItem(
            id: "ointment",
            name: "Salep Herbal & Kain",
            category: "Pertolongan Pertama",
            icon: "🌿",
            description: "Racikan salep daun perak dan kain perban bersih untuk menutup luka.",
            annethQuote: "\"Goresan semak luar desa bisa infeksi dengan cepat. Salep ini pencegahnya.\"",
            slotIndex: 3,
            isPacked: false
        ),
        ExpeditionItem(
            id: "journal",
            name: "Buku Jurnal Elias",
            category: "Dokumen & Petunjuk",
            icon: "📖",
            description: "Catatan penjelajah Elias yang ditemukan di akar longsor lereng hutan.",
            annethQuote: "\"Kita periksa tanah di sekitar akar pohon tempatmu menemukan buku ini.\"",
            slotIndex: 4,
            isPacked: false
        )
    ]

    @State private var selectedItem: ExpeditionItem?
    @State private var lastPackedMessage: String = "Pilih perlengkapan dari meja kerja untuk dimasukkan ke dalam tas ekspedisi."
    @State private var packSuccessAnimation: Bool = false
    @State private var bagPulse: CGFloat = 1.0

    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationHaptic = UINotificationFeedbackGenerator()

    public init(onComplete: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    private var packedCount: Int {
        items.filter(\.isPacked).count
    }

    private var allPacked: Bool {
        packedCount == items.count
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background malam remang-remang di belakang rumah Anneth
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.12),
                        Color(red: 0.10, green: 0.14, blue: 0.18),
                        Color(red: 0.05, green: 0.06, blue: 0.09)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Pendar cahaya hangat dari jendela dapur Anneth
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.65, blue: 0.25).opacity(0.18),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 400
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    // Header Bar
                    headerBar

                    // Konten Utama 2 Kolom (Landscape Optimized)
                    HStack(alignment: .top, spacing: 18) {
                        // Kolom Kiri: Meja Kerja & Daftar Barang
                        itemWorkbenchView
                            .frame(maxWidth: .infinity)

                        // Kolom Kanan: Ransel Ekspedisi Anneth
                        expeditionBagView
                            .frame(width: min(proxy.size.width * 0.44, 380))
                    }
                    .padding(.horizontal, 16)

                    // Footer Bar & Dialogue Box Anneth
                    footerDialogueBar
                }
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("🎒 PERSIAPAN EKSPEDISI · PARTY LOADOUT")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.98, green: 0.85, blue: 0.45))

                    Text("(\(packedCount)/\(items.count))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(allPacked ? Color(red: 0.45, green: 0.92, blue: 0.55) : Color(red: 0.90, green: 0.75, blue: 0.35))
                }

                Text("Belakang Rumah Anneth · Kemas barang-barang wajib ke dalam tas ransel")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.70))
            }

            Spacer()

            // Tombol Tutup / Batal
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.white.opacity(0.65))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Workbench List View (Kolom Kiri)

    private var itemWorkbenchView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MEJA PERLENGKAPAN")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.85, green: 0.88, blue: 0.92))

                Spacer()

                Text("Ketuk untuk memasukkan ke tas")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.55))
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        itemCardRow(item: item)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.11, green: 0.14, blue: 0.18).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func itemCardRow(item: ExpeditionItem) -> some View {
        let isSelected = selectedItem?.id == item.id

        return Button {
            selectAndToggleItem(item)
        } label: {
            HStack(spacing: 12) {
                // Ikon bulat
                ZStack {
                    Circle()
                        .fill(item.isPacked ? Color(red: 0.14, green: 0.28, blue: 0.18) : Color(red: 0.18, green: 0.22, blue: 0.28))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(item.isPacked ? Color.green.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1)
                        )

                    Text(item.icon)
                        .font(.system(size: 18))
                }

                // Deskripsi item
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.name)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(item.isPacked ? Color(red: 0.75, green: 0.92, blue: 0.80) : Color.white)

                        Spacer()

                        Text(item.category)
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45).opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.black.opacity(0.35))
                            )
                    }

                    Text(item.description)
                        .font(.system(size: 9.5, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.72))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Status tombol kemas
                VStack {
                    if item.isPacked {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 0.45, green: 0.92, blue: 0.55))
                            Text("Terkemas")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(Color(red: 0.45, green: 0.92, blue: 0.55))
                        }
                    } else {
                        Text("+ Kemas")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.10, green: 0.12, blue: 0.14))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 0.95, green: 0.82, blue: 0.42))
                            )
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 0.20, green: 0.25, blue: 0.32) : (item.isPacked ? Color(red: 0.12, green: 0.18, blue: 0.15).opacity(0.75) : Color(red: 0.14, green: 0.17, blue: 0.22)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color(red: 0.95, green: 0.82, blue: 0.42) : (item.isPacked ? Color.green.opacity(0.35) : Color.white.opacity(0.08)), lineWidth: 1.2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expedition Bag View (Kolom Kanan)

    private var expeditionBagView: some View {
        VStack(spacing: 12) {
            // Visual Tas Ransel
            VStack(spacing: 6) {
                HStack {
                    Text("TAS EKSPEDISI ANNETH")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))

                    Spacer()

                    Text("Kapasitas: \(packedCount)/5")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(allPacked ? Color.green : Color.white.opacity(0.85))
                }

                // Representasi visual slot tas
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.28, green: 0.18, blue: 0.11),
                                    Color(red: 0.18, green: 0.12, blue: 0.08)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(red: 0.65, green: 0.45, blue: 0.25), lineWidth: 2)
                        )
                        .scaleEffect(bagPulse)

                    VStack(spacing: 8) {
                        // Tali gesper kulit atas
                        HStack(spacing: 24) {
                            Rectangle()
                                .fill(Color(red: 0.12, green: 0.08, blue: 0.05))
                                .frame(width: 8, height: 16)
                            Rectangle()
                                .fill(Color(red: 0.12, green: 0.08, blue: 0.05))
                                .frame(width: 8, height: 16)
                        }

                        // 5 Slot Kompartemen
                        VStack(spacing: 6) {
                            ForEach(0..<5) { index in
                                bagSlotRow(index: index)
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.09, green: 0.11, blue: 0.14).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.35), lineWidth: 1)
                    )
            )

            // Tombol Siapkan Ekspedisi (Aktif saat 5/5)
            Button {
                finishPackingExpedition()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: allPacked ? "checkmark.seal.fill" : "lock.fill")
                        .font(.system(size: 14, weight: .bold))

                    Text(allPacked ? "KUNCI & SIAPKAN EKSPEDISI" : "KEMAS SELURUH BARANG (\(packedCount)/5)")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                }
                .foregroundColor(allPacked ? Color(red: 0.10, green: 0.15, blue: 0.10) : Color.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(allPacked ? Color(red: 0.45, green: 0.92, blue: 0.55) : Color.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(allPacked ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .disabled(!allPacked)
        }
    }

    private func bagSlotRow(index: Int) -> some View {
        let slotItem = items.first(where: { $0.slotIndex == index })
        let isFilled = slotItem?.isPacked ?? false

        return HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFilled ? Color(red: 0.14, green: 0.28, blue: 0.18) : Color.black.opacity(0.4))
                    .frame(width: 26, height: 26)

                if isFilled, let icon = slotItem?.icon {
                    Text(icon)
                        .font(.system(size: 13))
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.35))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(isFilled ? (slotItem?.name ?? "") : "Kompartemen Kosong #\(index + 1)")
                    .font(.system(size: 10.5, weight: isFilled ? .bold : .medium, design: .rounded))
                    .foregroundColor(isFilled ? Color(red: 0.90, green: 0.95, blue: 0.90) : Color.white.opacity(0.40))

                Text(isFilled ? (slotItem?.category ?? "") : "Wajib diisi")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(isFilled ? Color(red: 0.55, green: 0.92, blue: 0.65) : Color.white.opacity(0.25))
            }

            Spacer()

            if isFilled {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.45, green: 0.92, blue: 0.55))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isFilled ? Color(red: 0.18, green: 0.24, blue: 0.20).opacity(0.7) : Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isFilled ? Color.green.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Footer Dialogue Bar

    private var footerDialogueBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.35, green: 0.22, blue: 0.45))
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color(red: 0.85, green: 0.70, blue: 0.95), lineWidth: 1.2))

                Text("A")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Anneth:")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.45))

                Text(lastPackedMessage)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.92))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.85, green: 0.70, blue: 0.45).opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Logic & Actions

    private func selectAndToggleItem(_ item: ExpeditionItem) {
        selectedItem = item

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let willPack = !items[index].isPacked
            items[index].isPacked = willPack

            if willPack {
                mediumHaptic.impactOccurred()
                lastPackedMessage = items[index].annethQuote
                triggerBagPulse()
            } else {
                lastPackedMessage = "\"\(items[index].name) dikeluarkan dari tas.\""
            }

            if allPacked {
                notificationHaptic.notificationOccurred(.success)
                lastPackedMessage = "\"Perlengkapan untuk empat orang sudah lengkap. Besok pagi lewat celah bukit timur. Jangan berpisah!\""
            }
        }
    }

    private func triggerBagPulse() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            bagPulse = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.2)) {
                bagPulse = 1.0
            }
        }
    }

    private func finishPackingExpedition() {
        heavyHaptic.impactOccurred()
        onComplete?()
    }
}
