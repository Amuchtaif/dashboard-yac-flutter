import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payroll_detail_screen.dart';
import '../services/payroll_service.dart';
import 'package:intl/intl.dart';

class PayrollHistoryScreen extends StatefulWidget {
  const PayrollHistoryScreen({super.key});

  @override
  State<PayrollHistoryScreen> createState() => _PayrollHistoryScreenState();
}

class _PayrollHistoryScreenState extends State<PayrollHistoryScreen> {
  final PayrollService _payrollService = PayrollService();
  List<Map<String, dynamic>> _payrolls = [];
  bool _isLoading = true;
  String? _userId;
  double _totalPaidYear = 0;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final rawId = prefs.get('user_id') ?? prefs.get('userId');
      if (rawId is int) {
        _userId = rawId.toString();
      } else {
        _userId = rawId?.toString();
      }
    });

    if (_userId != null && _userId != "0" && _userId != "null") {
      _fetchPayrolls();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPayrolls() async {
    if (_userId == null || _userId == "0" || _userId == "null") {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final rawResults = await _payrollService.getPayrollHistory(
        userId: int.parse(_userId!),
        tahun: _selectedYear.toString(),
        limit: 50,
      );

      // Filter lokal untuk memastikan data sesuai dengan tahun yang dipilih
      // Kita mengizinkan data jika tahunnya cocok, ATAU jika tahunnya bukan format Masehi
      // (misalnya tahun Hijriah 1447 untuk THR) atau jika data tahunnya kosong.
      final results =
          rawResults.where((p) {
            final yearStr = p['periode_tahun']?.toString() ?? '';
            final yearInt = int.tryParse(yearStr);

            // Jika periode_tahun adalah tahun Masehi (> 2000), filter ketat
            if (yearInt != null && yearInt > 2000) {
              return yearInt == _selectedYear;
            }

            // Jika bukan tahun Masehi (misal 1447) atau null/kosong, tampilkan saja
            return true;
          }).toList();

      double total = 0;
      for (var p in results) {
        final net = p['gaji_netto'];
        double netValue = 0;
        if (net is num) {
          netValue = net.toDouble();
        } else if (net is String) {
          netValue = double.tryParse(net) ?? 0;
        }
        total += netValue;
      }

      if (mounted) {
        setState(() {
          _payrolls = results;
          _totalPaidYear = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat data gaji: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: _fetchPayrolls,
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        _buildTitleSection(),
                        const SizedBox(height: 20),
                        _buildYearFilter(),
                        const SizedBox(height: 20),
                        _buildSummaryCard(),
                        const SizedBox(height: 24),
                        _payrolls.isEmpty
                            ? _buildEmptyState()
                            : Column(
                              children:
                                  _payrolls
                                      .map(
                                        (payroll) => _buildPayrollCard(payroll),
                                      )
                                      .toList(),
                            ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "Belum ada data penggajian",
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ),

        // Title
        Text(
          'Riwayat Penggajian',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        // Placeholder untuk keseimbangan layout
        const SizedBox(width: 42),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Gaji',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lihat rincian pendapatan bulanan Anda',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildYearFilter() {
    final currentYear = DateTime.now().year;
    final years = [currentYear, currentYear - 1];

    return Row(
      children:
          years.map((year) {
            bool isSelected = _selectedYear == year;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(
                  year == currentYear
                      ? "Tahun Ini ($year)"
                      : "Tahun Lalu ($year)",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF0085FF),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        isSelected ? Colors.transparent : Colors.grey.shade200,
                  ),
                ),
                showCheckmark: false,
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      _selectedYear = year;
                    });
                    _fetchPayrolls();
                  }
                },
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL TERBAYAR $_selectedYear',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.grey.shade500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(_totalPaidYear),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0085FF),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 8),
                child: Text(
                  '/ ${_payrolls.length} Bulan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(Map<String, dynamic> data) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final periodStr =
        "${data['nama_bulan']} ${data['periode_tahun']}";
    final amount = double.tryParse(data['gaji_netto'].toString()) ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayrollDetailScreen(payrollData: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            // Header Card (Periode & Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      periodStr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['status'] ?? 'TERBAYAR',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inner Blue Box (Gaji Bersih)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FF), // Very light blue background
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GAJI BERSIH',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            currencyFormat.format(amount),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0085FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.blue.shade300,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
