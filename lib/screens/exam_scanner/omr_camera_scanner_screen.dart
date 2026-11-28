import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/exam_model.dart';
import '../../services/omr_scanner_service.dart';
import 'omr_result_review_screen.dart';

class OmrCameraScannerScreen extends StatefulWidget {
  final ExamPackageDetailModel packageDetail;

  const OmrCameraScannerScreen({super.key, required this.packageDetail});

  @override
  State<OmrCameraScannerScreen> createState() => _OmrCameraScannerScreenState();
}

class _OmrCameraScannerScreenState extends State<OmrCameraScannerScreen> {
  late MobileScannerController _scannerController;
  final OmrScannerService _omrService = OmrScannerService();
  final ImagePicker _picker = ImagePicker();

  bool _isTorchOn = false;
  bool _isFinalizingCapture = false;
  bool _showShutterFlash = false;

  // Auto-Capture opsional (tangkap otomatis bila 2 frame berturut-turut stabil)
  bool _autoCaptureEnabled = false;
  int _stableMatchFrames = 0;
  String? _lastStableSignature;

  // Bila user menekan shutter sebelum frame QR terbaru masuk, tangkap frame berikutnya langsung
  bool _pendingDirectCapture = false;
  Timer? _captureTimeoutTimer;

  // State QR & frame kamera live terakhir
  OmrQrPayload? _detectedQrPayload;
  String? _detectedStudentName;
  String? _warningMessage;

  Uint8List? _latestFrameBytes;
  List<Point2D>? _latestQrCorners;
  DateTime? _latestFrameTime;

