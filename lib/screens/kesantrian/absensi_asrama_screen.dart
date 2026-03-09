import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AbsensiAsramaScreen extends StatefulWidget {
  const AbsensiAsramaScreen({super.key});

  @override
  State<AbsensiAsramaScreen> createState() => _AbsensiAsramaScreenState();
}

class _AbsensiAsramaScreenState extends State<AbsensiAsramaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildRoomList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text(
          'Scan Santri',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Absensi Asrama',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kehadiran Malam Ini',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '342 / 350',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '97.7%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 0.977,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    final rooms = [
      {'name': 'Gedung A - Lt 1', 'count': '40/40', 'status': 'Lengkap'},
      {'name': 'Gedung A - Lt 2', 'count': '38/40', 'status': 'Belum'},
      {'name': 'Gedung B - Lt 1', 'count': '40/40', 'status': 'Lengkap'},
      {'name': 'Gedung B - Lt 2', 'count': '35/40', 'status': 'Belum'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'REKAP PER LANTAI',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rooms.map((room) => _buildRoomCard(room)),
      ],
    );
  }

  Widget _buildRoomCard(Map<String, String> room) {
    bool isComplete = room['status'] == 'Lengkap';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isComplete
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.check_circle_rounded : Icons.pending_rounded,
              color:
                  isComplete
                      ? const Color(0xFF166534)
                      : const Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['name']!,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Status: ${room['status']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            room['count']!,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isComplete ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
