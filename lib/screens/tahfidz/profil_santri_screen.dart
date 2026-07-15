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
                        final nis = student['nis'] ?? '-';

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
                              'NIS: $nis | Kelas: $studentClass',
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
      _teacherName = prefs.getString('fullName') ?? '-';

      final summaryResult = await _repository.getDashboard(widget.studentId);
      final historyResult = await _repository.getEntries({'student_id': widget.studentId});

      if (mounted) {
        if (summaryResult['success'] == true && historyResult['success'] == true) {
          setState(() {
            _summary = summaryResult['data'] ?? {};
            _history = historyResult['data'] ?? [];
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
    final nis = widget.studentData['nis'] ?? '-';

    final double baselineJuz = double.tryParse(_summary['baseline_juz']?.toString() ?? '0') ?? 0.0;
    final double targetSemester = double.tryParse(_summary['target_semester']?.toString() ?? '0') ?? 0.0;
    final int totalHafalanBaru = int.tryParse(_summary['total_hafalan_baru']?.toString() ?? '0') ?? 0;
    final double totalHafalan = double.tryParse(_summary['total_juz']?.toString() ?? '0') ?? 0.0;
    final double percentage = double.tryParse(_summary['progress_semester']?.toString() ?? '0') ?? 0.0;

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
          'Detail Profil Santri',
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
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    // Identity card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                                child: Text(
                                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                  style: GoogleFonts.poppins(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 24),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                                    ),
                                    Text(
                                      'NIS: $nis',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                    Text(
                                      'Kelas: $studentClass | Halaqah: $_teacherName',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
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
                            childAspectRatio: 2.2,
                            children: [
                              _buildSummaryMiniCard('Baseline Hafalan', '$baselineJuz Juz'),
                              _buildSummaryMiniCard('Target Semester', '$targetSemester Juz'),
                              _buildSummaryMiniCard('Hafalan Baru', '$totalHafalanBaru Setoran'),
                              _buildSummaryMiniCard('Total Hafalan', '$totalHafalan Juz'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Target achievement percentage bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pencapaian Target',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (percentage / 100.0).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                              minHeight: 8,
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tab headers
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.teal,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.teal,
                        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Setoran'),
                          Tab(text: 'Murojaah'),
                          Tab(text: 'Tasmi\''),
                          Tab(text: 'Ujian'),
                        ],
                      ),
                    ),

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

  Widget _buildSummaryMiniCard(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(String type) {
    final list = _getFilteredHistory(type);
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Belum ada riwayat',
          style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
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
        final surahStart = item['surah_awal'] ?? '';
        final surahEnd = item['surah_akhir'] ?? '';
        final ayatStart = item['ayat_awal'] ?? '';
        final ayatEnd = item['ayat_akhir'] ?? '';
        final score = item['nilai'] ?? '-';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$surahStart (Ayat $ayatStart) s/d $surahEnd (Ayat $ayatEnd)',
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tanggal: $date',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (score != null && score != '-') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Nilai: $score',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
