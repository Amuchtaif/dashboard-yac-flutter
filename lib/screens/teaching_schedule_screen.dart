import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'session_detail_screen.dart';

class TeachingScheduleScreen extends StatelessWidget {
  const TeachingScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, dynamic>> schedules = [
      {
        'subject': 'Tahfidz Al-Quran',
        'time': '07:30 - 09:00 WIB',
        'class': 'Kelas 8A - Halaqah Al-Jazari',
        'location': 'Gedung A - Ruang 201',
        'icon': Icons.menu_book_rounded, // Book icon
        'type_icon': Icons.menu_book_rounded,
      },
      {
        'subject': 'Fiqh',
        'time': '09:15 - 10:45 WIB',
        'class': 'Kelas 9B - Akhwat',
        'location': 'Gedung B - Aula Utama',
        'icon': Icons.menu_book_rounded,
        'type_icon': Icons.menu_book_rounded,
      },
      {
        'subject': 'Bahasa Arab',
        'time': '11:00 - 12:30 WIB',
        'class': 'Kelas 7C - Ikhwan',
        'location': 'Gedung A - Ruang 105',
        'icon': Icons.translate_rounded, // Translate icon
        'type_icon': Icons.translate_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light grey background
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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final item = schedules[index];
          return _buildScheduleCard(context, item);
        },
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['subject'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF42A5F5), // Light Blue
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      item['type_icon'],
                      color: const Color(0xFF90CAF9), // Lighter blue for icon
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.access_time_filled, item['time']),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.people_alt, item['class']),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, item['location']),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionDetailScreen(sessionData: item),
                ),
              );
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'DETAIL SESI',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF42A5F5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF42A5F5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF64748B), // Slate 500
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF475569), // Slate 600
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
