import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tahfidz_service.dart';

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
  String? _selectedJadwal;
  final List<String> _jadwalOptions = ['Pagi', 'Siang', 'Sore'];
  Timer? _timer;
  String _currentTime = "";

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
    super.dispose();
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('userId');
    setState(() => _teacherId = id);

    if (_teacherId != null) {
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
        setState(() {
          _isHalaqohOpened = true;
          // Set session based on check-in notes if possible, or default to current
          if (history.first['notes'] != null) {
            _selectedSession = history.first['notes'];
          }
        });
        await _fetchStudents();
      }
    } catch (e) {
      debugPrint("Error checking halaqoh status: $e");
    } finally {
      if (!_isHalaqohOpened) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBukaHalaqoh() async {
    if (_teacherId == null) return;
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

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _service.getStudents();
      setState(() {
        _students = students;
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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isHalaqohOpened)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchStudents,
            ),
        ],
      ),
      body:
          !_isHalaqohOpened
              ? _buildOpeningView()
              : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final id = int.tryParse(student['id'].toString()) ?? 0;
                        return _buildStudentCard(student, id);
                      },
                    ),
                  ),
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
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedJadwal = jadwal),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.indigo : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.indigo
                                      : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            jadwal,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButton<String>(
              value: _selectedSession,
              underline: const SizedBox(),
              items:
                  ['Pagi', 'Siang', 'Sore'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(fontSize: 13),
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
        ],
      ),
    );
  }

  Widget _buildStudentCard(dynamic student, int id) {
    String currentStatus = _attendanceStatus[id] ?? 'Hadir';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student['nama_siswa'] ?? 'No Name',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (student['kelas'] != null)
            Text(
              "Kelas: ${student['kelas']}",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusOption(id, 'Hadir', Colors.green, currentStatus),
              _buildStatusOption(id, 'Sakit', Colors.orange, currentStatus),
              _buildStatusOption(id, 'Izin', Colors.blue, currentStatus),
              _buildStatusOption(id, 'Alpha', Colors.red, currentStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    int id,
    String label,
    Color color,
    String currentStatus,
  ) {
    bool isSelected = currentStatus == label;
    return InkWell(
      onTap: () {
        setState(() {
          _attendanceStatus[id] = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isSelected ? color : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
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
                    'Simpan Absensi Santri',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }
}
