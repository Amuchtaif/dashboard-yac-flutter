import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../services/rpp_service.dart';

class CreateRppScreen extends StatefulWidget {
  const CreateRppScreen({super.key});

  @override
  State<CreateRppScreen> createState() => _CreateRppScreenState();
}

class _CreateRppScreenState extends State<CreateRppScreen> {
  final _formKey = GlobalKey<FormState>();
  final RppService _rppService = RppService();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _meetingController = TextEditingController();
  final TextEditingController _timeAllocationController =
      TextEditingController();
  final TextEditingController _standardCompetencyController =
      TextEditingController();
  final TextEditingController _basicCompetencyController =
      TextEditingController();
  final TextEditingController _indicatorController = TextEditingController();
  final TextEditingController _objectivesController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _resourcesController = TextEditingController();
  final TextEditingController _assessmentController = TextEditingController();

  String _teacherName = "";
  String? _selectedYear;
  String? _selectedLevel;
  String? _selectedSubject;
  String? _selectedClass;
  String? _selectedSemester;

  List<Map<String, dynamic>> _allTeachingInfo = [];
  List<String> _academicYears = [];
  List<String> _semesters = ['Ganjil', 'Genap'];

  List<String> _levels = [];
  List<String> _filteredSubjects = [];
  List<String> _filteredClasses = [];

  Map<String, dynamic>? _activePeriod;
  bool _isLoadingInfo = true;
  bool _isSubmitting = false;
  bool _showErrors = false;

