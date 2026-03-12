import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/grading_service.dart';
import '../services/teacher_service.dart';

class InputGradingScreen extends StatefulWidget {
  const InputGradingScreen({super.key});

  @override
  State<InputGradingScreen> createState() => _InputGradingScreenState();
}

class _InputGradingScreenState extends State<InputGradingScreen> {
  final GradingService _gradingService = GradingService();
  final TeacherService _teacherService = TeacherService();

  // Header State
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
  String? _selectedSubjectId;
  String? _selectedTypeId;

  List<Map<String, dynamic>> _allTeachingInfo = [];
  List<Map<String, dynamic>> _masterClasses = [];
  List<Map<String, dynamic>> _masterSubjects = [];
  List<Map<String, dynamic>> _classList = [];
  List<Map<String, dynamic>> _subjectList = [];
  List<Map<String, dynamic>> _typeList = [];
  List<Map<String, dynamic>> _students = [];

  final Map<String, TextEditingController> _scoreControllers = {};

  bool _isLoading = true;
  bool _isFetchingStudents = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.get('user_id') ?? prefs.get('userId');
      final teacherId = userId?.toString() ?? '0';

      final results = await Future.wait([
        _gradingService.getTeachingInfo(teacherId),
        _teacherService.getClassList(),
        _teacherService.getSubjectList(),
        _gradingService.getAssessmentTypes(),
      ]);

      if (mounted) {
        setState(() {
          _allTeachingInfo = results[0];
          _masterClasses = results[1];
          _masterSubjects = results[2];
          _typeList = results[3];

          // Filter classes that the teacher actually teaches (using Names like RPP)
          final taughtClassNames =
              _allTeachingInfo
                  .map(
                    (e) =>
                        (e['class_name'] ?? e['grade_name'] ?? '').toString(),
                  )
                  .where((name) => name.isNotEmpty)
                  .toSet();

          _classList =
              _masterClasses.where((c) {
                final name = (c['name'] ?? c['class_name'] ?? '').toString();
                return taughtClassNames.contains(name);
              }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data awal: $e')));
      }
    }
  }

  Future<void> _fetchStudents() async {
    if (_selectedClassId == null) return;

    setState(() {
      _isFetchingStudents = true;
      _students = [];
      _scoreControllers.clear();
    });

    try {
      final fetchedStudents = await _gradingService.getStudentsByClass(
        _selectedClassId!,
      );

      if (mounted) {
        setState(() {
          _students = fetchedStudents;
          for (var s in _students) {
            final studentId =
                s['id']?.toString() ?? s['student_id']?.toString() ?? '';
            if (studentId.isNotEmpty) {
              _scoreControllers[studentId] = TextEditingController();
            }
          }
          _isFetchingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingStudents = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data siswa: $e')));
      }
    }
  }

  Future<void> _submitGrading() async {
    if (_selectedClassId == null ||
        _selectedSubjectId == null ||
        _selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua informasi header')),
      );
      return;
    }

    if (_students.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Daftar siswa kosong')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getInt('user_id') ?? prefs.getInt('userId');

      final List<Map<String, dynamic>> scores = [];
      _scoreControllers.forEach((studentId, controller) {
        if (controller.text.isNotEmpty) {
          scores.add({
            'student_id': int.tryParse(studentId) ?? studentId,
            'score': int.tryParse(controller.text) ?? 0,
          });
        }
      });

      final payload = {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'class_id': int.tryParse(_selectedClassId ?? '') ?? 0,
        'subject_id': int.tryParse(_selectedSubjectId ?? '') ?? 0,
        'assessment_type_id': int.tryParse(_selectedTypeId ?? '') ?? 0,
        'teacher_id': teacherId,
        'scores': scores,
      };

      final result = await _gradingService.submitGrading(payload);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penilaian berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to refresh history
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan system: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Input Penilaian Baru',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : ListView(
                children: [
                  _buildHeaderForm(),
                  _isFetchingStudents
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: _buildStudentLoadingState(),
                      )
                      : _students.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: _buildEmptyStudentState(),
                      )
                      : _buildStudentScoringList(),
                ],
              ),
      bottomNavigationBar:
          _students.isNotEmpty && !_isFetchingStudents
              ? _buildBottomAction()
              : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF7C3AED)),
          const SizedBox(height: 16),
          Text(
            'Memuat data awal...',
            style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF7C3AED)),
          const SizedBox(height: 16),
          Text(
            'Mengambil daftar siswa...',
            style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Pilih Kelas',
                  value: _selectedClassId,
                  icon: Icons.class_outlined,
                  items:
                      _classList
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['id'].toString(),
                              child: Text(e['name'] ?? e['class_name'] ?? '-'),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedClassId = val;
                      _selectedSubjectId = null;

                      final selectedClassMap = _masterClasses.firstWhere(
                        (c) => c['id'].toString() == val,
                        orElse: () => {},
                      );
                      final selectedClassName =
                          (selectedClassMap['name'] ??
                                  selectedClassMap['class_name'] ??
                                  '')
                              .toString();

                      final taughtSubjectNames =
                          _allTeachingInfo
                              .where(
                                (e) =>
                                    (e['class_name'] ??
                                        e['grade_name'] ??
                                        '') ==
                                    selectedClassName,
                              )
                              .map((e) => (e['subject_name'] ?? '').toString())
                              .where((name) => name.isNotEmpty)
                              .toSet();

                      _subjectList =
                          _masterSubjects.where((s) {
                            final name =
                                (s['name'] ?? s['subject_name'] ?? '')
                                    .toString();
                            return taughtSubjectNames.contains(name);
                          }).toList();
                    });
                    _fetchStudents();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF7C3AED),
                              onPrimary: Colors.white,
                              onSurface: Color(0xFF1E293B),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: _buildStaticField(
                    label: 'Tanggal',
                    value: DateFormat('dd MMM yyyy').format(_selectedDate),
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropDownField(
            label: 'Mata Pelajaran',
            value: _selectedSubjectId,
            icon: Icons.book_outlined,
            items:
                _subjectList
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['id'].toString(),
                        child: Text(e['name'] ?? e['subject_name'] ?? '-'),
                      ),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _selectedSubjectId = val),
          ),
          const SizedBox(height: 16),
          _buildDropDownField(
            label: 'Jenis Penilaian',
            value: _selectedTypeId,
            icon: Icons.assignment_outlined,
            items:
                _typeList
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['id'].toString(),
                        child: Text(
                          e['name'] ??
                              e['type_name'] ??
                              e['assessment_type'] ??
                              '-',
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _selectedTypeId = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDropDownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF94A3B8),
              ),
              hint: Text(
                'Pilih...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 10),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStudentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.group_add_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Daftar Siswa Belum Muncul',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Harap pilih kelas untuk memuat daftar siswa',
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentScoringList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAFTAR NILAI SISWA',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_students.length} Siswa',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            final id =
                student['id']?.toString() ??
                student['student_id']?.toString() ??
                '';
            final name =
                student['name'] ??
                student['student_name'] ??
                student['nama_siswa'] ??
                'Siswa';
            final nis =
                student['nis'] ??
                student['nisn'] ??
                student['nomor_induk'] ??
                '0';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFF7C3AED),
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
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIS: $nis',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 65,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _scoreControllers[id],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
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

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitGrading,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  'Simpan Data Penilaian',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
      ),
    );
  }
}
