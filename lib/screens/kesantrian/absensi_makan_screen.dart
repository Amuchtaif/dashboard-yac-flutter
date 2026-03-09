import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AbsensiMakanScreen extends StatefulWidget {
  const AbsensiMakanScreen({super.key});

  @override
  State<AbsensiMakanScreen> createState() => _AbsensiMakanScreenState();
}

class _AbsensiMakanScreenState extends State<AbsensiMakanScreen> {
  String _selectedMeal = 'Makan Siang';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildMealTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatsBanner(),
                    const SizedBox(height: 24),
                    _buildRecentScanList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFF97316),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text(
          'Scan Makan',
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
            'Absensi Makan',
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

  Widget _buildMealTabs() {
    final meals = ['Makan Pagi', 'Makan Siang', 'Makan Malam'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: meals.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedMeal == meals[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedMeal = meals[index]),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF97316) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFFF97316)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    meals[index],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SANTRI SUDAH MAKAN',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '285',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SISA JATAH',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '65',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScanList() {
    final recent = [
      {'name': 'Zaidan Al-Farabi', 'time': '12:30', 'status': 'Hadir'},
      {'name': 'Fatih Pratama', 'time': '12:28', 'status': 'Hadir'},
      {'name': 'Ihsan Kamil', 'time': '12:25', 'status': 'Hadir'},
      {'name': 'Rizky Ramadhan', 'time': '12:20', 'status': 'Hadir'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANTRIAN TERAKHIR',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...recent.map((s) => _buildRecentItem(s)),
      ],
    );
  }

  Widget _buildRecentItem(Map<String, String> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF7ED),
            child: const Icon(Icons.person, color: Color(0xFFF97316), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['name']!,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Pukul: ${s['time']}',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
