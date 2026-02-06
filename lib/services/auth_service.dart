import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import '../models/user_model.dart';
import 'permission_service.dart';

class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({required this.success, required this.message, this.user});
}

class AuthService {
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // print('Raw Server Response: ${response.body}');

        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData['success'] == true) {
            final userData = responseData['data'];
            final user = User.fromJson(userData);

            // Save session data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('userId', user.id);
            await prefs.setString('fullName', user.fullName);
            await prefs.setString('email', user.email);
            await prefs.setString('unitName', user.unitName);
            await prefs.setString('divisionName', user.divisionName);
            await prefs.setString('positionName', user.positionName);
            await prefs.setString('phoneNumber', user.phoneNumber);
            await prefs.setInt('positionLevel', user.positionLevel);
            await prefs.setInt(
              'divisionId',
              user.divisionId,
            ); // Added divisionId
            await prefs.setBool('isLoggedIn', true);
            // Save Login Timestamp for 12h Session
            await prefs.setInt(
              'login_timestamp',
              DateTime.now().millisecondsSinceEpoch,
            );

            // Fetch user permissions after successful login
            final permissionService = PermissionService();
            await permissionService.fetchPermissions(user.id);
            debugPrint('✅ User permissions loaded for userId: ${user.id}');

            return AuthResult(
              success: true,
              message: responseData['message'] ?? 'Login Successful',
              user: user,
            );
          } else {
            return AuthResult(
              success: false,
              message: responseData['message'] ?? 'Login Failed',
            );
          }
        } catch (e) {
          final snippet =
              response.body.length > 200
                  ? '${response.body.substring(0, 200)}...'
                  : response.body;
          return AuthResult(
            success: false,
            message: 'Server Error (Invalid JSON): $snippet',
          );
        }
      } else {
        return AuthResult(
          success: false,
          message: 'Server Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Connection Error: $e');
    }
  }

  Future<void> logout() async {
    // Clear permission cache
    final permissionService = PermissionService();
    await permissionService.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
