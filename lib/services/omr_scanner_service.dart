import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Size;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/exam_model.dart';

/// Struktur titik 2 dimensi (sendable antar Isolate)
class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  Point2D operator +(Point2D other) => Point2D(x + other.x, y + other.y);
  Point2D operator -(Point2D other) => Point2D(x - other.x, y - other.y);
  Point2D operator *(double factor) => Point2D(x * factor, y * factor);

  double distanceTo(Point2D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() =>
      'Point2D(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Titik overlay AR untuk setiap bulatan pada kamera realtime (koordinat source image)
class OmrOverlayBubble {
  final int questionNumber;
  final String optionLabel;
  final double srcX;
  final double srcY;
  final double radiusPx;
  final String status; // 'correct', 'wrong', 'key_hint', 'double'

  const OmrOverlayBubble({
    required this.questionNumber,
    required this.optionLabel,
    required this.srcX,
    required this.srcY,
    required this.radiusPx,
    required this.status,
  });
}

/// Hasil evaluasi OMR on-device (baik untuk mode Realtime AR maupun Full Capture)
class OmrScanResult {
  final List<ExamAnswerItem> answers;
  final int correctCount;
  final int wrongCount;
  final int blankCount;
  final int doubleCount;
  final double score;
  final bool isValidGrid;
  final double gridConfidence;
  final Size sourceImageSize;
  final List<Point2D>
  detectedCorners; // TL, TR, BR, BL dalam koordinat sourceImageSize
  final List<OmrOverlayBubble> arBubbles;
  final Uint8List annotatedImageBytes;
  final String annotatedImagePath;

  const OmrScanResult({
    required this.answers,
    required this.correctCount,
    required this.wrongCount,
    required this.blankCount,
    required this.doubleCount,
    required this.score,
    this.isValidGrid = true,
    this.gridConfidence = 1.0,
    this.sourceImageSize = Size.zero,
    this.detectedCorners = const [],
    this.arBubbles = const [],
    required this.annotatedImageBytes,
    required this.annotatedImagePath,
  });
}

/// Parameter kirim ke background Isolate
class _OmrIsolatePayload {
  final Uint8List imageBytes;
  final OmrLayoutModel omrLayout;
  final List<AnswerKeyModel> answerKeys;
  final List<Point2D>? qrCorners;
  final bool annotateImage;
  final int maxWorkWidth;

  const _OmrIsolatePayload({
    required this.imageBytes,
    required this.omrLayout,
    required this.answerKeys,
    this.qrCorners,
    required this.annotateImage,
    required this.maxWorkWidth,
  });
}

class OmrScannerService {
  // Standar target resolusi hasil warp perspektif (sesuai rasio fisik LJK 172mm : 185mm)
  static const int targetW = 1000;
  static const int targetH = 1076;

  /// Memproses file foto LJK (untuk Galeri / High-res Review) di background Isolate
  Future<OmrScanResult> processLjkImage({
    required File imageFile,
    required OmrLayoutModel omrLayout,
    required List<AnswerKeyModel> answerKeys,
    List<Point2D>? qrCorners,
  }) async {
    final bytes = await imageFile.readAsBytes();
    return processLjkBytes(
      imageBytes: bytes,
      omrLayout: omrLayout,
      answerKeys: answerKeys,
      qrCorners: qrCorners,
      annotateImage: true,
    );
  }

  /// Memproses raw JPEG bytes langsung dari kamera live stream (Realtime AR / Direct Capture)
  Future<OmrScanResult> processLjkBytes({
    required Uint8List imageBytes,
    required OmrLayoutModel omrLayout,
    required List<AnswerKeyModel> answerKeys,
    List<Point2D>? qrCorners,
    bool annotateImage = false,
  }) async {
    final maxWorkW = annotateImage ? 1150 : 520;

    final result = await compute(
      _runOmrScanIsolate,
      _OmrIsolatePayload(
        imageBytes: imageBytes,
        omrLayout: omrLayout,
        answerKeys: answerKeys,
        qrCorners: qrCorners,
        annotateImage: annotateImage,
        maxWorkWidth: maxWorkW,
      ),
    );

    // Jika mode review/simpan, tuliskan preview JPEG anotasi ke temp dir di main isolate
    if (annotateImage && result.annotatedImageBytes.isNotEmpty) {
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFilePath =
            '${tempDir.path}/omr_preview_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(tempFilePath).writeAsBytes(result.annotatedImageBytes);
        return OmrScanResult(
          answers: result.answers,
          correctCount: result.correctCount,
          wrongCount: result.wrongCount,
          blankCount: result.blankCount,
          doubleCount: result.doubleCount,
          score: result.score,
          isValidGrid: result.isValidGrid,
          gridConfidence: result.gridConfidence,
          sourceImageSize: result.sourceImageSize,
          detectedCorners: result.detectedCorners,
          arBubbles: result.arBubbles,
          annotatedImageBytes: result.annotatedImageBytes,
          annotatedImagePath: tempFilePath,
        );
      } catch (e) {
        debugPrint('Warning saving temp annotated image: $e');
      }
    }

    return result;
  }
}

/// Top-level Isolate entry point untuk OMR processing yang responsif tanpa freeze UI
OmrScanResult _runOmrScanIsolate(_OmrIsolatePayload payload) {
  final decoded = img.decodeImage(payload.imageBytes);
  if (decoded == null) {
    throw Exception('Gagal membaca format gambar LJK.');
  }

  final oriented = img.bakeOrientation(decoded);
  final origW = oriented.width.toDouble();
  final origH = oriented.height.toDouble();

  // Downscale terkontrol agar super cepat (realtime ~20-40ms) tanpa kehilangan detail bulatan
  late final img.Image workImg;
  late final double invScale;
  if (oriented.width > payload.maxWorkWidth) {
    final targetWorkW = payload.maxWorkWidth;
    final targetWorkH = (oriented.height * targetWorkW / oriented.width)
        .round()
        .clamp(100, 3000);
    workImg = img.copyResize(
      oriented,
      width: targetWorkW,
      height: targetWorkH,
      interpolation: img.Interpolation.linear,
    );
    invScale = origW / workImg.width;
  } else {
    workImg = oriented;
    invScale = 1.0;
  }

  final scaleToWork = 1.0 / invScale;
  final scaledQrCorners =
      payload.qrCorners
          ?.map((p) => Point2D(p.x * scaleToWork, p.y * scaleToWork))
          .toList();

  final w = workImg.width;
  final h = workImg.height;

  // Ekstrak buffer luminance 1D sekali jalan (zero-allocation reads)
  final gray = _extractLuminanceBuffer(workImg);
  final blur = _boxBlur3x3(gray, w, h, passes: 1);

  // Tahap 1: Segmentasi kertas putih & isolasi background meja/clipboard
  final paperInfo = _segmentWhitePaper(gray, w, h);

  // Tahap 2: Deteksi 3-Tier Lokasi Box OMR (Marker Sudut -> QR/Kertas -> Template Grid Registration)
  final alignment = _alignOmrBox(
    gray: gray,
    blur: blur,
    w: w,
    h: h,
    paper: paperInfo,
    omrLayout: payload.omrLayout,
    qrCorners: scaledQrCorners,
  );

  final workCorners = alignment.corners; // TL, TR, BR, BL pada workImg

  // Homography antara kanvas standar [1000 x 1076] dan workImg
  final dstBox = [
    const Point2D(0, 0),
    Point2D(OmrScannerService.targetW - 1.0, 0),
    Point2D(OmrScannerService.targetW - 1.0, OmrScannerService.targetH - 1.0),
    Point2D(0, OmrScannerService.targetH - 1.0),
  ];

  // dst -> workImg (digunakan langsung untuk sampling & proyeksi AR balik ke kamera!)
  final hDstToWork = _getPerspectiveMatrix(dstBox, workCorners);

  // Tahap 3: Evaluasi isi bulatan + micro-refinement + bangun visual AR / preview JPEG
  return _evaluateAndGrade(
    workImg: workImg,
    gray: gray,
    workW: w,
    workH: h,
    invScale: invScale,
    origSize: Size(origW, origH),
    workCorners: workCorners,
    hDstToWork: hDstToWork,
    omrLayout: payload.omrLayout,
    answerKeys: payload.answerKeys,
    paperBrightness: paperInfo.paperWhite,
    annotateImage: payload.annotateImage,
  );
}

