import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KepulanganScreen extends StatefulWidget {
  const KepulanganScreen({super.key});

  @override
  State<KepulanganScreen> createState() => _KepulanganScreenState();
}

class _KepulanganScreenState extends State<KepulanganScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHomecomingBanner(),
                    const SizedBox(height: 24),
                    _buildActivePermissionsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.luggage_rounded, color: Colors.white),
        label: Text(
          'Izin Pulang',
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
            'Izin Kepulangan',
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

  Widget _buildHomecomingBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488),
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage(
            'https://www.transparenttextures.com/patterns/cubes.png',
          ),
          opacity: 0.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SANTRI DI RUMAH',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '42',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Santri sedang dalam masa perizinan.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.home_work_rounded, color: Colors.white, size: 60),
        ],
      ),
    );
  }

  Widget _buildActivePermissionsList() {
    final permissions = [
      {
        'name': 'Muhammad Al-Fatih',
        'reason': 'Acara Keluarga',
        'return': '09 Mar 2026',
        'status': 'Aktif',
      },
      {
        'name': 'Zaki Ahmad',
        'reason': 'Sakit',
        'return': 'Indefinite',
        'status': 'Aktif',
      },
      {
        'name': 'Faisal Malik',
        'reason': 'Urgent',
        'return': '08 Mar 2026',
        'status': 'Aktif',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IZIN AKTIF SAAT INI',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...permissions.map((p) => _buildPermissionCard(p)),
      ],
    );
  }

  Widget _buildPermissionCard(Map<String, String> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF0FDFA),
                child: Icon(Icons.person, color: Color(0xFF0D9488)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name']!,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      p['reason']!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
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
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p['status']!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_repeat_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Kembali: ${p['return']}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
