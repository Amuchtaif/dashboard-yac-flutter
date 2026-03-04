import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/teacher_service.dart';
import 'teaching_journal_screen.dart';

class TeachingScheduleScreen extends StatefulWidget {
  const TeachingScheduleScreen({super.key});

  @override
  State<TeachingScheduleScreen> createState() => _TeachingScheduleScreenState();
}

class _TeachingScheduleScreenState extends State<TeachingScheduleScreen> {
  final TeacherService _teacherService = TeacherService();
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    // Get current day name in English
    final String englishDay = DateFormat('EEEE').format(DateTime.now());

    // Map to Indonesian day names for API
    final Map<String, String> dayMap = {
      'Monday': 'Senin',
      'Tuesday': 'Selasa',
      'Wednesday': 'Rabu',
      'Thursday': 'Kamis',
      'Friday': 'Jumat',
      'Saturday': 'Sabtu',
      'Sunday': 'Ahad',
    };

    final String day = dayMap[englishDay] ?? 'Senin';

    debugPrint('Fetching schedule for day: $day ($englishDay)');

    try {
      final data = await _teacherService.getDailySchedule(day);
      if (mounted) {
        setState(() {
          schedules = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat jadwal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Jadwal Mengajar',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : schedules.isEmpty
              ? Center(
                child: Text(
                  'Tidak ada jadwal hari ini',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final item = schedules[index];
                  return _buildScheduleCard(context, item);
                },
              ),
    );
  }

  String _formatTime(String time) {
    try {
      final dateTime = DateFormat('HH:mm:ss').parse(time);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      if (time.length >= 5) {
        return time.substring(0, 5);
      }
      return time;
    }
  }

  bool _isWithinTimeRange(String startStr, String endStr) {
    try {
      final now = DateTime.now();

      // Use a consistent date for comparison
      final today = DateFormat('yyyy-MM-dd').format(now);
      final start = DateTime.parse('$today $startStr');
      final end = DateTime.parse('$today $endStr');

      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return false;
    }
  }

  Widget _buildScheduleCard(BuildContext context, Map<String, dynamic> item) {
    final startTime = _formatTime(item['start_time'] ?? '');
    final endTime = _formatTime(item['end_time'] ?? '');

    // Check if current time is within schedule range
    // Check if current time is within schedule range
    final bool isActive = _isWithinTimeRange(
      item['start_time'] ?? '00:00:00',
      item['end_time'] ?? '23:59:59',
    );

    final bool isJournalFilled =
        (item['is_journal_filled'] ?? 0).toString() != '0';
    final bool hasAttendance = (item['has_attendance'] ?? 0).toString() != '0';
    final bool canAccess = isActive || isJournalFilled || hasAttendance;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              canAccess
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TeachingJournalScreen(
                              scheduleId: item['id'].toString(),
                              date: DateFormat(
                                'yyyy-MM-dd',
                              ).format(DateTime.now()),
                              subjectName:
                                  item['subject_name'] ?? 'Mata Pelajaran',
                              className: item['class_name'] ?? 'Kelas',
                              teacherName: item['teacher_name'] ?? 'Guru',
                            ),
                      ),
                    ).then((value) {
                      _fetchSchedule();
                    });
                  }
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Jadwal ini hanya dapat diakses pada jam $startTime - $endTime',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: const Color(0xFF475569),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.6,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF42A5F5) : Colors.grey,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MATA PELAJARAN',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            isActive
                                                ? const Color(0xFF64748B)
                                                : Colors.grey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subject_name'] ?? 'Mata Pelajaran',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            canAccess
                                                ? const Color(0xFF0F172A)
                                                : Colors.grey[600],
                                        height: 1.2,
                                      ),
                                    ),
                                    if (isJournalFilled) ...[
                                      const SizedBox(height: 8),
                                      _buildBadge(
                                        icon: Icons.check_circle,
                                        label: 'Anda telah mengajar',
                                        bgColor: const Color(0xFFE8F5E9),
                                        textColor: const Color(0xFF2E7D32),
                                      ),
                                    ] else if (hasAttendance) ...[
                                      const SizedBox(height: 8),
                                      _buildBadge(
                                        icon: Icons.info_outline,
                                        label: 'Anda belum isi jurnal',
                                        bgColor: const Color(0xFFFFF3E0),
                                        textColor: const Color(0xFFE65100),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      isActive
                                          ? const Color(0xFFE3F2FD)
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color:
                                      isActive
                                          ? const Color(0xFF1E88E5)
                                          : Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildDetailItem(
                                Icons.access_time_filled,
                                '$startTime - $endTime',
                                isActive
                                    ? const Color(0xFFE3F2FD)
                                    : Colors.grey[200]!,
                                isActive
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey[600]!,
                              ),
                              _buildDetailItem(
                                Icons.people_alt,
                                item['class_name'] ?? 'Kelas',
                                isActive
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.grey[200]!,
                                isActive
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[600]!,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