// ============================================================================
// FAST LOW-LEVEL IMAGE BUFFERS
// ============================================================================

Uint8List _extractLuminanceBuffer(img.Image src) {
  final buf = Uint8List(src.width * src.height);
  int idx = 0;
  for (final p in src) {
    // Rec. 601 luminance integer approximation
    buf[idx++] = ((p.r * 77 + p.g * 150 + p.b * 29).round() >> 8).clamp(0, 255);
  }
  return buf;
}

Uint8List _boxBlur3x3(Uint8List src, int w, int h, {int passes = 1}) {
  Uint8List current = Uint8List.fromList(src);
  Uint8List next = Uint8List(w * h);

  for (int pass = 0; pass < passes; pass++) {
    for (int y = 0; y < h; y++) {
      final yPrev = y > 0 ? y - 1 : 0;
      final yNext = y < h - 1 ? y + 1 : h - 1;
      final r0 = yPrev * w;
      final r1 = y * w;
      final r2 = yNext * w;

      for (int x = 0; x < w; x++) {
        final xPrev = x > 0 ? x - 1 : 0;
        final xNext = x < w - 1 ? x + 1 : w - 1;
        final sum =
            current[r0 + xPrev] +
            current[r0 + x] +
            current[r0 + xNext] +
            current[r1 + xPrev] +
            current[r1 + x] +
            current[r1 + xNext] +
            current[r2 + xPrev] +
            current[r2 + x] +
            current[r2 + xNext];
        next[r1 + x] = (sum ~/ 9).clamp(0, 255);
      }
    }
    final tmp = current;
    current = next;
    next = tmp;
  }
  return current;
}

// ============================================================================
// PAPER SEGMENTATION & 3-TIER OMR ALIGNMENT
// ============================================================================

class _PaperInfo {
  final double left;
  final double right;
  final double top;
  final double bot;
  final double paperWhite;
  final double skewAngleRad;

  const _PaperInfo({
    required this.left,
    required this.right,
    required this.top,
    required this.bot,
    required this.paperWhite,
    required this.skewAngleRad,
  });

  double get width => (right - left).clamp(40.0, 4000.0);
  double get height => (bot - top).clamp(40.0, 4000.0);
  double get centerX => (left + right) * 0.5;
}

_PaperInfo _segmentWhitePaper(Uint8List gray, int w, int h) {
  // Ambil sampel area tengah (0.25..0.75) untuk mengestimasi putih kertas (80th percentile)
  final samples = <int>[];
  final stepY = math.max(1, (h * 0.025).round());
  final stepX = math.max(1, (w * 0.025).round());

  for (int y = (h * 0.28).round(); y < (h * 0.72).round(); y += stepY) {
    final rowOff = y * w;
    for (int x = (w * 0.25).round(); x < (w * 0.75).round(); x += stepX) {
      samples.add(gray[rowOff + x]);
    }
  }
  samples.sort();
  final p80 =
      samples.isNotEmpty ? samples[(samples.length * 0.80).floor()] : 210;
  final paperWhite = p80.toDouble().clamp(145.0, 250.0);
  final brightThresh = (paperWhite * 0.76).round().clamp(115, 195);

  // Cari bentangan kertas terlebar (median left & right) di baris tengah kertas
  final lefts = <int>[];
  final rights = <int>[];
  final scanYs = <double>[];

  for (double yf = 0.34; yf <= 0.66; yf += 0.04) {
    final y = (h * yf).round().clamp(0, h - 1);
    final rowOff = y * w;
    // Cari run bright terpanjang
    int bestStart = -1;
    int bestLen = 0;
    int curStart = -1;

    for (int x = 0; x < w; x++) {
      if (gray[rowOff + x] >= brightThresh) {
        if (curStart == -1) curStart = x;
      } else if (curStart != -1) {
        // Toleransi celah teks/garis kecil <= 6px di dalam kertas
        final len = x - curStart;
        if (len > bestLen) {
          bestLen = len;
          bestStart = curStart;
        }
        // Cek lookahead 8px apakah lanjut kertas putih
        bool resumes = false;
        final maxLook = math.min(w, x + 8);
        for (int lx = x + 1; lx < maxLook; lx++) {
          if (gray[rowOff + lx] >= brightThresh) {
            resumes = true;
            x = lx;
            break;
          }
        }
        if (!resumes) {
          curStart = -1;
        }
      }
    }
    if (curStart != -1) {
      final len = w - curStart;
      if (len > bestLen) {
        bestLen = len;
        bestStart = curStart;
      }
    }

    if (bestStart != -1 && bestLen > w * 0.35) {
      lefts.add(bestStart);
      rights.add(bestStart + bestLen);
      scanYs.add(y.toDouble());
    }
  }

  double pLeft = w * 0.08;
  double pRight = w * 0.92;
  double skewRad = 0.0;

  if (lefts.isNotEmpty) {
    final sortedL = List<int>.from(lefts)..sort();
    final sortedR = List<int>.from(rights)..sort();
    pLeft = sortedL[sortedL.length ~/ 2].toDouble();
    pRight = sortedR[sortedR.length ~/ 2].toDouble();

    if (lefts.length >= 3) {
      // Hitung rotasi murni kertas dari rata-rata kemiringan kiri & kanan
      // (menghindari distorsi trapesium / perspektif dari kemiringan 1 sisi saja)
      final dy = scanYs.last - scanYs.first;
      if (dy > 20) {
        final hasLeft = pLeft > 4 && pLeft < w * 0.4;
        final hasRight = pRight < w - 5 && pRight > w * 0.6;
        if (hasLeft && hasRight) {
          final angL = math.atan2(lefts.last - lefts.first, dy);
          final angR = math.atan2(rights.last - rights.first, dy);
          // Hanya anggap rotasi bila kedua sisi miring ke arah yang sama
          if (angL * angR > 0) {
            final avgAng = (angL + angR) * 0.5;
            if (avgAng.abs() < 0.14) skewRad = avgAng;
          }
        }
      }
    }
  }

  // Cari batas atas & bawah kertas di sepanjang midline horizontal
  final midX = ((pLeft + pRight) * 0.5).round().clamp(0, w - 1);
  int pTop = (h * 0.06).round();
  int pBot = (h * 0.94).round();
  final centerY = (h * 0.50).round();

  for (int y = centerY; y >= 0; y--) {
    if (gray[y * w + midX] < brightThresh) {
      bool stillDark = true;
      for (int ly = math.max(0, y - 6); ly < y; ly++) {
        if (gray[ly * w + midX] >= brightThresh) {
          stillDark = false;
          break;
        }
      }
      if (stillDark) {
        pTop = y;
        break;
      }
    }
  }
  for (int y = centerY; y < h; y++) {
    if (gray[y * w + midX] < brightThresh) {
      bool stillDark = true;
      for (int ly = y + 1; ly <= math.min(h - 1, y + 6); ly++) {
        if (gray[ly * w + midX] >= brightThresh) {
          stillDark = false;
          break;
        }
      }
      if (stillDark) {
        pBot = y;
        break;
      }
    }
  }

  return _PaperInfo(
    left: pLeft,
    right: pRight,
    top: pTop.toDouble(),
    bot: pBot.toDouble(),
    paperWhite: paperWhite,
    skewAngleRad: skewRad,
  );
}

class _AlignmentResult {
  final List<Point2D> corners;
  const _AlignmentResult(this.corners);
}

