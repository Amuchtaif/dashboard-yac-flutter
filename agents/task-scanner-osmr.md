# 📱 [Task Spec] Implementasi Flutter Mobile: Fitur Scanner LJK (OMR) & Koreksi Soal Pilihan Ganda

Dokumen spesifikasi teknis lengkap untuk pengerjaan sisi **Flutter Mobile App** (`C:\src\Project\dashboard-yac`) agar terintegrasi penuh dengan modul **Bank Soal & LJK (OMR)** yang sudah dibangun pada backend **Dashboard YAC** (`d:\xampp\htdocs\dashboard-yac`).

> **Catatan Arsitektur Penting:**  
> Backend berjalan di **Shared Hosting (PHP 8.2 + MySQL)** sehingga seluruh proses pemindaian kamera, deteksi QR Code, pelurusan kertas (_perspective warp_), dan pembacaan bulatan jawaban (**OMR**) **HARUS berjalan 100% _on-device_ di Flutter** (tidak mengirim foto mentah untuk diproses di server).

---

## 1. 🎯 Alur Kerja Fitur di Aplikasi Flutter

1. **Daftar Paket Soal:** Guru membuka menu **Koreksi LJK / Exam Scanner**, melihat daftar paket soal pada tahun ajaran aktif (bisa memilih paket `published`, atau `draft` untuk uji coba).
2. **Unduh & Cache Lokal (Offline-Ready):** Saat membuka paket soal, Flutter mengunduh metadata paket, **kunci jawaban (`answer_keys`)**, **daftar santri kelas (`students`)**, dan **koordinat geometri LJK (`omr_layout`)**, lalu menyimpannya di cache lokal (Hive / SharedPreferences / SQLite) agar guru tetap bisa scan di ruang kelas meski sinyal lemah.
3. **Kamera Scanner LJK:**
   - Guru mengarahkan kamera ke lembar LJK cetak A4 dari web (`views/exams/print_ljk.php`).
   - Aplikasi membaca **QR Code** di pojok kanan atas LJK untuk otomatis mengenali `package_id` dan `student_id` (serta bisa verifikasi apakah LJK cocok dengan paket soal yang dibuka).
   - Aplikasi mendeteksi **4 kotak hitam sudut (_Fiducial Anchor Markers_)** pada area jawaban, meluruskan perspektif kertas (_perspective transform_), lalu membaca intensitas arsiran pada koordinat bulatan secara dinamis (mendukung variasi **3 opsi `A–C`**, **4 opsi `A–D`**, maupun **5 opsi `A–E`**, hingga 100 soal).
4. **Preview Koreksi Visual & Revisi Manual (_Tap-to-Fix_):**
   - Setelah capture/scan, tampilkan foto LJK yang sudah diluruskan (_warped image_) dengan **overlay visual**:
     - 🟢 **Hijau:** Jawaban benar
     - 🔴 **Merah:** Jawaban salah (+ penanda kuning/outline di posisi kunci jawaban yang benar)
     - 🟡 **Kuning/Abu:** Kosong (`BLANK`) atau arsiran ganda (`DOUBLE`)
   - Guru dapat **mengetuk nomor soal** di daftar/grid untuk memperbaiki jawaban secara manual jika ada arsiran tipis/coretan yang keliru terbaca.
   - Jika QR Code berasal dari LJK Kosong (`s:0`), tampilkan _searchable picker_ untuk memilih nama santri dari daftar `students` paket tersebut.
5. **Submit ke Backend:** Kirim hasil jawaban JSON (+ opsional gambar LJK terkompresi) ke `/api/exams/submit_scan.php`. Backend melakukan validasi skor final dan menyimpannya ke database (opsional `auto_sync=1` untuk langsung sinkron ke `student_assessments`).

---

## 2. 🔌 Kontrak REST API Backend (Sudah Siap Pakai)

Lokasi endpoint di server: `https://dashboard.assunnahcirebon.com/api/exams/` (atau `{BASE_URL}/api/exams/`).

### A. Ambil Daftar Paket Soal Guru

- **URL:** `GET /api/exams/packages.php?user_id={user_id}`
- **Query Params Opsional:** `status` (`published`, `draft`, `closed`). Default mengembalikan `published` dan `draft` milik guru pada tahun ajaran aktif (atau semua jika Admin).
- **Response (HTTP 200):**

