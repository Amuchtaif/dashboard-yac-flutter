import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  Future<List<Assignment>> getAssignments(int userId, {String? status}) async {
    try {
      String url = "${ApiConstants.getAssignments}?user_id=$userId";
      if (status != null) {
        url += "&status=$status";
      }

      debugPrint("📋 FETCH ASSIGNMENTS: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      debugPrint(
        "📋 ASSIGNMENTS RESPONSE [${response.statusCode}]: ${response.body}",
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true || data['status'] == 'success') {
          final List<dynamic> list = data['data'] ?? [];
          debugPrint("📋 ASSIGNMENTS COUNT: ${list.length}");
          return list.map((item) => Assignment.fromJson(item)).toList();
        } else {
          debugPrint(
            "📋 ASSIGNMENTS API ERROR: ${data['message'] ?? data['status']}",
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint("ERROR FETCH ASSIGNMENTS: $e");
      return [];
    }
  }

  /// Fetch assignments created by the supervisor
  Future<List<Assignment>> getCreatedAssignments(int creatorId) async {
    try {
      String url = "${ApiConstants.getAssignments}?created_by=$creatorId";

      debugPrint("📋 FETCH CREATED ASSIGNMENTS: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      debugPrint(
        "📋 CREATED ASSIGNMENTS RESPONSE [${response.statusCode}]: ${response.body}",
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true || data['status'] == 'success') {
          final List<dynamic> list = data['data'] ?? [];
          debugPrint("📋 CREATED ASSIGNMENTS COUNT: ${list.length}");
          if (list.isNotEmpty) {
            debugPrint("📋 SAMPLE DATA KEYS: ${list.first.keys.toList()}");
          }
          return list.map((item) => Assignment.fromJson(item)).toList();
        } else {
          debugPrint(
            "📋 CREATED ASSIGNMENTS API ERROR: ${data['message'] ?? data['status']}",
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint("ERROR FETCH CREATED ASSIGNMENTS: $e");
      return [];
    }
  }

  Future<Assignment?> getDetail(int id) async {
    try {
      debugPrint("📋 FETCH DETAIL: ${ApiConstants.getAssignmentDetail}?id=$id");

      final response = await http.get(
        Uri.parse("${ApiConstants.getAssignmentDetail}?id=$id"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      debugPrint(
        "📋 DETAIL RESPONSE [${response.statusCode}]: ${response.body}",
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true || data['status'] == 'success') {
          return Assignment.fromJson(data['data']);
        } else {
          debugPrint(
            "📋 DETAIL API ERROR: ${data['message'] ?? data['status']}",
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint("ERROR FETCH ASSIGNMENT DETAIL: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> createAssignment({
    required String title,
    required String description,
    required String priority,
    required String dueDate,
    required int createdBy,
    required int assignedTo,
    String? specialInstruction,
    File? attachment,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.createAssignment),
      );

      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['priority'] = priority;
      request.fields['due_date'] = dueDate;
      request.fields['created_by'] = createdBy.toString();
      request.fields['assigned_to'] = assignedTo.toString();
      request.fields['special_instructions'] = specialInstruction ?? '';

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath('attachment', attachment.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Gagal membuat tugas'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateStatus(int taskId, String status) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateAssignmentStatus),
        headers: {'ngrok-skip-browser-warning': 'true'},
        body: {'task_id': taskId.toString(), 'status': status},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Gagal merubah status'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProgress(int taskId, int progress) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateAssignmentProgress),
        headers: {'ngrok-skip-browser-warning': 'true'},
        body: {'task_id': taskId.toString(), 'progress': progress.toString()},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Gagal merubah progress'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitReport({
    required int taskId,
    required String reportNotes,
    File? attachment,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.submitAssignmentReport),
      );

      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});
      request.fields['task_id'] = taskId.toString();
      request.fields['report_notes'] = reportNotes;

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath('attachment', attachment.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Gagal mengirim laporan'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch list of subordinates for a given supervisor
  Future<List<Map<String, dynamic>>> getSubordinates(int supervisorId) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.getSubordinates}?supervisor_id=$supervisorId",
        ),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          return list.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint("ERROR FETCH SUBORDINATES: $e");
      return [];
    }
  }
}
