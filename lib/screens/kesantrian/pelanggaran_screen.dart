import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PelanggaranScreen extends StatefulWidget {
  const PelanggaranScreen({super.key});

  @override
  State<PelanggaranScreen> createState() => _PelanggaranScreenState();
}

class _PelanggaranScreenState extends State<PelanggaranScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSeverityCard(),
                    const SizedBox(height: 24),
                    _buildRecentViolations(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFE11D48),
        icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
        label: Text(
          'Catat Pelanggaran',
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
            'Kedisiplinan & Pelanggaran',
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

  Widget _buildSeverityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Ringan', '12'),
              _buildStatItem('Sedang', '5'),
              _buildStatItem('Berat', '1'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Total Bulan Ini: 18 Kasus',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentViolations() {
    final violations = [
      {
        'name': 'Udin Sedunia',
        'type': 'Bolos Sekolah',
        'severity': 'Berat',
        'date': '07 Mar 2026',
      },
      {
        'name': 'Rahmat Hidayat',
        'type': 'Terlambat Berjamaah',
        'severity': 'Ringan',
        'date': '06 Mar 2026',
      },
      {
        'name': 'Samsul Arifin',
        'type': 'Tidak Membawa Kitab',
        'severity': 'Ringan',
        'date': '06 Mar 2026',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PELANGGARAN TERAKHIR',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...violations.map((v) => _buildViolationCard(v)),
      ],
    );
  }

  Widget _buildViolationCard(Map<String, String> v) {
    Color severityColor =
        v['severity'] == 'Berat'
            ? Colors.red
            : (v['severity'] == 'Sedang' ? Colors.orange : Colors.blue);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v['severity']!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              Text(
                v['date']!,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            v['name']!,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            v['type']!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lihat Detail & Tindak Lanjut',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE11D48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
