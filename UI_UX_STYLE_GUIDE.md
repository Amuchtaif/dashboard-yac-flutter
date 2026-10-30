# 🎨 Panduan Desain & Basis Styling UI/UX (Aplikasi YAC)
**Yayasan As-Sunnah Cirebon (Dashboard YAC)**  
*Dokumentasi Resmi Basis Styling, Desain Sistem, dan Analisis Komponen Antarmuka*

---

## 1. Filosofi Desain & Visi Antarmuka

Aplikasi **Dashboard YAC (Yayasan As-Sunnah Cirebon)** dirancang dengan pendekatan:
1. **Modern Clean & Functional**: Tampilan yang bersih, elegan, dan fungsional tanpa ornamen berlebihan.
2. **Keterbacaan Tinggi (High Legibility)**: Menggunakan tipografi Google Fonts **Poppins** yang tegas, jelas, dan ramah di berbagai ukuran layar smartphone.
3. **Konsistensi Berbasis Peran & Modul (Role & Module-Based Color Coding)**: Memberikan warna tematik pada modul utama (Pendidikan, Kesantrian, Tahfidz, Kepegawaian/Presensi, Sarpras) sehingga pengguna dapat dengan cepat mengidentifikasi konteks kerja mereka.
4. **Interaksi Ramah Pengguna (Haptic & Micro-Feedback)**: Menyediakan status umpan balik yang jelas (loading spinner, shimmer, pull-to-refresh, floating SnackBar, dan empty state informatif).

---

## 2. Sistem Warna (Color Palette)

### 2.1 Brand & Core Palette
| Nama Token | Hex Code | Pratinjau | Penggunaan Utama |
|---|---|---|---|
| `Brand Navy` | `#1F3C88` | 🟦 | Warna resmi logo YAC, tombol utama login, splash |
| `Brand Blue` | `#2563EB` | 🟦 | Aksen primer Material, link aktif, toggle switch |
| `Primary Light` | `#3B82F6` | 🔷 | Highlight, header kalender, button secondary |
| `Indigo Accent`| `#4F46E5` | 🟪 | Modul presensi & rekap, gradient header, badge aktif |

### 2.2 Warna Latar & Netral (Neutrals & Backgrounds)
| Nama Token | Hex Code | Penggunaan |
|---|---|---|
| `Scaffold Background` | `#F8FAFC` (Slate 50) | Latar belakang seluruh halaman modern |
| `Legacy Background` | `#F5F5F5` | Latar belakang modul lama (direkomendasikan migrasi ke `#F8FAFC`) |
| `Surface Card` | `#FFFFFF` | Kontainer kartu, dialog, bottom sheet, elevated card |
| `Sub-Surface / Input Fill` | `#F1F5F9` (Slate 100) | Latar isian form text field, container selector |
| `Border Soft` | `#E2E8F0` (Slate 200) | Garis pembatas kartu, field border, divider halus |
| `Text Main` | `#1E293B` (Slate 800) | Judul halaman, teks tebal, nama, label utama |
| `Text Regular` | `#334155` (Slate 700) | Teks isi/konten, deskripsi, paragraf |
| `Text Muted` | `#64748B` (Slate 500) | Label sekunder, waktu, tanggal, subtitle kartu |
| `Text Light / Hint` | `#94A3B8` (Slate 400) | Placeholder form, disabled text, counter |

### 2.3 Warna Modul / Kategori Kerja (Domain Themes)
Setiap divisi memiliki warna identitas untuk memudahkan diferensiasi visual:
- **Presensi & Kepegawaian**: `#4F46E5` (Indigo) & `#6366F1`
- **Pendidikan & Guru (Akademik)**: `#2563EB` (Royal Blue) & `#3B82F6`
- **Laporan Kerja (Work Report)**: `#7C3AED` (Deep Violet) & `#8B5CF6`
- **Kesantrian & Asrama**: `#EA580C` (Warm Amber/Orange) & `#F97316`
- **Tahfidz Al-Qur'an**: `#0D9488` (Teal) & `#059669` (Emerald Green)
- **Inventaris & Sarpras**: `#D97706` (Amber Gold)
- **Media & Dakwah (TV/News)**: `#DC2626` (Red)

