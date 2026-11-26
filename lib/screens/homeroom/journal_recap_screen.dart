import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/offline_sync_banner.dart';

class JournalRecapScreen extends StatefulWidget {
  const JournalRecapScreen({super.key});

  @override
  State<JournalRecapScreen> createState() => _JournalRecapScreenState();
}

class _JournalRecapScreenState extends State<JournalRecapScreen> {
  bool _isLoading = true;
  String? _userId;
  String? _className;
  String? _errorMessage;
  List<dynamic> _journals = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUserId = prefs.get('user_id') ?? prefs.get('userId') ?? 0;
    setState(() {
      _userId = rawUserId.toString();
    });
    if (_userId != "0" && _userId != null) {
      _fetchJournals();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Sesi pengguna tidak valid. Silakan masuk ulang.";
      });
    }
  }

  Future<void> _fetchJournals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final cacheKey = 'homeroom_journals_${_userId}_$formattedDate';
    final offlineSync = OfflineSyncService();

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/homeroom/dashboard.php"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "user_id": _userId,
          "action": "get_journals",
          "date": formattedDate,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await offlineSync.saveCache(cacheKey, data);
          await offlineSync.saveCache(
              'homeroom_journals_${_userId}_latest', data);
          setState(() {
            _journals = data['data'] ?? [];
            if (data['class'] != null && data['class']['name'] != null) {
              _className = data['class']['name'].toString();
            }
            _errorMessage = null;
            _isLoading = false;
          });
          return;
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal memuat jurnal kelas';
            _journals = [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching journals (trying cache): $e");
    }

    // Fallback offline
    final cached = await offlineSync.getCache(cacheKey) ??
        await offlineSync.getCache('homeroom_journals_${_userId}_latest');
    if (cached != null && cached is Map<String, dynamic>) {
      setState(() {
        _journals = cached['data'] ?? [];
        if (cached['class'] != null && cached['class']['name'] != null) {
          _className = cached['class']['name'].toString();
        }
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _errorMessage = "Gagal terhubung ke server. Periksa koneksi internet Anda.";
        _journals = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchJournals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Rekap Jurnal Kelas",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: "Pilih Tanggal",
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineSyncBanner(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          // Filter Bar Tanggal Aktif
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.event_note, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_className != null)
                        Text(
                          "Wali Kelas $_className",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      Text(
                        _formatDateIndo(_selectedDate),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar, size: 14),
                  label: Text(
                    "Ganti",
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body Content
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchJournals,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text("Coba Lagi", style: GoogleFonts.poppins(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_journals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "Belum ada jurnal untuk tanggal ini",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDateIndo(_selectedDate),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text("Pilih Tanggal Lain", style: GoogleFonts.poppins(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchJournals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _journals.length,
        itemBuilder: (context, index) {
          final item = _journals[index];
          return _buildJournalCard(item);
        },
      ),
    );
  }

  Widget _buildJournalCard(dynamic journal) {
    final subjectName = (journal['subject_name'] ?? 'Mata Pelajaran').toString();
    final rawStart = (journal['start_time'] ?? '-').toString();
    final rawEnd = (journal['end_time'] ?? '-').toString();
    final startTime = (rawStart != 'null' && rawStart.isNotEmpty) ? _formatTime(rawStart) : '-';
    final endTime = (rawEnd != 'null' && rawEnd.isNotEmpty) ? _formatTime(rawEnd) : '-';
    final teacherName = (journal['teacher_name'] ?? '-').toString();
    final cleanTeacherName = (teacherName != 'null' && teacherName.isNotEmpty) ? teacherName : '-';
    final topic = (journal['topic'] ?? '-').toString();
    final cleanTopic = (topic != 'null' && topic.isNotEmpty) ? topic : '-';
    final notes = (journal['notes'] ?? '-').toString();
    final cleanNotes = (notes != 'null' && notes.isNotEmpty) ? notes : '-';
    final presentCount = journal['count_present']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: const Color(0xFF10B981),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subjectName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$startTime - $endTime",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Guru: $cleanTeacherName",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (presentCount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Hadir: $presentCount",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFF047857),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      Text(
                        "Materi / Topik:",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cleanTopic,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Catatan KBM:",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cleanNotes,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateIndo(DateTime dt) {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(dt);
    }
  }

  String _formatTime(String t) {
    if (t == '-' || t.isEmpty) return '-';
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }
}
