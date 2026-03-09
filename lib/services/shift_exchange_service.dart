import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class ShiftExchangeService {
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<int?> _getDivisionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('divisionId');
  }

  Future<int?> _getUnitId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('unitId');
  }

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'User not found'};
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.shiftSummary}?user_id=$userId'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('Error fetching shift summary: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<List<Map<String, dynamic>>> getEmployees({
    int? divisionId,
    int? unitId,
  }) async {
    try {
      final currentUserId = await _getUserId();
      final userDivisionId = divisionId ?? await _getDivisionId();
      final userUnitId = unitId ?? await _getUnitId();

      String url = '${ApiConstants.getEmployees}?all=true';
      if (currentUserId != null) url += '&user_id=$currentUserId';
      if (userDivisionId != null) url += '&division_id=$userDivisionId';
      if (userUnitId != null) url += '&unit_id=$userUnitId';

      debugPrint('🔍 Fetching colleagues with URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<Map<String, dynamic>> employees =
              List<Map<String, dynamic>>.from(data['data']);

          // Filter out the current user and ensure they are from same division if that was the filter
          return employees.where((e) {
            final isNotMe = e['id'].toString() != currentUserId.toString();
            final posName = e['position_name']?.toString().toLowerCase() ?? '';
            final isNotAdmin =
                !posName.contains('administrator') &&
                !posName.contains('admin');
            final isNotKabid = !posName.contains('kepala bidang');
            return isNotMe && isNotAdmin && isNotKabid;
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching employees: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getList(String type) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConstants.shiftGetList}?user_id=$userId&type=$type'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching shift list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createRequest({
    required int substituteId,
    required String exchangeDate,
    required String reason,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'User not found'};
      }

      final response = await http.post(
        Uri.parse(ApiConstants.shiftCreate),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'requester_id': userId,
          'substitute_id': substituteId,
          'exchange_date': exchangeDate,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('Error creating shift request: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateStatus(int id, String status) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'User not found'};
      }

      final response = await http.post(
        Uri.parse(ApiConstants.shiftUpdateStatus),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'id': id, 'status': status, 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('Error updating shift status: $e');
      return {'success': false, 'message': 'Connection error'};
    }
  }
}
