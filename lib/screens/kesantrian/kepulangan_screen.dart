import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/perpulangan_model.dart';
import '../../services/perpulangan_service.dart';
import '../../services/asrama_service.dart';

class KepulanganScreen extends StatefulWidget {
  const KepulanganScreen({super.key});

  @override
  State<KepulanganScreen> createState() => _KepulanganScreenState();
}

class _KepulanganScreenState extends State<KepulanganScreen> {
  final PerpulanganService _service = PerpulanganService();
  final AsramaService _asramaService = AsramaService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<BoardingHoliday> _holidays = [];
  BoardingHoliday? _selectedHoliday;

  List<PerpulanganStudent> _allStudents = [];
  List<PerpulanganStudent> _filteredStudents = [];
  List<PerpulanganPermit> _activeLiburPermits = [];
  final Set<int> _selectedStudentIds = {};

  DateTime? _tanggalKeluar;
  DateTime? _tanggalKembali;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _listSearchController = TextEditingController();
  int? _supervisorId;

  // Primary Theme Color
  final Color primaryColor = const Color(0xFF0085FF);

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _supervisorId = prefs.getInt('userId');

      final asramas = await _asramaService.getDaftarAsrama();
      if (asramas.isNotEmpty) {
        final students = await _service.getStudents(
          roomId: asramas.first.id,
          supervisorId: _supervisorId,
        );
        _allStudents = students;
      }

      final activePermits = await _service.getActivePermits(
        supervisorId: _supervisorId,
      );
      _activeLiburPermits =
          activePermits
              .where((p) => p.category == 'Libur' && p.status != 'Kembali')
              .toList();

      _holidays = await _service.getHolidays();
      _selectedHoliday = null;

      // Removed mock data to ensure only dynamic data is used
      