  // State Realtime AR Evaluation
  bool _isAnalyzingLiveFrame = false;
  DateTime _lastLiveAnalysisTime = DateTime.fromMillisecondsSinceEpoch(0);
  OmrScanResult? _liveResult;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: true,
      formats: const [BarcodeFormat.qrCode],
      cameraResolution: const Size(1920, 1080),
    );
  }

  @override
  void dispose() {
    _captureTimeoutTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetectBarcode(BarcodeCapture capture) {
    if (_isFinalizingCapture) return;

    Barcode? matchedBarcode;
    OmrQrPayload? matchedPayload;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || !raw.startsWith('YAC|')) continue;

      final payload = OmrQrPayload.tryParse(raw);
      if (payload != null) {
        matchedBarcode = barcode;
        matchedPayload = payload;
        break;
      }
    }

    if (matchedPayload == null || matchedBarcode == null) return;

    final frameBytes = capture.image;
    final qrCorners =
        matchedBarcode.corners.map((o) => Point2D(o.dx, o.dy)).toList();

    final isSamePayload = _detectedQrPayload?.raw == matchedPayload.raw;
    final isPackageMismatch =
        matchedPayload.packageId != widget.packageDetail.package.id;

    String? studentName;
    String? warnMsg;
    if (isPackageMismatch) {
      warnMsg =
          'Perhatian: LJK ini milik Paket #${matchedPayload.packageId}, bukan paket aktif (#${widget.packageDetail.package.id}).';
    } else if (matchedPayload.isBlankLjk) {
      studentName = 'LJK Kosong (Pilih Santri Manual)';
    } else {
      final st = widget.packageDetail.getStudent(matchedPayload.studentId);
      studentName =
          st != null ? st.namaSiswa : 'Santri #${matchedPayload.studentId}';
    }

    if (frameBytes != null && frameBytes.isNotEmpty) {
      _latestFrameBytes = frameBytes;
      _latestQrCorners = qrCorners.length >= 4 ? qrCorners : null;
      _latestFrameTime = DateTime.now();
    }

    if (!isSamePayload ||
        _warningMessage != warnMsg ||
        _detectedStudentName != studentName) {
      setState(() {
        _detectedQrPayload = matchedPayload;
        _warningMessage = warnMsg;
        _detectedStudentName = studentName;
        if (!isSamePayload) {
          _liveResult = null;
          _stableMatchFrames = 0;
          _lastStableSignature = null;
        }
      });
    }

    // Jika user baru menekan Capture dan menunggu frame fresh
    if (_pendingDirectCapture && frameBytes != null && frameBytes.isNotEmpty) {
      _pendingDirectCapture = false;
      _captureTimeoutTimer?.cancel();
      _finalizeCapturedBytes(frameBytes, qrCorners: _latestQrCorners);
      return;
    }

    // Jalankan evaluasi Realtime AR OMR di background Isolate secara ter-throttle
    if (frameBytes != null &&
        frameBytes.isNotEmpty &&
        !isPackageMismatch &&
        !_isAnalyzingLiveFrame) {
      final elapsedMs =
          DateTime.now().difference(_lastLiveAnalysisTime).inMilliseconds;
      if (elapsedMs >= 320) {
        _runRealtimeAnalysis(
          frameBytes: frameBytes,
          qrCorners: _latestQrCorners,
          qrRaw: matchedPayload.raw,
        );
      }
    }
  }

  Future<void> _runRealtimeAnalysis({
    required Uint8List frameBytes,
    required List<Point2D>? qrCorners,
    required String qrRaw,
  }) async {
    _isAnalyzingLiveFrame = true;
    _lastLiveAnalysisTime = DateTime.now();

    try {
      final result = await _omrService.processLjkBytes(
        imageBytes: frameBytes,
        omrLayout: widget.packageDetail.omrLayout,
        answerKeys: widget.packageDetail.answerKeys,
        qrCorners: qrCorners,
        annotateImage: false,
      );

      if (!mounted || _isFinalizingCapture) return;
      // Pastikan frame masih untuk lembar QR yang sama
      if (_detectedQrPayload?.raw != qrRaw) return;

      if (result.isValidGrid) {
        setState(() {
          _liveResult = result;
        });

        // Cek stabilitas untuk fitur Auto-Capture jika diaktifkan
        if (_autoCaptureEnabled) {
          final sig =
              '$qrRaw|${result.answers.map((a) => a.selectedOption).join(',')}';
          if (sig == _lastStableSignature) {
            _stableMatchFrames++;
          } else {
            _lastStableSignature = sig;
            _stableMatchFrames = 1;
          }

          if (_stableMatchFrames >= 2 && _latestFrameBytes != null) {
            _stableMatchFrames = 0;
            await _captureDirectFromLiveStream();
          }
        }
      } else {
        // Grid belum terkunci penuh di frame ini
        if (_liveResult != null &&
            DateTime.now().difference(_lastLiveAnalysisTime).inMilliseconds >
                1200) {
          setState(() => _liveResult = null);
        }
      }
    } catch (e) {
      debugPrint('Realtime OMR frame skipped: $e');
    } finally {
      _isAnalyzingLiveFrame = false;
    }
  }

  /// Langsung mencapture frame dari live preview kamera TANPA membuka app kamera eksternal!
  Future<void> _captureDirectFromLiveStream() async {
    if (_isFinalizingCapture) return;

    final now = DateTime.now();
    final hasFreshFrame =
        _latestFrameBytes != null &&
        _latestFrameTime != null &&
        now.difference(_latestFrameTime!).inMilliseconds < 1800;

    if (hasFreshFrame) {
      await _finalizeCapturedBytes(
        _latestFrameBytes!,
        qrCorners: _latestQrCorners,
      );
      return;
    }

    // Jika frame fresh belum diterima, tunggu sejenak maksimal 800ms untuk frame kamera berikutnya
    setState(() => _pendingDirectCapture = true);
    _captureTimeoutTimer?.cancel();
    _captureTimeoutTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted || !_pendingDirectCapture) return;
      setState(() => _pendingDirectCapture = false);

      // Bila ada frame lama (< 8 detik), tetap bisa dipakai sebagai cadangan
      if (_latestFrameBytes != null &&
          _latestFrameTime != null &&
          DateTime.now().difference(_latestFrameTime!).inSeconds < 8) {
        _finalizeCapturedBytes(_latestFrameBytes!, qrCorners: _latestQrCorners);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Arahkan kamera ke LJK hingga QR Code & jawaban terdeteksi sebelum capture.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _finalizeCapturedBytes(
    Uint8List rawBytes, {
    List<Point2D>? qrCorners,
  }) async {
    if (_isFinalizingCapture) return;

    setState(() {
      _isFinalizingCapture = true;
      _showShutterFlash = true;
    });
    HapticFeedback.mediumImpact();

    // Pause kamera sementara proses simpan preview & review
    unawaited(_scannerController.stop().catchError((_) {}));

    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _showShutterFlash = false);
    });

    if (!mounted) return;

    // Tampilkan loading ringkas
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF10B981)),
                    const SizedBox(height: 16),
                    Text(
                      'Mengunci & Mengoreksi LJK...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menyusun hasil koreksi & overlay visual',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final result = await _omrService.processLjkBytes(
        imageBytes: rawBytes,
        omrLayout: widget.packageDetail.omrLayout,
        answerKeys: widget.packageDetail.answerKeys,
        qrCorners: qrCorners,
        annotateImage: true,
      );

      if (!mounted) return;
      Navigator.pop(context); // tutup loading

      final studentId = _detectedQrPayload?.studentId;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder:
              (_) => OmrResultReviewScreen(
                packageDetail: widget.packageDetail,
                scanResult: result,
                initialStudentId:
                    studentId != null && studentId > 0 ? studentId : null,
              ),
        ),
      );

      if (!mounted) return;

      // Aktifkan kembali live camera setelah kembali dari layar review
      if (saved == true) {
        setState(() {
          _detectedQrPayload = null;
          _detectedStudentName = null;
          _warningMessage = null;
          _liveResult = null;
          _latestFrameBytes = null;
          _latestQrCorners = null;
          _stableMatchFrames = 0;
          _lastStableSignature = null;
        });
      }
      await _scannerController.start().catchError((_) {});
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _scannerController.start().catchError((_) {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memproses LJK: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFinalizingCapture = false);
      }
    }
  }

  Future<void> _pickFromGalleryAndProcess() async {
    if (_isFinalizingCapture) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );

      if (picked == null) return;
      if (!mounted) return;

      // Coba deteksi QR Code langsung dari foto galeri (jika platform mendukung)
      try {
        final barcodeResult = await _scannerController.analyzeImage(
          picked.path,
        );
        if (barcodeResult != null) {
          for (final b in barcodeResult.barcodes) {
            final raw = b.rawValue;
            if (raw != null && raw.startsWith('YAC|')) {
              final payload = OmrQrPayload.tryParse(raw);
              if (payload != null) {
                _detectedQrPayload = payload;
                _latestQrCorners =
                    b.corners.length >= 4
                        ? b.corners.map((o) => Point2D(o.dx, o.dy)).toList()
                        : null;
                if (payload.studentId > 0) {
                  final st = widget.packageDetail.getStudent(payload.studentId);
                  _detectedStudentName =
                      st?.namaSiswa ?? 'Santri #${payload.studentId}';
                }
                break;
              }
            }
          }
        }
      } catch (_) {
        // Simulator / perangkat tertentu melempar UnsupportedError untuk analyzeImage
      }

      final bytes = await File(picked.path).readAsBytes();
      await _finalizeCapturedBytes(bytes, qrCorners: _latestQrCorners);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error galeri: $e', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidQr =
        _detectedQrPayload != null && _warningMessage == null;
    final bool hasLiveLock =
        _liveResult != null && _liveResult!.isValidGrid && hasValidQr;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview (MobileScanner with Tap-To-Focus)
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            tapToFocus: true,
            onDetect: _onDetectBarcode,
          ),

          // 2. Viewfinder Guides
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _OmrViewfinderPainter(isLocked: hasLiveLock),
            ),
          ),

          // 3. LIVE REALTIME AR OVERLAY (Kotak Grid + Bulatan Hijau Benar / Merah Salah / Kuning Kunci)
          if (hasLiveLock)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _LiveOmrArPainter(result: _liveResult!),
              ),
            ),

          // 4. Shutter Flash Feedback
          if (_showShutterFlash)
            IgnorePointer(
              child: Container(color: Colors.white.withValues(alpha: 0.72)),
            ),

          // 5 & 6. Top Header Bar + Live Student Status Banner (di dalam SafeArea agar tidak tumpang tindih)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.55),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.packageDetail.package.subjectName} • ${widget.packageDetail.package.gradeName}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Toggle Auto-Capture
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _autoCaptureEnabled = !_autoCaptureEnabled;
                                  _stableMatchFrames = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _autoCaptureEnabled
                                          ? const Color(0xFF10B981)
                                          : Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        _autoCaptureEnabled
                                            ? Colors.white
                                            : Colors.white38,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _autoCaptureEnabled
                                          ? Icons.auto_awesome_rounded
                                          : Icons.touch_app_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _autoCaptureEnabled ? 'Auto' : 'Manual',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            CircleAvatar(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.55),
                              child: IconButton(
                                icon: Icon(
                                  _isTorchOn
                                      ? Icons.flash_on_rounded
                                      : Icons.flash_off_rounded,
                                  color:
                                      _isTorchOn
                                          ? const Color(0xFFFBBF24)
                                          : Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _scannerController.toggleTorch();
                                  setState(() => _isTorchOn = !_isTorchOn);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildStatusBanner(),
                  ],
                ),
              ),
            ),
          ),

          // 7. Realtime Live Score HUD + Shutter Controls (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasLiveLock) _buildLiveScoreHud(_liveResult!),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 12, 32, 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Tombol Galeri
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.6,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.photo_library_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onPressed: _pickFromGalleryAndProcess,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Galeri',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        // Direct In-App Capture Button
                        GestureDetector(
                          onTap: _captureDirectFromLiveStream,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  color:
                                      hasValidQr
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF2563EB),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (hasValidQr
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF2563EB))
                                          .withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child:
                                      _pendingDirectCapture
                                          ? const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                          : Container(
                                            width: 58,
                                            height: 58,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                            child: Icon(
                                              hasValidQr
                                                  ? Icons.check_rounded
                                                  : Icons.camera_alt_rounded,
                                              size: 30,
                                              color:
                                                  hasValidQr
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFF2563EB),
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasValidQr ? 'Capture Hasil' : 'Scan LJK',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Spacer simetri dengan tombol reset deteksi
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.6,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _detectedQrPayload = null;
                                    _detectedStudentName = null;
                                    _warningMessage = null;
                                    _liveResult = null;
                                    _latestFrameBytes = null;
                                    _stableMatchFrames = 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reset',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveScoreHud(OmrScanResult result) {
    final answeredItems =
        result.answers.where((a) => !a.isBlank).take(8).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nilai: ${result.score}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _hudBadge('B: ${result.correctCount}', const Color(0xFF34D399)),
              const SizedBox(width: 6),
              _hudBadge('S: ${result.wrongCount}', const Color(0xFFF87171)),
              const SizedBox(width: 6),
              _hudBadge(
                'K: ${result.blankCount + result.doubleCount}',
                const Color(0xFFFBBF24),
              ),
              const Spacer(),
              Text(
                'LIVE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF34D399),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          if (answeredItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    answeredItems.map((a) {
                      final isOk = a.isCorrect == true;
                      final bg =
                          isOk
                              ? const Color(0xFF065F46)
                              : const Color(0xFF7F1D1D);
                      final fg =
                          isOk
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFFCA5A5);
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${a.questionNumber}:${a.selectedOption} ${isOk ? "✓" : "✗"}',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hudBadge(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_warningMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _warningMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_detectedStudentName != null) {
      final hasLive = _liveResult != null && _liveResult!.isValidGrid;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              hasLive
                  ? Icons.document_scanner_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasLive
                    ? '$_detectedStudentName • Siap Capture'
                    : '✓ Terdeteksi: $_detectedStudentName (Mendeteksi jawaban...)',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            color: Color(0xFF93C5FD),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Arahkan LJK penuh ke layar agar QR & jawaban terdeteksi realtime',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter Overlay AR Realtime untuk menggambar bounding quad + ring Benar/Salah langsung di kamera
class _LiveOmrArPainter extends CustomPainter {
  final OmrScanResult result;

  const _LiveOmrArPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final imgSize = result.sourceImageSize;
    if (imgSize.isEmpty || result.detectedCorners.length < 4) return;

    // Mapping persis BoxFit.cover dari koordinat sourceImage -> layar Widget
    final scale = math.max(
      size.width / imgSize.width,
      size.height / imgSize.height,
    );
    final offsetX = (size.width - imgSize.width * scale) / 2.0;
    final offsetY = (size.height - imgSize.height * scale) / 2.0;

    Offset toScreen(double sx, double sy) =>
        Offset(sx * scale + offsetX, sy * scale + offsetY);

    // 1. Gambar Quadrilateral Kotak Jawaban yang terkunci realtime
    final quadPts =
        result.detectedCorners.map((p) => toScreen(p.x, p.y)).toList();
    final quadPath = Path()..addPolygon(quadPts, true);

    final quadStroke =
        Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    canvas.drawPath(quadPath, quadStroke);

    final cornerDotPaint =
        Paint()
          ..color = const Color(0xFF34D399)
          ..style = PaintingStyle.fill;
    for (final pt in quadPts) {
      canvas.drawCircle(pt, 4.5, cornerDotPaint);
    }

    // 2. Gambar Bulatan Jawaban AR (Hijau Benar, Merah Salah, Kuning Kunci)
    final greenStroke =
        Paint()
          ..color = const Color(0xFF10B981)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
    final greenFill =
        Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;

    final redStroke =
        Paint()
          ..color = const Color(0xFFEF4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
    final redFill =
        Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;

    final keyStroke =
        Paint()
          ..color = const Color(0xFFF59E0B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;

    for (final b in result.arBubbles) {
      final center = toScreen(b.srcX, b.srcY);
      final r = (b.radiusPx * scale).clamp(4.0, 26.0);

      if (b.status == 'correct') {
        canvas.drawCircle(center, r, greenFill);
        canvas.drawCircle(center, r, greenStroke);
      } else if (b.status == 'wrong' || b.status == 'double') {
        canvas.drawCircle(center, r, redFill);
        canvas.drawCircle(center, r, redStroke);
      } else if (b.status == 'key_hint') {
        canvas.drawCircle(center, r + 1.5, keyStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiveOmrArPainter oldDelegate) =>
      oldDelegate.result != result;
}

/// Custom Painter Viewfinder Panduan (Proporsi presisi print_ljk.php)
class _OmrViewfinderPainter extends CustomPainter {
  final bool isLocked;

  const _OmrViewfinderPainter({this.isLocked = false});

  @override
  void paint(Canvas canvas, Size size) {
    final targetW = size.width * 0.84;
    final targetH = targetW * (185.0 / 172.0);
    final qrSize = targetW * 0.16;
    final qrGap = targetW * 0.14;

    final left = (size.width - targetW) / 2;
    final preferredTop = (size.height - targetH) / 2 + 42;
    final maxTop = size.height - targetH - 140;
    final minTop = qrSize + qrGap + 150;
    final double top =
        preferredTop
            .clamp(math.min(minTop, maxTop), math.max(minTop, maxTop))
            .toDouble();
    final right = left + targetW;
    final bottom = top + targetH;
    final rect = Rect.fromLTRB(left, top, right, bottom);

    // Scrim lembut di sekeliling kotak OMR (tetap jaga area QR di atas terlihat jelas)
    final scrimPaint =
        Paint()..color = Colors.black.withValues(alpha: isLocked ? 0.25 : 0.35);
    final bgPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final qrRect = Rect.fromLTWH(
      right - qrSize,
      top - qrGap - qrSize,
      qrSize,
      qrSize,
    );
    final holePath =
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)))
          ..addRRect(RRect.fromRectAndRadius(qrRect, const Radius.circular(6)));
    final combined = Path.combine(PathOperation.difference, bgPath, holePath);
    canvas.drawPath(combined, scrimPaint);

    // Border & corner brackets (meredup halus saat AR Live sudah terkunci)
    final borderPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: isLocked ? 0.18 : 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    final cornerPaint =
        Paint()
          ..color =
              isLocked
                  ? const Color(0xFF10B981).withValues(alpha: 0.45)
                  : const Color(0xFF3B82F6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    // TL
    canvas.drawLine(
      Offset(left, top + cornerLen),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLen, top),
      cornerPaint,
    );
    // TR
    canvas.drawLine(
      Offset(right - cornerLen, top),
      Offset(right, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, top),
      Offset(right, top + cornerLen),
      cornerPaint,
    );
    // BL
    canvas.drawLine(
      Offset(left, bottom - cornerLen),
      Offset(left, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + cornerLen, bottom),
      cornerPaint,
    );
    // BR
    canvas.drawLine(
      Offset(right - cornerLen, bottom),
      Offset(right, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - cornerLen),
      cornerPaint,
    );

    // Kotak Pemandu QR Code di atas-kanan OMR
    final qrBoxPaint =
        Paint()
          ..color = const Color(
            0xFFFBBF24,
          ).withValues(alpha: isLocked ? 0.45 : 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(qrRect, const Radius.circular(6)),
      qrBoxPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OmrViewfinderPainter oldDelegate) =>
      oldDelegate.isLocked != isLocked;
}
