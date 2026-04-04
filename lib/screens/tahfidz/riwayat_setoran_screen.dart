import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/tahfidz_service.dart';
import '../../providers/tahfidz_provider.dart';
import './setoran_tahfidz_screen.dart';

class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {
  final TahfidzService _service = TahfidzService();
  bool _isLoading = true;
  List<dynamic> _history = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<TahfidzProvider>(context, listen: false);
      final int? teacherId = provider.teacherId;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final data = await _service.getMemorizationHistory(
        teacherId: teacherId,
        date: dateStr,
      );

      if (mounted) {
        setState(() => _history = data);
      }
    } catch (e) {
      debugPrint("Error fetching memorization history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildDateHeader()),
          if (_history.isNotEmpty) SliverToBoxAdapter(child: _buildSummary()),
          _buildHistoryList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SetoranTahfidzScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Setoran',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Colors.blueAccent,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Riwayat Setoran',
        style: GoogleFonts.poppins(
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildDateHeader() {
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.blueAccent),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _fetchHistory();
                  }
                },
                child: Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildDateNavBtn(Icons.chevron_left, () {
                setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                _fetchHistory();
              }),
              const SizedBox(width: 8),
              _buildDateNavBtn(Icons.chevron_right, () {
                setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                _fetchHistory();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildSummary() {
    int lancar = _history.where((r) => r['quality'] == 'Lancar').length;
    int ulang = _history.where((r) => r['quality'] == 'Ulang').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          _buildStatDot('Total', _history.length.toString(), Colors.blueAccent),
          const SizedBox(width: 12),
          _buildStatDot('Lancar', lancar.toString(), const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _buildStatDot('Ulang', ulang.toString(), const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatDot(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$value $label',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }
    if (_history.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories_rounded, size: 64, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
              Text(
                'Tidak ada data Hafalan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ketuk ikon kalender untuk ganti tanggal',
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final record = _history[index];
            return _buildModernCard(record);
          },
          childCount: _history.length,
        ),
      ),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> record) {
    final studentName = record['student_name'] ?? '-';
    final surah = record['surah_name'] ?? '-';
    final ayatStart = record['ayat_start']?.toString() ?? '-';
    final ayatEnd = record['ayat_end']?.toString() ?? '-';
    final quality = record['quality'] ?? '-';
    final notes = record['notes'] ?? '';

    Color qualityColor;
    IconData qualityIcon;
    switch (quality) {
      case 'Lancar':
        qualityColor = const Color(0xFF10B981);
        qualityIcon = Icons.check_circle_rounded;
        break;
      case 'Kurang Lancar':
        qualityColor = const Color(0xFFF59E0B);
        qualityIcon = Icons.error_rounded;
        break;
      case 'Ulang':
        qualityColor = const Color(0xFFEF4444);
        qualityIcon = Icons.cancel_rounded;
        break;
      default:
        qualityColor = Colors.grey;
        qualityIcon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Student Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                  child: Text(
                    studentName.toString().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        record['student_class'] ??
                            record['kelas'] ??
                            record['tingkat'] ??
                            '-',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(qualityIcon, size: 14, color: qualityColor),
                      const SizedBox(width: 4),
                      Text(
                        quality,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: qualityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content - Hafalan Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      '$surah',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ayat $ayatStart - $ayatEnd',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.sticky_note_2_outlined, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          notes,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
