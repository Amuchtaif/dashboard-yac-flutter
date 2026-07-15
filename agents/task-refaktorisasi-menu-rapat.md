# Task Flutter: Integrasi API Employee Groups pada Modul Buat Rapat

## Tujuan

Melakukan integrasi API **Employee Groups** pada halaman **Buat Rapat** sehingga pengguna dapat memilih peserta rapat dengan mudah menggunakan kombinasi:

- Kelompok Karyawan (Employee Group)
- Karyawan Individual

Task ini hanya mencakup implementasi Flutter menggunakan API yang telah tersedia.

---

# Ruang Lingkup

Implementasikan integrasi API Employee Groups pada halaman **Buat Rapat**.

Halaman harus mendukung:

- Menampilkan daftar kelompok karyawan
- Menampilkan daftar karyawan individual
- Memilih kombinasi grup dan individu
- Preview peserta sebelum rapat disimpan
- Menampilkan ringkasan peserta
- Menghapus pilihan peserta

Flutter **tidak melakukan proses filtering ataupun merge data peserta**. Seluruh proses tersebut dilakukan oleh backend.

---

# Integrasi API

## 1. Daftar Employee Groups

Gunakan endpoint:

```text
GET /api/employee_groups/
```

Implementasikan:

- Pagination
- Search
- Filter berdasarkan:
  - Dynamic
  - Manual
  - Status Aktif

Gunakan parameter:

- page
- limit
- search
- type
- is_active

---

## 2. Detail Employee Group

Gunakan endpoint:

```text
GET /api/employee_groups/detail.php?id={group_id}
```

Digunakan untuk:

- Melihat informasi grup
- Menampilkan deskripsi grup
- Menampilkan tipe grup
- Menampilkan informasi rules (Dynamic)
- Menampilkan informasi anggota (Manual)

---

## 3. Preview Dynamic Group

Gunakan endpoint:

```text
POST /api/employee_groups/preview.php
```

Fungsi:

Menampilkan preview anggota sebelum grup digunakan.

Flutter hanya mengirim request.

Backend mengembalikan:

- Total Anggota
- Daftar Anggota

Flutter hanya menampilkan hasil.

---

## 4. Daftar Anggota Manual Group

Gunakan endpoint:

```text
GET /api/employee_groups/members.php?group_id={id}
```

Digunakan ketika pengguna ingin melihat isi Manual Group.

---

# Perubahan UI Pemilihan Peserta

Hilangkan konsep:

- Radio Button
- Dropdown Pemilihan Peserta

Ganti menjadi satu tombol utama:

```text
+ Tambah Peserta
```

---

# Bottom Sheet Pemilihan Peserta

Saat tombol ditekan.

Tampilkan Bottom Sheet.

Memiliki dua Tab:

## Tab Kelompok

Menampilkan daftar Employee Group.

Fitur:

- Search
- Infinite Scroll
- Refresh
- Badge Dynamic / Manual
- Jumlah Anggota (jika tersedia)

Card menampilkan:

- Nama Grup
- Deskripsi singkat
- Jenis Grup
- Status

Klik Card

↓

Tambah ke daftar peserta.

---

## Tab Karyawan

Menggunakan API pencarian karyawan yang sudah tersedia pada aplikasi.

Fitur:

- Search
- Pagination
- Multi Select

Klik Karyawan

↓

Tambah ke daftar peserta.

---

# Selected Participant

Peserta yang sudah dipilih ditampilkan dalam bentuk Chip.

Contoh:

```text
[ SDIT Ikhwan ✕ ]

[ Guru Tahfidz ✕ ]

[ Ahmad Fauzi ✕ ]
```

Chip dapat dihapus kapan saja.

---

# Ringkasan Peserta

Di bawah daftar Chip tampilkan:

```text
2 Kelompok

4 Individu

58 Total Peserta
```

Total peserta berasal dari hasil Preview API.

Flutter tidak menghitung sendiri jumlah akhir.

---

# Preview Peserta

Tambahkan tombol:

```text
Preview Peserta
```

Saat ditekan.

Flutter memanggil API Preview.

Tampilkan halaman/modal.

Informasi:

- Total Peserta
- Daftar Peserta

Setiap item menampilkan:

- Nama
- Unit
- Jabatan

Backend bertanggung jawab melakukan deduplikasi peserta.

Flutter hanya menampilkan hasil.

---

# Loading State

Seluruh request API wajib memiliki:

- Skeleton Loading
- Loading Indicator
- Disable Button ketika request berlangsung

---

# Empty State

Employee Group

```text
Belum ada kelompok karyawan.
```

Karyawan

```text
Tidak ada data karyawan.
```

Search

```text
Data tidak ditemukan.
```

---

# Error Handling

Tangani kondisi:

- Tidak ada koneksi internet
- Timeout
- Unauthorized
- Internal Server Error

Sediakan tombol Retry.

---

# Performance

Implementasikan:

- Pagination
- Infinite Scroll
- Debounce Search
- Lazy Loading

Jangan mengambil seluruh Employee Group maupun seluruh daftar karyawan dalam satu request.

---

# State Management

Integrasikan dengan state management yang telah digunakan pada aplikasi.

State harus tetap terjaga ketika:

- Membuka Bottom Sheet
- Menutup Bottom Sheet
- Melakukan Search
- Scroll Pagination
- Berpindah Tab

---

# Catatan Implementasi

- Seluruh komunikasi data menggunakan API Employee Groups yang telah tersedia.
- Jangan membuat proses filtering manual di Flutter.
- Jangan melakukan deduplikasi peserta di Flutter.
- Jangan melakukan kalkulasi jumlah peserta di Flutter.
- Seluruh business logic berada di backend.
- Flutter hanya bertugas sebagai presentation layer dan consumer API.

---

# Acceptance Criteria

- Daftar Employee Group berhasil ditampilkan menggunakan API.
- Detail Employee Group dapat ditampilkan.
- Manual Group dapat menampilkan daftar anggotanya.
- Dynamic Group dapat melakukan Preview melalui API.
- Bottom Sheet pemilihan peserta berjalan dengan baik.
- Pengguna dapat memilih kombinasi Group dan Individual.
- Daftar peserta ditampilkan dalam bentuk Chip.
- Ringkasan peserta selalu diperbarui berdasarkan hasil API.
- Seluruh loading, pagination, pencarian, dan error handling berjalan dengan baik.
- Tidak terdapat business logic filtering maupun deduplikasi peserta di sisi Flutter.
