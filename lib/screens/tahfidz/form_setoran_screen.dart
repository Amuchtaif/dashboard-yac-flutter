import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tahfidz_repository.dart';
import '../../services/tahfidz_service.dart';
import '../../services/quran_service.dart';
import '../../models/surah_model.dart';
import '../../screens/login_screen.dart';

class FormSetoranScreen extends StatefulWidget {
  final Map<String, dynamic>? entry;
  final int? initialStudentId;

  const FormSetoranScreen({super.key, this.entry, this.initialStudentId});

  @override
  State<FormSetoranScreen> createState() => _FormSetoranScreenState();
}

class _FormSetoranScreenState extends State<FormSetoranScreen> {
  final TahfidzRepository _repository = TahfidzRepository();
  final TahfidzService _tahfidzService = TahfidzService();
  final QuranService _quranService = QuranService();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  List<Surah> _surahs = [];
  List<Surah> _filteredSurahs = [];
  int? _teacherId;

  // Form Fields
  int? _selectedStudentId;
  DateTime _selectedDate = DateTime.now();
  String _selectedJenisSetoran = 'HAFALAN_BARU';
  int? _selectedSurahAwal;
  int? _selectedSurahAkhir;

  final TextEditingController _ayatAwalController = TextEditingController();
  final TextEditingController _ayatAkhirController = TextEditingController();
  final TextEditingController _jumlahBarisController = TextEditingController(text: '1');
  String? _selectedNilai;
  final TextEditingController _catatanController = TextEditingController();

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ayatAwalController.dispose();
    _ayatAkhirController.dispose();
    _jumlahBarisController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String get _selectedStudentDisplayName {
    if (_selectedStudentId == null) return 'Pilih Santri';
    final student = _students.firstWhere(
      (s) => int.tryParse(s['id']?.toString() ?? '') == _selectedStudentId,
      orElse: () => null,
    );
    if (student == null) return 'Pilih Santri';
    final name = student['nama_siswa'] ?? student['full_name'] ?? student['name'] ?? '-';
    final klass = student['kelas'] ??
        student['nama_kelas'] ??
        student['tingkat'] ??
        student['unit_name'] ??
        student['nama_unit'] ??
        student['division_name'] ??
        student['nama_halaqah'] ??
        student['halaqah'] ??
        student['nama_halaqoh'] ??
        student['rombel'] ??
        student['jenjang'];
    return klass != null ? '$name - $klass' : name;
  }

  String get _selectedSurahAwalName {
    if (_selectedSurahAwal == null) return 'Pilih Surah Awal';
    for (var surah in _surahs) {
      if (surah.nomor == _selectedSurahAwal) return surah.namaLatin;
    }
    return 'Pilih Surah Awal';
  }

  String get _selectedSurahAkhirName {
    if (_selectedSurahAkhir == null) return 'Pilih Surah Akhir';
    for (var surah in _surahs) {
      if (surah.nomor == _selectedSurahAkhir) return surah.namaLatin;
    }
    return 'Pilih Surah Akhir';
  }

