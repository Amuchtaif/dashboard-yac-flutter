import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PermitService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<bool> hasApprovedFullDayPermitToday(int userId) async {
    final url = Uri.parse('$baseUrl/get_permits.php?user_id=$userId');
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> permits = data['data'];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (var permit in permits) {
            String status = (permit['status'] ?? '').toString().toLowerCase();
            if (status != 'approved') continue;

            // Check if full day
            var isHourly = permit['is_hourly'];
            bool isFullDay = (isHourly == '0' || isHourly == 0 || isHourly == null);

            if (!isFullDay) continue;

            String? startDateStr = permit['start_date'];
            String? endDateStr = permit['end_date'];

            if (startDateStr != null && endDateStr != null) {
              DateTime startDate = DateTime.parse(startDateStr);
              DateTime endDate = DateTime.parse(endDateStr);
              
              DateTime start = DateTime(startDate.year, startDate.month, startDate.day);
              DateTime end = DateTime(endDate.year, endDate.month, endDate.day);

              if ((today.isAtSameMomentAs(start) || today.isAfter(start)) && 
                  (today.isAtSameMomentAs(end) || today.isBefore(end))) {
                return true;
              }
            }
          }
        }
      }
    } catch (e) {
      // print('Error checking permits: $e');
    }
    return false;
  }
}
