import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../services/teacher_service.dart';

import 'class_journal_screen.dart';

class TeachingJournalScreen extends StatefulWidget {
  final String scheduleId;
  final String date;
  final String subjectName;
  final String className;

  const TeachingJournalScreen({
    super.key,
    required this.scheduleId,
    required this.date,
    required this.subjectName,
    required this.className,
    required this.teacherName,
  });

  final String teacherName;

  @override
  State<TeachingJournalScreen> createState() => _TeachingJournalScreenState();
}

class _TeachingJournalScreenState extends State<TeachingJournalScreen> {
  final TeacherService _teacherService = TeacherService();
  final _formKey = GlobalKey<FormState>();

  // Controllers

  // State
  bool isLoading = true;
  bool isSubmitting = false;
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {}; // student_id -> status
  Map<String, dynamic>? journalData;
  bool isJournalFilled = false;

  // Mapping from DB values to UI values
  final Map<String, String> _dbToUi = {
    'present': 'Hadir',
    'sick': 'Sakit',
    'permit': 'Izin',
    'absent': 'Alpha',
    'late': 'Alpha', // fallback
  };

  // Mapping from UI values to DB values
  final Map<String, String> _uiToDb = {
    'Hadir': 'present',
    'Sakit': 'sick',
    'Izin': 'permit',
    'Alpha': 'absent',
  };

  // Attendance Options
  final List<String> statusOptions = ['Hadir', 'Sakit', 'Izin', 'Alpha'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _teacherService.getStudentsBySchedule(
        widget.scheduleId,
        widget.date,
      );

      if (mounted) {
        setState(() {
          // Assuming data struct from API: { 'students': [...], 'journal': {...} }
          // If the API returns raw students list or detailed structure, adjust here.
          // Based on user request: "Mengambil daftar siswa... Juga mengembalikan data jurnal jika sudah ada."

          if (data['students'] != null) {
            students = List<Map<String, dynamic>>.from(data['students']);
            // Initialize attendance status
            for (var student in students) {
              final dbStatus = student['status']?.toString() ?? '';
              attendanceStatus[student['student_id'].toString()] =
                  _dbToUi[dbStatus] ?? 'Hadir';
            }
          }

          if (data['journal'] != null) {
            journalData = data['journal'];
            isJournalFilled = true;
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  void _navigateToJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ClassJournalScreen(
              scheduleId: widget.scheduleId,
              date: widget.date,
              subjectName: widget.subjectName,
              className: widget.className,
              teacherName: widget.teacherName,
              attendanceStatus: attendanceStatus,
              uiToDbMapping: _uiToDb,
              totalStudents: students.length,
              existingJournal: journalData,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Absensi Siswa',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildStudentList(),
                      const SizedBox(height: 80), // Spacer FAB
                    ],
                  ),
                ),
              ),
      floatingActionButton:
          isLoading
              ? null
              : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToJournal,
                    icon: Icon(
                      isJournalFilled
                          ? Icons.description_outlined
                          : Icons.arrow_forward,
                      color: Colors.white,
                    ),
                    label: Text(
                      isJournalFilled
                          ? 'Lihat Detail Jurnal'
                          : 'Lanjut Isi Jurnal',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: const Color(
                        0xFF42A5F5,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSummaryCards() {
    int total = students.length;
    int hadir = attendanceStatus.values.where((s) => s == 'Hadir').length;
    int sakit = attendanceStatus.values.where((s) => s == 'Sakit').length;
    int izin = attendanceStatus.values.where((s) => s == 'Izin').length;
    int alpha = attendanceStatus.values.where((s) => s == 'Alpha').length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            'Total',
            total.toString(),
            const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryItem(
            'Hadir',
            hadir.toString(),
            const Color(0xFF00C853),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryItem(
            'Sakit',
            sakit.toString(),
            const Color(0xFFFFA000),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryItem(
            'Izin',
            izin.toString(),
            const Color(0xFF039BE5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryItem(
            'Alpha',
            alpha.toString(),
            const Color(0xFFE53935),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = student['student_id'].toString();

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
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      student['student_name']?[0] ?? 'S',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    // Assuming no image URL in data, using initial.
                    // If image URL exists: backgroundImage: NetworkImage(student['photo_url']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['student_name'] ?? 'Nama Siswa',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'ID: $studentId • ${widget.className}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      statusOptions.map((status) {
                        final isSelected =
                            attendanceStatus[studentId] == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap:
                                isJournalFilled
                                    ? null
                                    : () {
                                      setState(() {
                                        attendanceStatus[studentId] = status;
                                      });
                                    },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? _getStatusColor(status)
                                        : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: _getStatusColor(status),
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hadir':
        return const Color(0xFF00C853);
      case 'Sakit':
        return const Color(0xFFFFA000);
      case 'Izin':
        return const Color(0xFF039BE5);
      case 'Alpha':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }
}
