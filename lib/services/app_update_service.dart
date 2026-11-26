import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_constants.dart';

class AppVersionResponse {
  final bool success;
  final String latestVersion;
  final int latestBuild;
  final int minBuildRequired;
  final String apkUrl;
  final String changelog;
  final String? message;

  AppVersionResponse({
    required this.success,
    required this.latestVersion,
    required this.latestBuild,
    required this.minBuildRequired,
    required this.apkUrl,
    required this.changelog,
    this.message,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionResponse(
      success: json['success'] == true,
      latestVersion: json['latest_version']?.toString() ?? '',
      latestBuild: int.tryParse(json['latest_build']?.toString() ?? '0') ?? 0,
      minBuildRequired:
          int.tryParse(json['min_build_required']?.toString() ?? '0') ?? 0,
      apkUrl: json['apk_url']?.toString() ?? '',
      changelog: json['changelog']?.toString() ?? '',
      message: json['message']?.toString(),
    );
  }
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// Pembanding versi semver (misal '1.5.8' > '1.5.7')
  bool isVersionNewer(String latest, String current) {
    try {
      final cleanLatest = latest.toLowerCase().replaceAll('v', '').trim();
      final cleanCurrent = current.toLowerCase().replaceAll('v', '').trim();

      if (cleanLatest.isEmpty || cleanCurrent.isEmpty) return false;

      final latestParts = cleanLatest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final currentParts = cleanCurrent
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      final maxLength = latestParts.length > currentParts.length
          ? latestParts.length
          : currentParts.length;

      for (int i = 0; i < maxLength; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) {
      debugPrint('AppUpdateService isVersionNewer error: $e');
    }
    return false;
  }

  /// Pengecekan versi aplikasi ke backend server
  Future<AppVersionResponse?> checkVersion({
    int? employeeId,
    String? currentVersion,
    int? currentBuild,
  }) async {
    try {
      int resolvedEmployeeId = employeeId ?? 0;
      if (resolvedEmployeeId == 0) {
        final prefs = await SharedPreferences.getInstance();
        final rawUserId = prefs.get('user_id') ?? prefs.get('userId');
        if (rawUserId is int) {
          resolvedEmployeeId = rawUserId;
        } else if (rawUserId is String) {
          resolvedEmployeeId = int.tryParse(rawUserId) ?? 0;
        }
      }

      String resolvedVersion = currentVersion ?? '1.0.0';
      int resolvedBuild = currentBuild ?? 0;

      if (currentVersion == null || currentBuild == null) {
        final info = await PackageInfo.fromPlatform();
        resolvedVersion = info.version;
        resolvedBuild = int.tryParse(info.buildNumber) ?? 0;
      }

      final body = jsonEncode({
        "employee_id": resolvedEmployeeId,
        "app_version": resolvedVersion,
        "build_number": resolvedBuild,
      });

      debugPrint('AppUpdateService: checking version with body: $body');

      final response = await http.post(
        Uri.parse(ApiConstants.appVersion),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: body,
      );

      debugPrint(
        'AppUpdateService response (${response.statusCode}): ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return AppVersionResponse.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('AppUpdateService error: $e');
    }
    return null;
  }

  /// Pengecekan versi dan memunculkan dialog update jika tersedia
  Future<void> checkAppUpdate(
    BuildContext context, {
    bool showFeedbackIfUpToDate = false,
  }) async {
    if (kIsWeb) return;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      final currentVersion = info.version;

      final res = await checkVersion(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );

      if (res == null || !res.success) {
        if (showFeedbackIfUpToDate && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal memeriksa pembaruan aplikasi. Periksa koneksi Anda.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // Deteksi ketersediaan update: jika build lebih tinggi ATAU versi string lebih baru
      final bool hasNewBuild = res.latestBuild > currentBuild;
      final bool hasNewVersion = isVersionNewer(
        res.latestVersion,
        currentVersion,
      );
      final bool hasApkUrl = res.apkUrl.trim().isNotEmpty;

      if ((hasNewBuild || hasNewVersion) && hasApkUrl) {
        final bool isForced = currentBuild < res.minBuildRequired;

        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersion: res.latestVersion,
            latestBuild: res.latestBuild,
            apkUrl: res.apkUrl,
            changelog: res.changelog,
            isForced: isForced,
          );
        }
      } else if (showFeedbackIfUpToDate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aplikasi sudah versi terbaru (v$currentVersion).',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('AppUpdateService checkAppUpdate error: $e');
      if (showFeedbackIfUpToDate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Dialog konfirmasi update (Wajib update jika isForced == true)
  void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required int latestBuild,
    required String apkUrl,
    required String changelog,
    bool isForced = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: true,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isForced
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    color: isForced
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isForced ? 'Pembaruan Wajib' : 'Pembaruan Tersedia',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Versi $latestVersion (Build $latestBuild)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isForced
                      ? 'Pembaruan ini wajib dilakukan untuk melanjutkan penggunaan aplikasi.'
                      : 'Versi baru aplikasi sudah tersedia. Perbarui sekarang untuk mendapatkan fitur terbaru dan perbaikan sistem.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
                if (changelog.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Catatan Pembaruan:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 140),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        changelog,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Nanti',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isForced
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  startDownload(context, apkUrl, isForced: isForced);
                },
                child: Text(
                  'Update Sekarang',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Buka browser eksternal untuk mengunduh APK secara manual
  static Future<void> openBrowserDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('AppUpdateService openBrowserDownload error: $e');
    }
  }

  /// Mengunduh APK pembaruan dan memicu installer Android
  void startDownload(
    BuildContext context,
    String apkUrl, {
    bool isForced = false,
  }) {
    final ValueNotifier<String> progressNotifier = ValueNotifier("0%");
    final ValueNotifier<double?> progressValueNotifier = ValueNotifier(null);
    bool isDialogShowing = true;

    void closeDialog() {
      if (isDialogShowing && context.mounted) {
        isDialogShowing = false;
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          debugPrint('AppUpdateService error closing dialog: $e');
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Mengunduh Pembaruan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: progressNotifier,
            builder: (_, val, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double?>(
                  valueListenable: progressValueNotifier,
                  builder: (_, progressVal, __) => LinearProgressIndicator(
                    value: progressVal,
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  val,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                isDialogShowing = false;
                Navigator.of(ctx, rootNavigator: true).pop();
                openBrowserDownload(apkUrl);
              },
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: Text(
                'Unduh via Browser',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      isDialogShowing = false;
    });

    try {
      OtaUpdate().execute(
        apkUrl,
        destinationFilename: 'update.apk',
        androidProviderAuthority: 'com.example.dashboard_yac.ota_update_provider',
      ).listen(
        (OtaEvent event) {
          debugPrint('AppUpdateService OtaEvent: ${event.status} (${event.value})');
          if (event.status == OtaStatus.DOWNLOADING) {
            progressNotifier.value = "${event.value}%";
            final double? parsedVal = double.tryParse(event.value ?? '');
            if (parsedVal != null) {
              progressValueNotifier.value = parsedVal / 100.0;
            }
          } else if (event.status == OtaStatus.INSTALLING) {
            progressNotifier.value = "Menyiapkan instalasi...";
            closeDialog();
          } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR ||
              event.status == OtaStatus.INSTALLATION_ERROR ||
              event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR ||
              event.status == OtaStatus.INTERNAL_ERROR) {
            closeDialog();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pembaruan otomatis gagal (${event.status.name}). Silakan unduh manual.',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 10),
                  action: SnackBarAction(
                    label: 'Browser',
                    textColor: Colors.white,
                    onPressed: () => openBrowserDownload(apkUrl),
                  ),
                ),
              );
            }
          }
        },
        onError: (e) {
          debugPrint('AppUpdateService OtaUpdate onError: $e');
          closeDialog();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Gagal mengunduh pembaruan. Silakan unduh manual.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 10),
                action: SnackBarAction(
                  label: 'Browser',
                  textColor: Colors.white,
                  onPressed: () => openBrowserDownload(apkUrl),
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('AppUpdateService startDownload catch: $e');
      closeDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Browser',
              textColor: Colors.white,
              onPressed: () => openBrowserDownload(apkUrl),
            ),
          ),
        );
      }
    }
  }
}
