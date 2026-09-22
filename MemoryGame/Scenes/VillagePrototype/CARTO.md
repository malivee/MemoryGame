# Carto Desa: Keping Gabungan

Modul yang dimaksud adalah `VillageCartoScene`, dibuka lewat **Area Desa**.
Ini terpisah dari `RightDeckPuzzleScene` dan dari progres cerita desa utama.

## Sumber Kebenaran

- `VillageCartoMap`: aset `VillageCartoMap.imageset`, grid sumber 18 x 10,
  45 bentuk tetromino, jalur jalan, bangunan, dan posisi awal Arthur.
- `VillageTileLayout`: penempatan, rotasi, footprint, outline, sambungan
  jalan, navigasi, serta transformasi posisi sumber/dunia.
- `VillageCartoScene`: rendering dan input. Tidak mendefinisikan ulang
  bentuk keping atau aturan collision.

Satu keping terdiri dari **empat sel yang menyatu**: T, Z, S, L, J, I, atau O.
Empat sel itu tidak bisa dipindahkan, diputar, atau dikembalikan secara terpisah.
Satu grup awal terpasang; seluruh grup lainnya tersedia di inventori.

Gambar terbaru digunakan pada mode susun dan jelajah, termasuk bangunan
yang ada di gambar. Jalan dan penghalang memakai koordinat gambar baru,
bukan koordinat `VillageMap` untuk cerita desa.

## Penempatan dan Navigasi

Peta dapat disusun bebas atau membentuk kelompok terpisah. Tidak ada target
urutan gambar. Seluruh footprint harus berada dalam papan dan tidak boleh
bertumpuk, termasuk sel yang jauh dari anchor keping.

Semua pasangan sisi sel yang saling bersentuhan diperiksa. Ujung jalan
harus sejajar; jalan-tanah ditolak, tanah-tanah diperbolehkan. Sisi internal
empat sel tidak dianggap sambungan antar-keping.

Border mengikuti perimeter luar tanpa garis pemisah internal. Preview
drop menampilkan seluruh bentuk, hijau jika sah dan merah jika ditolak.
Penanda oranye hanya menunjukkan port jalan di perimeter luar.

Area sentuh inventori mengikuti bentuk yang terlihat setelah rotasi.
Pada papan, menyentuh sel mana pun memilih satu grup yang sama; ruang
kosong di lekukan T/Z/L bukan bagian keping. Drag mempertahankan sel
yang dipegang sebagai offset terhadap anchor.

Arthur tetap memakai analog dan tap-to-move. Posisi sumber Arthur mengikuti
pemindahan/rotasi seluruh grup. Ruang kosong dan ujung jalan yang tidak
tersambung tidak bisa dilalui. Semua keping boleh dikembalikan ke inventori;
jika tidak ada tempat berjalan, mode jelajah tidak dapat dimulai.

## Save

Layout baru disimpan pada `village.carto.layout.v3` dengan versi schema 3.
Save v2 berisi kotak tunggal dan tetap dibiarkan, tidak ditimpa atau
diinterpretasikan sebagai tetromino. Layout baru dimulai dari satu grup.
Save cerita utama dan portal puzzle tidak diubah.

## Validasi

Jalankan dari root proyek:

```sh
swiftc -module-cache-path /tmp/memorygame-carto-cache \
  MemoryGame/Models/Village/VillageCartoMap.swift \
  MemoryGame/Models/Village/VillageTileLayout.swift \
  Validation/Carto/main.swift -o /tmp/memorygame-carto-check
/tmp/memorygame-carto-check
```

Validasi mencakup tiling tanpa celah/overlap, empat sel terhubung per keping,
outline cekung, semua rotasi, hit test dan transformasi tiap sel, overlap
pada sel non-anchor, semua kombinasi tetangga dekat keping awal, susunan
gambar utuh, jalan, pengembalian grup, papan kosong, dan save round-trip.
