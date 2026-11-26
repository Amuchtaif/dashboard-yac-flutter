import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meal_attendance_model.dart';
import 'offline_sync_service.dart';

class MealAttendanceService {
  static const String endpoint = "${ApiConfig.baseUrl}/meal_attendance";

  static bool _isSuccess(dynamic data) {
    if (data == null) return false;
    final success = data['success'];
    final status = data['status'];
    
    // Check various ways the backend might indicate success
    if (success == true || success == 'true' || success == 1 || success == '1') return true;
    if (status == 'success' || status == true || status == 'true' || status == 1 || status == '1') return true;
    
    return false;
  }

  static List<MealStudent> _applyPendingOfflineTasks(
    List<MealStudent> list,
    String date,
    String mealType,
  ) {
    final offlineSync = OfflineSyncService();
    if (offlineSync.queue.isEmpty) return list;

    final updated = List<MealStudent>.from(list);
    for (final task in offlineSync.queue) {
      if (task.type == 'meal_scan') {
        final payload = task.payload;
        if (payload['meal_type']?.toString().toLowerCase() ==
            mealType.toLowerCase()) {
          final studentId =
              int.tryParse(payload['student_id']?.toString() ?? '0');
          for (int i = 0; i < updated.length; i++) {
            if (updated[i].id == studentId && updated[i].attendanceId == null) {
              updated[i] = updated[i].copyWith(
                attendanceId: -1,
                checkTime: 'Offline',
              );
            }
          }
        }
      } else if (task.type == 'meal_bulk') {
        final payload = task.payload;
        if (payload['date'] == date &&
            payload['meal_type']?.toString().toLowerCase() ==
                mealType.toLowerCase()) {
          final studentIds = (payload['student_ids'] as List<dynamic>?)
                  ?.map((id) => int.tryParse(id.toString()) ?? 0)
                  .toSet() ??
              {};
          for (int i = 0; i < updated.length; i++) {
            if (studentIds.contains(updated[i].id) &&
                updated[i].attendanceId == null) {
              updated[i] = updated[i].copyWith(
                attendanceId: -1,
                checkTime: 'Offline',
              );
            }
          }
        }
      }
    }
    return updated;
  }

