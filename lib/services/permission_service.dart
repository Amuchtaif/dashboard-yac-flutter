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
  bool _isLoaded = false;

  /// Getter untuk mengecek apakah user bisa membuat rapat
  bool get canCreateMeeting => _canCreateMeeting;

  /// Getter untuk mengecek apakah permission sudah di-load
  bool get isLoaded => _isLoaded;

  /// Load permission dari SharedPreferences (cached)
  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _canCreateMeeting = prefs.getBool('can_create_meeting') ?? false;
    _isLoaded = true;
    debugPrint(
      "📋 Permission Loaded from Cache: canCreateMeeting=$_canCreateMeeting",
    );
  }

  /// Fetch permission dari API dan simpan ke cache
  /// Dipanggil saat login atau refresh session
  Future<bool> fetchPermissions(int userId) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_user_permissions.php?user_id=$userId",
      );

      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final responseData = data['data'];
          final permissions = responseData['permissions'];

          // Parse permission values (handle both int and string)
          _canCreateMeeting = _parseBool(permissions['can_create_meeting']);

          // Simpan ke SharedPreferences untuk cache
          await _saveToCache();

          _isLoaded = true;
          debugPrint(
            "✅ Permissions Fetched: canCreateMeeting=$_canCreateMeeting",
          );
          return true;
        } else {
          debugPrint("❌ Fetch Permissions Failed: ${data['message']}");
          return false;
        }
      } else {
        debugPrint("❌ Fetch Permissions HTTP Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Fetch Permissions Error: $e");
      return false;
    }
  }

  /// Simpan permission ke SharedPreferences
  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('can_create_meeting', _canCreateMeeting);
    debugPrint("💾 Permissions saved to cache");
  }

  /// Update permission secara manual (misal untuk testing)
  Future<void> setPermission({required bool canCreateMeeting}) async {
    _canCreateMeeting = canCreateMeeting;
    await _saveToCache();
    _isLoaded = true;
  }

  /// Reset semua permission (saat logout)
  Future<void> clear() async {
    _canCreateMeeting = false;
    _isLoaded = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('can_create_meeting');
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

  /// Validasi apakah user diperbolehkan melakukan aksi tertentu
  /// Bisa di-extend untuk permission lainnya
  bool hasPermission(String permissionName) {
    switch (permissionName) {
      case 'create_meeting':
        return _canCreateMeeting;
      default:
        debugPrint("⚠️ Unknown permission: $permissionName");
        return false;
    }
  }
}
