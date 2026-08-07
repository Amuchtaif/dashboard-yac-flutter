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
      final int userId = prefs.getInt('userId') ?? 0;
      final baseUrl = ApiConfig.baseUrl;

      final response = await http.get(
        Uri.parse("$baseUrl/tahfidz/dashboard_pimpinan?action=detail_halaqoh&id=${widget.halaqahId}&user_id=$userId"),
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
            _halaqahData = res['data']?['info'] ?? res['data']?['halaqah'] ?? {};
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
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D9488), size: 14),
            onPressed: () => Navigator.pop(context),
          ),
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
    final groupName = _halaqahData['name'] ?? 'Halaqah Tahfidz';
    final teacherName = _halaqahData['teacher_name'] ?? 'Tidak ada';
    final memberCount = _halaqahData['member_count'] ?? 0;
    final attRate = _halaqahData['attendance_rate'] ?? 0;
    final avgProgress = _halaqahData['avg_progress'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2), width: 3),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF0FDFA),
                  child: Text(
                    groupName.isNotEmpty ? groupName[0].toUpperCase() : 'H',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
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
                      groupName, 
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pengampu: $teacherName", 
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Jumlah Santri", 
                  "$memberCount Santri", 
                  Icons.people_rounded, 
                  const Color(0xFF6366F1), 
                  const Color(0xFFEEF2FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Kehadiran", 
                  "$attRate%", 
                  Icons.check_circle_outline_rounded, 
                  const Color(0xFF10B981), 
                  const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Rata Capaian", 
                  "$avgProgress Juz", 
                  Icons.stars_rounded, 
                  const Color(0xFF0D9488), 
                  const Color(0xFFF0FDFA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label, 
    String value, 
    IconData icon, 
    Color accentColor, 
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value, 
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        final studentName = student['full_name'] ?? 'Santri';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              studentName,
              style: GoogleFonts.poppins(
                fontSize: 12.5, 
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "Kelas: ${student['kelas'] ?? '-'} • Baseline: ${student['baseline_juz'] ?? 0} Juz", 
                style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${student['total_juz'] ?? 0} Juz", 
                      style: GoogleFonts.poppins(color: const Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Terakhir: ${student['last_setor_date'] ?? '-'}", 
                      style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
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
            const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat detail halaqah.', 
              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14), 
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
