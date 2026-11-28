import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/exam_model.dart';
import '../../services/exam_service.dart';
import '../../services/omr_scanner_service.dart';

class OmrResultReviewScreen extends StatefulWidget {
  final ExamPackageDetailModel packageDetail;
  final OmrScanResult scanResult;
  final int? initialStudentId;
  final File? rawImageFile;

  const OmrResultReviewScreen({
    super.key,
    required this.packageDetail,
    required this.scanResult,
    this.initialStudentId,
    this.rawImageFile,
  });

  @override
  State<OmrResultReviewScreen> createState() => _OmrResultReviewScreenState();
}

class _OmrResultReviewScreenState extends State<OmrResultReviewScreen> {
  final ExamService _examService = ExamService();

  late List<ExamAnswerItem> _answers;
  int? _selectedStudentId;
  StudentExamModel? _selectedStudent;
  int _currentUserId = 0;
  bool _isSaving = false;

  late int _correctCount;
  late int _wrongCount;
  late int _blankCount;
  late int _doubleCount;
  late double _score;

  @override
  void initState() {
    super.initState();
    // Salin list jawaban agar bisa diedit secara independen
    _answers = widget.scanResult.answers
        .map((a) => ExamAnswerItem(
              questionNumber: a.questionNumber,
              selectedOption: a.selectedOption,
              correctOption: a.correctOption,
              isCorrect: a.isCorrect,
              fillRatios: a.fillRatios,
            ))
        .toList();

    _selectedStudentId = widget.initialStudentId;
    if (_selectedStudentId != null && _selectedStudentId! > 0) {
      _selectedStudent = widget.packageDetail.getStudent(_selectedStudentId!);
    }

    _recalculateScores();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get('user_id') ?? prefs.get('userId') ?? prefs.get('id');
    _currentUserId = rawId != null ? int.tryParse(rawId.toString()) ?? 0 : 0;
  }

  /// Hitung ulang skor setiap kali guru mengubah jawaban manual (Tap-to-Fix)
  void _recalculateScores() {
    int c = 0;
    int w = 0;
    int b = 0;
    int d = 0;

    final keyMap = {for (final k in widget.packageDetail.answerKeys) k.questionNumber: k.correctOption};

    for (final ans in _answers) {
      final correctKey = keyMap[ans.questionNumber];
      if (ans.selectedOption == 'BLANK') {
        b++;
      } else if (ans.selectedOption == 'DOUBLE') {
        d++;
      } else if (correctKey != null && ans.selectedOption == correctKey) {
        c++;
      } else {
        w++;
      }
    }

    final totalQ = widget.packageDetail.package.totalQuestions > 0
        ? widget.packageDetail.package.totalQuestions
        : _answers.length;

    final rawScore = totalQ > 0 ? ((c / totalQ) * 100.0) : 0.0;
    final finalScore = (rawScore * 10).round() / 10.0;

    setState(() {
      _correctCount = c;
      _wrongCount = w;
      _blankCount = b;
      _doubleCount = d;
      _score = finalScore;
    });
  }

  void _onOptionTapped(int questionNumber, String newOption) {
    setState(() {
      final ans = _answers.firstWhere((a) => a.questionNumber == questionNumber);
      ans.selectedOption = newOption;
      _recalculateScores();
    });
  }

