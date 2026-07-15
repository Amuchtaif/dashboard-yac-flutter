import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/tahfidz_repository.dart';
import '../../screens/login_screen.dart';
import './form_setoran_screen.dart';

class DetailSetoranScreen extends StatefulWidget {
  final int entryId;

  const DetailSetoranScreen({super.key, required this.entryId});

  @override
  State<DetailSetoranScreen> createState() => _DetailSetoranScreenState();
}

class _DetailSetoranScreenState extends State<DetailSetoranScreen> {
  final TahfidzRepository _repository = TahfidzRepository();
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;
  Map<String, dynamic> _entry = {};

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getEntry(widget.entryId);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _entry = result['data'] ?? {};
          _isLoading = false;
        });
      } else {
        if (result['message'] != null && result['message'].toString().contains('Unauthorized')) {
          _handleLogout();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Gagal memuat detail setoran';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Setoran'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan setoran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final result = await _repository.deleteEntry(widget.entryId);

    if (mounted) {
      setState(() => _isDeleting = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan setoran berhasil dihapus.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menghapus setoran.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatJenisSetoran(String raw) {
    switch (raw.toUpperCase()) {
      case 'HAFALAN_BARU':
      case 'HAFALAN BARU':
        return 'Hafalan Baru';
      case 'MUROJAAH':
        return 'Murojaah';
      case 'TASMI':
        return 'Tasmi\'';
      case 'UJIAN':
        return 'Ujian';
      default:
        return raw;
    }
  }

  Color _getJenisSetoranColor(String raw) {
    switch (raw.toUpperCase()) {
      case 'HAFALAN_BARU':
      case 'HAFALAN BARU':
        return const Color(0xFF3B82F6); // Blue
      case 'MUROJAAH':
        return const Color(0xFF8B5CF6); // Purple
      case 'TASMI':
        return const Color(0xFF10B981); // Emerald Green
      case 'UJIAN':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  Color _getKelancaranColor(String value) {
    switch (value.toLowerCase()) {
      case 'lancar':
      case 'ziyadah':
      case 'murajaah':
        return const Color(0xFF10B981); // Emerald Green
      case 'kurang':
      case 'kurang lancar':
        return const Color(0xFFF59E0B); // Amber
      case 'tidak':
      case 'ulang':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getKelancaranIcon(String value) {
    switch (value.toLowerCase()) {
      case 'lancar':
      case 'ziyadah':
      case 'murajaah':
        return Icons.check_circle_rounded;
      case 'kurang':
      case 'kurang lancar':
        return Icons.error_rounded;
      case 'tidak':
      case 'ulang':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildHeaderCard(String studentName, String jenisSetoran) {
    final typeName = _formatJenisSetoran(jenisSetoran);
    final typeColor = _getJenisSetoranColor(jenisSetoran);
    final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor.withValues(alpha: 0.8),
                  typeColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            studentName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: typeColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              typeName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeCard(String surahAwal, String ayatAwal, String surahAkhir, String ayatAkhir) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batas Hafalan',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Start Surah
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai Dari',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      surahAwal,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ayat $ayatAwal',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider arrow visual
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // End Surah
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sampai Dengan',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      surahAkhir,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ayat $ayatAkhir',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String jumlahBaris, String nilai) {
    final scoreColor = _getKelancaranColor(nilai);
    final scoreIcon = _getKelancaranIcon(nilai);

    return Row(
      children: [
        // Jumlah Baris Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.linear_scale_rounded,
                        color: Color(0xFF3B82F6),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jumlah Baris',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$jumlahBaris Baris',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Kelancaran Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        scoreIcon,
                        color: scoreColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kelancaran',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nilai,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralCard(String tanggal, String catatan) {
    String formattedDate = tanggal;
    try {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(tanggal);
      formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(parsedDate);
    } catch (_) {}

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal Setoran',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 20),

          // Catatan Section
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Catatan Tambahan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Text(
              catatan.isNotEmpty && catatan != '-' ? catatan : 'Tidak ada catatan tambahan.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: catatan.isNotEmpty && catatan != '-' ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                fontStyle: catatan.isNotEmpty && catatan != '-' ? FontStyle.normal : FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = _entry['student_name'] ?? 'Nama Santri';
    final jenisSetoran = _entry['jenis_setoran'] ?? _entry['entry_type'] ?? '-';
    final tanggal = _entry['tanggal'] ?? _entry['date'] ?? '-';
    final surahAwal = _entry['surah_awal'] ?? _entry['surah_start'] ?? '-';
    final ayatAwal = _entry['ayat_awal']?.toString() ?? _entry['start_ayah']?.toString() ?? '-';
    final surahAkhir = _entry['surah_akhir'] ?? _entry['surah_end'] ?? '-';
    final ayatAkhir = _entry['ayat_akhir']?.toString() ?? _entry['end_ayah']?.toString() ?? '-';
    final jumlahBaris = _entry['jumlah_baris']?.toString() ?? _entry['line_count']?.toString() ?? '0';
    final nilai = _entry['status'] ?? _entry['quality'] ?? _entry['nilai'] ?? _entry['score']?.toString() ?? '-';
    final catatan = _entry['catatan'] ?? _entry['notes'] ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Detail Setoran',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: _isLoading || _errorMessage != null
            ? null
            : [
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F0FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormSetoranScreen(entry: _entry),
                        ),
                      ).then((value) {
                        if (value == true) {
                          _fetchDetail();
                        }
                      });
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: _isDeleting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 20),
                    onPressed: _isDeleting ? null : _deleteEntry,
                  ),
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDetail,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          child: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Header Card (Profile Section)
                      _buildHeaderCard(studentName, jenisSetoran),
                      const SizedBox(height: 20),

                      // Setoran Range Card (Visual progress timeline)
                      _buildRangeCard(surahAwal, ayatAwal, surahAkhir, ayatAkhir),
                      const SizedBox(height: 16),

                      // Side-by-Side Quick Stats Cards
                      _buildStatsRow(jumlahBaris, nilai),
                      const SizedBox(height: 16),

                      // General Details Card
                      _buildGeneralCard(tanggal, catatan),
                    ],
                  ),
                ),
    );
  }
}
