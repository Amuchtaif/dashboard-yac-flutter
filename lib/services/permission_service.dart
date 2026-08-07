import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service untuk mengelola permission/hak akses user.
/// Menggunakan Singleton pattern agar state permission konsisten di seluruh aplikasi.
class PermissionService {
  // Singleton instance
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Cache permission di memory untuk akses cepat
  bool _canCreateMeeting = false;
  bool _canApprovePermits = false;
  bool _canAccessTahfidzMonitoring = false;
  bool _isWaliKelas = false;
  bool _isLoaded = false;
  bool _usingFallback = false;
  List<String> _allowedTahfidzUnits = [];

  /// Getter untuk mengecek apakah user bisa membuat rapat
  bool get canCreateMeeting => _canCreateMeeting;

  /// Getter untuk mengecek apakah user bisa menyetujui izin
  bool get canApprovePermits => _canApprovePermits;

  /// Getter untuk mengecek apakah user diizinkan mengakses Dashboard Monitoring Tahfidz (Pimpinan)
  bool get canAccessTahfidzMonitoring => _canAccessTahfidzMonitoring;

  /// Getter untuk list unit Tahfidz yang diizinkan untuk user
  List<String> get allowedTahfidzUnits => _allowedTahfidzUnits;

  /// Getter untuk mengecek apakah user adalah Wali Kelas
  bool get isWaliKelas => _isWaliKelas;

  /// Getter untuk mengecek apakah permission sudah di-load
  bool get isLoaded => _isLoaded;

  /// Getter untuk mengecek apakah data saat ini dari fallback
  bool get usingFallback => _usingFallback;

  /// List permission aktif (string)
  List<String> _activePermissions = [];
  List<String> get activePermissions => _activePermissions;

