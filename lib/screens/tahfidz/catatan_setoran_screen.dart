import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tahfidz_repository.dart';
import '../../services/tahfidz_service.dart';
import '../../services/quran_service.dart';
import '../../models/surah_model.dart';
import '../../screens/login_screen.dart';
import './form_setoran_screen.dart';
import './detail_setoran_screen.dart';

class CatatanSetoranScreen extends StatefulWidget {
  const CatatanSetoranScreen({super.key});

  @override
  State<CatatanSetoranScreen> createState() => _CatatanSetoranScreenState();
}

class _CatatanSetoranScreenState extends State<CatatanSetoranScreen> {
  final TahfidzRepository _repository = TahfidzRepository();
  final TahfidzService _tahfidzService = TahfidzService();
  final QuranService _quranService = QuranService();

  DateTime _selectedDate = DateTime.now();
  List<dynamic> _students = [];
  List<dynamic> _entries = [];
  List<Surah> _surahList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? teacherId = prefs.getInt('userId');

      // Fetch teacher's students
      final studentsList = await _tahfidzService.getMyStudents(teacherId);

      // Fetch surahs if empty
      if (_surahList.isEmpty) {
        _surahList = await _quranService.getAllSurahs();
      }

      // Fetch entries for the selected date
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final entriesResult = await _repository.getEntries({
        'date': dateStr,
        'start_date': dateStr,
        'end_date': dateStr,
      });

