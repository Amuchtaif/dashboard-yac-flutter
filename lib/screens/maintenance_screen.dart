import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_status_provider.dart';

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
  String? _errorFeedback;

  Future<void> _checkMaintenanceStatus() async {
    setState(() {
      _isLoading = true;
      _errorFeedback = null;
    });

    try {
      final provider = context.read<AppStatusProvider>();
      // Clear any existing snackbars from previous attempts
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final isStillMaintenance = await provider.checkStatus();

      if (mounted) {
        if (isStillMaintenance) {
          setState(() {
            _errorFeedback =
                "Sistem masih dalam pemeliharaan. Silakan coba beberapa saat lagi.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorFeedback =
              "Gagal terhubung ke server. Periksa koneksi internet Anda.";
        });
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
              "Sistem Sedang\nDalam Pemeliharaan",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
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
                  if (_errorFeedback != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorFeedback!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkMaintenanceStatus,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        "Coba Lagi",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
              _isLoading
                  ? "Memeriksa status..."
                  : "Ketuk tombol untuk memuat ulang",
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
