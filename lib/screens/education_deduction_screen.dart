import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationDeductionScreen extends StatefulWidget {
  final String nik;
  final String period;

  const EducationDeductionScreen({
    super.key,
    required this.nik,
    required this.period,
  });

  @override
  State<EducationDeductionScreen> createState() => _EducationDeductionScreenState();
}

class _EducationDeductionScreenState extends State<EducationDeductionScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _deductionData = [];
  double _totalBayar = 0;
  double _totalHutang = 0;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedInNik = prefs.getString('nik');
      final targetNik = (loggedInNik != null && loggedInNik.isNotEmpty) ? loggedInNik : widget.nik;

      final response = await http.get(Uri.parse(
          'https://script.google.com/macros/s/AKfycbxgoiBa2MH0F9bBzsObFeqYZt3CfUlyUxSC816nL1R5XVoCYXzPaG4aAM-15m3kPuc/exec'));

      if (response.statusCode == 200) {
        final List<dynamic> allData = json.decode(response.body);

        // Filter & Sort logic based on JS snippet
        final filtered = allData.where((item) {
          if (item['NO INDUK'] == null || item['NO INDUK'] == '-') return false;

          // Normalize values for comparison
          // Use 'NIK' as the primary key
          final rawItemNik = (item['NIK'] ?? item['nik'] ?? item['NIK_KARYAWAN'] ?? '').toString().trim();
          final itemBulan = item['Bulan Gaji']?.toString().trim().toLowerCase() ?? '';
          
          // Remove leading zeros and non-digits from NIK for comparison
          final itemNikClean = rawItemNik.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
          final targetNikClean = targetNik.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');

          final normalizedTargetPeriod = widget.period.trim().toLowerCase();

          // Filter by NIK (if provided in sheet)
          // If NIK is empty in target, we can't filter correctly, so we skip this check or return false
          if (targetNikClean.isEmpty) return false;
          if (itemNikClean != targetNikClean) return false;

          // Filter by Period (More flexible: check if target period is contained in or contains item period)
          if (itemBulan.isNotEmpty && !itemBulan.contains(normalizedTargetPeriod) && !normalizedTargetPeriod.contains(itemBulan)) {
            return false;
          }

          return true;
        }).toList();


        // Sort by Date (latest first)
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse((a['TANGGAL '] ?? a['TANGGAL'] ?? '').toString()) ?? DateTime(0);
          final dateB = DateTime.tryParse((b['TANGGAL '] ?? b['TANGGAL'] ?? '').toString()) ?? DateTime(0);
          return dateB.compareTo(dateA);
        });

        double bayar = 0;
        double hutang = 0;
        for (var item in filtered) {
          bayar += double.tryParse((item['TOTAL BAYAR'] ?? 0).toString()) ?? 0;
          hutang += double.tryParse((item['TOTAL HUTANG'] ?? 0).toString()) ?? 0;
        }

        if (mounted) {
          setState(() {
            _deductionData = filtered;
            _totalBayar = bayar;
            _totalHutang = hutang;
            _isLoading = false;
            // Tidak perlu set _errorMessage di sini agar masuk ke empty state
          });
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  String _formatDate(dynamic value) {
    if (value == null || value == '-') return '-';
    try {
      final date = DateTime.parse(value.toString());
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  String _formatMonthYear(dynamic value) {
    if (value == null || value == '-') return '-';
    try {
      final date = DateTime.parse(value.toString());
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Potongan Pendidikan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF005AAA)))
          : _errorMessage != null
              ? _buildErrorState()
              : _deductionData.isEmpty
                  ? _buildEmptyState()
                  : _buildDataList(),
      bottomNavigationBar: !_isLoading && _deductionData.isNotEmpty ? _buildSummaryBar() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005AAA)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bebas Potongan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda tidak mempunyai potongan pendidikan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deductionData.length,
      itemBuilder: (context, index) {
        final item = _deductionData[index];
        return _buildDeductionCard(item, index);
      },
    );
  }

  Widget _buildDeductionCard(Map<String, dynamic> item, int index) {
    final bool isExpanded = _expandedIndices.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedIndices.remove(index);
              } else {
                _expandedIndices.add(index);
              }
            });
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF16A34A),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['NAMA'] ?? '-',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kelas: ${item['KELAS'] ?? '-'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TANGGAL',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _formatDate(item['TANGGAL '] ?? item['TANGGAL']),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TOTAL BAYAR',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _formatCurrency(item['TOTAL BAYAR']),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'JMLH SPP',
                        _formatCurrency(item['JMLH SPP']),
                      ),
                      _buildDetailRow(
                        'Periode SPP',
                        '${_formatMonthYear(item['BULAN AWAL'])} - ${_formatMonthYear(item['BULAN AKHIR'])}',
                      ),
                      _buildDetailRow('PPDB', _formatCurrency(item['PPDB'])),
                      _buildDetailRow(
                        'Daftar Ulang',
                        _formatCurrency(item['DAFTAR ULANG']),
                      ),
                      _buildDetailRow(
                        'SPP Lama',
                        _formatCurrency(item['SPP LAMA']),
                      ),
                      _buildDetailRow(
                        'PPDB Lama',
                        _formatCurrency(item['PPDB LAMA']),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFFF1F5F9)),
                      ),
                      _buildDetailRow(
                        'TOTAL BAYAR',
                        _formatCurrency(item['TOTAL BAYAR']),
                        isBold: true,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'RINCIAN HUTANG',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Hut. PPDB',
                        _formatCurrency(item['HUT PPDB']),
                      ),
                      _buildDetailRow(
                        'Hut. Daftar Ulang',
                        _formatCurrency(item['HUT DAFTAR ULANG']),
                      ),
                      _buildDetailRow(
                        'Hut. SPP Lama',
                        _formatCurrency(item['HUT SPP LAMA']),
                      ),
                      _buildDetailRow(
                        'Hut. PPDB Lama',
                        _formatCurrency(item['HUT PPDB LAMA']),
                      ),
                      _buildDetailRow(
                        'TOTAL HUTANG',
                        _formatCurrency(item['TOTAL HUTANG']),
                        isBold: true,
                        color: const Color(0xFFEF4444),
                      ),
                      if (item['Download Nota'] != null &&
                          item['Download Nota'].toString().startsWith('http'))
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  () => _launchURL(
                                    item['Download Nota'].toString(),
                                  ),
                              icon: const Icon(
                                Icons.description_rounded,
                                size: 18,
                              ),
                              label: const Text('Unduh Nota Pembayaran'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005AAA),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isBold ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isBold ? Colors.black87 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Bayar', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                  Text(
                    _formatCurrency(_totalBayar),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF00796B)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Hutang', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                  Text(
                    _formatCurrency(_totalHutang),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    String finalUrl = url;
    
    // If it's a Google Drive link, we can try to use the viewer or direct download link
    if (url.contains('drive.google.com')) {
      // Transformation logic if needed, but let's try externalApplication first
    }

    final uri = Uri.parse(finalUrl);
    try {
      // Use externalApplication to force opening the browser or Drive app
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
        throw 'Gagal membuka aplikasi luar';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka nota: $e\nPastikan aplikasi browser atau Drive terpasang.'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Salin Link',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
              },
            ),
          ),
        );
      }
    }
  }
}
