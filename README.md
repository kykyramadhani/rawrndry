# Laundry Day 🧺

Game kasual bertema **laundry** untuk iPhone/iPad. Pemain berperan sebagai petugas laundry: menerima cucian kotor dari pelanggan, mencuci, menjemur, melipat, lalu mengembalikannya untuk mendapat koin. Dibuat dengan **Swift** dan **SpriteKit** (framework 2D game bawaan Apple), dimainkan dalam mode **landscape** (layar mendatar).

Dokumen ini dibuat supaya siapa pun yang belum pernah mengurus game bisa langsung paham: teknologi apa yang dipakai, bagaimana alur permainannya, dan bagaimana kode-nya diorganisir.

---

## 1. Teknologi yang dipakai

| Bagian | Framework | Untuk apa |
|---|---|---|
| Tampilan & gameplay | **SpriteKit** | Engine 2D dari Apple — semua yang bergerak di layar (karakter, baju, tombol) adalah "node" SpriteKit |
| Shell aplikasi | **UIKit + Storyboard** | `Main.storyboard` → `GameViewController` adalah pintu masuk aplikasi yang aktif dipakai |
| Suara & musik | **AVFoundation** | Memutar musik latar, efek suara (gosok, lipat, dsb) |
| Deteksi tiup mikrofon | **AVFoundation + SoundAnalysis** | Fitur "tiup HP untuk mengeringkan baju" di scene Drying |
| Bahasa | **Swift 5** | Satu-satunya bahasa pemrograman di project ini |

Tidak ada backend/server — semua data (hari ke berapa, skor, progres cucian) disimpan **di memori** selama app berjalan lewat satu objek pusat bernama `GameState`, dan sebagian pengaturan (bahasa, volume, mic on/off) disimpan permanen lewat `UserDefaults` (penyimpanan kecil bawaan iOS).

---

## 2. Struktur folder penting

```
Laundry/
├── App/
│   └── GameViewController.swift     # Pintu masuk app, buka scene pertama (StartScene)
├── Scenes/
│   ├── Start/StartScene.swift       # Halaman judul & tombol START/CONTINUE
│   ├── Onboarding/OnboardingScene.swift  # Tutorial cerita raptor (hanya Day 1)
│   ├── FrontDesk/CustomerScene.swift     # Terima cucian kotor dari pelanggan
│   ├── FrontDesk/HandoffScene.swift      # Serahkan cucian bersih ke pelanggan
│   └── Washing/WashingScene.swift        # Mini-game cuci
├── WashingScene.swift, DryingScene.swift, FoldingScene.swift  # Mini-game inti (lihat catatan di bawah)
├── GameState.swift                  # "Otak" penyimpanan progres pesanan saat ini
├── Station.swift                    # Logika panah kiri/kanan untuk pindah antar scene
├── Models/                          # Struct data: LaundryItem, CustomerModel, LevelDesign
├── Managers/                        # Singleton: Audio, Settings, Customer, Haptic, dst.
├── Helpers/                         # Nama aset, teks lokalisasi (EN/ID), helper kecil
├── SKScene+Helpers.swift            # Fungsi bersama semua scene (HUD, popup, tutorial spotlight)
├── HomeButton.swift / SettingsPopup.swift  # Tombol home & settings yang muncul di semua scene
└── Asset/, Assets.xcassets/         # Gambar, font, audio
```

