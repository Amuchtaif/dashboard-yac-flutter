import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StudentService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final url = Uri.parse('$baseUrl/tahfidz/get_students.php');

    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
    return [];
  }
}
