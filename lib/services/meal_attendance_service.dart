import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meal_attendance_model.dart';

class MealAttendanceService {
  static const String endpoint = "${ApiConfig.baseUrl}/meal_attendance";

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
        if (data['success'] == true) {
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
        if (data['success'] == true) {
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
        return data['success'] == true;
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
        return data['success'] == true;
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
        return data['success'] == true;
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
    int? roomId,
  }) async {
    final url = Uri.parse("$endpoint/get_stats.php").replace(
      queryParameters: {
        'date': date,
        'meal_type': mealType,
        if (musyrifId != null) 'musyrif_id': musyrifId.toString(),
        if (roomId != null) 'room_id': roomId.toString(),
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true) {
          return MealStats.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
