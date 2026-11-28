import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/exam_model.dart';
import '../../services/exam_service.dart';
import '../../services/omr_scanner_service.dart';
import 'omr_camera_scanner_screen.dart';
import 'omr_result_review_screen.dart';

class ExamPackageDetailScreen extends StatefulWidget {
  final ExamPackageModel package;
  const ExamPackageDetailScreen({super.key, required this.package});

  @override
  State<ExamPackageDetailScreen> createState() => _ExamPackageDetailScreenState();
}

class _ExamPackageDetailScreenState extends State<ExamPackageDetailScreen> {
  final ExamService _examService = ExamService();
  final OmrScannerService _omrService = OmrScannerService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchStudentController = TextEditingController();

  bool _isLoading = true;
  ExamPackageDetailModel? _detail;
  String _studentFilter = 'Semua'; // 'Semua', 'Sudah', 'Belum'
  List<StudentExamModel> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _searchStudentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final detail = await _examService.getPackageDetail(widget.package.id);

    if (!mounted) return;
    setState(() {
      _detail = detail;
      _applyStudentFilter();
      _isLoading = false;
    });
  }

  void _applyStudentFilter() {
    if (_detail == null) return;
    final query = _searchStudentController.text.trim().toLowerCase();

    setState(() {
      _filteredStudents = _detail!.students.where((st) {
        if (_studentFilter == 'Sudah' && !st.isScanned) return false;
        if (_studentFilter == 'Belum' && st.isScanned) return false;

        if (query.isNotEmpty) {
          final nameMatch = st.namaSiswa.toLowerCase().contains(query);
          final nisMatch = st.nomorInduk.toLowerCase().contains(query);
          return nameMatch || nisMatch;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _pickImageFromGallery() async {
    if (_detail == null) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );

      if (picked == null) return;

      int? detectedStudentId;
      List<Point2D>? qrCorners;
      final scanner = MobileScannerController(autoStart: false);
      try {
        final barcodeResult = await scanner.analyzeImage(
          picked.path,
          formats: const [BarcodeFormat.qrCode],
        );
        if (barcodeResult != null) {
          for (final b in barcodeResult.barcodes) {
            final raw = b.rawValue;
            if (raw != null && raw.startsWith('YAC|')) {
              final payload = OmrQrPayload.tryParse(raw);
              if (payload != null) {
                if (payload.studentId > 0) {
                  detectedStudentId = payload.studentId;
                }
                if (b.corners.length >= 4) {
                  qrCorners =
                      b.corners.map((o) => Point2D(o.dx, o.dy)).toList();
                }
                break;
              }
            }
          }
        }
      } catch (_) {
      } finally {
        await scanner.dispose();
      }

      final file = File(picked.path);
      _processImageAndOpenReview(
        file,
        predetectedStudentId: detectedStudentId,
        qrCorners: qrCorners,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _processImageAndOpenReview(
    File imageFile, {
    int? predetectedStudentId,
    List<Point2D>? qrCorners,
  }) async {
    if (_detail == null) return;

    // Tampilkan loading dialog selama on-device OMR berjalan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF2563EB)),
                const SizedBox(height: 16),
                Text(
                  'Memproses Koreksi LJK...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Meluruskan kertas & membaca arsiran on-device',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await _omrService.processLjkImage(
        imageFile: imageFile,
        omrLayout: _detail!.omrLayout,
        answerKeys: _detail!.answerKeys,
        qrCorners: qrCorners,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      // Buka Review Screen
      final updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OmrResultReviewScreen(
            packageDetail: _detail!,
            scanResult: result,
            initialStudentId: predetectedStudentId,
            rawImageFile: imageFile,
          ),
        ),
      );

      if (updated == true) {
        _loadDetail();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses LJK: $e', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _openCameraScanner() async {
    if (_detail == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OmrCameraScannerScreen(
          packageDetail: _detail!,
        ),
      ),
    );

    if (updated == true) {
      _loadDetail();
    }
  }

  void _showResultsSummaryModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResultsSummarySheet(packageId: widget.package.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannedCount = _detail?.students.where((s) => s.isScanned).length ?? widget.package.scannedCount;
    final totalCount = _detail?.students.length ?? widget.package.classStudentCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.package.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Rekap Nilai Kelas',
            onPressed: _showResultsSummaryModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : Column(
              children: [
                // Top Info & Action Buttons Card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Overview Badges
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Soal & Kunci',
                              value: '${_detail?.answerKeys.length ?? widget.package.totalQuestions} Soal',
                              subvalue: '${widget.package.optionCount} Opsi (${widget.package.optionLabels.join("-")})',
                              icon: Icons.key_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Progres Koreksi',
                              value: '$scannedCount / $totalCount',
                              subvalue: totalCount > 0 ? '${((scannedCount / totalCount) * 100).toInt()}% Selesai' : '0%',
                              icon: Icons.fact_check_rounded,
                              color: scannedCount == totalCount && totalCount > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: _openCameraScanner,
                              icon: const Icon(Icons.document_scanner_rounded, size: 20),
                              label: Text(
                                'Mulai Scan LJK',
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(Icons.photo_library_outlined, size: 18),
                              label: Text(
                                'Galeri',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search & Filter Santri Bar
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DAFTAR SANTRI KELAS (${widget.package.gradeName})',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              _buildMiniFilter('Semua'),
                              const SizedBox(width: 4),
                              _buildMiniFilter('Sudah'),
                              const SizedBox(width: 4),
                              _buildMiniFilter('Belum'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchStudentController,
                          onChanged: (_) => _applyStudentFilter(),
                          style: GoogleFonts.poppins(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau nomor induk...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List of Students
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada santri yang sesuai.',
                            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            return _buildStudentTile(_filteredStudents[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subvalue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF64748B)),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                Text(
                  subvalue,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFilter(String label) {
    final isSel = _studentFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _studentFilter = label;
          _applyStudentFilter();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentTile(StudentExamModel st) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: st.isScanned ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
            child: Icon(
              st.isScanned ? Icons.check_circle_rounded : Icons.person_outline_rounded,
              size: 20,
              color: st.isScanned ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  st.namaSiswa,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'NISN: ${st.nomorInduk.isNotEmpty ? st.nomorInduk : "-"}',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (st.isScanned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${st.lastScore ?? 0}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF047857),
                    ),
                  ),
                  Text(
                    'Terkoreksi',
                    style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Belum',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet Rekap Hasil Nilai Kelas
class _ResultsSummarySheet extends StatefulWidget {
  final int packageId;
  const _ResultsSummarySheet({required this.packageId});

  @override
  State<_ResultsSummarySheet> createState() => _ResultsSummarySheetState();
}

class _ResultsSummarySheetState extends State<_ResultsSummarySheet> {
  final ExamService _examService = ExamService();
  bool _isLoading = true;
  List<ExamScanResultItem> _results = [];
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final res = await _examService.getScanResults(widget.packageId);
    if (!mounted) return;
    setState(() {
      _results = res.results;
      _summary = res.summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rekap Nilai Scan Kelas',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))))
          else ...[
            // Stat Cards
            if (_summary != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      'Rata-rata',
                      '${_summary!['average_score'] ?? 0}',
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryBox(
                      'Tertinggi',
                      '${_summary!['highest_score'] ?? 0}',
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryBox(
                      'Terendah',
                      '${_summary!['lowest_score'] ?? 0}',
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'Daftar Hasil Terkoreksi (${_results.length} Santri):',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada hasil scan yang disimpan.',
                        style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final r = _results[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.namaSiswa,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      'Benar: ${r.correctCount} • Salah: ${r.wrongCount} • Kosong/Ganda: ${r.blankCount + r.doubleCount}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  '${r.score}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: r.score >= 75 ? const Color(0xFF047857) : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
