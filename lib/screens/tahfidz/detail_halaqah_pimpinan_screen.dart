import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'profil_santri_screen.dart';

class DetailHalaqahPimpinanScreen extends StatefulWidget {
  final int halaqahId;
  const DetailHalaqahPimpinanScreen({super.key, required this.halaqahId});

  @override
  State<DetailHalaqahPimpinanScreen> createState() => _DetailHalaqahPimpinanScreenState();
}

class _DetailHalaqahPimpinanScreenState extends State<DetailHalaqahPimpinanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _halaqahData = {};
  List<dynamic> _students = [];

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
        Uri.parse("$baseUrl/tahfidz/dashboard_pimpinan?action=detail_halaqoh&id=${widget.halaqahId}"),
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
            _halaqahData = res['data']?['halaqah'] ?? {};
            _students = res['data']?['students'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage = "Gagal memuat detail halaqah.";
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
          _halaqahData['name'] ?? 'Detail Halaqah',
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
                        _buildHalaqahCard(),
                        const SizedBox(height: 24),
                        Text(
                          "Daftar Santri (${_students.length})",
                          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildStudentList(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHalaqahCard() {
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
                decoration: const BoxDecoration(color: Color(0xFFCCFBF1), shape: BoxShape.circle),
                child: const Icon(Icons.group_work, color: Color(0xFF0F766E), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_halaqahData['name'] ?? 'Halaqah Tahfidz', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    Text("Pengampu: ${_halaqahData['teacher_name'] ?? 'Tidak ada'}", style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Jumlah Santri", "${_halaqahData['member_count'] ?? 0} Santri"),
              _buildStat("Kehadiran Bulan Ini", "${_halaqahData['attendance_rate'] ?? 0}%"),
              _buildStat("Rata-rata Capaian", "${_halaqahData['avg_progress'] ?? 0} Juz"),
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

  Widget _buildStudentList() {
    if (_students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text("Halaqah ini belum memiliki santri.", style: GoogleFonts.poppins(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(student['full_name'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: Text("Kelas: ${student['kelas'] ?? '-'} • Baseline: ${student['baseline_juz'] ?? 0} Juz", style: GoogleFonts.poppins(fontSize: 10)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${student['total_juz'] ?? 0} Juz", style: GoogleFonts.poppins(color: const Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 12)),
                Text("Terakhir Setor: ${student['last_setor_date'] ?? '-'}", style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailProfileScreen(
                    studentId: student['id'],
                    studentData: student,
                  ),
                ),
              );
            },
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