_AlignmentResult _alignOmrBox({
  required Uint8List gray,
  required Uint8List blur,
  required int w,
  required int h,
  required _PaperInfo paper,
  required OmrLayoutModel omrLayout,
  required List<Point2D>? qrCorners,
}) {
  // Cek sudut kemiringan dan skala estimasi dari QR corners bila ada
  double qrTheta = paper.skewAngleRad;
  double? qrWbEst;
  double? qrBotY;

  if (qrCorners != null && qrCorners.length >= 4) {
    final qTL = qrCorners[0];
    final qTR = qrCorners[1];
    final qBR = qrCorners[2];
    final qBL = qrCorners[3];
    final qW = qTL.distanceTo(qTR);
    final qH = qTL.distanceTo(qBL);
    if (qW > 8 && qH > 8) {
      final rawAng = math.atan2(qTR.y - qTL.y, qTR.x - qTL.x);
      if (rawAng.abs() < 0.25) {
        qrTheta = rawAng;
      }
      // Di print_ljk.php: QR size 24mm, omr anchor box width 172mm -> ratio ~7.17
      qrWbEst = qW * (omrLayout.boxWidthMm / 24.0);
      qrBotY = math.max(qBL.y, qBR.y);
    }
  }

  // TIER 1: Deteksi 4 Kotak Hitam Fiducial Marker (7mm x 7mm) HANYA di dalam area kertas putih
  final fiducialCorners = _detectFiducialSquaresInsidePaper(
    gray: gray,
    w: w,
    h: h,
    paper: paper,
    boxRatioHW: omrLayout.boxHeightMm / omrLayout.boxWidthMm,
    qrBotY: qrBotY,
  );

  // Gunakan parameter grid untuk Tier 2/3 search
  final gridFeatures = _GridFeaturePoints.fromLayout(omrLayout);

  if (fiducialCorners != null) {
    // Fiducial 4 kotak hitam sudah sangat presisi; hanya uji micro-nudge global +-1.5px tanpa distorsi skala
    final nudged = _microNudgeTranslationOnly(
      gray: gray,
      w: w,
      h: h,
      corners: fiducialCorners,
      features: gridFeatures,
      maxNudgePx: 1.5,
    );
    return _AlignmentResult(nudged);
  }

  // TIER 2 + TIER 3: Sheet + QR + Coarse-to-Fine Template Grid Auto-Registration
  // (Mengatasi LJK lama tanpa 4 kotak hitam atau kotak sudut terpotong/terhalang)
  final wbFromPaper = paper.width * (omrLayout.boxWidthMm / 210.0);
  double baseWb = wbFromPaper.clamp(w * 0.35, w * 0.96);
  if (qrWbEst != null && qrWbEst > w * 0.30 && qrWbEst < w * 1.15) {
    // Jika kertas putih penuh tampak, gabungkan keduanya
    baseWb = (wbFromPaper * 0.45 + qrWbEst * 0.55).clamp(w * 0.35, w * 0.96);
  }

  final hwRatio = omrLayout.boxHeightMm / omrLayout.boxWidthMm;

  // Bangun rentang pencarian Y berdasarkan posisi kertas & QR
  final yMinSearch =
      qrBotY != null
          ? (qrBotY + (baseWb / 7.17) * 0.5).clamp(h * 0.08, h * 0.60)
          : (paper.top + paper.height * 0.08).clamp(h * 0.08, h * 0.55);
  final yMaxSearch =
      qrBotY != null
          ? (qrBotY + (baseWb / 7.17) * 3.4).clamp(yMinSearch + 20, h * 0.65)
          : (paper.bot - baseWb * hwRatio * 0.45).clamp(
            yMinSearch + 20,
            h * 0.62,
          );

  double bestScore = -1e12;
  double bestX0 = paper.centerX - baseWb * 0.5;
  double bestY0 = yMinSearch;
  double bestWb = baseWb;

  final scales = [0.82, 0.88, 0.94, 1.00, 1.06, 1.12, 1.18];
  final stepDx = math.max(3.0, (w * 0.010));
  final stepDy = math.max(2.5, (h * 0.004));
  final maxDx = math.max(24.0, paper.width * 0.14);

  final cosT = math.cos(qrTheta);
  final sinT = math.sin(qrTheta);

  // Coarse search
  for (final sc in scales) {
    final wb = baseWb * sc;
    final hb = wb * hwRatio;
    if (wb < w * 0.30 || wb > w * 1.10) continue;
    final x0Base = paper.centerX - wb * 0.5;

    for (double dx = -maxDx; dx <= maxDx; dx += stepDx) {
      final x0 = x0Base + dx;
      if (x0 < -wb * 0.15 || x0 + wb > w + wb * 0.15) continue;

      for (double y0 = yMinSearch; y0 <= yMaxSearch; y0 += stepDy) {
        if (y0 + hb * 0.55 > h) continue;
        final score = _scoreGridHypothesis(
          blur: blur,
          w: w,
          h: h,
          x0: x0,
          y0: y0,
          wb: wb,
          hb: hb,
          cosT: cosT,
          sinT: sinT,
          features: gridFeatures,
          paperWhite: paper.paperWhite,
        );
        if (score > bestScore) {
          bestScore = score;
          bestX0 = x0;
          bestY0 = y0;
          bestWb = wb;
        }
      }
    }
  }

  // Anti-periodicity guard: bandingkan tepat +-1 baris dan +-1 kolom opsi
  final shiftY = gridFeatures.stepY * (bestWb * hwRatio);
  final shiftX = gridFeatures.stepX * bestWb;
  final anchorX0 = bestX0;
  final anchorY0 = bestY0;
  for (final sy in [-shiftY, 0.0, shiftY]) {
    for (final sx in [-shiftX, 0.0, shiftX]) {
      if (sy == 0.0 && sx == 0.0) continue;
      final candX = anchorX0 + sx;
      final candY = anchorY0 + sy;
      if (candY < 0 || candY + bestWb * hwRatio * 0.55 > h) continue;
      final sc = _scoreGridHypothesis(
        blur: blur,
        w: w,
        h: h,
        x0: candX,
        y0: candY,
        wb: bestWb,
        hb: bestWb * hwRatio,
        cosT: cosT,
        sinT: sinT,
        features: gridFeatures,
        paperWhite: paper.paperWhite,
      );
      if (sc > bestScore) {
        bestScore = sc;
        bestX0 = candX;
        bestY0 = candY;
      }
    }
  }

  // Fine search (+- 10px sekitar hasil terbaik + fine skew tilt)
  double bestFineScore = bestScore;
  double fineX0 = bestX0;
  double fineY0 = bestY0;
  double fineWb = bestWb;
  double fineTheta = qrTheta;

  final fineStep = math.max(1.5, w * 0.003);
  final fineRangeScale = bestWb * 0.06;

  for (
    double ds = -fineRangeScale;
    ds <= fineRangeScale;
    ds += math.max(2.0, fineStep * 1.3)
  ) {
    final wb = bestWb + ds;
    final hb = wb * hwRatio;
    for (double dx = -fineStep * 5; dx <= fineStep * 5; dx += fineStep) {
      for (double dy = -fineStep * 5; dy <= fineStep * 5; dy += fineStep) {
        final x0 = bestX0 + dx - ds * 0.5;
        final y0 = bestY0 + dy;
        final score = _scoreGridHypothesis(
          blur: blur,
          w: w,
          h: h,
          x0: x0,
          y0: y0,
          wb: wb,
          hb: hb,
          cosT: cosT,
          sinT: sinT,
          features: gridFeatures,
          paperWhite: paper.paperWhite,
        );
        if (score > bestFineScore) {
          bestFineScore = score;
          fineX0 = x0;
          fineY0 = y0;
          fineWb = wb;
        }
      }
    }
  }

  // Test fine angle tweak (-3 deg .. +3 deg around qrTheta)
  for (double dAng = -0.055; dAng <= 0.056; dAng += 0.015) {
    final ang = qrTheta + dAng;
    final cA = math.cos(ang);
    final sA = math.sin(ang);
    final hb = fineWb * hwRatio;
    final sc = _scoreGridHypothesis(
      blur: blur,
      w: w,
      h: h,
      x0: fineX0,
      y0: fineY0,
      wb: fineWb,
      hb: hb,
      cosT: cA,
      sinT: sA,
      features: gridFeatures,
      paperWhite: paper.paperWhite,
    );
    if (sc > bestFineScore) {
      bestFineScore = sc;
      fineTheta = ang;
    }
  }

  final fineHb = fineWb * hwRatio;
  final cF = math.cos(fineTheta);
  final sF = math.sin(fineTheta);
  final cx = fineX0 + fineWb * 0.5;
  final cy = fineY0 + fineHb * 0.5;

  Point2D rot(double lx, double ly) {
    final rx = lx - cx;
    final ry = ly - cy;
    return Point2D(cx + rx * cF - ry * sF, cy + rx * sF + ry * cF);
  }

  final corners = [
    rot(fineX0, fineY0),
    rot(fineX0 + fineWb, fineY0),
    rot(fineX0 + fineWb, fineY0 + fineHb),
    rot(fineX0, fineY0 + fineHb),
  ];

  // Refine 4 corners independently +-2px untuk perspektif kecil
  final finalCorners = _refineQuadLocally(
    blur: blur,
    w: w,
    h: h,
    initCorners: corners,
    features: gridFeatures,
  );

  return _AlignmentResult(finalCorners);
}

