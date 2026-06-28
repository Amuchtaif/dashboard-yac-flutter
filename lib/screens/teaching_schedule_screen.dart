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
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  Future<void> _fetchSchedule() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // Get selected day name in English
    final String englishDay = DateFormat('EEEE').format(_selectedDate);

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
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    debugPrint('Fetching schedule for day: $day ($englishDay), date: $formattedDate');

    try {
      final data = await _teacherService.getDailySchedule(day, date: formattedDate);
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
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : schedules.isEmpty
                ? Center(
                  child: Text(
                    'Tidak ada jadwal pada tanggal ini',
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 8),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final item = schedules[index];
                    return _buildScheduleCard(context, item);
                  },
                ),
          ),
        ],
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

    // Check if current time is within schedule range on the selected date
    final bool isTodaySelected = _isToday(_selectedDate);
    final bool isActive = isTodaySelected && _isWithinTimeRange(
      item['start_time'] ?? '00:00:00',
      item['end_time'] ?? '23:59:59',
    );

    final bool isJournalFilled =
        (item['is_journal_filled'] ?? 0).toString() != '0';
    final bool hasAttendance = (item['has_attendance'] ?? 0).toString() != '0';
    final bool isPast = _isPastDate(_selectedDate);
    final bool canAccess = isPast
        ? (isJournalFilled || hasAttendance)
        : (isActive || isJournalFilled || hasAttendance);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: canAccess ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (canAccess)
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
                              ).format(_selectedDate),
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
                    final String snackbarText = isPast
                        ? 'Tidak ada data absensi dan jurnal untuk tanggal ini'
                        : 'Jadwal ini hanya dapat diakses pada jam $startTime - $endTime';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          snackbarText,
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
            opacity: canAccess ? 1.0 : 0.6,
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
                                    ] else if (isPast) ...[
                                      const SizedBox(height: 8),
                                      _buildBadge(
                                        icon: Icons.cancel_outlined,
                                        label: 'Tidak ada data',
                                        bgColor: const Color(0xFFFFEBEE),
                                        textColor: const Color(0xFFC62828),
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

  Widget _buildDateSelector() {
    final bool isTodaySelected = _isToday(_selectedDate);
    final String formattedDate = _formatSelectedDate(_selectedDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF475569)),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _fetchSchedule();
            },
            tooltip: 'Hari Sebelumnya',
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      formattedDate,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                if (!isTodaySelected) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime.now();
                      });
                      _fetchSchedule();
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(
                        'Kembali ke Hari Ini',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E88E5),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isTodaySelected ? Colors.grey[300] : const Color(0xFF475569),
            ),
            onPressed: isTodaySelected
                ? null
                : () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _fetchSchedule();
                  },
            tooltip: 'Hari Berikutnya',
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF1E88E5),
                size: 20,
              ),
              onPressed: () => _selectDate(context),
              tooltip: 'Pilih Tanggal',
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Ahad'
    ];
    final List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final String dayName = days[date.weekday - 1];
    final String monthName = months[date.month - 1];

    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initial = _selectedDate.isAfter(now) ? now : _selectedDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E88E5),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSchedule();
    }
  }
}
