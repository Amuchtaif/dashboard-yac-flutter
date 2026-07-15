# Task Frontend Flutter - Dashboard Tahfidz Bertingkat

## Tujuan

Mengembangkan Dashboard Tahfidz pada aplikasi Flutter sebagai pusat monitoring tahfidz untuk role **Kepala Pondok, Mudir, Kamad, dan Kanit Tahfidz**.

Dashboard digunakan untuk memonitor seluruh aktivitas tahfidz secara **live update** berdasarkan data dari Backend API tanpa melakukan input data.

---

# Ruang Lingkup

Dashboard hanya bersifat monitoring.

Seluruh data berasal dari API Dashboard Tahfidz.

Tidak ada fitur:

- Input data
- Edit data
- Hapus data
- Approval
- Push Notification

Dashboard harus melakukan pembaruan data secara otomatis (auto refresh/live update) tanpa perlu refresh manual.

---

# Role dan Hak Akses

## Kepala Pondok

Menampilkan seluruh data:

- MTs
- MA
- Seluruh Halaqoh
- Seluruh Pengampu
- Seluruh Santri

---

## Mudir

Menampilkan seluruh Unit Pendidikan:

- MTs
- MA

---

## Kamad

Menampilkan seluruh data pada unit yang dipimpin.

Contoh:

- Kamad MTs hanya melihat MTs
- Kamad MA hanya melihat MA

---

## Kanit Tahfidz

Menampilkan seluruh halaqoh dalam unitnya.

---

# Struktur Halaman

## Dashboard Tahfidz

Halaman utama terdiri dari beberapa section yang dapat discroll secara vertikal.

---

# Widget Executive Summary

Menampilkan KPI Card:

- Total Santri
- Total Pengampu
- Total Halaqoh
- Kehadiran Santri Hari Ini
- Kehadiran Pengampu Hari Ini
- Total Setoran Hari Ini
- Total Murajaah Hari Ini
- Hafalan Baru Hari Ini
- Santri Belum Setor
- Halaqoh Belum Mengisi Aktivitas

Setiap card dapat ditekan untuk membuka halaman detail.

---

# Widget Dashboard Kehadiran

Menampilkan statistik:

## Santri

- Hadir
- Izin
- Sakit
- Alfa

## Pengampu

- Hadir
- Izin
- Tidak Hadir
- Belum Absen

Dilengkapi progress indicator persentase kehadiran.

---

# Widget Live Activity

Menampilkan aktivitas terbaru secara kronologis.

Contoh aktivitas:

- Pengampu mengisi absensi
- Santri setor hafalan
- Santri murajaah
- Pengampu menambahkan evaluasi

Daftar aktivitas diperbarui otomatis.

---

# Widget Progress Hafalan

Menampilkan:

- Total Hafalan
- Target Semester
- Target Tahunan
- Persentase Ketercapaian

Menggunakan progress bar dan chart.

---

# Widget Distribusi Hafalan

Menampilkan chart distribusi:

- Belum 1 Juz
- 1–5 Juz
- 6–10 Juz
- 11–20 Juz
- 21–29 Juz
- 30 Juz

---

# Widget Monitoring Halaqoh

Menampilkan daftar:

- Nama Halaqoh
- Pengampu
- Jumlah Santri
- Kehadiran
- Setoran
- Murajaah
- Progress Hafalan

Klik item membuka Detail Halaqoh.

---

# Halaman Detail Halaqoh

Menampilkan:

- Informasi Halaqoh
- Pengampu
- Jumlah Santri
- Daftar Santri
- Kehadiran Hari Ini
- Setoran Hari Ini
- Murajaah Hari Ini
- Grafik Progress Hafalan
- Riwayat Aktivitas

---

# Widget Monitoring Pengampu

Menampilkan:

- Nama Pengampu
- Halaqoh
- Kehadiran
- Jumlah Setoran
- Jumlah Murajaah
- Evaluasi

Klik membuka Detail Pengampu.

---

# Halaman Detail Pengampu

Menampilkan:

