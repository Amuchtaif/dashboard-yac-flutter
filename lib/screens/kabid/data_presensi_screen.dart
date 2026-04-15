import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';
import '../../models/staff_attendance_model.dart';
import '../../services/kabid_service.dart';

class DataPresensiScreen extends StatefulWidget {
  const DataPresensiScreen({super.key});

  @override
  State<DataPresensiScreen> createState() => _DataPresensiScreenState();
}

class _DataPresensiScreenState extends State<DataPresensiScreen> {
  final KabidService _kabidService = KabidService();
  List<StaffAttendance> _attendanceList = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await Future.wait([
        _kabidService.getStaffList(userId),
        _kabidService.getStaffAttendance(userId: userId, date: dateStr),
      ]);

      final List<Map<String, dynamic>> staffList =
          results[0] as List<Map<String, dynamic>>;
      final List<StaffAttendance> attendanceList =
          results[1] as List<StaffAttendance>;

      // Merge: Map all staff to their attendance if it exists, otherwise use default Alpha status
      List<StaffAttendance> mergedList =
          staffList.map((s) {
            final sId =
                s['id'] is int
                    ? s['id']
                    : int.tryParse(s['id']?.toString() ?? '0') ?? 0;
            return attendanceList.firstWhere(
              (a) => a.id == sId,
              orElse:
                  () => StaffAttendance(
                    id: sId,
                    name: s['name'] ?? '',
                    position: s['position_name'] ?? s['position'] ?? '',
                    photo: s['profile_photo'] ?? s['photo'],
                    time: '-',
                    status: 'Alpha',
                  ),
            );
          }).toList();

      setState(() {
        _attendanceList = mergedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildDateFilter(),
            if (!_isLoading && _attendanceList.isNotEmpty) _buildSummaryCards(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildAttendanceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Data Presensi Staf',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TANGGAL',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: const Text('Ganti'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFF6FF),
              foregroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    int hadir = _attendanceList.where((e) => e.status == 'Hadir').length;
    int terlambat =
        _attendanceList.where((e) => e.status == 'Terlambat').length;
    int izin =
        _attendanceList
            .where((e) => ['Izin', 'Sakit', 'Cuti'].contains(e.status))
            .length;
    int alpha =
        _attendanceList
            .where(
              (e) =>
                  ![
                    'Hadir',
                    'Terlambat',
                    'Izin',
                    'Sakit',
                    'Cuti',
                  ].contains(e.status),
            )
            .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _buildStatItem('HADIR', hadir, const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildStatItem('TELAT', terlambat, const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _buildStatItem('IZIN', izin, const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          _buildStatItem('ALPHA', alpha, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAttendanceList() {
    if (_attendanceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data presensi',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _attendanceList.length,
      itemBuilder: (context, index) {
        final item = _attendanceList[index];
        Color statusColor;
        switch (item.status) {
          case 'Hadir':
            statusColor = const Color(0xFF10B981);
            break;
          case 'Terlambat':
            statusColor = const Color(0xFFF59E0B);
            break;
          case 'Izin':
          case 'Sakit':
          case 'Cuti':
            statusColor = const Color(0xFF3B82F6);
            break;
          default:
            statusColor = const Color(0xFFEF4444); // Alpha/Unknown
        }

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
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: () {
                  final url = ApiConstants.getProfilePhotoUrl(item.photo);
                  return (url != null && url.isNotEmpty)
                      ? CachedNetworkImageProvider(url)
                      : null;
                }(),
                child:
                    (ApiConstants.getProfilePhotoUrl(item.photo) == null)
                        ? Text(
                          item.name.isNotEmpty ? item.name[0] : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 18,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      item.position,
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
                    item.time,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
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
}
