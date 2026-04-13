import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/surah_model.dart';

class QuranService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<List<Surah>> getAllSurahs() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/quran/list_surat.php'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);

        if (decoded.containsKey('data') && decoded['data'] is List) {
          final List<dynamic> data = decoded['data'];
          return data.map((json) => Surah.fromJson(json)).toList();
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Failed to load surahs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching surahs: $e');
    }
  }

  Future<Surah> getSurahDetail(int nomor) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/quran/get_surah.php?nomor=$nomor'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);

        if (decoded.containsKey('data')) {
          return Surah.fromJson(decoded['data']);
        } else {
          throw Exception('Invalid API response format for detail');
        }
      } else {
        throw Exception('Failed to load surah detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching surah detail: $e');
    }
  }
}

