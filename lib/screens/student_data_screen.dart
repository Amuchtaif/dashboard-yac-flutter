import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/student_service.dart';

class StudentDataScreen extends StatefulWidget {
  const StudentDataScreen({super.key});

  @override
  State<StudentDataScreen> createState() => _StudentDataScreenState();
}

class _StudentDataScreenState extends State<StudentDataScreen> {
  final StudentService _studentService = StudentService();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedUnit = 'Semua';
  String _selectedClass = 'Semua';
  List<String> _units = ['Semua'];
  List<String> _classes = ['Semua'];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    final data = await _studentService.getAllStudents();
    setState(() {
      _students = data;
      _isLoading = false;

      // Extract unique units and classes
      final units =
          data
              .map((e) => e['tingkat']?.toString() ?? 'Lainnya')
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();
      units.sort();
      _units = ['Semua', ...units];

      final classes =
          data
              .map((e) => e['kelas']?.toString() ?? 'Lainnya')
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();
      classes.sort();
      _classes = ['Semua', ...classes];

      _applyFilters();
      _updateClasses();
    });
  }

  void _updateClasses() {
    setState(() {
      final relevantStudents =
          _selectedUnit == 'Semua'
              ? _students
              : _students
                  .where(
                    (s) =>
                        (s['tingkat']?.toString() ?? 'Lainnya') ==
                        _selectedUnit,
                  )
                  .toList();

      final classes =
          relevantStudents
              .map((e) => e['kelas']?.toString() ?? 'Lainnya')
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();
      classes.sort();
      _classes = ['Semua', ...classes];

      // Reset selected class if it's no longer available in the new unit
      if (!_classes.contains(_selectedClass)) {
        _selectedClass = 'Semua';
      }
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents =
          _students.where((s) {
            final name = s['nama_siswa']?.toString().toLowerCase() ?? '';
            final nis = s['nis']?.toString().toLowerCase() ?? '';
            final unit = s['tingkat']?.toString() ?? 'Lainnya';
            final kelas = s['kelas']?.toString() ?? 'Lainnya';

            final matchesSearch = name.contains(query) || nis.contains(query);
            final matchesUnit =
                _selectedUnit == 'Semua' || unit == _selectedUnit;
            final matchesClass =
                _selectedClass == 'Semua' || kelas == _selectedClass;

            return matchesSearch && matchesUnit && matchesClass;
          }).toList();
    });
  }

  void _filterStudents(String query) {
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Data Siswa',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (!_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Unit / Tingkat',
                      value: _selectedUnit,
                      items: _units,
                      onChanged: (val) {
                        setState(() => _selectedUnit = val!);
                        _updateClasses();
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'Kelas',
                      value: _selectedClass,
                      items: _classes,
                      onChanged: (val) {
                        setState(() => _selectedClass = val!);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child:
                _isLoading
                    ? _buildLoadingState()
                    : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blue.shade400,
                size: 20,
              ),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onChanged: onChanged,
              items:
                  items.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterStudents,
          decoration: InputDecoration(
            hintText: 'Cari nama siswa...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Data siswa tidak ditemukan',
            style: GoogleFonts.poppins(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAvatar(student),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['nama_siswa'] ?? 'Unknown Name',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIS: ${student['nomor_induk'] ?? '-'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Kelas ${student['kelas'] ?? '-'}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.blue.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> student) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade100, width: 2),
        image:
            student['foto'] != null && student['foto'].toString().isNotEmpty
                ? DecorationImage(
                  image: NetworkImage(student['foto']),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          student['foto'] == null || student['foto'].toString().isEmpty
              ? Center(
                child: Text(
                  (student['nama_siswa'] ?? '?').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue.shade300,
                  ),
                ),
              )
              : null,
    );
  }
}
