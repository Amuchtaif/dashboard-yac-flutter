# SYSTEM_MAP.md - Dashboard YAC

Dokumentasi navigasi utama sistem untuk proyek **Dashboard YAC (Yayasan Assunnah Cirebon)**.

## # Project Summary
- **Tujuan**: Aplikasi dashboard internal untuk manajemen operasional yayasan pendidikan, mencakup kehadiran staf, jurnal pengajaran, rekapan tahfidz, inventaris, dan publikasi berita/konten edukasi.
- **Tech Stack**:
  - **Runtime**: Dart 3.x (Flutter SDK ^3.7.2)
  - **Framework**: Flutter (Mobile/Multiplatform)
  - **State Management**: `Provider` (Tahfidz, Quran)
  - **Data Access**: `http` (REST API), `shared_preferences` (Session), `flutter_secure_storage`.
  - **Integrasi**: Firebase Cloud Messaging (Notifikasi), Google Maps (Geolocator), YouTube (Video Player).
- **Pola Arsitektur**: Layer-based architecture (UI Screens -> State Providers -> Business Services -> Config/Constants).

## # Core Logic Flow (Critical)
### 1. Autentikasi & Sesi
`LoginScreen` -> `AuthService[login]` -> `ApiConstants[loginEndpoint]` -> `SharedPreferences` (Save User & Token) -> `PermissionService[fetchPermissions]` -> `DashboardScreen`.

### 2. Beranda & Distribusi Fitur
`DashboardScreen` -> `PermissionService[loadFromCache]` -> `UI Conditional Rendering` (Menampilkan menu berdasarkan level jabatan/ijin) -> Feature Page (e.g., Attendance, News).

### 3. Alur Data (Tahfidz Example)
`TahfidzScreen` -> `TahfidzProvider[fetchStudents]` -> `TahfidzService[getMyStudents]` -> `ApiConstants[tahfidzGetMyStudents]` -> `TahfidzModel[fromJson]` -> `UI Update`.

## # Clean Tree (Source Code)
```text
lib/
├── config/             # Konfigurasi dasar (Base URL)
├── core/               # Konstanta API & Global constants
├── models/             # Data structure/Entity (User, News, Tahfidz, etc.)
├── providers/          # State management (ChangeNotifier)
├── screens/            # UI Pages (Dashboard, Login, Feature screens)
│   ├── kabid/         # Fitur khusus Kepala Bidang
│   ├── kesantrian/    # Manajemen santri
│   ├── scan/          # Fitur scan QR/Presence
│   └── tahfidz/       # Fitur khusus Tahfidz
├── services/           # Logika bisnis & Integrasi API
├── utils/              # Helper functions (Formatters, Validators)
└── widgets/            # Reusable UI component (Cards, Loaders)
```

## # Module Map (The Chapters)
| Path | Fungsi Utama | Deskripsi Peran |
| :--- | :--- | :--- |
| `lib/main.dart` | `main()`, `MyApp` | Entrypoint: Inisialisasi Firebase & Check sesi validitas (48 jam). |
| `lib/config/api_config.dart` | `ApiConfig` | Konfigurasi global URL API. |
| `lib/core/api_constants.dart` | `ApiConstants` | Mapping seluruh endpoint REST API. |
| `lib/services/auth_service.dart` | `login()`, `logout()` | Manajemen kredensial & penyimpanan session. |
| `lib/services/permission_service.dart` | `fetchPermissions()` | Mengatur akses fitur berdasarkan role pengguna (RBAC). |
| `lib/screens/dashboard_screen.dart` | `DashboardScreen` | Hub utama aplikasi dengan grid menu dinamis. |
| `lib/providers/tahfidz_provider.dart` | `TahfidzProvider` | Pengelolaan state data hafalan & santri bimbingan. |
| `lib/screens/login_screen.dart` | `LoginScreen` | UI autentikasi awal. |

## # Data & Config
- **Konfigurasi Utama**: `lib/config/api_config.dart` (`baseUrl`: `https://demo.assunnahcirebon.com/api`).
- **Skema Data**: 
  - `User`: ID, Unit, Division, Position Level, Permissions.
  - `Permission`: Map of features allowed for the user.
- **Penyimpanan Lokal**: 
  - `SharedPreferences`: Session status, User details, Permissions.
- **Output Artifacts**: PDF (via `printing` package), Image/Photo (via `camera`/`image_picker`).

## # External Integrations
- **Firebase Core/Messaging**: Push notification service.
- **Google Fonts**: Tipografi sistem (Poppins).
- **YouTube API**: Streaming konten Assunnah TV.
- **Local Notifications**: Pengingat & notifikasi sistem lokal.

## # Risks / Blind Spots
- **Header Khusus**: Penggunaan `ngrok-skip-browser-warning` menunjukkan sisa debugging atau penggunaan tunnel untuk staging.
- **Mixed API Structure**: Struktur endpoint PHP tidak sepenuhnya seragam (beberapa di sub-folder, beberapa di root API).
- **Security**: Kredensial disimpan di `SharedPreferences`, disarankan migrasi penuh ke `flutter_secure_storage` untuk data sensitif jika belum.
- **Data Freshness**: Penggunaan `Sliding Expiration` pada sesi di `main.dart` perlu dipastikan sinkron dengan expired token di server.