```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "id": 12,
      "title": "PTS Ganjil Fiqih 7A",
      "teacher_id": 196,
      "grade_level_id": 42,
      "subject_id": 8,
      "assessment_type_id": 1,
      "academic_year_id": 4,
      "total_questions": 25,
      "option_count": 4,
      "option_labels": ["A", "B", "C", "D"],
      "scoring_mode": "equal_100",
      "exam_date": "2026-11-27",
      "ljk_template": "v1",
      "status": "published",
      "subject_name": "Fiqih",
      "grade_name": "7A",
      "unit_name": "MTs",
      "assessment_type_name": "Penilaian Tengah Semester",
      "teacher_name": "Ust. Fulan",
      "filled_questions": 25,
      "scanned_count": 12,
      "class_student_count": 24
    }
  ]
}
```

---

### B. Ambil Detail Paket, Kunci Jawaban, Daftar Santri & Geometri OMR

- **URL:** `GET /api/exams/package_detail.php?package_id={package_id}`
- **Response (HTTP 200):**

```json
{
  "success": true,
  "package": {
    "id": 12,
    "title": "PTS Ganjil Fiqih 7A",
    "subject_name": "Fiqih",
    "grade_name": "7A",
    "unit_name": "MTs",
    "assessment_type_name": "Penilaian Tengah Semester",
    "total_questions": 25,
    "option_count": 4,
    "option_labels": ["A", "B", "C", "D"],
    "scoring_mode": "equal_100",
    "ljk_template": "v1",
    "status": "published",
    "exam_date": "2026-11-27"
  },
  "answer_keys": [
    {
      "question_id": 101,
      "question_number": 1,
      "correct_option": "A",
      "weight": 1.0
    },
    {
      "question_id": 102,
      "question_number": 2,
      "correct_option": "C",
      "weight": 1.0
    }
  ],
  "students": [
    {
      "id": 199,
      "nama_siswa": "Ammar Jundullah",
      "nomor_induk": "2-2223101",
      "is_scanned": false,
      "last_score": null
    }
  ],
  "omr_layout": {
    "template": "v1",
    "box_width_mm": 172,
    "box_height_mm": 185,
    "columns": 2,
    "rows_per_col": 25,
    "total_questions": 25,
    "option_count": 4,
    "option_labels": ["A", "B", "C", "D"],
    "bubble_radius_x": 0.014,
    "bubble_diameter_mm": 4.82,
    "questions": [
      {
        "question_number": 1,
        "col": 1,
        "row": 1,
        "num_x": 0.079,
        "y": 0.0733,
        "options": {
          "A": { "x": 0.167, "y": 0.0733 },
          "B": { "x": 0.251, "y": 0.0733 },
          "C": { "x": 0.335, "y": 0.0733 },
          "D": { "x": 0.419, "y": 0.0733 }
        }
      }
    ]
  }
}
```

---

### C. Submit Hasil Scan LJK

- **URL:** `POST /api/exams/submit_scan.php`
- **Content-Type:** `application/json` (atau `multipart/form-data` jika menyertakan foto LJK `scan_image`).
- **Payload JSON:**

```json
{
  "package_id": 12,
  "student_id": 199,
  "scanner_user_id": 196,
  "auto_sync": true,
  "answers": [
    { "question_number": 1, "selected_option": "A" },
    { "question_number": 2, "selected_option": "C" },
    { "question_number": 3, "selected_option": "BLANK" },
    { "question_number": 4, "selected_option": "DOUBLE" }
  ]
}
```

> Jika mengirim `multipart/form-data`, kirim `answers` sebagai JSON string (`jsonEncode(...)`) dan lampirkan file terkompresi (JPEG max 5MB, disarankan di-resize ke lebar ~1000px) pada field `scan_image`.

- **Response (HTTP 200):**

```json
{
  "success": true,
  "message": "Hasil scan LJK berhasil dikoreksi dan disimpan.",
  "student_name": "Ammar Jundullah",
  "data": {
    "scan_result_id": 45,
    "package_id": 12,
    "student_id": 199,
    "total_questions": 25,
    "correct_count": 20,
    "wrong_count": 3,
    "blank_count": 1,
    "double_count": 1,
    "score": 80,
    "answers": [
      {
        "question_id": 101,
        "question_number": 1,
        "selected_option": "A",
        "correct_option": "A",
        "is_correct": 1
      }
    ]
  },
  "assessment_sync": {
    "assessment_id": 145,
    "synced_count": 1
  }
}
```

---

### D. Ambil Rekap Nilai Hasil Scan per Paket

- **URL:** `GET /api/exams/scan_results.php?package_id={package_id}`
- **Response (HTTP 200):**

