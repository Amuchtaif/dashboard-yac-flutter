import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';

class JournalRecapScreen extends StatefulWidget {
  const JournalRecapScreen({super.key});

  @override
  State<JournalRecapScreen> createState() => _JournalRecapScreenState();
}

class _JournalRecapScreenState extends State<JournalRecapScreen> {
  bool _isLoading = true;
  String? _userId;
  List<dynamic> _journals = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = (prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0).toString();
    });
    if (_userId != "0") {
      _fetchJournals();
    }
  }

  Future<void> _fetchJournals() async {
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
          "action": "get_journals",
          "date": DateFormat('Y-M-d').format(_selectedDate),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _journals = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() => _selectedDate = picked);
                _fetchJournals();
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _journals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada jurnal untuk tanggal ini",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: Colors.green,
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
                              journal['subject_name'] ?? 'Mata Pelajaran',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Text(
                            "${journal['start_time']} - ${journal['end_time']}",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Guru: ${journal['teacher_name']}",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Divider(height: 24),
                      Text(
                        "Materi:",
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journal['topic'] ?? "-",
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Catatan KBM:",
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journal['notes'] ?? "-",
                        style: GoogleFonts.poppins(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[700]),
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
}
