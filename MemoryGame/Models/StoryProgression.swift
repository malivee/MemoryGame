// Sumber urutan cerita, dialog, minigame, hadiah,
// dan pembukaan wilayah desa.

import Foundation

struct StoryProgressionStep: Identifiable {
    let id: Int
    let title: String
    let world: PuzzleWorld
    let area: String
    let unlockedPieceID: Int
    let npcs: [StoryNPC]
    let dialogue: [StoryLine]
    let minigame: StoryMinigame?
}

enum StoryMinigame: String {
    case maraShelfQTE
}

struct StoryNPC: Equatable, Identifiable {
    let id: String
    let name: String
    let role: String
}

enum StoryProgression {
    static let wellConversation: [StoryLine] = [
        line(
            "Warga",
            "Di luar batas desa, orang bisa kehilangan jalan pulang. Hutan itu bukan tempat untuk anak-anak."
        ),
        line(
            "Warga",
            "Sejak kecil kita diajari: desa menjaga kita. Di sini ada makanan, rumah, dan tetangga. Untuk apa mencari bahaya?"
        ),
        line(
            "Warga",
            "Orang yang baik tetap di desa. Ingat itu, Arthur. Rasa ingin tahu hanya akan mencelakakanmu."
        )
    ]

    static func showsWellResidents(
        for progress: PrologueProgress
    ) -> Bool {
        (0..<12).contains(progress.storyProgress)
    }

    static func villageAccess(
        for progress: PrologueProgress
    ) -> VillageAccess {
        switch progress.storyProgress {
        case ...0:
            // Rumah Arthur, sumur, dan halaman Bu Mara.
            return .opening
        case 1...2:
            // Step 1 selesai: lumbung dan jalannya terbuka.
            return .barnRoute
        case 3:
            // Step 3 selesai: kandang Roland dan jalan depannya terbuka.
            return .rolandRoute
        case 4...7:
            // Step 4 selesai: rumah Anneth terbuka.
            return .annethRoute
        case 8...9:
            // Step 8 selesai: rumah Kakek Beryn terbuka.
            return .berynRoute
        case 10:
            // Step 10 selesai: gudang dekat sungai terbuka.
            return .storehouseRoute
        default:
            // Step 11 selesai: seluruh wilayah desa terbuka.
            return .wholeVillage
        }
    }

    @discardableResult
    static func complete(
        _ step: StoryProgressionStep,
        in progress: PrologueProgress
    ) -> Bool {
        guard currentStep(for: progress)?.id == step.id else {
            return false
        }

        // Prasyarat diperiksa juga pada model, bukan hanya UI.
        if step.minigame == .maraShelfQTE &&
            !canStartMaraQTE(progress) {
            return false
        }

        progress.storyProgress = step.id
        return true
    }

