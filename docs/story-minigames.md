# Story Minigames

Dokumen ini menjelaskan kontrak minigame dalam progresi cerita. Tujuannya adalah menjaga `StoryProgression.swift` sebagai single source of truth (SSOT) ketika developer atau agent menambah dan mengubah minigame.

## Aturan SSOT

Setiap minigame cerita harus dideklarasikan sebagai case `StoryMinigame`, kemudian dipasang pada `StoryProgressionStep.minigame`. Scene tidak boleh menentukan kepemilikan minigame melalui angka step seperti `step.id == 1`.

```swift
enum StoryMinigame: String {
    case maraShelfQTE
    case basketDeliveryQTE
    case seedSorting
    case fencePostQTE
    case tuberSorting
}

step(
    1,
    "Arthur menolong Bu Mara",
    .villagePrototype,
    "Jalan Rumah Arthur - Sumur",
    16,
    [npc("mara", "Bu Mara", "warga")],
    [line("Bu Mara", "...")],
    .maraShelfQTE
)
```

`nil` berarti step tidak memiliki minigame. Data world, area, NPC, dialog, hadiah puzzle, dan minigame ditentukan pada entry step yang sama.

## Step 1: Rak Bu Mara

Minigame `.maraShelfQTE` berjalan di `VillagePrototypeScene`.

1. Arthur berbicara dengan Bu Mara.
2. Dialog selesai tanpa menyelesaikan story step.
3. Prompt interaksi tampil pada rak miring di halaman Bu Mara.
4. Arthur mendekati rak dan memulai `QuickTimeEventNode`.
5. QTE yang tersedia saat ini meminta 15 ketukan pada tombol `ANGKAT`.
6. Keberhasilan QTE memanggil `StoryProgression.complete`, menyimpan progres, dan membuka step berikutnya.

Posisi visual rak berasal dari `VillageArtwork`. Node prompt dan adapter QTE berada di `VillagePrototypeScene`. Kepemilikan minigame tetap berasal dari `StoryProgressionStep.minigame`.

## Minigame Step 1-5

| Step | StoryMinigame | Implementasi reusable | Waktu dimulai |
| --- | --- | --- | --- |
| 1 | `maraShelfQTE` | `TapQuickTimeEventNode` | Setelah mengambil air, berbicara dengan Bu Mara, lalu mengetuk rak |
| 2 | `basketDeliveryQTE` | `ClassicTapQuickTimeEventNode` | Setelah menyelesaikan dialog dengan Kakek |
| 3 | `seedSorting` | `SeedSortingMinigameNode` | Setelah berbicara dengan Keneth di lumbung |
| 4 | `fencePostQTE` | `ClassicTapQuickTimeEventNode` | Setelah berbicara dengan Roland di kandang |
| 5 | `tuberSorting` | `ItemSortingMinigameNode` | Setelah berbicara dengan Anneth |

Minigame harus berhasil sebelum `StoryProgression.complete` dipanggil. Dismissal minigame membangun ulang NPC, akses wilayah, objektif, dan kabut untuk step berikutnya.

## Batas Implementasi Saat Ini

`QuickTimeEventNode` yang tersedia hanya mendukung ketuk cepat. QTE ini belum memiliki Core Motion, fase hold, slider presisi, batas waktu, atau fail state. Ketika sistem QTE diperluas, pertahankan case `.maraShelfQTE` dan ganti implementasi adapter scene tanpa memindahkan kepemilikan minigame keluar dari `StoryProgression`.

## Menambah Minigame Baru

1. Tambahkan case baru pada `StoryMinigame`.
2. Pasang case itu pada entry `StoryProgression.steps` yang sesuai.
3. Buat trigger visual/interaksi di scene milik `step.world`.
4. Scene memilih minigame melalui `step.minigame`, bukan melalui ID step.
5. Panggil `StoryProgression.complete(step, in:)` hanya setelah minigame berhasil.
6. Simpan progres melalui `PrologueStore.shared.save()`.
7. Pastikan kegagalan tidak menaikkan `storyProgress` dan pemain dapat mengulang trigger.

Jangan menduplikasi dialog, hadiah puzzle, atau hubungan step-minigame di file scene. Scene bertugas menampilkan dan menjalankan mekanik; `StoryProgression` menentukan urutan serta kepemilikannya.
