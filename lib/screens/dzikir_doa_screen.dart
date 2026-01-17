import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dzikir_detail_screen.dart';

class DzikirDoaScreen extends StatelessWidget {
  const DzikirDoaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 30,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE3EEFF), Color(0xFFF3F6FF)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF1F2937),
                        size: 24,
                      ),
                    ),
                    Text(
                      "Dzikir & Doa",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.search,
                        color: Color(0xFF1F2937),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Dzikir List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDzikirCard(
                      context,
                      title: "Dzikir Pagi",
                      subtitle: "Sunnah Nabi",
                      icon: Icons.wb_sunny_outlined,
                      color: Colors.blueAccent,
                      bgColor: const Color(0xFFE3EEFF),
                      type: 'pagi',
                    ),
                    _buildDzikirCard(
                      context,
                      title: "Dzikir Petang",
                      subtitle: "Sunnah Nabi",
                      icon: Icons.nightlight_round,
                      color: Colors.orangeAccent,
                      bgColor: const Color(0xFFFFF4E3),
                      type: 'sore',
                    ),
                    _buildDzikirCard(
                      context,
                      title: "Dzikir Setelah Shalat",
                      subtitle: "Fardhu & Sunnah",
                      icon:
                          Icons
                              .settings_suggest_outlined, // Placeholder for geometric icon
                      color: Colors.green,
                      bgColor: const Color(0xFFE3FFE9),
                      type: 'solat',
                    ),
                    _buildDzikirCard(
                      context,
                      title: "Dzikir Sebelum Tidur",
                      subtitle: "Perlindungan Malam",
                      icon: Icons.bedtime_outlined,
                      color: Colors.deepPurpleAccent,
                      bgColor: const Color(0xFFEDE3FF),
                      type: '', // No API type yet
                    ),
                    _buildDzikirCard(
                      context,
                      title: "Doa Harian",
                      subtitle: "Mustajab & Pilihan",
                      icon: Icons.book_outlined,
                      color: Colors.amber[700]!,
                      bgColor: const Color(0xFFFFF8E1),
                      type: '', // No API type yet
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDzikirCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (type.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fitur belum tersedia")),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DzikirDetailScreen(
                      title: title,
                      subtitle: subtitle,
                      type: type,
                    ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[300],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
