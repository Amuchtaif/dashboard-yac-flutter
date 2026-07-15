# Task: Modul Aktivitas Siswa (Frontend Flutter)

## Tujuan

Membangun modul **Aktivitas Siswa** pada aplikasi Flutter yang digunakan oleh **Guru** dan **Musyrif/AH** untuk mencatat aktivitas pembiasaan ibadah serta kegiatan non-akademik siswa.

Modul ini **berdiri sendiri** dan **tidak terintegrasi dengan modul Tahfidz**. Seluruh data aktivitas dikelola melalui Backend API dan jenis aktivitas bersifat **dinamis** (dikelola dari Admin Panel).

---

# Scope Pekerjaan

- Integrasi menu pada Dashboard
- Halaman Daftar Aktivitas Siswa
- Halaman Tambah Aktivitas
- Halaman Detail Aktivitas
- Halaman Edit Aktivitas
- Upload Dokumentasi
- Integrasi API
- State Management
- Validasi Form
- Loading & Error Handling

---

# 1. Integrasi Menu Dashboard

Tambahkan menu baru dengan nama:

```text
Aktivitas Siswa
```

Menu ini **tidak berdiri sendiri**, tetapi ditempatkan pada dua kelompok menu di Dashboard.

## Menu Pendidikan

Tambahkan menu:

- Tahfidz
- Absensi Tahfidz
- **Aktivitas Siswa**
- Menu Pendidikan lainnya

Menu ini digunakan oleh **Guru**.

---

## Menu Kesantrian

Tambahkan menu:

- Perizinan
- Pelanggaran
- **Aktivitas Siswa**
- Menu Kesantrian lainnya

Menu ini digunakan oleh **Musyrif/AH**.

---

## Navigasi

Walaupun muncul pada dua kelompok menu, keduanya mengarah ke halaman yang sama.

Tidak membuat dua halaman yang berbeda.

Data yang ditampilkan mengikuti hak akses pengguna yang sedang login.

---

# 2. Halaman Daftar Aktivitas Siswa

Halaman utama setelah pengguna membuka menu.

## Komponen

- AppBar
- Search Bar
- Filter
- Pull To Refresh
- Floating Action Button (Tambah Aktivitas)
- Infinite Scroll List

---

## Filter

Filter berdasarkan:

- Siswa
- Jenis Aktivitas
- Rentang Tanggal

Seluruh data filter berasal dari Backend API.

---

## Card Aktivitas

Setiap card menampilkan:

- Nama Siswa
- Nama Aktivitas
- Badge Tipe (Personal / Event)
- Status
- Tanggal
- Nama Guru/Musyrif Penginput
- Jumlah Dokumentasi (jika ada)

Tap card membuka halaman Detail Aktivitas.

---

# 3. Halaman Tambah Aktivitas

Digunakan oleh Guru dan Musyrif/AH.

## Field

### Jenis Aktivitas

Dropdown.

Sumber data:

GET /api/mobile/activity-types

Hanya menampilkan aktivitas yang aktif.

---

### Pilih Siswa

Dropdown Searchable / Bottom Sheet Search.

Data berasal dari:

GET /api/mobile/students

Hanya menampilkan siswa sesuai hak akses pengguna.

---

### Tanggal

Date Picker.

Default:

Hari ini.

---

### Jam Mulai

Time Picker.

Opsional.

---

### Jam Selesai

Time Picker.

Opsional.

---

### Status

Dropdown.

Pilihan:

- Dilaksanakan
- Tidak Dilaksanakan
- Berhalangan

---

### Catatan

Text Area.

Opsional.

---

### Dokumentasi

Upload:

- Kamera
- Galeri
- PDF (jika didukung backend)

Support Multiple Upload.

Preview sebelum upload.

Bisa menghapus file sebelum disimpan.

---

## Tombol

Simpan

Ketika berhasil:

- Snackbar sukses.
- Kembali ke halaman daftar.
- Data otomatis diperbarui.

---

# 4. Fitur Input Cepat (Quick Checklist)

Selain form standar, sediakan mode **Input Cepat** untuk aktivitas yang bersifat rutin.

Alur:

1. Pilih Jenis Aktivitas.
2. Pilih Tanggal.
3. Sistem menampilkan daftar siswa sesuai hak akses.
4. Guru/Musyrif cukup mencentang siswa yang melaksanakan aktivitas.
5. Tekan tombol **Simpan**.

Backend akan menerima data dalam bentuk batch sehingga proses input jauh lebih cepat dibanding menginput satu per satu.

Fitur ini sangat direkomendasikan untuk aktivitas seperti:

- Shalat Dhuha
- Puasa Sunnah
- Dzikir Pagi
- Dzikir Petang
- Sedekah
- Aktivitas rutin lainnya

---

