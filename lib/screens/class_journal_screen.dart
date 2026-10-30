import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/teacher_service.dart';
import 'teaching_journal_screen.dart';

class ClassJournalScreen extends StatefulWidget {
  final String scheduleId;
  final String date;
  final String subjectName;
  final String className;
  final String teacherName;
  final Map<String, String> attendanceStatus; // student_id -> status
  final Map<String, String> uiToDbMapping; // UI -> DB mapping
  final int totalStudents;
  final Map<String, dynamic>? existingJournal;

  const ClassJournalScreen({
    super.key,
    required this.scheduleId,
    required this.date,
    required this.subjectName,
    required this.className,
    required this.teacherName,
    required this.attendanceStatus,
    required this.uiToDbMapping,
    required this.totalStudents,
    this.existingJournal,
  });

  @override
  State<ClassJournalScreen> createState() => _ClassJournalScreenState();
}

class _ClassJournalScreenState extends State<ClassJournalScreen> {
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

  String _formatIndonesianDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  bool isSubmitting = false;
  String _teacherName = '';
  bool isReadOnly = false;
  bool _isLoadingData = false;
  Map<String, String> _attendanceStatus = {};
  int _totalStudents = 0;
  String _savedTopic = '';
  String _savedNotes = '';

  @override
  void initState() {
    super.initState();
    _attendanceStatus = Map<String, String>.from(widget.attendanceStatus);
    _totalStudents = widget.totalStudents;
    _loadTeacherName();
    if (_isPast) {
      isReadOnly = true;
    }
    if (widget.existingJournal != null) {
      final topic = widget.existingJournal!['topic'] ?? '';
      final notes = widget.existingJournal!['notes'] ?? '';
      if (topic.isNotEmpty && notes.isNotEmpty) {
        isReadOnly = true;
      }
      _topicController.text = topic;
      _summaryController.text = notes;
      _savedTopic = topic;
      _savedNotes = notes;
    }
  }