  void _openStudentPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentSelectionSheet(
        students: widget.packageDetail.students,
        currentSelectedId: _selectedStudentId,
        onSelected: (st) {
          setState(() {
            _selectedStudentId = st.id;
            _selectedStudent = st;
          });
        },
      ),
    );
  }

  Future<void> _saveAndProceed() async {
    // Validasi santri
    if (_selectedStudentId == null || _selectedStudentId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'LJK Kosong terdeteksi. Harap pilih nama santri terlebih dahulu!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFEF4444),
          action: SnackBarAction(
            label: 'Pilih Santri',
            textColor: Colors.white,
            onPressed: _openStudentPickerModal,
          ),
        ),
      );
      _openStudentPickerModal();
      return;
    }

    setState(() => _isSaving = true);

    final submission = ExamScanSubmission(
      packageId: widget.packageDetail.package.id,
      studentId: _selectedStudentId!,
      scannerUserId: _currentUserId,
      autoSync: true,
      answers: _answers,
      scanImagePath: widget.scanResult.annotatedImagePath,
    );

    final result = await _examService.submitScan(submission);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedStudent?.namaSiswa ?? "Santri"} berhasil dikoreksi (Nilai: $_score)!',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Kembali dengan membawa `true` agar layar scanner siap untuk santri berikutnya
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${result.message}', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.packageDetail.package.optionLabels;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Koreksi LJK',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              widget.packageDetail.package.title,
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Student Identity Header Card
            _buildStudentCard(),
            const SizedBox(height: 14),

            // 2. Score Summary Metrics Card
            _buildScoreMetricCard(),
            const SizedBox(height: 16),

            // 3. Visual LJK Image Overlay (Pinch to zoom)
            _buildImagePreviewCard(),
            const SizedBox(height: 20),

            // 4. Tap-To-Fix Manual Review Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REVISI JAWABAN (TAP-TO-FIX)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Ketuk untuk ubah',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Question List Cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _answers.length,
              itemBuilder: (context, index) {
                final ans = _answers[index];
                return _buildQuestionFixTile(ans, labels);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildStudentCard() {
    final hasStudent = _selectedStudent != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasStudent ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: hasStudent ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
            child: Icon(
              hasStudent ? Icons.person_rounded : Icons.person_search_rounded,
              color: hasStudent ? const Color(0xFF2563EB) : const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStudent ? _selectedStudent!.namaSiswa : 'LJK Kosong (Pilih Santri)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasStudent ? const Color(0xFF1E293B) : const Color(0xFFD97706),
                  ),
                ),
                Text(
                  hasStudent
                      ? 'NISN: ${_selectedStudent!.nomorInduk.isNotEmpty ? _selectedStudent!.nomorInduk : "-"}'
                      : 'Ketuk tombol di samping untuk memilih santri',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openStudentPickerModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasStudent ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB),
              foregroundColor: hasStudent ? const Color(0xFF334155) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              hasStudent ? 'Ganti' : 'Pilih',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetricCard() {
    final isGood = _score >= 75.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nilai Besar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isGood ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isGood ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'NILAI',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isGood ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
                Text(
                  '$_score',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isGood ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 3 Kolom Metrik
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubMetric('Benar', '$_correctCount', const Color(0xFF10B981)),
                _buildSubMetric('Salah', '$_wrongCount', const Color(0xFFEF4444)),
                _buildSubMetric(
                  'Kosong/2x',
                  '${_blankCount + _doubleCount}',
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.preview_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      'Preview Koreksi LJK (Overlay)',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Pinch zoom untuk cek arsiran',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Zoomable Warped Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFF0F172A),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: Image.memory(
                    widget.scanResult.annotatedImageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Legend Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildLegendItem(const Color(0xFF10B981), 'Benar'),
                _buildLegendItem(const Color(0xFFEF4444), 'Salah'),
                _buildLegendItem(const Color(0xFFF59E0B), 'Kunci Seharusnya'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildQuestionFixTile(ExamAnswerItem ans, List<String> labels) {
    final keyMap = {for (final k in widget.packageDetail.answerKeys) k.questionNumber: k.correctOption};
    final correctKey = keyMap[ans.questionNumber];
    final isCorrect = (correctKey != null && ans.selectedOption == correctKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFFE2E8F0)
              : ans.isBlank
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFFECDD3),
        ),
      ),
      child: Row(
        children: [
          // Nomor Soal
          SizedBox(
            width: 32,
            child: Text(
              '${ans.questionNumber}.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),

          // Kunci Jawaban Indikator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Kunci: $correctKey',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Pilihan Opsi A, B, C, D, (E)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final opt in labels)
                  _buildOptionBubbleButton(
                    opt: opt,
                    isSelected: ans.selectedOption == opt,
                    isKey: opt == correctKey,
                    isCorrect: isCorrect,
                    onTap: () => _onOptionTapped(ans.questionNumber, opt),
                  ),
                _buildBlankButton(
                  isSelected: ans.isBlank,
                  onTap: () => _onOptionTapped(ans.questionNumber, 'BLANK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBubbleButton({
    required String opt,
    required bool isSelected,
    required bool isKey,
    required bool isCorrect,
    required VoidCallback onTap,
  }) {
    Color bg = const Color(0xFFF8FAFC);
    Color border = const Color(0xFFCBD5E1);
    Color textColor = const Color(0xFF475569);

    if (isSelected) {
      if (isCorrect) {
        bg = const Color(0xFF10B981);
        border = const Color(0xFF059669);
        textColor = Colors.white;
      } else {
        bg = const Color(0xFFEF4444);
        border = const Color(0xFFDC2626);
        textColor = Colors.white;
      }
    } else if (isKey) {
      // Highlight outline kunci jika bukan opsi terpilih
      border = const Color(0xFFF59E0B);
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: isSelected || isKey ? 1.8 : 1.0),
        ),
        child: Text(
          opt,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected || isKey ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBlankButton({required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          'Kosong',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Scan Ulang',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAndProceed,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan & Scan Lanjut',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable Modal Sheet untuk memilih santri jika LJK Kosong
class _StudentSelectionSheet extends StatefulWidget {
  final List<StudentExamModel> students;
  final int? currentSelectedId;
  final ValueChanged<StudentExamModel> onSelected;

  const _StudentSelectionSheet({
    required this.students,
    required this.currentSelectedId,
    required this.onSelected,
  });

  @override
  State<_StudentSelectionSheet> createState() => _StudentSelectionSheetState();
}

class _StudentSelectionSheetState extends State<_StudentSelectionSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<StudentExamModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.students;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = widget.students.where((s) {
        return s.namaSiswa.toLowerCase().contains(q) || s.nomorInduk.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pilih Santri Pemilik LJK',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),

          // Search Box
          TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari nama atau NISN...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Santri tidak ditemukan.',
                      style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final s = _filtered[i];
                      final isSelected = s.id == widget.currentSelectedId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.person,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          s.namaSiswa,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'NISN: ${s.nomorInduk}',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF2563EB))
                            : (s.isScanned
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Sudah',
                                      style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF047857)),
                                    ),
                                  )
                                : null),
                        onTap: () {
                          widget.onSelected(s);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