- Profil Pengampu
- Halaqoh
- Statistik Pengampu
- Riwayat Aktivitas

---

# Widget Monitoring Santri

Menampilkan daftar:

- Nama
- Kelas
- Halaqoh
- Pengampu
- Hafalan Terakhir
- Hari Terakhir Setor
- Kehadiran
- Progress Hafalan

Dilengkapi fitur pencarian.

Klik membuka Detail Santri.

---

# Halaman Detail Santri

Menampilkan:

- Profil Santri
- Hafalan Terakhir
- Riwayat Setoran
- Riwayat Murajaah
- Grafik Progress Hafalan
- Riwayat Kehadiran

---

# Widget Santri Perlu Perhatian

Menampilkan otomatis:

- Tidak setor > 3 hari
- Kehadiran rendah
- Alfa berturut-turut
- Progress stagnan
- Murajaah rendah
- Target semester belum tercapai

Klik membuka Detail Santri.

---

# Widget Statistik Historis

Filter:

- Hari
- Minggu
- Bulan
- Semester
- Tahun Ajaran

Grafik berubah mengikuti filter.

---

# Widget Executive Insight

Menampilkan ringkasan otomatis dari backend.

Contoh:

- Persentase kehadiran
- Jumlah setoran
- Jumlah murajaah
- Unit terbaik
- Halaqoh terbaik
- Halaqoh memerlukan perhatian
- Santri belum setor

---

# Widget Perbandingan Unit

(Khusus Kepala Pondok dan Mudir)

Menampilkan perbandingan:

- MTs
- MA

Indikator:

- Jumlah Santri
- Jumlah Pengampu
- Kehadiran
- Progress Hafalan

---

# Widget Ranking

Menampilkan:

## Ranking Unit

## Ranking Halaqoh

## Ranking Pengampu

Klik item membuka halaman detail.

---

# Widget Health Score

(Khusus Kepala Pondok)

Menampilkan skor setiap unit berdasarkan data dari backend.

---

# Filter Global

Sediakan panel filter yang memengaruhi seluruh widget.

Filter:

- Unit
- Jenjang
- Kelas
- Halaqoh
- Pengampu
- Semester
- Tahun Ajaran
- Rentang Tanggal

Seluruh widget melakukan reload ketika filter berubah.

---

# Drill Down

Dashboard harus mendukung navigasi bertingkat.

Dashboard

↓

Unit

↓

Kelas

↓

Halaqoh

↓

Pengampu

↓

Santri

↓

Riwayat Hafalan

---

# Live Update

Dashboard harus memperbarui data secara otomatis.

Tidak menggunakan:

- Push Notification
- Popup
- Badge Notification

Gunakan mekanisme:

- WebSocket / SSE apabila tersedia.
- Auto Refresh berkala sebagai fallback.

---

# UI/UX

- Menggunakan Material Design 3.
- Responsif untuk tablet dan smartphone.
- KPI menggunakan Card.
- Chart mudah dibaca.
- Mendukung Dark Mode.
- Skeleton Loading pada seluruh widget.
- Empty State ketika data kosong.
- Error State ketika API gagal.
- Pull to Refresh pada halaman dashboard.
- Animasi ringan saat data berubah.

---

# Arsitektur Frontend

Pisahkan berdasarkan layer:

- Presentation
- State Management
- Repository
- API Service

Gunakan state management yang telah menjadi standar proyek.

Seluruh data dashboard berasal dari Repository dan tidak boleh mengakses API secara langsung dari Widget.

---

# Acceptance Criteria

- Dashboard menyesuaikan hak akses pengguna yang login.
- Seluruh widget berhasil mengambil data dari Backend API.
- Dashboard mendukung filter global.
- Seluruh KPI dapat di-drill-down hingga level santri.
- Live update berjalan tanpa refresh manual.
- Terdapat loading, empty state, dan error state pada seluruh widget.
- Performa tetap responsif meskipun menampilkan data dalam jumlah besar.
- UI konsisten dengan desain aplikasi YAC dan mendukung penggunaan pada smartphone maupun tablet.
