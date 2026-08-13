import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/tahfidz_service.dart';
import '../../services/quran_service.dart';
import '../../models/surah_model.dart';
import '../../providers/tahfidz_provider.dart';
import '../../utils/access_control.dart';
import './riwayat_setoran_screen.dart';

class SetoranTahfidzScreen extends StatefulWidget {
  const SetoranTahfidzScreen({super.key});

  @override
  State<SetoranTahfidzScreen> createState() => _SetoranTahfidzScreenState();
}

class _SetoranTahfidzScreenState extends State<SetoranTahfidzScreen> {
  final TahfidzService _service = TahfidzService();
  final QuranService _quranService = QuranService();

  List<dynamic> _studentsList = [];
  List<dynamic> _filteredStudents = [];
  int? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentClass;

  List<Surah> _surahList = [];
  List<Surah> _filteredSurahs = [];
  String? _selectedSurahStart;
  String? _selectedSurahEnd;

  final TextEditingController _ayatStartController = TextEditingController();
  final TextEditingController _ayatEndController = TextEditingController();
  final TextEditingController _totalBarisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final ValueNotifier<String> _quality = ValueNotifier<String>('Lancar');
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Coordinator state
  bool _isKoordinator = false;
  DateTime _coordSelectedDate = DateTime.now();
  List<dynamic> _coordMemorizationRecords = [];

  @override
  void dispose() {
    _ayatStartController.dispose();
    _ayatEndController.dispose();
    _totalBarisController.dispose();
    _notesController.dispose();
    _quality.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isKoordinator = AccessControl.can('is_koordinator');
    if (_isKoordinator) {
      _fetchCoordinatorData();
    } else {
      _loadInitialData();
    }
  }

