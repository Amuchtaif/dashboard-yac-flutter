import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/rpp_service.dart';
import 'create_rpp_screen.dart';
import 'rpp_detail_screen.dart';

class RppScreen extends StatefulWidget {
  const RppScreen({super.key});

  @override
  State<RppScreen> createState() => _RppScreenState();
}

class _RppScreenState extends State<RppScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RppService _rppService = RppService();

  Map<String, dynamic>? _activePeriod;
  bool _isLoadingHeader = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHeaderData();
  }

  Future<void> _loadHeaderData() async {
    final period = await _rppService.getActivePeriod();
    if (mounted) {
      setState(() {
        _activePeriod = period;
        _isLoadingHeader = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        const SizedBox(height: 24),
                        _buildTabSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRppList(isDraft: false),
                        _buildRppList(isDraft: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRppScreen()),
          );
          if (result != null) {
            if (result == 'published') {
              _tabController.animateTo(0);
            } else if (result == 'draft') {
              _tabController.animateTo(1);
            }
            setState(() {}); // Refresh lists
          }
        },
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Buat RPP Baru',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rencana Pembelajaran',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semester Aktif',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                _isLoadingHeader
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      _activePeriod != null && _activePeriod!.isNotEmpty
                          ? '${_activePeriod!['semester']} ${_activePeriod!['academic_year_name']}'
                          : 'Pilih Semester',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFF4F46E5),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [Tab(text: 'Daftar RPP'), Tab(text: 'Draft')],
      ),
    );
  }

  Widget _buildRppList({required bool isDraft}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _rppService.getRppList(isDraft: isDraft),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  isDraft
                      ? 'Belum ada draft RPP'
                      : 'Belum ada RPP yang diterbitkan',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final rppData = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: rppData.length,
          itemBuilder: (context, index) {
            return _buildRppCard(rppData[index]);
          },
        );
      },
    );
  }

  Widget _buildRppCard(Map<String, dynamic> rpp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RppDetailScreen(rpp: rpp),
              ),
            );
            if (result != null) {
              if (result == 'published') {
                _tabController.animateTo(0);
              } else if (result == 'draft') {
                _tabController.animateTo(1);
              }
              setState(() {});
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          rpp['created_at'] != null
                              ? (rpp['created_at'] as String).substring(0, 10)
                              : 'Baru Saja',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'duplicate') {
                          _duplicateRpp(rpp);
                        } else if (value == 'delete') {
                          _confirmDeleteRpp(rpp);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.copy_all_rounded,
                                    size: 18,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Duplikat ke Draft',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Hapus RPP',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Color(0xFF94A3B8),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  rpp['title'] ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardInfo(
                        Icons.book_outlined,
                        rpp['subject_name'] ?? '-',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCardInfo(
                        Icons.people_outline_rounded,
                        '${rpp['grade_name'] ?? rpp['class_name'] ?? '-'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Center(
                          child: Text(
                            'Lihat Detail Rencana',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _duplicateRpp(Map<String, dynamic> rpp) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get full detail to ensure we have all fields for duplication
      final fullData = await _rppService.getRppDetail(rpp['id'].toString());

      if (fullData == null) {
        if (mounted) Navigator.pop(context);
        throw Exception('Gagal mengambil data detail RPP');
      }

      // Prepare data for new RPP
      final Map<String, dynamic> newData = {
        'academic_year_id': fullData['academic_year_id'] ?? 1,
        'semester': fullData['semester'] ?? 'Ganjil',
        'education_unit_id': fullData['education_unit_id'] ?? 1,
        'grade_level_id': fullData['grade_level_id'] ?? 0,
        'subject_id': fullData['subject_id'] ?? 0,
        'session_no': fullData['session_no'] ?? fullData['meeting_no'] ?? '1',
        'allocation':
            fullData['allocation'] ?? fullData['time_allocation'] ?? '-',
        'title': '${fullData['title'] ?? 'Tanpa Judul'} (Duplikat)',
        'content_cp': fullData['content_cp'] ?? fullData['content_sk'] ?? '',
        'content_atp': fullData['content_atp'] ?? fullData['content_kd'] ?? '',
        'content_pertanyaan_pemantik':
            fullData['content_pertanyaan_pemantik'] ??
            fullData['content_indicator'] ??
            '',
        'learning_goal':
            fullData['learning_goal'] ?? fullData['objectives'] ?? '',
        'teaching_material':
            fullData['teaching_material'] ?? fullData['material'] ?? '',
        'teaching_profil_pancasila':
            fullData['teaching_profil_pancasila'] ??
            fullData['teaching_method'] ??
            '',
        'content_steps': fullData['content_steps'] ?? '',
        'content_summary': fullData['content_summary'] ?? '',
        'assessment': fullData['assessment'] ?? '',
        'is_draft': 1,
      };

      final result = await _rppService.createRpp(newData);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true || result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RPP Berhasil Diduplikasi ke Draft!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _tabController.animateTo(1); // Switch to draft tab
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal duplikasi: ${result['message']}'),
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

  Future<void> _confirmDeleteRpp(Map<String, dynamic> rpp) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Hapus RPP?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus RPP "${rpp['title']}"? Tindakan ini tidak dapat dibatalkan.',
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
      _deleteRpp(rpp['id'].toString());
    }
  }

  Future<void> _deleteRpp(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _rppService.deleteRpp(id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RPP Berhasil Dihapus!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {});
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

  Widget _buildCardInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