  static Future<List<MealStudent>> getStudents({
    required String date,
    required String mealType,
    int? gradeId,
    int? roomId,
  }) async {
    final url = Uri.parse("$endpoint/get_students_list.php").replace(
      queryParameters: {
        'date': date,
        'meal_type': mealType,
        if (gradeId != null) 'grade_id': gradeId.toString(),
        if (roomId != null) 'room_id': roomId.toString(),
      },
    );

    final cacheKey = 'meal_students_${mealType}_$date';
    final offlineSync = OfflineSyncService();

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_isSuccess(data)) {
          final list = data['data'] as List;
          await offlineSync.saveCache(cacheKey, list);
          await offlineSync.saveCache('meal_students_latest', list);
          final studentList =
              list.map((item) => MealStudent.fromJson(item)).toList();
          return _applyPendingOfflineTasks(studentList, date, mealType);
        }
      }
    } catch (e) {
      debugPrint('Error fetching meal students (trying cache): $e');
    }

    // Fallback cache offline
    final cached = await offlineSync.getCache(cacheKey) ??
        await offlineSync.getCache('meal_students_latest');
    if (cached != null && cached is List) {
      debugPrint('📦 Menggunakan cache lokal untuk absensi makan ($mealType)');
      final studentList =
          cached.map((item) => MealStudent.fromJson(item)).toList();
      return _applyPendingOfflineTasks(studentList, date, mealType);
    }

    return [];
  }

  static Future<List<MealStudent>> getStudentsByMusyrif({
    required int musyrifId,
    required String date,
    required String mealType,
  }) async {
    final url = Uri.parse("$endpoint/get_students_by_musyrif.php").replace(
      queryParameters: {
        'musyrif_id': musyrifId.toString(),
        'date': date,
        'meal_type': mealType,
      },
    );

    final cacheKey = 'meal_students_musyrif_${musyrifId}_${mealType}_$date';
    final offlineSync = OfflineSyncService();

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_isSuccess(data)) {
          final list = data['data'] as List;
          await offlineSync.saveCache(cacheKey, list);
          await offlineSync.saveCache('meal_students_musyrif_latest', list);
          final studentList =
              list.map((item) => MealStudent.fromJson(item)).toList();
          return _applyPendingOfflineTasks(studentList, date, mealType);
        }
      }
    } catch (e) {
      debugPrint('Error fetching meal students by musyrif (trying cache): $e');
    }

    // Fallback cache offline
    final cached = await offlineSync.getCache(cacheKey) ??
        await offlineSync.getCache('meal_students_musyrif_latest');
    if (cached != null && cached is List) {
      debugPrint('📦 Menggunakan cache lokal untuk musyrif ($mealType)');
      final studentList =
          cached.map((item) => MealStudent.fromJson(item)).toList();
      return _applyPendingOfflineTasks(studentList, date, mealType);
    }

    return [];
  }

  static Future<List<MealStudent>> getStudentsByWaliKelas({
    required int waliKelasId,
    required String date,
    required String mealType,
  }) async {
    // Some backends use 'user_id' instead of 'wali_kelas_id' for consistency
    final url = Uri.parse("$endpoint/get_students_by_wali_kelas.php").replace(
      queryParameters: {
        'wali_kelas_id': waliKelasId.toString(),
        'user_id': waliKelasId.toString(),
        'date': date,
        'meal_type': mealType,
      },
    );

    final cacheKey = 'meal_students_wali_${waliKelasId}_${mealType}_$date';
    final offlineSync = OfflineSyncService();

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_isSuccess(data)) {
          final list = data['data'] as List;
          await offlineSync.saveCache(cacheKey, list);
          await offlineSync.saveCache('meal_students_wali_latest', list);
          final studentList =
              list.map((item) => MealStudent.fromJson(item)).toList();
          return _applyPendingOfflineTasks(studentList, date, mealType);
        }
      }
    } catch (e) {
      debugPrint('Error fetching meal students by wali kelas (trying cache): $e');
    }

    // Fallback cache offline
    final cached = await offlineSync.getCache(cacheKey) ??
        await offlineSync.getCache('meal_students_wali_latest') ??
        await offlineSync.getCache('meal_students_latest');
    if (cached != null && cached is List) {
      debugPrint('📦 Menggunakan cache lokal untuk wali kelas ($mealType)');
      final studentList =
          cached.map((item) => MealStudent.fromJson(item)).toList();
      return _applyPendingOfflineTasks(studentList, date, mealType);
    }

    return [];
  }

  static Future<bool> markAsEaten({
    required int studentId,
    required String mealType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$endpoint/scan.php"),
        body: json.encode({'student_id': studentId, 'meal_type': mealType}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _isSuccess(data);
      } else {
        // Server status non-200, enqueue offline
        await OfflineSyncService().enqueueTask(
          type: 'meal_scan',
          payload: {'student_id': studentId, 'meal_type': mealType},
          description: 'Makan $mealType: Santri #$studentId',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Network error marking meal, enqueuing offline task: $e');
      // Simpan di antrean offline saat koneksi putus
      await OfflineSyncService().enqueueTask(
        type: 'meal_scan',
        payload: {'student_id': studentId, 'meal_type': mealType},
        description: 'Makan $mealType: Santri #$studentId',
      );
      return true; // Kembalikan true agar UI segera terupdate
    }
  }

  static Future<bool> saveBulk({
    required String date,
    required String mealType,
    required List<int> studentIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$endpoint/save_bulk.php"),
        body: json.encode({
          'date': date,
          'meal_type': mealType,
          'student_ids': studentIds,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _isSuccess(data);
      } else {
        await OfflineSyncService().enqueueTask(
          type: 'meal_bulk',
          payload: {'date': date, 'meal_type': mealType, 'student_ids': studentIds},
          description: 'Makan Massal $mealType (${studentIds.length} Santri)',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Network error saveBulk, enqueuing offline task: $e');
      await OfflineSyncService().enqueueTask(
        type: 'meal_bulk',
        payload: {'date': date, 'meal_type': mealType, 'student_ids': studentIds},
        description: 'Makan Massal $mealType (${studentIds.length} Santri)',
      );
      return true;
    }
  }

  static Future<bool> unmarkEaten({required int attendanceId}) async {
    try {
      final response = await http.post(
        Uri.parse("$endpoint/delete.php"),
        body: json.encode({'id': attendanceId}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _isSuccess(data);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<MealStats?> getStats({
    required String date,
    required String mealType,
    int? musyrifId,
    int? waliKelasId,
    int? roomId,
  }) async {
    final url = Uri.parse("$endpoint/get_stats.php").replace(
      queryParameters: {
        'date': date,
        'meal_type': mealType,
        if (musyrifId != null) 'musyrif_id': musyrifId.toString(),
        if (waliKelasId != null) ...{
          'wali_kelas_id': waliKelasId.toString(),
          'user_id': waliKelasId.toString(), // Add user_id as fallback/alternative
        },
        if (roomId != null) 'room_id': roomId.toString(),
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && _isSuccess(data)) {
          return MealStats.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
