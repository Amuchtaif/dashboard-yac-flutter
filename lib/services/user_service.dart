import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import '../models/user_model.dart';

class UserService {
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    String? fullName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> payload = {'user_id': userId.toString()};
      if (fullName != null) payload['full_name'] = fullName;
      if (phoneNumber != null) payload['phone_number'] = phoneNumber;
      if (address != null) payload['address'] = address;

      final response = await http.post(
        Uri.parse(ApiConstants.updateProfile),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local storage with new user data
          if (data['data'] != null) {
            final user = User.fromJson(data['data']);
            await _saveUserToPrefs(user);
          }
          return {
            'success': true,
            'message': data['message'] ?? 'Profil berhasil diperbarui',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal memperbarui profil',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Kesalahan Server: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'success': false, 'message': 'Terjadi kesalahan koneksi'};
    }
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', user.fullName);
    await prefs.setString('email', user.email);
    await prefs.setString('unitName', user.unitName);
    await prefs.setString('divisionName', user.divisionName);
    await prefs.setString('positionName', user.positionName);
    await prefs.setString('phoneNumber', user.phoneNumber);
    await prefs.setString('address', user.address);
    await prefs.setInt('positionLevel', user.positionLevel);
    await prefs.setInt('divisionId', user.divisionId);
  }
}
