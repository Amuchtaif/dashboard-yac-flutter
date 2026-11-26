import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import '../core/api_constants.dart';
import 'notification_service.dart';

/// Model untuk tugas antrean offline yang menunggu sinkronisasi
class OfflineTask {
  final String id;
  final String type; // 'asrama_attendance', 'meal_scan', 'meal_bulk', 'tahfidz_setoran', 'tahfidz_attendance'
  final Map<String, dynamic> payload;
  final String description;
  final DateTime createdAt;
  int retryCount;

  OfflineTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.description,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory OfflineTask.fromJson(Map<String, dynamic> json) => OfflineTask(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
        description: json['description'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
        retryCount: json['retry_count'] ?? 0,
      );
}

/// Service utama untuk Offline-First Caching & Sinkronisasi Otomatis
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final List<OfflineTask> _queue = [];
  bool _isSyncing = false;
  bool _isInitialized = false;

  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final StreamController<String> _syncEventController =
      StreamController<String>.broadcast();
  Stream<String> get syncEventStream => _syncEventController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  List<OfflineTask> get queue => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get isSyncing => _isSyncing;

  /// Inisialisasi service: load antrean dari penyimpanan dan dengarkan konektivitas
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadQueue();

    // Listen konektivitas untuk auto-sync saat online
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);
      if (hasConnection && _queue.isNotEmpty && !_isSyncing) {
        debugPrint(
            '🔄 OfflineSyncService: Koneksi pulih, memulai auto-sync ${_queue.length} antrean...');
        syncAll();
      }
    });
  }

  // ==========================================
  // CACHE PERSISTENCE (Master Data)
  // ==========================================

  /// Simpan master data ke cache lokal (SharedPreferences)
  Future<void> saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_cache_$key', jsonEncode(data));
      await prefs.setString(
          'offline_cache_time_$key', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Error saving cache for $key: $e');
    }
  }

  /// Ambil master data dari cache lokal
  Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_cache_$key');
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str);
      }
    } catch (e) {
      debugPrint('⚠️ Error loading cache for $key: $e');
    }
    return null;
  }

  /// Ambil waktu cache terakhir
  Future<DateTime?> getCacheTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('offline_cache_time_$key');
      if (str != null) return DateTime.tryParse(str);
    } catch (_) {}
    return null;
  }

  // ==========================================
  // OFFLINE QUEUE MANAGEMENT
  // ==========================================

  /// Tambahkan tugas ke antrean offline
  Future<void> enqueueTask({
    required String type,
    required Map<String, dynamic> payload,
    required String description,
  }) async {
    final task = OfflineTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      type: type,
      payload: payload,
      description: description,
    );

    _queue.add(task);
    pendingCountNotifier.value = _queue.length;
    await _saveQueue();

    debugPrint('📥 Enqueued offline task: $description (Total: ${_queue.length})');
  }

  /// Hapus tugas dari antrean
  Future<void> removeTask(String taskId) async {
    _queue.removeWhere((t) => t.id == taskId);
    pendingCountNotifier.value = _queue.length;
    await _saveQueue();
  }

  /// Bersihkan seluruh antrean
  Future<void> clearQueue() async {
    _queue.clear();
    pendingCountNotifier.value = 0;
    await _saveQueue();
  }

  // ==========================================
  // SYNCHRONIZATION ENGINE
  // ==========================================

  /// Sinkronkan semua data dalam antrean ke server
  Future<Map<String, dynamic>> syncAll() async {
    if (_isSyncing) {
      return {'status': 'in_progress', 'message': 'Sinkronisasi sedang berlangsung'};
    }
    if (_queue.isEmpty) {
      return {'status': 'empty', 'message': 'Tidak ada data antrean'};
    }

    _isSyncing = true;
    isSyncingNotifier.value = true;

    int successCount = 0;
    int failCount = 0;
    final List<OfflineTask> failedTasks = [];

    final initialCount = _queue.length;
    debugPrint('🚀 Memulai sinkronisasi $initialCount data antrean offline...');

    // Salin list antrean untuk diproses
    final tasksToProcess = List<OfflineTask>.from(_queue);

    for (final task in tasksToProcess) {
      try {
        final success = await _processTask(task);
        if (success) {
          successCount++;
          _queue.removeWhere((t) => t.id == task.id);
        } else {
          task.retryCount++;
          failedTasks.add(task);
          failCount++;
        }
      } catch (e) {
        debugPrint('⚠️ Error processing task ${task.id}: $e');
        task.retryCount++;
        failedTasks.add(task);
        failCount++;
      }
    }

    await _saveQueue();
    pendingCountNotifier.value = _queue.length;
    _isSyncing = false;
    isSyncingNotifier.value = false;

    final summaryMsg =
        'Sinkronisasi selesai: $successCount berhasil, $failCount gagal/tertunda.';
    debugPrint('🏁 $summaryMsg');
    _syncEventController.add(summaryMsg);

    // Tampilkan notifikasi jika ada data yang tersinkronisasi
    if (successCount > 0) {
      try {
        await NotificationService().showLocalNotification(
          id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Sinkronisasi Otomatis Berhasil',
          body: '$successCount data transaksi offline berhasil disimpan ke server.',
        );
      } catch (e) {
        debugPrint('Error showing sync notification: $e');
      }
    }

    return {
      'status': 'complete',
      'successCount': successCount,
      'failCount': failCount,
      'message': summaryMsg,
    };
  }

  /// Eksekusi pemrosesan satu tugas sesuai jenisnya
  Future<bool> _processTask(OfflineTask task) async {
    switch (task.type) {
      case 'asrama_attendance':
        return await _submitAsramaAttendance(task.payload);
      case 'meal_scan':
        return await _submitMealScan(task.payload);
      case 'meal_bulk':
        return await _submitMealBulk(task.payload);
      case 'tahfidz_setoran':
        return await _submitTahfidzSetoran(task.payload);
      case 'tahfidz_attendance':
        return await _submitTahfidzAttendance(task.payload);
      case 'tahfidz_teacher_attendance':
        return await _submitTahfidzTeacherAttendance(task.payload);
      case 'tahfidz_add_member':
        return await _submitTahfidzAddMember(task.payload);
      case 'tahfidz_remove_member':
        return await _submitTahfidzRemoveMember(task.payload);
      case 'homeroom_attendance':
        return await _submitHomeroomAttendance(task.payload);
      case 'teacher_attendance':
        return await _submitTeacherScheduleAttendance(task.payload);
      default:
        debugPrint('Unknown task type: ${task.type}');
        return true; // remove unknown task to avoid infinite stuck
    }
  }

  // --- Handlers untuk masing-masing API ---

  Future<bool> _submitAsramaAttendance(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(ApiConstants.boardingSubmitAttendance),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> _submitMealScan(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/meal_attendance/scan.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': payload['student_id'],
        'meal_type': payload['meal_type'],
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final success = data['success'] ?? data['status'];
      return success == true || success == 'true' || success == 1 || success == 'success';
    }
    return false;
  }

  Future<bool> _submitMealBulk(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/meal_attendance/save_bulk.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': payload['date'],
        'meal_type': payload['meal_type'],
        'student_ids': payload['student_ids'],
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final success = data['success'] ?? data['status'];
      return success == true || success == 'true' || success == 1 || success == 'success';
    }
    return false;
  }

  Future<bool> _submitTahfidzSetoran(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tahfidz/submit_memorization.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> _submitTahfidzAttendance(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tahfidz/submit_student_attendance.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> _submitTahfidzTeacherAttendance(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tahfidz/submit_teacher_attendance.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> _submitTahfidzAddMember(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(ApiConstants.tahfidzAddMember),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> _submitTahfidzRemoveMember(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(ApiConstants.tahfidzRemoveMember),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> _submitHomeroomAttendance(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/homeroom/dashboard.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> _submitTeacherScheduleAttendance(
      Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(ApiConstants.submitTeacherAttendance),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success' || data['success'] == true;
    }
    return false;
  }

  /// Prefetch & simpan master data penting (santri halaqoh, asrama, makan, jadwal, dll) saat online
  Future<void> precacheMasterData(dynamic userId) async {
    final int? id = userId is int ? userId : int.tryParse(userId?.toString() ?? '');
    if (id == null) return;
    try {
      final url = Uri.parse('${ApiConstants.tahfidzGetMyStudents}?teacher_id=$id');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if ((data['success'] == true || data['status'] == 'success') && data['data'] != null) {
          final list = data['data'] as List;
          await saveCache('tahfidz_students_$id', list);
          await saveCache('tahfidz_students_latest', list);
          debugPrint('📥 Precached master santri tahfidz (${list.length} santri)');
        }
      }
    } catch (_) {}

    try {
      final allUrl = Uri.parse('${ApiConfig.baseUrl}/tahfidz/get_students.php');
      final allRes = await http.get(allUrl).timeout(const Duration(seconds: 8));
      if (allRes.statusCode == 200) {
        final allData = jsonDecode(allRes.body);
        if (allData['success'] == true && allData['data'] != null) {
          await saveCache('tahfidz_all_students', allData['data']);
        }
      }
    } catch (_) {}

    // Precache asrama rooms
    try {
      final asramaUrl = Uri.parse('${ApiConstants.boardingGetRooms}?supervisor_id=$id');
      final asramaRes = await http.get(asramaUrl).timeout(const Duration(seconds: 8));
      if (asramaRes.statusCode == 200) {
        final asramaData = jsonDecode(asramaRes.body);
        if (asramaData['success'] == true && asramaData['data'] != null) {
          await saveCache('asrama_rooms_latest', asramaData['data']);
          debugPrint('📥 Precached master asrama rooms');
        }
      }
    } catch (_) {}

    // Precache meal students by musyrif
    try {
      final mealUrl = Uri.parse('${ApiConfig.baseUrl}/meal_attendance/get_students_by_musyrif.php?musyrif_id=$id');
      final mealRes = await http.get(mealUrl).timeout(const Duration(seconds: 8));
      if (mealRes.statusCode == 200) {
        final mealData = jsonDecode(mealRes.body);
        if ((mealData['success'] == true || mealData['status'] == 'success') && mealData['data'] != null) {
          await saveCache('meal_students_musyrif_latest', mealData['data']);
          debugPrint('📥 Precached master meal students for musyrif');
        }
      }
    } catch (_) {}

    // Precache jadwal mengajar guru
    try {
      final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Ahad'];
      for (final day in days) {
        final uri = Uri.parse(ApiConstants.teacherSchedule).replace(queryParameters: {
          'employee_id': id.toString(),
          'day': day,
        });
        final res = await http.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final result = jsonDecode(res.body);
          if ((result['status'] == 'success' || result['success'] == true) &&
              result['data'] != null) {
            await saveCache('teacher_schedule_${id}_$day', result['data']);
          }
        }
      }
      debugPrint('📥 Precached teaching schedule for teacher #$id');
    } catch (_) {}
  }

  // ==========================================
  // STORAGE HELPERS (File & SharedPreferences)
  // ==========================================

  Future<File?> _getQueueFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/offline_queue.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveQueue() async {
    final jsonList = _queue.map((t) => t.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);

    // Save to SharedPreferences as primary/backup
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_tasks_queue', jsonStr);
    } catch (e) {
      debugPrint('Error saving queue to SharedPreferences: $e');
    }

    // Also persist to documents directory file
    try {
      final file = await _getQueueFile();
      if (file != null) {
        await file.writeAsString(jsonStr, flush: true);
      }
    } catch (e) {
      debugPrint('Error saving queue to file: $e');
    }
  }

  Future<void> _loadQueue() async {
    _queue.clear();
    String? jsonStr;

    // Try reading file first
    try {
      final file = await _getQueueFile();
      if (file != null && await file.exists()) {
        jsonStr = await file.readAsString();
      }
    } catch (_) {}

    // Fallback to SharedPreferences
    if (jsonStr == null || jsonStr.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        jsonStr = prefs.getString('offline_tasks_queue');
      } catch (_) {}
    }

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        for (var item in list) {
          _queue.add(OfflineTask.fromJson(item));
        }
        pendingCountNotifier.value = _queue.length;
        debugPrint('📦 Loaded ${_queue.length} offline tasks from cache.');
      } catch (e) {
        debugPrint('Error parsing offline queue: $e');
      }
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _syncEventController.close();
  }
}
