import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class PerformanceService {
  Future<Map<String, dynamic>?> getPerformanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;

      if (userId == 0) return null;

      final url = Uri.parse('${ApiConstants.performanceData}?user_id=$userId');
      debugPrint('PerformanceService: Fetching data from $url');

      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching performance data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;

      final url = Uri.parse(
        '${ApiConstants.performanceLeaderboard}?user_id=$userId',
      );
      debugPrint('PerformanceService: Fetching leaderboard from $url');

      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return null;
    }
  }
}
