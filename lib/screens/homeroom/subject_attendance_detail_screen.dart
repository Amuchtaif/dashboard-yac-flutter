import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';

class SubjectAttendanceDetailScreen extends StatefulWidget {
  final int journalId;
  const SubjectAttendanceDetailScreen({super.key, required this.journalId});

  @override
  State<SubjectAttendanceDetailScreen> createState() =>
      _SubjectAttendanceDetailScreenState();
}

class _SubjectAttendanceDetailScreenState
    extends State<SubjectAttendanceDetailScreen> {
  bool _isLoading = true;
  String? _userId;
  Map<String, dynamic>? _journal;
  List<dynamic> _attendance = [];

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
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
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
          "action": "get_journal_attendance_detail",
          "journal_id": widget.journalId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _journal = data['journal'];
            _attendance = data['attendance'] ?? [];
            _isLoading = false;
          });
        } else {
          _showError(data['message'] ?? "Gagal mengambil data");
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Detail Absensi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJournalCard(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          "Daftar Kehadiran",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _attendance.length.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attendance.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _buildStudentItem(_attendance[index]);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '-';
    final parts = time.split(':');
    if (parts.length >= 2) {
      return "${parts[0]}:${parts[1]}";
    }
    return time;
  }

  Widget _buildJournalCard() {
    if (_journal == null) return const SizedBox();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section with Gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.blueAccent.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _journal!['subject_name'] ?? '-',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        _journal!['teacher_name'] ?? '-',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Info Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildModernInfoRow(Icons.event_note_rounded, "Tanggal", DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(_journal!['date'])), Colors.blue),
                const SizedBox(height: 16),
                _buildModernInfoRow(Icons.alarm_on_rounded, "Jam Pelajaran", "${_formatTime(_journal!['start_time'])} - ${_formatTime(_journal!['end_time'])}", Colors.indigo),
                const SizedBox(height: 16),
                _buildModernInfoRow(Icons.auto_stories_rounded, "Materi / Topik", _journal!['topic'] ?? '-', Colors.teal),
                if (_journal!['notes'] != null && _journal!['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildModernInfoRow(Icons.sticky_note_2_rounded, "Catatan Guru", _journal!['notes'], Colors.amber),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF334155), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentItem(Map<String, dynamic> item) {
    String status = item['status']?.toString().toLowerCase() ?? 'present';
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'present':
      case 'h':
        statusColor = Colors.green;
        statusLabel = "Hadir";
        break;
      case 'absent':
      case 'a':
        statusColor = Colors.red;
        statusLabel = "Alpha";
        break;
      case 'sick':
      case 's':
        statusColor = Colors.blue;
        statusLabel = "Sakit";
        break;
      case 'permit':
      case 'i':
        statusColor = Colors.orange;
        statusLabel = "Izin";
        break;
      case 'late':
      case 't':
        statusColor = Colors.deepOrange;
        statusLabel = "Telat";
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Text(
              item['nama_siswa'][0],
              style: GoogleFonts.poppins(
                fontSize: 14,
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
                  item['nama_siswa'] ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "NIS: ${item['nomor_induk'] ?? '-'}",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
