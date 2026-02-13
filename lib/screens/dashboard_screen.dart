import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'profile_screen.dart'; // import profile
import 'main_permit_screen.dart';
import 'qibla_screen.dart';
import 'quran_list_screen.dart';
import 'dzikir_doa_screen.dart';
import 'assunnah_tv_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'meeting_list_screen.dart'; // import meeting list screen

import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../config/api_config.dart';
import 'inventory_category_screen.dart'; // Import Inventory Screen
import 'payroll_history_screen.dart'; // Import Payroll Screen
import 'tahfidz/absensi_tahfidz_screen.dart';
import 'tahfidz/absensi_pengampu_screen.dart';
import 'tahfidz/setoran_tahfidz_screen.dart';
import 'tahfidz/penilaian_tahfidz_screen.dart';
import '../utils/access_control.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Fungsi untuk ambil token & kirim ke PHP
  Future<void> _updateMyToken() async {
    try {
      // 1. Minta Izin Notifikasi (Wajib untuk Android 13+)
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. Ambil Token Unik HP ini
      String? token = await messaging.getToken();

      if (token == null) {
        debugPrint("Gagal mengambil FCM Token");
        return;
      }

      debugPrint("FCM Token Saya: $token"); // Debug: Lihat di console

      // 3. Ambil User ID dari SharedPrefs
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');

      if (userId != null) {
        // 4. Kirim ke API PHP
        var url = Uri.parse("$baseUrl/update_fcm_token.php");
        // Ganti 10.0.2.2 dengan IP Laptop jika pakai HP Asli (misal: 192.168.1.XX)

        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
          body: jsonEncode({"user_id": userId.toString(), "fcm_token": token}),
        );

        debugPrint("Update Token Status: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error update token: $e");
    }
  }

  int _currentIndex = 0;

  // --- VARIABLES STATE ---
  String _fullName = 'Loading...';
  String _unitName = '';
  String _divisionName = '';
  String _positionName = '';
  String _userId = "";

  // Data Dashboard
  String _attendanceStatus = "BELUM_ABSEN";
  String _timeIn = "-";
  String _timeOut = "-";
  String _todaySchedule = "Loading...";
  List<dynamic> _recentActivities = [];
  bool _isKoordinator = false;
  bool _isLoadingActivity = false;

  // --- KONFIGURASI API ---
  // Sesuaikan IP ini. Jika di Emulator Android pakai 10.0.2.2.
  // Jika di HP Asli pakai IP Laptop (misal: 192.168.1.X)
  final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateMyToken();

    // 1. Setup Interacted Message (Click handler)
    setupInteractedMessage();

    // 2. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔥 FOREGROUND NOTIF RECEIVED!");
      debugPrint("Title: ${message.notification?.title}");
      debugPrint("Body: ${message.notification?.body}");
      debugPrint("Data: ${message.data}");

      // Prepare payload with title/body included if they exist in notification
      Map<String, dynamic> payloadData = Map.from(message.data);
      if (message.notification != null) {
        payloadData['title'] = message.notification!.title;
        payloadData['body'] = message.notification!.body;
      }

      if (message.notification != null) {
        if (!mounted) return;

        // Tampilkan Notifikasi Sistem (Floating / Heads Up)
        NotificationService().showLocalNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Notifikasi Baru',
          body: message.notification!.body ?? '',
          payload: jsonEncode(payloadData),
        );
      } else {
        // Fallback jika notifikasi null tapi ada data (kadang terjadi)
        NotificationService().showLocalNotification(
          id: message.hashCode,
          title: message.data['title'] ?? 'Notifikasi Baru',
          body: message.data['body'] ?? 'Anda memiliki notifikasi baru',
          payload: jsonEncode(payloadData), // Use the same prepared payload
        );
      }
    });

    // 3. Listen to Local Notification Taps
    NotificationService().selectNotificationStream.listen((String? payload) {
      if (payload != null) {
        debugPrint("🔔 Local Notification Tapped! Payload: $payload");
        try {
          final Map<String, dynamic> data = jsonDecode(payload);
          _handleNavigationData(data);
        } catch (e) {
          debugPrint("Error parsing payload: $e");
        }
      }
    });

    // Init Notification Service (Fire and forget)
    NotificationService().init();
  }

  // --- LOGIC: HANDLE NOTIFICATION CLICK ---
  Future<void> setupInteractedMessage() async {
    // 1. App from Terminated State
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleNavigationData(initialMessage.data);
    }

    // 2. App from Background State
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigationData(message.data);
    });
  }

  void _handleNavigationData(Map<String, dynamic> data) {
    debugPrint("🚀 Handling Navigation Data: $data");

    // Check screen type
    String? screen = data['screen'];
    String? title = data['title'] ?? '';
    String? body = data['body'] ?? '';

    if (!mounted) return;

    // Case 1: Approval (Manager)
    if (screen == 'approval') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPermitScreen()),
      );
    }
    // Case 2: Permit Status Update (Staff) - "halaman perizinan"
    // Also check for "Status anda diperbarui" in title/body as fallback
    else if (screen == 'permit' ||
        (title != null && title.toLowerCase().contains('status')) ||
        (body != null && body.toLowerCase().contains('status'))) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPermitScreen()),
      );
    }
  }

  // --- LOGIC 1: LOAD USER DATA ---
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _fullName = prefs.getString('fullName') ?? 'User';
      _unitName = prefs.getString('unitName') ?? '';
      _divisionName = prefs.getString('divisionName') ?? '';
      _positionName = prefs.getString('positionName') ?? '';
      int id = prefs.getInt('userId') ?? 0; // Default 0 jika tidak ada
      _userId = id.toString();
    });

    if (_userId != "0") {
      // 1. Refresh Permissions agar menu sesuai hak akses terbaru
      await PermissionService().fetchPermissions(int.parse(_userId));
      if (mounted) setState(() {});

      // 2. Fetch Data Dashboard
      _fetchDashboardData();
    }
  }

  // --- LOGIC 2: FETCH ALL DATA ---
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoadingActivity = true);

    // Pastikan nama file PHP sesuai dengan yang kita buat: get_dashboard.php
    final url = "$baseUrl/get_dashboard_data.php?user_id=$_userId";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && mounted) {
          setState(() {
            // 1. Status
            _attendanceStatus = data['status_absensi'] ?? "BELUM_ABSEN";

            // 2. Jadwal
            _todaySchedule = data['today_schedule'] ?? "Tidak Ada Jadwal";

            // 3. Data Jam Absen Hari Ini (Safety Check)
            if (data['data_hari_ini'] != null && data['data_hari_ini'] is Map) {
              _timeIn = data['data_hari_ini']['time_in'] ?? "-";
              _timeOut = data['data_hari_ini']['time_out'] ?? "-";
            } else {
              _timeIn = "-";
              _timeOut = "-";
            }

            // 4. History
            _recentActivities = data['history'] ?? [];

            // 5. Check Koordinator
            _isKoordinator =
                data['user_profile']?['is_koordinator'] == 1 ||
                data['user_profile']?['is_koordinator'] == true ||
                data['user_profile']?['is_koordinator'] == "1" ||
                _positionName.toLowerCase().contains('koordinator');
          });
        }
      } else {
        debugPrint("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error Fetch Dashboard: $e");
    } finally {
      if (mounted) setState(() => _isLoadingActivity = false);
    }
  }

  // --- LOGIC 3: EKSEKUSI ABSEN ---
  Future<void> _handleAttendance() async {
    if (_attendanceStatus == "SELESAI") return;

    // 1. Ambil Lokasi
    Position? position;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sedang mengambil lokasi...")),
      );
      position = await _determinePosition();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar(message: "Gagal ambil lokasi: $e", isError: true);
      return;
    }

    // 2. Kirim ke API
    String type = (_attendanceStatus == "BELUM_ABSEN") ? "IN" : "OUT";
    final url = "$baseUrl/attendance.php";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "user_id": _userId,
          "type": type,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
        }),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final data = jsonDecode(response.body);

      _showSnackBar(
        message: data['message'] ?? "Terjadi kesalahan",
        isError: !(data['success'] == true),
      );

      if (data['success'] == true) {
        _fetchDashboardData(); // Refresh data dashboard
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar(message: "Gagal terhubung ke server", isError: true);
    }
  }

  void _showSnackBar({required String message, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- GPS HELPER ---
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS mati. Mohon nyalakan GPS.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    // List Halaman untuk Bottom Navigation
    final List<Widget> pages = [
      HomeTab(
        fullName: _fullName,
        unitName: _unitName,
        deptName: _divisionName,
        positionName: _positionName,
        recentActivities: _recentActivities,
        isLoading: _isLoadingActivity,
        onAttendanceTap: _handleAttendance,
        attendanceStatus: _attendanceStatus,
        timeIn: _timeIn,
        timeOut: _timeOut,
        todaySchedule: _todaySchedule,
        isKoordinator: _isKoordinator,
      ),
      const Center(child: Text("Halaman Berita")),
      const Center(child: Text("Halaman Kinerja")),
      const ProfileScreen(), // Pastikan import sudah benar
    ];

    // menu bottom bar
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      extendBody: true, // Allow body to go behind bottom bar
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.fastOutSlowIn,
        switchOutCurve: Curves.fastOutSlowIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Modern Scale + Fade Transition
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
              ),
              child: child,
            ),
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          // Ensures correct stacking order during transition
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, "Beranda", 0),
            _buildNavItem(Icons.menu_book_rounded, "Berita", 1),
            _buildNavItem(Icons.access_time_filled_rounded, "Kinerja", 2),
            _buildNavItem(Icons.person_rounded, "Profil", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          // Changed to Column for text below icon
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2B83F6) : Colors.grey[400],
              size: 24, // Slightly smaller to fit text
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10, // Small text
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF2B83F6) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// WIDGET UI: HOME TAB
// ==========================================================

