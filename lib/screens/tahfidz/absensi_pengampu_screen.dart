import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tahfidz_service.dart';

class AbsensiPengampuScreen extends StatefulWidget {
  const AbsensiPengampuScreen({super.key});

  @override
  State<AbsensiPengampuScreen> createState() => _AbsensiPengampuScreenState();
}

class _AbsensiPengampuScreenState extends State<AbsensiPengampuScreen> {
  final TahfidzService _service = TahfidzService();
  int? _teacherId;
  bool _isLoading = true;
  List<dynamic> _history = [];
  Map<String, dynamic>? _todayRecord;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    setState(() => _teacherId = id);

    if (_teacherId != null) {
      await _fetchHistory();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getTeacherAttendanceHistory(
        teacherId: _teacherId,
      );
      setState(() {
        _history = data;

        // Find today's record
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        try {
          _todayRecord = data.firstWhere(
            (element) => element['date'] == today,
            orElse: () => null,
          );
        } catch (e) {
          _todayRecord = null;
        }
      });
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckInOut() async {
    if (_teacherId == null) return;

    String action = 'check_in';
    if (_todayRecord != null) {
      if (_todayRecord!['check_out_time'] == null) {
        action = 'check_out';
      } else {
        return; // Already done
      }
    }

    // Show dialog to confirm
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  action == 'check_in'
                      ? 'Konfirmasi Masuk'
                      : 'Konfirmasi Pulang',
                ),
                content: Text(
                  'Anda yakin ingin melakukan ${action == 'check_in' ? 'Check In' : 'Check Out'}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ya'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    final result = await _service.submitTeacherAttendance(
      teacherId: _teacherId!,
      action: action,
    );

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchHistory();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Absensi Pengampu',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildActionCard(),
                  Expanded(child: _buildHistoryList()),
                ],
              ),
    );
  }

  Widget _buildActionCard() {
    String statusText = "Belum Absen";
    String btnText = "Check In";
    Color btnColor = Colors.indigo;
    bool isDone = false;
    String timeInfo = "--:--";

    if (_todayRecord != null) {
      if (_todayRecord!['check_out_time'] != null) {
        statusText = "Selesai";
        btnText = "Selesai";
        btnColor = Colors.grey;
        isDone = true;
        timeInfo =
            "${_todayRecord!['check_in_time']} - ${_todayRecord!['check_out_time']}";
      } else {
        statusText = "Sudah Check In";
        btnText = "Check Out";
        btnColor = Colors.orange;
        timeInfo = "Masuk: ${_todayRecord!['check_in_time']}";
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            timeInfo,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDone ? Colors.green[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDone ? Colors.green[800] : Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDone ? null : _handleCheckInOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                btnText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['date'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    item['notes'] ?? '-',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "In: ${item['check_in_time'] ?? '-'}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Out: ${item['check_out_time'] ?? '-'}",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
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
