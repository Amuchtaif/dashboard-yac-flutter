import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'offline_sync_service.dart';

class TahfidzRepository {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Handle unauthorized response
  bool _checkResponse(http.Response response) {
    if (response.statusCode == 401) {
      debugPrint("TahfidzRepository: Unauthorized request (401). Triggering logout...");
      // Clear locally.
      SharedPreferences.getInstance().then((prefs) {
        prefs.clear();
      });
      return false;
    }
    return true;
  }

  Future<Map<String, dynamic>> getDashboard(int studentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$_baseUrl/tahfidz/dashboard?student_id=$studentId"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getBaselines() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$_baseUrl/tahfidz/baselines"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> createBaseline(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$_baseUrl/tahfidz/baselines"),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateBaseline(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("$_baseUrl/tahfidz/baselines/$id"),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getEntries(Map<String, dynamic> filters) async {
    final offlineSync = OfflineSyncService();
    final dateStr = filters['date']?.toString() ??
        filters['start_date']?.toString() ??
        filters['end_date']?.toString() ??
        '';
    final cacheKey = dateStr.isNotEmpty
        ? 'tahfidz_entries_$dateStr'
        : 'tahfidz_entries_latest';

    try {
      final headers = await _getHeaders();
      final queryParams = filters
          .map((key, value) => MapEntry(key, value?.toString() ?? ''));
      // Remove empty params
      queryParams.removeWhere((key, value) => value.isEmpty);
      final uri = Uri.parse("$_baseUrl/tahfidz/entries")
          .replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));

      _checkResponse(response);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          await offlineSync.saveCache(cacheKey, decoded['data']);
          await offlineSync.saveCache('tahfidz_entries_latest', decoded['data']);
        }
        return decoded;
      }
    } catch (e) {
      debugPrint("Error fetching tahfidz entries (using offline cache): $e");
    }

    // Fallback: baca dari cache lokal dan gabungkan dengan antrean offline jika ada
    List<dynamic> entries = [];
    final cached = await offlineSync.getCache(cacheKey) ??
        await offlineSync.getCache('tahfidz_entries_latest');
    if (cached != null && cached is List) {
      entries = List.from(cached);
    }

    // Gabungkan dengan antrean setoran offline jika tanggal sesuai
    final offlineTasks =
        offlineSync.queue.where((t) => t.type == 'tahfidz_setoran');
    for (var task in offlineTasks) {
      final payload = task.payload;
      final taskDate = payload['date']?.toString() ??
          payload['created_at']?.toString() ??
          '';
      if (dateStr.isEmpty || taskDate.contains(dateStr)) {
        entries.insert(0, {
          'id': -DateTime.now().millisecondsSinceEpoch,
          'student_id': payload['student_id'],
          'teacher_id': payload['teacher_id'],
          'date': taskDate.isNotEmpty ? taskDate : dateStr,
          'session': payload['session'] ?? payload['session_name'],
          'start_surah_id': payload['start_surah_id'] ?? payload['surah_id'],
          'surah_start': payload['surah_start'],
          'start_ayah': payload['start_ayah'] ?? payload['ayat_start'],
          'end_surah_id': payload['end_surah_id'],
          'surah_end': payload['surah_end'],
          'end_ayah': payload['end_ayah'] ?? payload['ayat_end'],
          'quality': payload['status'] ?? 'LANCAR',
          'status': payload['status'] ?? 'LANCAR',
          'entry_type':
              payload['entry_type'] ?? payload['jenis_setoran'] ?? 'HAFALAN_BARU',
          'notes': payload['notes'],
          'is_offline_pending': true,
        });
      }
    }

    return {
      'success': true,
      'isOffline': true,
      'data': entries,
      'message': 'Data dimuat dari cache lokal',
    };
  }

  Future<Map<String, dynamic>> getEntry(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$_baseUrl/tahfidz/entries/$id"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> createEntry(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$_baseUrl/tahfidz/entries"),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateEntry(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("$_baseUrl/tahfidz/entries/$id"),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteEntry(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse("$_baseUrl/tahfidz/entries/$id"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getSemesterReport(Map<String, dynamic> filters) async {
    try {
      final headers = await _getHeaders();
      final queryParams = filters.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      queryParams.removeWhere((key, value) => value.isEmpty);
      final uri = Uri.parse("$_baseUrl/tahfidz/report-semester").replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> closeSemester(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$_baseUrl/tahfidz/report-semester/close"),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getSnapshot(int semesterId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$_baseUrl/tahfidz/snapshots/$semesterId"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPimpinanDashboard(int userId, Map<String, dynamic> filters) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'user_id': userId.toString(),
        ...filters.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      };
      queryParams.removeWhere((key, value) => value.isEmpty);

      final uri = Uri.parse("$_baseUrl/tahfidz/dashboard_pimpinan").replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      _checkResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getActiveAcademicYear() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("$_baseUrl/tahfidz/get_active_academic_year.php"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      _checkResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Timeout or Network Error: $e'};
    }
  }
}
