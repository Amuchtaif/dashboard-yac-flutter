import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/violation_model.dart';

class ViolationService {
  static const String endpoint = "${ApiConfig.baseUrl}/student_violations";

  static Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('user_id') ?? prefs.get('userId');
    return userId?.toString() ?? '0';
  }

  static Future<List<Violation>> getList({
    String? status,
    int? kategoriId,
    int? santriId,
    String? search,
  }) async {
    try {
      final userId = await _getUserId();
      final url = Uri.parse("$endpoint/list.php").replace(queryParameters: {
        'user_id': userId,
        if (status != null) 'status': status,
        if (kategoriId != null) 'kategori_id': kategoriId.toString(),
        if (santriId != null) 'santri_id': santriId.toString(),
        if (search != null) 'search': search,
      });

      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => Violation.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<ViolationCategory>> getCategories() async {
    try {
      final userId = await _getUserId();
      final url =
          Uri.parse("$endpoint/get_categories.php").replace(queryParameters: {
        'user_id': userId,
      });
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => ViolationCategory.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDetail(int id) async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse("$endpoint/get_detail.php?id=$id&user_id=$userId"),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'is_officer': data['data']['is_officer'] ?? false,
            'violation': Violation.fromJson(data['data']['violation']),
            'followups': (data['data']['followups'] as List)
                .map((item) => ViolationFollowup.fromJson(item))
                .toList(),
          };
        }
      }
      return {'error': 'Failed to fetch details'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Officer Management
  static const String officerEndpoint = "${ApiConfig.baseUrl}/violation_officers";

  static Future<List<ViolationOfficer>> getOfficers() async {
    try {
      final response = await http.get(
        Uri.parse("$officerEndpoint/list.php"),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => ViolationOfficer.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addOfficer(int employeeId) async {
    try {
      final response = await http.post(
        Uri.parse("$officerEndpoint/add.php"),
        body: json.encode({'employee_id': employeeId}),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteOfficer(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$officerEndpoint/delete.php"),
        body: json.encode({'id': id}),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getOfficerEmployees() async {
    try {
      final response = await http.get(
        Uri.parse("$officerEndpoint/get_employees.php"),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> create({
    required int santriId,
    required int kategoriId,
    required String deskripsi,
    required String tanggal,
    String? lokasi,
    required String status,
  }) async {
    try {
      final userId = await _getUserId();
      final response = await http.post(
        Uri.parse("$endpoint/create.php"),
        body: json.encode({
          'user_id': userId,
          'santri_id': santriId,
          'kategori_id': kategoriId,
          'deskripsi': deskripsi,
          'tanggal': tanggal,
          'lokasi': lokasi,
          'status': status,
        }),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addFollowup({
    required int pelanggaranId,
    required String tindakan,
    String? catatan,
    required String tanggal,
    required String status,
  }) async {
    try {
      final userId = await _getUserId();
      final response = await http.post(
        Uri.parse("$endpoint/add_followup.php"),
        body: json.encode({
          'user_id': userId,
          'pelanggaran_id': pelanggaranId,
          'tindakan': tindakan,
          'catatan': catatan,
          'tanggal': tanggal,
          'status': status,
        }),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> update({
    required int id,
    required int santriId,
    required int kategoriId,
    required String deskripsi,
    required String tanggal,
    String? lokasi,
    required String status,
  }) async {
    try {
      final userId = await _getUserId();
      final response = await http.post(
        Uri.parse("$endpoint/update.php"),
        body: json.encode({
          'id': id,
          'user_id': userId,
          'santri_id': santriId,
          'kategori_id': kategoriId,
          'deskripsi': deskripsi,
          'tanggal': tanggal,
          'lokasi': lokasi,
          'status': status,
        }),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> delete(int id) async {
    try {
      final userId = await _getUserId();
      final response = await http.post(
        Uri.parse("$endpoint/delete.php"),
        body: json.encode({
          'id': id,
          'user_id': userId,
        }),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final userId = await _getUserId();
      final url =
          Uri.parse("$endpoint/get_students.php").replace(queryParameters: {
        'user_id': userId,
      });
      final response = await http.get(url, headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
