import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'teaching_schedule_screen.dart';

class EducationMenuScreen extends StatelessWidget {
  const EducationMenuScreen({super.key});

  final List<Map<String, dynamic>> _subMenus = const [
    {
      'title': 'Data Siswa',
      'icon': Icons.people_outline,
      'color': Color(0xFF2196F3),
    },
    {
      'title': 'Data Guru',
      'icon': Icons.person_outline,
      'color': Color(0xFF4CAF50),
    },
    {
      'title': 'Kelas & Rombel',
      'icon': Icons.meeting_room_outlined,
      'color': Color(0xFFFF9800),
    },
    {
      'title': 'Mata Pelajaran',
      'icon': Icons.book_outlined,
      'color': Color(0xFF9C27B0),
    },
    {
      'title': 'Jadwal',
      'icon': Icons.calendar_today_outlined,
      'color': Color(0xFFE91E63),
    },
    {
      'title': 'Absensi Siswa',
      'icon': Icons.how_to_reg_outlined,
      'color': Color(0xFF00BCD4),
    },
    {
      'title': 'Kalender Akademik',
      'icon': Icons.event_note_outlined,
      'color': Color(0xFF3F51B5),
    },
  ];

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
          'Menu Pendidikan',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _subMenus.length,
        itemBuilder: (context, index) {
          final item = _subMenus[index];
          return _buildMenuCard(context, item);
        },
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item['title'] == 'Jadwal') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeachingScheduleScreen(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menu ${item['title']} akan segera hadir'),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
