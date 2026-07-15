import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/student_activity_model.dart';

class StudentActivityService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<int> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic rawUserId = prefs.get('user_id') ?? prefs.get('userId');
      if (rawUserId == null) return 0;
      if (rawUserId is int) return rawUserId;
      if (rawUserId is String) return int.tryParse(rawUserId) ?? 0;
      return 0;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return 0;
    }
  }

  // 1. Get Activity Types
  Future<List<ActivityType>> getActivityTypes() async {
    final url = Uri.parse('$baseUrl/mobile/activity-types');
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => ActivityType.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching activity types: $e');
    }
    return [];
  }

  // 2. Get Students (Scoped to user)
  Future<List<Map<String, dynamic>>> getStudents() async {
    final userId = await _getUserId();
    final url = Uri.parse('$baseUrl/mobile/students?user_id=$userId');
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
    return [];
  }

  // 3. Get Student Activities (Filtered and Paginated)
  Future<Map<String, dynamic>> getActivities({
    int? studentId,
    int? activityTypeId,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int limit = 15,
  }) async {
    final userId = await _getUserId();
    
    // Construct query parameters
    final queryParams = {
      'user_id': userId.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
      if (studentId != null) 'student_id': studentId.toString(),
      if (activityTypeId != null) 'activity_type_id': activityTypeId.toString(),
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('$baseUrl/mobile/student-activities').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(
        uri,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final list = (data['data'] as List? ?? [])
              .map((item) => StudentActivity.fromJson(item))
              .toList();
          return {
            'success': true,
            'data': list,
            'total': data['total'] ?? 0,
            'pages': data['pages'] ?? 1,
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching student activities: $e');
    }
    return {
      'success': false,
      'data': <StudentActivity>[],
      'total': 0,
      'pages': 1,
    };
  }

  // 4. Create Single Activity
  Future<Map<String, dynamic>> createActivity({
    required int activityTypeId,
    required int studentId,
    required String activityDate,
    required String status,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    final userId = await _getUserId();
    final url = Uri.parse('$baseUrl/mobile/student-activities?user_id=$userId');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'activity_type_id': activityTypeId,
          'student_id': studentId,
          'activity_date': activityDate,
          'status': status,
          'start_time': startTime,
          'end_time': endTime,
          'note': note,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error creating activity: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // 5. Create Batch Activities (Quick Checklist)
  Future<Map<String, dynamic>> createBatchActivity({
    required int activityTypeId,
    required String activityDate,
    required String status,
    required List<int> studentIds,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    final userId = await _getUserId();
    final url = Uri.parse('$baseUrl/mobile/student-activities/batch?user_id=$userId');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'activity_type_id': activityTypeId,
          'activity_date': activityDate,
          'status': status,
          'student_ids': studentIds,
          'start_time': startTime,
          'end_time': endTime,
          'note': note,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error creating batch activity: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // 6. Update Activity
  Future<Map<String, dynamic>> updateActivity({
    required int id,
    int? activityTypeId,
    int? studentId,
    String? activityDate,
    String? status,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    final userId = await _getUserId();
    final url = Uri.parse('$baseUrl/mobile/student-activities/$id?user_id=$userId');
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          if (activityTypeId != null) 'activity_type_id': activityTypeId,
          if (studentId != null) 'student_id': studentId,
          if (activityDate != null) 'activity_date': activityDate,
          if (status != null) 'status': status,
          'start_time': startTime,
          'end_time': endTime,
          'note': note,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error updating activity: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // 7. Delete Activity
  Future<Map<String, dynamic>> deleteActivity(int id) async {
    final userId = await _getUserId();
    final url = Uri.parse('$baseUrl/mobile/student-activities/$id?user_id=$userId');
    
    try {
      final response = await http.delete(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // 8. Upload Attachment
  Future<Map<String, dynamic>> uploadAttachment(int activityId, File file, {String caption = ''}) async {
    final userId = await _getUserId();
    final url = Uri.parse('$baseUrl/mobile/student-activities/$activityId/attachments');
    
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });
      request.fields['user_id'] = userId.toString();
      request.fields['caption'] = caption;
      
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // 9. Delete Attachment
  Future<Map<String, dynamic>> deleteAttachment(int activityId, int attachmentId) async {
    final userId = await _getUserId();
    final url = Uri.parse('$baseUrl/mobile/student-activities/$activityId/attachments/$attachmentId?user_id=$userId');
    
    try {
      final response = await http.delete(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
