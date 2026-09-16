import Foundation

struct StoryLine {
    let speaker: String
    let text: String
}

enum PrologueDialogue {
    static let book: [StoryLine] = [
        .init(speaker: "Buku lama", text: "Sketsa perbukitan di luar lembah. Sebuah catatan: ‘Jalan berlanjut melewati punggung bukit…’ Sisanya memudar."),
        .init(speaker: "Arthur", text: "Ada sesuatu di luar desa yang belum kita tahu. Aku ingin melihatnya!"),
        .init(speaker: "Arthur", text: "Tapi aku perlu memikirkannya baik-baik. Akan kutunjukkan ini kepada teman-teman.")
    ]
    static func friend(_ friend: FriendID) -> [StoryLine] {
        switch friend {
        case .keneth: return [
            .init(speaker: "Arthur", text: "Lihat sketsa ini. Bagaimana kalau kita mencari tahu jalan di luar desa?"),
            .init(speaker: "Keneth", text: "Di sini aku tahu tempatku. Kalau kita pergi, apa yang masih jadi milikku?"),
            .init(speaker: "Arthur", text: "Aku belum tahu apa yang akan kita temui. Aku ingin mendengar keputusanmu."),
            .init(speaker: "Keneth", text: "Aku mau mencoba ikut. Tapi meninggalkan rumah tetap terasa berat.")
        ]
        case .roland: return [
            .init(speaker: "Arthur", text: "Buku ini menggambar bukit di luar lembah. Kita bisa mencari jalannya bersama."),
            .init(speaker: "Roland", text: "Aku ikut! Kalian jangan berangkat sebelum aku datang, ya?"),
            .init(speaker: "Arthur", text: "Kita berkumpul dulu. Tak seorang pun berangkat sendirian.")
        ]
        case .anneth: return [
            .init(speaker: "Anneth", text: "Kita baru punya gambar dari buku ini. Bagaimana kalau jalannya berbeda?"),
            .init(speaker: "Arthur", text: "Kita cari penanda yang nyata dulu, lalu putuskan langkah berikutnya."),
            .init(speaker: "Anneth", text: "Baik, aku ikut mencari. Kita tetap perlu memeriksa jalan dan bekal kita.")
        ]
        }
    }
    static let changedRoute: [StoryLine] = [
        .init(speaker: "Anneth", text: "Jalannya tidak seperti yang kubayangkan. Rencana kita belum lengkap."),
        .init(speaker: "Arthur", text: "Kita periksa pelan-pelan. Aku tak mau pilihanku membahayakan kalian.")
    ]
    static let marker: [StoryLine] = [
        .init(speaker: "Arthur", text: "Ada penanda jalan di sini. Arah itu menuju batas desa."),
        .init(speaker: "Anneth", text: "Setidaknya ini petunjuk yang bisa kita lihat sendiri. Kita belum tahu apa yang ada setelahnya.")
    ]
    static let gathering: [StoryLine] = [
        .init(speaker: "Arthur", text: "Aku ingin tahu apa yang ada di luar… tapi kalau keputusanku malah membahayakan kalian?"),
        .init(speaker: "Keneth", text: "Aku masih berat meninggalkan desa. Beri aku waktu melihatnya sekali lagi."),
        .init(speaker: "Roland", text: "Kita berempat sudah di sini, kan? Aku tak mau tertinggal."),
        .init(speaker: "Anneth", text: "Kita tidak bisa memastikan semuanya. Aku siap mulai dengan yang kita tahu sekarang.")
    ]
}
