import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';

class QuranDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahNameLatin;
  final String surahNameArabic;
  final int jumlahAyat;
  final String tempatTurun;

  const QuranDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahNameLatin,
    required this.surahNameArabic,
    required this.jumlahAyat,
    required this.tempatTurun,
  });

  @override
  State<QuranDetailScreen> createState() => _QuranDetailScreenState();
}

class _QuranDetailScreenState extends State<QuranDetailScreen> {
  final QuranService _quranService = QuranService();
  bool _isLoading = true;
  String _errorMessage = '';
  Surah? _surahDetail;

  @override
  void initState() {
    super.initState();
    _fetchSurahDetail();
  }

  Future<void> _fetchSurahDetail() async {
    try {
      final surah = await _quranService.getSurahDetail(widget.surahNumber);
      setState(() {
        _surahDetail = surah;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
              // Custom Header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                    Column(
                      children: [
                        Text(
                          widget.surahNameLatin,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          "${widget.jumlahAyat} Ayat • ${widget.tempatTurun.toUpperCase()}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {}, // Bookmark placeholder
                      icon: const Icon(
                        Icons.bookmark_border,
                        color: Color(0xFF1F2937),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Gagal memuat data",
                                style: GoogleFonts.poppins(),
                              ),
                              TextButton(
                                onPressed: _fetchSurahDetail,
                                child: const Text("Coba Lagi"),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _surahDetail?.ayat.length ?? 0,
                          itemBuilder: (context, index) {
                            final ayah = _surahDetail!.ayat[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bismillah Header for first Ayah (except at-Taubah)
                                if (index == 0 &&
                                    widget.surahNumber != 1 &&
                                    widget.surahNumber != 9)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                                        style: GoogleFonts.amiri(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Ayah Card
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Top Actions Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF2B83F6,
                                                ).withValues(alpha: 0.3),
                                              ),
                                              color: const Color(0xFFF1F6FF),
                                            ),
                                            child: Text(
                                              "${ayah.nomorAyat}",
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF2B83F6),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed:
                                                    () {}, // Share Function
                                                icon: Icon(
                                                  Icons.share_outlined,
                                                  color: Colors.grey[400],
                                                  size: 20,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                              const SizedBox(width: 16),
                                              IconButton(
                                                onPressed: () {}, // Play Audio
                                                icon: Icon(
                                                  Icons.play_circle_outline,
                                                  color: Colors.grey[400],
                                                  size: 20,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Arabic Text
                                      Text(
                                        ayah.teksArab,
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.amiri(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          height:
                                              2.2, // Good spacing for Arabic
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Translation
                                      Text(
                                        ayah.teksIndonesia,
                                        textAlign: TextAlign.left,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          height: 1.6,
                                          color: const Color(
                                            0xFF6B7280,
                                          ), // Gray 500
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