```json
{
  "success": true,
  "summary": {
    "scanned_count": 12,
    "average_score": 82.5,
    "highest_score": 100,
    "lowest_score": 60
  },
  "data": [
    {
      "id": 45,
      "package_id": 12,
      "student_id": 199,
      "nama_siswa": "Ammar Jundullah",
      "nomor_induk": "2-2223101",
      "correct_count": 20,
      "wrong_count": 3,
      "blank_count": 1,
      "double_count": 1,
      "score": 80,
      "assessment_id": 145,
      "scan_image_url": "https://dashboard.assunnahcirebon.com/uploads/exams/scans/scan_12_199_17958.jpg",
      "scanned_at": "2026-11-27 14:15:00"
    }
  ]
}
```

---

## 3. 📐 Spesifikasi Teknis LJK, QR Code & Algoritma OMR On-Device

### A. Format Payload QR Code pada LJK

Setiap lembar LJK yang dicetak dari `views/exams/print_ljk.php` memiliki QR Code berisi string terstruktur:

```text
YAC|p:{package_id}|s:{student_id}|q:{total_questions}|o:{option_count}|t:{template}
```

Contoh:

- **Pre-Printed Santri:** `YAC|p:12|s:199|q:25|o:4|t:v1` → `student_id = 199` terdeteksi otomatis.
- **LJK Kosong:** `YAC|p:12|s:0|q:25|o:4|t:v1` → `student_id = 0`, aplikasi wajib meminta guru memilih nama santri dari dropdown `students`.

Parsing di Flutter:

- Split dengan `|`, pastikan diawali `YAC`, lalu parse key-value `p`, `s`, `q`, `o`, `t`.
- Validasi: jika `p != selectedPackage.id`, tampilkan konfirmasi/peringatan kepada guru (_"QR LJK ini milik paket soal lain (#p). Pindah ke paket tersebut atau batalkan?"_).

---

### B. Geometri LJK & Anchor Markers

Pada LJK cetak (`print_ljk.php`):

- Area jawaban dibatasi kotak berdimensi **`172.0 mm × 185.0 mm`** (rasio `W : H = 172 : 185 ≈ 0.92973`).
- Di keempat sudut tepat (`(0%, 0%)`, `(100%, 0%)`, `(0%, 100%)`, `(100%, 100%)`) terdapat **4 kotak hitam pekat (_Fiducial Anchor Markers_)** berukuran `7mm × 7mm` yang titik pusatnya berada di sudut kotak koordinat normalisasi `(0,0)`, `(1,0)`, `(0,1)`, dan `(1,1)`.
- Koordinat setiap bulatan jawaban `A..E` diberikan langsung oleh API dalam `omr_layout.questions[]`:
  - `x` dan `y` adalah posisi relatif `0.0 .. 1.0` terhadap titik pusat 4 sudut tersebut!
  - `bubble_radius_x` adalah radius relatif terhadap lebar kanvas hasil warp.

---

### C. Pipeline Pengolahan Citra OMR di Flutter (`opencv_dart`)

Disarankan menggunakan package **`opencv_dart`** (C++ OpenCV native binding untuk Flutter, sangat cepat ~30-80ms per frame/foto) + **`camera`** + **`mobile_scanner`** (atau `google_mlkit_barcode_scanning` untuk QR Code).

#### Langkah-langkah Pemrosesan Foto LJK:

1. **Scan QR Code (opsional sebelum/bersamaan capture):**
   - Ekstrak payload `YAC|p:...|s:...` dari bagian atas gambar.
2. **Preprocessing & Deteksi 4 Corner Anchor Markers:**
   - Konversi citra ke **Grayscale** → **GaussianBlur (5×5)** → **AdaptiveThreshold** (`ADAPTIVE_THRESH_GAUSSIAN_C`, `THRESH_BINARY_INV`, `blockSize=21`, `C=10`) agar tahan terhadap bayangan lampu kelas yang tidak merata.
   - Cari kontur (`findContours`, `RETR_EXTERNAL` atau `RETR_LIST`):
     - Filter kontur yang memiliki `approxPolyDP` bersudut **4 titik** (`epsilon = 0.04 * perimeter`), berbentuk mendekati persegi (`aspectRatio` antara `0.75` s.d. `1.35`), solidity tinggi (`area / boundingRectArea > 0.75`), dan luas yang wajar (sesuai ukuran kotak `7mm × 7mm` relatif terhadap frame).
     - Kelompokkan atau identifikasi 4 kandidat sudut terluar area LJK (**Top-Left, Top-Right, Bottom-Left, Bottom-Right**) berdasarkan posisi $(x+y)$ dan $(x-y)$ dari _centroid_ kontur!
     - _(Tips UX Kamera)_: Pada tampilan kamera _live preview_, tampilkan **4 kotak target pemandu** (_viewfinder corners_) dengan rasio `172:185` sehingga posisi 4 kotak LJK sejajar dengan area kamera, membuat deteksi nyaris 100% akurat!
