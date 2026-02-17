import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PayrollService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Map<String, dynamic>>> getPayrollHistory({
    required int userId,
    String? bulan,
    String? tahun,
  }) async {
    String urlString = '$baseUrl/payroll.php?user_id=$userId';
    if (bulan != null) urlString += '&bulan=$bulan';
    if (tahun != null) urlString += '&tahun=$tahun';

    final url = Uri.parse(urlString);

    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if ((data['success'] == true || data['status'] == true) &&
            data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      // print('Error fetching payroll: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPayrollDetail(String idPayroll) async {
    final url = Uri.parse('$baseUrl/payroll.php?id=$idPayroll');

    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true || data['status'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      // print('Error fetching payroll detail: $e');
    }
    return null;
  }
}