### 2.4 Warna Status Semantik (Semantic Feedback)
| Status | Warna Utama | Latar Tint (Background) | Garis Border | Makna / Konteks |
|---|---|---|---|---|
| **Hadir / Sukses / Lancar** | `#22C55E` (Green) | `#F0FDF4` | `#DCFCE7` | Absen masuk tepat waktu, hafalan lancar, disetujui |
| **Terlambat / Alpha / Ditolak** | `#EF4444` (Red) | `#FEF2F2` | `#FEE2E2` | Terlambat masuk, alpha, setoran ulang, pelanggaran |
| **Sakit / Peringatan / Menunggu**| `#F59E0B` (Amber) | `#FFFBEB` | `#FEF3C7` | Izin sakit, butuh approval, catatan khusus |
| **Izin / Info / Pulang Cepat** | `#0284C7` (Sky Blue) | `#E0F2FE` | `#BAE6FD` | Izin dinas/pribadi, pengumuman, dispensasi |

---

## 3. Sistem Tipografi (Typography Hierarchy)

Font standar aplikasi adalah **Google Fonts Poppins** (`GoogleFonts.poppins(...)`).

```
+--------------------------------------------------------------------------+
|  Display/Hero Title  | 20-22px | Bold (w700)      | Color: #1E293B       |
|  Page Title (AppBar) | 16-18px | SemiBold (w600)  | Color: #1E293B       |
|  Section Header      | 15-16px | SemiBold/Bold    | Color: #1E293B       |
|  Card Title / Primary| 14-15px | SemiBold (w600)  | Color: #1E293B       |
|  Body Regular        | 13-14px | Regular (w400)   | Color: #334155       |
|  Subtitle / Secondary| 11-12px | Medium (w500)    | Color: #64748B       |
|  Badges / Chips      | 10-11px | Bold (w700)      | Color: Semantic      |
|  Micro Caption       |  9-10px | SemiBold (w600)  | Color: #94A3B8       |
+--------------------------------------------------------------------------+
```

### Standar Deklarasi Teks:
```dart
// Judul Layar / AppBar Title
style: GoogleFonts.poppins(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: const Color(0xFF1E293B),
);

// Judul Seksi (Section Title)
style: GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: const Color(0xFF1E293B),
);

// Teks Utama Kartu
style: GoogleFonts.poppins(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: const Color(0xFF1E293B),
);

// Teks Deskripsi / Tanggal
style: GoogleFonts.poppins(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: const Color(0xFF64748B),
);

// Teks Badge Status
style: GoogleFonts.poppins(
  fontSize: 10,
  fontWeight: FontWeight.bold,
  color: const Color(0xFF22C55E),
);
```

---

## 4. Spasi, Radius, & Elevasi (Geometry & Depth)

### 4.1 Skala Spasi (Spacing Scale)
- `4px` : Jarak antar icon dan teks badge kecil
- `8px` : Padding badge, jarak antar kolom mini
- `12px`: Jarak antar elemen dalam satu kartu, margin bawah item daftar
- `16px`: Padding default form, padding kartu standar, margin horizontal
- `20px`: Margin tepi luar layar (Edge Screen Margin), padding kartu besar
- `24px`: Jarak antar section besar dalam halaman
- `32px`: Spacing empty state, separator akhir halaman

### 4.2 Skala Border Radius
- `BorderRadius.circular(6)` : Tag kecil, badge status kotak mini
- `BorderRadius.circular(10-12)`: Tombol aksi, text input field, icon container
- `BorderRadius.circular(16)` : Kartu daftar riwayat, notifikasi item, alert card
- `BorderRadius.circular(20-24)`: Hero card, summary card, kalender card
- `BorderRadius.circular(30)` : Bottom sheet top corners, circular full-pill button
- `BoxShape.circle` : Avatar profil, icon check-in, marker dots

### 4.3 Elevasi & Bayangan (Shadow System)
Gunakan bayangan halus modern (`withValues(alpha: ...)`) daripada elevasi kasar Material:

```dart
// Kartu Standar (Subtle Card Shadow)
boxShadow: [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 15,
    offset: const Offset(0, 5),
  ),
]

// Kartu Hero / Gradient (Glow Shadow)
boxShadow: [
  BoxShadow(
    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
    blurRadius: 18,
    offset: const Offset(0, 8),
  ),
]

// Floating / Elevated Component
boxShadow: [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 20,
    offset: const Offset(0, 10),
  ),
]
```

---

## 5. Analisis Komponen UI & UX di Setiap Layar

