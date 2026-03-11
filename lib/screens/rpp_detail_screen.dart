import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/rpp_service.dart';
import 'create_rpp_screen.dart';

class RppDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rpp;

  const RppDetailScreen({super.key, required this.rpp});

  @override
  State<RppDetailScreen> createState() => _RppDetailScreenState();
}

class _RppDetailScreenState extends State<RppDetailScreen> {
  final RppService _rppService = RppService();
  Map<String, dynamic>? _fullRppData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final detail = await _rppService.getRppDetail(widget.rpp['id'].toString());
    if (mounted) {
      if (detail != null) {
        setState(() {
          _fullRppData = detail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _fullRppData = widget.rpp;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    final rppData = _fullRppData ?? widget.rpp;
    final bool isDraft =
        rppData['is_draft'] == 1 || rppData['is_draft'] == true;

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
          overflow: TextOverflow.ellipsis,
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
      floatingActionButton:
          isDraft
              ? FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CreateRppScreen(initialRppData: rppData),
                    ),
                  );
                  if (result != null) {
                    // refresh or pop with result
                    Navigator.pop(context, result);
                  }
                },
                backgroundColor: const Color(0xFF4F46E5),
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                label: Text(
                  'Lanjutkan Draft',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
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
                          (rppData['level_name'] ??
                                  rppData['unit_name'] ??
                                  'JENJANG')
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
                        rppData['created_at'] != null
                            ? (rppData['created_at'] as String).substring(0, 10)
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
                    rppData['title'] ?? 'Judul RPP',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildMiniInfo(
                        Icons.person_rounded,
                        rppData['teacher_name'] ?? '-',
                      ),
                      _buildMiniInfo(
                        Icons.book_rounded,
                        rppData['subject_name'] ?? '-',
                      ),
                      _buildMiniInfo(
                        Icons.people_alt_rounded,
                        rppData['grade_name'] ?? rppData['class_name'] ?? '-',
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
              _buildInfoItem('Tahun Ajaran', rppData['academic_year'] ?? '-'),
              _buildInfoItem('Semester', rppData['semester'] ?? '-'),
              _buildInfoItem(
                'Pertemuan',
                'Ke-${rppData['session_no'] ?? rppData['meeting_no'] ?? '1'}',
              ),
              _buildInfoItem(
                'Alokasi Waktu',
                rppData['allocation'] ?? rppData['time_allocation'] ?? '-',
              ),
            ]),

            const SizedBox(height: 32),
            _buildSectionTitle('Kompetensi & Indikator'),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Standar Kompetensi',
              rppData['content_sk'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Kompetensi Dasar',
              rppData['content_kd'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Indikator',
              rppData['content_indicator'] ?? '-',
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Rencana Pembelajaran'),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Tujuan Pembelajaran',
              rppData['learning_goal'] ?? rppData['objectives'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Materi Ajar',
              rppData['teaching_material'] ?? rppData['material'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Langkah Pembelajaran',
              rppData['content_steps'] ?? '-',
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Pendukung & Penilaian'),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Alat & Sumber',
              rppData['teaching_method'] ?? rppData['resources'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Penilaian',
              rppData['assessment'] ?? rppData['content_summary'] ?? '-',
            ),

            const SizedBox(height: 100), // padding for FAB
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
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
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    final displayValue = (value.isEmpty) ? '-' : value;
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
            displayValue,
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
