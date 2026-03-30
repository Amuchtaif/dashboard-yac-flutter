import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';
import '../../services/kabid_service.dart';

class DetailRekapAbsensiScreen extends StatefulWidget {
  final String month;
  final String percentage;

  const DetailRekapAbsensiScreen({
    super.key,
    required this.month,
    required this.percentage,
  });

  @override
  State<DetailRekapAbsensiScreen> createState() =>
      _DetailRekapAbsensiScreenState();
}

class _DetailRekapAbsensiScreenState extends State<DetailRekapAbsensiScreen> {
  final KabidService _kabidService = KabidService();
  List<Map<String, dynamic>> _staffStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      final results = await _kabidService.getStaffAttendanceMonthDetail(
        userId: userId,
        month: widget.month,
      );

      setState(() {
        _staffStats = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat detail: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black,
          ),
        ),
        title: Text(
          'Detail Performa',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSummaryCard(),
                    const SizedBox(height: 32),
                    _buildStaffDetailHeader(),
                    const SizedBox(height: 16),
                    _buildStaffDetailList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildMonthSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.month,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value:
                      double.tryParse(widget.percentage.replaceAll('%', ''))! /
                      100,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: Colors.orange,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                widget.percentage,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Persentase Kehadiran',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDetailHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PERFORMA INDIVIDU',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        Text(
          '${_staffStats.length} Karyawan',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffDetailList() {
    if (_staffStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Tidak ada data staf',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _staffStats.length,
      itemBuilder: (context, index) {
        final item = _staffStats[index];
        final photoUrl = ApiConstants.getProfilePhotoUrl(item['photo']);

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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage:
                        (photoUrl != null) ? CachedNetworkImageProvider(photoUrl) : null,
                    child:
                        (photoUrl == null)
                            ? Text(
                              (item['name'] as String).isNotEmpty
                                  ? (item['name'] as String)[0]
                                  : '?',
                              style: const TextStyle(fontSize: 12),
                            )
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const Icon(Icons.stars, color: Colors.amber, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat(
                    'Hadir',
                    '${item['hadir']}',
                    const Color(0xFF10B981),
                  ),
                  _buildMiniStat(
                    'Telat',
                    '${item['telat']}',
                    const Color(0xFFF59E0B),
                  ),
                  _buildMiniStat(
                    'Izin/Sakit',
                    '${item['absent']}',
                    const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