### 5.1 Dashboard Utama (`dashboard_screen.dart`)
- **Header Profil**: Menampilkan foto pengguna (`CachedNetworkImage` dalam avatar lingkaran), nama lengkap, jabatan, dan divisi/unit. Dilengkapi icon lonceng notifikasi dengan badge merah jika ada pesan belum dibaca.
- **Kartu Presensi Cepat (Hero Attendance Card)**:
  - Tombol aksi utama "Absen Masuk" / "Absen Pulang".
  - Status jam masuk dan jam pulang yang jelas.
  - Kartu verifikasi lokasi GPS & peta mini interaktif dengan radius penugasan.
- **Menu Grid Layanan (Role-Based Features)**:
  - Grid 4 kolom dengan icon bulat berwarna tematik.
  - Ditampilkan secara dinamis sesuai perizinan pengguna (Role: Guru, Musrif, Wali Kelas, Kabid, dll).
- **Banner Slider Berita**: Card horizontal dengan gambar tajuk dan judul berita terbaru yayasan.
- **Daftar Aktivitas Terbaru**: Feed aktivitas hari ini (presensi, izin, setoran).

### 5.2 Layar Rekap Kehadiran Pribadi (`self_attendance_recap_screen.dart`)
- **AppBar**:
  - Judul di tengah: "Rekap Kehadiran" disertai sub-judul rentang tanggal aktif (misal: `26 Sep - 25 Okt 2026`).
  - Action pojok kanan atas: Icon kalender untuk membuka dialog filter rentang tanggal.
- **Calendar View**:
  - `TableCalendar` interaktif dengan indikator titik warna (Dot):
    - 🟢 Dot Hijau: Hadir (tercatat absensi masuk/pulang).
    - 🔴 Dot Merah: Tidak Hadir (hari yang sudah lewat hingga hari ini tanpa absensi).
    - Masa depan: Tanpa dot.
  - Kalender menampilkan seluruh data bulan aktif dan tidak terpotong oleh filter rentang tanggal.
  - Pemilihan tanggal di kalender akan memfilter detail kehadiran untuk hari tersebut.
- **Summary Card**:
  - Gradient Indigo-Ungu elegan (`#4F46E5` ke `#6366F1`).
  - Menampilkan 4 metrik: Total Hadir, Tepat Waktu, Terlambat, dan Pulang Cepat.
- **Daftar Riwayat Kehadiran**:
  - Setiap card memuat jenis absensi (Masuk/Pulang), hari & tanggal lengkap, jam, serta pill badge status (Tepat Waktu / Terlambat).
  - Dilengkapi tombol "Lihat Semua" dan "Reset Filter".

