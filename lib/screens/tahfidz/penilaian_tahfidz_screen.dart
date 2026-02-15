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
  int? _selectedStudentId;
  DateTime _selectedDate = DateTime.now();
  String _category = 'Bulanan';

  final TextEditingController _tajweedController = TextEditingController();
  final TextEditingController _fluencyController = TextEditingController();
  final TextEditingController _makhrajController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Coordinator state
  bool _isKoordinator = false;
  List<dynamic> _coordAssessmentRecords = [];

  @override
  void initState() {
    super.initState();
    _isKoordinator = AccessControl.can('is_koordinator');
    if (_isKoordinator) {
      _fetchCoordinatorData();
    } else {
      _fetchStudents();
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

  Future<void> _fetchStudents() async {
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

      setState(() {
        _studentsList = provider.myStudents;
      });
    } catch (e) {
      debugPrint("Error fetching students: $e");
    } finally {
      setState(() => _isLoading = false);
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
      Navigator.pop(context);
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
    // --- COORDINATOR VIEW ---
    if (_isKoordinator) {
      return _buildCoordinatorView();
    }

    // --- PENGAMPU VIEW ---
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          'Input Penilaian',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard([
                      _buildLabel('Pilih Siswa'),
                      const SizedBox(height: 8),
                      _buildStudentDropdown(),
                      const SizedBox(height: 20),
                      _buildLabel('Tanggal Penilaian'),
                      const SizedBox(height: 8),
                      _buildDatePicker(),
                      const SizedBox(height: 20),
                      _buildLabel('Kategori'),
                      const SizedBox(height: 8),
                      _buildCategoryDropdown(),
                    ]),
                    const SizedBox(height: 20),
                    _buildCard([
                      Text(
                        "Nilai (0-100)",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildScoreInput("Tajwid", _tajweedController),
                      const SizedBox(height: 12),
                      _buildScoreInput("Kelancaran", _fluencyController),
                      const SizedBox(height: 12),
                      _buildScoreInput("Makhraj", _makhrajController),
                    ]),
                    const SizedBox(height: 20),
                    _buildCard([
                      _buildLabel("Catatan / Komentar"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: "Tulis catatan perkembangan...",
                        ),
                      ),
                    ]),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitPenilaian,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isSubmitting ? "Menyimpan..." : "Simpan Penilaian",
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
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
                        ? ' - Kelas ${s['kelas']}'
                        : s['nama_kelas'] != null
                        ? ' - Kelas ${s['nama_kelas']}'
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          items:
              ["Bulanan", "Ujian", "Harian"].map((c) {
                return DropdownMenuItem<String>(value: c, child: Text(c));
              }).toList(),
          onChanged: (val) => setState(() => _category = val!),
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

  Widget _buildScoreInput(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(child: Text(label, style: GoogleFonts.poppins())),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Monitoring Penilaian',
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
                'Kategori: $category',
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
