import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _hasPermissions = false;
  String _distanceDisplay = "Menghitung...";

  // Mecca Coordinates
  final double _meccaLat = 21.422487;
  final double _meccaLong = 39.826206;

  double? _qiblaDirection; // Angle from North to Mecca

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        _hasPermissions = true;
      });
      _calculateQiblaData();
    }
  }

  Future<void> _calculateQiblaData() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // 1. Calculate Distance
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _meccaLat,
        _meccaLong,
      );

      // 2. Calculate Qibla Direction (Bearing)
      double lat1 = position.latitude * (math.pi / 180.0);
      double lon1 = position.longitude * (math.pi / 180.0);
      double lat2 = _meccaLat * (math.pi / 180.0);
      double lon2 = _meccaLong * (math.pi / 180.0);

      double dLon = lon2 - lon1;

      double y = math.sin(dLon) * math.cos(lat2);
      double x =
          math.cos(lat1) * math.sin(lat2) -
          math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

      double brng = math.atan2(y, x);
      // convert to degrees
      double brngDegrees = (brng * 180.0 / math.pi);
      // normalize to 0-360
      double qibla = (brngDegrees + 360) % 360;

      setState(() {
        _distanceDisplay = "${(distanceInMeters / 1000).toStringAsFixed(0)} km";
        _qiblaDirection = qibla;
      });
    } catch (e) {
      setState(() {
        _distanceDisplay = "- km";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          "Arah Kiblat",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _hasPermissions
              ? StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error reading compass: ${snapshot.error}"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data?.heading == null) {
                    // Some emulators don't have compass sensors
                    return const Center(
                      child: Text(
                        "Sensor Kompas tidak ditemukan pada perangkat ini.",
                      ),
                    );
                  }

                  // Device heading (0 = North, 90 = East)
                  double? heading = snapshot.data!.heading;

                  // If heading is null (shouldn't be handled above) use 0
                  double direction = heading ?? 0;

                  // If we haven't calculated qibla yet, wait or default to something (maybe 0 but visual will be wrong)
                  // We'll just assume north if qibla not ready, but usually calculation is fast.
                  double qiblaAngle = _qiblaDirection ?? 0;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Main Compass Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 300,
                                width: 300,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 1. The Dial: Rotates opposite to heading so North stays North visually relative to screen
                                    Transform.rotate(
                                      angle: (direction * (math.pi / 180) * -1),
                                      child: CustomPaint(
                                        size: const Size(280, 280),
                                        painter: CompassDialPainter(),
                                      ),
                                    ),

                                    // 2. The Qibla Needle:
                                    if (_qiblaDirection != null)
                                      Transform.rotate(
                                        angle:
                                            ((direction * -1) + qiblaAngle) *
                                            (math.pi / 180),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.mosque,
                                                size: 24,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                            Container(
                                              width: 4,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.blueAccent,
                                                  width: 2,
                                                ),
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 110),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),
                              Text(
                                "${qiblaAngle.toStringAsFixed(0)}°",
                                style: GoogleFonts.poppins(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2FA2B1),
                                ),
                              ),
                              Text(
                                "MEKKAH",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                        Text(
                          "$_distanceDisplay ke Mekkah",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Location Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.blueAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Lokasi Anda",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _checkPermissions();
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Recalibrate",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CA1F8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "Posisikan ponsel anda sejajar dengan lantai untuk akurasi terbaik",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Mohon izinkan akses lokasi."),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _checkPermissions,
                      child: const Text("Berikan Izin"),
                    ),
                  ],
                ),
              ),
    );
  }
}

class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dashPaint =
        Paint()
          ..color = Colors.grey[300]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    _drawDashedCircle(canvas, center, radius * 0.9, dashPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final divisions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < 4; i++) {
      final angleRad = (angles[i] - 90) * (math.pi / 180);
      final tx = center.dx + (radius * 0.75) * math.cos(angleRad);
      final ty = center.dy + (radius * 0.75) * math.sin(angleRad);

      textPainter.text = TextSpan(
        text: divisions[i],
        style: GoogleFonts.poppins(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(tx - textPainter.width / 2, ty - textPainter.height / 2),
      );
    }

    for (int i = 0; i < 360; i += 30) {
      if (i % 90 == 0) continue;
      final angleRad = (i - 90) * (math.pi / 180);
      final start = Offset(
        center.dx + (radius * 0.85) * math.cos(angleRad),
        center.dy + (radius * 0.85) * math.sin(angleRad),
      );
      final end = Offset(
        center.dx + (radius * 0.9) * math.cos(angleRad),
        center.dy + (radius * 0.9) * math.sin(angleRad),
      );
      canvas.drawLine(start, end, dashPaint..color = Colors.grey[300]!);
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashWidth = 5;
    const dashSpace = 5;
    double currentAngle = 0;
    while (currentAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashWidth / radius,
        false,
        paint,
      );
      currentAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