### 5.3 Layar Pendidikan & Akademik (`teaching_schedule_screen`, `class_journal_screen`, `student_grading_screen`)
- **Selektor Hari & Jenjang**: Tab bar atau horizontal scroll chip untuk berpindah hari (Senin - Ahad) atau jenjang sekolah (TK, SD, MTs, MA, Ma'had Aly).
- **Status Filter Counters**: Badge row berjejer menampilkan jumlah siswa (Total, Hadir, Sakit, Izin, Alpha) yang berfungsi ganda sebagai filter klik satu sentuhan.
- **Input Nilai & Form Jurnal**:
  - Card per siswa dengan avatar inisial, NIS, nama lengkap, dan quick status selector (H / S / I / A).
  - Floating action button besar di bawah untuk menyimpan jurnal kelas atau penilaian harian.

### 5.4 Layar Kesantrian & Asrama (`kesantrian/absensi_asrama_screen.dart`, `absensi_makan_screen.dart`)
- **Pengelompokan per Kamar/Gedung**: List asrama dengan visual progress bar persentase santri yang sudah diabsen.
- **Pencarian Cepat Siswa**: Search bar sticky di bagian atas dengan input real-time filtering nama atau kamar santri.
- **Status Makan & Perizinan**: Card riwayat izin dengan badge status proses (Menunggu Persetujuan, Disetujui, Ditolak, Selesai).

### 5.5 Layar Tahfidz Al-Qur'an (`tahfidz/setoran_tahfidz_screen.dart`, `riwayat_setoran_screen.dart`)
- **Selektor Surah & Ayat**: Bottom sheet modal pencarian surah Al-Qur'an dengan input keyboard angka untuk ayat awal dan ayat akhir.
- **Badge Kualitas Hafalan**:
  - `Lancar` (Hijau)
  - `Kurang Lancar` (Kuning/Orange)
  - `Ulang` (Merah)
- **Tampilan Juz & Baris**: Statistik progress mutqin santri per halaqah.

### 5.6 Layar Pengajuan Izin & Laporan Kerja (`permit_screen.dart`, `work_report_screen.dart`)
- **Segmented Control Izin**: Tab pilihan jenis izin ("Izin Jam" vs "Izin Hari").
- **Attachment Upload Box**: Area upload foto bukti/surat dokter dengan preview gambar dan tombol hapus/ganti.
- **Time/Date Picker Trigger**: Kotak input sentuh dengan icon kalender/jam yang memicu picker bawaan platform.

---

## 6. Library Template Komponen Standar

### 6.1 AppBar Standar Layar
```dart
AppBar buildCustomAppBar(BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: const Color(0xFFF8FAFC),
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
      onPressed: () => Navigator.pop(context),
    ),
    centerTitle: true,
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
      ],
    ),
    actions: actions,
  );
}
```

### 6.2 Kartu Hero Gradient (Summary Card)
```dart
Widget buildGradientSummaryCard({
  required String stat1Value,
  required String stat1Label,
  required String stat2Value,
  required String stat2Label,
  required String stat3Value,
  required String stat3Label,
  required String stat4Value,
  required String stat4Label,
  List<Color> gradientColors = const [Color(0xFF4F46E5), Color(0xFF6366F1)],
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: gradientColors.first.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            _buildStatItem(stat1Label, stat1Value, Icons.check_circle_outline_rounded),
            _buildStatItem(stat2Label, stat2Value, Icons.timer_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatItem(stat3Label, stat3Value, Icons.alarm_off_rounded),
            _buildStatItem(stat4Label, stat4Value, Icons.directions_walk_rounded),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStatItem(String label, String value, IconData icon) {
  return Expanded(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

### 6.3 Kartu Item Daftar Riwayat (History Item Card)
```dart
Widget buildHistoryCard({
  required String title,
  required String subtitle,
  required String trailingTime,
  required String badgeLabel,
  required Color badgeColor,
  required IconData leadingIcon,
  required Color iconBg,
  required Color iconColor,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(leadingIcon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              trailingTime,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (badgeLabel.isNotEmpty && badgeLabel != '-')
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
```

### 6.4 Status Badge / Pill
```dart
Widget buildStatusBadge(String text, {Color color = const Color(0xFF22C55E)}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );
}
```

### 6.5 Empty State Standar
```dart
Widget buildEmptyState({
  required String title,
  required String message,
  IconData icon = Icons.inbox_rounded,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 7. Prinsip UX & Panduan Best Practice

1. **Responsif & Aman dari Overlap (Safe Area & Keyboard)**:
   - Setiap layar yang memiliki input form harus dibungkus dengan `SingleChildScrollView(physics: BouncingScrollPhysics())` atau `SafeArea`.
   - Hindari nested scrolling yang kaku; gunakan `shrinkWrap: true` dengan `physics: NeverScrollableScrollPhysics()` jika meletakkan list di dalam `SingleChildScrollView`.
2. **Efisiensi Memuat Data (Pull-to-Refresh & Feedback)**:
   - Gunakan `RefreshIndicator(color: primaryColor, onRefresh: ...)` pada seluruh halaman riwayat dan dashboard.
   - Hindari memblokir seluruh halaman saat refreshing data ringan; tampilkan skeleton/shimmer atau spinner lokal agar UI tetap responsif.
3. **Format Tanggal Bahasa Indonesia**:
   - Selalu gunakan `locale: 'id_ID'` saat menggunakan `DateFormat` dan kalender.
   - Contoh format standar: `DateFormat('EEEE, dd MMM yyyy', 'id_ID')` menghasilkan `"Jumat, 30 Okt 2026"`.
4. **Target Sentuh Ergonomis (Touch Target Size)**:
   - Ukuran minimum area sentuh tombol/icon adalah **44 x 44 piksel** untuk mencegah *mis-tap* pada layar sentuh ponsel.
5. **Modern API Flutter**:
   - Gunakan `color.withValues(alpha: 0.15)` sesuai standar Flutter 3.27+ daripada fungsi lama `withOpacity(...)` untuk menjamin performa rendering yang optimal.