/// Deteksi 4 kotak hitam solid (7mm x 7mm) di dalam area kertas putih
List<Point2D>? _detectFiducialSquaresInsidePaper({
  required Uint8List gray,
  required int w,
  required int h,
  required _PaperInfo paper,
  required double boxRatioHW,
  double? qrBotY,
}) {
  final darkThresh = (paper.paperWhite * 0.50).round().clamp(55, 130);
  final paperBrightThresh = (paper.paperWhite * 0.72).round().clamp(110, 190);
  final estBoxW = paper.width * (172.0 / 210.0);
  final estMarkerSide = (estBoxW * (7.0 / 172.0)).clamp(6.0, 60.0);
  final minSide = math.max(5, (estMarkerSide * 0.58).round());
  final maxSide = math.max(10, (estMarkerSide * 2.25).round());
  final minArea = math.max(16, (minSide * minSide * 0.62).round());

  // Area pencarian cukup longgar ke samping/bawah agar keystone kertas tidak memotong kotak sudut
  final padX = math.max(4.0, paper.width * 0.06);
  final pLeft = (paper.left - padX).round().clamp(1, w - 2);
  final pRight = (paper.right + padX).round().clamp(1, w - 2);
  final pTop =
      qrBotY != null
          ? (qrBotY + 3.0).round().clamp(1, h - 2)
          : (paper.top + paper.height * 0.14).round().clamp(1, h - 2);
  final pBot = (paper.bot + 8.0).round().clamp(1, h - 2);

  if (pRight - pLeft < 40 || pBot - pTop < 40) return null;

  final visited = Uint8List(w * h);
  final candidates = <_BlobCandidate>[];
  final queue = <int>[];

  for (int y = pTop; y < pBot; y++) {
    final rowOff = y * w;
    for (int x = pLeft; x < pRight; x++) {
      final idx = rowOff + x;
      if (visited[idx] != 0 || gray[idx] >= darkThresh) continue;

      // BFS flood-fill 4-connected component
      visited[idx] = 1;
      queue.clear();
      queue.add(idx);
      int head = 0;

      int minX = x, maxX = x, minY = y, maxY = y;
      double sumX = 0, sumY = 0;
      int area = 0;
      bool tooBig = false;

      while (head < queue.length) {
        final cur = queue[head++];
        final cy = cur ~/ w;
        final cx = cur - cy * w;
        sumX += cx;
        sumY += cy;
        area++;
        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
        if (cy < minY) minY = cy;
        if (cy > maxY) maxY = cy;

        if (maxX - minX > maxSide * 2 ||
            maxY - minY > maxSide * 2 ||
            area > maxSide * maxSide * 2) {
          tooBig = true;
          // Lanjutkan penandaan agar tidak dicek lagi, tapi tidak valid
        }

        // 4 tetangga
        if (cx > pLeft) {
          final n = cur - 1;
          if (visited[n] == 0 && gray[n] < darkThresh) {
            visited[n] = 1;
            queue.add(n);
          }
        }
        if (cx < pRight - 1) {
          final n = cur + 1;
          if (visited[n] == 0 && gray[n] < darkThresh) {
            visited[n] = 1;
            queue.add(n);
          }
        }
        if (cy > pTop) {
          final n = cur - w;
          if (visited[n] == 0 && gray[n] < darkThresh) {
            visited[n] = 1;
            queue.add(n);
          }
        }
        if (cy < pBot - 1) {
          final n = cur + w;
          if (visited[n] == 0 && gray[n] < darkThresh) {
            visited[n] = 1;
            queue.add(n);
          }
        }
      }

      if (tooBig || area < minArea) continue;

      final bw = (maxX - minX + 1).toDouble();
      final bh = (maxY - minY + 1).toDouble();
      if (bw < minSide || bw > maxSide || bh < minSide || bh > maxSide) {
        continue;
      }

      final aspect = bw / bh;
      if (aspect < 0.55 || aspect > 1.80) continue;

      final fillFactor = area / (bw * bh);
      if (fillFactor < 0.60) continue;

      // Uji kesikuan 4 sudut bounding box untuk membedakan kotak sudut (hitam di sudut)
      // dari bulatan jawaban terarsir penuh (putih di ke-4 sudut bounding box)
      final cornerInX = math.max(1, (bw * 0.15).round());
      final cornerInY = math.max(1, (bh * 0.15).round());
      final cornerThresh = darkThresh + 20;
      int darkCorners = 0;
      if (gray[(minY + cornerInY) * w + (minX + cornerInX)] < cornerThresh) {
        darkCorners++;
      }
      if (gray[(minY + cornerInY) * w + (maxX - cornerInX)] < cornerThresh) {
        darkCorners++;
      }
      if (gray[(maxY - cornerInY) * w + (minX + cornerInX)] < cornerThresh) {
        darkCorners++;
      }
      if (gray[(maxY - cornerInY) * w + (maxX - cornerInX)] < cornerThresh) {
        darkCorners++;
      }
      if (darkCorners < 3) continue;

      // Pastikan dikelilingi kertas putih (bukan teks menempel atau pinggiran meja gelap)
      final offset = math.max(3, (bw * 0.45).round());
      final cpx = (minX + maxX) ~/ 2;
      final cpy = (minY + maxY) ~/ 2;
      int brightSides = 0;
      if (minX - offset >= 0 &&
          gray[cpy * w + (minX - offset)] >= paperBrightThresh) {
        brightSides++;
      }
      if (maxX + offset < w &&
          gray[cpy * w + (maxX + offset)] >= paperBrightThresh) {
        brightSides++;
      }
      if (minY - offset >= 0 &&
          gray[(minY - offset) * w + cpx] >= paperBrightThresh) {
        brightSides++;
      }
      if (maxY + offset < h &&
          gray[(maxY + offset) * w + cpx] >= paperBrightThresh) {
        brightSides++;
      }

      if (brightSides < 2) continue;

      candidates.add(
        _BlobCandidate(
          center: Point2D(sumX / area, sumY / area),
          sizeScore: fillFactor * (1.0 - (aspect - 1.0).abs() * 0.3),
        ),
      );
    }
  }

  if (candidates.length < 3) return null;

  // Batasi kandidat hanya di pinggir kiri (<32% kertas) dan pinggir kanan (>68% kertas)
  // agar bulatan jawaban di area tengah tidak pernah dianggap marker sudut!
  final leftBoundX = paper.left + paper.width * 0.32;
  final rightBoundX = paper.right - paper.width * 0.32;
  final midY = (pTop + pBot) * 0.5;

  final tlList = <_BlobCandidate>[];
  final trList = <_BlobCandidate>[];
  final brList = <_BlobCandidate>[];
  final blList = <_BlobCandidate>[];

  for (final c in candidates) {
    final cx = c.center.x;
    final cy = c.center.y;
    if (cx <= leftBoundX && cy < midY) {
      tlList.add(c);
    } else if (cx >= rightBoundX && cy < midY) {
      trList.add(c);
    } else if (cx >= rightBoundX && cy >= midY) {
      brList.add(c);
    } else if (cx <= leftBoundX && cy >= midY) {
      blList.add(c);
    }
  }

  // Urutkan tiap sudut agar kandidat terluar & paling kotak diuji lebih dulu
  final paperCenter = Point2D(paper.centerX, midY);
  int cmpCand(_BlobCandidate a, _BlobCandidate b) {
    final sa = a.sizeScore * 100 + a.center.distanceTo(paperCenter) * 0.35;
    final sb = b.sizeScore * 100 + b.center.distanceTo(paperCenter) * 0.35;
    return sb.compareTo(sa);
  }

  tlList.sort(cmpCand);
  trList.sort(cmpCand);
  brList.sort(cmpCand);
  blList.sort(cmpCand);

  bool isValidQuad(Point2D tl, Point2D tr, Point2D br, Point2D bl) {
    // Pastikan ke-4 sudut berada di dalam batas gambar (dengan toleransi tipis 12px)
    for (final p in [tl, tr, br, bl]) {
      if (p.x < -12 || p.x > w + 12 || p.y < -12 || p.y > h + 12) {
        return false;
      }
    }

    final topW = tl.distanceTo(tr);
    final botW = bl.distanceTo(br);
    final leftH = tl.distanceTo(bl);
    final rightH = tr.distanceTo(br);

    if (topW < paper.width * 0.48 || botW < paper.width * 0.48) return false;
    if ((topW - botW).abs() / math.max(topW, botW) > 0.20) return false;
    if ((leftH - rightH).abs() / math.max(leftH, rightH) > 0.20) return false;

    final avgW = (topW + botW) * 0.5;
    final avgH = (leftH + rightH) * 0.5;
    final ratio = avgH / avgW;
    if ((ratio - boxRatioHW).abs() > 0.24) return false;

    // Cek ortogonalitas sudut (menolak jajaran genjang miring ekstrem > ~14 derajat shear)
    final vTopX = tr.x - tl.x;
    final vTopY = tr.y - tl.y;
    final vLeftX = bl.x - tl.x;
    final vLeftY = bl.y - tl.y;
    final dotTL = (vTopX * vLeftX + vTopY * vLeftY).abs();
    final cosTL = dotTL / math.max(1.0, topW * leftH);
    if (cosTL > 0.22) return false;

    return true;
  }

  final tlCands =
      tlList.isNotEmpty ? tlList.take(2).map((e) => e.center).toList() : [null];
  final trCands =
      trList.isNotEmpty ? trList.take(2).map((e) => e.center).toList() : [null];
  final brCands =
      brList.isNotEmpty ? brList.take(2).map((e) => e.center).toList() : [null];
  final blCands =
      blList.isNotEmpty ? blList.take(2).map((e) => e.center).toList() : [null];

  for (final topLeft in tlCands) {
    for (final topRight in trCands) {
      for (final botRight in brCands) {
        for (final botLeft in blCands) {
          final foundCount =
              [
                topLeft,
                topRight,
                botRight,
                botLeft,
              ].where((e) => e != null).length;
          if (foundCount < 3) continue;

          final pTL = topLeft ?? (topRight! + botLeft! - botRight!);
          final pTR = topRight ?? (topLeft! + botRight! - botLeft!);
          final pBR = botRight ?? (topRight! + botLeft! - topLeft!);
          final pBL = botLeft ?? (topLeft! + botRight! - topRight!);

          if (isValidQuad(pTL, pTR, pBR, pBL)) {
            return [pTL, pTR, pBR, pBL];
          }
        }
      }
    }
  }

  return null;
}

