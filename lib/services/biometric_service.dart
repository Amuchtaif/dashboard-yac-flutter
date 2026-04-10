import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Check if biometrics are available and if there are saved credentials
  Future<bool> canUseBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      if (!(canAuthenticateWithBiometrics || isSupported)) return false;

      // Check if any biometrics are enrolled in the system
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return false;

      final credentials = await getCredentials();
      return credentials != null;
    } catch (e) {
      debugPrint("Error checking biometrics: $e");
      return false;
    }
  }

  // Pure biometric check (even if no credentials yet)
  Future<bool> isDeviceSupported() async {
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;
      if (!isSupported || !canCheck) return false;

      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason:
            'Silakan verifikasi identitas Anda untuk masuk ke Aplikasi YAC',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Use only biometrics, not PIN/Pattern
          useErrorDialogs: true, // Provides system dialogs for common issues
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric Auth Error: $e");
      if (e.code == 'NotAvailable') {
        // This usually means biometrics aren't enrolled
        return false;
      }
      return false;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String>?> getCredentials() async {
    String? email = await _storage.read(key: 'email');
    String? password = await _storage.read(key: 'password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
  }
}
