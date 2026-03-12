import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class GradingService {
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('user_id') ?? prefs.get('userId');
    return userId?.toString() ?? '0';
  }

  bool _isSuccess(dynamic result) {
    if (result == null) return false;
    return result['success'] == true || result['status'] == 'success';
  }

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
        if (_isSuccess(result) && result['data'] != null) {
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
      final userId = await _getUserId();

      final url = '${ApiConstants.gradingGetHistory}?teacher_id=$userId';
      debugPrint('GradingService: Fetching history from $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      debugPrint('GradingService: History Response Status: ${response.statusCode}');
      debugPrint('GradingService: History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (_isSuccess(result) && result['data'] != null) {
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
    if (assessmentId.isEmpty || assessmentId == 'null') {
      debugPrint('GradingService: assessmentId is empty');
      return null;
    }
    try {
      // Use manual concatenation for the simplest possible URL construction
      final url = '${ApiConstants.gradingGetDetail}?id=$assessmentId';
      debugPrint('GradingService: Fetching detail from $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      debugPrint(
        'GradingService: Detail Response Status: ${response.statusCode}',
      );
      debugPrint('GradingService: Detail Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (_isSuccess(result) && result['data'] != null) {
          return result['data'];
        }
      } else if (response.statusCode == 400) {
        // Log the exact error from the server if it's a 400
        debugPrint('GradingService: 400 Error Response: ${response.body}');
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
        if (_isSuccess(result) && result['data'] != null) {
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
        if (_isSuccess(result) &&
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
