import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'teaching_journal_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const SessionDetailScreen({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Sesi Pelajaran',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SESI BERLANGSUNG',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E88E5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      sessionData['subject_name'] ?? 'Mata Pelajaran',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle (Class & Teacher)
                    _buildIconText(
                      Icons.people_outline,
                      sessionData['class_name'] ?? 'Kelas',
                    ),
                    const SizedBox(height: 8),
                    _buildIconText(
                      Icons.person_outline,
                      sessionData['teacher_name'] ?? 'Guru',
                    ),
                    const SizedBox(height: 32),

                    // Info Cards
                    _buildInfoItem(
                      Icons.access_time_filled,
                      'WAKTU SESI',
                      '${sessionData['start_time']} - ${sessionData['end_time']}',
                    ),
                    const SizedBox(height: 20),
                    _buildInfoItem(
                      Icons.calendar_today,
                      'TANGGAL',
                      DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoItem(
                      Icons.location_on,
                      'LOKASI',
                      sessionData['room_name'] ?? 'Lokasi',
                    ),
                    const SizedBox(height: 32),

                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 24),

                    // Agenda Section
                    Text(
                      'AGENDA PEMBELAJARAN',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAgendaItem(
                      'Silakan isi jurnal untuk mencatat agenda.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TeachingJournalScreen(
                      scheduleId:
                          (sessionData['id'] ?? sessionData['schedule_id'])
                              .toString(),
                      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      subjectName:
                          sessionData['subject_name'] ?? 'Mata Pelajaran',
                      className: sessionData['class_name'] ?? 'Kelas',
                      teacherName: sessionData['teacher_name'] ?? 'Guru',
                    ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note_rounded),
              const SizedBox(width: 8),
              Text(
                'Isi Jurnal & Absensi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF42A5F5), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF42A5F5), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
