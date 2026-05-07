import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/attendance_model.dart';
import '../models/location_model.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<LocationModel>> getLocations() async {
    final url = Uri.parse('$baseUrl/get_locations.php');
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if ((data['success'] == true || data['status'] == true) &&
            data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((json) => LocationModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // print('Error fetching locations: $e');
    }
    return [];
  }

  Future<List<AttendanceActivity>> getHistory(int userId, {String? startDate, String? endDate}) async {
    final url = Uri.parse('$baseUrl/attendance.php');
    try {
      final Map<String, dynamic> body = {
        'action': 'get_history',
        'user_id': userId,
      };
      
      if (startDate != null) body['start_date'] = startDate;
      if (endDate != null) body['end_date'] = endDate;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if ((data['success'] == true || data['status'] == true) &&
            data['data'] != null) {
          final List<dynamic> historyList = data['data'];
          return historyList
              .map((json) => AttendanceActivity.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      // print('Error fetching history: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> checkIn({
    required int userId,
    required int locationId,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse('$baseUrl/attendance.php');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'action': 'check_in',
          'user_id': userId,
          'location_id': locationId,
          'type': 'IN',
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        }),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message':
              'Server mengembalikan respon kosong. Ini biasanya menandakan adanya error pada script server (attendance.php).'
        };
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required int userId,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse('$baseUrl/attendance.php');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'action': 'check_out',
          'user_id': userId,
          'type': 'OUT',
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        }),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message':
              'Server mengembalikan respon kosong pada proses check-out. Harap lapor ke admin.'
        };
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
