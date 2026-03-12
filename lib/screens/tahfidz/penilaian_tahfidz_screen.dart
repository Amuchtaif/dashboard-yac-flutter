import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/tahfidz_service.dart';
import '../../providers/tahfidz_provider.dart';
import '../../utils/access_control.dart';

class PenilaianTahfidzScreen extends StatefulWidget {
  const PenilaianTahfidzScreen({super.key});

  @override
  State<PenilaianTahfidzScreen> createState() => _PenilaianTahfidzScreenState();
}

class _PenilaianTahfidzScreenState extends State<PenilaianTahfidzScreen> {
  final TahfidzService _service = TahfidzService();

  List<dynamic> _studentsList = [];
  List<dynamic> _assessmentTypes = [];
  int? _selectedStudentId;
  DateTime _selectedDate = DateTime.now();
  String _category = 'Bulanan';

  final TextEditingController _tajweedController = TextEditingController();
  final TextEditingController _fluencyController = TextEditingController();
  final TextEditingController _makhrajController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isInputView = false;

  // Coordinator state
  bool _isKoordinator = false;
  List<dynamic> _coordAssessmentRecords = [];
  List<dynamic> _teacherAssessmentRecords = [];

  @override
  void initState() {
    super.initState();
    _isKoordinator = AccessControl.can('is_koordinator');
    _fetchAssessmentTypes();
    if (_isKoordinator) {
      _fetchCoordinatorData();
    } else {
      _fetchTeacherData();
    }
  }

  Future<void> _fetchTeacherData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? teacherId = prefs.getInt('userId');
      final String? teacherName = prefs.getString('fullName');

      if (!mounted) return;
      final provider = Provider.of<TahfidzProvider>(context, listen: false);
      if (provider.myStudents.isEmpty) {
        await provider.fetchMyStudents(teacherId, teacherName: teacherName);
      } else {
        provider.setTeacherInfo(teacherId, teacherName);
      }

      final history = await _service.getAssessmentHistory(teacherId: teacherId);

