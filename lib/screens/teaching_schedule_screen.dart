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

  Widget _buildScheduleCard(BuildContext context, Map<String, dynamic> item) {
    final startTime = _formatTime(item['start_time'] ?? '');
    final endTime = _formatTime(item['end_time'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TeachingJournalScreen(
                      scheduleId: item['id'].toString(),
                      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      subjectName: item['subject_name'] ?? 'Mata Pelajaran',
                      className: item['class_name'] ?? 'Kelas',
                      teacherName: item['teacher_name'] ?? 'Guru',
                    ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF42A5F5),
                    borderRadius: BorderRadius.only(
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
                                    item['subject_name'] ?? 'Mata Pelajaran',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFF1E88E5),
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
                              const Color(0xFFE3F2FD),
                              const Color(0xFF1565C0),
                            ),
                            _buildDetailItem(
                              Icons.people_alt,
                              item['class_name'] ?? 'Kelas',
                              const Color(0xFFE8F5E9),
                              const Color(0xFF2E7D32),
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
}
