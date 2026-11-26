import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/asrama_model.dart';
import '../core/api_constants.dart';
import 'offline_sync_service.dart';

class AsramaService {
  Future<List<Asrama>> getDaftarAsrama({String? date}) async {
    final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cacheKey = 'asrama_rooms_$targetDate';
    final offlineSync = OfflineSyncService();

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUserId = prefs.get('userId') ?? prefs.get('user_id');
      final userId = rawUserId != null ? int.tryParse(rawUserId.toString()) : null;
      
      final url = Uri.parse('${ApiConstants.boardingGetRooms}?supervisor_id=$userId&date=$targetDate');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          // Cache master data kamar asrama
          await offlineSync.saveCache(cacheKey, list);
          await offlineSync.saveCache('asrama_rooms_latest', list);
          return list.map((json) => Asrama.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching asrama list (trying cache): $e');
    }

    // Fallback ke cache jika offline
    final cached = await offlineSync.getCache(cacheKey) ??
        await offlineSync.getCache('asrama_rooms_latest');
    if (cached != null && cached is List) {
      debugPrint('📦 Menggunakan cache lokal untuk daftar asrama (${cached.length} kamar)');
      return cached.map((json) => Asrama.fromJson(json)).toList();
    }

    return [];
  }

  Future<List<SantriAsrama>> getSantriByAsrama(int asramaId, {String? date}) async {
    final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cacheKey = 'asrama_students_${asramaId}_$targetDate';
    final fallbackCacheKey = 'asrama_students_${asramaId}_latest';
    final offlineSync = OfflineSyncService();

    try {
      final url = Uri.parse('${ApiConstants.boardingGetStudents}?room_id=$asramaId&date=$targetDate');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          // Simpan ke cache lokal
          await offlineSync.saveCache(cacheKey, list);
          await offlineSync.saveCache(fallbackCacheKey, list);
          return list.map((json) => SantriAsrama.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching students by asrama (trying cache): $e');
    }

    // Fallback ke cache jika offline
    final cached = await offlineSync.getCache(cacheKey) ??
        await offlineSync.getCache(fallbackCacheKey);
    if (cached != null && cached is List) {
      debugPrint('📦 Menggunakan cache lokal untuk santri asrama kamar #$asramaId (${cached.length} santri)');
      final list = cached.map((json) => SantriAsrama.fromJson(json)).toList();

      // Periksa apakah ada antrean offline untuk kamar ini pada tanggal ini, jika ada, update status lokal
      final pendingAsramaTasks = offlineSync.queue
          .where((t) =>
              t.type == 'asrama_attendance' &&
              t.payload['room_id'] == asramaId &&
              t.payload['date'] == targetDate)
          .toList();
      if (pendingAsramaTasks.isNotEmpty) {
        final lastTask = pendingAsramaTasks.last;
        final attendanceList =
            lastTask.payload['attendance'] as List<dynamic>? ?? [];
        final Map<int, Map<String, dynamic>> attendanceMap = {
          for (var item in attendanceList)
            if (item['student_id'] != null)
              int.tryParse(item['student_id'].toString()) ?? 0:
                  Map<String, dynamic>.from(item)
        };
        for (var s in list) {
          if (attendanceMap.containsKey(s.id)) {
            final att = attendanceMap[s.id]!;
            s.status = att['status']?.toString() ?? s.status;
            if (att['notes'] != null && att['notes'].toString().isNotEmpty) {
              s.keterangan = att['notes'].toString();
            }
          }
        }
      }
      return list;
    }

    return [];
  }

  Future<Map<String, dynamic>> submitAbsensi(int asramaId, List<SantriAsrama> absensi, {String? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final rawUserId = prefs.get('userId') ?? prefs.get('user_id');
    final userId = rawUserId != null ? int.tryParse(rawUserId.toString()) : null;
    final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    final payload = {
      "room_id": asramaId,
      "date": targetDate,
      "created_by": userId,
      "attendance": absensi.map((s) => {
        "student_id": s.id,
        "status": s.status,
        "notes": s.keterangan ?? ""
      }).toList()
    };

    // Update cache lokal langsung agar langsung terlihat di layar
    final offlineSync = OfflineSyncService();
    try {
      final updatedJsonList = absensi.map((s) => s.toJson()).toList();
      await offlineSync.saveCache('asrama_students_${asramaId}_$targetDate', updatedJsonList);
      await offlineSync.saveCache('asrama_students_${asramaId}_latest', updatedJsonList);
    } catch (_) {}

    try {
      debugPrint('📤 Submitting Attendance: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(ApiConstants.boardingSubmitAttendance),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? (data['success'] == true ? 'Berhasil' : 'Gagal menyimpan'),
        };
      } else {
        // Jika server error (500/502/503), simpan ke antrean offline
        await offlineSync.enqueueTask(
          type: 'asrama_attendance',
          payload: payload,
          description: 'Absensi Kamar #$asramaId ($targetDate)',
        );
        return {
          'success': true,
          'isOffline': true,
          'message': 'Disimpan lokal di perangkat (Server Sibuk). Akan disinkronkan otomatis.',
        };
      }
    } catch (e) {
      debugPrint('Network error submitting attendance, enqueuing offline: $e');
      // Simpan ke antrean offline jika koneksi gagal/blank spot
      await offlineSync.enqueueTask(
        type: 'asrama_attendance',
        payload: payload,
        description: 'Absensi Kamar #$asramaId ($targetDate)',
      );
      return {
        'success': true,
        'isOffline': true,
        'message': 'Tersimpan di HP (Mode Offline). Akan otomatis terkirim saat sinyal kembali.',
      };
    }
  }
}
