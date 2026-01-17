import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dzikir_model.dart';
import '../services/dzikir_service.dart';

class DzikirDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String type;

  const DzikirDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  @override
  State<DzikirDetailScreen> createState() => _DzikirDetailScreenState();
}

class _DzikirDetailScreenState extends State<DzikirDetailScreen> {
  final DzikirService _dzikirService = DzikirService();
  late Future<List<DzikirModel>> _dzikirFuture;

  @override
  void initState() {
    super.initState();
    _dzikirFuture = _dzikirService.getDzikir(widget.type);
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
                    Column(
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          widget.subtitle.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.bookmark,
                        color: Color(0xFF1F2937),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: FutureBuilder<List<DzikirModel>>(
                  future: _dzikirFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada data dzikir',
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }

                    final dzikirList = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: dzikirList.length,
                      itemBuilder: (context, index) {
                        final item = dzikirList[index];
                        return _buildDzikirItem(item);
                      },
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

  Widget _buildDzikirItem(DzikirModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Title, Instruction, Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DZIKIR",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B83F6), // Blue Title
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.ulang,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              // Counter Button
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                  ),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "0",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      "COUNT",
                      style: GoogleFonts.poppins(
                        fontSize: 7,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Arabic Text
          Text(
            item.arab,
            textAlign: TextAlign.end,
            style: GoogleFonts.amiri(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 2.2,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Translation
          Text(
            item.indo,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF6B7280), // Gray 500
            ),
          ),
        ],
      ),
    );
  }
}
