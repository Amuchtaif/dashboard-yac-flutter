import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/asrama_model.dart';
import '../core/api_constants.dart';

class AsramaService {
  Future<List<Asrama>> getDaftarAsrama({String? date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final url = Uri.parse('${ApiConstants.boardingGetRooms}?supervisor_id=$userId&date=$targetDate');
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((json) => Asrama.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching asrama list: $e');
    }
    return [];
  }

  Future<List<SantriAsrama>> getSantriByAsrama(int asramaId, {String? date}) async {
    try {
      final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final url = Uri.parse('${ApiConstants.boardingGetStudents}?room_id=$asramaId&date=$targetDate');
      
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          if (list.isNotEmpty) {
            debugPrint('📥 Sample Student Keys: ${list[0].keys.toList()}');
            debugPrint('📥 Sample Student Data: ${jsonEncode(list[0])}');
          }
          return list.map((json) => SantriAsrama.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching students by asrama: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> submitAbsensi(int asramaId, List<SantriAsrama> absensi, {String? date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
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

      debugPrint('📤 Submitting Attendance: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(ApiConstants.boardingSubmitAttendance),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(payload),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? (data['success'] == true ? 'Berhasil' : 'Gagal menyimpan'),
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error submitting attendance: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