class HomeTab extends StatelessWidget {
  final String fullName;
  final String unitName;
  final String deptName;
  final String positionName;
  final List<dynamic> recentActivities;
  final bool isLoading;
  final VoidCallback onAttendanceTap;
  final String attendanceStatus;
  final String timeIn;
  final String timeOut;

  final String todaySchedule;
  final bool isKoordinator;

  const HomeTab({
    super.key,
    required this.fullName,
    required this.unitName,
    required this.deptName,
    required this.positionName,
    required this.recentActivities,
    required this.isLoading,
    required this.onAttendanceTap,
    required this.attendanceStatus,
    required this.timeIn,
    required this.timeOut,
    required this.todaySchedule,
    required this.isKoordinator,
  });
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Aktivitas Terbaru', action: 'View All'),
            const SizedBox(height: 10),
            _buildRecentActivityList(),
            const SizedBox(height: 27),
            _buildSectionTitle('Menu Islami'),
            const SizedBox(height: 12),
            _buildServicesGrid(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Menu Umum'),
            const SizedBox(height: 12),
            _buildGeneralMenuGrid(context),
            const SizedBox(height: 24),
            // Show Tahfidz Menu Only If User Has Permission
            if (AccessControl.can('can_access_tahfidz')) ...[
              _buildSectionTitle('Menu Tahfidz'),
              const SizedBox(height: 12),
              _buildTahfidzMenuGrid(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ahlan,',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                fullName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              // Show subtitle: unitName for staff, positionName for managers
              if (unitName.isNotEmpty || positionName.isNotEmpty)
                Text(
                  unitName.isNotEmpty
                      ? "$unitName - $deptName"
                      : "$positionName - $deptName",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        StreamBuilder<int>(
          stream: NotificationService().unreadCountStream,
          initialData: 0,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              debugPrint('Dashboard: Badge Stream received: ${snapshot.data}');
            }
            final count = snapshot.data ?? 0;
            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  onPressed: () => _showNotificationSheet(context),
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black87,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Notifications",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "CLEAR ALL",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: FutureBuilder<List<dynamic>>(
                  future: NotificationService().getNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            "No notifications",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    final notifs = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: notifs.length,
                      itemBuilder: (context, index) {
                        final n = notifs[index];
                        final String title = n['title'] ?? 'Title';
                        final String body = n['body'] ?? 'Body';
                        final String date = n['created_at'] ?? '';
                        final String status = n['status'] ?? '';
                        final String type = n['type'] ?? '';

                        // Logic Icon
                        Color iconBg = Colors.grey[200]!;
                        Color iconColor = Colors.grey;
                        IconData icon = Icons.notifications;

                        if (type == 'incoming' || status == 'Pending') {
                          iconBg = const Color(0xFFFEF3C7);
                          iconColor = const Color(0xFFD97706);
                          icon = Icons.access_time_filled;
                        } else if (status == 'Approved') {
                          iconBg = const Color(0xFFDCFCE7);
                          iconColor = const Color(0xFF166534);
                          icon = Icons.check_circle;
                        } else if (status == 'Rejected') {
                          iconBg = const Color(0xFFFEE2E2);
                          iconColor = const Color(0xFFDC2626);
                          icon = Icons.cancel;
                        }

                        // Parse time if possible (simple split by space)
                        String timeStr = date;
                        if (date.contains(' ')) {
                          timeStr = date.split(' ')[1]; // Get HH:mm:ss
                          if (timeStr.length > 5) {
                            timeStr = timeStr.substring(0, 5); // HH:mm
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    final now = DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(now);

    String statusLabel = "Belum Absen";
    Color statusColor = Colors.grey;
    String displayTime = "--:--";
    String btnText = "Absen Masuk";
    Color btnColor = Colors.blueAccent;
    IconData btnIcon = Icons.login;

    if (attendanceStatus == "SUDAH_MASUK") {
      statusLabel = "Sudah Masuk";
      statusColor = Colors.green;
      displayTime = timeIn;
      btnText = "Absen Pulang";
      btnColor = Colors.orange;
      btnIcon = Icons.logout;
    } else if (attendanceStatus == "SELESAI") {
      statusLabel = "Selesai";
      statusColor = Colors.blue;
      displayTime = timeOut;
      btnText = "Sampai Jumpa";
      btnColor = Colors.grey;
      btnIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ), // Perbaikan: withOpacity lebih kompatibel
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Absensi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    displayTime,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // --- SCHEDULE SECTION ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.1),
              ), // Perbaikan: withOpacity
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF546E7A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Jam Kerja Hari ini",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF90A4AE),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todaySchedule,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF263238),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: attendanceStatus == "SELESAI" ? null : onAttendanceTap,
              icon: Icon(btnIcon),
              label: Text(btnText),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (recentActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "Belum ada aktivitas",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children:
            recentActivities.map((activity) {
              String type = activity['type'] ?? "Activity";
              String time = activity['time'] ?? "-";
              String date = activity['date'] ?? "-";
              String status = activity['status'] ?? "Hadir";
              bool isMasuk = type.toLowerCase().contains("masuk");

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMasuk ? Colors.blue[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isMasuk ? Icons.login : Icons.logout,
                        color: isMasuk ? Colors.blue : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            date,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      {'title': 'Al Quran', 'icon': Icons.menu_book, 'color': Colors.orange},
      {
        'title': 'Dzikir & Do\'a',
        'icon': Icons.nights_stay,
        'color': Colors.green,
      },
      {'title': 'Arah Kiblat', 'icon': Icons.explore, 'color': Colors.red},
      {'title': 'TV Sunnah', 'icon': Icons.live_tv, 'color': Colors.purple},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          services.map((service) {
            return Expanded(
              child: Container(
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (service['title'] == 'Arah Kiblat') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QiblaScreen(),
                          ),
                        );
                      } else if (service['title'] == 'Al Quran') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuranListScreen(),
                          ),
                        );
                      } else if (service['title'] == 'Dzikir & Do\'a') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DzikirDoaScreen(),
                          ),
                        );
                      } else if (service['title'] == 'TV Sunnah') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AssunnahTvScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center vertically
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (service['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              service['icon'] as IconData,
                              color: service['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            service['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildGeneralMenuGrid(BuildContext context) {
    final menus = [
      {'title': 'Izin Kerja', 'icon': Icons.work_outline, 'color': Colors.blue},
      {'title': 'Rapat Pertemuan', 'icon': Icons.groups, 'color': Colors.amber},
      {
        'title': 'Inventaris Barang',
        'icon': Icons.inventory_2,
        'color': Colors.teal,
      },
      {'title': 'Penggajian', 'icon': Icons.payments, 'color': Colors.pink},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          menus.map((menu) {
            return Expanded(
              child: Container(
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (menu['title'] == 'Izin Kerja') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainPermitScreen(),
                          ),
                        );
                      } else if (menu['title'] == 'Rapat Pertemuan') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MeetingListScreen(),
                          ),
                        );
                      } else if (menu['title'] == 'Inventaris Barang') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const InventoryCategoryScreen(),
                          ),
                        );
                      } else if (menu['title'] == 'Penggajian') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PayrollHistoryScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (menu['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              menu['icon'] as IconData,
                              color: menu['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            menu['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, {String? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            child: Text(
              action,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTahfidzMenuGrid(BuildContext context) {
    if (isKoordinator || AccessControl.can('is_koordinator')) {
      // COORDINATOR VIEW
      // Rows: Absensi (2 cols), Penilaian (Full), Setoran (Full)
      final absensiMenus = [
        {
          'title': 'Absensi Tahfidz',
          'icon': Icons.how_to_reg,
          'color': Colors.indigo,
        },
        {
          'title': 'Absensi Pengampu',
          'icon': Icons.co_present,
          'color': Colors.deepPurple,
        },
      ];

      return Column(
        children: [
          Row(
            children:
                absensiMenus
                    .map(
                      (menu) => Expanded(child: _buildMenuCard(context, menu)),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),
          _buildFullWidthMenuCard(context, {
            'title': 'Penilaian',
            'icon': Icons.assignment_turned_in_rounded,
            'color': Colors.orangeAccent,
          }),
          const SizedBox(height: 12),
          _buildFullWidthMenuCard(context, {
            'title': 'Setoran',
            'icon': Icons.edit_note_rounded,
            'color': Colors.teal,
          }),
        ],
      );
    } else {
      // NON-COORDINATOR VIEW
      final mainMenus = [
        {
          'title': 'Absensi Tahfidz',
          'icon': Icons.how_to_reg,
          'color': Colors.indigo,
        },
        {
          'title': 'Penilaian',
          'icon': Icons.assignment_turned_in_rounded,
          'color': Colors.orangeAccent,
        },
      ];

      return Column(
        children: [
          Row(
            children:
                mainMenus
                    .map(
                      (menu) => Expanded(child: _buildMenuCard(context, menu)),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          _buildFullWidthMenuCard(context, {
            'title': 'Setoran',
            'icon': Icons.edit_note_rounded,
            'color': Colors.teal,
          }),
        ],
      );
    }
  }

  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> menu) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleMenuNavigation(context, menu['title'] as String),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (menu['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  menu['icon'] as IconData,
                  color: menu['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                menu['title'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthMenuCard(
    BuildContext context,
    Map<String, dynamic> menu,
  ) {
    return Container(
      width: double.infinity,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            (menu['color'] as Color).withValues(alpha: 0.1),
            Colors.white,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleMenuNavigation(context, menu['title'] as String),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (menu['color'] as Color).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    menu['icon'] as IconData,
                    color: menu['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu['title'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Input Hafalan Baru Santri",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: (menu['color'] as Color).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuNavigation(BuildContext context, String title) {
    if (title == 'Absensi Tahfidz') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AbsensiTahfidzScreen()),
      );
    } else if (title == 'Absensi Pengampu') {
      if (isKoordinator) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AbsensiPengampuScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Akses ditolak. Menu ini hanya untuk koordinator."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (title == 'Setoran') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SetoranTahfidzScreen()),
      );
    } else if (title == 'Penilaian') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PenilaianTahfidzScreen()),
      );
    }
  }
}
