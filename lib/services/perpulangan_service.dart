import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/perpulangan_model.dart';
import '../core/api_constants.dart';
import 'offline_sync_service.dart';

class PerpulanganService {
  Future<List<PerpulanganPermit>> getActivePermits({
    String search = '',
    int? supervisorId,
  }) async {
    try {
      int? finalSupervisorId = supervisorId;
      if (finalSupervisorId == null) {
        final prefs = await SharedPreferences.getInstance();
        final rawId = prefs.get('userId') ?? prefs.get('user_id');
        finalSupervisorId =
            rawId != null ? int.tryParse(rawId.toString()) : null;
      }

      final url = Uri.parse(
        '${ApiConstants.perpulanganGetActive}?search=$search&user_id=${finalSupervisorId ?? ""}',
      );
      final response = await http.get(
        url,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          if (search.isEmpty) {
            await OfflineSyncService()
                .saveCache('perpulangan_active_permits_latest', list);
          }
          return list.map((json) => PerpulanganPermit.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetch active permits: $e');
    }

    final cached = await OfflineSyncService()
        .getCache('perpulangan_active_permits_latest');
    if (cached != null && cached is List) {
      return cached.map((json) => PerpulanganPermit.fromJson(json)).toList();
    }

    return [];
  }

  Future<PerpulanganStats?> getStats({int? supervisorId}) async {
    try {
      int? finalSupervisorId = supervisorId;
      if (finalSupervisorId == null) {
        final prefs = await SharedPreferences.getInstance();
        final rawId = prefs.get('userId') ?? prefs.get('user_id');
        finalSupervisorId =
            rawId != null ? int.tryParse(rawId.toString()) : null;
      }

      final url = Uri.parse(
        '${ApiConstants.perpulanganGetStats}?user_id=${finalSupervisorId ?? ""}',
      );
      final response = await http.get(
        url,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          await OfflineSyncService()
              .saveCache('perpulangan_stats_latest', data['data']);
          return PerpulanganStats.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching perpulangan stats: $e');
    }

    final cached =
        await OfflineSyncService().getCache('perpulangan_stats_latest');
    if (cached != null && cached is Map<String, dynamic>) {
      return PerpulanganStats.fromJson(cached);
    }

    return null;
  }

  Future<List<PerpulanganStudent>> getStudents({
    required int roomId,
    int? supervisorId,
  }) async {
    try {
      int? finalSupervisorId = supervisorId;
      if (finalSupervisorId == null) {
        final prefs = await SharedPreferences.getInstance();
        finalSupervisorId = prefs.getInt('userId');
      }

      final url = Uri.parse(
        '${ApiConstants.perpulanganGetStudents}?room_id=$roomId&supervisor_id=${finalSupervisorId ?? ""}',
      );
      debugPrint('🔍 Fetching Students: $url');
      final response = await http.get(
        url,
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          debugPrint('✅ Fetched ${list.length} students.');
          return list.map((json) => PerpulanganStudent.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching students: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> submitPermit({
    required int studentId,
    required String category,
    required String reason,
    required String startDate,
    required String endDate,
    int? musrifId,
  }) async {
    try {
      int? finalMusrifId = musrifId;
      if (finalMusrifId == null) {
        final prefs = await SharedPreferences.getInstance();
        finalMusrifId = prefs.getInt('userId');
      }

      final payload = {
        "student_id": studentId,
        "musrif_id": finalMusrifId,
        "category": category,
        "reason": reason,
        "start_date": startDate,
        "end_date": endDate,
      };

      final response = await http.post(
        Uri.parse(ApiConstants.perpulanganSubmit),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<Map<String, dynamic>> updateStatus(int permitId, String status) async {
    try {
      final payload = {"permit_id": permitId, "status": status};
      final response = await http.post(
        Uri.parse(ApiConstants.perpulanganUpdateStatus),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<List<BoardingHoliday>> getHolidays() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.boardingGetHolidays),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((json) => BoardingHoliday.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetch holidays: $e');
    }
    return [];
  }
}