  Future<void> _fetchCoordinatorData() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_coordSelectedDate);
      final records = await _service.getMemorizationHistory(date: dateStr);
      if (mounted) {
        setState(() => _coordMemorizationRecords = records);
      }
    } catch (e) {
      debugPrint('Error fetching coordinator memorization data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? teacherId = prefs.getInt('userId');
      final String? teacherName = prefs.getString('fullName');

      // Use provider to fetch students
      if (!mounted) return;
      final provider = Provider.of<TahfidzProvider>(context, listen: false);
      if (provider.myStudents.isEmpty) {
        await provider.fetchMyStudents(teacherId, teacherName: teacherName);
      } else {
        provider.setTeacherInfo(teacherId, teacherName);
        await provider.checkHalaqohStatus();
      }

      final surahs = await _quranService.getAllSurahs();
      setState(() {
        _studentsList = provider.myStudents;
        _filteredStudents = _studentsList;
        _surahList = surahs;
        _filteredSurahs = _surahList;
      });

      // Check restrictions (only for non-coordinator)
      if (!_isKoordinator && (!provider.isHalaqohOpened || !provider.isAttendanceSubmitted)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !provider.isHalaqohOpened
                  ? 'Mohon buka halaqoh dulu'
                  : 'Mohon absen santri dulu',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStudentPicker() {
    _filteredStudents = _studentsList;
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
                          _filteredStudents =
                              _studentsList.where((s) {
                                final name =
                                    (s['nama_siswa'] ??
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
                    child:
                        _filteredStudents.isEmpty
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
                                      _selectedStudentId = int.tryParse(
                                        student['id'].toString(),
                                      );
                                      _selectedStudentName = name;
                                      _selectedStudentClass = klass;
                                    });
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

  void _showSurahPicker({required bool isStart}) {
    _filteredSurahs = _surahList;
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
                          _filteredSurahs =
                              _surahList
                                  .where(
                                    (s) => s.namaLatin.toLowerCase().contains(
                                      value.toLowerCase(),
                                    ),
                                  )
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
                                      _selectedSurahStart = surah.namaLatin;
                                      _selectedSurahEnd ??= surah.namaLatin;
                                    } else {
                                      _selectedSurahEnd = surah.namaLatin;
                                    }
                                  });
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

  Future<void> _submitSetoran() async {
    final provider = Provider.of<TahfidzProvider>(context, listen: false);
    if (!_isKoordinator && (!provider.isHalaqohOpened || !provider.isAttendanceSubmitted)) {
      _showError(
        !provider.isHalaqohOpened
            ? 'Mohon buka halaqoh dulu'
            : 'Mohon absen santri dulu',
      );
      return;
    }

    if (_selectedStudentId == null) {
      _showError('Pilih santri terlebih dahulu');
      return;
    }
    if (_selectedSurahStart == null) {
      _showError('Pilih surah awal terlebih dahulu');
      return;
    }
    if (_selectedSurahEnd == null) {
      _showError('Pilih surah akhir terlebih dahulu');
      return;
    }

    setState(() => _isSubmitting = true);

    final int? teacherId = provider.teacherId;

    int? startSurahId;
    int? endSurahId;
    for (var s in _surahList) {
      if (s.namaLatin == _selectedSurahStart) startSurahId = s.nomor;
      if (s.namaLatin == _selectedSurahEnd) endSurahId = s.nomor;
    }

    final activeSession =
        provider.activeSession ?? (DateTime.now().hour < 12 ? 'Pagi' : 'Sore');
    final now = DateTime.now();

    final data = {
      "student_id": _selectedStudentId,
      "date": DateFormat('yyyy-MM-dd').format(now),
      "session": activeSession,
      "session_name": activeSession,
      "waktu_setoran": DateFormat('HH:mm:ss').format(now),
      "time": DateFormat('HH:mm:ss').format(now),
      "created_at": DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      "start_surah_id": startSurahId,
      "surah_start": _selectedSurahStart,
      "surah_id": startSurahId,
      "start_ayah": int.tryParse(_ayatStartController.text) ?? 1,
      "ayat_start": int.tryParse(_ayatStartController.text) ?? 1,
      "line_count": int.tryParse(_totalBarisController.text) ?? 0,
      "total_baris": int.tryParse(_totalBarisController.text) ?? 0,
      "end_surah_id": endSurahId ?? startSurahId,
      "surah_end": _selectedSurahEnd,
      "end_ayah": int.tryParse(_ayatEndController.text) ?? 1,
      "ayat_end": int.tryParse(_ayatEndController.text) ?? 1,
      "status": _quality.value,
      "entry_type": "HAFALAN_BARU",
      "jenis_setoran": "HAFALAN_BARU",
      "notes": _notesController.text,
      "teacher_id": teacherId,
    };

    final result = await _service.submitMemorization(data);
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setoran Berhasil Disimpan'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RiwayatSetoranScreen()),
      );
    } else {
      _showError('Gagal: ${result['message']}');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    // --- COORDINATOR VIEW ---
    if (_isKoordinator) {
      return _buildCoordinatorView();
    }

    // --- PENGAMPU VIEW ---
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Input Hafalan',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const RiwayatSetoranScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: Colors.blueAccent,
                            ),
                            label: Text(
                              'Riwayat',
                              style: GoogleFonts.poppins(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withValues(
                                alpha: 0.1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
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
                            _buildLabel('Nama Pengampu'),
                            const SizedBox(height: 8),
                            Consumer<TahfidzProvider>(
                              builder: (context, provider, child) {
                                return _buildReadOnlyField(
                                  provider.teacherName ?? 'Memuat...',
                                  icon: Icons.assignment_ind_rounded,
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                             _buildLabel('Pilih Santri'),
                            const SizedBox(height: 8),
                            _buildSelectionField(
                              _selectedStudentName != null
                                  ? (_selectedStudentClass != null
                                      ? '$_selectedStudentName - $_selectedStudentClass'
                                      : _selectedStudentName!)
                                  : 'Cari nama santri...',
                              _showStudentPicker,
                              icon: Icons.person_search_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('Surah Awal'),
                            const SizedBox(height: 8),
                            _buildSelectionField(
                              _selectedSurahStart ?? 'Cari nama surah awal...',
                              () => _showSurahPicker(isStart: true),
                              icon: Icons.menu_book_outlined,
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('Surah Akhir'),
                            const SizedBox(height: 8),
                            _buildSelectionField(
                              _selectedSurahEnd ?? 'Cari nama surah akhir...',
                              () => _showSurahPicker(isStart: false),
                              icon: Icons.menu_book_outlined,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Ayat Mulai'),
                                      const SizedBox(height: 8),
                                      _buildNumberInput(_ayatStartController),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Ayat Selesai'),
                                      const SizedBox(height: 8),
                                      _buildNumberInput(_ayatEndController),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Total Baris'),
                                      const SizedBox(height: 8),
                                      _buildNumberInput(_totalBarisController),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('Kualitas Hafalan'),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: ValueListenableBuilder<String>(
                                valueListenable: _quality,
                                builder: (context, currentQuality, _) {
                                  return Row(
                                    children: [
                                      _buildQualityOption('Lancar', currentQuality),
                                      _buildQualityOption('Kurang Lancar', currentQuality),
                                      _buildQualityOption('Ulang', currentQuality),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('Catatan (Opsional)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              _notesController,
                              'Catatan tambahan...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isSubmitting ? null : _submitSetoran,
                                icon:
                                    _isSubmitting
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
                                      : 'Simpan Setoran',
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
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSelectionField(
    String text,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color:
                      text.contains('...') ? const Color(0xFF94A3B8) : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
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
              size: 18,
              color: Colors.blueAccent,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Setoran Tahfidz',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    int val = int.tryParse(controller.text) ?? 0;
                    controller.text = (val + 1).toString();
                  },
                  child: const Icon(Icons.arrow_drop_up_rounded, size: 20, color: Color(0xFF64748B)),
                ),
                GestureDetector(
                  onTap: () {
                    int val = int.tryParse(controller.text) ?? 0;
                    if (val > 0) controller.text = (val - 1).toString();
                  },
                  child: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(String label, String currentQuality) {
    bool isSelected = currentQuality == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) _quality.value = label;
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: Colors.transparent, // Ensure full area is clickable
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  // ====== COORDINATOR VIEW ======
  Widget _buildCoordinatorView() {
    final dateStr = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(_coordSelectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Monitoring Setoran',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCoordinatorData,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Picker Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.indigo[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _coordSelectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _coordSelectedDate = picked);
                        _fetchCoordinatorData();
                      }
                    },
                    child: Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(
                      () =>
                          _coordSelectedDate = _coordSelectedDate.subtract(
                            const Duration(days: 1),
                          ),
                    );
                    _fetchCoordinatorData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(
                      () =>
                          _coordSelectedDate = _coordSelectedDate.add(
                            const Duration(days: 1),
                          ),
                    );
                    _fetchCoordinatorData();
                  },
                ),
              ],
            ),
          ),
          // Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Total Setoran: ${_coordMemorizationRecords.length}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Records List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _coordMemorizationRecords.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada setoran pada tanggal ini',
                            style: GoogleFonts.poppins(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _coordMemorizationRecords.length,
                      itemBuilder: (context, index) {
                        final record = _coordMemorizationRecords[index];
                        return _buildCoordRecordCard(record);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordRecordCard(Map<String, dynamic> record) {
    final studentName = record['student_name'] ?? '-';
    final surah = record['surah_name'] ?? '-';
    final ayatStart = record['ayat_start']?.toString() ?? '-';
    final ayatEnd = record['ayat_end']?.toString() ?? '-';
    final quality = record['quality'] ?? '-';
    final teacherName = record['teacher_name'] ?? '-';
    final notes = record['notes'] ?? '';

    Color qualityColor;
    switch (quality) {
      case 'Lancar':
        qualityColor = Colors.green;
        break;
      case 'Kurang Lancar':
        qualityColor = Colors.orange;
        break;
      case 'Ulang':
        qualityColor = Colors.red;
        break;
      default:
        qualityColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                  child: Text(
                    studentName.toString().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Pengampu: $teacherName',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quality,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: qualityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: Colors.indigo[300]),
                const SizedBox(width: 6),
                Text(
                  '$surah: $ayatStart - $ayatEnd',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notes,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
