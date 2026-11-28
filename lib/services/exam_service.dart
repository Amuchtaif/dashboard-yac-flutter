import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import '../models/exam_model.dart';

class ExamService {
  static const String _packagesCachePrefix = 'exam_packages_cache_';
  static const String _packageDetailCachePrefix = 'exam_pkg_detail_cache_';
  static const String _pendingScansKey = 'exam_pending_scans_queue';

  /// Ambil daftar paket ujian guru (dengan caching offline)
  Future<List<ExamPackageModel>> getPackages({
    required int userId,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_packagesCachePrefix$userId';

    // 1. Coba ambil dari server API
    try {
      var urlStr = '${ApiConstants.examsPackages}?user_id=$userId';
      if (status != null && status.isNotEmpty) {
        urlStr += '&status=$status';
      }
      final response = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          // Update cache lokal
          await prefs.setString(cacheKey, jsonEncode(list));
          return list.map((item) => ExamPackageModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Info: Server API exams/packages offline/gagal ($e), menggunakan cache lokal.');
    }

    // 2. Fallback ke SharedPreferences cache
    try {
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedStr);
        return list.map((item) => ExamPackageModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error reading cached exam packages: $e');
    }

    return [];
  }

  /// Ambil detail paket, kunci jawaban, santri, dan geometri OMR (dengan caching offline)
  Future<ExamPackageDetailModel?> getPackageDetail(int packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_packageDetailCachePrefix$packageId';

    // 1. Coba ambil dari server API
    try {
      final url = '${ApiConstants.examsPackageDetail}?package_id=$packageId';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update cache lokal
          await prefs.setString(cacheKey, response.body);
          return ExamPackageDetailModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Info: Server API exams/package_detail offline/gagal ($e), menggunakan cache lokal.');
    }

    // 2. Fallback ke SharedPreferences cache
    try {
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr);
        return ExamPackageDetailModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error reading cached package detail: $e');
    }

    return null;
  }

  /// Submit hasil scan LJK ke server (dengan penanganan offline)
  Future<({bool success, String message, Map<String, dynamic>? data, bool isOffline})> submitScan(
    ExamScanSubmission submission,
  ) async {
    try {
      // Jika menyertakan file foto LJK, gunakan MultipartRequest
      if (submission.scanImagePath != null && submission.scanImagePath!.isNotEmpty) {
        final file = File(submission.scanImagePath!);
        if (await file.exists()) {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse(ApiConstants.examsSubmitScan),
          );

          request.fields['package_id'] = submission.packageId.toString();
          request.fields['student_id'] = submission.studentId.toString();
          request.fields['scanner_user_id'] = submission.scannerUserId.toString();
          request.fields['auto_sync'] = submission.autoSync ? '1' : '0';
          request.fields['answers'] = jsonEncode(
            submission.answers.map((a) => {
              'question_number': a.questionNumber,
              'selected_option': a.selectedOption,
            }).toList(),
          );

          request.files.add(
            await http.MultipartFile.fromPath('scan_image', file.path),
          );

          final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
          final response = await http.Response.fromStream(streamedResponse);

          return _handleScanResponse(response, submission);
        }
      }

      // JSON Request standar jika tanpa file atau file tidak ditemukan
      final response = await http.post(
        Uri.parse(ApiConstants.examsSubmitScan),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(submission.toJson()),
      ).timeout(const Duration(seconds: 15));

      return _handleScanResponse(response, submission);
    } catch (e) {
      debugPrint('Network error submitting scan: $e. Menyimpan offline...');
      await _savePendingScanOffline(submission);
      return (
        success: true,
        message: 'Koneksi offline: Hasil koreksi LJK tersimpan di perangkat dan akan disinkronkan saat terhubung.',
        data: null,
        isOffline: true,
      );
    }
  }

  ({bool success, String message, Map<String, dynamic>? data, bool isOffline}) _handleScanResponse(
    http.Response response,
    ExamScanSubmission submission,
  ) {
    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          // Update status santri di cache lokal
          _updateStudentCacheAfterScan(submission.packageId, submission.studentId, body['data']?['score']);
          return (
            success: true,
            message: body['message']?.toString() ?? 'Hasil scan LJK berhasil disimpan.',
            data: body['data'] is Map ? Map<String, dynamic>.from(body['data']) : null,
            isOffline: false,
          );
        } else {
          return (
            success: false,
            message: body['message']?.toString() ?? 'Gagal menyimpan hasil scan di server.',
            data: null,
            isOffline: false,
          );
        }
      } catch (e) {
        return (
          success: false,
          message: 'Gagal memproses respons server: $e',
          data: null,
          isOffline: false,
        );
      }
    } else {
      String msg = 'Server mengembalikan kode ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) msg = body['message'].toString();
      } catch (_) {}
      return (
        success: false,
        message: msg,
        data: null,
        isOffline: false,
      );
    }
  }

  /// Simpan submission scan ke antrean offline jika jaringan gagal
  Future<void> _savePendingScanOffline(ExamScanSubmission submission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_pendingScansKey);
      List<dynamic> queue = str != null ? jsonDecode(str) : [];
      queue.add(submission.toJson());
      await prefs.setString(_pendingScansKey, jsonEncode(queue));

      _updateStudentCacheAfterScan(submission.packageId, submission.studentId, null);
    } catch (e) {
      debugPrint('Error saving offline scan queue: $e');
    }
  }

  /// Update data santri di cache paket lokal setelah di-scan
  Future<void> _updateStudentCacheAfterScan(int packageId, int studentId, dynamic score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_packageDetailCachePrefix$packageId';
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        final Map<String, dynamic> data = jsonDecode(cachedStr);
        if (data['students'] is List) {
          for (final st in data['students']) {
            if (st['id'] == studentId) {
              st['is_scanned'] = true;
              if (score != null) st['last_score'] = double.tryParse(score.toString());
              break;
            }
          }
          await prefs.setString(cacheKey, jsonEncode(data));
        }
      }
    } catch (_) {}
  }

  /// Ambil rekap hasil scan per paket
  Future<({bool success, List<ExamScanResultItem> results, Map<String, dynamic>? summary})> getScanResults(
    int packageId,
  ) async {
    try {
      final url = '${ApiConstants.examsScanResults}?package_id=$packageId';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          final results = list.map((item) => ExamScanResultItem.fromJson(item)).toList();
          return (
            success: true,
            results: results,
            summary: data['summary'] is Map ? Map<String, dynamic>.from(data['summary']) : null,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching scan results: $e');
    }

    return (
      success: false,
      results: <ExamScanResultItem>[],
      summary: null,
    );
  }
}