3. **Perspective Transform (Meluruskan Kertas):**
   - Gunakan `getPerspectiveTransform` dari 4 titik pusat marker (`[TL, TR, BR, BL]`) ke kanvas target beresolusi tetap:
     - Lebar `W = 1000`, Tinggi `H = 1076` (`round(1000 * 185 / 172)`).
   - Terapkan `warpPerspective` untuk mendapatkan citra LJK tegak lurus `1000 × 1076 px`.
4. **Thresholding Area Jawaban:**
   - Pada citra warped `1000 × 1076`, buat citra biner invers menggunakan **Adaptive Threshold** (atau Otsu lokal per kolom) sehingga arsiran pensil/pulpen hitam bernilai putih (`255`) dan kertas kosong bernilai hitam (`0`).
   - _(Catatan)_: Huruf tipis `A/B/C/D/E` yang tercetak di dalam bulatan kosong memiliki garis tipis (`~7pt` abu-abu/slate) yang rata-rata hanya mengisi ~10–18% area bulatan, sedangkan bulatan yang dihitamkan santri mengisi **>45–85%** area bulatan!
5. **Pembacaan Bulatan Dinamis (`omr_layout.questions`):**
   - Hitung radius sampling dalam piksel: `r = (omrLayout.bubbleRadiusX * W) * 0.82` _(sedikit di dalam garis tepi lingkaran agar border lingkaran hitam `0.45mm` tidak ikut terhitung penuh!)_.
   - Untuk setiap soal `q` di `omrLayout.questions`:
     - Untuk setiap opsi `lbl` (`A..C`, `A..D`, atau `A..E`):
       - Titik pusat piksel: `cx = opt.x * W`, `cy = opt.y * H`.
       - Hitung rasio piksel putih (_fill ratio_) di dalam masker lingkaran beradius `r` pada titik `(cx, cy)`.
   - **Klasifikasi Jawaban per Nomor (Relative + Absolute Threshold):**
     - Definisikan `FILLED_THRESHOLD = 0.38` (bisa dikalibrasi/disetel di pengaturan scanner, misal `0.35 - 0.45`) dan `GAP_RATIO` terhadap opsi tertinggi.
     - Kumpulkan semua opsi yang memiliki `fillRatio >= FILLED_THRESHOLD` (atau nilai maksimum jauh di atas rata-rata baris tersebut jika santri mengarsir agak tipis, misal `maxRatio >= 0.28 && (maxRatio - secondMaxRatio) >= 0.14`):
       - Jika **0 opsi** memenuhi → `"BLANK"`
       - Jika **1 opsi** memenuhi → `optionLabel` (mis. `"B"`)
       - Jika **≥ 2 opsi** memenuhi (selisih tipis di atas threshold) → `"DOUBLE"`
6. **Penilaian Instan & Rendering Overlay:**
   - Bandingkan hasil tiap nomor dengan `answer_keys` lokal:
     - Cocok → gambar lingkaran **Hijau (`#10B981`)** di `(cx, cy)` pada preview citra `1000 × 1076`.
     - Salah → gambar lingkaran **Merah (`#EF4444`)** di jawaban santri + lingkaran outline **Kuning/Biru (`#F59E0B`)** di posisi `correct_option`.
     - `BLANK` / `DOUBLE` → gambar indikator **Kuning** di nomor tersebut + outline kunci benar.

---

## 4. 📱 Rincian Layar & Komponen UI di Flutter

Disarankan menempatkan modul baru di `lib/features/exam_scanner/` (atau menyesuaikan struktur folder di `C:\src\Project\dashboard-yac`):

1. **Entry Point Menu:**
   - Tambahkan menu/kartu **"Koreksi LJK (OMR)"** di halaman Akademik / Beranda Guru (hanya tampil untuk guru/admin dengan permission akademik atau jadwal mengajar).
2. **`ExamPackageListScreen` (Daftar Paket Ujian):**
   - Memanggil `GET /api/exams/packages.php?user_id=...`.
   - Menampilkan judul paket, mapel, kelas, variasi opsi (`4 Opsi A-D`), progres soal (`25/25`), jumlah terscan (`12/24`), badge status (`Siap Scan` / `Draft`).
   - Fitur _Pull-to-refresh_ & filter status.
