import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/surah_model.dart';
import '../data/quran_surah_data.dart';
import 'offline_sync_service.dart';

class QuranService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<List<Surah>> getAllSurahs() async {
    final offlineSync = OfflineSyncService();

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/quran/list_surat.php'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);

        if (decoded.containsKey('data') && decoded['data'] is List) {
          final List<dynamic> data = decoded['data'];
          await offlineSync.saveCache('quran_all_surahs', data);
          return data.map((j) => Surah.fromJson(j)).toList();
        }
      }
    } catch (e) {
      debugPrint("QuranService: Network error fetching surahs (fallback to offline): $e");
    }

    // 1. Fallback dari cache lokal
    final cached = await offlineSync.getCache('quran_all_surahs');
    if (cached != null && cached is List && cached.isNotEmpty) {
      debugPrint("📦 QuranService: Menggunakan cache lokal untuk ${cached.length} surah");
      return cached.map((j) => Surah.fromJson(j)).toList();
    }

    // 2. Fallback dari static master data 114 surah (selalu tersedia 100% offline)
    debugPrint("📦 QuranService: Menggunakan data statis bawaan untuk 114 surah");
    return List.from(kOfflineSurahs);
  }

  Future<Surah> getSurahDetail(int nomor) async {
    final offlineSync = OfflineSyncService();
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/quran/get_surah.php?nomor=$nomor'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        if (decoded.containsKey('data')) {
          await offlineSync.saveCache('quran_surah_$nomor', decoded['data']);
          return Surah.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      debugPrint("QuranService: Network error fetching surah detail: $e");
    }

    // Fallback cache detail
    final cached = await offlineSync.getCache('quran_surah_$nomor');
    if (cached != null && cached is Map<String, dynamic>) {
      return Surah.fromJson(cached);
    }

    // Fallback dari static data
    final staticSurah = kOfflineSurahs.firstWhere(
      (s) => s.nomor == nomor,
      orElse: () => Surah(
        nomor: nomor,
        nama: '',
        namaLatin: 'Surah $nomor',
        jumlahAyat: 0,
        tempatTurun: '',
        arti: '',
        deskripsi: '',
        audioFull: '',
      ),
    );
    return staticSurah;
  }
}
