import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/meeting_model.dart';
import 'scan/scan_qr_screen.dart';
import '../core/api_constants.dart';

class MeetingDetailScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSharing = false;
  bool _isSubmittingAbsensi = false;
  bool _hasAttended = false;
  int? _currentUserId;
  bool _isLoadingAttendees = false;
  List<dynamic> _attendees = [];
  Map<String, dynamic> _attendeeSummary = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUser();
    await _checkAttendanceStatus();
    _fetchAttendees();
  }

  Future<void> _fetchAttendees() async {
    setState(() => _isLoadingAttendees = true);
    try {
      final url = Uri.parse(
        '${ApiConstants.getMeetingAttendees}?meeting_id=${widget.meeting.id}',
      );
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _attendees = data['data'] ?? [];
            _attendeeSummary =
                data['summary'] != null
                    ? Map<String, dynamic>.from(data['summary'])
                    : {};
            // Also check if current user has attended from API data
            if (_currentUserId != null) {
              final myAttendance = _attendees.any(
                (p) =>
                    p['id']?.toString() == _currentUserId.toString() &&
                    p['status'] == 'present',
              );
              if (myAttendance && !_hasAttended) {
                _hasAttended = true;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendees: $e');
    } finally {
      setState(() => _isLoadingAttendees = false);
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId') ?? prefs.getInt('user_id');
    });
  }

  Future<void> _checkAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final attended =
        prefs.getBool('attended_meeting_${widget.meeting.id}') ?? false;
    if (mounted) {
      setState(() {
        _hasAttended = attended;
      });
    }
  }

  bool get _isMeetingStarted {
    try {
      if (widget.meeting.date.isEmpty || widget.meeting.startTime.isEmpty) {
        return true;
      }
      final date = DateTime.parse(widget.meeting.date);
      final timeParts = widget.meeting.startTime.split(':');
      if (timeParts.length < 2) return true;

      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      return DateTime.now().isAfter(startDateTime);
    } catch (e) {
      return true; // Fallback to allow if parsing fails
    }
  }

  bool get _isFinished {
    if (widget.meeting.status.toLowerCase() == 'finished') return true;
    try {
      if (widget.meeting.date.isEmpty || widget.meeting.endTime.isEmpty) {
        return false;
      }
      final date = DateTime.parse(widget.meeting.date);
      final timeParts = widget.meeting.endTime.split(':');
      if (timeParts.length < 2) return false;

      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      return DateTime.now().isAfter(endDateTime);
    } catch (e) {
      return widget.meeting.status.toLowerCase() == 'finished';
    }
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;
    // Determine if meeting type is online
    final isOnline = meeting.type.toLowerCase() == 'online';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF), // Light blue-ish background
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // Share or more options
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Main Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Category badge - menampilkan tipe rapat
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOnline ? Icons.videocam : Icons.location_on,
                                  size: 14,
                                  color: const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline ? 'RAPAT ONLINE' : 'RAPAT OFFLINE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            meeting.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Date & Time
                          _buildInfoRow(
                            Icons.calendar_today_outlined,
                            meeting.formattedDate,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time,
                            meeting.formattedTime,
                          ),
                          const SizedBox(height: 12),

                          // Location or Link
                          if (isOnline && meeting.link != null)
                            _buildInfoRow(
                              Icons.videocam_outlined,
                              'Online Meeting',
                              subtitle: meeting.link,
                              isLink: true,
                            )
                          else if (!isOnline && meeting.location != null)
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              meeting.location!,
                            ),

                          // Creator info
                          if (meeting.creatorName != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Penyelenggara: ${meeting.creatorName}',
                            ),
                          ],

                          const SizedBox(height: 32),

                          // QR Code Section - Only for Creator
                          if (_currentUserId == widget.meeting.creatorId)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // QR Code with RepaintBoundary for capture
                                  RepaintBoundary(
                                    key: _qrKey,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          QrImageView(
                                            data:
                                                widget.meeting.qrToken ??
                                                'MEET-${widget.meeting.id}',
                                            version: QrVersions.auto,
                                            size: 160,
                                            eyeStyle: const QrEyeStyle(
                                              eyeShape: QrEyeShape.square,
                                              color: Color(0xFF3B82F6),
                                            ),
                                            dataModuleStyle:
                                                const QrDataModuleStyle(
                                                  dataModuleShape:
                                                      QrDataModuleShape.square,
                                                  color: Color(0xFF3B82F6),
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            widget.meeting.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1F2937),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            widget.meeting.formattedDate,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Bagikan QR untuk absensi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Share Button
                                  ElevatedButton.icon(
                                    onPressed: _isSharing ? null : _shareQrCode,
                                    icon:
                                        _isSharing
                                            ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.share_rounded,
                                              size: 18,
                                            ),
                                    label: Text(
                                      _isSharing
                                          ? 'Menyiapkan...'
                                          : 'Bagikan QR Code',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Attendance success banner
                          if (_hasAttended && !_isFinished)
                            _buildAttendedBanner(),

                          // Participants List Section - always shown
                          _buildParticipantsSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            if (!_hasAttended)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Scan QR Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isFinished
                                  ? () {
                                    _showErrorSnackbar(
                                      'Rapat sudah berakhir. Anda tidak dapat melakukan scan kehadiran.',
                                    );
                                  }
                                  : _isMeetingStarted
                                  ? () {
                                    _handleScanAbsensi();
                                  }
                                  : () {
                                    _showErrorSnackbar(
                                      'Rapat belum dimulai. Harap tunggu hingga waktu mulai.',
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isFinished
                                    ? Colors.grey[400]
                                    : _isMeetingStarted
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color:
                                    _isFinished ? Colors.white70 : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Scan QR',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _isFinished
                                          ? Colors.white70
                                          : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendedBanner() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kehadiran Tercatat ✓',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Anda telah berhasil hadir di rapat ini',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    final totalCount = _attendeeSummary['total'] ?? _attendees.length;
    final presentCount =
        _attendeeSummary['present'] ??
        _attendees.where((p) => p['status'] == 'present').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Peserta Rapat',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$presentCount/$totalCount Hadir',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingAttendees)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_attendees.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline, color: Colors.grey[400], size: 40),
                const SizedBox(height: 12),
                Text(
                  'Belum ada data peserta',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attendees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final participant = _attendees[index];
              final name = participant['full_name'] ?? 'Peserta';
              final isPresent = participant['status'] == 'present';
              final time = participant['attended_at'] ?? '';
              String formattedTime = '';
              if (time.isNotEmpty) {
                try {
                  final parsed = DateTime.parse(time);
                  formattedTime =
                      '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
                } catch (_) {
                  formattedTime = time;
                }
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isPresent
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isPresent
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color:
                                isPresent
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          if (participant['email'] != null)
                            Text(
                              participant['email'],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isPresent
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPresent ? 'Hadir' : 'Belum Hadir',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  isPresent
                                      ? const Color(0xFF166534)
                                      : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        if (isPresent && formattedTime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              formattedTime,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text, {
    String? subtitle,
    bool isLink = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color:
                        isLink
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF6B7280),
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleScanAbsensi() async {
    final meeting = widget.meeting;

    // Navigate to scanner
    if (!mounted) return;
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrScreen()),
    );

    if (scannedData != null && mounted) {
      // Validate QR
      // Format expected: "MEET-{ID}" or custom token
      // For now, let's validate it contains the ID

      final expectedToken = meeting.qrToken ?? 'MEET-${meeting.id}';

      if (scannedData == expectedToken) {
        _confirmAbsensi();
      } else {
        _showErrorSnackbar('QR Code tidak valid untuk rapat ini.');
      }
    }
  }

  void _confirmAbsensi() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Konfirmasi Absensi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Anda akan melakukan absensi untuk rapat:\n\n"${widget.meeting.title}"',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _submitAbsensi();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Ya, Absen',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _submitAbsensi() async {
    if (_isSubmittingAbsensi) return; // Prevent double submission

    setState(() => _isSubmittingAbsensi = true);

    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final userId = prefs.getInt('userId');

      if (userId == null) {
        _showErrorSnackbar('Sesi telah berakhir. Silakan login ulang.');
        return;
      }

      // Call API to record attendance
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/submit_meeting_attendance.php',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'meeting_id': widget.meeting.id,
          'user_id': userId,
          'attended_at': DateTime.now().toIso8601String(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['message'] ?? 'Absensi berhasil dicatat!',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Save local attendance status
        await prefs.setBool('attended_meeting_${widget.meeting.id}', true);
        if (mounted) {
          setState(() {
            _hasAttended = true;
          });
          // Refresh participants list to show updated status
          _fetchAttendees();
        }
      } else {
        // Show error from server
        _showErrorSnackbar(data['message'] ?? 'Gagal mencatat absensi');
      }
    } catch (e) {
      debugPrint('Error submitting attendance: $e');
      if (mounted) {
        _showErrorSnackbar('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingAbsensi = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _shareQrCode() async {
    setState(() => _isSharing = true);

    try {
      // Capture QR code widget as image
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final fileName =
          'qr_rapat_${widget.meeting.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'QR Code Absensi Rapat: ${widget.meeting.title}\n${widget.meeting.formattedDate} • ${widget.meeting.formattedTime}',
        subject: 'QR Code Rapat - ${widget.meeting.title}',
      );
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Gagal membagikan QR code', style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}
