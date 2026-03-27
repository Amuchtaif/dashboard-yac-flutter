import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/meal_attendance_model.dart';
import '../../services/meal_attendance_service.dart';

class AbsensiMakanScreen extends StatefulWidget {
  const AbsensiMakanScreen({super.key});

  @override
  State<AbsensiMakanScreen> createState() => _AbsensiMakanScreenState();
}

class _AbsensiMakanScreenState extends State<AbsensiMakanScreen> {
  String _selectedMeal = 'Siang';
  DateTime _selectedDate = DateTime.now();
  List<MealStudent> _students = [];
  List<MealStudent> _filteredStudents = [];
  MealStats? _stats;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMeal = _getDefaultMealType();
    _fetchData();
  }

  String _getDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour <= 9) return 'Pagi';
    if (hour >= 11 && hour <= 14) return 'Siang';
    if (hour >= 17 && hour <= 20) return 'Malam';
    return 'Siang'; // Default
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final positionName = prefs.getString('positionName') ?? '';
      final isMusyrif = positionName.toLowerCase().contains('musyrif');

      final results = await Future.wait([
        isMusyrif && userId != null
            ? MealAttendanceService.getStudentsByMusyrif(
                musyrifId: userId,
                date: dateStr,
                mealType: _selectedMeal,
              )
            : MealAttendanceService.getStudents(
                date: dateStr,
                mealType: _selectedMeal,
              ),
        MealAttendanceService.getStats(
          date: dateStr,
          mealType: _selectedMeal,
          musyrifId: isMusyrif ? userId : null,
        ),
      ]);

      setState(() {
        _students = results[0] as List<MealStudent>;
        _stats = results[1] as MealStats?;
        _filterStudents(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((s) =>
                s.namaSiswa.toLowerCase().contains(query.toLowerCase()) ||
                s.nomorInduk.contains(query))
            .toList();
      }
    });
  }

  Future<void> _toggleMealStatus(MealStudent student) async {
    final success = student.attendanceId == null
        ? await MealAttendanceService.markAsEaten(
            studentId: student.id, mealType: _selectedMeal)
        : await MealAttendanceService.unmarkEaten(
            attendanceId: student.attendanceId!);

    if (success) {
      _fetchData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status makan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildMealTabs(),
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatsBanner(),
                      const SizedBox(height: 24),
                      _buildStudentList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Presensi Makan Santri',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _fetchData();
              }
            },
            icon: const Icon(Icons.calendar_today, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTabs() {
    final meals = [
      {'val': 'Pagi', 'label': 'Pagi'},
      {'val': 'Siang', 'label': 'Siang'},
      {'val': 'Malam', 'label': 'Sore'},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: meals.map((m) {
          bool isSelected = _selectedMeal == m['val'];
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _selectedMeal = m['val']!);
                _fetchData();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF97316) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    m['label']!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterStudents,
        decoration: InputDecoration(
          hintText: 'Cari Nama atau NIS...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isLoading && _stats == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SANTRI SUDAH MAKAN',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_stats?.totalServed ?? 0}',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BELUM MAKAN',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_stats?.totalQuota ?? 0) - (_stats?.totalServed ?? 0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoading && _students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.person_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data santri',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAFTAR SANTRI (${_filteredStudents.length})',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
            if (_filteredStudents.any((s) => s.attendanceId == null))
              TextButton.icon(
                onPressed: _handleBulkAction,
                icon: const Icon(Icons.done_all, size: 16),
                label: Text('Pilih Semua', style: GoogleFonts.poppins(fontSize: 12)),
              )
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredStudents.length,
          itemBuilder: (context, index) {
            return _buildStudentItem(_filteredStudents[index]);
          },
        ),
      ],
    );
  }

  Future<void> _handleBulkAction() async {
    final untreated = _filteredStudents.where((s) => s.attendanceId == null).toList();
    if (untreated.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Tandai ${untreated.length} santri sudah makan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Simpan')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final success = await MealAttendanceService.saveBulk(
        date: dateStr,
        mealType: _selectedMeal,
        studentIds: untreated.map((s) => s.id).toList(),
      );
      if (success) {
        _fetchData();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan data masal')),
          );
        }
      }
    }
  }

  Widget _buildStudentItem(MealStudent student) {
    bool isDone = student.attendanceId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFFF97316).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDone ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
            child: Icon(
              Icons.person,
              color: isDone ? const Color(0xFFF97316) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.namaSiswa,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDone ? const Color(0xFFF97316) : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${student.nomorInduk} • ${student.kelas}',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
                if (isDone)
                  Text(
                    'Pukul: ${student.checkTime ?? "-"}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFFF97316),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _toggleMealStatus(student),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFF97316),
              foregroundColor: isDone ? Colors.red : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isDone ? 'Batal' : 'Ambil Jatah',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
