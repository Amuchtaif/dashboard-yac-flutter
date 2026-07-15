import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tahfidz_repository.dart';
import '../../services/tahfidz_service.dart';
import '../../screens/login_screen.dart';

class BaselineTahfidzScreen extends StatefulWidget {
  const BaselineTahfidzScreen({super.key});

  @override
  State<BaselineTahfidzScreen> createState() => _BaselineTahfidzScreenState();
}

class _BaselineTahfidzScreenState extends State<BaselineTahfidzScreen> {
  final TahfidzRepository _repository = TahfidzRepository();
  final TahfidzService _tahfidzService = TahfidzService();

  List<dynamic> _students = [];
  List<dynamic> _baselines = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _academicYearName = '-';
  int? _academicYearId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? teacherId = prefs.getInt('userId');

      final baselineResult = await _repository.getBaselines();
      final studentsList = await _tahfidzService.getMyStudents(teacherId);
      final activeYearResult = await _repository.getActiveAcademicYear();

      if (mounted) {
        if (baselineResult['success'] == true) {
          setState(() {
            _baselines = baselineResult['data'] ?? [];
            _students = studentsList;
            _isLoading = false;

            if (activeYearResult['success'] == true && activeYearResult['data'] != null) {
              _academicYearName = activeYearResult['data']['name'] ?? '-';
              _academicYearId = int.tryParse(activeYearResult['data']['id']?.toString() ?? '');
            } else if (_baselines.isNotEmpty) {
              _academicYearName = _baselines.first['academic_year_name'] ?? '-';
              _academicYearId = int.tryParse(_baselines.first['academic_year_id']?.toString() ?? '');
            }
          });
        } else {
          if (baselineResult['message'] != null && baselineResult['message'].toString().contains('Unauthorized')) {
            _handleLogout();
          } else {
            setState(() {
              _errorMessage = baselineResult['message'] ?? 'Gagal memuat data baseline';
              _isLoading = false;
            });
          }
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

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  int _getFilledCount() {
    int count = 0;
    for (var student in _students) {
      final studentId = int.tryParse(student['id']?.toString() ?? '');
      final hasBaseline = _baselines.any((b) => int.tryParse(b['student_id']?.toString() ?? '') == studentId);
      if (hasBaseline) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final filledCount = _getFilledCount();
    final totalCount = _students.length;
    final double progressRatio = totalCount == 0 ? 0.0 : filledCount / totalCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Baseline Hafalan',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
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
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'Coba Lagi',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Progress Info Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tahun Ajaran Aktif',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _academicYearName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDFA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF0D9488),
                                  size: 20,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress Pengisian',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$filledCount dari $totalCount Santri',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    height: 6,
                                    width: constraints.maxWidth * progressRatio,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        ],
                      ),
                    ),

                    // Student List Section Title
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
                      child: Text(
                        'Daftar Santri',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),

                    // Student List
                    Expanded(
                      child: _students.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_alt_outlined, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada santri terdaftar',
                                    style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final studentId = int.tryParse(student['id']?.toString() ?? '');
                                final studentName = (student['nama_siswa'] ?? student['full_name'] ?? student['name'] ?? 'Santri').toString();
                                final className = (student['kelas'] ?? student['nama_kelas'] ?? '-').toString();

                                // Find matching baseline record
                                final baseline = _baselines.firstWhere(
                                  (b) => int.tryParse(b['student_id']?.toString() ?? '') == studentId,
                                  orElse: () => null,
                                );

                                final double? baselineJuz = baseline != null
                                    ? double.tryParse(baseline['baseline_juz']?.toString() ?? '')
                                    : null;

                                final bool isFilled = baselineJuz != null;
                                final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.015),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isFilled
                                          ? const Color(0xFFE6F4EA)
                                          : const Color(0xFFF1F5F9),
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w900,
                                          color: isFilled
                                              ? const Color(0xFF137333)
                                              : const Color(0xFF64748B),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      studentName,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "Kelas $className",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isFilled
                                                ? const Color(0xFFE6F4EA)
                                                : const Color(0xFFFFF7ED),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isFilled
                                                  ? const Color(0xFFCEEAD6)
                                                  : const Color(0xFFFFE4E6),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            isFilled ? '$baselineJuz Juz' : 'Belum Diisi',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isFilled
                                                  ? const Color(0xFF137333)
                                                  : const Color(0xFFEA580C),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFFCBD5E1),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InputBaselineScreen(
                                            studentId: studentId!,
                                            studentName: studentName,
                                            academicYearId: _academicYearId ?? 1,
                                            baselineRecord: baseline,
                                          ),
                                        ),
                                      ).then((_) => _fetchData());
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class InputBaselineScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final int academicYearId;
  final Map<String, dynamic>? baselineRecord;

  const InputBaselineScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.academicYearId,
    this.baselineRecord,
  });

  @override
  State<InputBaselineScreen> createState() => _InputBaselineScreenState();
}

class _InputBaselineScreenState extends State<InputBaselineScreen> {
  final TahfidzRepository _repository = TahfidzRepository();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _juzController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  DateTime _assessmentDate = DateTime.now();

  bool _isSubmitting = false;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    if (widget.baselineRecord != null) {
      _juzController.text = widget.baselineRecord!['baseline_juz']?.toString() ?? '';
      _catatanController.text = widget.baselineRecord!['notes'] ?? '';
      if (widget.baselineRecord!['assessment_date'] != null) {
        _assessmentDate = DateFormat('yyyy-MM-dd').parse(widget.baselineRecord!['assessment_date']);
      }
      _isLocked = widget.baselineRecord!['verification_status'] == 'Locked' ||
          widget.baselineRecord!['status'] == 'Locked';
    }
  }

  @override
  void dispose() {
    _juzController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isLocked) return;
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate.isAfter(now) ? now : _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && picked != _assessmentDate) {
      setState(() {
        _assessmentDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      'academic_year_id': widget.academicYearId,
      'student_id': widget.studentId,
      'baseline_juz': double.parse(_juzController.text),
      'assessment_date': DateFormat('yyyy-MM-dd').format(_assessmentDate),
      'notes': _catatanController.text,
    };

    final messenger = ScaffoldMessenger.of(context);
    Map<String, dynamic> result;

    if (widget.baselineRecord != null) {
      result = await _repository.updateBaseline(widget.baselineRecord!['id'], payload);
    } else {
      result = await _repository.createBaseline(payload);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Baseline berhasil disimpan.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        if (result['message'] != null && result['message'].toString().contains('Unauthorized')) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan baseline.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Input Baseline',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Locked Info Warning
              if (_isLocked) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: Color(0xFFEA580C), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Baseline terkunci / Read Only. Periode pengisian telah berakhir.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEA580C),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],

              // Student Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(
                        initial,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF475569),
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.studentName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pencatatan Baseline Hafalan',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Total Hafalan Awal Juz Input
              Text(
                'Total Hafalan Awal (Juz)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _juzController,
                enabled: !_isLocked,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Contoh: 15.0',
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                  if (double.tryParse(value) == null) return 'Harus berupa angka/desimal';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Tanggal Asesmen Selector
              Text(
                'Tanggal Asesmen',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMMM yyyy', 'id_ID').format(_assessmentDate),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.calendar_month_rounded,
                        color: _isLocked ? const Color(0xFF94A3B8) : const Color(0xFF0D9488),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Catatan Input
              Text(
                'Catatan Tambahan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                enabled: !_isLocked,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tulis catatan jika ada...',
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              if (!_isLocked) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Simpan Baseline',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
