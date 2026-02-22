import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class TeacherService {
  Future<List<Map<String, dynamic>>> getDailySchedule(String day) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Handle both String and Int types for user_id safely
      String employeeId = '0';
      if (prefs.containsKey('user_id')) {
        final userId = prefs.get('user_id');
        if (userId is int) {
          employeeId = userId.toString();
        } else if (userId is String) {
          employeeId = userId;
        }
      }

      final uri = Uri.parse(
        ApiConstants.teacherSchedule,
      ).replace(queryParameters: {'employee_id': employeeId, 'day': day});

      debugPrint('TeacherService: Fetching schedule from $uri');

      final response = await http.get(uri);

      debugPrint('TeacherService: Response Status: ${response.statusCode}');
      debugPrint('TeacherService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Debug: print keys to verify structure
        debugPrint('Result keys: ${result.keys}');

        // Handle {"status": "success", "data": [...]} structure
        if (result['status'] == 'success' || result['success'] == true) {
          if (result['data'] != null) {
            return List<Map<String, dynamic>>.from(result['data']);
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStudentsBySchedule(
    String scheduleId,
    String date,
  ) async {
    try {
      final uri = Uri.parse(
        ApiConstants.teacherStudents,
      ).replace(queryParameters: {'schedule_id': scheduleId, 'date': date});

      debugPrint('TeacherService: Fetching students from $uri');

      final response = await http.get(uri);

      debugPrint(
        'TeacherService: Students Response Status: ${response.statusCode}',
      );
      debugPrint('TeacherService: Students Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' || result['success'] == true) {
          if (result['data'] != null) {
            return result['data'];
          }
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching students: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> submitAttendance(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.submitTeacherAttendance),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      debugPrint('TeacherService: submitting to ${response.request?.url}');
      debugPrint('TeacherService: payload: ${jsonEncode(data)}');
      debugPrint('TeacherService: Submit Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['status'] == 'success' || result['success'] == true,
          'message': result['message'] ?? 'Unknown error',
        };
      }
      return {
        'success': false,
        'message': 'HTTP Error: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('Error submitting attendance: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers({String search = ''}) async {
    try {
      final queryParams = <String, String>{};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}teacher/get_teachers.php',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('TeacherService: Fetching teachers from $uri');
      final response = await http.get(uri);

      debugPrint(
        'TeacherService: Teachers Response Status: ${response.statusCode}',
      );
      debugPrint('TeacherService: Teachers Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClassList({String search = ''}) async {
    try {
      final queryParams = <String, String>{};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final uri = Uri.parse(
        ApiConstants.getClasses,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('TeacherService: Fetching classes from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getClassDetail(String classId) async {
    try {
      final uri = Uri.parse(
        ApiConstants.getClassDetail,
      ).replace(queryParameters: {'class_id': classId});

      debugPrint('TeacherService: Fetching class detail from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching class detail: $e');
      return null;
    }
  }
}
