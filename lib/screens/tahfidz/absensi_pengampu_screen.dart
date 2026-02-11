import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/tahfidz_service.dart';

class AbsensiPengampuScreen extends StatefulWidget {
  const AbsensiPengampuScreen({super.key});

  @override
  State<AbsensiPengampuScreen> createState() => _AbsensiPengampuScreenState();
}

class _AbsensiPengampuScreenState extends State<AbsensiPengampuScreen> {
  final TahfidzService _service = TahfidzService();
  bool _isLoading = true;
  List<dynamic> _teachers = [];
  Map<int, String> _attendanceStatus = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await _service.getTeachers();
      final history = await _service.getTeacherAttendanceHistory(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      setState(() {
        _teachers = teachers;
        // Map history to teachers
        for (var t in _teachers) {
          int id = int.tryParse(t['id'].toString()) ?? 0;
          if (id != 0) {
            final record = history.firstWhere(
              (h) => h['teacher_id'].toString() == id.toString(),
              orElse: () => null,
            );
            if (record != null) {
              _attendanceStatus[id] =
                  record['check_out_time'] != null
                      ? 'Hadir (Selesai)'
                      : 'Hadir';
            } else {
              _attendanceStatus[id] = 'Belum Absen';
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error fetching teachers or history: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTeacherStatus(int teacherId, String action) async {
    final result = await _service.submitTeacherAttendance(
      teacherId: teacherId,
      action: action,
    );

    if (result['success'] == true) {
      _fetchTeachers(); // Refresh
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Absensi Pengampu',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _teachers.isEmpty
                    ? const Center(child: Text('Tidak ada data pengampu'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final id = int.tryParse(teacher['id'].toString()) ?? 0;
                        return _buildTeacherCard(teacher, id);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Kehadiran Pengampu',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTeachers,
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(dynamic teacher, int id) {
    String status = _attendanceStatus[id] ?? 'Belum Absen';
    Color statusColor = status == 'Belum Absen' ? Colors.grey : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher['nama_lengkap'] ?? teacher['name'] ?? 'Pengampu',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'Belum Absen')
            ElevatedButton(
              onPressed: () => _updateTeacherStatus(id, 'check_in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Hadir'),
            )
          else if (status == 'Hadir')
            TextButton(
              onPressed: () => _updateTeacherStatus(id, 'check_out'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Pulang'),
            ),
        ],
      ),
    );
  }
}
