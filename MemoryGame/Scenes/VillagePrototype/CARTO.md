# Carto Desa: Keping Gabungan

## Zona Bangunan

Air biru selalu dilarang, termasuk subgrid tepi yang sebagian menyentuh air.
`waterSubcellIndices` berasal dari piksel biru aset `123.jpg` dan mengalahkan
perluasan kontur. Preview dan validasi tapak memakai mask yang sama.
Mask air berada dalam koordinat sumber sehingga tetap mengikuti rotasi keping.
Jika aset diganti, regenerasikan daftar dengan:

```sh
swift Validation/Carto/Tools/generate-water-mask.swift MemoryGame/Resources/Assets.xcassets/VillageCartoMap.imageset/123.jpg
```

Salin hasil generator ke `VillageCartoMap.waterSubcellIndices`. Generator
memakai grid sumber 54 x 30 (18 x 10 sel, masing-masing 3 x 3 subgrid).

Keping yang diizinkan diturunkan dari mask kontur aset aktif, bukan daftar
nomor terpisah. Daftar tujuh keping lama memotong kontur pada batas keping.
Nomor layar tetap ID + 1; hanya subgrid valid yang dapat dipakai.

Setiap sel persegi penyusun keping memiliki subgrid 3 x 3. Bentuk tetromino
tetap satu grup empat sel; grid bangunan tidak memecah grup menjadi keping baru.
`VillageCartoMap.buildableSourceSubcells` adalah sumber tunggal izin lahan,
diturunkan dari dua kontur dataran tengah pada aset aktif `123.jpg`.
Koordinat trace dinormalisasi dari referensi 1818 x 1344 ke ukuran dunia,
tidak memakai koordinat gambar lama 1672 x 941. Sungai di antara dua kontur
tidak termasuk zona. Seluruh subgrid harus berada di dalam kontur;
tepi grid tetap bertangga karena sel persegi tidak dapat mengikuti kurva
secara persis. Bangunan yang ditempatkan pemain tidak boleh bertumpuk.
Kontur perlu ditinjau jika gambar sumber diganti.

`VillageTileLayout.buildableSubcell` mengubah koordinat papan kembali ke
gambar sumber, sehingga mask ikut berpindah dan berputar bersama keping.
Preview grid dan validasi seluruh tapak bangunan memakai fungsi yang sama.
Save lama tetap memuat keping dan bangunan valid; bangunan yang kini berada
di lahan tidak valid kembali ke inventori tanpa membuang bangunan valid lain.

Grid 3 x 3 bukan ukuran bangunan. Ukuran placeholder rumah yang sudah ada
(6 x 4 subgrid) tidak diubah oleh aturan lahan ini; seluruh tapaknya tetap
harus ditopang lahan yang diizinkan.

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
