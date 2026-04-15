import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dzikir_model.dart';

class DzikirService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<List<DzikirModel>> getDzikir(String type) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dzikir/get_dzikir.php?type=$type'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> dzikirList = data['data'];
        return dzikirList.map((json) => DzikirModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load dzikir');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