> **Catatan soal file yang "nyasar":** project ini awalnya bernama *TrialRawrndy*/*RawrndyApp*, lalu diganti nama jadi *Laundry*. Peninggalan dari versi lama masih ada di folder tapi **tidak lagi dipakai** dalam alur permainan sekarang:
> - `GameScene.swift`, `MainMenuScene.swift`, `Scenes/Packing/PackagingScene.swift` — scene contoh/purwarupa lama, sudah digantikan oleh `FoldingScene`.
> - `Managers/DayManager.swift`, `SaveManager.swift`, `ProgressManager.swift`, `CurrencyManager.swift` — sistem hari/koin versi awal; sekarang semua itu ditangani langsung oleh `GameState`.
> - `App/RawrndyApp.swift` — pintu masuk versi SwiftUI dari project lama; yang aktif dipakai sekarang adalah `Main.storyboard` + `GameViewController`.
>
> Aman diabaikan, tapi baik untuk diketahui kalau suatu saat mau beres-beres project.

---

## 3. Alur permainan (garis besar)

```
GameViewController
      │
      ▼
  StartScene  ───(hari 1 & belum pernah main)───▶ OnboardingScene (tutorial cerita)
      │                                                    │
      │ (hari 2+, atau sudah lewat onboarding)              │
      ▼◀───────────────────────────────────────────────────┘
  CustomerScene  (pelanggan datang, taruh cucian kotor)
      │
      ▼
  WashingScene  ──▶  DryingScene  ──▶  FoldingScene
      │  (cuci)         (jemur)          (lipat & bungkus)
      ▼
  HandoffScene  (serahkan bungkusan bersih, dapat koin & bintang)
      │
      ├─ masih ada pelanggan hari ini → kembali ke CustomerScene
      └─ pelanggan hari ini habis     → popup Reward → hari berikutnya → StartScene
```

Poin penting:
- **1 hari = beberapa pelanggan** (jumlahnya diatur di `LevelDesign.swift`). Saat ini baru ada 3 hari yang didesain; kalau sudah selesai semua, `StartScene` menampilkan pesan "More levels coming soon!".
- **Panah kiri/kanan** di setiap scene gameplay (lihat `Station.swift`) membiarkan pemain **bebas berpindah** antara Customer → Washing → Drying → Folding kapan saja, tidak harus berurutan. Progres tiap baju tetap tersimpan di `GameState`, jadi tidak hilang walau pindah-pindah scene.
- Setiap pesanan punya salah satu dari 3 tipe (`OrderType` di `GameState.swift`), yang menentukan tahap mana saja yang **wajib** selesai sebelum bisa diserahkan ke pelanggan:
  - `washOnly` → cukup dicuci
  - `washAndDry` → cuci + jemur
  - `washDryIron` → cuci + jemur + lipat

---

## 4. Penjelasan tiap scene

### StartScene — Halaman judul
Menampilkan background dan tombol **START** (hari 1) atau **CONTINUE** (hari 2+). Kalau seluruh hari yang didesain sudah tamat, tombolnya berubah jadi **START NEW GAME** yang mengulang dari hari 1.

### OnboardingScene — Tutorial cerita
Hanya muncul sekali, sebelum pelanggan pertama di hari 1. Karakter "raptor" bicara lewat balon kata dengan efek ketik huruf-per-huruf (typewriter), memperkenalkan alur cuci → jemur → lipat. Tap layar mempercepat teks yang sedang diketik.

### CustomerScene — Meja depan (terima cucian)
Pelanggan berjalan masuk membawa tas cucian kotor sambil bicara lewat balon kata (mis. minta sabun tertentu). Tap tas cucian → pindah ke WashingScene, dan pesanan baru (`GameState.startOrder`) mulai dicatat.

### WashingScene — Mencuci
Tahapannya per baju:
1. **Seret** baju kotor dari keranjang kiri ke batu cuci.
2. **Pilih sabun** yang benar (kalau pelanggan minta sabun tertentu) dengan menyeret botol sabun ke baju — salah sabun akan ditolak.
3. **Gosok** bajunya (gesek layar berulang) sampai progress noda 100%. Noda "berat" butuh gosokan lebih lama daripada noda "ringan". Ada gelembung sabun & getaran haptic sebagai feedback.
4. **Seret** baju bersih ke keranjang kanan → baju berikutnya otomatis muncul.

### DryingScene — Menjemur
1. Seret baju basah dari keranjang ke tali jemuran.
2. **Tiup mikrofon HP** untuk mengeringkan (game mendeteksi suara tiupan lewat volume mikrofon). Kalau mikrofon dimatikan di Settings, ada alat kipas daun sebagai pengganti — cukup diseret/digesek di dekat jemuran.
3. Terlalu keras meniup ("overblow") membuat baju yang belum kering **jatuh kembali** ke keranjang basah (layar ikut bergetar/shake sebagai efek).
4. Baju yang sudah 100% kering diseret ke keranjang kanan (kering).

### FoldingScene — Melipat & membungkus
1. Seret tiap baju kering satu per satu ke tengah bungkusan daun.
2. Setelah semua baju masuk, **gesek layar ke 4 arah berurutan** (kanan → kiri → bawah → atas) mengikuti panah yang menyala, mensimulasikan melipat 4 sisi daun pembungkus.
3. Terakhir, seret tali ke tengah bungkusan untuk mengikatnya → bungkusan selesai, otomatis lanjut ke HandoffScene (atau CustomerScene kalau pesanan tidak butuh dilipat).

### HandoffScene — Serahkan ke pelanggan
Seret bungkusan cucian bersih ke tangan pelanggan. Setelah diserahkan, muncul popup **Reward**: bintang 1–3 (berdasarkan persentase koin yang didapat dari maksimal yang mungkin) dan jumlah koin yang masuk ke skor. Kalau ini pelanggan terakhir hari itu, tombol OK di popup akan lanjut ke hari berikutnya.

---

## 5. "Otak" penyimpanan data — `GameState`

`GameState.shared` adalah satu objek tunggal (singleton) yang selalu hidup selama app berjalan. Semua scene gameplay membaca & menulis ke sini, bukan menyimpan datanya sendiri-sendiri — makanya progres tidak hilang walau pemain berpindah scene lewat panah kiri/kanan.

Yang disimpan antara lain:
- `currentDay`, `score` — hari & skor total pemain
- `currentOrderItems` — daftar baju di pesanan yang sedang dikerjakan
- `itemProgress` — progres cuci/jemur/lipat **per baju** (0.0–1.0), plus penanda posisi tiap baju (di batu cuci? di jemuran? sudah dilipat?)
- `isReadyForHandoff` / `isReadyForFolding` — dihitung otomatis dari `orderType` + progres, dipakai scene untuk mengunci aksi yang belum boleh dilakukan

> Catatan kecil: ada properti `tornItemsCount` (jumlah baju "sobek" yang harusnya memotong bayaran di Handoff) tapi belum ada scene manapun yang benar-benar menaikkan nilainya — jadi untuk saat ini penaltinya selalu 0. Kemungkinan ini fitur yang direncanakan tapi belum selesai dibangun.

---

## 6. Data & konten game (folder `Models/`)

- **`LevelDesign.swift`** — tabel desain level per hari (jumlah pelanggan, jumlah baju tiap pelanggan, besar bayaran). Di sinilah tempat menambah hari baru kalau mau memperpanjang game.
- **`CustomerModel.swift`** — data satu pelanggan (gambar karakter, daftar baju, sabun yang diminta, bayaran).
- **`LaundryItem.swift`** — data satu baju (pola/pattern 1–4, tingkat noda ringan/berat, sabun yang diminta vs. yang dipakai).

`Managers/CustomerManager.swift` bertugas mengacak pelanggan hari itu berdasarkan tabel di `LevelDesign` (pola baju, noda, dan permintaan sabun diacak setiap kali generate).

---

## 7. Fitur pendukung yang dipakai di semua scene

- **Tutorial "spotlight"** (`showSpotlightTutorial` di `SKScene+Helpers.swift`) — meredupkan layar dan menyorot satu elemen tertentu dengan efek glow + balon petunjuk, muncul otomatis sekali saja di hari 1 untuk mengajari pemain baru.
- **Tombol Settings** (roda gigi) — atur volume musik/SFX, bahasa (EN/ID), dan on/off mikrofon.
- **Tombol Home** — konfirmasi "yakin mau kembali ke awal?" yang mengulang hari yang sedang berjalan dari nol.
- **Lokalisasi** (`Helpers/Localization.swift`) — sebagian teks game (popup, tutorial, HUD) sudah mendukung Inggris & Indonesia lewat `Loc.t(.key)`; sebagian teks lain (dialog pelanggan, dsb.) masih hardcode bahasa Inggris.

---

## 8. Menjalankan project

1. Buka `Laundry.xcodeproj` dengan Xcode.
2. Pilih target **Laundry**, jalankan di simulator/perangkat iPhone atau iPad (orientasi dikunci **landscape**).
3. Untuk mencoba fitur "tiup mic" di Drying, jalankan di **perangkat asli** (simulator tidak punya input mikrofon sungguhan) dan izinkan akses mikrofon saat diminta.
4. Saat build **Debug**, semua tutorial spotlight akan otomatis direset tiap kali app dibuka (lihat `GameViewController.swift`) supaya developer bisa lihat ulang tutorialnya tanpa harus hapus data app.
