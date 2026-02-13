import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/tahfidz_service.dart';
import '../../providers/tahfidz_provider.dart';

class AbsensiTahfidzScreen extends StatefulWidget {
  const AbsensiTahfidzScreen({super.key});

  @override
  State<AbsensiTahfidzScreen> createState() => _AbsensiTahfidzScreenState();
}

class _AbsensiTahfidzScreenState extends State<AbsensiTahfidzScreen> {
  final TahfidzService _service = TahfidzService();

  DateTime _selectedDate = DateTime.now();
  String _selectedSession = 'Pagi';
  List<dynamic> _students = [];
  final Map<int, String> _attendanceStatus = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _teacherId;

  // Halaqoh Opening State
  bool _isHalaqohOpened = false;
  bool _hasCheckedOut = false;
  String? _selectedJadwal;
  final List<String> _jadwalOptions = ['Pagi', 'Siang', 'Sore'];
  Timer? _timer;
  String _currentTime = "";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('userId');
    String? name = prefs.getString('fullName');
    setState(() => _teacherId = id);

    if (_teacherId != null) {
      if (!mounted) return;
      Provider.of<TahfidzProvider>(
        context,
        listen: false,
      ).setTeacherInfo(id, name);
      await _checkHalaqohStatus();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkHalaqohStatus() async {
    setState(() => _isLoading = true);
    try {
      final history = await _service.getTeacherAttendanceHistory(
        teacherId: _teacherId,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      if (history.isNotEmpty) {
        // Mencari apakah ada sesi yang masih aktif (belum check-out)
        final activeSession = history.firstWhere(
          (h) => h['check_out_time'] == null || h['check_out_time'] == "",
          orElse: () => null,
        );

        if (activeSession != null) {
          setState(() {
            _isHalaqohOpened = true;
            _hasCheckedOut = false;
            // Set sesi berdasarkan catatan check-in
            if (activeSession['notes'] != null &&
                activeSession['notes'] != "") {
              _selectedSession = activeSession['notes'];
            }
          });
          await _fetchStudents();
        } else {
          // Semua sesi sudah ditutup, kembali ke layar Buka Halaqoh
          setState(() {
            _isHalaqohOpened = false;
            _hasCheckedOut = false;
          });
        }
      } else {
        // History kosong, pastikan layar Buka Halaqoh muncul
        setState(() {
          _isHalaqohOpened = false;
          _hasCheckedOut = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking halaqoh status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengecek status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBukaHalaqoh() async {
    if (_teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Pengampu tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }
    if (_selectedJadwal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih jadwal halaqoh terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _service.submitTeacherAttendance(
      teacherId: _teacherId!,
      action: 'check_in',
      notes: _selectedJadwal,
      time: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      setState(() {
        _isHalaqohOpened = true;
        _selectedSession = _selectedJadwal!;
      });
      _fetchStudents();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleTutupHalaqoh() async {
    if (_teacherId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Tutup Halaqoh?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Apakah Anda yakin ingin menutup halaqoh hari ini?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Tutup Halaqoh',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    final result = await _service.submitTeacherAttendance(
      teacherId: _teacherId!,
      action: 'check_out',
      notes:
          _selectedSession, // Kirimkan informasi sesi agar backend tidak salah tutup
      time: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (!mounted) return;
      setState(() {
        _isHalaqohOpened = false;
        _hasCheckedOut =
            true; // Langsung tampilkan layar "Selesai" setelah tutup
        _students = [];
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menutup halaqoh: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<TahfidzProvider>(context, listen: false);
      await provider.fetchMyStudents(_teacherId);

      setState(() {
        _students = provider.myStudents;
        for (var s in _students) {
          int id = int.tryParse(s['id'].toString()) ?? 0;
          if (id != 0) {
            _attendanceStatus[id] = 'Hadir';
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAttendance() async {
    if (_teacherId == null) return;

    setState(() => _isSubmitting = true);

    List<Map<String, dynamic>> attendanceList = [];
    _attendanceStatus.forEach((studentId, status) {
      attendanceList.add({"student_id": studentId, "status": status});
    });

    final result = await _service.submitStudentAttendance(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      session: _selectedSession,
      teacherId: _teacherId,
      students: attendanceList,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absensi berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _isHalaqohOpened ? 'Absensi Santri' : 'Buka Halaqoh',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isHalaqohOpened) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchStudents,
              tooltip: 'Muat Ulang Santri',
            ),
          ],
        ],
      ),
      body:
          _hasCheckedOut
              ? _buildClosedView()
              : !_isHalaqohOpened
              ? _buildOpeningView()
              : Column(
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  _buildStatsSection(),
                  Expanded(child: _buildStudentList()),
                  _buildBottomBar(),
                ],
              ),
    );
  }

  Widget _buildOpeningView() {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              _currentTime.isEmpty ? "--:--" : _currentTime,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pilih Jadwal Halaqoh:",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children:
                  _jadwalOptions.map((jadwal) {
                    bool isSelected = _selectedJadwal == jadwal;
                    IconData icon;
                    switch (jadwal) {
                      case 'Pagi':
                        icon = Icons.wb_sunny_rounded;
                        break;
                      case 'Siang':
                        icon = Icons.light_mode_rounded;
                        break;
                      case 'Sore':
                        icon = Icons.wb_twilight_rounded;
                        break;
                      default:
                        icon = Icons.access_time_rounded;
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedJadwal = jadwal),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.indigo : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.indigo
                                      : Colors.grey[200]!,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Colors.indigo.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.indigo[400],
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                jadwal,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleBukaHalaqoh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Buka Halaqoh',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Halaqoh Selesai",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Anda telah menutup halaqoh untuk hari ini.\nTerima kasih atas dedikasinya!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Kembali ke Dashboard",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Date column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TANGGAL',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                        }
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Session column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HALAQOH',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSession,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items:
                              ['Pagi', 'Siang', 'Sore'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedSession = newValue!;
                            });
                          },
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged:
            (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Cari nama santri...",
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.blueAccent.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    int total = _students.length;
    int hadir = _attendanceStatus.values.where((s) => s == 'Hadir').length;
    int sakit = _attendanceStatus.values.where((s) => s == 'Sakit').length;
    int izin = _attendanceStatus.values.where((s) => s == 'Izin').length;
    int alpha = _attendanceStatus.values.where((s) => s == 'Alpha').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip("Total: $total", Colors.black),
            _buildStatChip(
              "Hadir: $hadir",
              const Color(0xFF10B981),
            ), // Success Green
            _buildStatChip(
              "Sakit: $sakit",
              const Color(0xFFF59E0B),
            ), // Warning Orange
            _buildStatChip("Izin: $izin", const Color(0xFF2563EB)), // Info Blue
            _buildStatChip(
              "Alpha: $alpha",
              const Color(0xFFEF4444),
            ), // Danger Red
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final filteredStudents =
        _students.where((s) {
          final name =
              (s['nama_siswa'] ??
                      s['nama_santri'] ??
                      s['nama_lengkap'] ??
                      s['full_name'] ??
                      s['name'] ??
                      '')
                  .toString()
                  .toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

    if (filteredStudents.isEmpty) {
      bool isSearchEmpty = _searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchEmpty
                  ? Icons.person_off_outlined
                  : Icons.group_off_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isSearchEmpty
                  ? "Santri tidak ditemukan"
                  : "Anda belum memiliki daftar santri binaan.",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final id = int.tryParse(student['id'].toString()) ?? 0;
        return _buildStudentCard(student, id);
      },
    );
  }

  Widget _buildStudentCard(dynamic student, int id) {
    String currentStatus = _attendanceStatus[id] ?? 'Hadir';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0E7FF),
                  child: Text(
                    (student['nama_siswa'] ??
                            student['nama_santri'] ??
                            student['nama_lengkap'] ??
                            student['full_name'] ??
                            student['name'] ??
                            '?')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4338CA),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['nama_siswa'] ??
                            student['nama_santri'] ??
                            student['nama_lengkap'] ??
                            student['full_name'] ??
                            student['name'] ??
                            'No Name',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Kelas: ${student['kelas'] ?? student['nama_kelas'] ?? student['tingkat'] ?? student['unit_name'] ?? student['rombel'] ?? '-'}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIndicator(currentStatus),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Row(
              children: [
                _buildAttendanceButton(
                  id,
                  'HADIR',
                  const Color(0xFF10B981),
                  currentStatus,
                  isFirst: true,
                ),
                _buildAttendanceButton(
                  id,
                  'SAKIT',
                  const Color(0xFFF59E0B),
                  currentStatus,
                ),
                _buildAttendanceButton(
                  id,
                  'IZIN',
                  const Color(0xFF2563EB),
                  currentStatus,
                ),
                _buildAttendanceButton(
                  id,
                  'ALPHA',
                  const Color(0xFFEF4444),
                  currentStatus,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return const Color(0xFF10B981);
      case 'SAKIT':
        return const Color(0xFFF59E0B);
      case 'IZIN':
        return const Color(0xFF2563EB);
      case 'ALPHA':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  Widget _buildStatusIndicator(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(
    int id,
    String label,
    Color color,
    String currentStatus, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    bool isSelected = currentStatus.toUpperCase() == label;
    int index = ['HADIR', 'SAKIT', 'IZIN', 'ALPHA'].indexOf(label);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            // Mapping back to title case for internal state if needed
            final stateLabel =
                label.substring(0, 1) + label.substring(1).toLowerCase();
            _attendanceStatus[id] = stateLabel;
          });
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            border: Border(
              right:
                  index < 3
                      ? BorderSide(color: Colors.grey[200]!)
                      : BorderSide.none,
              left: isSelected && index > 0 ? BorderSide.none : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          // Simpan Button
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Simpan Absensi',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          // Tutup Halaqoh Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleTutupHalaqoh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.red, width: 1),
                ),
              ),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: Text(
                'Tutup Halaqoh',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