      if (mounted) {
        if (entriesResult['success'] == true) {
          setState(() {
            _students = studentsList;
            _entries = entriesResult['data'] ?? [];
            _isLoading = false;
          });
        } else {
          if (entriesResult['message'] != null && entriesResult['message'].toString().contains('Unauthorized')) {
            _handleLogout();
          } else {
            setState(() {
              _errorMessage = entriesResult['message'] ?? 'Gagal memuat data setoran';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getSurahName(dynamic surahIdOrName) {
    if (surahIdOrName == null) return '-';
    final idString = surahIdOrName.toString();
    final id = int.tryParse(idString);
    if (id != null) {
      final surah = _surahList.firstWhere(
        (s) => s.nomor == id,
        orElse: () => Surah(nomor: id, nama: '', namaLatin: 'Surah $id', jumlahAyat: 0, tempatTurun: '', arti: '', deskripsi: '', audioFull: ''),
      );
      return surah.namaLatin;
    }
    return idString;
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(DateTime.now()) ? DateTime.now() : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D9488),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _fetchData();
  }

  void _nextDay() {
    if (!_isToday(_selectedDate)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter students by search query
    final filteredStudents = _students.where((student) {
      final name = (student['nama_siswa'] ?? student['full_name'] ?? student['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: Color(0xFF0D9488),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Catatan Setoran',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date Selector Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0D9488), size: 24),
                  onPressed: _previousDay,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF0D9488), size: 16),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: !_isToday(_selectedDate) ? const Color(0xFF0D9488) : Colors.grey[300],
                    size: 24,
                  ),
                  onPressed: !_isToday(_selectedDate) ? _nextDay : null,
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama santri...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0D9488),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // Content Area
          Expanded(
            child: _isLoading
                ? _buildLoadingSkeleton()
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: const Color(0xFF0D9488),
                    child: _errorMessage != null
                        ? _buildErrorState()
                        : filteredStudents.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = filteredStudents[index];
                                  final studentId = int.tryParse(student['id']?.toString() ?? '');
                                  final studentName = student['nama_siswa'] ?? student['full_name'] ?? student['name'] ?? 'Santri';
                                  final studentClass = student['kelas'] ?? student['nama_kelas'] ?? '-';

                                  // Find entries for this student
                                  final studentEntries = _entries.where(
                                    (e) => int.tryParse(e['student_id']?.toString() ?? '') == studentId,
                                  ).toList();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.015),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                      border: Border.all(color: const Color(0xFFF1F5F9)),
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        leading: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFFF0FDFA),
                                          child: Text(
                                            studentName.isNotEmpty ? studentName.substring(0, 1).toUpperCase() : 'S',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF0D9488),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          studentName,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Kelas $studentClass',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: studentEntries.isNotEmpty ? const Color(0xFFF0FDFA) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            studentEntries.isNotEmpty 
                                                ? '${studentEntries.length} Setoran' 
                                                : 'Belum Ada',
                                            style: GoogleFonts.poppins(
                                              fontSize: 9.5,
                                              color: studentEntries.isNotEmpty ? const Color(0xFF0F766E) : const Color(0xFFD97706),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        initiallyExpanded: studentEntries.isNotEmpty,
                                        children: [
                                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                                          const SizedBox(height: 12),
                                          if (studentEntries.isEmpty) ...[
                                            _buildQuickAddBox(studentId, studentName),
                                          ] else ...[
                                            ...studentEntries.map((e) {
                                              final int entryId = int.tryParse(e['id']?.toString() ?? '') ?? 0;
                                              final rawType = e['jenis_setoran'] ?? e['entry_type'] ?? '';
                                              
                                              String typeLabel = rawType;
                                              Color badgeBg = const Color(0xFFF1F5F9);
                                              Color badgeText = const Color(0xFF475569);
                                              Color leftBorderColor = const Color(0xFF94A3B8);
                                              
                                              if (rawType == 'HAFALAN_BARU' || rawType == 'Hafalan Baru') {
                                                typeLabel = 'Ziyadah';
                                                badgeBg = const Color(0xFFECFDF5);
                                                badgeText = const Color(0xFF059669);
                                                leftBorderColor = const Color(0xFF10B981);
                                              } else if (rawType == 'MUROJAAH' || rawType == 'Murojaah') {
                                                typeLabel = 'Murojaah';
                                                badgeBg = const Color(0xFFEEF2FF);
                                                badgeText = const Color(0xFF4F46E5);
                                                leftBorderColor = const Color(0xFF6366F1);
                                              }

                                              final surahStartRaw = e['surah_awal'] ?? e['surah_start'] ?? e['start_surah_id'] ?? '';
                                              final surahEndRaw = e['surah_akhir'] ?? e['surah_end'] ?? e['end_surah_id'] ?? '';
                                              final surahStart = _getSurahName(surahStartRaw);
                                              final surahEnd = _getSurahName(surahEndRaw);
                                              
                                              final ayatStart = e['ayat_awal'] ?? e['start_ayah'] ?? '';
                                              final ayatEnd = e['ayat_akhir'] ?? e['end_ayah'] ?? '';

                                              final String rangeText = surahStart == surahEnd 
                                                  ? '$surahStart: $ayatStart - $ayatEnd' 
                                                  : '$surahStart ($ayatStart) s/d $surahEnd ($ayatEnd)';

                                              final qualityText = e['status'] ?? e['quality'] ?? '-';

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border(
                                                    left: BorderSide(color: leftBorderColor, width: 4),
                                                  ),
                                                ),
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                                  title: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                                        decoration: BoxDecoration(
                                                          color: badgeBg,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          typeLabel,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 9,
                                                            color: badgeText,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      if (qualityText != '-') ...[
                                                        Text(
                                                          qualityText,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ]
                                                    ],
                                                  ),
                                                  subtitle: Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      rangeText,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12.5,
                                                        color: const Color(0xFF1E293B),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => DetailSetoranScreen(entryId: entryId)),
                                                    ).then((_) => _fetchData());
                                                  },
                                                ),
                                              );
                                            }),
                                            const SizedBox(height: 4),
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => FormSetoranScreen(initialStudentId: studentId),
                                                  ),
                                                ).then((_) => _fetchData());
                                              },
                                              icon: const Icon(Icons.add_rounded, size: 16),
                                              label: Text(
                                                'Tambah Setoran Lagi',
                                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(0xFF0D9488),
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 30),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FormSetoranScreen()),
            ).then((_) => _fetchData());
          },
          backgroundColor: const Color(0xFF0D9488),
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildQuickAddBox(int? studentId, String studentName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, color: const Color(0xFF94A3B8).withValues(alpha: 0.7), size: 28),
          const SizedBox(height: 8),
          Text(
            'Belum Ada Setoran Hari Ini',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormSetoranScreen(initialStudentId: studentId),
                ),
              ).then((_) => _fetchData());
            },
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: Text(
              'Input Setoran',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[100],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 12, width: 140, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(height: 8, width: 80, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_rounded, size: 48, color: Color(0xFF0D9488)),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'Santri tidak ditemukan' : 'Belum ada santri terdaftar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Coba gunakan kata kunci pencarian yang lain'
                  : 'Silakan hubungi administrator untuk verifikasi data halaqah',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
