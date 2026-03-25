import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/staff_attendance_model.dart';
import '../models/staff_attendance_recap_model.dart';

class KabidService {
  Future<List<StaffAttendance>> getStaffAttendance({
    required int userId,
    String? date,
  }) async {
    try {
      final queryParams = {
        'user_id': userId.toString(),
      };
      if (date != null) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse(ApiConstants.kabidStaffAttendance).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          return list.map((item) => StaffAttendance.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching staff attendance: $e');
      return [];
    }
  }

  Future<StaffAttendanceRecap?> getStaffAttendanceRecap(int userId) async {
    try {
      final uri = Uri.parse(ApiConstants.kabidStaffAttendanceRecap).replace(
        queryParameters: {'user_id': userId.toString()},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return StaffAttendanceRecap.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching staff attendance recap: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getStaffAttendanceMonthDetail({
    required int userId,
    required String month,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.kabidStaffAttendanceMonthDetail).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'month': month,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          return List<Map<String, dynamic>>.from(list);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching staff month detail: $e');
      return [];
    }
  }
}
