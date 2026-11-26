import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import 'offline_sync_service.dart';

class TeacherService {
  Future<List<Map<String, dynamic>>> getDailySchedule(String day, {String? date}) async {
    final offlineSync = OfflineSyncService();
    String employeeId = '0';

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUserId = prefs.get('user_id') ?? prefs.get('userId');
      if (rawUserId != null) {
        employeeId = rawUserId.toString();
      }

      final cacheKey = 'teacher_schedule_${employeeId}_$day';
      final Map<String, String> queryParams = {
        'employee_id': employeeId,
        'day': day,
      };
      if (date != null) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse(
        ApiConstants.teacherSchedule,
      ).replace(queryParameters: queryParams);

      debugPrint('TeacherService: Fetching schedule from $uri');

      try {
        final response =
            await http.get(uri).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success' || result['success'] == true) {
            if (result['data'] != null) {
              final list = List<Map<String, dynamic>>.from(result['data']);
              await offlineSync.saveCache(cacheKey, list);
              await offlineSync.saveCache(
                  'teacher_schedule_${employeeId}_latest', list);
              return _overlayOfflineScheduleTasks(list, date);
            }
          }
        }
      } catch (e) {
        debugPrint('TeacherService error (trying cache): $e');
      }

      // Fallback cache offline
      final cached = await offlineSync.getCache(cacheKey) ??
          await offlineSync.getCache('teacher_schedule_${employeeId}_latest');
      if (cached != null && cached is List) {
        debugPrint('📦 Menggunakan cache lokal untuk jadwal mengajar ($day)');
        final list = List<Map<String, dynamic>>.from(
            cached.map((e) => Map<String, dynamic>.from(e)));
        return _overlayOfflineScheduleTasks(list, date);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _overlayOfflineScheduleTasks(
      List<Map<String, dynamic>> schedules, String? date) {
    final offlineSync = OfflineSyncService();
    if (offlineSync.queue.isEmpty) return schedules;

    final updated = List<Map<String, dynamic>>.from(schedules);
    for (final task in offlineSync.queue) {
      if (task.type == 'teacher_attendance') {
        final payload = task.payload;
        final scheduleId = payload['schedule_id']?.toString();
        final taskDate = payload['date']?.toString();

        if (date == null || taskDate == null || taskDate == date) {
          for (int i = 0; i < updated.length; i++) {
            if (updated[i]['id']?.toString() == scheduleId) {
              updated[i] = Map<String, dynamic>.from(updated[i]);
              updated[i]['has_attendance'] = 1;
              if (payload['topic'] != null &&
                  payload['topic'].toString().trim().isNotEmpty) {
                updated[i]['is_journal_filled'] = 1;
              }
            }
          }
        }
      }
    }
    return updated;
  }

  Future<Map<String, dynamic>> getStudentsBySchedule(
    String scheduleId,
    String date,
  ) async {
    final offlineSync = OfflineSyncService();
    final cacheKey = 'schedule_students_${scheduleId}_$date';
    final fallbackKey = 'schedule_students_${scheduleId}_latest';

    try {
      final uri = Uri.parse(
        ApiConstants.teacherStudents,
      ).replace(queryParameters: {'schedule_id': scheduleId, 'date': date});

      debugPrint('TeacherService: Fetching students from $uri');

      try {
        final response =
            await http.get(uri).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success' || result['success'] == true) {
            if (result['data'] != null) {
              final data = Map<String, dynamic>.from(result['data']);
              await offlineSync.saveCache(cacheKey, data);
              await offlineSync.saveCache(fallbackKey, data);
              return _overlayOfflineStudentTasks(data, scheduleId, date);
            }
          }
        }
      } catch (e) {
        debugPrint('TeacherService getStudents error (trying cache): $e');
      }

      // Fallback cache offline
      final cached = await offlineSync.getCache(cacheKey) ??
          await offlineSync.getCache(fallbackKey);
      if (cached != null && cached is Map<String, dynamic>) {
        debugPrint('📦 Menggunakan cache lokal untuk santri jadwal #$scheduleId');
        final data = Map<String, dynamic>.from(cached);
        return _overlayOfflineStudentTasks(data, scheduleId, date);
      }

      return {};
    } catch (e) {
      debugPrint('Error fetching students: $e');
      return {};
    }
  }

  Map<String, dynamic> _overlayOfflineStudentTasks(
      Map<String, dynamic> data, String scheduleId, String date) {
    final offlineSync = OfflineSyncService();
    if (offlineSync.queue.isEmpty) return data;

    final updatedData = Map<String, dynamic>.from(data);
    for (final task in offlineSync.queue) {
      if (task.type == 'teacher_attendance') {
        final payload = task.payload;
        if (payload['schedule_id']?.toString() == scheduleId &&
            payload['date']?.toString() == date) {
          // Overlay attendances
          if (payload['attendances'] != null &&
              updatedData['students'] != null &&
              updatedData['students'] is List) {
            final attendances = (payload['attendances'] as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            final Map<String, String> statusMap = {
              for (var att in attendances)
                att['student_id'].toString(): att['status'].toString()
            };

            final studentsList =
                List<Map<String, dynamic>>.from(updatedData['students']);
            for (int i = 0; i < studentsList.length; i++) {
              final stId = studentsList[i]['student_id']?.toString() ??
                  studentsList[i]['id']?.toString() ??
                  '';
              if (statusMap.containsKey(stId)) {
                studentsList[i] = Map<String, dynamic>.from(studentsList[i]);
                studentsList[i]['status'] = statusMap[stId];
              }
            }
            updatedData['students'] = studentsList;
          }

          // Overlay journal
          if (payload['topic'] != null || payload['notes'] != null) {
            final journal = Map<String, dynamic>.from(
                updatedData['journal'] as Map<String, dynamic>? ?? {});
            if (payload['topic'] != null) journal['topic'] = payload['topic'];
            if (payload['notes'] != null) journal['notes'] = payload['notes'];
            updatedData['journal'] = journal;
          }
        }
      }
    }
    return updatedData;
  }

  Future<Map<String, dynamic>> submitAttendance(
    Map<String, dynamic> data,
  ) async {
    final offlineSync = OfflineSyncService();
    final scheduleId = data['schedule_id']?.toString() ?? '';
    final date = data['date']?.toString() ?? '';

    // Update local cache immediately
    try {
      final cacheKey = 'schedule_students_${scheduleId}_$date';
      final cached = await offlineSync.getCache(cacheKey) ??
          await offlineSync.getCache('schedule_students_${scheduleId}_latest');
      if (cached != null && cached is Map<String, dynamic>) {
        final updatedData = _overlayOfflineStudentTasks(
            cached, scheduleId, date);
        await offlineSync.saveCache(cacheKey, updatedData);
        await offlineSync.saveCache(
            'schedule_students_${scheduleId}_latest', updatedData);
      }
    } catch (_) {}

    try {
      debugPrint('TeacherService: submitting attendance to server...');
      final response = await http.post(
        Uri.parse(ApiConstants.submitTeacherAttendance),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' || result['success'] == true) {
          return {
            'success': true,
            'isOffline': false,
            'message': result['message'] ?? 'Absensi berhasil disimpan',
          };
        }
      }

      // If server returned non-200 or failure, enqueue offline
      await offlineSync.enqueueTask(
        type: 'teacher_attendance',
        payload: data,
        description:
            'Jurnal & Absensi Mengajar Jadwal #$scheduleId ($date)',
      );
      return {
        'success': true,
        'isOffline': true,
        'message':
            'Disimpan lokal di perangkat (Server Sibuk). Akan otomatis disinkronkan saat server pulih.',
      };
    } catch (e) {
      debugPrint(
          'Network error submitting teacher attendance, enqueuing offline: $e');
      await offlineSync.enqueueTask(
        type: 'teacher_attendance',
        payload: data,
        description:
            'Jurnal & Absensi Mengajar Jadwal #$scheduleId ($date)',
      );
      return {
        'success': true,
        'isOffline': true,
        'message':
            'Tersimpan di HP (Mode Offline). Akan otomatis terkirim saat sinyal kembali.',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers({String search = ''}) async {
    try {
      final queryParams = <String, String>{};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}teacher/get_teachers.php',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('TeacherService: Fetching teachers from $uri');
      final response = await http.get(uri);

      debugPrint(
        'TeacherService: Teachers Response Status: ${response.statusCode}',
      );
      debugPrint('TeacherService: Teachers Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClassList({
    String search = '',
    String? teacherId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (teacherId != null) {
        queryParams['teacher_id'] = teacherId;
      }
      final uri = Uri.parse(
        ApiConstants.getClasses,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('TeacherService: Fetching classes from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getClassDetail(String classId) async {
    try {
      final uri = Uri.parse(
        ApiConstants.getClassDetail,
      ).replace(queryParameters: {'class_id': classId});

      debugPrint('TeacherService: Fetching class detail from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching class detail: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSubjectList({
    String search = '',
    String category = '',
    String? teacherId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search.isNotEmpty) queryParams['search'] = search;
      if (category.isNotEmpty && category != 'Semua') {
        queryParams['category'] = category;
      }
      if (teacherId != null) {
        queryParams['teacher_id'] = teacherId;
      }

      final uri = Uri.parse(
        ApiConstants.getSubjects,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('TeacherService: Fetching subjects from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAcademicCalendar(int year) async {
    try {
      final uri = Uri.parse(
        ApiConstants.getCalendar,
      ).replace(queryParameters: {'year': year.toString()});

      debugPrint('TeacherService: Fetching calendar from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching calendar: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecap({
    String? unit,
    String? classId,
    String? date,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (unit != null) {
        queryParams['unit'] = unit;
      }
      if (classId != null) {
        queryParams['class_id'] = classId;
      }
      if (date != null) {
        queryParams['date'] = date;
      }
      final uri = Uri.parse(
        ApiConstants.getAttendanceRecap,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      debugPrint('TeacherService: Fetching attendance recap from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching attendance recap: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTeacherTeachingInfo(String teacherId) async {
    try {
      final uri = Uri.parse(
        ApiConstants.teacherTeachingInfo,
      ).replace(queryParameters: {'employee_id': teacherId});

      debugPrint('TeacherService: Fetching teaching info from $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // get_my_teaching_info.php returns {"status": "success", "data": [...]}
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
}