class _BlobCandidate {
  final Point2D center;
  final double sizeScore;
  const _BlobCandidate({required this.center, required this.sizeScore});
}

// ============================================================================
// COARSE-TO-FINE PRINTED GRID REGISTRATION
// ============================================================================

class _GridFeaturePoints {
  final List<List<Point2D>> questionRows; // per soal: titik opsi A..E
  final List<Point2D> numPts; // titik nomor soal (1., 2., ...)
  final List<Point2D> headerPts;
  final List<Point2D> gapPts;
  final double stepX;
  final double stepY;

  const _GridFeaturePoints({
    required this.questionRows,
    required this.numPts,
    required this.headerPts,
    required this.gapPts,
    this.stepX = 0.087,
    this.stepY = 0.036,
  });

  factory _GridFeaturePoints.fromLayout(OmrLayoutModel layout) {
    final labels = layout.optionLabels;
    final questions = layout.questions;
    if (questions.isEmpty || labels.isEmpty) {
      return const _GridFeaturePoints(
        questionRows: [],
        numPts: [],
        headerPts: [],
        gapPts: [],
      );
    }

    final byCol = <int, List<OmrQuestionLayoutModel>>{};
    for (final q in questions) {
      byCol.putIfAbsent(q.col, () => []).add(q);
    }

    final col1 = byCol.values.first;
    final stepY = col1.length > 1 ? (col1[1].y - col1[0].y).abs() : 0.036;
    final firstOpts = [
      for (final l in labels)
        if (col1[0].options[l] != null) col1[0].options[l]!,
    ];
    final stepX =
        firstOpts.length > 1 ? (firstOpts[1].x - firstOpts[0].x).abs() : 0.087;

    final qRows = <List<Point2D>>[];
    final nPts = <Point2D>[];
    final hdrPts = <Point2D>[];
    final gapPts = <Point2D>[];

    for (final colQs in byCol.values) {
      if (colQs.isEmpty) continue;
      final firstQ = colQs.first;
      final lastQ = colQs.last;

      // Header A B C D E pada top: 2.8%, serta margin bersih tepat di atas header (top: 0.6%)
      for (final l in labels) {
        final opt = firstQ.options[l];
        if (opt != null) {
          hdrPts.add(Point2D(opt.x, 0.028));
          gapPts.add(Point2D(opt.x, 0.006));
        }
      }

      // Guard kosong di kanan opsi terakhir dan di atas num_x pada baris header
      final lastOptX = firstQ.options[labels.last]?.x ?? 0.45;
      final rxGuard = lastOptX + stepX * 0.72;
      gapPts.add(Point2D(firstQ.numX, 0.006));
      gapPts.add(Point2D(firstQ.numX, 0.028));
      gapPts.add(Point2D(rxGuard, 0.028));

      for (final q in colQs) {
        nPts.add(Point2D(q.numX, q.y));
        final row = <Point2D>[];
        for (int i = 0; i < labels.length; i++) {
          final opt = q.options[labels[i]];
          if (opt != null) {
            row.add(Point2D(opt.x, q.y));
          }
          if (i < labels.length - 1) {
            final nextOpt = q.options[labels[i + 1]];
            if (opt != null && nextOpt != null) {
              gapPts.add(Point2D((opt.x + nextOpt.x) * 0.5, q.y));
            }
          }
        }
        qRows.add(row);
        gapPts.add(Point2D(rxGuard, q.y));
      }

      // Celah vertikal antar baris
      for (int i = 0; i < colQs.length - 1; i++) {
        final yMid = (colQs[i].y + colQs[i + 1].y) * 0.5;
        for (final l in labels) {
          final opt = firstQ.options[l];
          if (opt != null) {
            gapPts.add(Point2D(opt.x, yMid));
          }
        }
      }

      // Guard baris tepat di bawah soal terakhir (mencegah pergeseran ke bawah/atas 1 baris)
      if (lastQ.row < layout.rowsPerCol) {
        final yBelow = lastQ.y + stepY;
        for (final l in labels) {
          final opt = firstQ.options[l];
          if (opt != null) {
            gapPts.add(Point2D(opt.x, yBelow));
          }
        }
        gapPts.add(Point2D(firstQ.numX, yBelow));
      }
    }

    return _GridFeaturePoints(
      questionRows: qRows,
      numPts: nPts,
      headerPts: hdrPts,
      gapPts: gapPts,
      stepX: stepX,
      stepY: stepY,
    );
  }
}

