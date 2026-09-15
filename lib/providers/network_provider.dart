import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NetworkProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOffline = false;
  bool _isChecking = false;
  bool _hasCheckedInitially = false;

  bool get isOffline => _isOffline;
  bool get isChecking => _isChecking;
  bool get hasCheckedInitially => _hasCheckedInitially;

  NetworkProvider() {
    _init();
  }

  Future<void> _init() async {
    await checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        (results.length == 1 && results.contains(ConnectivityResult.none))) {
      _setOffline(true);
    } else {
      // Ada antarmuka jaringan terhubung, verifikasi akses internet riil
      checkConnectivity();
    }
  }

  /// Memeriksa apakah ada akses internet aktual
  Future<bool> _checkInternetAccess() async {
    if (kIsWeb) {
      try {
        final response = await http
            .head(Uri.parse('${ApiConfig.baseUrl}/app_status.php'))
            .timeout(const Duration(seconds: 4));
        return response.statusCode > 0;
      } catch (_) {
        return false;
      }
    }

    // Platform Mobile & Desktop (Android, iOS, Windows, macOS, Linux)
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      // Coba host alternatif sebagai cadangan jika DNS google bermasalah
    } on TimeoutException catch (_) {
      // Timeout
    } catch (_) {}

    try {
      final fallback = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 3));
      return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa status konektivitas secara manual (misalnya tombol "Coba Lagi")
  Future<bool> checkConnectivity() async {
    _isChecking = true;
    notifyListeners();

    bool offline = false;
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty ||
          (results.length == 1 && results.contains(ConnectivityResult.none))) {
        offline = true;
      } else {
        final hasInternet = await _checkInternetAccess();
        offline = !hasInternet;
      }
    } catch (e) {
      debugPrint("⚠️ NetworkProvider check error: $e");
      offline = true;
    } finally {
      _isChecking = false;
      _hasCheckedInitially = true;
      _setOffline(offline);
    }

    return !_isOffline;
  }

  void _setOffline(bool offline) {
    if (_isOffline != offline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
