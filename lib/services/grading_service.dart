import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class GradingService {
  Future<List<Map<String, dynamic>>> getTeachingInfo(String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}teacher/get_my_teaching_info.php?employee_id=$employeeId',
        ),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching teaching info: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAssessmentHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId');

      final response = await http.get(
        Uri.parse('${ApiConstants.gradingGetHistory}?teacher_id=$userId'),
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
      debugPrint('Error fetching assessment history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAssessmentDetail(String assessmentId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.gradingGetDetail}?assessment_id=$assessmentId',
        ),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching assessment detail: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAssessmentTypes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.gradingGetTypes),
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
      debugPrint('Error fetching assessment types: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass(String classId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}get_class_detail.php?class_id=$classId',
        ),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true &&
            result['data'] != null &&
            result['data']['students'] != null) {
          return List<Map<String, dynamic>>.from(result['data']['students']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching students by class: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> submitGrading(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.gradingSubmit),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        // Force success true if status is 201 Created but API forgot to send success:true
        if (response.statusCode == 201 && result['success'] == null) {
          result['success'] = true;
        }
        return result;
      }

      // Attempt to parse body even on other status codes if it contains error info
      try {
        final result = jsonDecode(response.body);
        if (result['success'] == true) return result;
        return result;
      } catch (_) {
        return {
          'success': false,
          'message': 'HTTP Error ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error submitting grading: $e');
      return {'success': false, 'message': 'Connection Error: $e'};
    }
  }
}