  /// Load permission dari SharedPreferences (cached)
  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _canCreateMeeting = prefs.getBool('can_create_meeting') ?? false;
    _canApprovePermits = prefs.getBool('can_approve_permits') ?? false;
    _canAccessTahfidzMonitoring = prefs.getBool('can_access_tahfidz_monitoring') ?? false;
    _isWaliKelas = prefs.getBool('is_wali_kelas') ?? false;
    _activePermissions = prefs.getStringList('user_permissions') ?? [];
    _allowedTahfidzUnits = prefs.getStringList('allowed_tahfidz_units') ?? [];
    _usingFallback = prefs.getBool('using_fallback') ?? false;
    _isLoaded = true;
    debugPrint(
      "📋 Permission Loaded from Cache: canCreateMeeting=$_canCreateMeeting, canApprovePermits=$_canApprovePermits, canAccessTahfidzMonitoring=$_canAccessTahfidzMonitoring, usingFallback=$_usingFallback",
    );
    debugPrint("📋 Active Permissions from Cache: $_activePermissions, Allowed Units: $_allowedTahfidzUnits");
  }

  /// Fetch permission dari API dan simpan ke cache
  /// Dipanggil saat login atau refresh session
  Future<bool> fetchPermissions(int userId) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_user_permissions.php?user_id=$userId",
      );

      debugPrint("🌐 Fetching permissions from: $url");

      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      debugPrint("🌐 Permission API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final responseData = data['data'];
          final permissions =
              responseData['permissions'] as Map<String, dynamic>;

          // Parse permission values
          _canCreateMeeting = _parseBool(permissions['can_create_meeting']);
          _canApprovePermits = _parseBool(permissions['can_approve_permits']);
          _canAccessTahfidzMonitoring = _parseBool(permissions['can_access_tahfidz_monitoring']);
          _isWaliKelas = _parseBool(permissions['is_wali_kelas']);

          if (responseData['allowed_tahfidz_units'] != null) {
            _allowedTahfidzUnits = List<String>.from(
              responseData['allowed_tahfidz_units'].map((x) => x.toString()),
            );
          } else {
            _allowedTahfidzUnits = [];
          }

          // Populate active permissions list
          _activePermissions.clear();
          permissions.forEach((key, value) {
            if (_parseBool(value)) {
              _activePermissions.add(key);
            }
          });

          _usingFallback = false;
          await _saveToCache();

          _isLoaded = true;
          debugPrint("✅ Permissions Fetched from API: $_activePermissions");
          return true;
        } else {
          debugPrint("❌ Fetch Permissions Failed: ${data['message']}");
        }
      } else {
        debugPrint("❌ Fetch Permissions HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Fetch Permissions Error: $e");
    }

    // ============================================
    // FALLBACK strictly division-based
    // ============================================
    debugPrint("⚠️ API unavailable or failed, using strict fallback...");

    final prefs = await SharedPreferences.getInstance();
    final int positionLevel = prefs.getInt('positionLevel') ?? 99;
    final String positionName = prefs.getString('positionName') ?? '';
    final String divisionName = prefs.getString('divisionName') ?? '';

    debugPrint(
      "⚠️ Fallback Context - Level: $positionLevel, Pos: $positionName, Div: $divisionName",
    );

    _activePermissions.clear();
    _usingFallback = true;

    // 1. Create Meeting - Tetap untuk struktural (Level 1-3)
    if (positionLevel <= 3) {
      _canCreateMeeting = true;
      _activePermissions.add('can_create_meeting');
    }

    // 2. Approve Permits - Khusus Kesantrian atau Level 1-2
    if ((positionLevel <= 2 &&
            divisionName.toLowerCase().contains('kesantrian')) ||
        positionName.toLowerCase().contains('mudir') ||
        positionName.toLowerCase().contains('kepala bidang kesantrian') ||
        (positionLevel == 3 &&
            divisionName.toLowerCase().contains('kesantrian'))) {
      _canApprovePermits = true;
      _activePermissions.add('can_approve_permits');
    }

    // 3. Kabid Menu - Hanya untuk Mudir atau Kabid ASLI
    if (positionLevel == 1 ||
        positionName.toLowerCase().contains('mudir') ||
        (positionLevel == 2 &&
            positionName.toLowerCase().contains('kepala bidang'))) {
      _activePermissions.add('can_access_kabid');
    }

    // 4. Kesantrian Menu - Ketat berdasarkan divisi
    if (divisionName.toLowerCase().contains('kesantrian') ||
        positionName.toLowerCase().contains('musyrif') ||
        positionName.toLowerCase().contains('kesantrian')) {
      _activePermissions.add('can_access_kesantrian');
    }

    // 5. Tahfidz Menu - Ketat berdasarkan divisi
    if (divisionName.toLowerCase().contains('tahfidz') ||
        positionName.toLowerCase().contains('tahfidz')) {
      _activePermissions.add('can_access_tahfidz');
    }

    // 6. Pendidikan Menu - Ketat berdasarkan divisi atau guru
    if (divisionName.toLowerCase().contains('pendidikan') ||
        positionLevel == 4 ||
        positionName.toLowerCase().contains('guru') ||
        positionName.toLowerCase().contains('akademik')) {
      _activePermissions.add('can_access_education');
    }

    // 7. Penugasan/Coordinator
    if (positionName.toLowerCase().contains('koordinator')) {
      _activePermissions.add('is_koordinator');
    }

    await _saveToCache();
    _isLoaded = true;

    debugPrint("⚠️ Strict Fallback Applied: $_activePermissions");

    return false;
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('can_create_meeting', _canCreateMeeting);
    await prefs.setBool('can_approve_permits', _canApprovePermits);
    await prefs.setBool('can_access_tahfidz_monitoring', _canAccessTahfidzMonitoring);
    await prefs.setBool('is_wali_kelas', _isWaliKelas);
    await prefs.setStringList('user_permissions', _activePermissions);
    await prefs.setStringList('allowed_tahfidz_units', _allowedTahfidzUnits);
    await prefs.setBool('using_fallback', _usingFallback);
    debugPrint("💾 Permissions saved to cache");
  }

  /// Update permission secara manual
  Future<void> setPermission({required bool canCreateMeeting}) async {
    _canCreateMeeting = canCreateMeeting;
    _usingFallback = true;
    await _saveToCache();
    _isLoaded = true;
  }

  Future<void> clear() async {
    _canCreateMeeting = false;
    _canApprovePermits = false;
    _canAccessTahfidzMonitoring = false;
    _allowedTahfidzUnits = [];
    _isLoaded = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('can_create_meeting');
    await prefs.remove('can_approve_permits');
    await prefs.remove('can_access_tahfidz_monitoring');
    await prefs.remove('allowed_tahfidz_units');
    await prefs.remove('user_permissions');
    debugPrint("🗑️ Permissions cleared");
  }

  /// Helper untuk parse nilai ke boolean
  /// Mendukung: 1, "1", true, "true"
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  bool hasPermission(String permissionName) {
    debugPrint(
      "🔐 hasPermission('$permissionName') called. isLoaded=$_isLoaded, activePermissions=$_activePermissions",
    );
    if (_activePermissions.contains(permissionName)) {
      debugPrint("🔐 ✅ '$permissionName' FOUND in activePermissions");
      return true;
    }

    // Alias checking for Tahfidz Monitoring
    if (permissionName == 'can_access_tahfidz_monitoring' || permissionName == 'access_tahfidz_monitoring') {
      if (_canAccessTahfidzMonitoring ||
          _activePermissions.contains('can_access_tahfidz_monitoring') ||
          _activePermissions.contains('access_tahfidz_monitoring')) {
        debugPrint("🔐 ✅ Tahfidz Monitoring FOUND via alias check");
        return true;
      }
    }

    // Alias checking for Tahfidz
    if (permissionName == 'can_access_tahfidz' || permissionName == 'access_tahfidz') {
      if (_activePermissions.contains('can_access_tahfidz') ||
          _activePermissions.contains('access_tahfidz')) {
        debugPrint("🔐 ✅ Tahfidz FOUND via alias check");
        return true;
      }
    }

    // Fallback untuk backward compatibility jika diperlukan
    switch (permissionName) {
      case 'create_meeting':
        return _canCreateMeeting;
      case 'approve_permits':
        return _canApprovePermits;
      case 'can_access_tahfidz_monitoring':
      case 'access_tahfidz_monitoring':
        return _canAccessTahfidzMonitoring;
      default:
        debugPrint("🔐 ❌ '$permissionName' NOT FOUND in activePermissions");
        return false;
    }
  }
}
