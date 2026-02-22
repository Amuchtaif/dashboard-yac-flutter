import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'leaderboard_screen.dart';
import '../services/performance_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  final PerformanceService _performanceService = PerformanceService();

  bool isLoading = true;
  int totalPoints = 0;
  String grade = 'Loading...';
  String statusColorStr = '#94A3B8';
  List<Map<String, dynamic>> activities = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _performanceService.getPerformanceData();
    if (data != null && mounted) {
      setState(() {
        totalPoints = int.tryParse(data['total_points'].toString()) ?? 0;
        grade = data['status_text'] ?? 'Belum Ada Data';
        statusColorStr = data['status_color'] ?? '#94A3B8';
        if (data['history'] != null) {
          activities = List<Map<String, dynamic>>.from(data['history']);
        }
        isLoading = false;

        // Determine the next threshold for progress ring
        final nextThreshold = _getNextThreshold(totalPoints);
        final progress =
            nextThreshold > 0
                ? (totalPoints / nextThreshold).clamp(0.0, 1.0)
                : 0.0;

        _progressAnim = Tween<double>(begin: 0, end: progress).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
        _animController.forward(from: 0);
      });
    } else if (mounted) {
      setState(() {
        isLoading = false;
        grade = 'Data Tidak Tersedia';
        statusColorStr = '#94A3B8';
      });
    }
  }

  /// Returns the next status threshold to calculate progress ring.
  /// Returns the ceiling of the current tier so the ring fills proportionally.
  int _getNextThreshold(int points) {
    if (points <= 0) return 100; // -> Kurang
    if (points < 100) return 100; // -> Cukup
    if (points < 500) return 500; // -> Baik
    if (points < 800) return 800; // -> Sangat Baik
    return (points * 1.25).round(); // Beyond 800: keep growing
  }

  Color _hexToColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildScoreCard(),
                            const SizedBox(height: 20),
                            _buildCalculationCard(),
                            const SizedBox(height: 28),
                            _buildActivitySection(),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 40), // Spacer for centering
          Expanded(
            child: Text(
              'Kinerja Karyawan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () => _showInfoDialog(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SCORE CARD ──────────────────────────────────────
  Widget _buildScoreCard() {
    final statusColor = _hexToColor(statusColorStr);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Poin Kinerja',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          // Circular Progress
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _CircularScorePainter(
                    progress: _progressAnim.value,
                    trackColor: const Color(0xFFE2E8F0),
                    progressColor: statusColor,
                    strokeWidth: 12,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(totalPoints * _animController.value).round()}',
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'POIN',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Grade Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, color: statusColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  grade,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Check Leaderboard Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.leaderboard_rounded, size: 18),
              label: Text(
                'Cek Leaderboard',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CALCULATION LOGIC CARD ──────────────────────────
  Widget _buildCalculationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem Perhitungan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                _buildRuleRow(
                  'Absen Tepat Waktu',
                  '+10 Poin',
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 6),
                _buildRuleRow(
                  'Kehadiran Rapat',
                  '+10 Poin',
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 6),
                _buildRuleRow(
                  'Absen Telat',
                  '-5 Poin',
                  const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─── ACTIVITY SECTION ────────────────────────────────
  Widget _buildActivitySection() {
    if (activities.isEmpty) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Riwayat Aktivitas',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat aktivitas',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Aktivitas',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to full activity list
              },
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...activities.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final String pointsStr = activity['points']?.toString() ?? '0';
    final bool isPositive = !pointsStr.contains('-');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isPositive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
              color:
                  isPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Aktivitas',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity['date'] ?? ''} ${activity['time'] ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Points
          Text(
            pointsStr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  isPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO DIALOG ─────────────────────────────────────
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Tentang Poin Kinerja',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
            ),
            content: Text(
              'Poin kinerja dihitung berdasarkan aktivitas harian Anda. '
              'Poin akan terus bertambah seiring waktu.\n\n'
              '• Absen tepat waktu: +10 poin\n'
              '• Kehadiran rapat: +10 poin\n'
              '• Terlambat masuk: -5 poin\n\n'
              'Status Kinerja:\n'
              '• Kurang: 1 – 99 poin\n'
              '• Cukup: 100 – 499 poin\n'
              '• Baik: 500 – 799 poin\n'
              '• Sangat Baik: 800+ poin',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Mengerti',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

// ─── CIRCULAR SCORE PAINTER ────────────────────────────
class _CircularScorePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularScorePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background circle)
    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularScorePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