double _scoreGridHypothesis({
  required Uint8List blur,
  required int w,
  required int h,
  required double x0,
  required double y0,
  required double wb,
  required double hb,
  required double cosT,
  required double sinT,
  required _GridFeaturePoints features,
  required double paperWhite,
}) {
  if (features.questionRows.isEmpty || features.gapPts.isEmpty) return 0.0;

  final cx = x0 + wb * 0.5;
  final cy = y0 + hb * 0.5;

  int sampleAt(double nx, double ny) {
    final dx = x0 + nx * wb - cx;
    final dy = y0 + ny * hb - cy;
    final ix = (cx + dx * cosT - dy * sinT).round();
    final iy = (cy + dx * sinT + dy * cosT).round();
    if (ix < 0 || ix >= w || iy < 0 || iy >= h) return -1;
    return blur[iy * w + ix];
  }

  double gapSum = 0.0;
  for (final g in features.gapPts) {
    final v = sampleAt(g.x, g.y);
    if (v < 0) return -1e9;
    gapSum += v;
  }
  final bg = gapSum / features.gapPts.length;
  if (bg < paperWhite * 0.72) return -1e9;

  double score = 0.0;

  for (final row in features.questionRows) {
    int rowHits = 0;
    for (final p in row) {
      final v = sampleAt(p.x, p.y);
      if (v < 0) return -1e9;
      final diff = bg - v;
      if (diff > 0) {
        score += diff < 28.0 ? diff : 28.0;
      }
      if (diff > 11.0) {
        rowHits++;
        score += 22.0;
      }
    }
    if (rowHits == 0) {
      score -= 140.0;
    }
  }

  int hdrHits = 0;
  for (final hp in features.headerPts) {
    final v = sampleAt(hp.x, hp.y);
    if (v >= 0) {
      final diff = bg - v;
      if (diff > 0) score += (diff < 24.0 ? diff : 24.0) * 2.2;
      if (diff > 8.0) hdrHits++;
    }
  }
  if (features.headerPts.isNotEmpty && hdrHits == 0) {
    score -= 90.0;
  }

  for (final np in features.numPts) {
    final v = sampleAt(np.x, np.y);
    if (v >= 0) {
      final diff = bg - v;
      if (diff > 8.0) score += (diff < 24.0 ? diff : 24.0) * 0.8 + 10.0;
    }
  }

  for (final g in features.gapPts) {
    final v = sampleAt(g.x, g.y);
    if (v >= 0) {
      final diff = bg - v;
      if (diff > 14.0) {
        score -= (diff < 32.0 ? diff : 32.0) * 1.3;
      }
    }
  }

  return score;
}

List<Point2D> _refineQuadLocally({
  required Uint8List blur,
  required int w,
  required int h,
  required List<Point2D> initCorners,
  required _GridFeaturePoints features,
}) {
  if (features.questionRows.isEmpty || features.gapPts.isEmpty) {
    return initCorners;
  }

  var bestCorners = List<Point2D>.from(initCorners);
  double evalQuad(List<Point2D> c) {
    // Map unit square [0..1] -> quad c[0..3] secara bilinear untuk sampling cepat
    int sampleBilinear(double nx, double ny) {
      final top = Point2D(
        c[0].x + (c[1].x - c[0].x) * nx,
        c[0].y + (c[1].y - c[0].y) * nx,
      );
      final bot = Point2D(
        c[3].x + (c[2].x - c[3].x) * nx,
        c[3].y + (c[2].y - c[3].y) * nx,
      );
      final ix = (top.x + (bot.x - top.x) * ny).round();
      final iy = (top.y + (bot.y - top.y) * ny).round();
      if (ix < 0 || ix >= w || iy < 0 || iy >= h) return -1;
      return blur[iy * w + ix];
    }

    double gSum = 0;
    for (final g in features.gapPts) {
      final v = sampleBilinear(g.x, g.y);
      if (v < 0) return -1e9;
      gSum += v;
    }
    final bg = gSum / features.gapPts.length;
    if (bg < 140) return -1e9;

    double sc = 0;
    for (final row in features.questionRows) {
      for (final p in row) {
        final v = sampleBilinear(p.x, p.y);
        if (v < 0) return -1e9;
        final diff = bg - v;
        if (diff > 0) sc += diff < 28.0 ? diff : 28.0;
        if (diff > 10.0) sc += 18.0;
      }
    }
    for (final hp in features.headerPts) {
      final v = sampleBilinear(hp.x, hp.y);
      if (v >= 0 && bg - v > 10.0) sc += 14.0;
    }
    for (final g in features.gapPts) {
      final v = sampleBilinear(g.x, g.y);
      if (v >= 0 && bg - v > 15.0) sc -= 20.0;
    }
    return sc;
  }

  double bestScore = evalQuad(bestCorners);
  final step = math.max(1.5, w * 0.003);

  // Pergeseran translasi halus seluruh quad + skala simetris
  for (final s in [step, 0.8]) {
    int iters = 0;
    bool improved = true;
    while (improved && iters++ < 5) {
      improved = false;
      final moves = [
        [Point2D(s, 0), Point2D(s, 0), Point2D(s, 0), Point2D(s, 0)],
        [Point2D(-s, 0), Point2D(-s, 0), Point2D(-s, 0), Point2D(-s, 0)],
        [Point2D(0, s), Point2D(0, s), Point2D(0, s), Point2D(0, s)],
        [Point2D(0, -s), Point2D(0, -s), Point2D(0, -s), Point2D(0, -s)],
      ];
      for (final mv in moves) {
        final cand = [
          bestCorners[0] + mv[0],
          bestCorners[1] + mv[1],
          bestCorners[2] + mv[2],
          bestCorners[3] + mv[3],
        ];
        final sc = evalQuad(cand);
        if (sc > bestScore + 1.0) {
          bestScore = sc;
          bestCorners = cand;
          improved = true;
          break;
        }
      }
    }
  }

  return bestCorners;
}

/// Pergeseran translasi super-halus (+-maxNudgePx) khusus saat 4 marker fiducial telah ditemukan,
/// memastikan tidak ada distorsi lebar maupun kemiringan yang merusak posisi marker sejati.
List<Point2D> _microNudgeTranslationOnly({
  required Uint8List gray,
  required int w,
  required int h,
  required List<Point2D> corners,
  required _GridFeaturePoints features,
  required double maxNudgePx,
}) {
  if (features.questionRows.isEmpty) return corners;

  double evalShift(double dx, double dy) {
    final c = [
      corners[0] + Point2D(dx, dy),
      corners[1] + Point2D(dx, dy),
      corners[2] + Point2D(dx, dy),
      corners[3] + Point2D(dx, dy),
    ];

    double gSum = 0;
    int gCnt = 0;
    for (final g in features.gapPts) {
      final topX = c[0].x + (c[1].x - c[0].x) * g.x;
      final topY = c[0].y + (c[1].y - c[0].y) * g.x;
      final botX = c[3].x + (c[2].x - c[3].x) * g.x;
      final botY = c[3].y + (c[2].y - c[3].y) * g.x;
      final ix = (topX + (botX - topX) * g.y).round();
      final iy = (topY + (botY - topY) * g.y).round();
      if (ix >= 0 && ix < w && iy >= 0 && iy < h) {
        gSum += gray[iy * w + ix];
        gCnt++;
      }
    }
    if (gCnt == 0) return -1e9;
    final bg = gSum / gCnt;

    double sc = 0;
    for (final row in features.questionRows) {
      for (final p in row) {
        final topX = c[0].x + (c[1].x - c[0].x) * p.x;
        final topY = c[0].y + (c[1].y - c[0].y) * p.x;
        final botX = c[3].x + (c[2].x - c[3].x) * p.x;
        final botY = c[3].y + (c[2].y - c[3].y) * p.x;
        final ix = (topX + (botX - topX) * p.y).round();
        final iy = (topY + (botY - topY) * p.y).round();
        if (ix >= 0 && ix < w && iy >= 0 && iy < h) {
          final diff = bg - gray[iy * w + ix];
          if (diff > 0) sc += diff < 30.0 ? diff : 30.0;
        }
      }
    }
    return sc;
  }

  double bestDx = 0.0;
  double bestDy = 0.0;
  double bestScore = evalShift(0.0, 0.0);

  for (double dy = -maxNudgePx; dy <= maxNudgePx + 0.01; dy += 0.75) {
    for (double dx = -maxNudgePx; dx <= maxNudgePx + 0.01; dx += 0.75) {
      if (dx == 0.0 && dy == 0.0) continue;
      final sc = evalShift(dx, dy);
      if (sc > bestScore + 15.0) {
        bestScore = sc;
        bestDx = dx;
        bestDy = dy;
      }
    }
  }

  return [
    corners[0] + Point2D(bestDx, bestDy),
    corners[1] + Point2D(bestDx, bestDy),
    corners[2] + Point2D(bestDx, bestDy),
    corners[3] + Point2D(bestDx, bestDy),
  ];
}

// ============================================================================
// GRADING, PROJECTION TO SOURCE AR, & ANNOTATED PREVIEW GENERATION
// ============================================================================

