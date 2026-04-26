import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import '../services/rpp_service.dart';

class CreateRppScreen extends StatefulWidget {
  final Map<String, dynamic>? initialRppData;

  const CreateRppScreen({super.key, this.initialRppData});

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
  final TextEditingController _profilPancasilaController =
      TextEditingController(); // teaching_profil_pancasila
  final TextEditingController _mediaController =
      TextEditingController(); // content_summary (Media & Sumber Belajar)
  final TextEditingController _assessmentController = TextEditingController();
  final TextEditingController _smartPasteController = TextEditingController();

  String _teacherName = "";
  String? _selectedYear;
  String? _selectedLevel;
  String? _selectedSubject;
  String? _selectedClass;
  String? _selectedSemester;

  List<Map<String, dynamic>> _allTeachingInfo = [];
  List<String> _academicYears = [];
  final List<String> _semesters = ['Ganjil', 'Genap'];

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

    setState(() {
      _isLoadingInfo = false;
      if (widget.initialRppData != null) {
        final data = widget.initialRppData!;
        _titleController.text = data['title'] ?? '';
        _meetingController.text =
            data['session_no'] ?? data['meeting_no'] ?? '';
        _timeAllocationController.text =
            data['allocation'] ?? data['time_allocation'] ?? '';
        _standardCompetencyController.text =
            data['content_cp'] ?? data['content_sk'] ?? '';
        _basicCompetencyController.text =
            data['content_atp'] ?? data['content_kd'] ?? '';
        _indicatorController.text =
            data['content_pertanyaan_pemantik'] ??
            data['content_indicator'] ??
            '';
        _objectivesController.text = data['learning_goal'] ?? '';
        _materialController.text = data['teaching_material'] ?? '';
        _profilPancasilaController.text =
            data['teaching_profil_pancasila'] ?? data['teaching_method'] ?? '';
        _mediaController.text = data['content_summary'] ?? '';
        _stepsController.text = data['content_steps'] ?? '';
        _assessmentController.text = data['assessment'] ?? '';

        // 1. Handle Level (Jenjang)
        final lName = data['level_name'] ?? data['unit_name'] ?? '';
        if (lName.isNotEmpty) {
          if (!_levels.contains(lName)) {
            _levels.add(lName);
            _levels.sort();
          }
          _selectedLevel = lName;
        }

        // 2. Update filtered lists based on level
        _updateFilteredData();

        // 3. Handle Subject (Mapel)
        final sName = data['subject_name'] ?? '';
        if (sName.isNotEmpty) {
          if (!_filteredSubjects.contains(sName)) {
            _filteredSubjects.add(sName);
            _filteredSubjects.sort();
          }
          _selectedSubject = sName;
        }

        // 4. Handle Class (Kelas)
        final cName = data['grade_name'] ?? data['class_name'] ?? '';
        if (cName.isNotEmpty) {
          if (!_filteredClasses.contains(cName)) {
            _filteredClasses.add(cName);
            _filteredClasses.sort();
          }
          _selectedClass = cName;
        }

        // 5. Handle Year and Semester
        final yearName =
            data['academic_year'] ?? data['academic_year_name'] ?? '';
        if (yearName.isNotEmpty) {
          if (!_academicYears.contains(yearName)) {
            _academicYears.add(yearName);
            _academicYears.sort();
          }
          _selectedYear = yearName;
        }

        if (data['semester'] != null &&
            data['semester'].toString().isNotEmpty) {
          final sem = data['semester'].toString();
          if (_semesters.contains(sem)) {
            _selectedSemester = sem;
          }
        }
      }
    });
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

    // Find IDs from Master Data (Required for creation/publishing)
    final classItem = _masterClasses.firstWhere(
      (e) => e['class_name'] == _selectedClass,
      orElse: () => {},
    );
    final subjectItem = _masterSubjects.firstWhere(
      (e) => e['name'] == _selectedSubject,
      orElse: () => {},
    );

