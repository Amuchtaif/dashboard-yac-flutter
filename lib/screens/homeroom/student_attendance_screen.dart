import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isLoading = true;
  String? _userId;
  Map<String, dynamic>? _classInfo;
  List<dynamic> _students = [];
  final Map<int, String> _attendanceStatus =
      {}; // student_id -> status (H, S, I, A)
  final Map<int, TextEditingController> _noteControllers = {};
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId =
          (prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0).toString();
    });
    if (_userId != "0") {
      _fetchClassInfo();
    }
  }

  Future<void> _fetchClassInfo() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/homeroom/dashboard.php"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "user_id": _userId,
          "action": "get_class_info",
          "date": DateFormat('y-MM-dd').format(_selectedDate),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _classInfo = data['class'];
            _students = data['students'] ?? [];
            final existingAttendance =
                data['attendance'] as Map<String, dynamic>? ?? {};

            // Initialize status and notes
            _attendanceStatus.clear();
            for (var controller in _noteControllers.values) {
              controller.dispose();
            }
            _noteControllers.clear();

            for (var student in _students) {
              int id = int.parse(student['id'].toString());
              // Use existing status from attendance map if available, otherwise default to 'H'
              _attendanceStatus[id] = existingAttendance[id.toString()] ?? 'H';
              _noteControllers[id] = TextEditingController(
                text: '',
              ); // Notes not in map currently
            }
            _isLoading = false;
            // Enter edit mode if no attendance found for this date
            _isEditMode = existingAttendance.isEmpty;
          });
        } else {
          _showError(data['message'] ?? "Gagal mengambil data kelas");
        }
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> attendanceData = [];
      _attendanceStatus.forEach((studentId, status) {
        attendanceData.add({
          "student_id": studentId,
          "status": status,
          "notes": _noteControllers[studentId]?.text ?? "",
        });
      });

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/homeroom/dashboard.php"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "user_id": _userId,
          "action": "submit_attendance",
          "date": DateFormat('y-MM-dd').format(_selectedDate),
          "grade_level_id": _classInfo?['id'],
          "attendance": attendanceData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Absensi berhasil disimpan"),
                backgroundColor: Colors.green,
              ),
            );
          }
          _fetchClassInfo();
          setState(() => _isEditMode = false);
        } else {
          _showError(data['message'] ?? "Gagal simpan absensi");
        }
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<dynamic> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) {
      return s['nama_siswa'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  Map<String, int> _getSummary() {
    Map<String, int> summary = {'H': 0, 'S': 0, 'I': 0, 'A': 0};
    for (var status in _attendanceStatus.values) {
      if (summary.containsKey(status)) {
        summary[status] = summary[status]! + 1;
      }
    }
    return summary;
  }

  void _markAllAsPresent() {
    setState(() {
      for (var student in _students) {
        int id = int.parse(student['id'].toString());
        _attendanceStatus[id] = 'H';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Semua siswa ditandai Hadir"),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _classInfo != null ? _classInfo!['name'] : "Absensi Siswa",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: "Pilih Tanggal",
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.blueAccent,
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Colors.blueAccent,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _fetchClassInfo();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
              : _students.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  _buildTopStats(),
                  _buildSearchBar(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final id = int.parse(student['id'].toString());
                        return _buildStudentCard(student, id);
                      },
                    ),
                  ),
                  // Static Save/Edit Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isEditMode
                                ? _submitAttendance
                                : () => setState(() => _isEditMode = true),
                        icon: Icon(
                          _isEditMode ? Icons.save_rounded : Icons.edit_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isEditMode ? "SIMPAN ABSENSI" : "EDIT ABSENSI",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isEditMode ? Colors.blueAccent : Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Tidak ada data siswa ditemukan",
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    final summary = _getSummary();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ringkasan Hari Ini",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              _isEditMode
                  ? TextButton.icon(
                    onPressed: _markAllAsPresent,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: Text(
                      "Hadir Semua",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.green,
                    ),
                  )
                  : const SizedBox(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['H', 'S', 'I', 'A'].map((status) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          summary[status].toString(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusLabel(status),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: "Cari nama siswa...",
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'H':
        return 'Hadir';
      case 'S':
        return 'Sakit';
      case 'I':
        return 'Izin';
      case 'A':
        return 'Alpha';
      default:
        return '';
    }
  }

  Widget _buildStudentCard(dynamic student, int id) {
    final currentStatus = _attendanceStatus[id] ?? 'H';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      student['nama_siswa'][0],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['nama_siswa'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "NIS: ${student['nomor_induk'] ?? '-'}",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusIndicator(currentStatus),
              ],
            ),
          ),
          if (_isEditMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        ['H', 'S', 'I', 'A'].map((status) {
                          bool isSelected = _attendanceStatus[id] == status;
                          Color color = _getStatusColor(status);
                          return Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _attendanceStatus[id] = status,
                                  ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? color : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? color
                                            : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      status,
                                      style: GoogleFonts.poppins(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _getStatusLabel(status),
                                      style: GoogleFonts.poppins(
                                        color:
                                            isSelected
                                                ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
                                                : Colors.grey.shade400,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteControllers[id],
                    decoration: InputDecoration(
                      hintText:
                          "Tambah catatan untuk ${student['nama_siswa'].split(' ')[0]}...",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                      isDense: true,
                      prefixIcon: const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        _getStatusLabel(status),
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'H':
        return Colors.green;
      case 'S':
        return Colors.blue;
      case 'I':
        return Colors.orange;
      case 'A':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
