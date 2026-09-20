# Area Desa — mengikuti desain main

Kontrak minigame story dan aturan SSOT didokumentasikan di `docs/story-minigames.md`.

Modul desa mandiri, dapat dibuka dari tombol Area Desa di kiri atas layar puzzle awal. Tombol Kembali mengembalikan pemain ke papan puzzle. Eksplorasi desa tidak mengubah progres cerita atau syarat Jump In.

## Acuan visual

- Palet rumput sage-lime, jalan krem, kayu hangat, rumah panggung beratap jerami, dan cemara ber-chevron diambil dari SceneryPainter pada hasil pull main.
- Primitive cottage, pineTree, bushHedge, rocks dan helper geometri disalin ke VillageArtwork agar tidak perlu mengubah akses private atau file renderer utama. Ini salinan khusus modul; jika gaya main berubah, sinkronkan primitive tersebut.
- Karakter menggunakan MemoryCharacter asli, termasuk applyMovement untuk animasi berjalan. Bukan karakter pengganti.
- Font dan tombol memakai PrologueUI; kapsul atas dan stik mengikuti ExplorationScene+Rendering.
- Susunan landmark mengikuti gambar Area Desa: Anneth barat laut, Arthur barat daya, lumbung utara, sumur tengah, Bu Mara di timur sumur, Beryn selatan, gudang/sungai timur laut, kandang dan pagar ke arah hutan di tenggara.

## Membuka area desa

Jalankan aplikasi, lalu ketuk Area Desa di layar puzzle setelah cutscene pembuka.

Untuk preview terpisah, buka VillagePrototypePreview.swift di Xcode → Editor → Canvas → Resume. Gunakan live preview landscape.

Default preview memakai tahap `.opening`. Stik dan ketuk tanah menggerakkan Arthur. Tombol Lihat peta berganti antara kamera jalan dan denah penuh; ketuk bangunan dalam mode peta untuk deskripsi.

Tidak ada menu tahap pada HUD. `StoryProgression.villageAccess(for:)` adalah sumber urutan pembukaan kabut: opening, lumbung, kandang Roland, rumah Anneth, rumah Kakek Beryn, gudang, lalu seluruh desa. `VillageMap.accessibleAreas(stage:)` menentukan mask kabut sekaligus batas navigasi untuk setiap tahap. Preview dapat memakai salah satu nilai `VillageAccess` untuk memeriksa tahap tertentu.

## File

- Models/Village/VillageMap.swift: denah dan batas akses.
- Services/Village/VillageArtwork.swift: render denah dengan primitive visual main.
- Systems/Village/VillageNavigation.swift: collision dan pencarian rute preview.
- Scenes/VillagePrototype/: scene, rendering, input, dan host Canvas.
- Validation/Village/: tes navigasi mandiri, jalankan sh Validation/Village/run.sh.

## Batas pekerjaan

Eksterior desa dan eksplorasi preview saja. Interior, quest, QTE, audio, inventory, serta event Story.docx belum dihubungkan. Model akses preview tidak membaca/menulis UserDefaults atau PrologueStore. Penghubung pada RightDeckPuzzleScene hanya membuka dan menutup preview. project.pbxproj tidak diubah.

Modul bergantung pada MemoryCharacter, PrologueUI, serta dependensi existing karakter dari proyek main. Komponen tersebut tetap digunakan tanpa perubahan. Semua berkas baru mendapat komentar penjelasan Indonesia.

## Kamera dan tampilan

Scene memakai resizeFill dan ukuran SKView, sama dengan ExplorationScene. Zoom mengikuti max(1.45, min(1.85, tinggiLayar / 250)); kamera mengejar Arthur dengan interpolasi dt × 7.5 dan dibatasi tepi VillageMap. HUD memakai koordinat layar, stik di (88, 88), Kembali ke foto di kanan atas, dan Peta di kanan bawah. Mode Peta hanya tampilan denah opsional. Kecepatan berjalan 140 unit/detik mengikuti eksplorasi asli.

Tekstur 2x memakai sapuan tanah, arsiran pensil, kerikil, dan primitive bunga dari SceneryPainter, dengan kerapatan disesuaikan luas desa. Denah dan collision tetap mengikuti VillageMap.
