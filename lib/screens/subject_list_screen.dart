import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teacher_service.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TeacherService _teacherService = TeacherService();
  String _selectedCategory = 'Semua';
  List<Map<String, dynamic>> _subjects = [];
  final List<String> _categories = [
    'Semua',
    'Akademik',
    'Diniah',
    'Bahasa',
    'Umum',
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final results = await _teacherService.getSubjectList(
        search: _searchController.text,
        category: _selectedCategory,
      );
      setState(() {
        _subjects = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat mata pelajaran: $e')),
        );
      }
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'purple':
        return const Color(0xFFA855F7);
      case 'green':
        return const Color(0xFF10B981);
      case 'orange':
      case 'amber':
        return const Color(0xFFF59E0B);
      case 'red':
        return const Color(0xFFEF4444);
      case 'indigo':
        return const Color(0xFF6366F1);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'calculate':
      case 'functions':
        return Icons.functions_rounded;
      case 'mosque':
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'translate':
      case 'language':
        return Icons.translate_rounded;
      case 'history_edu':
      case 'history':
        return Icons.history_edu_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'public':
        return Icons.public_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildCategoryFilters(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _subjects.isEmpty
                      ? Center(
                        child: Text(
                          'Data tidak ditemukan',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          return _buildSubjectCard(_subjects[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            'Mata Pelajaran',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Color(0xFF1E293B)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _fetchSubjects(),
          decoration: InputDecoration(
            hintText: 'Cari mata pelajaran...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategory = category);
                _fetchSubjects();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final color = _getColorFromName(subject['color'] ?? 'blue');
    final icon = _getIconFromName(subject['icon'] ?? 'book');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subject['name'] ?? '-',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subject['code'] ?? '-',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (subject['category']?.toString().toLowerCase() ==
                                      'religi'
                                  ? 'Diniah'
                                  : (subject['category'] ?? 'Umum'))
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ' •  ${subject['hours_per_week'] ?? '0 Jam/Minggu'}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[300],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
