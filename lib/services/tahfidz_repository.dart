import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class TahfidzRepository {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
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
    try {
      final headers = await _getHeaders();
      final queryParams = filters.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      // Remove empty params
      queryParams.removeWhere((key, value) => value.isEmpty);
      final uri = Uri.parse("$_baseUrl/tahfidz/entries").replace(queryParameters: queryParams);

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
