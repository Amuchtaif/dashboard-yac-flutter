import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../models/news_model.dart';

class NewsService {
  Future<List<News>> getNews() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getNews),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> newsData = data['data'];
          return newsData.map((item) => News.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitNews({
    required int userId,
    required String title,
    required String category,
    required String content,
    required File coverPhoto,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.submitNews),
      );

      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});

      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      request.fields['category'] = category;
      request.fields['content'] = content;

      // Backend expects 'image' key for the file
      request.files.add(
        await http.MultipartFile.fromPath('image', coverPhoto.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        // Backend returns "status" => "success"
        if (resData['status'] == 'success') {
          return {
            'success': true,
            'message': resData['message'] ?? 'Berita berhasil dipublikasikan',
            'data': resData['data'],
          };
        } else {
          return {
            'success': false,
            'message': resData['message'] ?? 'Gagal membuat berita',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Kesalahan Server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }
}
