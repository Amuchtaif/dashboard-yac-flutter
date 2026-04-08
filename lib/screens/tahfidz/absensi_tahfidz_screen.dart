import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/tahfidz_service.dart';
import '../../providers/tahfidz_provider.dart';
import '../../utils/access_control.dart';
import './setoran_tahfidz_screen.dart';

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
  bool _isAddingStudent = false;
  int? _teacherId;
  bool _isKoordinator = false;

  // Halaqoh Opening State
  bool _isHalaqohOpened = false;
  bool _hasCheckedOut = false;
  String? _selectedJadwal;
  final List<String> _jadwalOptions = ['Pagi', 'Siang', 'Sore'];
  Timer? _timer;
  String _currentTime = "";

  // Coordinator State
  List<dynamic> _coordinatorStudents = [];
  String? _coordSelectedSession;
  bool _isAttendanceSubmitted = false;

  @override
  void initState() {
    super.initState();
    _isKoordinator = AccessControl.can('is_koordinator');
    if (_isKoordinator) {
      _fetchCoordinatorData();
    } else {
      _loadTeacherId();
    }
    _startTimer();
  }

  Future<void> _fetchCoordinatorData() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendanceRecords = await _service.getStudentAttendanceHistory(
        date: dateStr,
        session: _coordSelectedSession,
      );

      if (mounted) {
        setState(() {
          _coordinatorStudents = attendanceRecords;
        });
      }
    } catch (e) {
      debugPrint('Error fetching coordinator student data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    super.dispose();
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('userId');
    String? name = prefs.getString('fullName');
    setState(() => _teacherId = id);

    if (!_isKoordinator && _teacherId != null) {
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

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendanceHistory = await _service.getStudentAttendanceHistory(
        date: dateStr,
        session: _selectedSession,
      );

      if (mounted) {
        setState(() {
          _students = provider.myStudents;
          _isAttendanceSubmitted = attendanceHistory.isNotEmpty;

          final Map<int, String> newStatus = {};
          final Map<int, String> historyMap = {};
          for (var record in attendanceHistory) {
            int sId = int.tryParse(record['student_id'].toString()) ?? 0;
            if (sId != 0) {
              historyMap[sId] = record['status'] ?? 'Hadir';
            }
          }

          for (var s in _students) {
            int id =
                int.tryParse(
                  s['student_id']?.toString() ?? s['id']?.toString() ?? '0',
                ) ??
                0;
            if (id != 0) {
              newStatus[id] = historyMap[id] ?? 'Hadir';
            }
          }
          _attendanceStatus.clear();
          _attendanceStatus.addAll(newStatus);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addStudent(int studentId) async {
    if (_teacherId == null || studentId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID Santri tidak valid')));
      return;
    }

    setState(() => _isAddingStudent = true);
    final res = await _service.addHalaqahMember(_teacherId!, studentId);
    if (mounted) setState(() => _isAddingStudent = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Santri berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _fetchStudents();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${res['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _removeStudent(int studentId, String name) async {
    if (_teacherId == null) return false;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Hapus Santri?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus $name dari daftar Anda?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return false;

    if (mounted) setState(() => _isSubmitting = true);
    final res = await _service.removeHalaqahMember(_teacherId!, studentId);
    if (mounted) setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Santri berhasil dihapus'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _fetchStudents();
      return true;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${res['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _showAddStudentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Stack(
            children: [
              _AddStudentBottomSheet(
                onSelected: (id) {
                  Navigator.pop(ctx);
                  _addStudent(id);
                },
                existingIds:
                    _students
                        .map(
                          (s) =>
                              int.tryParse(
                                s['student_id']?.toString() ??
                                    s['id']?.toString() ??
                                    '0',
                              ) ??
                              0,
                        )
                        .toList(),
              ),
              if (_isAddingStudent)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
    );
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

    if (mounted) setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Absensi berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isAttendanceSubmitted = true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    // --- COORDINATOR VIEW ---
    if (_isKoordinator) {
      return _buildCoordinatorView();
    }

    // --- PENGAMPU VIEW ---
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body:
          _hasCheckedOut
              ? _buildClosedView()
              : !_isHalaqohOpened
              ? _buildOpeningView()
              : Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          floating: true,
                          snap: true,
                          title: Text(
                            _isHalaqohOpened
                                ? 'Absensi Santri'
                                : 'Buka Halaqoh',
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
                                icon: const Icon(Icons.edit_note_rounded),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const SetoranTahfidzScreen(),
                                    ),
                                  );
                                },
                                tooltip: 'Input Setoran',
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_month_rounded),
                                onPressed: () async {
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
                                tooltip: 'Filter Tanggal',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                onPressed: _showAddStudentBottomSheet,
                                tooltip: 'Tambah Santri',
                              ),
                            ],
                          ],
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _StickyHeaderDelegate(
                            minHeight: 200,
                            maxHeight: 200,
                            child: Container(
                              color: Colors.grey[100],
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                              ),
                              child: _buildSummaryCard(useMargin: false),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        _buildStudentSliverList(),
                      ],
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
    );
  }

  Widget _buildOpeningView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(
            'Buka Halaqoh',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        SliverToBoxAdapter(
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
                  DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(DateTime.now()),
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
                            onTap:
                                () => setState(() => _selectedJadwal = jadwal),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.indigo
                                        : Colors.grey[50],
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
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
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
        ),
      ],
    );
  }

  Widget _buildClosedView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(
            'Halaqoh Selesai',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({bool useMargin = true}) {
    int total = _students.length;
    int hadir = _attendanceStatus.values.where((s) => s == 'Hadir').length;
    int sakit = _attendanceStatus.values.where((s) => s == 'Sakit').length;
    int izin = _attendanceStatus.values.where((s) => s == 'Izin').length;
    int alpha = _attendanceStatus.values.where((s) => s == 'Alpha').length;

    double progress = total > 0 ? (hadir / total) : 0;

    return Container(
      margin:
          useMargin
              ? const EdgeInsets.fromLTRB(16, 8, 16, 16)
              : const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ringkasan Kehadiran",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Total $total Santri",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${(progress * 100).toInt()}% Hadir",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                width: MediaQuery.of(context).size.width * 0.8 * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModernStatItem(
                "Hadir",
                hadir.toString(),
                const Color(0xFF10B981),
                Icons.check_circle_rounded,
              ),
              _buildModernStatItem(
                "Sakit",
                sakit.toString(),
                const Color(0xFFF59E0B),
                Icons.medical_services_rounded,
              ),
              _buildModernStatItem(
                "Izin",
                izin.toString(),
                const Color(0xFF2563EB),
                Icons.pending_actions_rounded,
              ),
              _buildModernStatItem(
                "Alpha",
                alpha.toString(),
                const Color(0xFFEF4444),
                Icons.do_not_disturb_on_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSliverList() {
    final filteredStudents = _students;

    if (filteredStudents.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Anda belum memiliki daftar santri.",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = filteredStudents[index];
          final id = int.tryParse(student['id'].toString()) ?? 0;
          return _buildStudentCard(student, id);
        }, childCount: filteredStudents.length),
      ),
    );
  }

  Widget _buildStudentCard(dynamic student, int id) {
    String currentStatus = _attendanceStatus[id] ?? 'Hadir';
    Color statusColor = _getStatusColor(currentStatus);
    String studentName =
        (student['nama_siswa'] ??
                student['nama_santri'] ??
                student['nama_lengkap'] ??
                student['full_name'] ??
                student['name'] ??
                'Santri')
            .toString();

    return Dismissible(
      key: Key('student_$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _removeStudent(id, studentName),
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.redAccent.withValues(alpha: 0.8),
              Colors.red.shade700,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 32),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 36),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle Glow in Corner
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.1),
                        statusColor.withValues(alpha: 0.01),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Stylized Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: statusColor.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                studentName.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getStatusIcon(currentStatus),
                                size: 14,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${student['kelas'] ?? student['nama_kelas'] ?? '-'}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Attendance Choice Chips
                    Row(
                      children: [
                        _buildSuperModernChip(
                          id,
                          'HADIR',
                          Icons.done_all_rounded,
                          const Color(0xFF10B981),
                          currentStatus,
                        ),
                        const SizedBox(width: 8),
                        _buildSuperModernChip(
                          id,
                          'SAKIT',
                          Icons.medical_services_rounded,
                          const Color(0xFFF59E0B),
                          currentStatus,
                        ),
                        const SizedBox(width: 8),
                        _buildSuperModernChip(
                          id,
                          'IZIN',
                          Icons.pending_actions_rounded,
                          const Color(0xFF2563EB),
                          currentStatus,
                        ),
                        const SizedBox(width: 8),
                        _buildSuperModernChip(
                          id,
                          'ALPHA',
                          Icons.do_not_disturb_on_rounded,
                          const Color(0xFFEF4444),
                          currentStatus,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return Icons.check_circle_rounded;
      case 'SAKIT':
        return Icons.local_hospital_rounded;
      case 'IZIN':
        return Icons.info_rounded;
      case 'ALPHA':
        return Icons.cancel_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  Widget _buildSuperModernChip(
    int id,
    String label,
    IconData icon,
    Color color,
    String currentStatus,
  ) {
    bool isSelected = currentStatus.toUpperCase() == label;

    return Expanded(
      child: GestureDetector(
        onTap:
            _isAttendanceSubmitted
                ? null
                : () {
                  setState(() {
                    final stateLabel =
                        label.substring(0, 1) +
                        label.substring(1).toLowerCase();
                    _attendanceStatus[id] = stateLabel;
                  });
                },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          // Simpan Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  (_isSubmitting || _isAttendanceSubmitted)
                      ? null
                      : _submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _isAttendanceSubmitted
                        ? const Color(0xFF059669)
                        : Colors.grey[300],
                disabledForegroundColor: Colors.white,
                elevation: _isAttendanceSubmitted ? 0 : 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(
                        _isAttendanceSubmitted
                            ? Icons.check_circle_rounded
                            : Icons.save_rounded,
                        size: 20,
                      ),
              label: Text(
                _isSubmitting
                    ? 'Menyimpan...'
                    : (_isAttendanceSubmitted
                        ? 'Absensi Terkirim'
                        : 'Simpan Absensi'),
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

  // ====== COORDINATOR VIEW ======
  Widget _buildCoordinatorView() {
    int hadir =
        _coordinatorStudents.where((s) => s['status'] == 'Hadir').length;
    int sakit =
        _coordinatorStudents.where((s) => s['status'] == 'Sakit').length;
    int izin = _coordinatorStudents.where((s) => s['status'] == 'Izin').length;
    int alpha =
        _coordinatorStudents.where((s) => s['status'] == 'Alpha').length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  title: Text(
                    'Absensi Tahfidz',
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
                    IconButton(
                      icon: const Icon(Icons.calendar_month_rounded),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                          _fetchCoordinatorData();
                        }
                      },
                      tooltip: 'Filter Tanggal',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Filter Row: Sesi Halaqoh
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.white,
                        child: Row(
                          children: [
                            // Sesi Halaqoh
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    isExpanded: true,
                                    value: _coordSelectedSession,
                                    hint: Text(
                                      'Semua Sesi',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          'Semua Sesi',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      ..._jadwalOptions.map((s) {
                                        return DropdownMenuItem<String?>(
                                          value: s,
                                          child: Text(
                                            s,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(
                                        () => _coordSelectedSession = val,
                                      );
                                      _fetchCoordinatorData();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    minHeight: 154,
                    maxHeight: 154,
                    child: Container(
                      color: Colors.grey[100],
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: _buildCoordinatorSummary(
                        hadir,
                        sakit,
                        izin,
                        alpha,
                        useMargin: false,
                      ),
                    ),
                  ),
                ),
                _buildCoordStudentSliverList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordStudentSliverList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_coordinatorStudents.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Belum ada data absensi santri',
                style: GoogleFonts.poppins(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = _coordinatorStudents[index];
          return _buildCoordStudentCard(student);
        }, childCount: _coordinatorStudents.length),
      ),
    );
  }

  Widget _buildCoordinatorSummary(
    int hadir,
    int sakit,
    int izin,
    int alpha, {
    bool useMargin = true,
  }) {
    int total = _coordinatorStudents.length;
    double progress = total > 0 ? (hadir / total) : 0;

    return Container(
      margin:
          useMargin
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCoordStatCard(
                  "Hadir",
                  hadir.toString(),
                  const Color(0xFF10B981),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCoordStatCard(
                  "Sakit",
                  sakit.toString(),
                  const Color(0xFFF59E0B),
                  Icons.local_hospital,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCoordStatCard(
                  "Izin",
                  izin.toString(),
                  const Color(0xFF2563EB),
                  Icons.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCoordStatCard(
                  "Alpha",
                  alpha.toString(),
                  const Color(0xFFEF4444),
                  Icons.cancel,
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(progress * 100).toInt()}% Kehadiran",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoordStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordStudentCard(dynamic record) {
    final studentName = record['student_name']?.toString() ?? '-';
    final kelas = record['kelas']?.toString() ?? '-';
    final tingkat = record['tingkat']?.toString() ?? '-';
    final status = record['status']?.toString() ?? '-';
    final session = record['session']?.toString() ?? '-';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Hadir':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Sakit':
        statusColor = Colors.orange;
        statusIcon = Icons.local_hospital;
        break;
      case 'Izin':
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
      case 'Alpha':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Text(
                studentName.substring(0, 1).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Kelas $kelas  •  $tingkat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          session,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStudentBottomSheet extends StatefulWidget {
  final Function(int id) onSelected;
  final List<int> existingIds;

  const _AddStudentBottomSheet({
    required this.onSelected,
    required this.existingIds,
  });

  @override
  State<_AddStudentBottomSheet> createState() => _AddStudentBottomSheetState();
}

class _AddStudentBottomSheetState extends State<_AddStudentBottomSheet> {
  final TahfidzService _service = TahfidzService();
  final TextEditingController _findController = TextEditingController();
  List<dynamic> _allStudents = [];
  List<dynamic> _foundStudents = [];
  bool _searching = true;

  @override
  void initState() {
    super.initState();
    _loadAllStudents();
  }

  Future<void> _loadAllStudents() async {
    try {
      final list = await _service.getStudents();
      if (mounted) {
        setState(() {
          _allStudents = list;
          _foundStudents = list;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _filter(String q) {
    setState(() {
      _foundStudents =
          _allStudents
              .where(
                (s) => (s['nama_siswa'] ??
                        s['nama_santri'] ??
                        s['nama_lengkap'] ??
                        s['full_name'] ??
                        s['name'] ??
                        '')
                    .toString()
                    .toLowerCase()
                    .contains(q.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Tambah Santri',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _findController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kelas...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _searching
                    ? const Center(child: CircularProgressIndicator())
                    : _foundStudents.isEmpty
                    ? Center(
                      child: Text(
                        'Data tidak ditemukan',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _foundStudents.length,
                      itemBuilder: (ctx, idx) {
                        final s = _foundStudents[idx];
                        final id =
                            int.tryParse(
                              s['student_id']?.toString() ??
                                  s['id']?.toString() ??
                                  '0',
                            ) ??
                            0;
                        final isAlreadyMember = widget.existingIds.contains(id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            child: Text(
                              (s['nama_siswa'] ??
                                      s['nama_santri'] ??
                                      s['nama_lengkap'] ??
                                      s['full_name'] ??
                                      s['name'] ??
                                      '?')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(
                            s['nama_siswa'] ??
                                s['nama_santri'] ??
                                s['nama_lengkap'] ??
                                s['full_name'] ??
                                s['name'] ??
                                '-',
                            style: GoogleFonts.poppins(
                              color: isAlreadyMember ? Colors.grey : null,
                              decoration:
                                  isAlreadyMember
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                          subtitle: Text(
                            s['kelas'] ?? s['nama_kelas'] ?? '-',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing:
                              isAlreadyMember
                                  ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green,
                                  )
                                  : IconButton(
                                    onPressed: () => widget.onSelected(id),
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Colors.blueAccent,
                                  ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}
