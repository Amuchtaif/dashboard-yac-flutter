import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Hapus RPP?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus RPP ini?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Hapus',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );

    if (confirm == true) {
      _deleteRpp();
    }
  }

  Future<void> _deleteRpp() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _rppService.deleteRpp(widget.rpp['id'].toString());

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          Navigator.pop(context, 'deleted');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: ${result['message']}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
            onPressed: _shareRpp,
            icon: const Icon(
              Icons.share_outlined,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
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
                  if (result != null && context.mounted) {
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
            _buildSectionTitle('Kompetensi & Pertanyaan'),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Capaian Pembelajaran (CP)',
              rppData['content_cp'] ?? rppData['content_sk'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Alur Tujuan Pembelajaran (ATP)',
              rppData['content_atp'] ?? rppData['content_kd'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Pertanyaan Pemantik',
              rppData['content_pertanyaan_pemantik'] ??
                  rppData['content_indicator'] ??
                  '-',
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
              'Kegiatan Pembelajaran',
              rppData['content_steps'] ?? '-',
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Pendukung & Penilaian'),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Profil Pelajar Pancasila',
              rppData['teaching_profil_pancasila'] ??
                  rppData['teaching_method'] ??
                  '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Media & Sumber Belajar',
              rppData['content_summary'] ?? rppData['teaching_material'] ?? '-',
            ),
            const SizedBox(height: 16),
            _buildLongInfoCard(
              'Asesmen',
              rppData['assessment'] ?? '-',
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

  void _shareRpp() {
    final rppData = _fullRppData ?? widget.rpp;
    final String shareText = """
*MODUL AJAR (RPP) - KURIKULUM MERDEKA*
---------------------------------------
*JUDUL:* ${rppData['title'] ?? '-'}
*GURU:* ${rppData['teacher_name'] ?? '-'}
*MAPEL:* ${rppData['subject_name'] ?? '-'}
*KELAS:* ${rppData['grade_name'] ?? rppData['class_name'] ?? '-'}

*A. CAPAIAN PEMBELAJARAN (CP)*
${rppData['content_cp'] ?? rppData['content_sk'] ?? '-'}

*B. ALUR TUJUAN PEMBELAJARAN (ATP)*
${rppData['content_atp'] ?? rppData['content_kd'] ?? '-'}

*C. PERTANYAAN PEMANTIK*
${rppData['content_pertanyaan_pemantik'] ?? rppData['content_indicator'] ?? '-'}

*D. TUJUAN PEMBELAJARAN*
${rppData['learning_goal'] ?? rppData['objectives'] ?? '-'}

*E. MATERI AJAR*
${rppData['teaching_material'] ?? rppData['material'] ?? '-'}

*F. PROFIL PELAJAR PANCASILA*
${rppData['teaching_profil_pancasila'] ?? rppData['teaching_method'] ?? '-'}

*G. KEGIATAN PEMBELAJARAN*
${rppData['content_steps'] ?? '-'}

*H. MEDIA & SUMBER BELAJAR*
${rppData['content_summary'] ?? rppData['teaching_material'] ?? '-'}

*I. ASESMEN*
${rppData['assessment'] ?? '-'}
---------------------------------------
_Dikirim via Dashboard YAC_
""";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bagikan RPP',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () async {
                        Navigator.pop(context);
                        final url = Uri.parse(
                          "whatsapp://send?text=${Uri.encodeComponent(shareText)}",
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          final webUrl = Uri.parse(
                            "https://wa.me/?text=${Uri.encodeComponent(shareText)}",
                          );
                          await launchUrl(
                            webUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.copy_rounded,
                      label: 'Salin Teks',
                      color: const Color(0xFF4F46E5),
                      onTap: () {
                        Navigator.pop(context);
                        Clipboard.setData(ClipboardData(text: shareText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Teks RPP berhasil disalin!'),
                            backgroundColor: Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(20),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