  Widget _buildSelectionField(
    String text,
    VoidCallback? onTap, {
    IconData? icon,
    bool hasError = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: hasError ? Colors.redAccent : const Color(0xFFF1F5F9),
            width: hasError ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: hasError ? Colors.redAccent : const Color(0xFF94A3B8)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: text.startsWith('Pilih') || text.startsWith('Cari')
                      ? const Color(0xFF94A3B8)
                      : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: hasError ? Colors.redAccent : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentPicker(FormFieldState<int> formState) {
    _filteredStudents = _students;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: TextField(
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari nama santri...',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          _filteredStudents = _students.where((s) {
                            final name = (s['nama_siswa'] ??
                                    s['nama_santri'] ??
                                    s['nama_lengkap'] ??
                                    s['full_name'] ??
                                    s['name'] ??
                                    '')
                                .toString()
                                .toLowerCase();
                            return name.contains(value.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _filteredStudents.isEmpty
                        ? Center(
                            child: Text(
                              "Santri tidak ditemukan.",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              final id = int.tryParse(student['id']?.toString() ?? '');
                              final name = student['nama_siswa'] ??
                                  student['nama_santri'] ??
                                  student['nama_lengkap'] ??
                                  student['full_name'] ??
                                  student['name'] ??
                                  'No Name';
                              final klass = student['kelas'] ??
                                  student['nama_kelas'] ??
                                  student['tingkat'] ??
                                  student['unit_name'] ??
                                  student['nama_unit'] ??
                                  student['division_name'] ??
                                  student['nama_halaqah'] ??
                                  student['halaqah'] ??
                                  student['nama_halaqoh'] ??
                                  student['rombel'] ??
                                  student['jenjang'] ??
                                  '-';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                title: Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                trailing: Text(
                                  klass,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedStudentId = id;
                                  });
                                  formState.didChange(id);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSurahPicker(FormFieldState<int> formState, {required bool isStart}) {
    _filteredSurahs = _surahs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: TextField(
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari nama surah...',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          _filteredSurahs = _surahs
                              .where((s) => s.namaLatin.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _filteredSurahs.isEmpty
                        ? Center(
                            child: Text(
                              "Surah tidak ditemukan.",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredSurahs.length,
                            itemBuilder: (context, index) {
                              final surah = _filteredSurahs[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                title: Text(
                                  surah.namaLatin,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                trailing: Text(
                                  surah.nama,
                                  style: GoogleFonts.amiri(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    if (isStart) {
                                      _selectedSurahAwal = surah.nomor;
                                      _selectedSurahAkhir ??= surah.nomor;
                                    } else {
                                      _selectedSurahAkhir = surah.nomor;
                                    }
                                  });
                                  formState.didChange(surah.nomor);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _teacherId = prefs.getInt('userId');

      final studentsList = await _tahfidzService.getMyStudents(_teacherId);
      final surahsList = await _quranService.getAllSurahs();

      setState(() {
        _students = studentsList;
        _surahs = surahsList;
      });

      if (_isEdit) {
        final entry = widget.entry!;
        setState(() {
          _selectedStudentId = int.tryParse(entry['student_id']?.toString() ?? '');
          if (entry['date'] != null) {
            _selectedDate = DateFormat('yyyy-MM-dd').parse(entry['date']);
          } else if (entry['tanggal'] != null) {
            _selectedDate = DateFormat('yyyy-MM-dd').parse(entry['tanggal']);
          }

          _selectedJenisSetoran = entry['entry_type'] ?? entry['jenis_setoran'] ?? 'HAFALAN_BARU';

          // Ensure it matches backend formats
          if (_selectedJenisSetoran == 'Hafalan Baru') _selectedJenisSetoran = 'HAFALAN_BARU';
          if (_selectedJenisSetoran == 'Murojaah') _selectedJenisSetoran = 'MUROJAAH';
          if (_selectedJenisSetoran == 'Tasmi\'') _selectedJenisSetoran = 'TASMI';
          if (_selectedJenisSetoran == 'Ujian') _selectedJenisSetoran = 'UJIAN';

          _selectedSurahAwal = int.tryParse(entry['start_surah_id']?.toString() ?? entry['surah_id']?.toString() ?? '');
          _selectedSurahAkhir = int.tryParse(entry['end_surah_id']?.toString() ?? entry['surah_id']?.toString() ?? '');

          _ayatAwalController.text = entry['start_ayah']?.toString() ?? entry['ayat_awal']?.toString() ?? '';
          _ayatAkhirController.text = entry['end_ayah']?.toString() ?? entry['ayat_akhir']?.toString() ?? '';
          _jumlahBarisController.text = entry['line_count']?.toString() ?? entry['jumlah_baris']?.toString() ?? '1';
          final rawScore = entry['status']?.toString() ?? entry['quality']?.toString() ?? entry['score']?.toString() ?? entry['nilai']?.toString() ?? '';
          if (rawScore.toLowerCase() == 'lancar' || rawScore.toLowerCase() == 'ziyadah') {
            _selectedNilai = 'Lancar';
          } else if (rawScore.toLowerCase() == 'kurang' || rawScore.toLowerCase() == 'kurang lancar') {
            _selectedNilai = 'Kurang';
          } else if (rawScore.toLowerCase() == 'tidak' || rawScore.toLowerCase() == 'ulang') {
            _selectedNilai = 'Tidak';
          } else {
            _selectedNilai = null;
          }
          _catatanController.text = entry['notes'] ?? entry['catatan'] ?? '';
        });
      } else if (widget.initialStudentId != null) {
        setState(() {
          _selectedStudentId = widget.initialStudentId;
        });
      }
    } catch (e) {
      debugPrint('Error loading form data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      'student_id': _selectedStudentId,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'entry_type': _selectedJenisSetoran,
      'jenis_setoran': _selectedJenisSetoran,
      'start_surah_id': _selectedSurahAwal,
      'surah_start': _selectedSurahAwalName,
      'surah_id': _selectedSurahAwal,
      'start_ayah': int.parse(_ayatAwalController.text),
      'ayat_start': int.parse(_ayatAwalController.text),
      'end_surah_id': _selectedSurahAkhir,
      'surah_end': _selectedSurahAkhirName,
      'end_ayah': int.parse(_ayatAkhirController.text),
      'ayat_end': int.parse(_ayatAkhirController.text),
      'line_count': int.parse(_jumlahBarisController.text),
      'total_baris': int.parse(_jumlahBarisController.text),
      'score': null,
      'status': _selectedNilai,
      'notes': _catatanController.text,
      'teacher_id': _teacherId,
    };

    Map<String, dynamic> result;
    if (_isEdit) {
      result = await _repository.updateEntry(widget.entry!['id'], payload);
    } else {
      result = await _repository.createEntry(payload);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Perubahan berhasil disimpan.' : 'Setoran berhasil ditambahkan.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (result['message'] != null && result['message'].toString().contains('Unauthorized')) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan setoran.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildKelancaranOption(String value, Color activeColor, IconData icon, FormFieldState<String> state) {
    final isSelected = _selectedNilai == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNilai = value;
        });
        state.didChange(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFF1F5F9),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : const Color(0xFF94A3B8),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Color(0xFF3B82F6),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          _isEdit ? 'Edit Setoran' : 'Tambah Setoran',
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
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Santri Selector
                        _buildLabel('Santri'),
                        const SizedBox(height: 8),
                        FormField<int>(
                          key: const Key('form_field_santri'),
                          initialValue: _selectedStudentId,
                          validator: (value) => _selectedStudentId == null ? 'Santri wajib diisi' : null,
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSelectionField(
                                  _selectedStudentId != null ? _selectedStudentDisplayName : 'Pilih Santri',
                                  _isEdit ? null : () => _showStudentPicker(state),
                                  icon: Icons.person_search_rounded,
                                  hasError: state.hasError,
                                ),
                                if (state.hasError) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      state.errorText ?? '',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                                ]
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Date Picker
                        _buildLabel('Tanggal Setoran'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                                ),
                                const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6), size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Jenis Setoran
                        _buildLabel('Jenis Setoran'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedJenisSetoran,
                          decoration: _inputDecoration('Pilih Jenis Setoran'),
                          items: const [
                            DropdownMenuItem(value: 'HAFALAN_BARU', child: Text('Hafalan Baru')),
                            DropdownMenuItem(value: 'MUROJAAH', child: Text('Murojaah')),
                          ],
                          onChanged: (val) => setState(() => _selectedJenisSetoran = val!),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                          dropdownColor: Colors.white,
                        ),
                        const SizedBox(height: 20),

                        // Surah Awal Dropdown
                        _buildLabel('Surah Awal'),
                        const SizedBox(height: 8),
                        FormField<int>(
                          key: const Key('form_field_surah_awal'),
                          initialValue: _selectedSurahAwal,
                          validator: (value) => _selectedSurahAwal == null ? 'Surah awal wajib diisi' : null,
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSelectionField(
                                  _selectedSurahAwal != null ? _selectedSurahAwalName : 'Pilih Surah Awal',
                                  () => _showSurahPicker(state, isStart: true),
                                  icon: Icons.menu_book_outlined,
                                  hasError: state.hasError,
                                ),
                                if (state.hasError) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      state.errorText ?? '',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                                ]
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Ayat Awal
                        _buildLabel('Ayat Awal'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ayatAwalController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Masukkan ayat awal'),
                          style: GoogleFonts.poppins(fontSize: 14),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Ayat awal wajib diisi';
                            if (int.tryParse(value) == null) return 'Ayat harus angka';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Surah Akhir Dropdown
                        _buildLabel('Surah Akhir'),
                        const SizedBox(height: 8),
                        FormField<int>(
                          key: const Key('form_field_surah_akhir'),
                          initialValue: _selectedSurahAkhir,
                          validator: (value) => _selectedSurahAkhir == null ? 'Surah akhir wajib diisi' : null,
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSelectionField(
                                  _selectedSurahAkhir != null ? _selectedSurahAkhirName : 'Pilih Surah Akhir',
                                  () => _showSurahPicker(state, isStart: false),
                                  icon: Icons.menu_book_outlined,
                                  hasError: state.hasError,
                                ),
                                if (state.hasError) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      state.errorText ?? '',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                                ]
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Ayat Akhir
                        _buildLabel('Ayat Akhir'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ayatAkhirController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Masukkan ayat akhir'),
                          style: GoogleFonts.poppins(fontSize: 14),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Ayat akhir wajib diisi';
                            if (int.tryParse(value) == null) return 'Ayat harus angka';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Jumlah Baris
                        _buildLabel('Jumlah Baris'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                int current = int.tryParse(_jumlahBarisController.text) ?? 1;
                                if (current > 1) {
                                  setState(() {
                                    _jumlahBarisController.text = (current - 1).toString();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.remove_rounded, color: Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _jumlahBarisController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: _inputDecoration('1').copyWith(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                                  final val = int.tryParse(value);
                                  if (val == null || val < 1) return 'Minimal 1';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                int current = int.tryParse(_jumlahBarisController.text) ?? 1;
                                setState(() {
                                  _jumlahBarisController.text = (current + 1).toString();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.add_rounded, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Kelancaran
                        _buildLabel('Kelancaran'),
                        const SizedBox(height: 10),
                        FormField<String>(
                          initialValue: _selectedNilai,
                          validator: (value) => _selectedNilai == null ? 'Kelancaran wajib dipilih' : null,
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildKelancaranOption('Lancar', const Color(0xFF10B981), Icons.check_circle_outline_rounded, state)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildKelancaranOption('Kurang', const Color(0xFFF59E0B), Icons.help_outline_rounded, state)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildKelancaranOption('Tidak', const Color(0xFFEF4444), Icons.highlight_off_rounded, state)),
                                  ],
                                ),
                                if (state.hasError) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      state.errorText ?? '',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                                ]
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Catatan
                        _buildLabel('Catatan'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _catatanController,
                          maxLines: 3,
                          decoration: _inputDecoration('Catatan tambahan...'),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 30),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                            label: Text(
                              _isSubmitting
                                  ? 'Menyimpan...'
                                  : (_isEdit ? 'Simpan Perubahan' : 'Simpan Setoran'),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