    static let steps: [StoryProgressionStep] = [
        step(
            1,
            "Arthur menolong Bu Mara",
            .villagePrototype,
            "Jalan Rumah Arthur - Sumur",
            16,
            [npc("mara", "Bu Mara", "warga")],
            [
                line(
                    "Bu Mara",
                    "Arthur! Just in time. Can you help me move these clay pots?"
                ),
                line(
                    "Arthur",
                    "The ground is sinking under this leg. Let me wedge this brick under it."
                )
            ],
            .maraShelfQTE
        ),

        step(
            2,
            "Kembali menemui Kakek di rumah",
            .villagePrototype,
            "Rumah Arthur & Kakek",
            26,
            [npc("grandpa", "Kakek", "keluarga")],
            [
                line(
                    "Kakek",
                    "Airnya sudah diambil, Arthur?"
                ),
                line(
                    "Arthur",
                    "Sudah, Kek. Tadi aku juga membantu Bu Mara menegakkan raknya."
                ),
                line(
                    "Kakek",
                    "Bagus. Sekarang pergilah ke lumbung dan bantu Keneth. Tetap ikuti jalan desa."
                ),
                line(
                    "Arthur",
                    "Baik, Kek. Aku ke lumbung dulu."
                )
            ]
        ),

        step(
            3,
            "Arthur membantu Keneth di lumbung",
            .villagePrototype,
            "Lumbung Desa",
            27,
            [npc("keneth", "Keneth", "teman")],
            [
                line(
                    "Keneth",
                    "Leave it there. Are your hands clean?"
                ),
                line(
                    "Arthur",
                    "I wonder if the soil past the hills is like our garden."
                )
            ]
        ),

        step(
            4,
            "Arthur berbicara dengan Roland",
            .villagePrototype,
            "Pagar kandang",
            0,
            [npc("roland", "Roland", "teman")],
            [
                line("Roland", "Tell me first."),
                line(
                    "Arthur",
                    "Someday... I want to see the forest boundary up close."
                )
            ]
        ),

        step(
            5,
            "Arthur membantu Anneth",
            .villagePrototype,
            "Rumah Anneth dan area dapur",
            1,
            [
                npc("anneth", "Anneth", "teman"),
                npc("anneth-mother", "Ibu Anneth", "warga")
            ],
            [
                line(
                    "Anneth",
                    "Check it over there. Don't mix it with the ones I've already done."
                ),
                line(
                    "Ibu Anneth",
                    "Could you fetch some rock salt for me?"
                )
            ]
        ),

        step(
            6,
            "Arthur mengambil rock salt",
            .hills,
            "Jalur gerobak dan mulut tambang garam",
            10,
            [npc("miner", "Penambang Tua", "warga")],
            [
                line(
                    "Penambang Tua",
                    "The easy salt is gone. Take your time with the wall."
                ),
                line(
                    "Arthur",
                    "This place is running out of everything."
                )
            ]
        ),

        step(
            7,
            "Arthur mengantar garam",
            .villagePrototype,
            "Jalan pulang dari tambang ke rumah Anneth",
            8,
            [npc("anneth", "Anneth", "teman")],
            [
                line(
                    "Anneth",
                    "Halfway, Arthur. The bag is old."
                ),
                line(
                    "Arthur",
                    "I brought the salt. Nothing spilled this time."
                )
            ]
        ),

        step(
            8,
            "Arthur mencari herbs dan bertemu Hollow",
            .hills,
            "Tepi kebun dan lereng hutan",
            9,
            [npc("hollow", "The Hollow", "manifestasi")],
            [
                line("Arthur", "There is something in the fog."),
                line("The Hollow", "...")
            ]
        ),

        step(
            9,
            "Arthur memberi salep kepada Kakek Beryn",
            .villagePrototype,
            "Rumah dan teras Kakek Beryn",
            19,
            [npc("beryn", "Kakek Beryn", "sesepuh")],
            [
                line(
                    "Kakek Beryn",
                    "You saw something beyond the safe path, didn't you?"
                ),
                line(
                    "Arthur",
                    "I only went looking for herbs."
                )
            ]
        ),

        step(
            10,
            "Arthur memotong kayu dan menemukan buku",
            .hills,
            "Lereng hutan dan tanah longsor",
            5,
            [npc("elias", "Elias", "jejak masa lalu")],
            [
                line(
                    "Kakek",
                    "We're low on wood. Gather some at the bottom of the slope."
                ),
                line(
                    "Arthur",
                    "It's the exact same shape. The one from yesterday..."
                )
            ]
        ),

        step(
            11,
            "Arthur bercerita kepada teman-temannya",
            .villagePrototype,
            "Gudang kosong dekat sungai",
            6,
            [
                npc("keneth", "Keneth", "teman"),
                npc("roland", "Roland", "teman"),
                npc("anneth", "Anneth", "teman")
            ],
            [
                line(
                    "Keneth",
                    "And you're only telling us this now?!"
                ),
                line(
                    "Anneth",
                    "This might be important, but it's not a map."
                )
            ]
        ),

        step(
            12,
            "Perjalanan keluar desa",
            .villagePrototype,
            "Sumur desa",
            19,
            [
                npc("keneth", "Keneth", "teman"),
                npc("roland", "Roland", "teman"),
                npc("anneth", "Anneth", "teman")
            ],
            [
                line(
                    "Keneth",
                    "Kalian pernah dengar cerita tentang hutan di luar batas desa? Tidak ada yang pulang dengan selamat."
                ),
                line(
                    "Anneth",
                    "Di sini kita punya rumah, sumur, dan orang-orang yang menjaga kita. Dunia luar tidak memberi apa pun selain bahaya."
                ),
                line(
                    "Roland",
                    "Lebih aman tetap di desa. Jangan biarkan rasa ingin tahu membuat kita kehilangan tempat ini."
                ),
                line(
                    "Arthur",
                    "Kalau semua orang terus takut, bagaimana kita tahu apa yang sebenarnya ada di luar sana?"
                )
            ]
        ),

        step(
            13,
            "Tidak ada jalan pulang",
            .echoesBoundary,
            "Jalan utama menuju Desa Ilusi",
            15,
            [
                npc("hollow", "The Hollow", "manifestasi"),
                npc("roland", "Roland", "pelindung")
            ],
            [
                line("Anneth", "Step back. Now!"),
                line(
                    "Arthur",
                    "The path home should have been downhill."
                )
            ]
        )
    ]

    static func currentStep(
        for progress: PrologueProgress
    ) -> StoryProgressionStep? {
        steps.first {
            $0.id == progress.storyProgress + 1
        }
    }

    static func unlockedPieceIDs(
        for progress: PrologueProgress
    ) -> Set<Int> {
        Set(
            steps
                .filter { $0.id <= progress.storyProgress }
                .map(\.unlockedPieceID)
        )
    }

    static func step(
        _ id: Int,
        _ title: String,
        _ world: PuzzleWorld,
        _ area: String,
        _ piece: Int,
        _ npcs: [StoryNPC],
        _ dialogue: [StoryLine],
        _ minigame: StoryMinigame? = nil
    ) -> StoryProgressionStep {
        StoryProgressionStep(
            id: id,
            title: title,
            world: world,
            area: area,
            unlockedPieceID: piece,
            npcs: npcs,
            dialogue: dialogue,
            minigame: minigame
        )
    }

    static func npc(
        _ id: String,
        _ name: String,
        _ role: String
    ) -> StoryNPC {
        StoryNPC(id: id, name: name, role: role)
    }

    static func line(
        _ speaker: String,
        _ text: String
    ) -> StoryLine {
        StoryLine(speaker: speaker, text: text)
    }
}
