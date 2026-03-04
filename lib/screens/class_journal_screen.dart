import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/teacher_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  bool isSubmitting = false;
  String _teacherName = '';
  bool isReadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
    if (widget.existingJournal != null) {
      final topic = widget.existingJournal!['topic'] ?? '';
      final notes = widget.existingJournal!['notes'] ?? '';
      if (topic.isNotEmpty && notes.isNotEmpty) {
        isReadOnly = true;
      }
      _topicController.text = topic;
      _summaryController.text = notes;
    }
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

      final List<Map<String, String>> attendances = [];
      widget.attendanceStatus.forEach((studentId, status) {
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
          _showSuccessDialog();
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
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
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
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1E293B)),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              if (!isReadOnly)
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
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final int hadir =
        widget.attendanceStatus.values.where((s) => s == 'Hadir').length;
    final int izin =
        widget.attendanceStatus.values.where((s) => s == 'Izin').length;
    final int sakit =
        widget.attendanceStatus.values.where((s) => s == 'Sakit').length;
    // Assuming 'Total' is total students, not just present.
    final int total = widget.totalStudents;

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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.className,
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
                          DateFormat(
                            'EEE, d MMM yyyy',
                          ).format(DateTime.parse(widget.date)),
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
              borderSide: BorderSide.none,
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
              borderSide: BorderSide.none,
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
