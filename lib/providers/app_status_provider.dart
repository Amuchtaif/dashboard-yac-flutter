import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AppStatusProvider extends ChangeNotifier {
  bool _isMaintenance = false;
  String? _maintenanceMessage;
  Timer? _checkTimer;

  bool get isMaintenance => _isMaintenance;
  String? get maintenanceMessage => _maintenanceMessage;

  AppStatusProvider({bool initialIsMaintenance = false, String? initialMessage}) {
    _isMaintenance = initialIsMaintenance;
    _maintenanceMessage = initialMessage;
    _startPolling();
  }

  void _startPolling() {
    _checkTimer?.cancel();
    // Fallback polling every 30 minutes in case FCM fails
    _checkTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      checkStatus();
    });
  }

  void updateStatus(bool isMaintenance, String? message) {
    if (_isMaintenance != isMaintenance || _maintenanceMessage != message) {
      _isMaintenance = isMaintenance;
      _maintenanceMessage = message;
      notifyListeners();
    }
  }

  Future<bool> checkStatus() async {
    try {
      final response = await http
          .get(Uri.parse("${ApiConfig.baseUrl}/app_status.php"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool newStatus = data['status'] == 'maintenance';
        String? newMessage = data['message'];

        if (newStatus != _isMaintenance || newMessage != _maintenanceMessage) {
          _isMaintenance = newStatus;
          _maintenanceMessage = newMessage;
          notifyListeners();
        }
        return newStatus;
      }
    } catch (e) {
      debugPrint("Error checking app status: $e");
    }
    return _isMaintenance;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
