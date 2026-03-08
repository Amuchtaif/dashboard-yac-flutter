import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RppDetailScreen extends StatelessWidget {
  final Map<String, dynamic> rpp;

  const RppDetailScreen({super.key, required this.rpp});

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
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail RPP',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.share_outlined,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (rpp['level_name'] ?? 'JENJANG')
                              .toString()
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      Text(
                        rpp['created_at'] != null
                            ? (rpp['created_at'] as String).substring(0, 10)
                            : '-',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    rpp['title'] ?? 'Judul RPP',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniInfo(
                        Icons.book_rounded,
                        rpp['subject_name'] ?? '-',
                      ),
                      const SizedBox(width: 16),
                      _buildMiniInfo(
                        Icons.people_alt_rounded,
                        rpp['class_name'] ?? '-',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Informasi Identitas'),
            const SizedBox(height: 16),
            _buildInfoGrid([
              _buildInfoItem('Tahun Ajaran', rpp['academic_year'] ?? '-'),
              _buildInfoItem('Semester', rpp['semester'] ?? '-'),
              _buildInfoItem('Pertemuan', 'Ke-${rpp['meeting_no'] ?? '1'}'),
              _buildInfoItem('Alokasi Waktu', rpp['time_allocation'] ?? '-'),
            ]),

            const SizedBox(height: 32),
            _buildSectionTitle('Kompetensi & Indikator'),
            const SizedBox(height: 16),
            _buildLongInfoCard('Standar Kompetensi', rpp['content_sk'] ?? '-'),
            const SizedBox(height: 16),
            _buildLongInfoCard('Kompetensi Dasar', rpp['content_kd'] ?? '-'),
            const SizedBox(height: 16),
            _buildLongInfoCard('Indikator', rpp['content_indicator'] ?? '-'),

            const SizedBox(height: 32),
            _buildSectionTitle('Rencana Pembelajaran'),
            const SizedBox(height: 16),
            _buildLongInfoCard('Tujuan Pembelajaran', rpp['objectives'] ?? '-'),
            const SizedBox(height: 16),
            _buildLongInfoCard('Materi Ajar', rpp['material'] ?? '-'),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Langkah Pembelajaran',
              rpp['content_steps'] ?? '-',
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Pendukung & Penilaian'),
            const SizedBox(height: 16),
            _buildLongInfoCard('Alat & Sumber', rpp['resources'] ?? '-'),
            const SizedBox(height: 16),
            _buildLongInfoCard('Penilaian', rpp['content_summary'] ?? '-'),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 2.5,
        children: children,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildLongInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