  @override
  void didUpdateWidget(covariant ClassJournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_attendanceStatus.isEmpty && widget.attendanceStatus.isNotEmpty) {
      _attendanceStatus = Map<String, String>.from(widget.attendanceStatus);
      _totalStudents = widget.totalStudents;
    }
  }

  Future<void> _fetchLatestData() async {
    setState(() => _isLoadingData = true);
    try {
      final data = await _teacherService.getStudentsBySchedule(
        widget.scheduleId,
        widget.date,
      );

      final Map<String, String> dbToUi = {
        'present': 'Hadir',
        'sick': 'Sakit',
        'permit': 'Izin',
        'absent': 'Alpha',
        'late': 'Alpha',
      };

      if (mounted) {
        setState(() {
          if (data['students'] != null && data['students'] is List) {
            final studentsList =
                List<Map<String, dynamic>>.from(data['students']);
            _totalStudents = studentsList.length;
            final Map<String, String> updatedStatus = {};
            for (var student in studentsList) {
              final dbStatus = student['status']?.toString() ?? '';
              updatedStatus[student['student_id'].toString()] =
                  dbToUi[dbStatus] ?? 'Hadir';
            }
            _attendanceStatus = updatedStatus;
          }

          if (data['journal'] != null &&
              data['journal'] is Map<String, dynamic>) {
            final journal = data['journal'];
            final topic = journal['topic']?.toString() ?? '';
            final notes = journal['notes']?.toString() ?? '';
            if (isReadOnly) {
              _topicController.text = topic;
              _summaryController.text = notes;
              _savedTopic = topic;
              _savedNotes = notes;
            }
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _navigateToEditAttendance() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeachingJournalScreen(
              scheduleId: widget.scheduleId,
              date: widget.date,
              subjectName: widget.subjectName,
              className: widget.className,
              teacherName: widget.teacherName,
              isEditMode: true,
            ),
      ),
    );

    // Refresh data after returning from edit attendance
    _fetchLatestData();
  }

  void _enableEditJournal() {
    setState(() {
      isReadOnly = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Mode edit jurnal aktif. Silakan ubah data.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _teacherName =
            prefs.getString('fullName') ??
            prefs.getString('name') ??
            widget.teacherName;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String teacherId = '0';
      if (prefs.containsKey('user_id')) {
        final userId = prefs.get('user_id');
        if (userId is int) {
          teacherId = userId.toString();
        } else if (userId is String) {
          teacherId = userId;
        }
      }

      final statusMap =
          _attendanceStatus.isNotEmpty
              ? _attendanceStatus
              : widget.attendanceStatus;
      final List<Map<String, String>> attendances = [];
      statusMap.forEach((studentId, status) {
        final dbStatus = widget.uiToDbMapping[status] ?? 'present';
        attendances.add({'student_id': studentId, 'status': dbStatus});
      });

      final Map<String, dynamic> payload = {
        'schedule_id': widget.scheduleId,
        'teacher_id': teacherId,
        'date': widget.date,
        'topic': _topicController.text,
        'notes': _summaryController.text,
        'attendances': attendances,
      };

      final result = await _teacherService.submitAttendance(payload);

      if (mounted) {
        setState(() => isSubmitting = false);
        if (result['success'] == true) {
          _savedTopic = _topicController.text;
          _savedNotes = _summaryController.text;
          if (widget.existingJournal != null) {
            setState(() {
              isReadOnly = true;
              widget.existingJournal!['topic'] = _topicController.text;
              widget.existingJournal!['notes'] = _summaryController.text;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Jurnal berhasil diperbarui',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else {
            _showSuccessDialog();
          }
        } else {
          final message = result['message'] ?? 'Gagal menyimpan data.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $message')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.blue, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Jurnal Berhasil Disimpan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    'Kembali ke Jadwal',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Jurnal Kelas',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
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
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1E293B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 50),
              tooltip: 'Menu Opsi',
              onSelected: (value) {
                if (value == 'edit_attendance') {
                  _navigateToEditAttendance();
                } else if (value == 'edit_journal') {
                  _enableEditJournal();
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem<String>(
                      value: 'edit_attendance',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.how_to_reg_outlined,
                              size: 20,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit Absensi',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Ubah kehadiran siswa',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'edit_journal',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_note_outlined,
                              size: 20,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit Data Jurnal',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Ubah materi & ringkasan',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoadingData)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 24),
                    _buildFormSection(),
                    const SizedBox(height: 32),
                    if (!isReadOnly) ...[
                      if (widget.existingJournal != null)
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed:
                                    isSubmitting
                                        ? null
                                        : () {
                                          setState(() {
                                            _topicController.text = _savedTopic;
                                            _summaryController.text =
                                                _savedNotes;
                                            isReadOnly = true;
                                          });
                                        },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(
                                    0xFF1E88E5,
                                  ).withValues(alpha: 0.4),
                                ),
                                icon:
                                    isSubmitting
                                        ? const SizedBox.shrink()
                                        : const Icon(
                                          Icons.save_outlined,
                                          color: Colors.white,
                                        ),
                                label:
                                    isSubmitting
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          'Simpan Perubahan',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF1E88E5,
                              ), // Blue like mockup
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF1E88E5,
                              ).withValues(alpha: 0.4),
                            ),
                            icon:
                                isSubmitting
                                    ? const SizedBox.shrink()
                                    : const Icon(
                                      Icons.save_outlined,
                                      color: Colors.white,
                                    ),
                            label:
                                isSubmitting
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'Simpan Jurnal',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final statusMap =
        _attendanceStatus.isNotEmpty
            ? _attendanceStatus
            : widget.attendanceStatus;
    final int hadir = statusMap.values.where((s) => s == 'Hadir').length;
    final int izin = statusMap.values.where((s) => s == 'Izin').length;
    final int sakit = statusMap.values.where((s) => s == 'Sakit').length;
    // Assuming 'Total' is total students, not just present.
    final int total =
        _totalStudents > 0 ? _totalStudents : widget.totalStudents;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MATA PELAJARAN',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2196F3),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subjectName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _teacherName.isNotEmpty ? _teacherName : widget.teacherName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.className,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: Colors.grey[300]),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formatIndonesianDate(widget.date),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'TOTAL',
                  total.toString(),
                  Colors.white,
                  const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'HADIR',
                  hadir.toString(),
                  const Color(0xFFE8F5E9),
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'IZIN',
                  izin.toString(),
                  const Color(0xFFE3F2FD),
                  const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'SAKIT',
                  sakit.toString(),
                  const Color(0xFFFFEBEE),
                  const Color(0xFFC62828),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String count,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border:
            bgColor == Colors.white
                ? Border.all(color: Colors.grey.shade200)
                : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BAB / Materi',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _topicController,
          decoration: InputDecoration(
            hintText: 'Tuliskan Bab/Materi',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFFBDBDBD),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  isReadOnly
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  isReadOnly
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          readOnly: isReadOnly,
          validator:
              (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 24),
        Text(
          'Ringkasan Kegiatan',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _summaryController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Tuliskan ringkasan kegiatan pembelajaran hari ini...',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFFBDBDBD),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  isReadOnly
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  isReadOnly
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          readOnly: isReadOnly,
          validator:
              (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }
}