3. **`ExamPackageDetailScreen` (Dashboard Paket & Rekap Kelas):**
   - Memanggil `GET /api/exams/package_detail.php?package_id=...` dan menyimpannya ke cache offline.
   - Menampilkan tombol utama **"Mulai Scan LJK"** (Kamera) + tombol sekunder **"Pilih Foto dari Galeri"** (sangat berguna untuk debug/koreksi foto LJK yang dikirim via WA).
   - Menampilkan daftar santri kelas: tanda centang hijau + nilai bagi santri yang sudah di-scan, dan status "Belum" bagi yang belum.
4. **`OmrCameraScannerScreen` (Kamera Live Scanner):**
   - Live preview kamera belakang dengan overlay bingkai pemandu 4 kotak sudut (rasio `172:185`) + kotak pemandu QR di kanan atas.
   - Indikator status live: _"Arahkan LJK ke dalam bingkai"_ → _"QR Terdeteksi (Paket #12 • Ammar)"_ → tombol Capture (atau auto-capture saat stabil).
   - Toggle Flash/Torch untuk ruang kelas yang redup.
5. **`OmrResultReviewScreen` (Preview Koreksi & Tap-to-Fix):**
   - Atas: Gambar hasil warp (`1000 × 1076`) dengan overlay visual bulatan hijau/merah/kuning + _InteractiveViewer_ (bisa di-pinch zoom).
   - Header Info: Nama Santri (jika `student_id == 0` dari QR, tampilkan dropdown/searchable modal pilih santri) + Kartu Skor Besar (**Nilai**, **Benar**, **Salah**, **Kosong/Ganda**).
   - Bawah: Grid/List nomor soal `1..N` yang menampilkan jawaban terbaca vs kunci, dengan tombol cepat `A / B / C (/ D / E)` per nomor agar guru bisa revisi manual 1-tap lalu skor langsung terhitung ulang real-time!
   - Tombol Aksi:
     - **"Simpan & Scan Berikutnya"** → `POST /api/exams/submit_scan.php` (dengan `auto_sync: true`), tampilkan snackbar sukses lalu langsung kembali ke kamera untuk santri berikutnya (_batch flow_).
     - **"Scan Ulang"** → kembali ke kamera tanpa menyimpan.

---

## 5. 📦 Daftar Package Flutter yang Dibutuhkan (`pubspec.yaml`)

```yaml
dependencies:
  camera: ^0.11.0
  opencv_dart: ^1.3.0 # Deteksi 4 anchor, perspective warp, adaptive threshold, & fill-ratio OMR on-device
  mobile_scanner: ^6.0.0 # Atau google_mlkit_barcode_scanning untuk pembacaan QR Code LJK
  image_picker: ^1.1.2 # Fallback scan dari foto galeri
  http: ^1.2.2 # Atau dio (sesuai HTTP client yang sudah dipakai di project)
  path_provider: ^2.1.4 # Simpan sementara gambar hasil warp terkompresi
```

_(Sesuaikan versi package agar kompatibel dengan versi Dart/Flutter SDK & Gradle project `C:\src\Project\dashboard-yac`.)_

---

## 6. ✅ Checklist Verifikasi untuk Agent Flutter

- [ ] Paket `published` dan `draft` tampil di `ExamPackageListScreen` sesuai `user_id` guru.
- [ ] Uji cetak **LJK 3 Opsi (`A–C`)**, **4 Opsi (`A–D`)**, dan **5 Opsi (`A–E`)** dari web dashboard (`views/exams/print_ljk.php`), lalu scan dengan Flutter: pastikan semua bulatan terpetakan tepat pada posisinya.
- [ ] Uji scan LJK dalam kondisi kertas agak miring (±10–15°) dan pencahayaan ruangan normal: pastikan 4 anchor marker terdeteksi dan hasil warp lurus.
- [ ] Uji kasus jawaban **Benar**, **Salah**, **Kosong (`BLANK`)**, dan **Arsiran Ganda (`DOUBLE`)**.
- [ ] Uji fitur **Tap-to-Override** manual di layar review sebelum menekan **Simpan**.
- [ ] Uji **LJK Pre-Printed** (auto-detect `student_id` dari QR) maupun **LJK Kosong (`s:0`)** (pilih santri manual).
- [ ] Verifikasi setelah submit dari Flutter, data langsung muncul di halaman web `views/exams/results.php` dan tersinkron ke `student_assessments` (jika `auto_sync: true`).
