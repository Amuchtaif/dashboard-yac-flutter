import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/exam_model.dart';
import '../../services/exam_service.dart';
import 'exam_package_detail_screen.dart';

class ExamPackageListScreen extends StatefulWidget {
  const ExamPackageListScreen({super.key});

  @override
  State<ExamPackageListScreen> createState() => _ExamPackageListScreenState();
}

class _ExamPackageListScreenState extends State<ExamPackageListScreen> {
  final ExamService _examService = ExamService();
  final TextEditingController _searchController = TextEditingController();

  int _userId = 0;
  bool _isLoading = true;
  String _selectedFilter = 'Semua'; // 'Semua', 'Siap Scan', 'Draft'

  List<ExamPackageModel> _allPackages = [];
  List<ExamPackageModel> _filteredPackages = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfoAndPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfoAndPackages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final rawId = prefs.get('user_id') ?? prefs.get('userId') ?? prefs.get('id');
    _userId = rawId != null ? int.tryParse(rawId.toString()) ?? 0 : 0;

    await _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    final list = await _examService.getPackages(userId: _userId);

    if (!mounted) return;
    setState(() {
      _allPackages = list;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredPackages = _allPackages.where((pkg) {
        // Filter Status
        if (_selectedFilter == 'Siap Scan' && !pkg.isPublished) return false;
        if (_selectedFilter == 'Draft' && !pkg.isDraft) return false;

        // Filter Search
        if (query.isNotEmpty) {
          final titleMatch = pkg.title.toLowerCase().contains(query);
          final subjectMatch = pkg.subjectName.toLowerCase().contains(query);
          final gradeMatch = pkg.gradeName.toLowerCase().contains(query);
          return titleMatch || subjectMatch || gradeMatch;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              'Koreksi LJK (OMR)',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              'Pemeriksaan lembar jawaban santri',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPackages,
        color: const Color(0xFF2563EB),
        child: Column(
          children: [
            // Header Search & Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilter(),
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari paket ujian, mapel, atau kelas...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilter();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Siap Scan'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Draft'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Package List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : _filteredPackages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPackages.length,
                          itemBuilder: (context, index) {
                            return _buildPackageCard(_filteredPackages[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilter();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(ExamPackageModel pkg) {
    final statusColor = pkg.isPublished
        ? const Color(0xFF10B981) // Green
        : pkg.isDraft
            ? const Color(0xFFF59E0B) // Amber
            : const Color(0xFF64748B); // Slate

    final statusBgColor = statusColor.withValues(alpha: 0.1);
    final statusText = pkg.isPublished
        ? 'Siap Scan'
        : pkg.isDraft
            ? 'Draft'
            : 'Ditutup';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExamPackageDetailScreen(package: pkg),
              ),
            );
            _fetchPackages();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Mapel & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${pkg.subjectName} • Kelas ${pkg.gradeName}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  pkg.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle / Assessment type
                Text(
                  '${pkg.assessmentTypeName} • ${pkg.unitName}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                // Metadata Badges (Jumlah Soal, Opsi, Tgl)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildMetaChip(Icons.format_list_numbered, '${pkg.totalQuestions} Soal'),
                    _buildMetaChip(Icons.radio_button_checked, '${pkg.optionCount} Opsi (${pkg.optionLabels.join("-")})'),
                    if (pkg.examDate != null && pkg.examDate!.isNotEmpty)
                      _buildMetaChip(Icons.calendar_today_rounded, pkg.examDate!),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar Koreksi Santri
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progres Scan Santri:',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${pkg.scannedCount} / ${pkg.classStudentCount} Santri',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: pkg.scannedCount == pkg.classStudentCount && pkg.classStudentCount > 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pkg.scanProgress,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: pkg.scanProgress >= 1.0
                            ? const Color(0xFF10B981)
                            : const Color(0xFF2563EB),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Paket Ujian',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFilter != 'Semua'
                  ? 'Tidak ada paket dengan filter "$_selectedFilter". Coba ganti filter atau cari kata kunci lain.'
                  : 'Paket ujian pilihan ganda yang Anda buat di web Dashboard akan muncul di sini untuk dikoreksi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
