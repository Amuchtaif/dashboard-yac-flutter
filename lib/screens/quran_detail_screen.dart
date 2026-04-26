import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';
import '../providers/quran_provider.dart';

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

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<QuranProvider>(
          builder: (context, quranProvider, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Pengaturan Tampilan",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ukuran Font Arab",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B83F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${quranProvider.fontSize.toInt()} px",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B83F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: quranProvider.fontSize,
                    min: 24,
                    max: 48,
                    activeColor: const Color(0xFF2B83F6),
                    inactiveColor: const Color(0xFFE5E7EB),
                    onChanged: (val) => quranProvider.setFontSize(val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ukuran Font Latin",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B83F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${quranProvider.latinFontSize.toInt()} px",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B83F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: quranProvider.latinFontSize,
                    min: 10,
                    max: 24,
                    activeColor: const Color(0xFF2B83F6),
                    inactiveColor: const Color(0xFFE5E7EB),
                    onChanged: (val) => quranProvider.setLatinFontSize(val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ukuran Font Terjemahan",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B83F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${quranProvider.translationFontSize.toInt()} px",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B83F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: quranProvider.translationFontSize,
                    min: 10,
                    max: 24,
                    activeColor: const Color(0xFF2B83F6),
                    inactiveColor: const Color(0xFFE5E7EB),
                    onChanged: (val) => quranProvider.setTranslationFontSize(val),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quranProvider = Provider.of<QuranProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
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
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.surahNameLatin,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            "${widget.jumlahAyat} Ayat • ${widget.tempatTurun.toUpperCase()}",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSettings(context),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF1F2937),
                        size: 26,
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
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Gagal memuat data",
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                              TextButton(
                                onPressed: _fetchSurahDetail,
                                child: const Text("Coba Lagi"),
                              ),
                            ],
                          ),
                        )
                        : _buildBiasaView(quranProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiasaView(QuranProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _surahDetail?.ayat.length ?? 0,
      itemBuilder: (context, index) {
        final ayah = _surahDetail!.ayat[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (index == 0 && widget.surahNumber != 1 && widget.surahNumber != 9)
              _buildBismillah(),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAyahNumberBadge(ayah.nomorAyat),
                      Row(
                        children: [
                          _buildAyahAction(Icons.share_outlined, () {}),
                          const SizedBox(width: 8),
                          _buildAyahAction(Icons.play_circle_outline, () {}),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    ayah.teksArab,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.amiri(
                      fontSize: provider.fontSize,
                      fontWeight: FontWeight.bold,
                      height: 2.2,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ayah.teksLatin,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.notoSans(
                      fontSize: provider.latinFontSize,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF2B83F6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ayah.teksIndonesia,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: provider.translationFontSize,
                      height: 1.6,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAyahAction(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.grey[400], size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }





  Widget _buildBismillah({bool isClassic = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration:
          isClassic
              ? null
              : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
      child: Center(
        child: Text(
          "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
          style: GoogleFonts.amiri(
            fontSize: isClassic ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  Widget _buildAyahNumberBadge(int number) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [const Color(0xFF2B83F6), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B83F6).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        "$number",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

