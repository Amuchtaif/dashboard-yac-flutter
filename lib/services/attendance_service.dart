import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/attendance_model.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  Future<List<AttendanceActivity>> getHistory(int userId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}attendance.php');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({'action': 'get_history', 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
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

  Future<Map<String, dynamic>> checkIn(
    int userId,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}attendance.php');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'action': 'check_in',
          'user_id': userId,
          'type': 'Check In',
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> checkOut(
    int userId,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}attendance.php');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'action': 'check_out',
          'user_id': userId,
          'type': 'Check Out',
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
