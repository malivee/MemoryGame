# Border, sambungan jalan, dan pengembalian keping

Peta tetap dapat disusun bebas atau membentuk kelompok terpisah. Jika dua sisi saling menempel, seluruh ujung jalan di sisi itu harus bertemu dengan ujung jalan tetangga. Jalan–tanah atau ujung jalan yang tidak sejajar ditolak. Tanah–tanah diperbolehkan. Tidak ada target urutan gambar atau syarat seluruh keping menjadi satu kelompok.

Border krem berlapis garis gelap membatasi setiap keping. Keping terpilih ber-outline oranye dan memiliki nomor. Tanda oranye kecil pada border menunjukkan ujung jalan dan ikut diputar 90°. Preview drop berwarna hijau bila sah, merah bila ditolak. Rotasi pada keping yang sudah menempel hanya diterapkan jika sah; jika belum sah, pilih posisi lain untuk meletakkannya.

Area sentuh inventori sekarang berasal dari CGRect thumbnail yang terlihat, bukan children SKCropNode. Path jalan panjang yang terpotong secara visual tidak dapat memilih thumbnail lain. Pemilihan pada papan tetap berdasarkan sel persegi yang terlihat, termasuk setelah pan/zoom.

Pilih keping terpasang lalu tekan **Balikkan keping**, atau drag keping ke panel inventori. Semua keping, termasuk awal/Arthur, bisa dikembalikan. Jika Arthur kehilangan kepingnya, pilih tempat aman pada keping tersisa. Jika tidak ada tempat aman atau papan kosong, **Jelajahi** meminta pemain memasang keping yang dapat dilalui. Papan kosong dapat disimpan dan dimuat kembali.

Rumah tetap tidak ditampilkan di mode ini. Save v2 dan cerita utama dipertahankan. Save lama dimuat tanpa dihapus, sementara penempatan/rotasi baru memeriksa sisi yang disentuh.

File: VillageTileLayout.swift, VillageCartoScene.swift, Validation/Carto/main.swift, CARTO.md.

Validasi: typecheck seluruh source iOS (tanpa macro preview di salinan validasi); model menguji semua kombinasi tetangga dan rotasi terhadap keping awal, penolakan overlap, penempatan terpisah, pengembalian semua keping, save papan kosong, dan transformasi posisi pemain. Interaksi sentuh belum diuji langsung pada perangkat.