    if (!isDraft) {
      if (classItem.isEmpty || subjectItem.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal menemukan referensi Kelas/Mapel di sistem. Pastikan data master tersedia.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    // Map unit_name to a tentative level_id
    int foundLevelId = 0;
    if (classItem.isNotEmpty) {
      final unit = classItem['unit_name']?.toString() ?? '';
      if (unit == 'MTs') {
        foundLevelId = 1;
      } else if (unit == 'MA') {
        foundLevelId = 2;
      } else if (unit == 'SDIT') {
        foundLevelId = 3;
      } else if (unit == 'TKIT') {
        foundLevelId = 4;
      }
    }

    final rppData = {
      'academic_year_id': _activePeriod?['academic_year_id'] ?? 1,
      'semester': _selectedSemester ?? '',
      'education_unit_id': foundLevelId != 0 ? foundLevelId : 1, // unit jenjang
      'grade_level_id':
          classItem['id'] ?? 0, // actual class ID from grade_levels table
      'subject_id': subjectItem['id'] ?? 0,
      'session_no': _meetingController.text,
      'allocation': _timeAllocationController.text,
      'title': _titleController.text,
      'content_cp': _standardCompetencyController.text,
      'content_atp': _basicCompetencyController.text,
      'content_pertanyaan_pemantik': _indicatorController.text,
      'learning_goal': _objectivesController.text,
      'teaching_material': _materialController.text,
      'teaching_profil_pancasila': _profilPancasilaController.text,
      'content_steps': _stepsController.text,
      'content_summary': _mediaController.text,
      'assessment': _assessmentController.text,
      'is_draft': isDraft ? 1 : 0,
    };

    if (widget.initialRppData != null) {
      rppData['id'] = widget.initialRppData!['id'];
    }

    final result =
        widget.initialRppData != null
            ? await _rppService.updateRpp(rppData)
            : await _rppService.createRpp(rppData);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true || result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'RPP Berhasil Disimpan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, isDraft ? 'draft' : 'published');
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
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
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
          widget.initialRppData != null ? 'Edit RPP' : 'Buat RPP Baru',
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
                          const SizedBox(height: 16),
                          _buildSmartPasteButton(),
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
                              icon: Icons.topic_outlined,
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
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    'Alokasi Waktu',
                                    controller: _timeAllocationController,
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildInputGroup('Kompetensi', [
                            _buildLargeTextField(
                              'Capaian Pembelajaran (CP)',
                              _standardCompetencyController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Alur Tujuan Pembelajaran (ATP)',
                              _basicCompetencyController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Pertanyaan Pemantik',
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
                              'Kegiatan Pembelajaran',
                              _stepsController,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildInputGroup('Pendukung & Penilaian', [
                            _buildLargeTextField(
                              'Profil Pelajar Pancasila',
                              _profilPancasilaController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Media & Sumber Belajar',
                              _mediaController,
                            ),
                            const SizedBox(height: 20),
                            _buildLargeTextField(
                              'Asesmen',
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

  Widget _buildSmartPasteButton() {
    return InkWell(
      onTap: _showSmartPasteDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.content_paste_go_rounded,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Paste dari Word',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Tempel teks RPP untuk isi form otomatis',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showSmartPasteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Smart Paste',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tempelkan teks RPP dari Word/PDF Anda di bawah ini. Pastikan format mengandung poin A s/d I.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TextField(
                    controller: _smartPasteController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText:
                          'Contoh:\nA. Capaian Pembelajaran...\nB. Alur Tujuan...\n...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _processSmartPaste(_smartPasteController.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Proses & Isi Form',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom,
                ),
              ],
            ),
          ),
    );
  }

  void _processSmartPaste(String text) {
    if (text.isEmpty) return;

    final Map<String, TextEditingController> markersMapping = {
      'A': _standardCompetencyController,
      'B': _basicCompetencyController,
      'C': _indicatorController,
      'D': _objectivesController,
      'E': _materialController,
      'F': _profilPancasilaController,
      'G': _stepsController,
      'H': _mediaController,
      'I': _assessmentController,
    };

    final keys = markersMapping.keys.toList();
    bool foundAny = false;

    for (int i = 0; i < keys.length; i++) {
      final currentKey = keys[i];
      String stopKey = (i + 1 < keys.length) ? keys[i + 1] : '';

      String pattern =
          stopKey.isNotEmpty
              ? '$currentKey\\.\\s+([\\s\\S]*?)(?=\\s+$stopKey\\.\\s+)'
              : '$currentKey\\.\\s+([\\s\\S]*)';

      final regExp = RegExp(pattern, caseSensitive: true);
      final match = regExp.firstMatch(text);

      if (match != null) {
        markersMapping[currentKey]!.text = match.group(1)?.trim() ?? '';
        foundAny = true;
      }
    }

    if (foundAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil memproses teks RPP!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengenali format. Pastikan ada poin A. s/d I.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
