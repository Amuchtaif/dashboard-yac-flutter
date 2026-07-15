import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class DetailPengampuPimpinanScreen extends StatefulWidget {
  final int teacherId;
  const DetailPengampuPimpinanScreen({super.key, required this.teacherId});

  @override
  State<DetailPengampuPimpinanScreen> createState() => _DetailPengampuPimpinanScreenState();
}

class _DetailPengampuPimpinanScreenState extends State<DetailPengampuPimpinanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _teacherData = {};
  List<dynamic> _halaqahs = [];
  List<dynamic> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final baseUrl = ApiConfig.baseUrl;

      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/dashboard_pimpinan?action=detail_pengampu&id=${widget.teacherId}"),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success'] == true) {
          setState(() {
            _teacherData = res['data']?['teacher'] ?? {};
            _halaqahs = res['data']?['halaqahs'] ?? [];
            _recentLogs = res['data']?['recent_logs'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage = "Gagal memuat detail pengampu.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Kesalahan koneksi: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _teacherData['name'] ?? 'Detail Kinerja Pengampu',
          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        color: const Color(0xFF0D9488),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
            : _errorMessage != null
                ? _buildErrorState()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTeacherCard(),
                        const SizedBox(height: 24),
                        Text(
                          "Halaqah yang Diampu (${_halaqahs.length})",
                          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildHalaqahList(),
                        const SizedBox(height: 24),
                        Text(
                          "Input Setoran Terbaru",
                          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildRecentLogsList(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTeacherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.person_pin, color: Color(0xFF0369A1), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_teacherData['name'] ?? 'Guru Pengampu', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    Text("Pendidikan: ${_teacherData['division_name'] ?? 'Tahfidz'}", style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Unit Tugas", _teacherData['unit_name'] ?? '-'),
              _buildStat("Kehadiran Mengajar", "${_teacherData['attendance_rate'] ?? 0}%"),
              _buildStat("Input Minggu Ini", "${_teacherData['weekly_input_count'] ?? 0} kali"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildHalaqahList() {
    if (_halaqahs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text("Pengampu ini belum memiliki halaqah.", style: GoogleFonts.poppins(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _halaqahs.length,
      itemBuilder: (context, index) {
        final halaqah = _halaqahs[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(halaqah['group_name'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: Text("${halaqah['member_count'] ?? 0} Santri", style: GoogleFonts.poppins(fontSize: 10)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildRecentLogsList() {
    if (_recentLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text("Belum ada log input setoran baru dari pengampu ini.", style: GoogleFonts.poppins(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentLogs.length,
      itemBuilder: (context, index) {
        final log = _recentLogs[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(log['student_name'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: Text("Aktivitas: ${log['activity_name']} • Surah: ${log['surah_name'] ?? '-'} • Ayat: ${log['start_ayat']}-${log['end_ayat']}\nCatatan: ${log['notes'] ?? '-'}", style: GoogleFonts.poppins(fontSize: 10)),
            trailing: Text(log['date'] ?? '', style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey)),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetails,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }
}
