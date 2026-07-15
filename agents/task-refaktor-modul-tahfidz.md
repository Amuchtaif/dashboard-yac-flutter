# TASK_FLUTTER.md

# Refactor Modul Tahfidz - Flutter Mobile

## Priority

**High**

## Type

Feature Enhancement

---

# Background

Aplikasi Flutter digunakan sebagai media operasional Pengampu Tahfidz selama kegiatan halaqah berlangsung.

Flutter **bukan** pengganti Admin Panel.

Seluruh konfigurasi akademik, laporan, snapshot semester, pengaturan target hafalan, dan administrasi tetap dikelola melalui Admin Panel.

Flutter difokuskan untuk aktivitas harian:

- Mengisi Baseline Hafalan (awal Tahun Ajaran)
- Melakukan Absensi Tahfidz
- Mencatat Setoran Harian
- Melihat Profil Santri

---

# Navigation

```text
Menu Tahfidz

├── Baseline Hafalan
├── Absensi Tahfidz
└── Profil Santri
```

---

# Screen 1

## Baseline Hafalan

### Tujuan

Digunakan hanya pada awal Tahun Ajaran untuk mengisi hasil asesmen hafalan awal seluruh santri pada halaqah.

Halaman ini hanya aktif apabila periode Baseline dibuka oleh Admin.

---

### List Baseline

Menampilkan seluruh santri pada halaqah pengampu.

Contoh:

```text
Baseline Hafalan

Tahun Ajaran
2026 / 2027

Progress

12 / 18 Santri

──────────────────

Ahmad

5 Juz

──────────────────

Ali

4.5 Juz

──────────────────

Yusuf

Belum Diisi

──────────────────

Umar

Belum Diisi
```

---

### Klik Santri

Masuk ke halaman Input Baseline.

---

# Screen 2

## Input Baseline

Field

- Total Hafalan Awal (Juz)
- Tanggal Asesmen
- Catatan

Button

```text
Simpan
```

---

### Rules

- Tidak ada Approve.
- Tidak ada Reject.
- Pengampu dapat mengubah data selama periode Baseline masih dibuka.
- Setelah status **Locked**, seluruh field menjadi Read Only.

---

# Screen 3

## Absensi Tahfidz

Flow

```text
Tahfidz

↓

Absensi Tahfidz

↓

Pilih Halaqah

↓

Pagi

Siang

Sore
```

---

### Layar Absensi

Menampilkan daftar santri.

Status

- Hadir
- Izin
- Sakit
- Alpha

Setelah absensi berhasil disimpan.

Masuk otomatis ke halaman:

```text
Catatan Setoran
```

---

# Screen 4

## Catatan Setoran

Halaman ini menjadi pusat aktivitas setelah absensi selesai.

Menampilkan seluruh setoran pada tanggal tersebut.

Contoh:

```text
29 Juni 2026

──────────────────

Ahmad

Hafalan Baru

Al-Baqarah
1 - 20

──────────────────

Ali

Murojaah

Ad-Dhuha
- An-Nas

──────────────────

Yusuf

Belum Ada Setoran
```

---

### Floating Action Button

```text
+
```

Digunakan untuk menambah setoran baru.

---

# Screen 5

## Tambah Setoran

Field

- Santri
- Jenis Setoran
- Surah Awal
- Ayat Awal
- Surah Akhir
- Ayat Akhir
- Jumlah Baris
- Nilai
- Catatan

Button

```text
Simpan
```

---

### Validation

- Semua field wajib sesuai kebutuhan backend.
- Tidak ada perhitungan progress di Flutter.

---

# Screen 6

## Detail Setoran

Menampilkan seluruh informasi setoran.

Button

- Edit
- Hapus

Sesuai permission.

---

# Screen 7

## Profil Santri

Menampilkan informasi akademik Tahfidz.

Informasi

- Nama
- NIS
- Kelas
- Halaqah
- Pengampu

Ringkasan

- Baseline Hafalan
- Target Semester
- Hafalan Baru Semester
- Total Hafalan
- Persentase Target

Riwayat

- Daftar Setoran
- Riwayat Murojaah
- Riwayat Tasmi'
- Riwayat Ujian

Seluruh data berasal dari API Backend.

---

# API Integration

Gunakan endpoint backend yang telah didefinisikan pada API Contract.

Flutter tidak melakukan perhitungan:

- Progress
- Total Hafalan
- Persentase
- Report

Semua berasal dari Backend.

---

# State Management

Mengikuti arsitektur project yang sudah ada.

Tidak menambahkan package baru.

---

# Error Handling

Handle kondisi:

- Token Expired
- Validation Error
- Timeout
- Server Error
- Offline
- Empty State

Gunakan komponen global yang telah tersedia pada project.

---

# Performance

- Gunakan pagination pada daftar setoran.
- Refresh data hanya ketika diperlukan.
- Hindari request berulang.
- Gunakan lazy loading apabila jumlah data besar.

---

# Out of Scope

Flutter **tidak mengelola**:

- Target Hafalan
- Semester Closing
- Snapshot Semester
- Report Semester
- Dashboard Analitik
- Pengaturan Tahun Ajaran
- Lock / Unlock Baseline

Seluruh fitur tersebut tetap berada pada Admin Panel.

---

# Acceptance Criteria

## Baseline

- Pengampu dapat mengisi Baseline seluruh santri pada halaqah.
- Baseline dapat diubah selama periode masih dibuka.
- Baseline menjadi Read Only setelah status Locked.

---

## Absensi

- Pengampu dapat melakukan absensi berdasarkan jadwal halaqah.
- Setelah absensi selesai, aplikasi otomatis membuka halaman Catatan Setoran.

---

## Setoran

- Daftar Setoran tampil berdasarkan tanggal dan halaqah.
- FAB digunakan untuk menambah setoran baru.
- Setoran dapat diedit dan dihapus sesuai hak akses.

---

## Profil Santri

- Menampilkan ringkasan progres Tahfidz.
- Menampilkan riwayat setoran.
- Seluruh data berasal dari Backend.

---

## Integrasi

- Seluruh endpoint Backend digunakan sesuai API Contract.
- Tidak ada business logic akademik yang dipindahkan ke Flutter.
