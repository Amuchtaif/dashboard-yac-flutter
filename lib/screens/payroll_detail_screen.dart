import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
            _buildDownloadButton(),
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

  Widget _buildDownloadButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () {},
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
}
