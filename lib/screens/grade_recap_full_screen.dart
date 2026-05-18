import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradeRecapFullScreen extends StatefulWidget {
  final List<Map<String, dynamic>> assessments;
  const GradeRecapFullScreen({super.key, required this.assessments});

  @override
  State<GradeRecapFullScreen> createState() => _GradeRecapFullScreenState();
}

class _GradeRecapFullScreenState extends State<GradeRecapFullScreen> {
  String? _selectedClass;

  final List<Color> _palette = [
    const Color(0xFF7C3AED),
    const Color(0xFF2563EB),
    const Color(0xFF059669),
    const Color(0xFFD97706),
    const Color(0xFFDC2626),
    const Color(0xFF0891B2),
  ];

  List<String> get _classes {
    final s = <String>{};
    for (final a in widget.assessments) {
      final c = (a['class_name'] ?? '').toString();
      if (c.isNotEmpty) s.add(c);
    }
    return s.toList()..sort();
  }

  List<Map<String, dynamic>> get _filtered =>
      _selectedClass == null
          ? widget.assessments
          : widget.assessments
              .where(
                (a) => (a['class_name'] ?? '').toString() == _selectedClass,
              )
              .toList();

  Map<String, List<Map<String, dynamic>>> get _byType {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final a in _filtered) {
      final t =
          (a['assessment_type_name'] ??
                  a['type_name'] ??
                  a['assessment_type'] ??
                  'Lainnya')
              .toString();
      m.putIfAbsent(t, () => []).add(a);
    }
    return m;
  }

  double _avg(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return 0;
    return list
            .map(
              (e) => double.tryParse(e['avg_score']?.toString() ?? '0') ?? 0.0,
            )
            .reduce((a, b) => a + b) /
        list.length;
  }

  Color _scoreColor(double v) {
    if (v >= 80) return const Color(0xFF059669);
    if (v >= 65) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final overallAvg = _avg(filtered);
    final byType = _byType;
    final classes = _classes;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // ── Modern AppBar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: Colors.white,
            leadingWidth: 70,
            leading: Center(
              child: Material(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Rekap Nilai',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),

          // ── Sticky Class Selector ──────────────────────────────────────────
          if (classes.length > 1)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyClassSelectorDelegate(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 60,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildTabItem(
                              label: 'Semua Kelas',
                              value: null,
                              icon: Icons.grid_view_rounded,
                            ),
                            ...classes.map(
                              (c) => _buildTabItem(
                                label: c,
                                value: c,
                                icon: Icons.school_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Overall summary ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildOverallCard(overallAvg, filtered.length),
          ),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PER KATEGORI PENILAIAN',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Per-type
          byType.isEmpty
              ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Tidak ada data',
                    style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                  ),
                ),
              )
              : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final entry = byType.entries.toList()[i];
                    return _buildTypeCard(
                      entry.key,
                      entry.value,
                      _palette[i % _palette.length],
                    );
                  }, childCount: byType.length),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required String? value,
    required IconData icon,
  }) {
    final sel = _selectedClass == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedClass = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color:
              sel
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? const Color(0xFF7C3AED) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: sel ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                color: sel ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallCard(double avg, int count) {
    final progress = (avg / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata Keseluruhan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedClass ?? 'Semua Kelas',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder:
                (_, c) => Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      height: 8,
                      width: c.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat(Icons.assignment_outlined, '$count Penilaian'),
              _miniStat(Icons.people_outline, '${_byType.length} Kategori'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    String typeName,
    List<Map<String, dynamic>> items,
    Color color,
  ) {
    final avg = _avg(items);
    final progress = (avg / 100).clamp(0.0, 1.0);
    final sc = _scoreColor(avg);

    final Map<String, List<Map<String, dynamic>>> byClass = {};
    for (final a in items) {
      final cls = (a['class_name'] ?? '-').toString();
      byClass.putIfAbsent(cls, () => []).add(a);
    }
    final showClassBreakdown = _selectedClass == null && byClass.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _getCategoryIcon(typeName),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typeName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.layers_outlined, size: 12, color: const Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                '${items.length} Penilaian',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          avg.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: sc,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (_, c) => Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        height: 10,
                        width: c.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Breakdown
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: showClassBreakdown
                ? _buildClassBreakdown(byClass, color)
                : _buildItemList(items, color),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('ujian') || t.contains('exam')) return Icons.assignment_rounded;
    if (t.contains('tugas') || t.contains('quiz')) return Icons.quiz_rounded;
    if (t.contains('ulangan')) return Icons.menu_book_rounded;
    if (t.contains('praktek')) return Icons.science_rounded;
    return Icons.auto_awesome_mosaic_rounded;
  }

  Widget _buildClassBreakdown(
    Map<String, List<Map<String, dynamic>>> byClass,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Distribusi Kelas',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(Icons.info_outline_rounded, size: 14, color: const Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 16),
          ...byClass.entries.map((entry) {
            final clsAvg = _avg(entry.value);
            final clsProg = (clsAvg / 100).clamp(0.0, 1.0);
            final sc = _scoreColor(clsAvg);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(Icons.class_rounded, size: 16, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${entry.value.length} Penilaian',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        clsAvg.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: sc,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (_, c) => Stack(
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: 5,
                          width: c.maxWidth * clsProg,
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemList(List<Map<String, dynamic>> items, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Penilaian',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final itemAvg = double.tryParse(item['avg_score']?.toString() ?? '0') ?? 0.0;
            final sc = _scoreColor(itemAvg);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['subject_name']?.toString() ?? '-',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item['class_name'] ?? '-'} · ${item['student_count'] ?? 0} Siswa',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        itemAvg.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: sc,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StickyClassSelectorDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyClassSelectorDelegate({required this.child});

  @override
  double get minExtent => 61;
  @override
  double get maxExtent => 61;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          if (overlapsContent)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyClassSelectorDelegate oldDelegate) {
    return true;
  }
}