      setState(() {
        _studentsList = provider.myStudents;
        _teacherAssessmentRecords = history;
      });
    } catch (e) {
      debugPrint("Error fetching teacher data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCoordinatorData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all assessments for coordinator (no date filter)
      final records = await _service.getAssessmentHistory();
      if (mounted) {
        setState(() => _coordAssessmentRecords = records);
      }
    } catch (e) {
      debugPrint('Error fetching coordinator assessment data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAssessmentTypes() async {
    try {
      debugPrint('PenilaianTahfidzScreen: Fetching assessment types...');
      final types = await _service.getAssessmentTypes();
      debugPrint('PenilaianTahfidzScreen: Received ${types.length} types');

      if (mounted) {
        if (types.isNotEmpty) {
          setState(() {
            _assessmentTypes = types;
            // Check if current category is available in new types
            bool exists = types.any((t) {
              final name = (t['name'] ?? t['jenis'] ?? '').toString();
              return name == _category;
            });

            if (!exists) {
              _category =
                  (types.first['name'] ?? types.first['jenis'] ?? 'Bulanan')
                      .toString();
            }
          });
        } else {
          debugPrint(
            'PenilaianTahfidzScreen: Assessment types list is empty from server',
          );
        }
      }
    } catch (e) {
      debugPrint('PenilaianTahfidzScreen: Error fetching assessment types: $e');
    }
  }

  Future<void> _submitPenilaian() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih siswa terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = Provider.of<TahfidzProvider>(context, listen: false);
    final int? teacherId = provider.teacherId;

    int tajweed = int.tryParse(_tajweedController.text) ?? 0;
    int fluency = int.tryParse(_fluencyController.text) ?? 0;
    int makhraj = int.tryParse(_makhrajController.text) ?? 0;
    int total = (tajweed + fluency + makhraj) ~/ 3;

    final data = {
      "student_id": _selectedStudentId,
      "assessment_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
      "category": _category,
      "tajweed_score": tajweed,
      "fluency_score": fluency,
      "makhraj_score": makhraj,
      "total_score": total,
      "comments": _commentsController.text,
      "teacher_id": teacherId,
    };

    final result = await _service.submitAssessment(data);

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penilaian Tersimpan'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isInputView = false;
        // Reset form
        _tajweedController.clear();
        _fluencyController.clear();
        _makhrajController.clear();
        _commentsController.clear();
        _selectedStudentId = null;
      });
      _fetchTeacherData(); // Refresh history
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isKoordinator) {
      return _buildCoordinatorView();
    }

    return _isInputView ? _buildInputView() : _buildHistoryListView();
  }

  Widget _buildHistoryListView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Daftar Penilaian',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTeacherData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _teacherAssessmentRecords.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _teacherAssessmentRecords.length,
                itemBuilder: (context, index) {
                  final record = _teacherAssessmentRecords[index];
                  return _buildAssessmentCard(record);
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _isInputView = true),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Tambah Penilaian",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada data penilaian.",
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _isInputView = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Buat Penilaian Pertama"),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> record) {
    // Similar to coordinator card but maybe simplified
    final studentName = record['student_name'] ?? record['nama_siswa'] ?? '-';
    final category = record['category'] ?? '-';
    final date = record['assessment_date'] ?? '-';
    final total = record['total_score']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF3B82F6),
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
                  studentName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$category • $date",
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              total,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isInputView = false),
        ),
        title: Text(
          'Input Penilaian',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard([
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded,
                            size: 18, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        _buildLabel('Pilih Siswa'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildStudentDropdown(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 18, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        _buildLabel('Tanggal Penilaian'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDatePicker(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.category_rounded,
                            size: 18, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        _buildLabel('Jenis Penilaian'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryDropdown(),
                  ]),
                  const SizedBox(height: 20),
                  _buildCard([
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            size: 18, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Text(
                          "Input Nilai (0-100)",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildScoreInput("Tajwid", _tajweedController,
                        Icons.menu_book_rounded),
                    const SizedBox(height: 14),
                    _buildScoreInput("Kelancaran", _fluencyController,
                        Icons.record_voice_over_rounded),
                    const SizedBox(height: 14),
                    _buildScoreInput("Makhraj", _makhrajController,
                        Icons.record_voice_over_rounded),
                  ]),
                  const SizedBox(height: 20),
                  _buildCard([
                    Row(
                      children: [
                        const Icon(Icons.comment_rounded,
                            size: 18, color: Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        _buildLabel("Catatan / Komentar"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentsController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Tulis catatan perkembangan...",
                        hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF94A3B8), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPenilaian,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _isSubmitting ? "Sedang Menyimpan..." : "Simpan Penilaian",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildStudentDropdown() {
    if (_studentsList.isEmpty) {
      return Text(
        "Anda belum memiliki daftar santri binaan.",
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[400]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedStudentId,
          isExpanded: true,
          hint: const Text("Pilih Santri"),
          items:
              _studentsList.map((s) {
                int id = int.tryParse(s['id'].toString()) ?? 0;
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    "${s['nama_siswa'] ?? s['nama_santri'] ?? s['nama_lengkap'] ?? s['full_name'] ?? s['name'] ?? '-'}${s['kelas'] != null
                        ? ' - ${s['kelas']}'
                        : s['nama_kelas'] != null
                        ? ' - ${s['nama_kelas']}'
                        : ''}",
                  ),
                );
              }).toList(),
          onChanged: (val) => setState(() => _selectedStudentId = val),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    List<String> categories = ["Bulanan", "Ujian", "Harian"];
    if (_assessmentTypes.isNotEmpty) {
      categories =
          _assessmentTypes
              .map((t) => (t['name'] ?? t['jenis'] ?? '').toString())
              .where((name) => name.isNotEmpty)
              .toList();
    }

    // Ensure _category is still valid for the current list
    if (categories.isNotEmpty && !categories.contains(_category)) {
      _category = categories.first;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items:
              categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: Text(c, style: GoogleFonts.poppins(fontSize: 14)),
                );
              }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _category = val);
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreInput(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ====== COORDINATOR VIEW ======
  Widget _buildCoordinatorView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Monitoring Penilaian',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
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
          // Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Total Penilaian: ${_coordAssessmentRecords.length}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
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
                    : _coordAssessmentRecords.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assessment_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada data penilaian yang diinput',
                            style: GoogleFonts.poppins(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _coordAssessmentRecords.length,
                      itemBuilder: (context, index) {
                        final record = _coordAssessmentRecords[index];
                        return _buildCoordAssessmentCard(record);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordAssessmentCard(Map<String, dynamic> record) {
    final studentName = record['student_name'] ?? '-';
    final category = record['category'] ?? '-';
    final tajweed = record['tajweed_score']?.toString() ?? '-';
    final fluency = record['fluency_score']?.toString() ?? '-';
    final makhraj = record['makhraj_score']?.toString() ?? '-';
    final teacherName = record['teacher_name'] ?? '-';
    final comments = record['comments'] ?? '';

    // Calculate average
    double avg = 0;
    int count = 0;
    for (var score in [
      record['tajweed_score'],
      record['fluency_score'],
      record['makhraj_score'],
    ]) {
      if (score != null) {
        avg +=
            (score is int
                ? score.toDouble()
                : double.tryParse(score.toString()) ?? 0);
        count++;
      }
    }
    if (count > 0) avg = avg / count;

    Color avgColor;
    if (avg >= 80) {
      avgColor = Colors.green;
    } else if (avg >= 60) {
      avgColor = Colors.orange;
    } else {
      avgColor = Colors.red;
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
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child: Text(
                    studentName.toString().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
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
                    color: avgColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    avg.toStringAsFixed(0),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: avgColor,
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
                _buildCoordScoreChip('Tajwid', tajweed),
                const SizedBox(width: 8),
                _buildCoordScoreChip('Kelancaran', fluency),
                const SizedBox(width: 8),
                _buildCoordScoreChip('Makhraj', makhraj),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Jenis: $category',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      comments,
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

  Widget _buildCoordScoreChip(String label, String score) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              score,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
