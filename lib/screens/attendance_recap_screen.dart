import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/teacher_service.dart';

class AttendanceRecapScreen extends StatefulWidget {
  const AttendanceRecapScreen({super.key});

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen> {
  final TeacherService _teacherService = TeacherService();
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedUnit;
  String? _selectedClassName;
  String? _selectedClassId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    setState(() => _isLoading = true);
    try {
      final data = await _teacherService.getAttendanceRecap();
      if (mounted) {
        // Sort units based on user requirement
        const order = [
          'mahad aly',
          'ma',
          'idad lughoh',
          'mts',
          'sdit',
          'tkit',
          'playgroup',
        ];

        data.sort((a, b) {
          final aName = a['unit_name']?.toString().toLowerCase().replaceAll("'", "").replaceAll("`", "").trim() ?? '';
          final bName = b['unit_name']?.toString().toLowerCase().replaceAll("'", "").replaceAll("`", "").trim() ?? '';

          int aIndex = order.indexOf(aName);
          int bIndex = order.indexOf(bName);

          if (aIndex == -1) aIndex = 99;
          if (bIndex == -1) bIndex = 99;

          return aIndex.compareTo(bIndex);
        });

        setState(() {
          _units = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat jenjang: $e')));
      }
    }
  }

  Future<void> _fetchClasses(String unit) async {
    setState(() {
      _selectedUnit = unit;
      _isLoading = true;
    });
    try {
      final data = await _teacherService.getAttendanceRecap(unit: unit);
      if (mounted) {
        setState(() {
          _classes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data kelas: $e')));
      }
    }
  }

  Future<void> _fetchSubjects(String classId, String className) async {
    setState(() {
      _selectedClassId = classId;
      _selectedClassName = className;
      _isLoading = true;
    });
    try {
      final data = await _teacherService.getAttendanceRecap(classId: classId);
      if (mounted) {
        setState(() {
          _subjects = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat mata pelajaran: $e')),
        );
      }
    }
  }

  void _goBack() {
    if (_selectedClassId != null) {
      setState(() {
        _selectedClassId = null;
        _selectedClassName = null;
        _subjects = [];
      });
    } else if (_selectedUnit != null) {
      setState(() {
        _selectedUnit = null;
        _classes = [];
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Rekap Presensi';
    if (_selectedClassName != null) {
      title = 'Kelas $_selectedClassName';
    } else if (_selectedUnit != null) {
      title = 'Jenjang $_selectedUnit';
    }

    return PopScope(
      canPop: _selectedUnit == null && _selectedClassId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B),
              size: 20,
            ),
            onPressed: _goBack,
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedClassId != null
                ? _buildSubjectList()
                : _selectedUnit == null
                ? _buildUnitList()
                : _buildClassList(),
      ),
    );
  }

  Widget _buildUnitList() {
    if (_units.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data jenjang',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
            TextButton(onPressed: _fetchUnits, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unitName = _units[index]['unit_name']?.toString() ?? 'Unknown';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _fetchClasses(unitName),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unitName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Ketuk untuk melihat rekap kelas',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassList() {
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.door_front_door_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data kelas di jenjang ini',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
            TextButton(
              onPressed: () => _fetchClasses(_selectedUnit!),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat(
                    'EEEE, dd MMM yyyy',
                    'id_ID',
                  ).format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._classes.map((cls) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap:
                      () => _fetchSubjects(
                        cls['id'].toString(),
                        cls['name'].toString(),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.meeting_room_rounded,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cls['name']?.toString() ?? 'Unknown Class',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Ketuk untuk melihat detail per mapel',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal mata pelajaran hari ini',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
            TextButton(
              onPressed:
                  () => _fetchSubjects(_selectedClassId!, _selectedClassName!),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final sub = _subjects[index];
        final bool isAttended = sub['is_attended'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isAttended
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAttended
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color:
                        isAttended
                            ? const Color(0xFF166534)
                            : const Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub['subject_name'] ?? 'Mata Pelajaran',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        sub['teacher_name'] ?? 'Nama Guru',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sub['start_time']} - ${sub['end_time']}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isAttended
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAttended ? 'Sudah Absen' : 'Belum Absen',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isAttended
                              ? const Color(0xFF166534)
                              : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
