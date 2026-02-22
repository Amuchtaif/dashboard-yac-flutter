import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/teacher_service.dart';
import 'package:intl/intl.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  final TeacherService _teacherService = TeacherService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  // Real events data from API
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchCalendarData(_focusedDay.year);
  }

  Future<void> _fetchCalendarData(int year) async {
    setState(() => _isLoading = true);
    try {
      final results = await _teacherService.getAcademicCalendar(year);
      _events.clear();

      for (var item in results) {
        if (item['start_date'] != null) {
          final startDate = DateTime.parse(item['start_date']);
          final endDate =
              item['end_date'] != null
                  ? DateTime.parse(item['end_date'])
                  : startDate;

          // Use category from API, default to KEGIATAN
          String category = (item['category'] ?? 'KEGIATAN').toString();
          if (item['is_holiday'] == true) category = 'LIBUR';

          final eventData = {
            'title': item['title'] ?? '-',
            'type': category.toUpperCase(),
            'subtitle': item['description'] ?? '',
            'start_date': startDate,
            'end_date': endDate,
          };

          // Add event to every day in range
          for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
            final date = startDate.add(Duration(days: i));
            final normalizedDate = DateTime(date.year, date.month, date.day);

            if (_events[normalizedDate] == null) {
              _events[normalizedDate] = [];
            }
            _events[normalizedDate]!.add(eventData);
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading calendar: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    // Normalize time to midnight for map lookup
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Kalender Akademik',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCalendarCard(),
                    const SizedBox(height: 24),
                    _buildLegend(),
                    const SizedBox(height: 32),
                    _buildUpcomingAgenda(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          if (focusedDay.year != _focusedDay.year) {
            _fetchCalendarData(focusedDay.year);
          }
          _focusedDay = focusedDay;
        },
        eventLoader: _getEventsForDay,
        locale: 'id_ID',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
          weekdayStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          dowTextFormatter: (date, locale) {
            // S S R K J S M
            final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
            return days[date.weekday - 1];
          },
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF42A5F5),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white),
          defaultTextStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          weekendTextStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.blue.shade300,
          ),
          outsideTextStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade300,
          ),
          markersMaxCount: 1,
          markerDecoration: const BoxDecoration(
            color: Colors.transparent, // Default empty
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;

            final event = events.first as Map<String, dynamic>;
            Color markerColor = Colors.grey;
            if (event['type'] == 'LIBUR') {
              markerColor = const Color(0xFFC084FC); // Purple
            }
            if (event['type'] == 'UJIAN') {
              markerColor = const Color(0xFF60A5FA); // Blue
            }
            if (event['type'] == 'KEGIATAN') {
              markerColor = const Color(0xFF34D399); // Green
            }

            return Positioned(
              bottom: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(const Color(0xFFC084FC), 'LIBUR'),
          const SizedBox(width: 20),
          _legendItem(const Color(0xFF60A5FA), 'UJIAN'),
          const SizedBox(width: 20),
          _legendItem(const Color(0xFF34D399), 'KEGIATAN'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAgenda() {
    // Collect unique events based on title and start date
    final uniqueEvents = <String, Map<String, dynamic>>{};

    _events.forEach((date, events) {
      for (var event in events) {
        final start = event['start_date'];
        if (start == null) continue;

        final key = "${event['title']}_$start";
        if (!uniqueEvents.containsKey(key)) {
          uniqueEvents[key] = event;
        }
      }
    });

    final allEvents = uniqueEvents.values.toList();
    allEvents.sort((a, b) {
      final dateA = a['start_date'] as DateTime?;
      final dateB = b['start_date'] as DateTime?;
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agenda Akademik',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Tidak ada agenda untuk tahun ini',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...allEvents.map((e) {
              final startDate = e['start_date'] as DateTime?;
              final endDate = e['end_date'] as DateTime? ?? startDate;

              if (startDate == null) return const SizedBox();

              Color typeColor = const Color(0xFF34D399);
              if (e['type'] == 'LIBUR') typeColor = const Color(0xFFC084FC);
              if (e['type'] == 'UJIAN') typeColor = const Color(0xFF60A5FA);

              String dateDisplay = DateFormat(
                'd MMM',
                'id_ID',
              ).format(startDate);
              if (endDate != null && !isSameDay(startDate, endDate)) {
                if (startDate.month == endDate.month) {
                  dateDisplay =
                      '${startDate.day} - ${endDate.day} ${DateFormat('MMM', 'id_ID').format(startDate)}';
                } else {
                  dateDisplay =
                      '${DateFormat('d MMM', 'id_ID').format(startDate)} - ${DateFormat('d MMM', 'id_ID').format(endDate)}';
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _agendaCard(
                  startDate.day.toString(),
                  DateFormat('MMM', 'id_ID').format(startDate).toUpperCase(),
                  e['title'] ?? '-',
                  '$dateDisplay • ${e['subtitle'] ?? ''}',
                  typeColor,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _agendaCard(
    String day,
    String month,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Column(
              children: [
                Text(
                  day,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  month,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
