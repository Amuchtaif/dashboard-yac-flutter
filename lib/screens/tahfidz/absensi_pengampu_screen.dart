import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/tahfidz_service.dart';

class AbsensiPengampuScreen extends StatefulWidget {
  const AbsensiPengampuScreen({super.key});

  @override
  State<AbsensiPengampuScreen> createState() => _AbsensiPengampuScreenState();
}

class _AbsensiPengampuScreenState extends State<AbsensiPengampuScreen> {
  final TahfidzService _service = TahfidzService();
  bool _isLoading = true;
  List<dynamic> _pendingList = [];
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPendingAttendance();
  }

  Future<void> _fetchPendingAttendance() async {
    setState(() => _isLoading = true);
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
              // It is pending if NOT verified AND status is pending
              return !isVerified && statusApproval == 'pending';
            }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching pending attendance: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerification(int id, String action, String name) async {
    // Optimistic UI update
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
    } else {
      // Revert if failed
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Verifikasi Kehadiran',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchPendingAttendance,
                child:
                    _pendingList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _pendingList.length,
                          itemBuilder: (context, index) {
                            return _buildVerificationCard(_pendingList[index]);
                          },
                        ),
              ),
    );
  }

  Widget _buildEmptyState() {
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
    // Data parsing
    final teacherName = record['teacher_name'] ?? 'Pengampu';
    final unitName = record['unit_name'] ?? 'Unit Tahfidz';
    String notes = record['notes'] ?? 'Siang';
    if (!notes.toLowerCase().contains('halaqoh')) {
      notes = "Halaqoh $notes"; // Customize display
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
            color: const Color(0xFF42A5F5).withOpacity(0.08),
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
                        color: Colors.black.withOpacity(0.1),
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
                    color: Colors.blue[50], // Light blue for time
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
                      shadowColor: const Color(0xFF42A5F5).withOpacity(0.4),
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
