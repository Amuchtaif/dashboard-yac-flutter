import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tahfidz_repository.dart';
import '../../services/tahfidz_service.dart';

class ProfilSantriScreen extends StatefulWidget {
  const ProfilSantriScreen({super.key});

  @override
  State<ProfilSantriScreen> createState() => _ProfilSantriScreenState();
}

class _ProfilSantriScreenState extends State<ProfilSantriScreen> {
  final TahfidzService _tahfidzService = TahfidzService();

  List<dynamic> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? teacherId = prefs.getInt('userId');
      final studentsList = await _tahfidzService.getMyStudents(teacherId);

      if (mounted) {
        setState(() {
          _students = studentsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data santri: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil Santri',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStudents,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          child: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  ),
                )
              : _students.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada santri terdaftar',
                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = int.tryParse(student['id']?.toString() ?? '');
                        final studentName = student['nama_siswa'] ?? student['full_name'] ?? student['name'] ?? 'Santri';
                        final studentClass = student['kelas'] ?? student['nama_kelas'] ?? '-';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.withValues(alpha: 0.1),
                              child: Text(
                                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                style: GoogleFonts.poppins(color: Colors.teal, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              studentName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            subtitle: Text(
                              'Kelas: $studentClass',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailProfileScreen(
                                    studentId: studentId!,
                                    studentData: student,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

class StudentDetailProfileScreen extends StatefulWidget {
  final int studentId;
  final Map<String, dynamic> studentData;

  const StudentDetailProfileScreen({
    super.key,
    required this.studentId,
    required this.studentData,
  });

  @override
  State<StudentDetailProfileScreen> createState() => _StudentDetailProfileScreenState();
}

class _StudentDetailProfileScreenState extends State<StudentDetailProfileScreen> with SingleTickerProviderStateMixin {
  final TahfidzRepository _repository = TahfidzRepository();

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _summary = {};
  List<dynamic> _history = [];
  String _teacherName = '-';
  String _halaqahName = '-';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final summaryResult = await _repository.getDashboard(widget.studentId);
      final historyResult = await _repository.getEntries({
        'student_id': widget.studentId,
        'limit': '1000',
      });

      if (mounted) {
        if (summaryResult['success'] == true && historyResult['success'] == true) {
          setState(() {
            _summary = summaryResult['data'] ?? {};
            _history = historyResult['data'] ?? [];
            _teacherName = _summary['teacher_name'] ?? prefs.getString('fullName') ?? '-';
            _halaqahName = _summary['halaqah_name'] ?? '-';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Gagal memuat detail profil.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getFilteredHistory(String type) {
    return _history.where((e) {
      final entryType = e['entry_type'] ?? e['jenis_setoran'] ?? '';
      return entryType.toString().toUpperCase() == type.toUpperCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.studentData['nama_siswa'] ?? widget.studentData['full_name'] ?? widget.studentData['name'] ?? 'Santri';
    final studentClass = widget.studentData['kelas'] ?? widget.studentData['nama_kelas'] ?? '-';

    final double baselineJuz = double.tryParse(_summary['baseline_juz']?.toString() ?? '0') ?? 0.0;
    final double targetSemester = double.tryParse(_summary['target_semester']?.toString() ?? '0') ?? 0.0;
    final int totalHafalanBaru = int.tryParse(_summary['total_hafalan_baru']?.toString() ?? '0') ?? 0;
    final double totalHafalan = double.tryParse(_summary['total_juz']?.toString() ?? '0') ?? 0.0;
    final double percentage = double.tryParse(_summary['progress_semester']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F766E), size: 14),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Detail Profil Santri',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Identity card
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFFF0FDFA),
                                  child: Text(
                                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF0F766E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Kelas: $studentClass',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF065F46),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 14),
                          
                          // Halaqah & Ustadz Details
                          Row(
                            children: [
                              const Icon(Icons.group_work_rounded, color: Color(0xFF0D9488), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                                    children: [
                                      const TextSpan(text: 'Halaqah: '),
                                      TextSpan(
                                        text: _halaqahName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, color: Color(0xFF0D9488), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                                    children: [
                                      const TextSpan(text: 'Pengampu: '),
                                      TextSpan(
                                        text: _teacherName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Grid summary
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.3,
                            children: [
                              _buildSummaryMiniCard(
                                'Baseline Hafalan', 
                                '$baselineJuz Juz', 
                                Icons.playlist_add_check_rounded,
                                const Color(0xFF6366F1),
                                const Color(0xFFEEF2FF),
                              ),
                              _buildSummaryMiniCard(
                                'Target Semester', 
                                '$targetSemester Juz', 
                                Icons.flag_rounded,
                                const Color(0xFFF59E0B),
                                const Color(0xFFFEF3C7),
                              ),
                              _buildSummaryMiniCard(
                                'Hafalan Baru', 
                                '$totalHafalanBaru Setoran', 
                                Icons.menu_book_rounded,
                                const Color(0xFF10B981),
                                const Color(0xFFECFDF5),
                              ),
                              _buildSummaryMiniCard(
                                'Total Hafalan', 
                                '$totalHafalan Juz', 
                                Icons.stars_rounded,
                                const Color(0xFF0D9488),
                                const Color(0xFFF0FDFA),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Target achievement percentage bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pencapaian Target',
                                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (percentage / 100.0).clamp(0.0, 1.0),
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                                minHeight: 10,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab headers
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                        tabs: const [
                          Tab(text: 'Setoran'),
                          Tab(text: 'Murojaah'),
                          Tab(text: 'Tasmi\''),
                          Tab(text: 'Ujian'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHistoryTab('HAFALAN_BARU'),
                          _buildHistoryTab('MUROJAAH'),
                          _buildHistoryTab('TASMI'),
                          _buildHistoryTab('UJIAN'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryMiniCard(
    String label, 
    String val, 
    IconData icon, 
    Color accentColor, 
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  val,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(String type) {
    final list = _getFilteredHistory(type);
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Belum ada riwayat',
                style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final date = item['date'] != null
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['date']))
            : '-';
        final surahStart = item['surah_awal'] ?? item['surah_start'] ?? '';
        final surahEnd = item['surah_akhir'] ?? item['surah_end'] ?? '';
        final ayatStart = item['ayat_awal'] ?? item['start_ayah'] ?? item['ayat_start'] ?? '';
        final ayatEnd = item['ayat_akhir'] ?? item['end_ayah'] ?? item['ayat_end'] ?? '';
        final score = item['status'] ?? item['quality'] ?? item['nilai'] ?? item['score']?.toString() ?? '-';
        final notes = item['notes'] ?? item['catatan'] ?? '';

        // Status colors mapping
        Color statusColor = const Color(0xFF94A3B8); // Default gray
        Color statusBg = const Color(0xFFF1F5F9);
        String statusLabel = score;

        if (score.toLowerCase() == 'lancar' || score.toLowerCase() == 'ziyadah') {
          statusColor = const Color(0xFF10B981); // Green
          statusBg = const Color(0xFFECFDF5);
          statusLabel = 'Lancar';
        } else if (score.toLowerCase() == 'kurang' || score.toLowerCase() == 'kurang lancar') {
          statusColor = const Color(0xFFF59E0B); // Amber
          statusBg = const Color(0xFFFEF3C7);
          statusLabel = 'Kurang';
        } else if (score.toLowerCase() == 'tidak' || score.toLowerCase() == 'ulang' || score.toLowerCase() == 'tidak lancar') {
          statusColor = const Color(0xFFEF4444); // Red
          statusBg = const Color(0xFFFEF2F2);
          statusLabel = 'Ulang';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chrome_reader_mode_rounded, color: Color(0xFF0F766E), size: 20),
              ),
              title: Text(
                surahStart == surahEnd 
                    ? '$surahStart: $ayatStart - $ayatEnd' 
                    : '$surahStart ($ayatStart) s/d $surahEnd ($ayatEnd)',
                style: GoogleFonts.poppins(
                  fontSize: 13, 
                  color: const Color(0xFF1E293B), 
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  'Tanggal: $date',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10, 
                    color: statusColor, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes.isNotEmpty ? notes : 'Tidak ada catatan tambahan.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: notes.isNotEmpty ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                          fontStyle: notes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan pemuatan data',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfileData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