  List<Map<String, dynamic>> _masterClasses = [];
  List<Map<String, dynamic>> _masterSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherName = prefs.getString('fullName') ?? "Guru";
    });

    // Parallel fetch
    await Future.wait([
      _fetchTeachingInfo(),
      _fetchActivePeriod(),
      _fetchMasterData(),
    ]);

    setState(() => _isLoadingInfo = false);
  }

  Future<void> _fetchMasterData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConstants.baseUrl}get_classes.php')),
        http.get(Uri.parse('${ApiConstants.baseUrl}get_subjects.php')),
      ]);

      if (responses[0].statusCode == 200) {
        final result = jsonDecode(responses[0].body);
        if (result['success'] == true) {
          _masterClasses = List<Map<String, dynamic>>.from(result['data']);
        }
      }

      if (responses[1].statusCode == 200) {
        final result = jsonDecode(responses[1].body);
        if (result['success'] == true) {
          _masterSubjects = List<Map<String, dynamic>>.from(result['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching master data: $e');
    }
  }

  Future<void> _fetchActivePeriod() async {
    final period = await _rppService.getActivePeriod();
    if (period.isNotEmpty) {
      setState(() {
        _activePeriod = period;
        // Add to list if not present
        final yearStr = period['academic_year_name'] ?? '2024/2025';
        if (!_academicYears.contains(yearStr)) {
          _academicYears.add(yearStr);
        }
        _selectedYear = yearStr;
        _selectedSemester = period['semester'];
      });
    } else {
      setState(() {
        _academicYears = ['2024/2025', '2025/2026'];
      });
    }
  }

  Future<void> _fetchTeachingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.get('user_id') ?? prefs.get('userId');

      final url =
          '${ApiConstants.baseUrl}teacher/get_my_teaching_info.php?employee_id=$employeeId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final List<dynamic> rawData = result['data'];
          _allTeachingInfo = List<Map<String, dynamic>>.from(rawData);
          _levels =
              _allTeachingInfo
                  .map((e) => e['level_name'].toString())
                  .toSet()
                  .toList();
          _levels.sort();
        }
      }
    } catch (e) {
      debugPrint('Error fetching teaching info: $e');
    }
  }

  void _updateFilteredData() {
    setState(() {
      if (_selectedLevel == null) {
        _filteredSubjects = [];
        _filteredClasses = [];
      } else {
        _filteredSubjects =
            _allTeachingInfo
                .where((e) => e['level_name'] == _selectedLevel)
                .map((e) => e['subject_name'].toString())
                .toSet()
                .toList();
        _filteredSubjects.sort();

        _filteredClasses =
            _allTeachingInfo
                .where((e) => e['level_name'] == _selectedLevel)
                .map((e) => e['class_name'].toString())
                .toSet()
                .toList();
        _filteredClasses.sort();
      }

      if (_selectedSubject != null &&
          !_filteredSubjects.contains(_selectedSubject)) {
        _selectedSubject = null;
      }
      if (_selectedClass != null &&
          !_filteredClasses.contains(_selectedClass)) {
        _selectedClass = null;
      }
    });
  }

  Future<void> _submitRpp(bool isDraft) async {
    setState(() {
      _showErrors = !isDraft;
    });

    if (!isDraft) {
      if (!_formKey.currentState!.validate()) return;
    } else {
      // For draft, identity fields (Title, Level, Subject, Class) are still required by backend
      if (_titleController.text.isEmpty ||
          _selectedLevel == null ||
          _selectedSubject == null ||
          _selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Judul, Jenjang, Mapel, & Kelas wajib diisi/dipilih'),
          ),
        );
        return;
      }
      // Clear visible error messages for other fields
      _formKey.currentState?.save();
    }

    // Find IDs
    final selectedTeaching = _allTeachingInfo.firstWhere(
      (e) =>
          e['level_name'] == _selectedLevel &&
          e['subject_name'] == _selectedSubject &&
          e['class_name'] == _selectedClass,
      orElse: () => {},
    );

    if (selectedTeaching.isEmpty && !isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data mengajar tidak ditemukan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Lookup IDs from master data by matching names
    final classItem = _masterClasses.firstWhere(
      (e) => e['class_name'] == _selectedClass,
      orElse: () => {},
    );
    final subjectItem = _masterSubjects.firstWhere(
      (e) => e['name'] == _selectedSubject,
      orElse: () => {},
    );

    // Map unit_name to a tentative level_id
    int foundLevelId = 0;
    if (classItem.isNotEmpty) {
      final unit = classItem['unit_name']?.toString() ?? '';
      if (unit == 'MTs')
        foundLevelId = 1;
      else if (unit == 'MA')
        foundLevelId = 2;
      else if (unit == 'SDIT')
        foundLevelId = 3;
      else if (unit == 'TKIT')
        foundLevelId = 4;
    }

    final rppData = {
      'academic_year_id': _activePeriod?['academic_year_id'] ?? 1,
      'semester': _selectedSemester ?? '',
      'grade_level_id': foundLevelId != 0 ? foundLevelId : 1,
      'subject_id': subjectItem['id'] ?? 0,
      'class_id': classItem['id'] ?? 0,
      'title': _titleController.text,
      'content_sk': _standardCompetencyController.text,
      'content_kd': _basicCompetencyController.text,
      'content_indicator': _indicatorController.text,
      'content_steps': _stepsController.text,
      'content_summary': _assessmentController.text,
      'is_draft': isDraft ? 1 : 0,
      'meeting_no': _meetingController.text,
      'time_allocation': _timeAllocationController.text,
      'objectives': _objectivesController.text,
      'material': _materialController.text,
      'resources': _resourcesController.text,
    };

    final result = await _rppService.createRpp(rppData);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'RPP Berhasil Disimpan!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan RPP'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buat RPP Baru',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoadingInfo
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoBox(
                            'Lengkapi data konten RPP di bawah ini.',
                          ),
                          const SizedBox(height: 24),

                          _buildInputGroup('Info Guru', [
                            _buildTextField(
                              'Nama Guru',
                              controller: TextEditingController(
                                text: _teacherName,
                              ),
                              enabled: false,
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Judul RPP',
                              controller: _titleController,
                              hint: 'Contoh: Materi Adab Berbakti',
                              icon: Icons.title_rounded,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildInputGroup('Jadwal & Kelas', [
                            _buildDropdown(
                              'Tahun Ajaran',
                              _selectedYear,
                              _academicYears,
                              (v) => setState(() => _selectedYear = v),
                              Icons.calendar_today_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown(
                              'Semester',
                              _selectedSemester,
                              _semesters,
                              (v) => setState(() => _selectedSemester = v),
                              Icons.layers_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown(
                              'Jenjang Pendidikan',
                              _selectedLevel,
                              _levels,
                              (v) {
                                _selectedLevel = v;
                                _updateFilteredData();
                              },
                              Icons.school_outlined,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    'Mata Pelajaran',
                                    _selectedSubject,
                                    _filteredSubjects,
                                    (v) => setState(() => _selectedSubject = v),
                                    Icons.book_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDropdown(
                                    'Kelas',
                                    _selectedClass,
                                    _filteredClasses,
                                    (v) => setState(() => _selectedClass = v),
                                    Icons.people_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildInputGroup('Pertemuan', [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Pertemuan Ke',
                                    controller: _meetingController,
                                    keyboardType: TextInputType.number,
                                    hint: '1',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    'Alokasi Waktu',
                                    controller: _timeAllocationController,
                                    hint: '2 x 45 Menit',
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildInputGroup('Kompetensi', [
                            _buildLargeTextField(
                              'Standar Kompetensi',
                              _standardCompetencyController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Kompetensi Dasar',
                              _basicCompetencyController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Indikator',
                              _indicatorController,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildInputGroup('Rencana Pembelajaran', [
                            _buildLargeTextField(
                              'Tujuan Pembelajaran',
                              _objectivesController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Materi Ajar',
                              _materialController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Langkah Pembelajaran',
                              _stepsController,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildInputGroup('Pendukung & Penilaian', [
                            _buildLargeTextField(
                              'Alat & Sumber Belajar',
                              _resourcesController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Penilaian',
                              _assessmentController,
                            ),
                          ]),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed:
                                  _isSubmitting ? null : () => _submitRpp(true),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: Text(
                                'Simpan Draft',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting
                                      ? null
                                      : () => _submitRpp(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                shadowColor: const Color(
                                  0xFF4F46E5,
                                ).withValues(alpha: 0.3),
                              ),
                              child:
                                  _isSubmitting
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        'Terbitkan RPP',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF4F46E5),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF4338CA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label, {
    TextEditingController? controller,
    bool enabled = true,
    TextInputType? keyboardType,
    String? hint,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                icon != null
                    ? Icon(icon, size: 18, color: const Color(0xFF94A3B8))
                    : null,
            filled: true,
            fillColor:
                enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator:
              (v) =>
                  _showErrors && (v == null || v.isEmpty)
                      ? 'Wajib diisi'
                      : null,
        ),
      ],
    );
  }

  Widget _buildLargeTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator:
              (v) =>
                  _showErrors && (v == null || v.isEmpty)
                      ? 'Wajib diisi'
                      : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, [
    IconData? icon,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B8),
          ),
          decoration: InputDecoration(
            prefixIcon:
                icon != null
                    ? Icon(icon, size: 18, color: const Color(0xFF94A3B8))
                    : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (v) => _showErrors && v == null ? 'Wajib pilih' : null,
        ),
      ],
    );
  }
}
