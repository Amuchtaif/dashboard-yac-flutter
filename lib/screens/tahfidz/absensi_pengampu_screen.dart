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
  bool _isSubmitting = false;
  List<dynamic> _teachers = [];
  final Map<int, String> _attendanceStatus = {};
  final DateTime _selectedDate = DateTime.now();

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
              // Map legacy status to new options
              String rawStatus = record['action'] ?? 'HADIR';
              if (rawStatus == 'check_in') {
                _attendanceStatus[id] = 'HADIR';
              } else {
                _attendanceStatus[id] = rawStatus.toUpperCase();
              }
            } else {
              _attendanceStatus[id] =
                  'HADIR'; // Default to HADIR for convenience
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

  Future<void> _handleSaveAttendance() async {
    setState(() => _isSubmitting = true);
    int successCount = 0;
    int failCount = 0;

    // Simulate bulk submission by calling each individually
    // In a real scenario, a bulk endpoint would be better
    for (var entry in _attendanceStatus.entries) {
      final result = await _service.submitTeacherAttendance(
        teacherId: entry.key,
        action: entry.value.toLowerCase(),
        time: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        notes: "Absensi Koordinator",
      );

      if (result['success'] == true) {
        successCount++;
      } else {
        failCount++;
      }
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failCount == 0
              ? 'Seluruh absensi berhasil disimpan!'
              : '$successCount berhasil, $failCount gagal.',
        ),
        backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
      ),
    );

    if (failCount == 0) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Absensi Pengampu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: () {
                      // Date picker functionality could go here
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActiveSessionHeader(),
                        const SizedBox(height: 25),
                        _buildStatisticsRow(),
                        const SizedBox(height: 30),
                        Text(
                          'DAFTAR PENGAMPU',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 15),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = _teachers[index];
                            final id =
                                int.tryParse(teacher['id'].toString()) ?? 0;
                            return _buildTeacherCard(teacher, id);
                          },
                        ),
                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
    );
  }

  Widget _buildActiveSessionHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            'SESI AKTIF',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.lightBlue[400],
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_selectedDate),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50]?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: Colors.blue[400],
                ),
                const SizedBox(width: 8),
                Text(
                  'Sesi Pagi (07:30 - 11:30)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    int total = _teachers.length;
    int hadir = _attendanceStatus.values.where((s) => s == 'HADIR').length;
    int izin = _attendanceStatus.values.where((s) => s == 'IZIN').length;
    int alfa = _attendanceStatus.values.where((s) => s == 'ALFA').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatBox('TOTAL', total.toString(), Colors.blue),
          _buildStatBox('HADIR', hadir.toString(), Colors.teal),
          _buildStatBox('IZIN', izin.toString(), Colors.amber),
          _buildStatBox('ALFA', alfa.toString(), Colors.pink),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      width: 85,
      height: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(dynamic teacher, int id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image:
                        (teacher['foto'] != null && teacher['foto'] != "")
                            ? NetworkImage(teacher['foto'])
                            : const AssetImage(
                                  'assets/images/default_avatar.png',
                                )
                                as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child:
                    (teacher['foto'] == null || teacher['foto'] == "")
                        ? const Icon(Icons.person, color: Colors.grey, size: 30)
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher['nama_lengkap'] ?? teacher['name'] ?? 'Pengampu',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      teacher['unit_name'] ?? 'Halaqoh Al-Jazari',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusButton(id, 'HADIR', Colors.teal),
              _buildStatusButton(id, 'IZIN', Colors.amber),
              _buildStatusButton(id, 'SAKIT', Colors.orange),
              _buildStatusButton(id, 'ALFA', Colors.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(int teacherId, String status, Color color) {
    bool isSelected = _attendanceStatus[teacherId] == status;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _attendanceStatus[teacherId] = status;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 25,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSaveAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Simpan Absensi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