OmrScanResult _evaluateAndGrade({
  required img.Image workImg,
  required Uint8List gray,
  required int workW,
  required int workH,
  required double invScale,
  required Size origSize,
  required List<Point2D> workCorners,
  required List<double> hDstToWork,
  required OmrLayoutModel omrLayout,
  required List<AnswerKeyModel> answerKeys,
  required double paperBrightness,
  required bool annotateImage,
}) {
  final boxW =
      (workCorners[0].distanceTo(workCorners[1]) +
          workCorners[3].distanceTo(workCorners[2])) *
      0.5;

  // Core radius sampling (65% dari radius geometri dengan sub-pixel float sampling)
  final rFloat = (omrLayout.bubbleRadiusX * boxW * 0.65).clamp(2.2, 14.0);
  final rWork = rFloat.ceil();
  final r2Float = rFloat * rFloat;
  final keyMap = {
    for (final k in answerKeys) k.questionNumber: k.correctOption,
  };

  Point2D mapDstToWork(double dstX, double dstY) {
    final denom = hDstToWork[6] * dstX + hDstToWork[7] * dstY + hDstToWork[8];
    if (denom.abs() < 1e-7) return Point2D(dstX, dstY);
    final sx =
        (hDstToWork[0] * dstX + hDstToWork[1] * dstY + hDstToWork[2]) / denom;
    final sy =
        (hDstToWork[3] * dstX + hDstToWork[4] * dstY + hDstToWork[5]) / denom;
    return Point2D(sx, sy);
  }

  double sampleCoreMeanLum(double fx, double fy) {
    int total = 0;
    double sum = 0;
    final minX = (fx - rWork).floor();
    final maxX = (fx + rWork).ceil();
    final minY = (fy - rWork).floor();
    final maxY = (fy + rWork).ceil();
    for (int y = minY; y <= maxY; y++) {
      if (y < 0 || y >= workH) continue;
      final dy = y - fy;
      final dy2 = dy * dy;
      final rowOff = y * workW;
      for (int x = minX; x <= maxX; x++) {
        if (x < 0 || x >= workW) continue;
        final dx = x - fx;
        if (dx * dx + dy2 <= r2Float) {
          sum += gray[rowOff + x];
          total++;
        }
      }
    }
    return total > 0 ? (sum / total) : paperBrightness;
  }

  // Hitung jumlah baris yang benar-benar mengandung lingkaran cetak (Grid Validation)
  int validDetectedRows = 0;
  final answers = <ExamAnswerItem>[];
  final arBubbles = <OmrOverlayBubble>[];

  int correctCount = 0;
  int wrongCount = 0;
  int blankCount = 0;
  int doubleCount = 0;

  for (final q in omrLayout.questions) {
    final qNum = q.questionNumber;
    final correctKey = keyMap[qNum];

    final optMeanLums = <String, double>{};
    final optWorkCenters = <String, Point2D>{};

    for (final entry in q.options.entries) {
      final label = entry.key;
      final c = entry.value;
      final dstX = c.x * OmrScannerService.targetW;
      final dstY = c.y * OmrScannerService.targetH;
      final wp = mapDstToWork(dstX, dstY);
      optWorkCenters[label] = wp;
      optMeanLums[label] = sampleCoreMeanLum(wp.x, wp.y);
    }

    if (optMeanLums.isEmpty) continue;

    // Cek validitas baris: apakah setidaknya ada 1 bulatan lebih gelap dari kertas putih
    final minRowLum = optMeanLums.values.reduce(math.min);
    if (paperBrightness - minRowLum > 12.0) {
      validDetectedRows++;
    }

    // Row-adaptive unshaded baseline (maksimum kecerahan di antara opsi baris tersebut)
    final rowBrightBaseline = optMeanLums.values.reduce(math.max);

    // Hitung fill ratio (0.0 .. 1.0) berbasis penurunan intensitas terhadap baseline baris
    final scaleSpan = math.max(55.0, paperBrightness * 0.34);
    final ratios = <String, double>{};
    final drops = <String, double>{};

    for (final entry in optMeanLums.entries) {
      final drop = (rowBrightBaseline - entry.value).clamp(0.0, 255.0);
      drops[entry.key] = drop;
      ratios[entry.key] = (drop / scaleSpan).clamp(0.0, 1.0);
    }

    // Klasifikasi jawaban dengan ambang drop adaptif terhadap kertas
    // Unshaded ~ 0..16, Pensil tipis ~ 28+, Pensil 2B / Pulpen ~ 50..120
    final minDropFilled = math.max(25.0, paperBrightness * 0.125);
    final absCapLum = paperBrightness * 0.81;

    final sortedDrops =
        drops.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxEntry = sortedDrops.first;
    final secondDrop = sortedDrops.length > 1 ? sortedDrops[1].value : 0.0;

    final markedOptions =
        drops.entries
            .where(
              (e) =>
                  e.value >= minDropFilled &&
                  (optMeanLums[e.key] ?? 255.0) <= absCapLum,
            )
            .toList();

    String selectedOption = 'BLANK';
    if (markedOptions.isEmpty) {
      selectedOption = 'BLANK';
    } else if (markedOptions.length == 1) {
      selectedOption = markedOptions.first.key;
    } else {
      // Toleransi bekas hapusan sangat tipis: jika tergelap jauh melampaui ke-2
      if (maxEntry.value >= secondDrop * 2.1 &&
          secondDrop < minDropFilled * 1.4) {
        selectedOption = maxEntry.key;
      } else {
        selectedOption = 'DOUBLE';
      }
    }

    bool isCorrect = false;
    if (correctKey != null &&
        selectedOption != 'BLANK' &&
        selectedOption != 'DOUBLE') {
      isCorrect = (selectedOption == correctKey);
    }

    if (selectedOption == 'BLANK') {
      blankCount++;
    } else if (selectedOption == 'DOUBLE') {
      doubleCount++;
    } else if (isCorrect) {
      correctCount++;
    } else {
      wrongCount++;
    }

    answers.add(
      ExamAnswerItem(
        questionNumber: qNum,
        selectedOption: selectedOption,
        correctOption: correctKey,
        isCorrect: isCorrect,
        fillRatios: ratios,
      ),
    );

    // Kumpulkan lingkaran AR dalam koordinat sourceImage asli
    final arRadius = (omrLayout.bubbleRadiusX * boxW * invScale) * 1.05;
    for (final entry in optWorkCenters.entries) {
      final opt = entry.key;
      final wp = entry.value;
      String? status;
      if (selectedOption == 'DOUBLE' && drops[opt]! >= minDropFilled) {
        status = 'double';
      } else if (opt == selectedOption) {
        status = isCorrect ? 'correct' : 'wrong';
      } else if (!isCorrect && opt == correctKey) {
        status = 'key_hint';
      }

      if (status != null) {
        arBubbles.add(
          OmrOverlayBubble(
            questionNumber: qNum,
            optionLabel: opt,
            srcX: wp.x * invScale,
            srcY: wp.y * invScale,
            radiusPx: arRadius,
            status: status,
          ),
        );
      }
    }
  }

  final totalQ =
      omrLayout.totalQuestions > 0 ? omrLayout.totalQuestions : answers.length;
  final gridConf = totalQ > 0 ? (validDetectedRows / totalQ) : 0.0;
  final isValidGrid = gridConf >= 0.60;

  final score = totalQ > 0 ? ((correctCount / totalQ) * 100.0) : 0.0;
  final roundedScore = (score * 10).round() / 10.0;

  final sourceCorners =
      workCorners.map((p) => Point2D(p.x * invScale, p.y * invScale)).toList();

  // Mode Realtime AR: langsung kembalikan tanpa biaya warp penuh / JPEG encode!
  if (!annotateImage) {
    return OmrScanResult(
      answers: answers,
      correctCount: correctCount,
      wrongCount: wrongCount,
      blankCount: blankCount,
      doubleCount: doubleCount,
      score: roundedScore,
      isValidGrid: isValidGrid,
      gridConfidence: gridConf,
      sourceImageSize: origSize,
      detectedCorners: sourceCorners,
      arBubbles: arBubbles,
      annotatedImageBytes: Uint8List(0),
      annotatedImagePath: '',
    );
  }

  // Mode Capture Penuh: Lakukan perspective warp ke 1000x1076 & gambar visual feedback
  final warped = _warpPerspectiveFast(
    src: workImg,
    hDstToSrc: hDstToWork,
    outW: OmrScannerService.targetW,
    outH: OmrScannerService.targetH,
  );

  final ringR = ((omrLayout.bubbleRadiusX * OmrScannerService.targetW) * 0.92)
      .round()
      .clamp(5, 24);
  final greenColor = img.ColorRgba8(16, 185, 129, 220);
  final redColor = img.ColorRgba8(239, 68, 68, 225);
  final yellowColor = img.ColorRgba8(245, 158, 11, 235);

  for (int i = 0; i < omrLayout.questions.length; i++) {
    final q = omrLayout.questions[i];
    final ans = answers.firstWhere(
      (a) => a.questionNumber == q.questionNumber,
      orElse:
          () => ExamAnswerItem(
            questionNumber: q.questionNumber,
            selectedOption: 'BLANK',
            isCorrect: false,
          ),
    );
    final correctKey = keyMap[q.questionNumber];
    final bool isAnsCorrect = ans.isCorrect == true;

    for (final entry in q.options.entries) {
      final opt = entry.key;
      final coords = entry.value;
      final cx = (coords.x * OmrScannerService.targetW).round();
      final cy = (coords.y * OmrScannerService.targetH).round();

      if (opt == ans.selectedOption) {
        final clr = isAnsCorrect ? greenColor : redColor;
        img.drawCircle(warped, x: cx, y: cy, radius: ringR, color: clr);
        img.drawCircle(warped, x: cx, y: cy, radius: ringR + 1, color: clr);
        img.drawCircle(warped, x: cx, y: cy, radius: ringR + 2, color: clr);
      } else if (ans.selectedOption == 'DOUBLE' &&
          (ans.fillRatios?[opt] ?? 0.0) >= 0.45) {
        img.drawCircle(
          warped,
          x: cx,
          y: cy,
          radius: ringR + 1,
          color: redColor,
        );
        img.drawCircle(
          warped,
          x: cx,
          y: cy,
          radius: ringR + 2,
          color: redColor,
        );
      }

      if (!isAnsCorrect && opt == correctKey) {
        img.drawCircle(
          warped,
          x: cx,
          y: cy,
          radius: ringR + 2,
          color: yellowColor,
        );
        img.drawCircle(
          warped,
          x: cx,
          y: cy,
          radius: ringR + 3,
          color: yellowColor,
        );
        img.drawCircle(
          warped,
          x: cx,
          y: cy,
          radius: ringR + 4,
          color: yellowColor,
        );
      }
    }
  }

  final encodedJpg = Uint8List.fromList(img.encodeJpg(warped, quality: 85));

  return OmrScanResult(
    answers: answers,
    correctCount: correctCount,
    wrongCount: wrongCount,
    blankCount: blankCount,
    doubleCount: doubleCount,
    score: roundedScore,
    isValidGrid: isValidGrid,
    gridConfidence: gridConf,
    sourceImageSize: origSize,
    detectedCorners: sourceCorners,
    arBubbles: arBubbles,
    annotatedImageBytes: encodedJpg,
    annotatedImagePath: '',
  );
}

