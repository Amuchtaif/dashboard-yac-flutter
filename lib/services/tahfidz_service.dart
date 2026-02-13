import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TahfidzService {
  final String baseUrl = ApiConfig.baseUrl;

  // --- Students ---
  Future<List<dynamic>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/get_students.php"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
    }
    return [];
  }

  Future<List<dynamic>> getMyStudents(int? teacherId) async {
    if (teacherId == null) return [];
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/get_my_students.php?teacher_id=$teacherId"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching my students: $e");
    }
    return [];
  }

  Future<List<dynamic>> getTeachers() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/get_teachers.php"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching teachers: $e");
    }
    return [];
  }

  // --- Student Attendance ---
  Future<Map<String, dynamic>> submitStudentAttendance({
    required String date,
    required String session,
    required int? teacherId,
    required List<Map<String, dynamic>> students,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tahfidz/submit_student_attendance.php"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "date": date,
          "session": session,
          "teacher_id": teacherId,
          "students": students,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Server Error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<List<dynamic>> getStudentAttendanceHistory({
    String? date,
    String? studentId,
  }) async {
    try {
      String query = "";
      if (date != null) {
        query += "date=$date";
      }
      if (studentId != null) {
        query += "${query.isEmpty ? "" : "&"}student_id=$studentId";
      }

      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/get_student_attendance.php?$query"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching student attendance: $e");
    }
    return [];
  }

  // --- Teacher Attendance ---
  Future<Map<String, dynamic>> submitTeacherAttendance({
    required int teacherId,
    required String action, // 'check_in' or 'check_out'
    String? notes,
    String? time, // Pass device time
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tahfidz/submit_teacher_attendance.php"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "teacher_id": teacherId,
          "action": action,
          "notes": notes,
          "time": time,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        "success": false,
        "message": "Server error ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<List<dynamic>> getTeacherAttendanceHistory({
    String? date,
    int? teacherId,
  }) async {
    try {
      String query = "";
      if (date != null) {
        query += "date=$date";
      }
      if (teacherId != null) {
        query += "${query.isEmpty ? "" : "&"}teacher_id=$teacherId";
      }

      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/get_teacher_attendance.php?$query"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching teacher attendance: $e");
    }
    return [];
  }

  // --- Memorization (Setoran) ---
  Future<Map<String, dynamic>> submitMemorization(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tahfidz/submit_memorization.php"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        "success": false,
        "message": "Server error ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<List<dynamic>> getMemorizationHistory({
    int? teacherId,
    int? studentId,
    String? date,
  }) async {
    try {
      String query = "";
      if (teacherId != null) {
        query += "teacher_id=$teacherId";
      }
      if (studentId != null) {
        query += "${query.isEmpty ? "" : "&"}student_id=$studentId";
      }
      if (date != null) {
        query += "${query.isEmpty ? "" : "&"}date=$date";
      }

      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/get_memorization.php?$query"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching memorization history: $e");
    }
    return [];
  }

  // --- Assessment (Penilaian) ---
  Future<Map<String, dynamic>> submitAssessment(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tahfidz/submit_assessment.php"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Access-Control-Allow-Origin': '*',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        "success": false,
        "message": "Server error ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<List<dynamic>> getAssessmentHistory({
    int? teacherId,
    int? studentId,
    String? date,
    String? category,
  }) async {
    try {
      String query = "";
      if (teacherId != null) {
        query += "teacher_id=$teacherId";
      }
      if (studentId != null) {
        query += "${query.isEmpty ? "" : "&"}student_id=$studentId";
      }
      if (date != null) {
        query += "${query.isEmpty ? "" : "&"}date=$date";
      }
      if (category != null) {
        query += "${query.isEmpty ? "" : "&"}category=$category";
      }

      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/get_assessments.php?$query"),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching assessment history: $e");
    }
    return [];
  }
}
