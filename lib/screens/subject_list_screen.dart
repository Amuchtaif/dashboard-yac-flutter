import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  final List<Map<String, dynamic>> _allSubjects = [
    {
      'name': 'Matematika',
      'code': 'MTK-101',
      'category': 'Akademik',
      'hours': '5 Jam/Minggu',
      'icon': Icons.functions_rounded, // Sigma icon
      'color': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFEFF6FF),
    },
    {
      'name': 'Fiqh',
      'code': 'FQH-202',
      'category': 'Religi',
      'hours': '3 Jam/Minggu',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFA855F7),
      'bgColor': const Color(0xFFFAF5FF),
    },
    {
      'name': 'Bahasa Arab',
      'code': 'ARB-303',
      'category': 'Bahasa',
      'hours': '4 Jam/Minggu',
      'icon': Icons.translate_rounded,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFFECFDF5),
    },
    {
      'name': 'Sejarah',
      'code': 'SJR-404',
      'category': 'Akademik',
      'hours': '2 Jam/Minggu',
      'icon': Icons.history_edu_rounded,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFFFBEB),
    },
  ];

  List<Map<String, dynamic>> get _filteredSubjects {
    return _allSubjects.where((subject) {
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          subject['category'] == _selectedCategory;
      final matchesSearch = subject['name'].toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: _filteredSubjects.length,
                itemBuilder: (context, index) {
                  return _buildSubjectCard(_filteredSubjects[index]);
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
                  color: Colors.black.withOpacity(0.05),
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
                  color: Colors.black.withOpacity(0.05),
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
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
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
    final categories = ['Semua', 'Akademik', 'Religi', 'Bahasa'];
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = category),
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
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                color: subject['bgColor'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(subject['icon'], color: subject['color'], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        subject['code'],
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
                          color: subject['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subject['category'].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: subject['color'],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ' •  ${subject['hours']}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
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