# 5. Halaman Detail Aktivitas

Menampilkan informasi lengkap aktivitas.

Informasi:

- Nama Siswa
- Jenis Aktivitas
- Tipe Aktivitas
- Status
- Tanggal
- Jam
- Catatan
- Nama Penginput
- Dokumentasi

Dokumentasi dapat dibuka dalam mode preview.

---

# 6. Halaman Edit Aktivitas

Guru/Musyrif dapat mengubah aktivitas yang pernah dibuatnya.

Field sama seperti halaman Tambah.

Support:

- Mengubah aktivitas
- Mengubah status
- Mengubah catatan
- Menambah dokumentasi
- Menghapus dokumentasi

---

# 7. Hapus Aktivitas

Saat tombol Hapus dipilih:

- Tampilkan dialog konfirmasi.
- Setelah berhasil:
  - Snackbar sukses.
  - Refresh data otomatis.

---

# 8. Integrasi Backend API

## Jenis Aktivitas

GET

/api/mobile/activity-types

---

## Daftar Siswa

GET

/api/mobile/students

---

## Daftar Aktivitas

GET

/api/mobile/student-activities

Support:

- Pagination
- Search
- Filter

---

## Detail Aktivitas

GET

/api/mobile/student-activities/{id}

---

## Tambah Aktivitas

POST

/api/mobile/student-activities

---

## Batch Input (Quick Checklist)

POST

/api/mobile/student-activities/batch

Mengirim banyak data aktivitas dalam satu request.

---

## Edit Aktivitas

PUT

/api/mobile/student-activities/{id}

---

## Hapus Aktivitas

DELETE

/api/mobile/student-activities/{id}

---

## Upload Dokumentasi

POST

/api/mobile/student-activities/{id}/attachments

---

## Hapus Dokumentasi

DELETE

/api/mobile/student-activities/{id}/attachments/{attachmentId}

---

# 9. State Management

Gunakan arsitektur project yang sudah ada.

Pisahkan:

- Model
- API Service
- Repository
- Controller / State
- Screen
- Widget Reusable

Jangan menempatkan logika API langsung pada UI.

---

# 10. Validasi

Sebelum menyimpan data:

- Jenis Aktivitas wajib dipilih.
- Siswa wajib dipilih.
- Tanggal wajib diisi.
- Status wajib dipilih.

Tampilkan pesan validasi yang jelas apabila terdapat data yang belum lengkap.

---

# 11. Loading & Error Handling

Implementasikan:

- Skeleton Loading
- Pull To Refresh
- Infinite Scroll
- Empty State
- Retry Request
- Snackbar Error
- Dialog Error ketika diperlukan

---

# 12. User Experience

- Mengikuti Design System aplikasi.
- Responsive pada seluruh ukuran layar.
- Dropdown menggunakan Searchable Bottom Sheet apabila data banyak.
- Navigasi konsisten dengan modul lain.
- Mendukung Dark Mode apabila aplikasi telah mendukungnya.
- Proses input dibuat seminimal mungkin agar Guru dan Musyrif/AH dapat mencatat aktivitas dengan cepat.

---

# Hak Akses

## Guru

- Melihat daftar siswa yang menjadi tanggung jawabnya.
- Menambah aktivitas siswa.
- Mengedit aktivitas yang dibuat sendiri.
- Menghapus aktivitas yang dibuat sendiri.
- Upload dokumentasi.
- Melihat riwayat aktivitas siswa.

---

## Musyrif / AH

- Melihat daftar siswa yang menjadi tanggung jawabnya.
- Menambah aktivitas siswa.
- Mengedit aktivitas yang dibuat sendiri.
- Menghapus aktivitas yang dibuat sendiri.
- Upload dokumentasi.
- Melihat riwayat aktivitas siswa.

---

# Acceptance Criteria

- Menu **Aktivitas Siswa** tersedia pada kelompok **Menu Pendidikan** dan **Menu Kesantrian** di Dashboard.
- Kedua menu mengarah ke halaman Aktivitas Siswa yang sama.
- Guru dan Musyrif/AH hanya melihat siswa sesuai hak akses masing-masing.
- Jenis aktivitas diambil dari Backend API dan bersifat dinamis.
- Guru dan Musyrif/AH dapat melakukan CRUD aktivitas melalui aplikasi Flutter.
- Mendukung fitur **Input Cepat (Quick Checklist)** untuk pencatatan aktivitas rutin secara batch.
- Mendukung upload dan penghapusan dokumentasi.
- Seluruh halaman telah terintegrasi dengan Backend API.
- Seluruh halaman menerapkan loading, pagination, pencarian, filter, pull-to-refresh, empty state, dan error handling.
- Struktur kode mengikuti arsitektur project sehingga mudah dipelihara dan dikembangkan.
