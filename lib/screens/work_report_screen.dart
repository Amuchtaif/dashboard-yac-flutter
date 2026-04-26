import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/work_report_service.dart';
import 'input_work_report_screen.dart';

class WorkReportScreen extends StatefulWidget {
  const WorkReportScreen({super.key});

  @override
  State<WorkReportScreen> createState() => _WorkReportScreenState();
}

class _WorkReportScreenState extends State<WorkReportScreen>
    with TickerProviderStateMixin {
  final WorkReportService _reportService = WorkReportService();
  late TabController _tabController;
  bool _isLoading = true;
  int _positionLevel = 5;
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _myReports = [];
  List<Map<String, dynamic>> _staffReports = [];

  @override
  void initState() {
    super.initState();
    // Initialize with level 5 (default) or attempt to get it if possible?
    // For now, use the default _positionLevel (5)
    _tabController = TabController(length: _getTabLength(_positionLevel), vsync: this);
    _checkManagerStatus();
    _fetchData();
  }

  int _getTabLength(int level) {
    int count = 0;
    if (level != 1) count++;
    if (level <= 3) count++;
    return count > 0 ? count : 1;
  }

  Future<void> _checkManagerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('positionLevel') ?? 5;
    if (mounted) {
      setState(() {
        _positionLevel = level;
        int tabLength = _getTabLength(level);
        if (_tabController.length != tabLength) {
          _tabController.dispose();
          _tabController = TabController(length: tabLength, vsync: this);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final myReports = await _reportService.getMyReports();
      List<Map<String, dynamic>> staffReports = [];
      if (_positionLevel <= 3) {
        staffReports = await _reportService.getStaffReports();
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = (prefs.get('user_id') ?? prefs.get('userId'))?.toString();

      if (mounted) {
        setState(() {
          _myReports = myReports.where((r) {
            final date = DateTime.parse(r['report_date']);
            return date.month == _selectedMonth.month && date.year == _selectedMonth.year;
          }).toList();
          
          // Filter out user's own reports from staff reports if they exist there
          List<Map<String, dynamic>> filteredStaff = staffReports;
          if (userId != null) {
            filteredStaff = staffReports.where((r) => r['user_id']?.toString() != userId).toList();
          }
          
          _staffReports = filteredStaff.where((r) {
            final date = DateTime.parse(r['report_date']);
            return date.month == _selectedMonth.month && date.year == _selectedMonth.year;
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Laporan Kerja',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF7C3AED),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            if (_positionLevel != 1) const Tab(text: 'Laporan Saya'),
            if (_positionLevel <= 3) const Tab(text: 'Laporan'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      if (_positionLevel != 1) _buildReportList(_myReports, isMyReport: true),
                      if (_positionLevel <= 3) _buildReportList(_staffReports, isMyReport: false),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _positionLevel == 1 ? null : FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputWorkReportScreen()),
          );
          if (result == true) {
            _fetchData();
          }
        },
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Buat Laporan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    bool isCurrentMonth = _selectedMonth.month == DateTime.now().month && 
                         _selectedMonth.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPickerButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                _fetchData();
              });
            },
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDatePickerMode: DatePickerMode.year,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF7C3AED),
                          onPrimary: Colors.white,
                          onSurface: Color(0xFF1E293B),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedMonth = DateTime(picked.year, picked.month);
                    _fetchData();
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  if (!isCurrentMonth)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime.now();
                            _fetchData();
                          });
                        },
                        child: Text(
                          'Kembali ke Bulan Ini',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildPickerButton(
            icon: Icons.chevron_right_rounded,
            onPressed: isCurrentMonth
                ? null
                : () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                      _fetchData();
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: onPressed == null 
                ? Colors.grey.shade50 
                : const Color(0xFF7C3AED).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: onPressed == null ? Colors.grey.shade300 : const Color(0xFF7C3AED),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildReportList(List<Map<String, dynamic>> reports, {required bool isMyReport}) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada laporan',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report, isMyReport);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isMyReport) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report['category'] ?? 'Kegiatan',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.parse(report['report_date'])),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report['title'] ?? '-',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report['description'] ?? '-',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isMyReport) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    child: Text(
                      (report['employee_name'] ?? 'S')[0],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    report['employee_name'] ?? '-',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    report['unit_name'] ?? report['division_name'] ?? '-',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
