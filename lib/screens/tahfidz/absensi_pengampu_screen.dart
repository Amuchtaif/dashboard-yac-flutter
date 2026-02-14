import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/tahfidz_service.dart';

class AbsensiPengampuScreen extends StatefulWidget {
  const AbsensiPengampuScreen({super.key});

  @override
  State<AbsensiPengampuScreen> createState() => _AbsensiPengampuScreenState();
}

class _AbsensiPengampuScreenState extends State<AbsensiPengampuScreen>
    with SingleTickerProviderStateMixin {
  final TahfidzService _service = TahfidzService();
  late TabController _tabController;

  // Tab 1 - Kehadiran
  bool _isLoadingKehadiran = true;
  List<dynamic> _attendanceList = [];
  DateTime _selectedDate = DateTime.now();

  // Tab 2 - Approval
  bool _isLoadingApproval = true;
  List<dynamic> _pendingList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchKehadiranData();
    _fetchPendingAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========= TAB 1: Kehadiran =========
  Future<void> _fetchKehadiranData() async {
    setState(() => _isLoadingKehadiran = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final history = await _service.getTeacherAttendanceHistory(date: dateStr);
      if (mounted) {
        setState(() => _attendanceList = history);
      }
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
    } finally {
      if (mounted) setState(() => _isLoadingKehadiran = false);
    }
  }

  // ========= TAB 2: Approval =========
  Future<void> _fetchPendingAttendance() async {
    setState(() => _isLoadingApproval = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final history = await _service.getTeacherAttendanceHistory(date: dateStr);

      setState(() {
        _pendingList =
            history.where((record) {
              final isVerified = record['is_verified'].toString() == '1';
              final statusApproval =
                  record['status_approval']?.toString().toLowerCase() ??
                  'pending';
              return !isVerified && statusApproval == 'pending';
            }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching pending attendance: $e");
    } finally {
      if (mounted) setState(() => _isLoadingApproval = false);
    }
  }

  Future<void> _handleVerification(int id, String action, String name) async {
    final index = _pendingList.indexWhere(
      (r) => r['id'].toString() == id.toString(),
    );
    if (index == -1) return;

    final item = _pendingList[index];
    setState(() {
      _pendingList.removeAt(index);
    });

    final result = await _service.verifyTeacherAttendance(
      attendanceId: id,
      action: action,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name berhasil ${action == 'approve' ? 'diverifikasi' : 'ditolak'}',
          ),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      // Refresh kehadiran tab too
      _fetchKehadiranData();
    } else {
      setState(() {
        _pendingList.insert(index, item);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses: ${result['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Absensi Pengampu',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: Colors.indigo,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: [
            const Tab(
              icon: Icon(Icons.people_alt_rounded, size: 20),
              text: 'Kehadiran',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _pendingList.isNotEmpty,
                label: Text(
                  '${_pendingList.length}',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.pending_actions_rounded, size: 20),
              ),
              text: 'Approval',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildKehadiranTab(), _buildApprovalTab()],
      ),
    );
  }

  // =============================================
  //  TAB 1: KEHADIRAN PENGAMPU
  // =============================================
  Widget _buildKehadiranTab() {
    return Column(
      children: [
        // Date Picker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.indigo[400]),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _fetchKehadiranData();
                      _fetchPendingAttendance();
                    }
                  },
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(
                    () =>
                        _selectedDate = _selectedDate.subtract(
                          const Duration(days: 1),
                        ),
                  );
                  _fetchKehadiranData();
                  _fetchPendingAttendance();
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(
                    () =>
                        _selectedDate = _selectedDate.add(
                          const Duration(days: 1),
                        ),
                  );
                  _fetchKehadiranData();
                  _fetchPendingAttendance();
                },
              ),
            ],
          ),
        ),
        // Stats
        _buildKehadiranStats(),
        // List
        Expanded(
          child:
              _isLoadingKehadiran
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                    onRefresh: _fetchKehadiranData,
                    child:
                        _attendanceList.isEmpty
                            ? _buildEmptyKehadiran()
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _attendanceList.length,
                              itemBuilder: (context, index) {
                                return _buildKehadiranCard(
                                  _attendanceList[index],
                                );
                              },
                            ),
                  ),
        ),
      ],
    );
  }

  Widget _buildKehadiranStats() {
    int total = _attendanceList.length;
    int verified =
        _attendanceList.where((r) => r['is_verified'].toString() == '1').length;
    int pending =
        _attendanceList.where((r) {
          return r['is_verified'].toString() != '1' &&
              (r['status_approval']?.toString().toLowerCase() ?? 'pending') ==
                  'pending';
        }).length;
    int checkedOut =
        _attendanceList.where((r) {
          return r['check_out_time'] != null && r['check_out_time'] != '';
        }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatBadge(Icons.people, '$total', Colors.grey[700]!),
          const SizedBox(width: 6),
          _buildStatBadge(Icons.check_circle, '$verified', Colors.green),
          const SizedBox(width: 6),
          _buildStatBadge(Icons.pending, '$pending', Colors.orange),
          const SizedBox(width: 6),
          _buildStatBadge(Icons.logout, '$checkedOut', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyKehadiran() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada kehadiran pengampu',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildKehadiranCard(dynamic record) {
    final teacherName = record['teacher_name'] ?? record['full_name'] ?? '-';
    final notes = record['notes'] ?? '-';
    final checkIn = record['check_in_time']?.toString() ?? '';
    final checkOut = record['check_out_time']?.toString() ?? '';
    final isVerified = record['is_verified'].toString() == '1';
    final statusApproval =
        record['status_approval']?.toString().toLowerCase() ?? 'pending';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isVerified) {
      statusColor = Colors.green;
      statusText = 'Terverifikasi';
      statusIcon = Icons.verified;
    } else if (statusApproval == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Ditolak';
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending';
      statusIcon = Icons.pending;
    }

    // Determine aktif/selesai
    bool hasCheckOut = checkOut.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Text(
                    teacherName.toString().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notes,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.indigo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (hasCheckOut)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Selesai',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Aktif',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 3),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.login, size: 14, color: Colors.green[400]),
                const SizedBox(width: 4),
                Text(
                  checkIn.length > 5
                      ? checkIn.substring(0, 5)
                      : checkIn.isEmpty
                      ? '--:--'
                      : checkIn,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                if (hasCheckOut) ...[
                  Icon(Icons.logout, size: 14, color: Colors.red[400]),
                  const SizedBox(width: 4),
                  Text(
                    checkOut.length > 5 ? checkOut.substring(0, 5) : checkOut,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  //  TAB 2: APPROVAL
  // =============================================
  Widget _buildApprovalTab() {
    if (_isLoadingApproval) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _fetchPendingAttendance,
      child:
          _pendingList.isEmpty
              ? _buildEmptyApproval()
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _pendingList.length,
                itemBuilder: (context, index) {
                  return _buildVerificationCard(_pendingList[index]);
                },
              ),
    );
  }

  Widget _buildEmptyApproval() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: Colors.green[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Semua Beres!",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Semua kehadiran telah terverifikasi",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(dynamic record) {
    final teacherName = record['teacher_name'] ?? 'Pengampu';
    final unitName = record['unit_name'] ?? 'Unit Tahfidz';
    String notes = record['notes'] ?? 'Siang';
    if (!notes.toLowerCase().contains('halaqoh')) {
      notes = "Halaqoh $notes";
    }
    final photoUrl = record['teacher_photo'];
    final timeIn =
        record['check_in_time'] != null && record['check_in_time'] != ''
            ? record['check_in_time'].toString().substring(0, 5)
            : '--:--';

    final attendanceId = int.tryParse(record['id'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    color: Colors.grey[100],
                    image:
                        (photoUrl != null && photoUrl != '')
                            ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      (photoUrl == null || photoUrl == '')
                          ? Icon(
                            Icons.person,
                            color: Colors.grey[400],
                            size: 30,
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        unitName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: 16,
                      color: Colors.orange[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notes,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Check-in: $timeIn",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        () => _handleVerification(
                          attendanceId,
                          'reject',
                          teacherName,
                        ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red[100]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Tolak",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        () => _handleVerification(
                          attendanceId,
                          'approve',
                          teacherName,
                        ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shadowColor: const Color(
                        0xFF42A5F5,
                      ).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Verifikasi",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
