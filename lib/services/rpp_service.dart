import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class RppService {
  Future<String> _getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('user_id') ?? prefs.get('userId');
    return userId.toString();
  }

  Future<Map<String, dynamic>> getActivePeriod() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.rppGetActivePeriod),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' || result['success'] == true) {
          return result['data'];
        }
      }
      return {};
    } catch (e) {
      debugPrint('RppService: Error fetching active period: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getRppList({
    bool isDraft = false,
    String search = '',
  }) async {
    try {
      final employeeId = await _getEmployeeId();
      final url = Uri.parse(ApiConstants.rppGetList).replace(
        queryParameters: {
          'employee_id': employeeId,
          'is_draft': isDraft ? '1' : '0',
          'search': search,
        },
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' || result['success'] == true) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('RppService: Error fetching RPP list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getRppDetail(String rppId) async {
    try {
      final url = Uri.parse(
        ApiConstants.rppGetDetail,
      ).replace(queryParameters: {'rpp_id': rppId});

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' || result['success'] == true) {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('RppService: Error fetching RPP detail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createRpp(Map<String, dynamic> rppData) async {
    try {
      final employeeId = await _getEmployeeId();
      final body = {...rppData, 'employee_id': employeeId};

      debugPrint('RppService: Sending createRpp payload: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(ApiConstants.rppCreate),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('RppService: Create RPP Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      debugPrint('RppService: Error creating RPP: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateRpp(Map<String, dynamic> rppData) async {
    try {
      final employeeId = await _getEmployeeId();
      final body = {...rppData, 'employee_id': employeeId};

      debugPrint('RppService: Sending updateRpp payload: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(ApiConstants.rppUpdate),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('RppService: Update RPP Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      debugPrint('RppService: Error updating RPP: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteRpp(String rppId) async {
    try {
      final employeeId = await _getEmployeeId();
      final body = {'id': rppId, 'employee_id': employeeId};

      final response = await http.post(
        Uri.parse(ApiConstants.rppDelete),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      debugPrint('RppService: Error deleting RPP: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
