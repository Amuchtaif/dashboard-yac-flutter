# [Task] Implementasi In-App Auto-Update & Pelaporan Versi APK (Flutter)

## 📌 Deskripsi Fitur

Aplikasi didistribusikan secara mandiri dalam bentuk APK (di luar Google Play Store). Pengembang diminta menambahkan fitur:

1. Pengecekan versi aplikasi ke server backend.
2. Dialog notifikasi pembaruan (_Flexible_ atau _Forced Update_).
3. Pengunduhan otomatis file APK dan memicu _installer_ sistem Android.
4. Pelaporan versi yang sedang digunakan user ke dashboard admin.

---

## 🛠️ Checklist Pengerjaan

### 1. Izin Android (`android/app/src/main/AndroidManifest.xml`)

Tambahkan permission berikut di dalam tag `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<!-- Wajib agar Android mengizinkan instalasi APK dari dalam aplikasi -->
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
```

---

### 2. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  package_info_plus: ^8.0.0 # Membaca versi & build number lokal
  ota_update: ^5.2.0 # Download stream APK + trigger installer Android
  http: ^1.2.0
```

---

### 3. Kirim Versi Saat Login (`api/login.php`)

Di fungsi login, sertakan data `app_version` dan `build_number` pada body JSON:

```dart
final info = await PackageInfo.fromPlatform();

final body = jsonEncode({
  'email': emailController.text,
  'password': passwordController.text,
  'app_version': info.version,                 // Contoh: "1.0.0"
  'build_number': int.parse(info.buildNumber),   // Contoh: 1
});
```

---

### 4. Service Pengecekan Versi (`checkAppUpdate`)

Panggil fungsi ini di `initState()` halaman Home/Dashboard:

- **Method:** `POST`
- **URL:** `https://domain-anda/api/app_version.php`
- **Request Body:**
  ```json
  {
    "employee_id": 12,
    "app_version": "1.0.0",
    "build_number": 1
  }
  ```
- **Response Body:**
  ```json
  {
    "success": true,
    "latest_version": "1.2.0",
    "latest_build": 15,
    "min_build_required": 12,
    "apk_url": "https://domain-anda/uploads/app/app-release.apk",
    "changelog": "Perbaikan presensi dan stabilitas sistem."
  }
  ```

#### Logika Pengecekan:

1. Bandingkan `latest_build > current_build`. Jika bernilai `true`, munculkan dialog.
2. Cek apakah `current_build < min_build_required`:
   - **Forced Update:** `barrierDismissible: false`, gunakan `PopScope(canPop: false)`, dan sembunyikan tombol _"Nanti"_.
   - **Flexible Update:** Sediakan tombol _"Nanti"_ dan _"Update Sekarang"_.

---

### 5. Logika Download & Auto-Install

Saat tombol **"Update Sekarang"** ditekan:

```dart
void startDownload(BuildContext context, String apkUrl) {
  ValueNotifier<String> progressNotifier = ValueNotifier("0%");

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Mengunduh Pembaruan'),
      content: ValueListenableBuilder<String>(
        valueListenable: progressNotifier,
        builder: (_, val, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text(val),
          ],
        ),
      ),
    ),
  );

  OtaUpdate().execute(apkUrl, destinationFilename: 'update.apk').listen(
    (OtaEvent event) {
      if (event.status == OtaStatus.DOWNLOADING) {
        progressNotifier.value = "${event.value}%";
      } else if (event.status == OtaStatus.INSTALLING) {
        Navigator.pop(context); // Dialog ditutup, Package Installer otomatis muncul
      }
    },
    onError: (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh pembaruan: $e')),
      );
    },
  );
}
```

---

## ⚠️ Perhatian Khusus Rilis APK

- **Keystore Certificate:** APK baru wajib ditandatangani (_signed_) menggunakan `key.jks` dan _package name_ yang sama persis dengan APK yang sedang terpasang di HP user, agar tidak memicu error sistem _"App not installed / Signature mismatch"_.