// ============================================================================
// HOMOGRAPHY MATH & FAST BILINEAR WARP
// ============================================================================

List<double> _getPerspectiveMatrix(List<Point2D> src, List<Point2D> dst) {
  final a = List.generate(8, (_) => List.filled(8, 0.0));
  final b = List.filled(8, 0.0);

  for (int i = 0; i < 4; i++) {
    final sx = src[i].x;
    final sy = src[i].y;
    final dx = dst[i].x;
    final dy = dst[i].y;

    a[2 * i][0] = sx;
    a[2 * i][1] = sy;
    a[2 * i][2] = 1;
    a[2 * i][6] = -sx * dx;
    a[2 * i][7] = -sy * dx;
    b[2 * i] = dx;

    a[2 * i + 1][3] = sx;
    a[2 * i + 1][4] = sy;
    a[2 * i + 1][5] = 1;
    a[2 * i + 1][6] = -sx * dy;
    a[2 * i + 1][7] = -sy * dy;
    b[2 * i + 1] = dy;
  }

  final h8 = _solveLinearSystem(a, b);
  return [h8[0], h8[1], h8[2], h8[3], h8[4], h8[5], h8[6], h8[7], 1.0];
}

List<double> _solveLinearSystem(List<List<double>> a, List<double> b) {
  const n = 8;
  for (int i = 0; i < n; i++) {
    int maxRow = i;
    for (int k = i + 1; k < n; k++) {
      if (a[k][i].abs() > a[maxRow][i].abs()) maxRow = k;
    }

    final tempA = a[i];
    a[i] = a[maxRow];
    a[maxRow] = tempA;

    final tempB = b[i];
    b[i] = b[maxRow];
    b[maxRow] = tempB;

    final pivot = a[i][i];
    if (pivot.abs() < 1e-12) continue;

    for (int j = i; j < n; j++) {
      a[i][j] /= pivot;
    }
    b[i] /= pivot;

    for (int k = 0; k < n; k++) {
      if (k != i) {
        final factor = a[k][i];
        for (int j = i; j < n; j++) {
          a[k][j] -= factor * a[i][j];
        }
        b[k] -= factor * b[i];
      }
    }
  }
  return b;
}

img.Image _warpPerspectiveFast({
  required img.Image src,
  required List<double> hDstToSrc,
  required int outW,
  required int outH,
}) {
  final sw = src.width;
  final sh = src.height;
  // Ekstrak RGB flat sekali agar warp zero-allocation (~10x lebih cepat)
  final srcRgb = Uint8List(sw * sh * 3);
  int si = 0;
  for (final p in src) {
    srcRgb[si++] = p.r.toInt();
    srcRgb[si++] = p.g.toInt();
    srcRgb[si++] = p.b.toInt();
  }

  final outRgb = Uint8List(outW * outH * 3);
  final h0 = hDstToSrc[0], h1 = hDstToSrc[1], h2 = hDstToSrc[2];
  final h3 = hDstToSrc[3], h4 = hDstToSrc[4], h5 = hDstToSrc[5];
  final h6 = hDstToSrc[6], h7 = hDstToSrc[7], h8 = hDstToSrc[8];

  int outIdx = 0;
  for (int dy = 0; dy < outH; dy++) {
    final py = dy.toDouble();
    final rowBaseNumX = h1 * py + h2;
    final rowBaseNumY = h4 * py + h5;
    final rowBaseDen = h7 * py + h8;

    for (int dx = 0; dx < outW; dx++) {
      final px = dx.toDouble();
      final denom = h6 * px + rowBaseDen;
      if (denom.abs() < 1e-7) {
        outRgb[outIdx++] = 255;
        outRgb[outIdx++] = 255;
        outRgb[outIdx++] = 255;
        continue;
      }

      final sx = (h0 * px + rowBaseNumX) / denom;
      final sy = (h3 * px + rowBaseNumY) / denom;

      if (sx >= 0 && sx < sw - 1 && sy >= 0 && sy < sh - 1) {
        final x0 = sx.floor();
        final y0 = sy.floor();
        final fx = sx - x0;
        final fy = sy - y0;
        final invFx = 1.0 - fx;
        final invFy = 1.0 - fy;

        final w00 = invFx * invFy;
        final w10 = fx * invFy;
        final w01 = invFx * fy;
        final w11 = fx * fy;

        final i00 = (y0 * sw + x0) * 3;
        final i10 = i00 + 3;
        final i01 = i00 + sw * 3;
        final i11 = i01 + 3;

        outRgb[outIdx++] = (w00 * srcRgb[i00] +
                w10 * srcRgb[i10] +
                w01 * srcRgb[i01] +
                w11 * srcRgb[i11])
            .round()
            .clamp(0, 255);
        outRgb[outIdx++] = (w00 * srcRgb[i00 + 1] +
                w10 * srcRgb[i10 + 1] +
                w01 * srcRgb[i01 + 1] +
                w11 * srcRgb[i11 + 1])
            .round()
            .clamp(0, 255);
        outRgb[outIdx++] = (w00 * srcRgb[i00 + 2] +
                w10 * srcRgb[i10 + 2] +
                w01 * srcRgb[i01 + 2] +
                w11 * srcRgb[i11 + 2])
            .round()
            .clamp(0, 255);
      } else {
        outRgb[outIdx++] = 255;
        outRgb[outIdx++] = 255;
        outRgb[outIdx++] = 255;
      }
    }
  }

  return img.Image.fromBytes(
    width: outW,
    height: outH,
    bytes: outRgb.buffer,
    numChannels: 3,
    order: img.ChannelOrder.rgb,
  );
}
