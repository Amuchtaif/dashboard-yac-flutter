import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/meeting_model.dart';
import 'scan/scan_qr_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAttendanceStatus();
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

                          // QR Code Section
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
                                // QR Code dengan RepaintBoundary untuk capture
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
                                              meeting.qrToken ??
                                              'MEET-${meeting.id}',
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
                                          meeting.title,
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
                                          meeting.formattedDate,
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
                                  'Scan QR untuk absensi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Tombol Download/Share
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
                              _isMeetingStarted
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
                                _isMeetingStarted
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
                              const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Scan QR',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Upload File Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isMeetingStarted
                                  ? () {
                                    _handleUploadQrImage();
                                  }
                                  : () {
                                    _showErrorSnackbar(
                                      'Rapat belum dimulai. Harap tunggu hingga waktu mulai.',
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isMeetingStarted
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.upload_file,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upload QR',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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

  Future<void> _handleUploadQrImage() async {
    final meeting = widget.meeting;

    try {
      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        return; // User cancelled
      }

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Decode QR from image using MobileScannerController
      final controller = MobileScannerController();
      final barcodes = await controller.analyzeImage(image.path);
      await controller.dispose();

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (barcodes == null || barcodes.barcodes.isEmpty) {
        _showErrorSnackbar(
          'Tidak dapat membaca QR Code dari gambar. Pastikan gambar berisi QR Code yang jelas.',
        );
        return;
      }

      final scannedData = barcodes.barcodes.first.rawValue;

      if (scannedData == null) {
        _showErrorSnackbar('QR Code tidak dapat dibaca.');
        return;
      }

      // Validate QR
      final expectedToken = meeting.qrToken ?? 'MEET-${meeting.id}';

      if (scannedData == expectedToken) {
        _confirmAbsensi();
      } else {
        _showErrorSnackbar('QR Code tidak valid untuk rapat ini.');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      debugPrint('Error scanning QR from image: $e');
      _showErrorSnackbar(
        'Gagal membaca QR Code dari gambar. Silakan coba lagi.',
      );
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
