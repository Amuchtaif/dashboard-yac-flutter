# 📱 Dashboard YAC — Dokumentasi Fitur Aplikasi

> **Versi:** 1.0.0  
> **Platform:** Flutter (Android)  
> **Backend:** PHP + MySQL (XAMPP)  
> **Push Notification:** Firebase Cloud Messaging  
> **Terakhir diperbarui:** 14 Februari 2026

---

## 📋 Daftar Isi

1. [Arsitektur Aplikasi](#-arsitektur-aplikasi)
2. [Autentikasi & Sesi](#-autentikasi--sesi)
3. [Dashboard & Navigasi](#-dashboard--navigasi)
4. [Modul Absensi Karyawan](#-modul-absensi-karyawan)
5. [Modul Tahfidz](#-modul-tahfidz)
6. [Modul Izin Kerja](#-modul-izin-kerja)
7. [Modul Rapat & Pertemuan](#-modul-rapat--pertemuan)
8. [Modul Inventaris Barang](#-modul-inventaris-barang)
9. [Modul Penggajian](#-modul-penggajian)
10. [Fitur Islami](#-fitur-islami)
11. [Notifikasi](#-notifikasi)
12. [Profil Pengguna](#-profil-pengguna)
13. [Sistem Hak Akses](#-sistem-hak-akses)
14. [Struktur Folder](#-struktur-folder)

---

## 🏗 Arsitektur Aplikasi

### Tech Stack
| Komponen     | Teknologi                            |
| ------------ | ------------------------------------ |
| Frontend     | Flutter (Dart), Material Design 3    |
| Backend API  | PHP (REST API)                       |
| Database     | MySQL (via MySQLi)                   |
| Auth         | Session-based (SharedPreferences)    |
| Push Notif   | Firebase Cloud Messaging (FCM)       |
| Font         | Google Fonts (Poppins)               |
| State Mgmt   | Provider + setState                  |

### Arsitektur Frontend
```
lib/
├── main.dart              # Entry point, Firebase init, session check
├── config/
│   └── api_config.dart    # Base URL konfigurasi API
├── models/                # Data models (User, Meeting, Surah, dll.)
├── services/              # API service layer (HTTP calls)
├── providers/             # State management (Provider)
├── screens/               # UI screens
├── utils/                 # Utilitas (AccessControl)
└── widgets/               # Widget reusable
```

---

## 🔐 Autentikasi & Sesi

### Login
- **Screen:** `login_screen.dart`
- **API:** `login.php`
- Login menggunakan **username & password**
- Session disimpan di `SharedPreferences` dengan timestamp
- **Durasi sesi:** 24 jam (sliding expiration — diperpanjang setiap kali aktif)
- Sesi expired → otomatis redirect ke halaman login

### Profil
- **Screen:** `profile_screen.dart`
- **API:** `profile.php`
- Menampilkan: Nama, Unit, Divisi, Jabatan, Role
- Fitur logout dengan clear session

---

## 🏠 Dashboard & Navigasi

### Bottom Navigation (4 Tab)
| Tab       | Ikon                     | Deskripsi                              |
| --------- | ------------------------ | -------------------------------------- |
| Beranda   | `home_rounded`           | Dashboard utama dengan menu & status   |
| Berita    | `menu_book_rounded`      | Halaman berita (placeholder)           |
| Kinerja   | `access_time_filled`     | Halaman kinerja (placeholder)          |
| Profil    | `person_rounded`         | Profil pengguna & pengaturan           |

### Halaman Beranda (`HomeTab`)
- **Header** — Nama pengguna, unit, jabatan, tombol notifikasi
- **Status Card** — Status kehadiran hari ini (Hadir/Belum hadir), jam masuk & pulang, jadwal shift
- **Menu Islami** — Al Quran, Dzikir & Do'a, Arah Kiblat, TV Sunnah
- **Menu Umum** — Izin Kerja, Rapat Pertemuan, Inventaris Barang, Penggajian
- **Menu Tahfidz** (conditional) — Muncul hanya jika user punya akses `can_access_tahfidz`
- **Aktivitas Terbaru** — List 5 aktivitas terakhir (absensi, izin, rapat)

---

## ⏰ Modul Absensi Karyawan

### Fitur
- **Check-in & Check-out** berbasis lokasi GPS
- Validasi jarak dari lokasi kantor
- Menampilkan waktu masuk & pulang di dashboard
- Informasi jadwal shift hari ini

### File Terkait
| Komponen   | File                                |
| ---------- | ----------------------------------- |
| Service    | `attendance_service.dart`           |
| API        | `attendance.php`                    |
| Dashboard  | `get_dashboard_data.php`            |

---

## 📖 Modul Tahfidz

Modul ini memiliki **2 role utama** dengan tampilan yang berbeda:

### Role: Pengampu (Guru Tahfidz)
| Menu              | Deskripsi                                   |
| ----------------- | ------------------------------------------- |
| Absensi Tahfidz   | Buka halaqoh (Pagi/Siang/Sore), absensi santri |
| Penilaian         | Input penilaian santri                      |
| Setoran           | Input hafalan baru santri                   |

### Role: Koordinator Tahfidz
| Menu              | Deskripsi                                   |
| ----------------- | ------------------------------------------- |
| Absensi Tahfidz   | Monitoring absensi santri + filter halaqoh/sesi |
| Absensi Pengampu  | Monitoring & approval kehadiran pengampu    |
| Setoran           | Pantau hafalan baru santri                  |
| Penilaian         | Pantau penilaian santri                     |

---

### 1. Absensi Tahfidz (`absensi_tahfidz_screen.dart`)

#### View Pengampu
- **Buka Halaqoh** — Pilih jadwal (Pagi/Siang/Sore), submit check-in dengan waktu real-time
- **Absensi Santri** — Setelah halaqoh dibuka, tampil list santri untuk diabsen (Hadir/Sakit/Izin/Alpha)
- **Check-out** — Tutup halaqoh dan submit absensi santri
- **Search** — Pencarian nama santri

#### View Koordinator
- **Navigasi Tanggal** — Tombol maju/mundur per hari + date picker
- **Filter Kelompok Halaqoh** — Dropdown semua kelompok halaqoh
- **Filter Sesi** — Dropdown Pagi/Siang/Sore
- **Badge Statistik** — Icon + jumlah untuk: Total, Hadir, Sakit, Izin, Alpha
- **List Card Santri** — Nama, kelas, tingkat, sesi, status kehadiran

#### API Terkait
| API File                        | Fungsi                              |
| ------------------------------- | ----------------------------------- |
| `get_student_attendance.php`    | Ambil data absensi santri (filter: date, session, group_id) |
| `get_halaqah_groups.php`        | Ambil daftar kelompok halaqoh       |
| `submit_tahfidz_record.php`     | Submit record absensi               |

---

### 2. Absensi Pengampu (`absensi_pengampu_screen.dart`)

Layar ini memiliki **2 tab**:

#### Tab 1: Kehadiran
- **Navigasi Tanggal** — Maju/mundur + date picker
- **Badge Statistik** — Total, Terverifikasi, Pending, Check-out
- **List Card Pengampu** — Menampilkan:
  - Nama pengampu + avatar inisial
  - Badge halaqoh (Pagi/Siang/Sore)
  - Status aktif/selesai (berdasarkan check-out)
  - Status verifikasi (Terverifikasi ✅ / Pending ⏳ / Ditolak ❌)
  - Waktu check-in & check-out

#### Tab 2: Approval
- **Badge counter** pending di tab
- **Kartu verifikasi** — Detail pengampu, halaqoh, waktu check-in
- **Tombol Aksi** — Tolak / Verifikasi
- **Optimistic UI** — Update langsung sebelum respons server

#### API Terkait
| API File                          | Fungsi                          |
| --------------------------------- | ------------------------------- |
| `get_teacher_attendance.php`      | Ambil riwayat kehadiran pengampu |
| `verify_teacher_attendance.php`   | Approve/reject kehadiran        |
| `get_pending_approvals.php`       | Ambil list approval pending     |
| `approve_attendance.php`          | Approve kehadiran               |

---

### 3. Setoran Tahfidz (`setoran_tahfidz_screen.dart`)

#### View Pengampu
- **Pilih Santri** — Search & select dari daftar santri
- **Pilih Surah** — Picker surah Al-Quran
- **Input Detail** — Ayat awal/akhir, jumlah baris, kualitas (Lancar/Kurang Lancar/Tidak Lancar)
- **Submit Setoran** — Kirim data hafalan ke server

#### View Koordinator
- **Navigasi Tanggal** — Filter per hari
- **List Record Card** — Nama santri, surah, ayat, kualitas, pengampu, tanggal

#### API Terkait
| API File                     | Fungsi                    |
| ---------------------------- | ------------------------- |
| `submit_memorization.php`    | Submit setoran hafalan    |
| `get_memorization.php`       | Ambil data setoran        |
| `get_my_students.php`        | Ambil santri per pengampu |

---

### 4. Penilaian Tahfidz (`penilaian_tahfidz_screen.dart`)

#### View Pengampu
- **Pilih Santri** — Dropdown dari daftar santri
- **Pilih Kategori** — Kategori penilaian
- **Pilih Tanggal** — Date picker
- **Input Skor** — Field input untuk nilai
- **Submit Penilaian** — Kirim ke server

#### View Koordinator
- **Navigasi Tanggal** — Filter per hari
- **List Assessment Card** — Nama santri, kategori, skor, chip skor per aspek

#### API Terkait
| API File                  | Fungsi                    |
| ------------------------- | ------------------------- |
| `submit_assessment.php`   | Submit penilaian          |
| `get_assessments.php`     | Ambil data penilaian      |

---

### Manajemen Halaqoh

| Tabel DB             | Kolom Utama                           |
| -------------------- | ------------------------------------- |
| `halaqah_groups`     | id, group_name, teacher_id            |
| `halaqah_members`    | id, group_id, student_id             |
| `tahfidz_attendance` | id, student_id, date, status, session, teacher_id |
| `tahfidz_teacher_attendance` | id, teacher_id, date, check_in_time, check_out_time, notes, status, is_verified, status_approval |

---

## 📝 Modul Izin Kerja

### Screen: `main_permit_screen.dart`

#### Tab 1: Izin Saya (`MyPermitsTab`)
- **List Izin** — Daftar pengajuan izin pribadi
- **Status** — Pending, Approved, Rejected dengan warna berbeda
- **Detail** — Tipe izin, tanggal mulai/akhir, keterangan
- **Form Pengajuan** — Buat pengajuan izin baru (`permit_screen.dart`)

#### Tab 2: Persetujuan (`ApprovalsTab`) — Khusus Atasan
- **List Approval** — Daftar izin bawahan yang perlu disetujui
- **Aksi** — Approve / Reject pengajuan
- Hanya muncul untuk user level tertentu (atasan)

### API Terkait
| API File              | Fungsi                              |
| --------------------- | ----------------------------------- |
| `submit_permit.php`   | Submit pengajuan izin               |
| `get_my_permits.php`  | Ambil izin pribadi                  |
| `get_permits.php`     | Ambil semua izin (admin)            |
| `get_approval_list.php` | Ambil list approval untuk atasan |
| `action_permit.php`   | Approve/reject izin                 |

---

## 🤝 Modul Rapat & Pertemuan

### Fitur
- **List Rapat** (`meeting_list_screen.dart`) — Tab: Semua, Mendatang, Selesai
- **Buat Rapat** (`create_meeting_screen.dart`) — Form lengkap:
  - Judul, deskripsi, tipe (Internal/External)
  - Tanggal, waktu mulai & selesai
  - Mode (Online/Offline/Hybrid)
  - Pilih peserta (multi-select dari daftar staff atau per divisi)
- **Detail Rapat** (`meeting_detail_screen.dart`) — Informasi lengkap + daftar peserta
- **Absensi Rapat** — QR Code scanner atau upload foto QR (`scan_qr_screen.dart`)
- **Permission Guard** — Hanya user dengan `can_create_meeting` yang bisa buat rapat

### API Terkait
| API File                          | Fungsi                           |
| --------------------------------- | -------------------------------- |
| `create_meeting.php`              | Buat rapat baru                  |
| `get_meetings.php`                | Ambil daftar rapat               |
| `submit_meeting_attendance.php`   | Submit absensi rapat via QR      |
| `get_staff.php`                   | Ambil daftar staff               |
| `get_divisions.php`               | Ambil daftar divisi              |
| `get_staff_by_division.php`       | Staff per divisi                 |

---

## 📦 Modul Inventaris Barang

### Screen
- **Kategori Inventaris** (`inventory_category_screen.dart`) — Grid kategori barang dengan search
- **List Inventaris** (`inventory_list_screen.dart`) — Daftar barang per kategori

---

## 💰 Modul Penggajian

### Screen: `payroll_history_screen.dart`
- **Summary Card** — Total gaji, potongan, tunjangan
- **Riwayat Gaji** — List slip gaji per bulan
- **Detail Slip** — Komponen gaji (gaji pokok, tunjangan, potongan)

---

## 🕌 Fitur Islami

### 1. Al-Quran (`quran_list_screen.dart` + `quran_detail_screen.dart`)
- **Daftar Surah** — 114 surah lengkap
- **Detail Surah** — Baca ayat per surah
- **Service:** `quran_service.dart`

### 2. Dzikir & Do'a (`dzikir_doa_screen.dart` + `dzikir_detail_screen.dart`)
- **Daftar Dzikir** — Koleksi dzikir & do'a harian
- **Detail Dzikir** — Bacaan Arab, latin, terjemahan
- **Service:** `dzikir_service.dart`

### 3. Arah Kiblat (`qibla_screen.dart`)
- **Kompas Kiblat** — Arah kiblat real-time menggunakan sensor kompas
- **GPS** — Kalkulasi arah berdasarkan koordinat pengguna
- **UI** — Custom compass dial painter

### 4. TV Sunnah (`assunnah_tv_screen.dart`)
- **Video Islami** — Streaming video dari YouTube channel As-Sunnah
- **Player** — Built-in YouTube player
- **Service:** `youtube_service.dart`

---

## 🔔 Notifikasi

### Fitur
- **Firebase Cloud Messaging** — Push notification real-time
- **Background Handler** — Notifikasi tetap diterima saat app di background
- **Local Notification** — Channel "High Importance" dengan suara
- **Notification Sheet** — Bottom sheet di dashboard untuk melihat notifikasi
- **FCM Token** — Auto-update token ke server
- **Deep Link** — Tap notifikasi → navigasi ke halaman terkait

### File Terkait
| Komponen        | File                            |
| --------------- | ------------------------------- |
| Service         | `notification_service.dart`     |
| API             | `get_notifications.php`         |
| FCM Token       | `update_fcm_token.php`          |

---

## 👤 Profil Pengguna

### Screen: `profile_screen.dart`
- **Info Pengguna** — Nama, unit, divisi, jabatan
- **Display Position** — Fallback ke level-based position jika positionName kosong
- **Display Role** — Tampilkan role pengguna
- **Pengaturan** — Section toggle untuk fitur tertentu
- **Logout** — Clear session & kembali ke login

---

## 🔒 Sistem Hak Akses

### Mekanisme
1. **Permission API** (`get_user_permissions.php`) → Ambil daftar permission user saat login
2. **SharedPreferences** → Simpan permission di cache lokal
3. **AccessControl** (`access_control.dart`) → Helper class `AccessControl.can('permission_name')` → `bool`
4. **PermissionService** (`permission_service.dart`) → Load & manage permissions

### Permission yang Digunakan
| Permission Key        | Fungsi                               |
| --------------------- | ------------------------------------ |
| `can_access_tahfidz`  | Menampilkan menu Tahfidz di dashboard |
| `is_koordinator`      | Role koordinator di modul Tahfidz     |
| `can_create_meeting`  | Bisa membuat rapat pertemuan          |

### Hybrid Permission
- **Cek user override** → Tabel `user_permissions`
- **Fallback ke role** → Tabel `positions` (default permission per jabatan)
- **Helper:** `check_permission.php`

---

## 📁 Struktur Folder

### Frontend (Flutter)
```
lib/
├── config/
│   └── api_config.dart
├── core/
├── models/
│   ├── attendance_model.dart
│   ├── dzikir_model.dart
│   ├── meeting_model.dart
│   ├── notification_model.dart
│   ├── staff_model.dart
│   ├── surah_model.dart
│   ├── user_model.dart
│   └── video_model.dart
├── providers/
│   └── tahfidz_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── profile_screen.dart
│   ├── main_permit_screen.dart
│   ├── permit_screen.dart
│   ├── permit_list_screen.dart
│   ├── create_meeting_screen.dart
│   ├── meeting_list_screen.dart
│   ├── meeting_detail_screen.dart
│   ├── inventory_category_screen.dart
│   ├── inventory_list_screen.dart
│   ├── payroll_history_screen.dart
│   ├── quran_list_screen.dart
│   ├── quran_detail_screen.dart
│   ├── dzikir_doa_screen.dart
│   ├── dzikir_detail_screen.dart
│   ├── qibla_screen.dart
│   ├── assunnah_tv_screen.dart
│   ├── scan/
│   │   └── scan_qr_screen.dart
│   └── tahfidz/
│       ├── absensi_tahfidz_screen.dart
│       ├── absensi_pengampu_screen.dart
│       ├── setoran_tahfidz_screen.dart
│       └── penilaian_tahfidz_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── attendance_service.dart
│   ├── tahfidz_service.dart
│   ├── permission_service.dart
│   ├── notification_service.dart
│   ├── quran_service.dart
│   ├── dzikir_service.dart
│   └── youtube_service.dart
├── utils/
│   └── access_control.dart
└── widgets/
```

### Backend (PHP API)
```
api/
├── login.php
├── profile.php
├── attendance.php
├── get_dashboard_data.php
├── get_user_permissions.php
├── submit_permit.php
├── get_my_permits.php
├── action_permit.php
├── create_meeting.php
├── get_meetings.php
├── submit_meeting_attendance.php
├── get_employees.php
├── get_staff.php
├── get_divisions.php
├── get_notifications.php
├── update_fcm_token.php
└── tahfidz/
    ├── get_student_attendance.php
    ├── get_teacher_attendance.php
    ├── get_halaqah_groups.php
    ├── get_my_students.php
    ├── get_memorization.php
    ├── get_assessments.php
    ├── submit_tahfidz_record.php
    ├── submit_memorization.php
    ├── submit_assessment.php
    ├── verify_teacher_attendance.php
    ├── approve_attendance.php
    ├── get_pending_approvals.php
    └── setup_halaqah.php
```

---

## 📊 Ringkasan Fitur

| No | Modul              | Status    | Deskripsi Singkat                                      |
| -- | ------------------ | --------- | ------------------------------------------------------ |
| 1  | Login & Auth       | ✅ Aktif  | Login, session 24 jam, auto-expire                     |
| 2  | Dashboard          | ✅ Aktif  | Bottom nav, status kehadiran, menu grid                |
| 3  | Absensi Karyawan   | ✅ Aktif  | GPS-based check-in/out                                 |
| 4  | Tahfidz            | ✅ Aktif  | Absensi santri, setoran hafalan, penilaian, monitoring |
| 5  | Izin Kerja         | ✅ Aktif  | Pengajuan & approval izin                              |
| 6  | Rapat              | ✅ Aktif  | CRUD rapat, absensi QR, multi-select peserta           |
| 7  | Inventaris         | ✅ Aktif  | Kategori & list barang inventaris                      |
| 8  | Penggajian         | ✅ Aktif  | Riwayat slip gaji                                      |
| 9  | Al-Quran           | ✅ Aktif  | Baca 114 surah                                         |
| 10 | Dzikir & Do'a      | ✅ Aktif  | Koleksi dzikir harian                                  |
| 11 | Arah Kiblat        | ✅ Aktif  | Kompas kiblat real-time                                |
| 12 | TV Sunnah          | ✅ Aktif  | Streaming video islami                                 |
| 13 | Notifikasi         | ✅ Aktif  | Push notification FCM                                  |
| 14 | Hak Akses          | ✅ Aktif  | Hybrid permission (user override + role default)       |

---

*Dokumen ini di-generate otomatis berdasarkan analisis source code pada 14 Februari 2026.*
