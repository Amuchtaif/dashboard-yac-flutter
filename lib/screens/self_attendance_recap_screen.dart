import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';

class SelfAttendanceRecapScreen extends StatefulWidget {
  const SelfAttendanceRecapScreen({super.key});

  @override
  State<SelfAttendanceRecapScreen> createState() =>
      _SelfAttendanceRecapScreenState();
}

class _SelfAttendanceRecapScreenState extends State<SelfAttendanceRecapScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  String _formatDayName(DateTime date, {String format = 'EEEE, dd MMM yyyy'}) {
    final str = DateFormat(format, 'id_ID').format(date);
    if (date.weekday == DateTime.sunday) {
      return str.replaceAll('Minggu', 'Ahad').replaceAll('Min', 'Ahd');
    }
    return str;
  }

  List<AttendanceActivity> _allHistory = [];
  bool _isLoading = true;
  DateTimeRange? _selectedRange;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Set of dates (YYYY-MM-DD) with recorded attendance (across all loaded history)
  Set<String> _attendedDays = {};

  // Cache to track which months have been fetched from API (e.g. "2026-9", "2026-10")
  final Set<String> _fetchedMonths = {};

  // Summary counts for current selected range
  int _totalAttendance = 0;
  int _onTimeCount = 0;
  int _lateCount = 0;
  int _leftEarlyCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedRange = _calculateDefaultRange();
    _focusedDay = DateTime.now();
    _initialFetch();
  }

  DateTimeRange _calculateDefaultRange() {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (now.day <= 25) {
      // Siklus: 26 bulan lalu s/d 25 bulan ini
      start = DateTime(now.year, now.month - 1, 26);
      end = DateTime(now.year, now.month, 25);
    } else {
      // Siklus: 26 bulan ini s/d 25 bulan depan
      start = DateTime(now.year, now.month, 26);
      end = DateTime(now.year, now.month + 1, 25);
    }

    return DateTimeRange(start: start, end: end);
  }

  Future<void> _initialFetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;

      if (userId != 0) {
        // 1. Fetch data for current calendar month
        final now = _focusedDay;
        final monthKey = '${now.year}-${now.month}';
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        final monthStart = DateFormat('yyyy-MM-dd').format(firstDay);
        final monthEnd = DateFormat('yyyy-MM-dd').format(lastDay);

        final monthData = await _attendanceService.getHistory(
          userId,
          startDate: monthStart,
          endDate: monthEnd,
        );

        // 2. Fetch data for default filter range if it extends beyond current month
        final rangeStart =
            _selectedRange != null
                ? DateFormat('yyyy-MM-dd').format(_selectedRange!.start)
                : monthStart;
        final rangeEnd =
            _selectedRange != null
                ? DateFormat('yyyy-MM-dd').format(_selectedRange!.end)
                : monthEnd;

        List<AttendanceActivity> rangeData = [];
        if (rangeStart != monthStart || rangeEnd != monthEnd) {
          rangeData = await _attendanceService.getHistory(
            userId,
            startDate: rangeStart,
            endDate: rangeEnd,
          );
        }

        if (mounted) {
          final Set<String> attendedDays = {};
          final existingIds = <int>{};
          final List<AttendanceActivity> allData = [];

          for (var a in [...monthData, ...rangeData]) {
            if (!existingIds.contains(a.id)) {
              existingIds.add(a.id);
              allData.add(a);
              final datePart = a.timestamp.split(' ')[0].trim();
              if (datePart.isNotEmpty) {
                attendedDays.add(datePart);
              }
            }
          }

          setState(() {
            _allHistory = allData;
            _attendedDays = attendedDays;
            _fetchedMonths.add(monthKey);
            _processHistoryData();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat kehadiran: $e')),
        );
      }
    }
  }

  // Fetch month data when user navigates to previous/next month in TableCalendar
  Future<void> _fetchCalendarMonth(DateTime month) async {
    final monthKey = '${month.year}-${month.month}';
    if (_fetchedMonths.contains(monthKey)) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;
      if (userId == 0) return;

      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      final startDate = DateFormat('yyyy-MM-dd').format(firstDay);
      final endDate = DateFormat('yyyy-MM-dd').format(lastDay);

      final data = await _attendanceService.getHistory(
        userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        final Set<String> newAttendedDays = Set.from(_attendedDays);
        final existingIds = _allHistory.map((a) => a.id).toSet();
        final List<AttendanceActivity> merged = List.from(_allHistory);

        for (var a in data) {
          final datePart = a.timestamp.split(' ')[0].trim();
          if (datePart.isNotEmpty) {
            newAttendedDays.add(datePart);
          }
          if (!existingIds.contains(a.id)) {
            merged.add(a);
            existingIds.add(a.id);
          }
        }

        setState(() {
          _allHistory = merged;
          _attendedDays = newAttendedDays;
          _fetchedMonths.add(monthKey);
        });
      }
    } catch (e) {
      debugPrint('Error fetching calendar month: $e');
    }
  }

  Future<void> _fetchRangeData(DateTimeRange range) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;
      if (userId == 0) return;

      final startDate = DateFormat('yyyy-MM-dd').format(range.start);
      final endDate = DateFormat('yyyy-MM-dd').format(range.end);

      final data = await _attendanceService.getHistory(
        userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        final Set<String> newAttendedDays = Set.from(_attendedDays);
        final existingIds = _allHistory.map((a) => a.id).toSet();
        final List<AttendanceActivity> merged = List.from(_allHistory);

        for (var a in data) {
          final datePart = a.timestamp.split(' ')[0].trim();
          if (datePart.isNotEmpty) {
            newAttendedDays.add(datePart);
          }
          if (!existingIds.contains(a.id)) {
            merged.add(a);
            existingIds.add(a.id);
          }
        }

        setState(() {
          _allHistory = merged;
          _attendedDays = newAttendedDays;
        });
      }
    } catch (e) {
      debugPrint('Error fetching range data: $e');
    }
  }

  void _processHistoryData() {
    if (_selectedRange == null) return;

    final startDate = DateTime(
      _selectedRange!.start.year,
      _selectedRange!.start.month,
      _selectedRange!.start.day,
    );
    final endDate = DateTime(
      _selectedRange!.end.year,
      _selectedRange!.end.month,
      _selectedRange!.end.day,
      23,
      59,
      59,
    );

    final Set<String> uniqueHadir = {};
    final Set<String> uniqueOnTime = {};
    final Set<String> uniqueLate = {};
    int earlyCount = 0;

    for (var activity in _allHistory) {
      final datePart = activity.timestamp.split(' ')[0].trim();
      if (datePart.isEmpty) continue;

      try {
        final dt = DateTime.parse(activity.timestamp);
        if (dt.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
            dt.isBefore(endDate.add(const Duration(milliseconds: 1)))) {
          final type = activity.type.toLowerCase().trim();
          final status = activity.status.toLowerCase().trim();

          uniqueHadir.add(datePart);

          if (type.contains('in') || type.contains('masuk')) {
            if (status.contains('terlambat') ||
                status.contains('telat') ||
                status.contains('late')) {
              uniqueLate.add(datePart);
            } else {
              uniqueOnTime.add(datePart);
            }
          } else if (type.contains('out') || type.contains('pulang')) {
            if (status.contains('cepat') || status.contains('early')) {
              earlyCount++;
            }
          }
        }
      } catch (_) {}
    }

    _totalAttendance = uniqueHadir.length;
    _onTimeCount = uniqueOnTime.length;
    _lateCount = uniqueLate.length;
    _leftEarlyCount = earlyCount;
  }

  Future<void> _selectDateRange() async {
    final defaultRange = _calculateDefaultRange();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedRange ?? defaultRange,
      helpText: 'Filter Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: Column(
            children: [
              Expanded(child: child!),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      onPressed: () {
                        // Reset filter ke default cycle (26-25)
                        Navigator.pop(context, defaultRange);
                      },
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      label: Text(
                        'Reset Filter',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      final isReset =
          picked.start == defaultRange.start &&
          picked.end == defaultRange.end &&
          (_selectedRange?.start != defaultRange.start ||
              _selectedRange?.end != defaultRange.end);

      setState(() {
        _selectedRange = picked;
        _selectedDay = null;
      });

      // Ensure data for picked range is fetched and process stats
      await _fetchRangeData(picked);
      _processHistoryData();

      if (mounted && isReset) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Filter tanggal direset ke default',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Only display dots for the currently focused month
    if (date.month != _focusedDay.month || date.year != _focusedDay.year) {
      return [];
    }

    // Future dates do not show dots
    if (date.isAfter(today)) {
      return [];
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // If attended -> Green dot
    if (_attendedDays.contains(dateKey)) {
      return ['hadir'];
    }

    // Tidak hadir -> Red dot (tanpa pengecualian hari Ahad)
    return ['tidak_hadir'];
  }

  List<AttendanceActivity> get _displayedHistory {
    List<AttendanceActivity> list;
    if (_selectedDay != null) {
      final selKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      list =
          _allHistory.where((activity) {
            return activity.timestamp.startsWith(selKey);
          }).toList();
    } else if (_selectedRange != null) {
      final startDate = DateTime(
        _selectedRange!.start.year,
        _selectedRange!.start.month,
        _selectedRange!.start.day,
      );
      final endDate = DateTime(
        _selectedRange!.end.year,
        _selectedRange!.end.month,
        _selectedRange!.end.day,
        23,
        59,
        59,
      );

      list =
          _allHistory.where((activity) {
            try {
              final dt = DateTime.parse(activity.timestamp);
              return dt.isAfter(
                    startDate.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  dt.isBefore(endDate.add(const Duration(milliseconds: 1)));
            } catch (_) {
              return false;
            }
          }).toList();
    } else {
      list = List.from(_allHistory);
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Rekap Kehadiran',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (_selectedRange != null)
              Text(
                '${DateFormat('dd MMM').format(_selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange!.end)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4F46E5),
              size: 22,
            ),
            tooltip: 'Filter Tanggal',
            onPressed: _selectDateRange,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              )
              : RefreshIndicator(
                color: const Color(0xFF4F46E5),
                onRefresh: () async {
                  _fetchedMonths.clear();
                  await _initialFetch();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildCalendarCard(),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                      _buildHistoryHeader(),
                      const SizedBox(height: 12),
                      _buildHistorySection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                if (isSameDay(_selectedDay, selectedDay)) {
                  _selectedDay = null;
                } else {
                  _selectedDay = selectedDay;
                }
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              // Fetch data for the new month if navigating backwards/forwards
              _fetchCalendarMonth(focusedDay);
            },
            eventLoader: _getEventsForDay,
            locale: 'id_ID',
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFF1E293B),
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFF1E293B),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) {
                if (date.weekday == DateTime.sunday) return 'Ahad';
                return DateFormat.E('id_ID').format(date);
              },
              weekdayStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              weekendStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4F46E5),
              ),
              defaultTextStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF1E293B),
              ),
              weekendTextStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
              outsideTextStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade300,
              ),
              markersMaxCount: 1,
              markerDecoration: const BoxDecoration(color: Colors.transparent),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                final status = events.first as String;
                final bool isHadir = status == 'hadir';
                final Color dotColor =
                    isHadir ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

                final bool isSelected = isSameDay(_selectedDay, day);

                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border:
                          isSelected
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.35),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Hadir',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Tidak Hadir',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Total Hadir',
                _totalAttendance.toString(),
                Icons.how_to_reg_rounded,
              ),
              _buildStatItem(
                'Tepat Waktu',
                _onTimeCount.toString(),
                Icons.timer_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Terlambat',
                _lateCount.toString(),
                Icons.timer_off_rounded,
              ),
              _buildStatItem(
                'Pulang Cepat',
                _leftEarlyCount.toString(),
                Icons.directions_run_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    final defaultRange = _calculateDefaultRange();
    final bool isCustomFilter =
        _selectedRange != null &&
        (_selectedRange!.start != defaultRange.start ||
            _selectedRange!.end != defaultRange.end);

    String title;
    if (_selectedDay != null) {
      title = _formatDayName(_selectedDay!);
    } else if (_selectedRange != null) {
      title =
          'Riwayat (${DateFormat('dd MMM').format(_selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange!.end)})';
    } else {
      title = 'Riwayat Kehadiran';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_selectedDay != null)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedDay = null;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ),
            )
          else if (isCustomFilter)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedRange = defaultRange;
                  _selectedDay = null;
                  _processHistoryData();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Filter tanggal direset ke default',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restart_alt_rounded,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reset Filter',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final list = _displayedHistory;

    if (list.isEmpty) {
      if (_selectedDay != null) {
        return _buildDayEmptyState(_selectedDay!);
      }
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(list[index]);
      },
    );
  }

  Widget _buildHistoryItem(AttendanceActivity activity) {
    final String type = activity.type.toLowerCase();
    final bool isCheckIn = type.contains('in') || type.contains('masuk');

    DateTime? timestamp;
    try {
      timestamp = DateTime.parse(activity.timestamp);
    } catch (_) {}

    final dateStr =
        timestamp != null ? _formatDayName(timestamp) : activity.timestamp;
    final timeStr =
        timestamp != null ? DateFormat('HH:mm').format(timestamp) : '';

    final bool isLate =
        activity.status.toLowerCase().contains('terlambat') ||
        activity.status.toLowerCase().contains('telat') ||
        activity.status.toLowerCase().contains('late');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isCheckIn ? const Color(0xFFEEF2FF) : const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
              color:
                  isCheckIn ? const Color(0xFF4F46E5) : const Color(0xFFEA580C),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (activity.status.isNotEmpty && activity.status != '-')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isLate
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activity.status,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isLate
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayEmptyState(DateTime day) {
    final formatted = _formatDayName(day, format: 'EEEE, dd MMMM yyyy');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak Ada Absensi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tidak tercatat kehadiran pada $formatted',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data kehadiran',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cobalah rentang tanggal lain',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
