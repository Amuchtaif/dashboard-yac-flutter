import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import '../models/suggestion_feedback_model.dart';

class FeedbackSubmitResult {
  final bool success;
  final String message;
  final bool isOffline;
  final SuggestionFeedbackModel? data;

  FeedbackSubmitResult({
    required this.success,
    required this.message,
    this.isOffline = false,
    this.data,
  });
}

class SuggestionFeedbackService {
  static const String _storageKey = 'user_suggestion_feedbacks_v1';

  /// Ambil riwayat masukan milik user dari API server dengan fallback ke cache lokal
  Future<List<SuggestionFeedbackModel>> getMyFeedbacks(int userId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Coba ambil dari Server Backend
    try {
      final url = Uri.parse('${ApiConstants.feedbackGetMy}?user_id=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> serverJsonList = data['data'];
          final serverList = serverJsonList
              .map((item) => SuggestionFeedbackModel.fromJson(item))
              .toList();

          // Cek apakah ada draft lokal yang belum ada di server
          List<SuggestionFeedbackModel> pendingLocal = [];
          final localStr = prefs.getString('${_storageKey}_$userId');
          if (localStr != null && localStr.isNotEmpty) {
            try {
              final List<dynamic> localJsonList = jsonDecode(localStr);
              pendingLocal = localJsonList
                  .map((item) => SuggestionFeedbackModel.fromJson(item))
                  .where((f) =>
                      f.id.startsWith('fb_') &&
                      !serverList.any((s) => s.title == f.title && s.description == f.description))
                  .toList();
            } catch (_) {}
          }

          final mergedList = [...pendingLocal, ...serverList];
          // Simpan hasil gabungan ke cache lokal
          await prefs.setString(
            '${_storageKey}_$userId',
            jsonEncode(mergedList.map((f) => f.toJson()).toList()),
          );
          return mergedList;
        }
      }
    } catch (e) {
      debugPrint('Info: Server API feedback offline/gagal ($e), menggunakan cache lokal.');
    }

    // 2. Fallback ke SharedPreferences (Offline Cache)
    try {
      final str = prefs.getString('${_storageKey}_$userId');
      if (str != null && str.isNotEmpty) {
        final List<dynamic> list = jsonDecode(str);
        final realList = list
            .map((item) => SuggestionFeedbackModel.fromJson(item))
            .where((f) => !f.id.startsWith('sample_'))
            .toList();
        return realList;
      }
    } catch (e) {
      debugPrint('Error loading cached feedbacks: $e');
    }

    // 3. Kembalikan list kosong jika belum ada masukan
    return [];
  }

  /// Kirim usulan / lapor kendala baru ke Backend via Multipart Form Data
  Future<FeedbackSubmitResult> submitFeedback(SuggestionFeedbackModel feedback) async {
    // 1. Kirim ke Server API
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.feedbackSubmit),
      );

      request.fields['user_id'] = feedback.userId.toString();
      request.fields['type'] = feedback.type.apiValue;
      request.fields['module'] = feedback.module;
      request.fields['priority'] = feedback.priority.apiValue;
      request.fields['title'] = feedback.title;
      request.fields['description'] = feedback.description;
      if (feedback.appVersion != null && feedback.appVersion!.isNotEmpty) {
        request.fields['app_version'] = feedback.appVersion!;
      }
      if (feedback.deviceInfo != null && feedback.deviceInfo!.isNotEmpty) {
        request.fields['device_info'] = feedback.deviceInfo!;
      }

      // Lampirkan file screenshot jika ada
      if (feedback.attachmentPath != null &&
          feedback.attachmentPath!.isNotEmpty) {
        final file = File(feedback.attachmentPath!);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachment',
              file.path,
            ),
          );
        }
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Feedback berhasil dikirim ke server: ${response.body}');

          SuggestionFeedbackModel serverModel = feedback;
          if (data['data'] != null && data['data'] is Map<String, dynamic>) {
            final respData = data['data'] as Map<String, dynamic>;
            serverModel = SuggestionFeedbackModel(
              id: respData['id']?.toString() ?? feedback.id,
              userId: feedback.userId,
              userName: feedback.userName,
              userDivision: feedback.userDivision,
              type: feedback.type,
              module: feedback.module,
              title: feedback.title,
              description: feedback.description,
              priority: feedback.priority,
              attachmentPath: feedback.attachmentPath,
              attachmentUrl: respData['attachment_url'],
              appVersion: feedback.appVersion,
              deviceInfo: feedback.deviceInfo,
              status: FeedbackStatus.fromApi(respData['status']),
              createdAt: respData['created_at'] != null
                  ? (DateTime.tryParse(respData['created_at'].toString().replaceAll(' ', 'T')) ?? feedback.createdAt)
                  : feedback.createdAt,
            );
          }

          // Simpan ke local cache
          await _saveToLocalCache(serverModel);

          return FeedbackSubmitResult(
            success: true,
            message: data['message']?.toString() ?? 'Usulan Anda berhasil dikirim ke Tim IT & Manajemen!',
            data: serverModel,
          );
        } else {
          final errMsg = data['message']?.toString() ?? 'Gagal menyimpan usulan di server.';
          debugPrint('⚠️ Server error message: $errMsg');
          return FeedbackSubmitResult(
            success: false,
            message: errMsg,
          );
        }
      } else {
        String errMsg = 'Gagal mengirim usulan (HTTP ${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) errMsg = data['message'].toString();
        } catch (_) {}
        debugPrint('⚠️ Server non-200: $errMsg');
        return FeedbackSubmitResult(
          success: false,
          message: errMsg,
        );
      }
    } catch (e) {
      debugPrint('Network error submitting feedback: $e');
      // Offline fallback: simpan lokal
      await _saveToLocalCache(feedback);
      return FeedbackSubmitResult(
        success: true,
        isOffline: true,
        message: 'Koneksi offline: Usulan disimpan lokal di perangkat dan dapat dilihat di riwayat.',
        data: feedback,
      );
    }
  }

  Future<void> _saveToLocalCache(SuggestionFeedbackModel feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('${_storageKey}_${feedback.userId}');
      List<SuggestionFeedbackModel> currentList = [];
      if (str != null && str.isNotEmpty) {
        final List<dynamic> list = jsonDecode(str);
        currentList = list
            .map((item) => SuggestionFeedbackModel.fromJson(item))
            .where((f) => !f.id.startsWith('sample_'))
            .toList();
      }
      final updatedList = [
        feedback,
        ...currentList.where((f) => f.id != feedback.id),
      ];
      await prefs.setString(
        '${_storageKey}_${feedback.userId}',
        jsonEncode(updatedList.map((f) => f.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving feedback to local cache: $e');
    }
  }

  /// Hapus satu item masukan
  Future<bool> deleteFeedback(int userId, String feedbackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getMyFeedbacks(userId);

      final updatedList =
          currentList.where((f) => f.id != feedbackId).toList();
      final jsonList = updatedList.map((f) => f.toJson()).toList();
      await prefs.setString('${_storageKey}_$userId', jsonEncode(jsonList));

      return true;
    } catch (e) {
      debugPrint('Error deleting feedback: $e');
      return false;
    }
  }
}
