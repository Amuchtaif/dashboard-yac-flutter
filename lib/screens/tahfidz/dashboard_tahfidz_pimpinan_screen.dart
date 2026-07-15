import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/tahfidz_dashboard_provider.dart';
import 'detail_halaqah_pimpinan_screen.dart';
import 'profil_santri_screen.dart';

class TahfidzDashboardScreen extends StatefulWidget {
  const TahfidzDashboardScreen({super.key});

  @override
  State<TahfidzDashboardScreen> createState() => _TahfidzDashboardScreenState();
}

class _TahfidzDashboardScreenState extends State<TahfidzDashboardScreen> with SingleTickerProviderStateMixin {
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
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
        child: provider.errorMessage != null
            ? _buildErrorState(provider.errorMessage!)
            : provider.isLoading && provider.summary.isEmpty
                ? _buildLoadingSkeleton()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExecutiveSummaryGrid(provider),
                          const SizedBox(height: 24),
                          _buildProgressSection(provider),
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

    final items = [
      {'title': 'Total Santri', 'value': data['total_santri']?.toString() ?? '0', 'color': const Color(0xFF2563EB), 'icon': Icons.people},
      {'title': 'Total Pengampu', 'value': data['total_pengampu']?.toString() ?? '0', 'color': const Color(0xFF0D9488), 'icon': Icons.person_pin},
      {'title': 'Total Halaqoh', 'value': data['total_halaqah']?.toString() ?? '0', 'color': const Color(0xFF7C3AED), 'icon': Icons.group_work},
      {'title': 'Setoran Baru', 'value': data['total_setoran_hari_ini']?.toString() ?? '0', 'color': const Color(0xFFEA580C), 'icon': Icons.library_books},
      {'title': 'Murojaah Hari Ini', 'value': data['total_murajaah_hari_ini']?.toString() ?? '0', 'color': const Color(0xFF059669), 'icon': Icons.repeat},
      {'title': 'Belum Setor', 'value': data['santri_belum_setor']?.toString() ?? '0', 'color': const Color(0xFFDC2626), 'icon': Icons.warning_amber_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  Icon(item['icon'] as IconData, color: item['color'] as Color, size: 16),
                ],
              ),
              Text(
                item['value'] as String,
                style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(TahfidzDashboardProvider provider) {
    final prog = provider.progress;
    if (prog.isEmpty) return const SizedBox();

    final double percentage = (prog['progress_percentage'] as num?)?.toDouble() ?? 0.0;
    final double semesterTarget = (prog['target_semester_juz'] as num?)?.toDouble() ?? 0.0;
    final double yearlyTarget = (prog['target_tahunan_juz'] as num?)?.toDouble() ?? 0.0;
    final double achieved = (prog['total_hafalan_baru_juz'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Capaian & Target Hafalan", style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Capaian", style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10)),
                  Text("$achieved Juz", style: GoogleFonts.poppins(color: const Color(0xFF0D9488), fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(10)),
                child: Text("$percentage%", style: GoogleFonts.poppins(color: const Color(0xFF0F766E), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (percentage / 100.0).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF0D9488),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTargetItem("Target Semester", "$semesterTarget Juz"),
              _buildTargetItem("Target Tahunan", "$yearlyTarget Juz"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Kehadiran Hari Ini", style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text("Santri", style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildAttendanceRow([
            {'label': 'Hadir', 'val': santri['Hadir'] ?? 0, 'color': const Color(0xFF10B981)},
            {'label': 'Izin', 'val': santri['Izin'] ?? 0, 'color': const Color(0xFF3B82F6)},
            {'label': 'Sakit', 'val': santri['Sakit'] ?? 0, 'color': const Color(0xFFF59E0B)},
            {'label': 'Alfa', 'val': santri['Alfa'] ?? 0, 'color': const Color(0xFFEF4444)},
          ]),
          const SizedBox(height: 16),
          Text("Pengampu", style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildAttendanceRow([
            {'label': 'Hadir', 'val': pengampu['Hadir'] ?? 0, 'color': const Color(0xFF10B981)},
            {'label': 'Izin', 'val': pengampu['Izin'] ?? 0, 'color': const Color(0xFF3B82F6)},
            {'label': 'Sakit', 'val': pengampu['Sakit'] ?? 0, 'color': const Color(0xFFF59E0B)},
            {'label': 'Mangkir', 'val': pengampu['Tidak Hadir'] ?? 0, 'color': const Color(0xFFEF4444)},
            {'label': 'Belum Absen', 'val': pengampu['Belum Absen'] ?? 0, 'color': const Color(0xFF94A3B8)},
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
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 12,
            child: Row(
              children: items.map((item) {
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: items.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  "${item['label']}: ${item['val']}",
                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B)),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Distribusi Tingkat Juz Santri", style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Column(
            children: dist.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(entry.key, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B))),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value > 0 ? 0.6 : 0.0, // static max placeholder
                          color: const Color(0xFF0D9488),
                          backgroundColor: const Color(0xFFF1F5F9),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text("${entry.value} Santri", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
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
              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Text(
                "Santri Perlu Perhatian",
                style: GoogleFonts.poppins(color: const Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.bold),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFCA5A5))),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDetailProfileScreen(
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
                            Text(student['full_name'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            Text("Halaqah: ${student['halaqah_name']} • Kelas: ${student['kelas']}", style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("⚠️ Tidak setor ${student['days_since_last_setor']} hari", style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFFDC2626), fontWeight: FontWeight.bold)),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Perbandingan Unit", style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
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
                        Text("Unit", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                        Text("Santri", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
                        Text("Guru", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
                        Text("Setoran", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
                      ],
                    ),
                    ...provider.comparison.map((c) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(c['unit'] ?? '', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(c['student_count']?.toString() ?? '0', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF1E293B)), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(c['teacher_count']?.toString() ?? '0', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF1E293B)), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text("${c['total_memorized_juz_semester']} Juz", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488)), textAlign: TextAlign.center),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("10 Besar Capaian Halaqah", style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.rankings.length > 5 ? 5 : provider.rankings.length,
                  itemBuilder: (context, index) {
                    final rank = provider.rankings[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: const Color(0xFFCCFBF1),
                                child: Text((index + 1).toString(), style: GoogleFonts.poppins(fontSize: 8, color: const Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rank['name'] ?? '', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                  Text(rank['subtitle'] ?? '', style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                          Text(rank['value'] ?? '', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Drill Down Menu Bertingkat", style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDrillItem("Langkah 1: Unit", provider.filters['unit'].isEmpty ? "Pilih Unit" : provider.filters['unit'], () async {
                  final units = await provider.fetchDrillDown(_userId, 'unit');
                  if (mounted) _showDrillDownSelection("Pilih Unit", units, 'unit');
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDrillItem("Langkah 2: Kelas", provider.filters['kelas'].isEmpty ? "Pilih Kelas" : provider.filters['kelas'], () async {
                  if (provider.filters['unit'].isEmpty) {
                    _showSnackBar("Pilih Unit terlebih dahulu");
                    return;
                  }
                  final classes = await provider.fetchDrillDown(_userId, 'class', parentId: provider.filters['unit']);
                  if (mounted) _showDrillDownSelection("Pilih Kelas", classes, 'kelas');
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDrillItem("Langkah 3: Halaqah", "Pilih Halaqah", () async {
                  if (provider.filters['kelas'].isEmpty) {
                    _showSnackBar("Pilih Kelas terlebih dahulu");
                    return;
                  }
                  final halaqahs = await provider.fetchDrillDown(_userId, 'halaqah', parentId: provider.filters['kelas']);
                  if (mounted) _showDrillDownSelection("Pilih Halaqah", halaqahs, 'halaqah_id');
                }),
              ),
            ],
          ),
          if (provider.filters['unit'].isNotEmpty || provider.filters['kelas'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => provider.clearFilters(_userId),
                child: Text("Reset Drill Down", style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFDC2626), fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 8, color: const Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _showDrillDownSelection(String title, List<dynamic> items, String filterKey) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("Data kosong", style: GoogleFonts.poppins(color: Colors.grey)),
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
                        title: Text(item['name'] ?? '', style: GoogleFonts.poppins(fontSize: 12)),
                        onTap: () {
                          context.read<TahfidzDashboardProvider>().updateFilter(filterKey, item['id'], _userId);
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
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0D9488),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0D9488),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(text: "Santri"),
            Tab(text: "Halaqoh"),
            Tab(text: "Log Live"),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 350,
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
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(child: Text("Tidak ada data santri", style: GoogleFonts.poppins(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final st = list[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(st['full_name'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text("Kelas: ${st['kelas']} • Halaqah: ${st['halaqah_name']}", style: GoogleFonts.poppins(fontSize: 10)),
                trailing: Text("${st['total_juz']} Juz", style: GoogleFonts.poppins(color: const Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 12)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentDetailProfileScreen(
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
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(child: Text("Tidak ada data halaqah", style: GoogleFonts.poppins(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final h = list[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(h['group_name'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text("Ustadz: ${h['teacher_name']} • ${h['member_count']} Santri", style: GoogleFonts.poppins(fontSize: 10)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailHalaqahPimpinanScreen(halaqahId: h['id']),
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
      return Center(child: Text("Belum ada aktivitas live hari ini", style: GoogleFonts.poppins(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final act = list[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFCCFBF1),
              child: Icon(Icons.sync_alt, color: const Color(0xFF0F766E), size: 16),
            ),
            title: Text(act['student_name'] ?? '', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
            subtitle: Text("${act['activity_name']} oleh ${act['teacher_name']}\nCatatan: ${act['notes'] ?? '-'}", style: GoogleFonts.poppins(fontSize: 9)),
            trailing: Text(act['date'] ?? '', style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey)),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final provider = context.read<TahfidzDashboardProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Filter Global Tahfidz", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.clearFilters(_userId);
                            Navigator.pop(context);
                          },
                          child: Text("Reset Filter", style: GoogleFonts.poppins(color: Colors.red)),
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
    return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
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
            Text(message, style: GoogleFonts.poppins(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
