import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceSuccessDialog extends StatefulWidget {
  final String? type; // 'IN' (Masuk) or 'OUT' (Pulang)
  final String? message;
  final String? time;
  final String? date;
  final String? locationName;
  final String? status;
  final Duration autoCloseDuration;

  const AttendanceSuccessDialog({
    super.key,
    this.type,
    this.message,
    this.time,
    this.date,
    this.locationName,
    this.status,
    this.autoCloseDuration = const Duration(seconds: 3),
  });

  @override
  State<AttendanceSuccessDialog> createState() =>
      _AttendanceSuccessDialogState();
}

class _AttendanceSuccessDialogState extends State<AttendanceSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Box scale & pop animation
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    // Checkmark draw animation
    _checkAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeInOutCubic),
    );

    _animController.forward();

    // Auto-close dialog setelah delay 3 detik
    if (widget.autoCloseDuration > Duration.zero) {
      _autoCloseTimer = Timer(widget.autoCloseDuration, () {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Base blue color aplikasi
    const primaryColor = Color(0xFF2563EB); // Royal / Brand Blue YAC

    final isCheckIn = (widget.type ?? 'IN').toUpperCase() == 'IN';
    final title =
        isCheckIn ? 'Absen Masuk Berhasil!' : 'Absen Pulang Berhasil!';
    final subtitle = widget.message ?? 'Anda berhasil melakukan absensi';

    return PopScope(
      canPop: false, // Mencegah dismiss tak sengaja
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- TOP HEADER WITH ANIMATED CHECKBOX ---
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 20),
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _checkAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _AnimatedCheckmarkPainter(
                                progress: _checkAnimation.value,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- TITLE & SUBTITLE ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // --- ACTION BUTTON ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      _autoCloseTimer?.cancel();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Oke',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter untuk animasi checkmark yang menggambar checklist secara halus
class _AnimatedCheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnimatedCheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Checkmark points relative to size
    final p1 = Offset(w * 0.28, h * 0.52);
    final p2 = Offset(w * 0.44, h * 0.68);
    final p3 = Offset(w * 0.72, h * 0.36);

    final path = Path();

    if (progress <= 0.4) {
      // Draw first segment (p1 to p2)
      final t = progress / 0.4;
      final current = Offset.lerp(p1, p2, t)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(current.dx, current.dy);
    } else {
      // First segment is complete
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);

      // Draw second segment (p2 to p3)
      final t = (progress - 0.4) / 0.6;
      final current = Offset.lerp(p2, p3, t)!;
      path.lineTo(current.dx, current.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
