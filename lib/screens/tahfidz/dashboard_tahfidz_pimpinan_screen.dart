import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/tahfidz_dashboard_provider.dart';
import '../../services/permission_service.dart';
import 'detail_halaqah_pimpinan_screen.dart';
import 'profil_santri_screen.dart';

class TahfidzDashboardScreen extends StatefulWidget {
  const TahfidzDashboardScreen({super.key});

  @override
  State<TahfidzDashboardScreen> createState() => _TahfidzDashboardScreenState();
}

class _TahfidzDashboardScreenState extends State<TahfidzDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _userId = 0;
  Timer? _refreshTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAndFetch();

    // Set up auto-refresh timer (every 60 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted && _userId > 0) {
        context.read<TahfidzDashboardProvider>().fetchDashboardData(_userId);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;
    if (mounted && _userId > 0) {
      context.read<TahfidzDashboardProvider>().fetchDashboardData(_userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TahfidzDashboardProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dashboard Monitoring Tahfidz',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchDashboardData(_userId),
        color: const Color(0xFF0D9488),
        child:
            provider.errorMessage != null
                ? _buildErrorState(provider.errorMessage!)
                : provider.isLoading && provider.summary.isEmpty
                ? _buildLoadingSkeleton()
                : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExecutiveSummaryGrid(provider),
                        const SizedBox(height: 24),
                        _buildAttendanceSection(provider),
                        const SizedBox(height: 24),
                        _buildDistributionSection(provider),
                        const SizedBox(height: 24),
                        _buildAttentionSection(provider),
                        const SizedBox(height: 24),
                        _buildComparisonAndRankingSection(provider),
                        const SizedBox(height: 24),
                        _buildDrillDownNavigation(provider),
                        const SizedBox(height: 24),
                        _buildMonitoringListsTab(provider),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildExecutiveSummaryGrid(TahfidzDashboardProvider provider) {
    final data = provider.summary;
    if (data.isEmpty) return const SizedBox();

    final int belumSetorCount = int.tryParse(data['santri_belum_setor']?.toString() ?? '0') ?? 0;

    final items = [
      {
        'title': 'Total Santri',
        'subtitle': 'Santri Aktif Tahfidz',
        'value': data['total_santri']?.toString() ?? '0',
        'color': const Color(0xFF4F46E5),
        'bgColor': const Color(0xFFEEF2FF),
        'borderColor': const Color(0xFFE2E8F0),
        'icon': Icons.groups_rounded,
      },
      {
        'title': 'Total Pengampu',
        'subtitle': 'Musyrif & Muallim',
        'value': data['total_pengampu']?.toString() ?? '0',
        'color': const Color(0xFF0D9488),
        'bgColor': const Color(0xFFF0FDFA),
        'borderColor': const Color(0xFFE2E8F0),
        'icon': Icons.record_voice_over_rounded,
      },
      {
        'title': 'Total Halaqoh',
        'subtitle': 'Kelompok Hafalan',
        'value': data['total_halaqah']?.toString() ?? '0',
        'color': const Color(0xFF7C3AED),
        'bgColor': const Color(0xFFF5F3FF),
        'borderColor': const Color(0xFFE2E8F0),
        'icon': Icons.hub_rounded,
      },
      {
        'title': 'Setoran Baru',
        'subtitle': 'Hafalan Hari Ini',
        'value': data['total_setoran_hari_ini']?.toString() ?? '0',
        'color': const Color(0xFFEA580C),
        'bgColor': const Color(0xFFFFF7ED),
        'borderColor': const Color(0xFFE2E8F0),
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': 'Murojaah Hari Ini',
        'subtitle': 'Pengulangan Hafalan',
        'value': data['total_murajaah_hari_ini']?.toString() ?? '0',
        'color': const Color(0xFF059669),
        'bgColor': const Color(0xFFECFDF5),
        'borderColor': const Color(0xFFE2E8F0),
        'icon': Icons.published_with_changes_rounded,
      },
      {
        'title': 'Belum Setor',
        'subtitle': 'Perlu Tindak Lanjut',
        'value': data['santri_belum_setor']?.toString() ?? '0',
        'color': const Color(0xFFDC2626),
        'bgColor': const Color(0xFFFEF2F2),
        'borderColor': belumSetorCount > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        'icon': Icons.assignment_late_rounded,
        'isWarning': belumSetorCount > 0,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.38,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Color accentColor = item['color'] as Color;
        final Color bgColor = item['bgColor'] as Color;
        final Color borderColor = item['borderColor'] as Color;
        final bool isWarning = item['isWarning'] == true;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: isWarning ? 1.5 : 1.0),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isWarning ? 0.08 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  if (isWarning)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "PERHATIAN",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['value'] as String,
                    style: GoogleFonts.poppins(
                      color: isWarning ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF334155),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceSection(TahfidzDashboardProvider provider) {
    final att = provider.attendance;
    if (att.isEmpty) return const SizedBox();

    final santri = att['santri'] ?? {};
    final pengampu = att['pengampu'] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kehadiran Hari Ini",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Santri",
            style: GoogleFonts.poppins(
              color: const Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildAttendanceRow([
            {
              'label': 'Hadir',
              'val': santri['Hadir'] ?? 0,
              'color': const Color(0xFF10B981),
            },
            {
              'label': 'Izin',
              'val': santri['Izin'] ?? 0,
              'color': const Color(0xFF3B82F6),
            },
            {
              'label': 'Sakit',
              'val': santri['Sakit'] ?? 0,
              'color': const Color(0xFFF59E0B),
            },
            {
              'label': 'Alfa',
              'val': santri['Alfa'] ?? 0,
              'color': const Color(0xFFEF4444),
            },
          ]),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),
          Text(
            "Pengampu",
            style: GoogleFonts.poppins(
              color: const Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildAttendanceRow([
            {
              'label': 'Hadir',
              'val': pengampu['Hadir'] ?? 0,
              'color': const Color(0xFF10B981),
            },
            {
              'label': 'Izin',
              'val': pengampu['Izin'] ?? 0,
              'color': const Color(0xFF3B82F6),
            },
            {
              'label': 'Sakit',
              'val': pengampu['Sakit'] ?? 0,
              'color': const Color(0xFFF59E0B),
            },
            {
              'label': 'Mangkir',
              'val': pengampu['Tidak Hadir'] ?? 0,
              'color': const Color(0xFFEF4444),
            },
            {
              'label': 'Belum Absen',
              'val': pengampu['Belum Absen'] ?? 0,
              'color': const Color(0xFF94A3B8),
            },
          ]),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(List<Map<String, dynamic>> items) {
    int total = items.fold(0, (sum, i) => sum + (i['val'] as int));

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children:
                  items.map((item) {
                    int val = item['val'] as int;
                    if (total == 0 || val == 0) return const SizedBox();
                    return Expanded(
                      flex: val,
                      child: Container(color: item['color'] as Color),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children:
              items.map((item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${item['label']}: ${item['val']}",
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDistributionSection(TahfidzDashboardProvider provider) {
    final dist = provider.distribution;
    if (dist.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Distribusi Tingkat Juz Santri",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children:
                dist.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value:
                                    entry.value > 0
                                        ? 0.6
                                        : 0.0, // static max placeholder
                                color: const Color(0xFF0D9488),
                                backgroundColor: Colors.transparent,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${entry.value} Santri",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(TahfidzDashboardProvider provider) {
    final list = provider.attentionList;
    if (list.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Santri Perlu Perhatian",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF991B1B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length > 3 ? 3 : list.length,
            itemBuilder: (context, index) {
              final student = list[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDetailProfileScreen(
                              studentId: student['id'],
                              studentData: student,
                            ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['full_name'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Halaqah: ${student['halaqah_name']} • Kelas: ${student['kelas']}",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          student['days_since_last_setor']?.toString().contains('Belum') == true
                              ? "⚠️ Belum Pernah Setor"
                              : "⚠️ ${student['days_since_last_setor']} hari",
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonAndRankingSection(TahfidzDashboardProvider provider) {
    return Column(
      children: [
        if (provider.comparison.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Perbandingan Unit",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      children: [
                        Text(
                          "Unit",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          "Santri",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Guru",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Setoran",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    ...provider.comparison.map((c) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              c['unit'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              c['student_count']?.toString() ?? '0',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1E293B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              c['teacher_count']?.toString() ?? '0',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1E293B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              "${c['total_memorized_juz_semester']} Juz",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D9488),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (provider.rankings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "10 Besar Capaian Halaqah",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      provider.rankings.length > 5
                          ? 5
                          : provider.rankings.length,
                  itemBuilder: (context, index) {
                    final rank = provider.rankings[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: const Color(0xFFE0F2FE),
                                child: Text(
                                  (index + 1).toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    color: const Color(0xFF0284C7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rank['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    rank['subtitle'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            rank['value'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDrillDownNavigation(TahfidzDashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fillter Kelas dan Halaqoh",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDrillItem(
                  "Langkah 1: Unit",
                  provider.filters['unit'].isEmpty
                      ? "Pilih Unit"
                      : provider.filters['unit'],
                  () async {
                    final units = await provider.fetchDrillDown(
                      _userId,
                      'unit',
                    );
                    if (mounted) {
                      _showDrillDownSelection("Pilih Unit", units, 'unit');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDrillItem(
                  "Langkah 2: Kelas",
                  provider.filters['kelas'].isEmpty
                      ? "Pilih Kelas"
                      : provider.filters['kelas'],
                  () async {
                    if (provider.filters['unit'].isEmpty) {
                      _showSnackBar("Pilih Unit terlebih dahulu");
                      return;
                    }
                    final classes = await provider.fetchDrillDown(
                      _userId,
                      'class',
                      parentId: provider.filters['unit'],
                    );
                    if (mounted) {
                      _showDrillDownSelection("Pilih Kelas", classes, 'kelas');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDrillItem(
                  "Langkah 3: Halaqah",
                  "Pilih Halaqah",
                  () async {
                    if (provider.filters['kelas'].isEmpty) {
                      _showSnackBar("Pilih Kelas terlebih dahulu");
                      return;
                    }
                    final halaqahs = await provider.fetchDrillDown(
                      _userId,
                      'halaqah',
                      parentId: provider.filters['kelas'],
                    );
                    if (mounted) {
                      _showDrillDownSelection(
                        "Pilih Halaqah",
                        halaqahs,
                        'halaqah_id',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          if (provider.filters['unit'].isNotEmpty ||
              provider.filters['kelas'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => provider.clearFilters(_userId),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 12,
                  color: Color(0xFFDC2626),
                ),
                label: Text(
                  "Reset Drill Down",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrillItem(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDrillDownSelection(
    String title,
    List<dynamic> items,
    String filterKey,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Data kosong",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(
                          item['name'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        onTap: () {
                          context.read<TahfidzDashboardProvider>().updateFilter(
                            filterKey,
                            item['id'],
                            _userId,
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonitoringListsTab(TahfidzDashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: const Color(0xFF0D9488),
              borderRadius: BorderRadius.circular(12),
            ),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: "Santri"),
              Tab(text: "Halaqoh"),
              Tab(text: "Log Live"),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSantriTab(provider),
              _buildHalaqahTab(provider),
              _buildLiveLogTab(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSantriTab(TahfidzDashboardProvider provider) {
    return FutureBuilder<List<dynamic>>(
      future: provider.fetchMonitoringList(_userId, 'santri'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              "Tidak ada data santri",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final st = list[index];
            final studentName = st['full_name'] ?? 'Santri';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Kelas: ${st['kelas']} • Halaqah: ${st['halaqah_name']}",
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${st['total_juz']} Juz",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0D9488),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => StudentDetailProfileScreen(
                            studentId: st['id'],
                            studentData: st,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHalaqahTab(TahfidzDashboardProvider provider) {
    return FutureBuilder<List<dynamic>>(
      future: provider.fetchMonitoringList(_userId, 'halaqah'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              "Tidak ada data halaqah",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final h = list[index];
            final groupName = h['group_name'] ?? 'Halaqah';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDFA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_work_rounded,
                    color: Color(0xFF0D9488),
                    size: 20,
                  ),
                ),
                title: Text(
                  groupName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Pengampu: ${h['teacher_name']} • ${h['member_count']} Santri",
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              DetailHalaqahPimpinanScreen(halaqahId: h['id']),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLiveLogTab(TahfidzDashboardProvider provider) {
    final list = provider.activities;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 40, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(
              "Belum ada aktivitas live hari ini",
              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final act = list[index];
        final actName = act['activity_name']?.toString() ?? 'Setoran';
        final String studentName = act['student_name']?.toString() ?? 'Santri';
        final String studentClass = act['student_class']?.toString() ?? '';
        final String teacherName = act['teacher_name']?.toString() ?? 'Pengampu';
        final String? hafalanDetail = act['hafalan_detail']?.toString();
        final String? hafalanMeta = act['hafalan_meta']?.toString();
        final String? notes = act['notes']?.toString();

        Color badgeColor = const Color(0xFFEA580C);
        Color badgeBg = const Color(0xFFFFF7ED);
        IconData badgeIcon = Icons.auto_stories_rounded;

        final String actLower = actName.toLowerCase();
        if (actLower.contains('murojaah')) {
          badgeColor = const Color(0xFF2563EB);
          badgeBg = const Color(0xFFEFF6FF);
          badgeIcon = Icons.published_with_changes_rounded;
        } else if (actLower.contains('tasmi') || actLower.contains('ujian')) {
          badgeColor = const Color(0xFF7C3AED);
          badgeBg = const Color(0xFFF5F3FF);
          badgeIcon = Icons.verified_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Student Name, Class & Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            studentName,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (studentClass.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              studentClass,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    act['date'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Activity Type Badge & Teacher
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          actName,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "oleh $teacherName",
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Detail Hafalan Box (Surah, Ayat, Baris, Juz)
              if (hafalanDetail != null && hafalanDetail.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hafalanDetail,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                            if (hafalanMeta != null && hafalanMeta.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                hafalanMeta,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF14B8A6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Catatan Box (if exists)
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Catatan: $notes",
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final provider = context.read<TahfidzDashboardProvider>();
    final allowedUnits = PermissionService().allowedTahfidzUnits;
    final List<String> availableUnits =
        allowedUnits.isNotEmpty
            ? ['Semua Unit', ...allowedUnits]
            : [
              'Semua Unit',
              'SDIT',
              'MTS',
              'MA',
              'MAHAD ALY',
              'TKIT',
              'PLAY GROUP',
              'TPA',
              'IDAD LUGOH',
            ];

    String selectedUnit = provider.filters['unit'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter Global Tahfidz",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Pilih Unit Sekolah:",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        availableUnits.map((u) {
                          final val = (u == 'Semua Unit') ? '' : u;
                          final isSelected = selectedUnit == val;
                          return ChoiceChip(
                            label: Text(
                              u,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF334155),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0D9488),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (selected) {
                              setModalState(() {
                                selectedUnit = selected ? val : '';
                              });
                              provider.updateFilter(
                                'unit',
                                selectedUnit,
                                _userId,
                              );
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.clearFilters(_userId);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Reset Filter",
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Terapkan",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF0D9488)),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.poppins(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
