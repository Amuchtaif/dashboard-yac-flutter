import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tahfidz_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _service.getStudents();
      setState(() {
        _studentsList = students;
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

    final prefs = await SharedPreferences.getInstance();
    int? teacherId = prefs.getInt('userId');

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
                  child: Text(s['nama_siswa'] ?? '-'),
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
}
