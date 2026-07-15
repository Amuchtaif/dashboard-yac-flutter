import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailReportSemesterScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const DetailReportSemesterScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final bool isClosed = reportData['is_closed'] == 1 ||
        reportData['is_closed'] == '1' ||
        reportData['is_closed'] == true ||
        reportData['snapshot_id'] != null;

    final studentName = reportData['student_name'] ?? 'Santri';
    final percentage = double.tryParse(reportData['percentage_target']?.toString() ?? '0') ?? 0.0;
    final progress = reportData['progress_semester']?.toString() ?? '0';
    final target = reportData['target_semester']?.toString() ?? '0';
    final baseline = reportData['baseline_awal']?.toString() ?? '0';
    final totalHafalan = reportData['total_hafalan']?.toString() ?? '0';
    final totalMurojaah = reportData['total_murojaah']?.toString() ?? '0';
    final totalSetoran = reportData['total_setoran']?.toString() ?? '0';
    final nilaiTasmi = reportData['nilai_tasmi']?.toString() ?? '-';
    final hafalanBaru = reportData['hafalan_baru']?.toString() ?? '0';
    final notes = reportData['catatan'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Report Semester',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Closed Badge
            if (isClosed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Center(
                  child: Text(
                    'Semester Sudah Ditutup',
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],

            // Student Card Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.teal, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    studentName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress Target',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: target == '0' ? 0.0 : (percentage / 100.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                      minHeight: 6,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics fields card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _buildDetailItem('Baseline Awal', '$baseline Juz'),
                  const Divider(height: 24),
                  _buildDetailItem('Target Semester', '$target Halaman'),
                  const Divider(height: 24),
                  _buildDetailItem('Hafalan Baru', '$hafalanBaru Halaman'),
                  const Divider(height: 24),
                  _buildDetailItem('Total Hafalan', '$totalHafalan Juz'),
                  const Divider(height: 24),
                  _buildDetailItem('Progress', '$progress Halaman'),
                  const Divider(height: 24),
                  _buildDetailItem('Total Murojaah', '$totalMurojaah Halaman'),
                  const Divider(height: 24),
                  _buildDetailItem('Total Setoran', '$totalSetoran Kali'),
                  const Divider(height: 24),
                  _buildDetailItem('Nilai Tasmi\'', nilaiTasmi),
                  const Divider(height: 24),
                  _buildDetailItem('Catatan', notes.isEmpty ? '-' : notes, isMultiline: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isMultiline = false}) {
    if (isMultiline) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF374151),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