      _filteredStudents = _allStudents;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error in _fetchInitialData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents =
            _allStudents
                .where(
                  (s) => s.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final sendableStudents =
          _filteredStudents.where((s) => !_isStudentOnLibur(s.id)).toList();
      if (_selectedStudentIds.length == sendableStudents.length) {
        _selectedStudentIds.clear();
      } else {
        _selectedStudentIds.addAll(sendableStudents.map((s) => s.id));
      }
    });
  }

  bool _isStudentOnLibur(int studentId) {
    return _activeLiburPermits.any((p) => p.studentId == studentId);
  }

  PerpulanganPermit? _getStudentActiveLibur(int studentId) {
    try {
      return _activeLiburPermits.firstWhere((p) => p.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body:
            _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: _buildHeader(context),
                      ),
                    ),
                    TabBar(
                      dividerColor: Colors.transparent,
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryColor,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Input Masa Libur'),
                        Tab(text: 'Monitoring Santri'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildInputTab(context),
                          _buildMonitoringTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildInputTab(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(
                'Gunakan tab ini untuk mengirim santri pulang dalam rangka libur resmi terjadwal.',
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Pilih Jadwal Libur'),
              const SizedBox(height: 12),
              _buildHolidayDropdown(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfoCard('MULAI LIBUR', _tanggalKeluar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateInfoCard('SELESAI LIBUR', _tanggalKembali),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('PILIH SANTRI'),
                  TextButton(
                    onPressed: _toggleSelectAll,
                    child: Text(
                      'Pilih Semua',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSantriSelectionList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
        _buildFloatingSubmitButton(),
        if (_isSubmitting) _buildSubmittingOverlay(),
      ],
    );
  }

  Widget _buildMonitoringTab(BuildContext context) {
    final filteredMonitor =
        _allStudents
            .where(
              (s) => s.name.toLowerCase().contains(
                _listSearchController.text.toLowerCase(),
              ),
            )
            .toList();

    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _listSearchController,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama santri...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredMonitor.length,
              itemBuilder: (listContext, index) {
                final student = filteredMonitor[index];
                final activePermit = _getStudentActiveLibur(student.id);
                final isOnLibur = activePermit != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            isOnLibur
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                        child: Icon(
                          isOnLibur
                              ? Icons.mode_night_rounded
                              : Icons.school_rounded,
                          color: isOnLibur ? Colors.orange : primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isOnLibur
                                  ? 'Status: Sedang Libur'
                                  : 'Status: Di Pondok',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isOnLibur ? Colors.orange : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOnLibur)
                        ElevatedButton(
                          onPressed: () => _confirmReturn(activePermit),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade700,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Kembali',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () {
                            // Find the TabController from the DefaultTabController
                            DefaultTabController.of(listContext).animateTo(0);
                            setState(() {
                              _selectedStudentIds.add(student.id);
                              _searchController.text = '';
                              _filterStudents('');
                            });
                          },
                          icon: Icon(
                            Icons.edit_note_rounded,
                            color: primaryColor,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          'Kepulangan Santri',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 42),
      ],
    );
  }


  Widget _buildHeaderCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHolidayDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BoardingHoliday>(
          value: _selectedHoliday,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_circle_outlined,
            color: primaryColor,
          ),
          hint: Text(
            '--PILIH DATA--',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          items:
              _holidays.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedHoliday = val;
                _tanggalKeluar = DateTime.parse(val.startDate);
                _tanggalKembali = DateTime.parse(val.endDate);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateInfoCard(String label, DateTime? date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 12,
                color: primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                date != null ? DateFormat('dd MMM yyyy').format(date) : '-',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSantriSelectionList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStudents,
              decoration: InputDecoration(
                hintText: 'Cari nama santri...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          _filteredStudents.isEmpty
              ? Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 48,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada data santri ditemukan',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pastikan Anda memiliki daftar asrama dan santri yang tervalidasi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade300,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  final isSelected = _selectedStudentIds.contains(student.id);
                  final isOnLibur = _isStudentOnLibur(student.id);

                  return ListTile(
                    onTap:
                        isOnLibur
                            ? null
                            : () {
                              setState(() {
                                if (isSelected) {
                                  _selectedStudentIds.remove(student.id);
                                } else {
                                  _selectedStudentIds.add(student.id);
                                }
                              });
                            },
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          isOnLibur
                              ? Colors.orange.shade50
                              : (isSelected
                                  ? primaryColor
                                  : Colors.grey.shade100),
                      child: Text(
                        student.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isOnLibur
                                      ? Colors.orange
                                      : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOnLibur ? Colors.grey : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      isOnLibur ? 'Sedang Libur' : student.className,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isOnLibur ? Colors.orange : Colors.grey,
                      ),
                    ),
                    trailing:
                        isOnLibur
                            ? const Icon(
                              Icons.lock_clock_outlined,
                              size: 20,
                              color: Colors.orange,
                            )
                            : Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_off_rounded,
                              color:
                                  isSelected
                                      ? primaryColor
                                      : Colors.grey.shade200,
                            ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildFloatingSubmitButton() {
    bool hasSelection = _selectedStudentIds.isNotEmpty;
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: hasSelection ? 1.0 : 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'PULANGKAN SANTRI (${_selectedStudentIds.length})',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittingOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 20),
                Text(
                  'Memproses Perizinan...',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReturn(PerpulanganPermit p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Konfirmasi Kembali',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Apakah santri ${p.studentName} sudah kembali ke pondok?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Ya, Sudah'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final res = await _service.updateStatus(p.id, 'Kembali');

        if (!mounted) return;

        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Santri berhasil dikonfirmasi kembali.'),
              backgroundColor: Colors.green,
            ),
          );
          // After success, reload data and clear selection
          _selectedStudentIds.remove(p.studentId);
          await _fetchInitialData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal update status'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error in _confirmReturn: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_tanggalKeluar == null || _tanggalKembali == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan jadwal libur terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String reason = _selectedHoliday?.name ?? 'Libur Resmi';
      String startStr = DateFormat('yyyy-MM-dd').format(_tanggalKeluar!);
      String endStr = DateFormat('yyyy-MM-dd').format(_tanggalKembali!);

      int successCount = 0;
      for (int id in _selectedStudentIds) {
        final res = await _service.submitPermit(
          studentId: id,
          category: 'Libur',
          reason: reason,
          startDate: startStr,
          endDate: endStr,
          musrifId: _supervisorId,
        );
        if (res['success'] == true) successCount++;
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedStudentIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount santri berhasil dipulangkan'),
            backgroundColor: primaryColor,
          ),
        );
        _fetchInitialData();
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
