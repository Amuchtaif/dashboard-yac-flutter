import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  final String message;
  final bool isSessionValid;

  const MaintenanceScreen({
    super.key,
    required this.message,
    this.isSessionValid = false,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isLoading = false;
  late String _currentMessage;

  @override
  void initState() {
    super.initState();
    _currentMessage = widget.message;
  }

  Future<void> _checkMaintenanceStatus() async {
    setState(() => _isLoading = true);

    try {
      final response = await http
          .get(Uri.parse("${ApiConfig.baseUrl}/app_status.php"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'maintenance') {
          setState(() {
            _currentMessage = data['message'] ?? widget.message;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Sistem masih dalam pemeliharaan"),
                backgroundColor: Colors.amber,
              ),
            );
          }
        } else {
          // Maintenance is over!
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => widget.isSessionValid
                    ? const DashboardScreen()
                    : const LoginScreen(),
              ),
              (route) => false,
            );
          }
        }
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memeriksa status: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction_rounded,
                size: 80,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Sistem Sedang\nDIPERBARUI",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                  SizedBox(height: 24),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkMaintenanceStatus,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        "Coba Lagi",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            Text(
              _isLoading ? "Memeriksa status..." : "Ketuk tombol untuk memuat ulang",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

