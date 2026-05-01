import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meal_attendance_model.dart';

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

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_isSuccess(data)) {
          return (data['data'] as List)
              .map((item) => MealStudent.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
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

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_isSuccess(data)) {
          return (data['data'] as List)
              .map((item) => MealStudent.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
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
        'user_id': waliKelasId.toString(), // Add user_id as fallback/alternative
        'date': date,
        'meal_type': mealType,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_isSuccess(data)) {
          return (data['data'] as List)
              .map((item) => MealStudent.fromJson(item))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil data');
        }
      }
      throw Exception('Gagal menghubungi server');
    } catch (e) {
      rethrow;
    }
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
