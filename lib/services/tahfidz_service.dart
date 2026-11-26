import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../core/api_constants.dart';
import 'offline_sync_service.dart';

class TahfidzService {
  final String baseUrl = ApiConfig.baseUrl;

  // --- Students ---
  Future<List<dynamic>> getStudents() async {
    final offlineSync = OfflineSyncService();
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/tahfidz/get_students.php"))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List;
          await offlineSync.saveCache('tahfidz_all_students', list);
          return list;
        }
      }
    } catch (e) {
      debugPrint("Error fetching students (checking cache): $e");
    }

    // Fallback cache offline
    final cached = await offlineSync.getCache('tahfidz_all_students');
    if (cached != null && cached is List && cached.isNotEmpty) {
      return cached;
    }
    return [];
  }

  Future<List<dynamic>> getMyStudents(int? teacherId) async {
    final offlineSync = OfflineSyncService();
    int? effectiveId = teacherId;
    if (effectiveId == null) {
      final prefs = await SharedPreferences.getInstance();
      final dynamic raw = prefs.get('userId') ?? prefs.get('user_id');
      if (raw is int) {
        effectiveId = raw;
      } else if (raw is String) {
        effectiveId = int.tryParse(raw);
      }
    }

    final cacheKey =
        effectiveId != null
            ? 'tahfidz_students_$effectiveId'
            : 'tahfidz_students_unknown';

    try {
      final queryParam = effectiveId != null ? "?teacher_id=$effectiveId" : "";
      final response = await http
          .get(Uri.parse("${ApiConstants.tahfidzGetMyStudents}$queryParam"))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if ((data['success'] == true || data['status'] == 'success') &&
            data['data'] != null) {
          final list = data['data'] as List;
          if (effectiveId != null) {
            await offlineSync.saveCache(cacheKey, list);
          }
          await offlineSync.saveCache('tahfidz_students_latest', list);
          return list;
        }
      }
    } catch (e) {
      debugPrint("Error fetching my students (checking cache): $e");
    }

    // 1. Fallback cache spesifik pengampu
    if (effectiveId != null) {
      final cached = await offlineSync.getCache(cacheKey);
      if (cached != null && cached is List && cached.isNotEmpty) {
        debugPrint(
          "📦 Menggunakan cache lokal santri halaqoh (${cached.length} santri)",
        );
        return cached;
      }
    }

    // 2. Fallback cache santri halaqoh terbaru
    final cachedLatest = await offlineSync.getCache('tahfidz_students_latest');
    if (cachedLatest != null &&
        cachedLatest is List &&
        cachedLatest.isNotEmpty) {
      debugPrint(
        "📦 Menggunakan cache lokal santri halaqoh terbaru (${cachedLatest.length} santri)",
      );
      return cachedLatest;
    }

    // 3. Fallback cache seluruh santri tahfidz
    final cachedAll = await offlineSync.getCache('tahfidz_all_students');
    if (cachedAll != null && cachedAll is List && cachedAll.isNotEmpty) {
      debugPrint(
        "📦 Menggunakan fallback cache seluruh santri tahfidz (${cachedAll.length} santri)",
      );
      return cachedAll;
    }

    // 4. Fallback cache santri dari musyrif / meal jika tersedia
    final cachedMusyrif =
        await offlineSync.getCache('meal_students_musyrif_latest') ??
        await offlineSync.getCache('meal_students_latest');
    if (cachedMusyrif != null &&
        cachedMusyrif is List &&
        cachedMusyrif.isNotEmpty) {
      debugPrint(
        "📦 Menggunakan fallback cache santri musyrif/meal (${cachedMusyrif.length} santri)",
      );
      return cachedMusyrif;
    }

    return [];
  }

  Future<Map<String, dynamic>> addHalaqahMember(
    int teacherId,
    int studentId,
  ) async {
    final payload = {"teacher_id": teacherId, "student_id": studentId};
    final offlineSync = OfflineSyncService();

    // Perbarui cache lokal agar santri langsung muncul di daftar
    try {
      final cacheKey = 'tahfidz_students_$teacherId';
      List<dynamic> currentList = List.from(
        await offlineSync.getCache(cacheKey) ??
            await offlineSync.getCache('tahfidz_students_latest') ??
            [],
      );

      final allStudents = await offlineSync.getCache('tahfidz_all_students');
      Map<String, dynamic>? studentObj;
      if (allStudents != null && allStudents is List) {
        for (var s in allStudents) {
          if (s is Map &&
              (s['id']?.toString() == studentId.toString() ||
                  s['student_id']?.toString() == studentId.toString())) {
            studentObj = Map<String, dynamic>.from(s);
            break;
          }
        }
      }

      studentObj ??= {
        'id': studentId,
        'student_id': studentId,
        'nama_siswa': 'Santri #$studentId',
      };

      if (!currentList.any(
        (s) =>
            (s['id']?.toString() == studentId.toString()) ||
            (s['student_id']?.toString() == studentId.toString()),
      )) {
        currentList.add(studentObj);
        await offlineSync.saveCache(cacheKey, currentList);
        await offlineSync.saveCache('tahfidz_students_latest', currentList);
      }
    } catch (e) {
      debugPrint("Error updating local halaqah students on add: $e");
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.tahfidzAddMember),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("addHalaqahMember offline fallback: $e");
    }

    await offlineSync.enqueueTask(
      type: 'tahfidz_add_member',
      payload: payload,
      description: 'Tambah Santri #$studentId ke Halaqoh',
    );
    return {
      "success": true,
      "isOffline": true,
      "message": "Santri ditambahkan (Mode Offline).",
    };
  }

  Future<Map<String, dynamic>> removeHalaqahMember(
    int teacherId,
    int studentId,
  ) async {
    final payload = {"teacher_id": teacherId, "student_id": studentId};
    final offlineSync = OfflineSyncService();

    // Hapus dari cache lokal segera
    try {
      final cacheKey = 'tahfidz_students_$teacherId';
      List<dynamic> currentList = List.from(
        await offlineSync.getCache(cacheKey) ??
            await offlineSync.getCache('tahfidz_students_latest') ??
            [],
      );
      currentList.removeWhere(
        (s) =>
            (s['id']?.toString() == studentId.toString()) ||
            (s['student_id']?.toString() == studentId.toString()),
      );
      await offlineSync.saveCache(cacheKey, currentList);
      await offlineSync.saveCache('tahfidz_students_latest', currentList);
    } catch (e) {
      debugPrint("Error updating local halaqah students on remove: $e");
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.tahfidzRemoveMember),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("removeHalaqahMember offline fallback: $e");
    }

    await offlineSync.enqueueTask(
      type: 'tahfidz_remove_member',
      payload: payload,
      description: 'Hapus Santri #$studentId dari Halaqoh',
    );
    return {
      "success": true,
      "isOffline": true,
      "message": "Santri dihapus (Mode Offline).",
    };
  }

  Future<List<dynamic>> getTeachers() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/tahfidz/get_teachers.php"))
          .timeout(const Duration(seconds: 10));

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
    final payload = {
      "date": date,
      "session": session,
      "teacher_id": teacherId,
      "students": students,
    };

    // Selalu simpan ke cache lokal agar getStudentAttendanceHistory mengetahui presensi telah diisi
    if (teacherId != null) {
      final cacheKey =
          'tahfidz_student_attendance_${teacherId}_${session}_$date';
      final records =
          students
              .map(
                (s) => {
                  'student_id': s['student_id'],
                  'status': s['status'] ?? 'Hadir',
                },
              )
              .toList();
      await OfflineSyncService().saveCache(cacheKey, records);
    }

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/tahfidz/submit_student_attendance.php"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        await OfflineSyncService().enqueueTask(
          type: 'tahfidz_attendance',
          payload: payload,
          description: 'Presensi Tahfidz ($session - $date)',
        );
        return {
          "success": true,
          "isOffline": true,
          "message":
              "Presensi disimpan di HP (Mode Offline). Akan otomatis dikirim saat online.",
        };
      }
    } catch (e) {
      debugPrint(
        "Network error submitStudentAttendance, enqueuing offline: $e",
      );
      await OfflineSyncService().enqueueTask(
        type: 'tahfidz_attendance',
        payload: payload,
        description: 'Presensi Tahfidz ($session - $date)',
      );
      return {
        "success": true,
        "isOffline": true,
        "message":
            "Tersimpan di HP (Mode Offline). Akan disinkronkan otomatis saat online.",
      };
    }
  }

  Future<List<dynamic>> getStudentAttendanceHistory({
    String? date,
    String? studentId,
    String? session,
    int? groupId,
    int? teacherId,
  }) async {
    final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cacheKey =
        'tahfidz_student_attendance_${teacherId}_${session}_$targetDate';
    final offlineSync = OfflineSyncService();

    try {
      String query = "date=$targetDate";
      if (studentId != null) {
        query += "&student_id=$studentId";
      }
      if (session != null) {
        query += "&session=$session";
      }
      if (groupId != null) {
        query += "&group_id=$groupId";
      }
      if (teacherId != null) {
        query += "&teacher_id=$teacherId";
      }

      final response = await http
          .get(Uri.parse("$baseUrl/tahfidz/get_student_attendance.php?$query"))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List;
          await offlineSync.saveCache(cacheKey, list);
          return list;
        }
      }
    } catch (e) {
      debugPrint(
        "Error fetching student attendance (checking offline cache): $e",
      );
    }

    // Fallback cache presensi santri offline
    final cached = await offlineSync.getCache(cacheKey);
    if (cached != null && cached is List) {
      return cached;
    }

    return [];
  }

  Future<List<dynamic>> getHalaqahGroups() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/tahfidz/get_halaqah_groups.php"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching halaqah groups: $e");
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
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = time ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final payload = {
      "teacher_id": teacherId,
      "action": action,
      "notes": notes,
      "time": timeStr,
    };

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/tahfidz/submit_teacher_attendance.php"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _saveLocalTeacherSession(
            teacherId,
            action,
            notes,
            dateStr,
            timeStr,
          );
          return data;
        }
      }

      // Jika server mengembalikan non-200 atau gagal, simpan ke antrean offline
      await _enqueueTeacherAttendance(payload, action, notes);
      await _saveLocalTeacherSession(
        teacherId,
        action,
        notes,
        dateStr,
        timeStr,
      );
      return {
        "success": true,
        "isOffline": true,
        "message":
            action == 'check_in'
                ? "Halaqoh dibuka (Mode Offline). Presensi ustadz tersimpan lokal dan akan otomatis sinkron."
                : "Halaqoh ditutup (Mode Offline). Data tersimpan lokal dan akan otomatis sinkron.",
      };
    } catch (e) {
      debugPrint(
        "submitTeacherAttendance network error ($e), fallback to offline mode",
      );
      await _enqueueTeacherAttendance(payload, action, notes);
      await _saveLocalTeacherSession(
        teacherId,
        action,
        notes,
        dateStr,
        timeStr,
      );
      return {
        "success": true,
        "isOffline": true,
        "message":
            action == 'check_in'
                ? "Halaqoh dibuka (Mode Offline). Presensi ustadz tersimpan lokal dan akan otomatis sinkron."
                : "Halaqoh ditutup (Mode Offline). Data tersimpan lokal dan akan otomatis sinkron.",
      };
    }
  }

  Future<void> _enqueueTeacherAttendance(
    Map<String, dynamic> payload,
    String action,
    String? notes,
  ) async {
    final actionDesc = action == 'check_in' ? 'Buka Halaqoh' : 'Tutup Halaqoh';
    final notesDesc = notes != null ? ' ($notes)' : '';
    await OfflineSyncService().enqueueTask(
      type: 'tahfidz_teacher_attendance',
      payload: payload,
      description: '$actionDesc$notesDesc',
    );
  }

  Future<void> _saveLocalTeacherSession(
    int teacherId,
    String action,
    String? notes,
    String dateStr,
    String timeStr,
  ) async {
    final offlineSync = OfflineSyncService();
    final cacheKey = 'tahfidz_teacher_history_${teacherId}_$dateStr';
    final activeKey = 'tahfidz_active_session_$teacherId';

    List<dynamic> history = [];
    final cached = await offlineSync.getCache(cacheKey);
    if (cached != null && cached is List) {
      history = List.from(cached);
    }

    final simpleTime = timeStr.contains(' ') ? timeStr.split(' ')[1] : timeStr;

    if (action == 'check_in') {
      final newRecord = {
        "id": -DateTime.now().millisecondsSinceEpoch,
        "teacher_id": teacherId,
        "date": dateStr,
        "check_in_time": simpleTime,
        "check_out_time": null,
        "notes": notes ?? 'Pagi',
        "status": "approved",
        "is_offline": true,
      };
      // Gantikan sesi aktif lama atau tambahkan yang baru
      history.removeWhere(
        (h) =>
            h is Map &&
            (h['check_out_time'] == null || h['check_out_time'] == ""),
      );
      history.add(newRecord);
      await offlineSync.saveCache(cacheKey, history);

      await offlineSync.saveCache(activeKey, {
        "teacher_id": teacherId,
        "date": dateStr,
        "check_in_time": simpleTime,
        "check_out_time": null,
        "notes": notes ?? 'Pagi',
        "is_opened": true,
      });
    } else {
      // check_out: perbarui jam keluar
      bool updated = false;
      for (var record in history) {
        if (record is Map &&
            (record['check_out_time'] == null ||
                record['check_out_time'] == "")) {
          record['check_out_time'] = simpleTime;
          updated = true;
          break;
        }
      }
      if (!updated && history.isNotEmpty && history.last is Map) {
        history.last['check_out_time'] = simpleTime;
      }
      await offlineSync.saveCache(cacheKey, history);

      await offlineSync.saveCache(activeKey, {
        "teacher_id": teacherId,
        "date": dateStr,
        "check_in_time": simpleTime,
        "check_out_time": simpleTime,
        "notes": notes ?? 'Pagi',
        "is_opened": false,
      });
    }
  }

  Future<List<dynamic>> getTeacherAttendanceHistory({
    String? date,
    int? teacherId,
  }) async {
    final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cacheKey = 'tahfidz_teacher_history_${teacherId}_$targetDate';
    final offlineSync = OfflineSyncService();

    try {
      String query = "";
      if (date != null) {
        query += "date=$date";
      }
      if (teacherId != null) {
        query += "${query.isEmpty ? "" : "&"}teacher_id=$teacherId";
      }

      final response = await http
          .get(Uri.parse("$baseUrl/tahfidz/get_teacher_attendance.php?$query"))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List;
          if (teacherId != null) {
            await offlineSync.saveCache(cacheKey, list);
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint(
        "Error fetching teacher attendance (fallback to offline cache): $e",
      );
    }

    // Fallback cache offline
    if (teacherId != null) {
      final cached = await offlineSync.getCache(cacheKey);
      if (cached != null && cached is List && cached.isNotEmpty) {
        return cached;
      }

      final active = await offlineSync.getCache(
        'tahfidz_active_session_$teacherId',
      );
      if (active != null && active is Map) {
        if (active['date'] == targetDate && active['is_opened'] == true) {
          return [active];
        }
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> verifyTeacherAttendance({
    required int attendanceId,
    required String action, // 'approve' or 'reject'
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/tahfidz/verify_teacher_attendance.php"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"id": attendanceId, "action": action}),
          )
          .timeout(const Duration(seconds: 10));
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

  // --- Memorization (Setoran) ---
  Future<Map<String, dynamic>> submitMemorization(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/tahfidz/submit_memorization.php"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        await OfflineSyncService().enqueueTask(
          type: 'tahfidz_setoran',
          payload: data,
          description: 'Setoran Santri #${data['student_id']}',
        );
        return {
          "success": true,
          "isOffline": true,
          "message":
              "Setoran disimpan lokal (Server Sibuk). Akan disinkronkan otomatis.",
        };
      }
    } catch (e) {
      debugPrint("Network error submitMemorization, enqueuing offline: $e");
      await OfflineSyncService().enqueueTask(
        type: 'tahfidz_setoran',
        payload: data,
        description: 'Setoran Santri #${data['student_id']}',
      );
      return {
        "success": true,
        "isOffline": true,
        "message":
            "Setoran tersimpan di HP (Mode Offline). Akan otomatis terkirim saat online.",
      };
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

      final response = await http
          .get(Uri.parse("$baseUrl/tahfidz/get_memorization.php?$query"))
          .timeout(const Duration(seconds: 10));

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
      final response = await http
          .post(
            Uri.parse("$baseUrl/tahfidz/submit_assessment.php"),
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
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

      final response = await http
          .get(Uri.parse("$baseUrl/tahfidz/get_assessments.php?$query"))
          .timeout(const Duration(seconds: 10));

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

  Future<List<dynamic>> getAssessmentTypes() async {
    try {
      debugPrint(
        "TahfidzService: Fetching types from ${ApiConstants.tahfidzGetAssessmentTypes}",
      );
      final response = await http
          .get(Uri.parse(ApiConstants.tahfidzGetAssessmentTypes))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('<')) {
          debugPrint(
            "TahfidzService: Endpoint returned HTML (Check for PHP errors)",
          );
          return [];
        }

        final dynamic data = jsonDecode(body);
        if (data is List) {
          return data;
        } else if (data is Map) {
          if (data['success'] == true || data['status'] == 'success') {
            return data['data'] ?? data['types'] ?? data['list'] ?? [];
          }
          return data['data'] ?? [];
        }
      } else {
        debugPrint("TahfidzService: HTTP Error ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("TahfidzService: Format or Network Error: $e");
    }

    return [];
  }

  Future<Map<String, dynamic>> deleteAssessment(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.tahfidzDeleteAssessment),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"id": id}),
          )
          .timeout(const Duration(seconds: 10));

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
}
