import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  DateTime _focusedDay = DateTime(2024, 3, 11); // Set to March 2024 as in image
  DateTime? _selectedDay;

  // Mock events data
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime(2024, 3, 11): [
      {
        'title': 'Libur Awal Ramadhan',
        'type': 'LIBUR',
        'subtitle': 'Seluruh jenjang pendidikan',
      },
    ],
    DateTime(2024, 3, 18): [
      {
        'title': 'Ujian Tengah Semester',
        'type': 'UJIAN',
        'subtitle': 'Mulai: 08:00 WIB',
      },
    ],
    DateTime(2024, 3, 27): [
      {
        'title': 'Kegiatan Sekolah',
        'type': 'KEGIATAN',
        'subtitle': 'Seluruh siswa',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(2024, 3, 4); // March 4 is selected in the image
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFF8FAFC),
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agenda Mendatang',
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
          _agendaCard(
            '11',
            'MAR',
            'Libur Awal Ramadhan',
            'Seluruh jenjang pendidikan',
            const Color(0xFFC084FC),
          ),
          const SizedBox(height: 16),
          _agendaCard(
            '18',
            'MAR',
            'Ujian Tengah Semester',
            'Mulai: 08:00 WIB',
            const Color(0xFF60A5FA),
          ),
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
