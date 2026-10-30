import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/teacher_service.dart';

import 'class_journal_screen.dart';

class TeachingJournalScreen extends StatefulWidget {
  final String scheduleId;
  final String date;
  final String subjectName;
  final String className;

  final String teacherName;
  final bool isEditMode;

  const TeachingJournalScreen({
    super.key,
    required this.scheduleId,
    required this.date,
    required this.subjectName,
    required this.className,
    required this.teacherName,
    this.isEditMode = false,
  });

  @override
  State<TeachingJournalScreen> createState() => _TeachingJournalScreenState();
}

class _TeachingJournalScreenState extends State<TeachingJournalScreen> {
  final TeacherService _teacherService = TeacherService();
  
  bool get _isPast {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final date = DateTime.parse(widget.date);
      final compareDate = DateTime(date.year, date.month, date.day);
      return compareDate.isBefore(today);
    } catch (e) {
      return false;
    }
  }

  final _formKey = GlobalKey<FormState>();

  // Controllers

  // State
  bool isLoading = true;
  bool isSubmitting = false;
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {}; // student_id -> status
  Map<String, dynamic>? journalData;
  bool isJournalFilled = false;
  String? teacherId;
  String _selectedFilter = 'Total';

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
    _loadTeacherId();
    _fetchData();
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final userId = prefs.get('userId');
        if (userId is int) {
          teacherId = userId.toString();
        } else if (userId is String) {
          teacherId = userId;
        }
      });
    }
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

          if (data['students'] != null && data['students'] is List) {
            students = List<Map<String, dynamic>>.from(data['students']);
            // Initialize attendance status
            for (var student in students) {
              final dbStatus = student['status']?.toString() ?? '';
              attendanceStatus[student['student_id'].toString()] =
                  _dbToUi[dbStatus] ?? 'Hadir';
            }
          }

          if (data['journal'] != null &&
              data['journal'] is Map<String, dynamic>) {
            journalData = data['journal'];
            // Considered filled if both topic and notes are not empty
            final topic = journalData!['topic']?.toString() ?? '';
            final notes = journalData!['notes']?.toString() ?? '';
            if (topic.isNotEmpty && notes.isNotEmpty) {
              isJournalFilled = true;
            }
          }

          isLoading = false;
        });

        // Auto redirect if already filled
        if (isJournalFilled && !widget.isEditMode) {
          _navigateToJournal(replace: true);
        }
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

  Future<bool> _saveAttendanceExplicit() async {
    try {
      if (teacherId == null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.get('user_id') ?? prefs.get('userId');
        if (userId != null) {
          teacherId = userId.toString();
        }
      }

      final List<Map<String, String>> attendances = [];
      attendanceStatus.forEach((studentId, status) {
        final dbStatus = _uiToDb[status] ?? 'present';
        attendances.add({'student_id': studentId, 'status': dbStatus});
      });

      final Map<String, dynamic> payload = {
        'schedule_id': widget.scheduleId,
        'teacher_id': teacherId ?? '0',
        'date': widget.date,
        'topic': journalData?['topic'] ?? '',
        'notes': journalData?['notes'] ?? '',
        'attendances': attendances,
      };

      final result = await _teacherService.submitAttendance(payload);
      return result['success'] == true;
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      return false;
    }
  }

  Future<void> _saveAttendanceDraft() async {
    if (teacherId == null) return;

    final List<Map<String, String>> attendances = [];
    attendanceStatus.forEach((studentId, status) {
      final dbStatus = _uiToDb[status] ?? 'present';
      attendances.add({'student_id': studentId, 'status': dbStatus});
    });

    final Map<String, dynamic> payload = {
      'schedule_id': widget.scheduleId,
      'teacher_id': teacherId,
      'date': widget.date,
      'topic': journalData?['topic'] ?? '',
      'notes': journalData?['notes'] ?? '',
      'attendances': attendances,
    };

    // We don't wait for the result or show loading for "auto-save" to keep it smooth
    _teacherService.submitAttendance(payload).then((result) {
      if (result['success'] != true) {
        debugPrint('Failed to auto-save attendance: ${result['message']}');
      }
    });
  }

  void _navigateToJournal({bool replace = false}) async {
    final route = MaterialPageRoute(
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
    );

    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      final navigator = Navigator.of(context);
      final res = await navigator.push(route);
      if (res == true && mounted) {
        navigator.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Edit Absensi Siswa' : 'Absensi Siswa',
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
            onPressed: () => Navigator.pop(context, widget.isEditMode ? true : null),
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
                    onPressed: widget.isEditMode
                        ? (isSubmitting
                            ? null
                            : () async {
                                setState(() => isSubmitting = true);
                                final success = await _saveAttendanceExplicit();
                                if (!context.mounted) return;
                                setState(() => isSubmitting = false);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Perubahan absensi berhasil disimpan',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor:
                                          const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal menyimpan perubahan absensi',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              })
                        : _navigateToJournal,
                    icon: isSubmitting
                        ? const SizedBox.shrink()
                        : Icon(
                            widget.isEditMode
                                ? Icons.check_circle_outline
                                : ((isJournalFilled || _isPast)
                                    ? Icons.description_outlined
                                    : Icons.arrow_forward),
                            color: Colors.white,
                          ),
                    label: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.isEditMode
                                ? 'Simpan Perubahan Absensi'
                                : ((isJournalFilled || _isPast)
                                    ? 'Lihat Detail Jurnal'
                                    : 'Lanjut Isi Jurnal'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isEditMode
                          ? const Color(0xFF10B981)
                          : const Color(0xFF42A5F5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: (widget.isEditMode
                              ? const Color(0xFF10B981)
                              : const Color(0xFF42A5F5))
                          .withValues(alpha: 0.3),
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
    final bool isSelected = _selectedFilter == label;
    final bool isAnyFilterActive = _selectedFilter != 'Total';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = (_selectedFilter == label) ? 'Total' : label;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isAnyFilterActive && !isSelected
                ? color.withValues(alpha: 0.45)
                : color,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2.5)
                : Border.all(color: Colors.transparent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                  alpha: isSelected ? 0.45 : (isAnyFilterActive ? 0.1 : 0.3),
                ),
                blurRadius: isSelected ? 12 : 8,
                offset: Offset(0, isSelected ? 6 : 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.85),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final List<Map<String, dynamic>> filteredStudents;
    if (_selectedFilter == 'Total') {
      filteredStudents = students;
    } else {
      filteredStudents = students.where((student) {
        final studentId = student['student_id'].toString();
        return attendanceStatus[studentId] == _selectedFilter;
      }).toList();
    }

    if (filteredStudents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada siswa dengan status "$_selectedFilter"',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _selectedFilter = 'Total');
              },
              child: Text(
                'Tampilkan Semua Siswa',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF42A5F5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFilter != 'Total')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Filter: $_selectedFilter (${filteredStudents.length} Siswa)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedFilter = 'Total'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Reset Filter',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredStudents.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final student = filteredStudents[index];
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
                              'NIS: ${student['nomor_induk'] ?? student['nis'] ?? studentId} • ${widget.className}',
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
                                    (!widget.isEditMode && (isJournalFilled || _isPast))
                                        ? null
                                        : () {
                                          setState(() {
                                            attendanceStatus[studentId] = status;
                                          });
                                          _saveAttendanceDraft();
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
        ),
      ],
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
