import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PayrollDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payrollData;

  const PayrollDetailScreen({super.key, required this.payrollData});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final monthNames = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final periodName =
        "${monthNames[int.parse(payrollData['periode_bulan'].toString())]} ${payrollData['periode_tahun']}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF005AAA),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rincian Slip Gaji',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF005AAA)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildPeriodSection(periodName),
            const SizedBox(height: 24),
            _buildTotalSalaryCard(currencyFormat),
            const SizedBox(height: 32),
            _buildEarningsSection(currencyFormat),
            const SizedBox(height: 24),
            _buildDeductionsSection(currencyFormat),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildDebtBalanceSection(currencyFormat),
            const SizedBox(height: 32),
            _buildDownloadButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSection(String period) {
    return Column(
      children: [
        Text(
          'PERIODE PENGGAJIAN',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8EACCD),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          period,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSalaryCard(NumberFormat formatter) {
    final amount = double.tryParse(payrollData['gaji_netto'].toString()) ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Gaji Bersih',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(amount),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F9F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF27AE60),
                ),
                const SizedBox(width: 8),
                Text(
                  payrollData['status']?.toUpperCase() ?? 'BERHASIL DIBAYARKAN',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27AE60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection(NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PENERIMAAN',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.payments, color: Color(0xFF27AE60), size: 24),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Gaji Pokok',
            formatter.format(
              double.tryParse(payrollData['gapok'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'Tunjangan Jabatan',
            formatter.format(
              double.tryParse(payrollData['tunjab'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'Tunjangan Keluarga',
            formatter.format(
              double.tryParse(payrollData['tunkel'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'Tunjangan Anak',
            formatter.format(
              double.tryParse(payrollData['tunnak'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'KJM / Bonus',
            formatter.format(
              double.tryParse(payrollData['kjm'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'KJK',
            formatter.format(
              double.tryParse(payrollData['kjk'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'Tunjangan Khusus',
            formatter.format(
              double.tryParse(payrollData['tunkus'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'IKM',
            formatter.format(
              double.tryParse(payrollData['ikm'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'Lembur',
            formatter.format(
              double.tryParse(payrollData['lembur'].toString()) ?? 0,
            ),
          ),
          _buildDetailRow(
            'Tunjangan PPh21',
            formatter.format(
              double.tryParse(payrollData['tunj_pph21'].toString()) ?? 0,
            ),
          ),
          const SizedBox(height: 12),
          _buildTotalRow(
            'TOTAL PENERIMAAN',
            formatter.format(
              double.tryParse(payrollData['gaji_bruto'].toString()) ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsSection(NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POTONGAN',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.payments, color: Color(0xFFEB5757), size: 24),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Pajak PPh21',
            formatter.format(
              double.tryParse(payrollData['pph21'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'BPJS Kesehatan',
            formatter.format(
              double.tryParse(payrollData['bpjs_kes'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'BPJS Ketenagakerjaan',
            formatter.format(
              (double.tryParse(payrollData['bpjs_tk'].toString()) ?? 0) +
                  (double.tryParse(payrollData['jht_ip'].toString()) ?? 0),
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Infak',
            formatter.format(
              double.tryParse(payrollData['infak'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Donasi Radio',
            formatter.format(
              double.tryParse(payrollData['donasi_radio_ap'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Hutang Yayasan',
            formatter.format(
              double.tryParse(payrollData['hutang_yac'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Belanja',
            formatter.format(
              double.tryParse(payrollData['belanja'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Simp. Pokok',
            formatter.format(
              double.tryParse(payrollData['simp_pokok'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Simp. Wajib',
            formatter.format(
              double.tryParse(payrollData['simp_wajib'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Simp. Sukarela',
            formatter.format(
              double.tryParse(payrollData['simp_sukarela'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Qordul Hasan',
            formatter.format(
              double.tryParse(payrollData['hutang_kop'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Kredit Barang',
            formatter.format(
              double.tryParse(payrollData['kredit_brg'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Pend. Anak',
            formatter.format(
              double.tryParse(payrollData['pend_anak'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          _buildDetailRow(
            'Paket',
            formatter.format(
              double.tryParse(payrollData['paket'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
          const SizedBox(height: 12),
          _buildTotalRow(
            'TOTAL POTONGAN',
            formatter.format(
              double.tryParse(payrollData['jumlah_potongan'].toString()) ?? 0,
            ),
            isNegative: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String amount, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                isNegative ? '($amount)' : amount,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isNegative ? const Color(0xFFEB5757) : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade100, height: 1),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String amount, {
    bool isNegative = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isNegative ? const Color(0xFFEB5757) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMASI TAMBAHAN',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _buildSimpleInfoRow('Status Pegawai', payrollData['sta_peg']),
                _buildSimpleInfoRow('Masa Kerja', payrollData['masker']),
                _buildSimpleInfoRow('Golongan', payrollData['gol_r']),
                _buildSimpleInfoRow(
                  'Jumlah Kehadiran',
                  "${payrollData['jml_hari']} Hari",
                ),
                _buildSimpleInfoRow('Jabatan', payrollData['jabatan']),
                _buildSimpleInfoRow('Pendidikan', payrollData['pendidikan']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtBalanceSection(NumberFormat formatter) {
    // Check if any debt balances exist
    final hYayasan =
        double.tryParse(payrollData['saldo_hutang_yayasan'].toString()) ?? 0;
    final hMart =
        double.tryParse(payrollData['hut_assunnah_mart'].toString()) ?? 0;
    final hMurabahah =
        double.tryParse(payrollData['saldo_murabahah'].toString()) ?? 0;
    final hAnak =
        double.tryParse(payrollData['saldo_pendidikan_anak'].toString()) ?? 0;
    final hQordul =
        double.tryParse(payrollData['saldo_qordul_hasan'].toString()) ?? 0;

    if (hYayasan <= 0 &&
        hMart <= 0 &&
        hMurabahah <= 0 &&
        hAnak <= 0 &&
        hQordul <= 0) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KONFIRMASI SALDO HUTANG',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF546E7A),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (hYayasan > 0)
                  _buildSimpleInfoRow(
                    'Saldo Hutang Yayasan',
                    formatter.format(hYayasan),
                  ),
                if (hMart > 0)
                  _buildSimpleInfoRow(
                    'Hutang Assunnah Mart',
                    formatter.format(hMart),
                  ),
                if (hMurabahah > 0)
                  _buildSimpleInfoRow(
                    'Saldo Murabahah',
                    formatter.format(hMurabahah),
                  ),
                if (hAnak > 0)
                  _buildSimpleInfoRow(
                    'Saldo Pendidikan Anak',
                    formatter.format(hAnak),
                  ),
                if (hQordul > 0)
                  _buildSimpleInfoRow(
                    'Saldo Qordul Hasan',
                    formatter.format(hQordul),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoRow(String label, dynamic value) {
    if (value == null || value == "" || value == "null") {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () => _generatePdf(context),
        icon: const Icon(
          Icons.file_download_outlined,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Unduh Slip Gaji (PDF)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005AAA),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // Load logo
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

      // Load signature (Agung Junaedi)
      pw.MemoryImage? sigImage;
      try {
        final ByteData sigData = await rootBundle.load(
          'assets/images/signature_agung.png',
        );
        sigImage = pw.MemoryImage(sigData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Signature image not found: $e');
      }

      final currencyFormat = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      );

      String formatCurrency(dynamic value) {
        if (value == null || value == 0 || value == '0') return '0';
        return currencyFormat.format(double.tryParse(value.toString()) ?? 0);
      }

      final monthNames = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      final monthIndex =
          int.tryParse(payrollData['periode_bulan']?.toString() ?? '0') ?? 0;
      final periodMonth =
          monthIndex > 0 && monthIndex <= 12 ? monthNames[monthIndex] : '-';
      final periodYear = payrollData['periode_tahun'] ?? '-';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(25),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Column(
                children: [
                  // HEADER
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Image(logoImage, width: 60, height: 60),
                        pw.SizedBox(width: 20),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'YAYASAN ASSUNNAH CIREBON',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'BUKTI PERINCIAN GAJI GURU DAN KARYAWAN',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'BULAN - - $periodMonth $periodYear',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // EMPLOYEE INFO
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfFieldRow('Nama', payrollData['nama'] ?? '-'),
                              _pdfFieldRow(
                                'No. Induk',
                                payrollData['nik'] ?? '-',
                              ),
                              _pdfFieldRow(
                                'Tgl Lahir',
                                payrollData['tgl_lahir'] ?? '-',
                              ),
                              _pdfFieldRow(
                                'Jabatan',
                                payrollData['jabatan'] ?? '-',
                              ),
                              _pdfFieldRow(
                                'Martial',
                                payrollData['marital_status'] ?? '-',
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfFieldRow(
                                'Golongan/Esl',
                                payrollData['gol_r'] ?? '-',
                              ),
                              _pdfFieldRow(
                                'Masker',
                                payrollData['masker'] ?? '-',
                              ),
                              _pdfFieldRow(
                                'Stat. Pegawai',
                                payrollData['sta_peg'] ?? '-',
                              ),
                              _pdfFieldRow(
                                'Pendidikan',
                                payrollData['pendidikan'] ?? '-',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // A. GAJI POKOK
                  _pdfHeaderRow(
                    'A. Gaji Pokok',
                    formatCurrency(payrollData['gapok']),
                  ),

                  // B. TUNJANGAN
                  _pdfHeaderRow('B. Tunjangan', ''),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfItemValueRow(
                                'Jabatan',
                                formatCurrency(payrollData['tunjab']),
                              ),
                              _pdfItemValueRow(
                                'Keluarga',
                                formatCurrency(payrollData['tunkel']),
                              ),
                              _pdfItemValueRow(
                                'Anak',
                                formatCurrency(payrollData['tunnak']),
                              ),
                              _pdfItemValueRow(
                                'KJM',
                                formatCurrency(payrollData['kjm']),
                              ),
                              _pdfItemValueRow(
                                'KJK',
                                formatCurrency(payrollData['kjk']),
                              ),
                              _pdfItemValueRow(
                                'Tunj. PPh21',
                                formatCurrency(payrollData['tunj_pph21']),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfItemValueRow(
                                'Khusus',
                                formatCurrency(payrollData['tunkus']),
                              ),
                              _pdfItemValueRow(
                                'Kehadiran (${payrollData['jml_hari'] ?? 0})',
                                formatCurrency(payrollData['ikm']),
                              ),
                              _pdfItemValueRow(
                                'Lembur',
                                formatCurrency(payrollData['lembur']),
                              ),
                              _pdfItemValueRow('BPJS TK bg PT', '0'),
                              _pdfItemValueRow('BPJS Kesehatan', '0'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _pdfSubtotalRow(
                    'Jumlah Total Tunjangan',
                    formatCurrency(
                      (double.tryParse(payrollData['gaji_bruto'].toString()) ??
                              0) -
                          (double.tryParse(payrollData['gapok'].toString()) ??
                              0),
                    ),
                  ),

                  // GAJI BRUTO
                  _pdfBoldValueRow(
                    'Gaji Bruto ( A+B )',
                    formatCurrency(payrollData['gaji_bruto']),
                  ),

                  // C. POTONGAN
                  _pdfHeaderRow('C. Potongan', ''),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfItemValueRow(
                                'Hutang YAC',
                                formatCurrency(payrollData['hutang_yac']),
                              ),
                              _pdfItemValueRow(
                                'Pend. Anak',
                                formatCurrency(payrollData['pend_anak']),
                              ),
                              _pdfItemValueRow(
                                'Paket',
                                formatCurrency(payrollData['paket']),
                              ),
                              _pdfItemValueRow(
                                'Pajak (PPh 21)',
                                formatCurrency(payrollData['pph21']),
                              ),
                              _pdfItemValueRow(
                                'Infak',
                                formatCurrency(payrollData['infak']),
                              ),
                              _pdfItemValueRow(
                                'Don. Radio & AP',
                                formatCurrency(payrollData['donasi_radio_ap']),
                              ),
                              _pdfItemValueRow(
                                'BPJS TK',
                                formatCurrency(payrollData['bpjs_tk']),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfItemValueRow(
                                'BPJS Kesehatan',
                                formatCurrency(payrollData['bpjs_kes']),
                              ),
                              _pdfItemValueRow(
                                'Qordul Hasan',
                                formatCurrency(payrollData['hutang_kop']),
                              ),
                              _pdfItemValueRow(
                                'Simp. Wajib',
                                formatCurrency(payrollData['simp_wajib']),
                              ),
                              _pdfItemValueRow(
                                'Simp. Sukarela',
                                formatCurrency(payrollData['simp_sukarela']),
                              ),
                              _pdfItemValueRow(
                                'Simp. Pokok',
                                formatCurrency(payrollData['simp_pokok']),
                              ),
                              _pdfItemValueRow('Murabahah', '0'),
                              _pdfItemValueRow(
                                'Belanja',
                                formatCurrency(payrollData['belanja']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _pdfSubtotalRow(
                    'Jumlah Total Potongan',
                    formatCurrency(payrollData['jumlah_potongan']),
                  ),

                  // GAJI NETTO
                  _pdfBoldValueRow(
                    'Gaji Netto (A+B-C)',
                    formatCurrency(payrollData['gaji_netto']),
                  ),

                  // KONFIRMASI SALDO HUTANG
                  _pdfHeaderRowCenter('Konfirmasi Saldo Hutang'),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfItemValueRow(
                                'Yayasan',
                                formatCurrency(
                                  payrollData['saldo_hutang_yayasan'],
                                ),
                              ),
                              _pdfItemValueRow(
                                'Assunnah Mart',
                                formatCurrency(
                                  payrollData['hut_assunnah_mart'],
                                ),
                              ),
                              _pdfItemValueRow(
                                'Murabahah',
                                formatCurrency(payrollData['saldo_murabahah']),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              _pdfItemValueRow(
                                'Pendidikan Anak',
                                formatCurrency(
                                  payrollData['saldo_pendidikan_anak'],
                                ),
                              ),
                              _pdfItemValueRow(
                                'Qordul Hasan',
                                formatCurrency(
                                  payrollData['saldo_qordul_hasan'],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // NB
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                    child: pw.Text(
                      'NB:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  // FOOTER
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'Cirebon, ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Payroll,',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            if (sigImage != null)
                              pw.Container(
                                height: 35,
                                width: 100,

                                child: pw.Image(
                                  sigImage,
                                  fit: pw.BoxFit.contain,
                                ),
                              )
                            else
                              pw.SizedBox(height: 15),
                            pw.Text(
                              'Agung Junaedi',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Slip_Gaji_${payrollData['nama']}_${periodMonth}_${periodYear}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _pdfFieldRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Text(':', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfHeaderRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.symmetric(
          horizontal: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          if (value.isNotEmpty)
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfHeaderRowCenter(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.symmetric(
          horizontal: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  pw.Widget _pdfItemValueRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Text(':', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSubtotalRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfBoldValueRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border.symmetric(
          horizontal: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
