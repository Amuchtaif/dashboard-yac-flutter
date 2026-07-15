import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/tahfidz_repository.dart';
import '../../services/tahfidz_service.dart';
import '../../screens/login_screen.dart';
import './form_setoran_screen.dart';
import './detail_setoran_screen.dart';

class DaftarSetoranScreen extends StatefulWidget {
  const DaftarSetoranScreen({super.key});

  @override
  State<DaftarSetoranScreen> createState() => _DaftarSetoranScreenState();
}

class _DaftarSetoranScreenState extends State<DaftarSetoranScreen> {
  final TahfidzRepository _repository = TahfidzRepository();
  final TahfidzService _tahfidzService = TahfidzService();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<dynamic> _entries = [];
  List<dynamic> _students = [];
  List<dynamic> _halaqahs = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  // Filters state
  String _searchQuery = '';
  String? _selectedTahunAjaran;
  String? _selectedSemester;
  int? _selectedHalaqahId;
  int? _selectedStudentId;
  String? _selectedJenisSetoran;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
    _fetchEntries(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && _errorMessage == null) {
        _fetchEntries();
      }
    }
  }

  Future<void> _fetchMetadata() async {
    try {
      final studentsList = await _tahfidzService.getStudents();
      final halaqahList = await _tahfidzService.getHalaqahGroups();
      if (mounted) {
        setState(() {
          _students = studentsList;
          _halaqahs = halaqahList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
    }
  }

  Future<void> _fetchEntries({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _entries.clear();
        _isLoading = true;
        _hasMore = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final filters = {
      'page': _currentPage,
      'search': _searchQuery,
      if (_selectedTahunAjaran != null) 'tahun_ajaran': _selectedTahunAjaran,
      if (_selectedSemester != null) 'semester': _selectedSemester,
      if (_selectedHalaqahId != null) 'halaqah_id': _selectedHalaqahId,
      if (_selectedStudentId != null) 'student_id': _selectedStudentId,
      if (_selectedJenisSetoran != null) 'jenis_setoran': _selectedJenisSetoran,
      if (_selectedDateRange != null) 'start_date': DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start),
      if (_selectedDateRange != null) 'end_date': DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end),
    };

    final result = await _repository.getEntries(filters);

    if (mounted) {
      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        setState(() {
          _entries.addAll(data);
          _currentPage++;
          _isLoading = false;
          _isLoadingMore = false;
          if (data.length < 15) {
            _hasMore = false;
          }
        });
      } else {
        if (result['message'] != null && result['message'].toString().contains('Unauthorized')) {
          _handleLogout();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Gagal memuat daftar setoran';
            _isLoading = false;
            _isLoadingMore = false;
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

  void _confirmDelete(int entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Setoran'),
        content: const Text('Apakah Anda yakin ingin menghapus setoran ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final result = await _repository.deleteEntry(entryId);
              if (mounted) {
                if (result['success'] == true) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Setoran berhasil dihapus'), backgroundColor: Colors.green),
                  );
                  _fetchEntries(refresh: true);
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Gagal menghapus setoran'), backgroundColor: Colors.red),
                  );
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Setoran',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedTahunAjaran = null;
                              _selectedSemester = null;
                              _selectedHalaqahId = null;
                              _selectedStudentId = null;
                              _selectedJenisSetoran = null;
                              _selectedDateRange = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tahun Ajaran
                    DropdownButtonFormField<String>(
                      value: _selectedTahunAjaran,
                      decoration: const InputDecoration(labelText: 'Tahun Ajaran', border: OutlineInputBorder()),
                      items: ['2023/2024', '2024/2025', '2025/2026'].map((tahun) {
                        return DropdownMenuItem(value: tahun, child: Text(tahun));
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedTahunAjaran = val),
                    ),
                    const SizedBox(height: 12),

                    // Semester
                    DropdownButtonFormField<String>(
                      value: _selectedSemester,
                      decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Ganjil (1)')),
                        DropdownMenuItem(value: '2', child: Text('Genap (2)')),
                      ],
                      onChanged: (val) => setModalState(() => _selectedSemester = val),
                    ),
                    const SizedBox(height: 12),

                    // Halaqah
                    DropdownButtonFormField<int>(
                      value: _selectedHalaqahId,
                      decoration: const InputDecoration(labelText: 'Halaqah', border: OutlineInputBorder()),
                      items: _halaqahs.map((h) {
                        return DropdownMenuItem<int>(
                          value: int.tryParse(h['id']?.toString() ?? ''),
                          child: Text(h['group_name'] ?? h['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedHalaqahId = val),
                    ),
                    const SizedBox(height: 12),

                    // Santri
                    DropdownButtonFormField<int>(
                      value: _selectedStudentId,
                      decoration: const InputDecoration(labelText: 'Santri', border: OutlineInputBorder()),
                      items: _students.map((student) {
                        return DropdownMenuItem<int>(
                          value: int.tryParse(student['id']?.toString() ?? ''),
                          child: Text(student['nama_siswa'] ?? student['full_name'] ?? student['name'] ?? '-'),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedStudentId = val),
                    ),
                    const SizedBox(height: 12),

                    // Jenis Setoran
                    DropdownButtonFormField<String>(
                      value: _selectedJenisSetoran,
                      decoration: const InputDecoration(labelText: 'Jenis Setoran', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Hafalan Baru', child: Text('Hafalan Baru')),
                        DropdownMenuItem(value: 'Murojaah', child: Text('Murojaah')),
                        DropdownMenuItem(value: 'Tasmi\'', child: Text('Tasmi\'')),
                        DropdownMenuItem(value: 'Ujian', child: Text('Ujian')),
                      ],
                      onChanged: (val) => setModalState(() => _selectedJenisSetoran = val),
                    ),
                    const SizedBox(height: 12),

                    // Date range picker trigger
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: _selectedDateRange,
                        );
                        if (picked != null) {
                          setModalState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDateRange == null
                                  ? 'Pilih Rentang Tanggal'
                                  : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                              style: TextStyle(color: _selectedDateRange == null ? Colors.grey.shade600 : Colors.black87),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Filter
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchEntries(refresh: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daftar Setoran',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.teal),
            onPressed: _showFilterSheet,
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama santri atau surat...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _fetchEntries(refresh: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _fetchEntries(refresh: true);
              },
            ),
          ),

          // Main List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchEntries(refresh: true),
              child: _isLoading
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
                                  onPressed: () => _fetchEntries(refresh: true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                  child: const Text('Coba Lagi'),
                                )
                              ],
                            ),
                          ),
                        )
                      : _entries.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada data setoran ditemukan',
                                style: GoogleFonts.poppins(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _entries.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _entries.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                final item = _entries[index];
                                final int id = int.tryParse(item['id']?.toString() ?? '') ?? 0;
                                final studentName = item['student_name'] ?? 'Santri';
                                final dateStr = item['tanggal'] ?? '';
                                final type = item['jenis_setoran'] ?? '';
                                final surahStart = item['surah_awal'] ?? '';
                                final surahEnd = item['surah_akhir'] ?? '';
                                final ayatStart = item['ayat_awal'] ?? '';
                                final ayatEnd = item['ayat_akhir'] ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.01),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => DetailSetoranScreen(entryId: id)),
                                      );
                                    },
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            studentName,
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            type,
                                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text(
                                          'Hafalan: $surahStart (Ayat $ayatStart) s/d $surahEnd (Ayat $ayatEnd)',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tanggal: $dateStr',
                                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => FormSetoranScreen(entry: item)),
                                            ).then((_) => _fetchEntries(refresh: true));
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _confirmDelete(id),
                                        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormSetoranScreen()),
          ).then((_) => _fetchEntries(refresh: true));
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
