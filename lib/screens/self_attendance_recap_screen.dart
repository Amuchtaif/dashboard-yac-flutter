import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';

class SelfAttendanceRecapScreen extends StatefulWidget {
  const SelfAttendanceRecapScreen({super.key});

  @override
  State<SelfAttendanceRecapScreen> createState() => _SelfAttendanceRecapScreenState();
}

class _SelfAttendanceRecapScreenState extends State<SelfAttendanceRecapScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<AttendanceActivity> _allHistory = [];
  List<AttendanceActivity> _filteredHistory = [];
  bool _isLoading = true;
  DateTimeRange? _selectedRange;
  int _totalAttendance = 0;
  int _onTimeCount = 0;
  int _lateCount = 0;
  int _leftEarlyCount = 0;

  @override
  void initState() {
    super.initState();
    _calculateInitialRange();
    _fetchHistory();
  }

  void _calculateInitialRange() {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (now.day <= 25) {
      // Siklus: 26 bulan lalu s/d 25 bulan ini
      start = DateTime(now.year, now.month - 1, 26);
      end = DateTime(now.year, now.month, 25);
    } else {
      // Siklus: 26 bulan ini s/d 25 bulan depan
      start = DateTime(now.year, now.month, 26);
      end = DateTime(now.year, now.month + 1, 25);
    }

    _selectedRange = DateTimeRange(start: start, end: end);
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;
      
      if (userId != 0) {
        final data = await _attendanceService.getHistory(userId);
        setState(() {
          _allHistory = data;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat history: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedRange == null) {
      _filteredHistory = _allHistory;
      return;
    }

    setState(() {
      _filteredHistory = _allHistory.where((activity) {
        try {
          final date = DateTime.parse(activity.timestamp);
          // Normalize to date only for comparison if needed, but here we include the whole day
          return date.isAfter(_selectedRange!.start.subtract(const Duration(seconds: 1))) &&
                 date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
      
      // Sort by timestamp descending
      _filteredHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Calculate stats
      _totalAttendance = 0;
      _onTimeCount = 0;
      _lateCount = 0;
      _leftEarlyCount = 0;

      for (var activity in _filteredHistory) {
        final type = activity.type.toLowerCase();
        final status = activity.status.toLowerCase();

        // Entry is a Check-In (Masuk)
        if (type.contains('in') || type.contains('masuk')) {
          _totalAttendance++;
          
          if (status.contains('terlambat') || status.contains('telat')) {
            _lateCount++;
          } else {
            // Count as On Time if it's "Tepat Waktu", "Hadir", or if it's an IN without "Terlambat/Telat" status
            _onTimeCount++;
          }
        } 
        // Entry is a Check-Out (Pulang)
        else if (type.contains('out') || type.contains('pulang')) {
          if (status.contains('cepat')) {
            _leftEarlyCount++;
          }
        }
      }
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedRange) {
      setState(() {
        _selectedRange = picked;
      });
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rekap Kehadiran',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildRangeSelector(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : _filteredHistory.isEmpty 
                ? _buildEmptyState()
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    final start = DateFormat('dd MMM yyyy').format(_selectedRange!.start);
    final end = DateFormat('dd MMM yyyy').format(_selectedRange!.end);

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rentang Tanggal',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  Text(
                    '$start - $end',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Total Hadir', _totalAttendance.toString(), Icons.how_to_reg_rounded),
              _buildStatItem('Tepat Waktu', _onTimeCount.toString(), Icons.timer_rounded),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Terlambat', _lateCount.toString(), Icons.timer_off_rounded),
              _buildStatItem('Pulang Cepat', _leftEarlyCount.toString(), Icons.directions_run_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final activity = _filteredHistory[index];
        final bool isCheckIn = activity.type.toLowerCase().contains('in');
        
        DateTime? timestamp;
        try {
          timestamp = DateTime.parse(activity.timestamp);
        } catch (_) {}

        final dateStr = timestamp != null ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(timestamp) : activity.timestamp;
        final timeStr = timestamp != null ? DateFormat('HH:mm').format(timestamp) : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCheckIn ? const Color(0xFFEEF2FF) : const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                  color: isCheckIn ? const Color(0xFF4F46E5) : const Color(0xFFEA580C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (activity.status.isNotEmpty && activity.status != '-')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (activity.status.toLowerCase().contains('terlambat') || activity.status.toLowerCase().contains('telat'))
                          ? const Color(0xFFFEF2F2) 
                          : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activity.status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (activity.status.toLowerCase().contains('terlambat') || activity.status.toLowerCase().contains('telat'))
                            ? const Color(0xFFEF4444) 
                            : const Color(0xFF22C55E),
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data kehadiran',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
          Text(
            'Cobalah rentang tanggal lain',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}
