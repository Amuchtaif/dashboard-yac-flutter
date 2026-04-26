import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class WorkReportService {
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('user_id') ?? prefs.get('userId');
    return userId?.toString() ?? '0';
  }

  Future<Map<String, dynamic>> saveReport(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.workReportSave),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final result = jsonDecode(response.body);
        return result;
      }
    } catch (e) {
      debugPrint('Error saving work report: $e');
      return {'success': false, 'message': 'Connection Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('${ApiConstants.workReportGetMy}?user_id=$userId'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my reports: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStaffReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.get('user_id') ?? prefs.get('userId');
      final positionLevel = prefs.getInt('positionLevel') ?? 5;
      final unitId = prefs.get('unitId');
      final divisionId = prefs.get('divisionId');

      final url = '${ApiConstants.workReportGetStaff}?user_id=$userId'
          '&position_level=$positionLevel'
          '&unit_id=${unitId ?? ''}'
          '&division_id=${divisionId ?? ''}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching staff reports: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workReportGetCategories),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          final List<dynamic> categories = result['data'];
          return categories.map((c) => c['name'].toString()).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }
}
