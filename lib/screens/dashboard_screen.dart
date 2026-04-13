import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'meeting_list_screen.dart'; // import meeting list screen
import 'package:provider/provider.dart';
import '../providers/tahfidz_provider.dart';

import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../config/api_config.dart';
import '../core/api_constants.dart';
import 'inventory_category_screen.dart'; // Import Inventory Screen
import 'payroll_history_screen.dart'; // Import Payroll Screen
import 'tahfidz/absensi_tahfidz_screen.dart';
import 'tahfidz/absensi_pengampu_screen.dart';
import 'tahfidz/setoran_tahfidz_screen.dart';
import 'tahfidz/penilaian_tahfidz_screen.dart';
import 'teaching_schedule_screen.dart';
import 'rpp_screen.dart';
import 'kabid/data_presensi_screen.dart';
import 'kabid/rekap_absensi_screen.dart';
import 'kabid/absensi_manual_screen.dart';

import 'kesantrian/absensi_asrama_screen.dart';
import 'kesantrian/absensi_makan_screen.dart';
import 'kesantrian/pelanggaran_screen.dart';
import 'kesantrian/kepulangan_screen.dart';
import 'kesantrian/izin_santri_screen.dart';
import 'class_list_screen.dart';
import '../services/attendance_service.dart';
import '../models/location_model.dart';
import '../utils/access_control.dart';
import 'subject_list_screen.dart';
import 'student_data_screen.dart';
import 'academic_calendar_screen.dart';
import 'teacher_data_screen.dart';
import 'assignment_screen.dart';
import 'task_detail_screen.dart';
import 'performance_screen.dart';
import 'news_screen.dart';
import 'attendance_recap_screen.dart';
import 'shift_swap_screen.dart';
import '../services/news_service.dart';
import '../models/news_model.dart';
import 'student_grading_screen.dart';
import 'news_detail_screen.dart';

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
  String _profilePhoto = '';
  String _userId = "";

  // Data Dashboard
  String _attendanceStatus = "BELUM_ABSEN";
  String _timeIn = "-";
  String _timeOut = "-";
  String _todaySchedule = "Loading...";
  List<dynamic> _recentActivities = [];
  bool _isKoordinator = false;
  bool _isLoadingActivity = false;
  bool _isSwapped = false;
  String? _swapPartnerName;
  bool _canApprovePermits = false;

  final String baseUrl = ApiConfig.baseUrl;
  List<LocationModel> _locations = [];
  List<News> _newsList = [];
  bool _isLoadingNews = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateMyToken();

    // 1. Init Notification Service FIRST (must be before any showLocalNotification calls)
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    // Initialize local notification plugin FIRST
    await NotificationService().init();
    debugPrint("✅ NotificationService initialized");

    // 2. Setup Interacted Message (Click handler for terminated/background)
    setupInteractedMessage();

    // 3. Foreground Message Handler
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
        debugPrint("🔔 Showing local notification for FCM message...");
        FlutterLocalNotificationsPlugin().show(
          message.notification.hashCode,
          message.notification!.title ?? 'Notifikasi Baru',
          message.notification!.body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // Id unik ini harus sama antara konfigurasi dan pemanggilan
              'High Importance Notifications',
              channelDescription:
                  'Dipakai untuk notifikasi penting agar melayang/bisa bunyi.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(payloadData),
        );
      } else {
        // Fallback jika notifikasi null tapi ada data (kadang terjadi)
        debugPrint("🔔 FCM notification is null, using data fields...");
        FlutterLocalNotificationsPlugin().show(
          message.hashCode,
          message.data['title'] ?? 'Notifikasi Baru',
          message.data['body'] ?? 'Anda memiliki notifikasi baru',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'Dipakai untuk notifikasi penting agar melayang/bisa bunyi.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(payloadData),
        );
      }

      // Immediately refresh badge count so bell icon updates in real-time
      NotificationService().refreshBadge();
    });

    // 4. Listen to Local Notification Taps
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

    // 5. Start Polling (fetch from API every 30s)
    NotificationService().startPolling();

    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    _locations = await AttendanceService().getLocations();
    if (mounted) setState(() {});
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

    // Case 1: Approval Santri (Manager/Mudir)
    if (screen == 'approval' || screen == 'izin_santri') {
      final String? id = data['id']?.toString();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IzinSantriScreen(initialPermitId: id),
        ),
      );
    }
    // Case 2: Assignment - tugas baru atau update tugas
    else if (screen == 'assignment') {
      final String? taskId = data['task_id']?.toString();
      if (taskId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(taskId: int.parse(taskId)),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AssignmentScreen()),
        );
      }
    }
    // Case 3: Assignment List
    else if (screen == 'assignment_list') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AssignmentScreen()),
      );
    }
    // Case 4: Permit Status Update (Staff) - "halaman perizinan"
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
    await prefs.reload(); // Force sync with disk to get latest update
    if (!mounted) return;

    setState(() {
      _fullName = prefs.getString('fullName') ?? 'User';
      _unitName = prefs.getString('unitName') ?? '';
      _divisionName = prefs.getString('divisionName') ?? '';
      _positionName = prefs.getString('positionName') ?? '';
      _profilePhoto = prefs.getString('profilePhoto') ?? '';
      int id =
          prefs.getInt('user_id') ??
          prefs.getInt('userId') ??
          0; // Try both keys
      _userId = id.toString();
    });

    // Fetch news regardless of userId for general feed
    _fetchNewsData();

    if (_userId != "0") {
      // Parallel requests for permissions and dashboard data
      Future.wait([
        PermissionService().fetchPermissions(int.parse(_userId)).then((_) {
          if (mounted) {
            setState(() {
              _canApprovePermits = PermissionService().canApprovePermits;
            });
          }
        }),
        _fetchDashboardData(),
      ]);
    }
  }

  Future<void> _fetchNewsData() async {
    if (!mounted) return;
    setState(() => _isLoadingNews = true);
    try {
      final news = await NewsService().getNews();
      if (mounted) {
        setState(() {
          _newsList = news;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching news: $e");
      if (mounted) setState(() => _isLoadingNews = false);
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

            // 5. Swap Info
            _isSwapped = data['is_swapped'] == true;
            _swapPartnerName = data['swap_partner_name'];

            // 6. Check Koordinator
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

    // 1. Flow Berdasarkan Status
    if (_attendanceStatus == "BELUM_ABSEN" ||
        _attendanceStatus == "SUDAH_MASUK") {
      // Check-in & Check-out flow: Sekarang keduanya butuh pilih lokasi
      if (_locations.isEmpty) {
        _showLoadingSnackBar("Mengambil data lokasi...");
        await _fetchLocations();
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (_locations.isEmpty) {
        _showSnackBar(
          message: "Data lokasi kantor tidak tersedia",
          isError: true,
        );
        return;
      }

      if (_locations.length == 1) {
        _handleAttendanceWithGPS(_locations.first);
      } else {
        _showLocationPicker();
      }
    }
  }

  Future<void> _handleAttendanceWithGPS(LocationModel location) async {
    // Ambil GPS & Cek Mock
    Position? position;
    try {
      _showLoadingSnackBar("Mengambil lokasi GPS...");
      position = await _determinePosition();
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (position.isMocked) {
        _showInvalidLocationDialog();
        return;
      }

      if (_attendanceStatus == "BELUM_ABSEN") {
        await _executeCheckIn(location, position);
      } else {
        await _executeCheckOut(position);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnackBar(message: "Gagal ambil lokasi: $e", isError: true);
    }
  }

  void _showInvalidLocationDialog() {
    _showSmoothDialog(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Lokasi Tidak Valid",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Mock location (GPS Palsu) terdeteksi. Silakan matikan aplikasi Fake GPS Anda untuk melanjutkan absensi.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCheckIn(
    LocationModel location,
    Position position,
  ) async {
    try {
      _showLoadingSnackBar("Sedang mengirim absensi...");
      final result = await AttendanceService().checkIn(
        userId: int.parse(_userId),
        locationId: location.id,
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (result['success'] == true || result['status'] == true) {
        _showSnackBar(message: result['message'] ?? "Absen masuk berhasil");
        _fetchDashboardData();
      } else {
        _showErrorDialog(result['message'] ?? "Gagal melakukan absensi");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnackBar(message: "Kesalahan jaringan: $e", isError: true);
    }
  }

  Future<void> _executeCheckOut(Position position) async {
    try {
      _showLoadingSnackBar("Sedang mengirim absensi...");
      final result = await AttendanceService().checkOut(
        userId: int.parse(_userId),
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (result['success'] == true || result['status'] == true) {
        _showSnackBar(message: result['message'] ?? "Absen pulang berhasil");
        _fetchDashboardData();
      } else {
        _showErrorDialog(result['message'] ?? "Gagal melakukan absensi");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnackBar(message: "Kesalahan jaringan: $e", isError: true);
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void _showErrorDialog(String message) {
    _showSmoothDialog(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Informasi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Tutup",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSmoothDialog({required Widget child}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => child,
    );
  }

  void _showLocationPicker() {
    _showSmoothDialog(child: _buildLocationPickerContent(context));
  }

  Widget _buildLocationPickerContent(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Pilih Lokasi Kantor",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _locations.length,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _handleAttendanceWithGPS(loc);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                              color: Colors.blue.withValues(alpha: 0.02),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    size: 22,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        loc.address.isNotEmpty
                                            ? loc.address
                                            : "Ketuk untuk memilih lokasi ini",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Kembali",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar({required String message, bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
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

    try {
      // Mencoba mengambil lokasi dengan akurasi tinggi dan timeout yang lebih lama (30 detik)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
    } catch (e) {
      // Jika akurasi tinggi gagal/timeout, coba dengan akurasi medium
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy:
              LocationAccuracy.medium, // Lebih cepat mengunci lokasi
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e2) {
        // Sebagai upaya terakhir, coba ambil lokasi terakhir yang diketahui
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
        // Jika semua gagal, baru lemparkan error original
        return Future.error(
          'Gagal mendapatkan lokasi GPS. Mohon pastikan Anda berada di area terbuka dan coba lagi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // List Halaman untuk Bottom Navigation
    final List<Widget> pages = [
      HomeTab(
        key: ValueKey('home_tab_$_profilePhoto'),
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
        profilePhoto: _profilePhoto,
        newsList: _newsList,
        isLoadingNews: _isLoadingNews,
        isSwapped: _isSwapped,
        swapPartnerName: _swapPartnerName,
        canApprovePermits: _canApprovePermits,
        onRefresh: () async {
          await _fetchDashboardData();
          await _fetchNewsData();
        },
        onSeeAllNews: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const NewsScreen(),
      const PerformanceScreen(),
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
      onTap: () {
        setState(() => _currentIndex = index);
        // Refresh user data (especially profile photo) when switching tabs
        _loadUserData();
      },
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
  final String profilePhoto;
  final List<dynamic> recentActivities;
  final bool isLoading;
  final VoidCallback onAttendanceTap;
  final String attendanceStatus;
  final String timeIn;
  final String timeOut;

  final String todaySchedule;
  final bool isKoordinator;
  final bool isSwapped;
  final String? swapPartnerName;
  final bool canApprovePermits;
  final Future<void> Function() onRefresh;

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
    required this.profilePhoto,
    required this.newsList,
    required this.isLoadingNews,
    required this.isSwapped,
    this.swapPartnerName,
    required this.canApprovePermits,
    required this.onRefresh,
    required this.onSeeAllNews,
  });

  final List<News> newsList;
  final bool isLoadingNews;
  final VoidCallback onSeeAllNews;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildStatusCard(),
              const SizedBox(height: 27),
              _buildSectionTitle('Aktivitas Terbaru'),
              const SizedBox(height: 20),
              _buildRecentActivityList(),
              const SizedBox(height: 27),
              _buildSectionTitle('Menu Islami'),
              const SizedBox(height: 12),
              _buildServicesGrid(context),
              const SizedBox(height: 24),
              _buildNewsBanner(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Menu Umum'),
              const SizedBox(height: 12),
              _buildGeneralMenuGrid(context),
              // Show Education Menu Only If User Has Permission
              if (AccessControl.can('can_access_education')) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Menu Pendidikan'),
                const SizedBox(height: 12),
                _buildEducationMenuGrid(context),
              ],
              // Show Tahfidz Menu Only If User Has Permission
              if (AccessControl.can('can_access_tahfidz')) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Menu Tahfidz'),
                const SizedBox(height: 12),
                _buildTahfidzMenuGrid(context),
              ],
              // Show Kepala Bidang Menu Only If User Has Permission
              if (AccessControl.can('can_access_kabid')) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Menu Kepala Bidang'),
                const SizedBox(height: 12),
                _buildKabidMenuGrid(context),
              ],
              // Show Kesantrian Menu Only If User Has Permission
              if (AccessControl.can('can_access_kesantrian')) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Menu Kesantrian'),
                const SizedBox(height: 12),
                _buildKesantrianMenuGrid(context),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blueAccent,
          child: ClipOval(
            child: () {
              final String? photoUrl = ApiConstants.getProfilePhotoUrl(
                profilePhoto,
              );
              return (photoUrl != null && photoUrl.isNotEmpty)
                  ? CachedNetworkImage(
                    key: ValueKey(photoUrl),
                    imageUrl: photoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.person, color: Colors.white),
                  )
                  : const Icon(Icons.person, color: Colors.white);
            }(),
          ),
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
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
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
    final future = NotificationService().getNotifications();
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: future,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final notifs = snapshot.data ?? [];
            final isEmpty = !isLoading && notifs.isEmpty;

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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Notifikasi",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        if (!isLoading && notifs.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await NotificationService().clearNotifications();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              "Hapus Semua",
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
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tidak ada notifikasi",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        itemCount: notifs.length,
                        itemBuilder: (context, index) {
                          final n = notifs[index];
                          final String title = n['title'] ?? 'Title';
                          final String body = n['body'] ?? 'Body';
                          final String date = n['created_at'] ?? '';
                          final String status = n['status'] ?? '';
                          final String type = n['type'] ?? '';

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
                          } else if (type == 'assignment') {
                            iconBg = const Color(0xFFDBEAFE);
                            iconColor = const Color(0xFF2563EB);
                            icon = Icons.assignment_rounded;
                          }

                          String timeStr = date;
                          if (date.contains(' ')) {
                            timeStr = date.split(' ')[1];
                            if (timeStr.length > 5) {
                              timeStr = timeStr.substring(0, 5);
                            }
                          }

                          return GestureDetector(
                            onTap: () {
                              // Dismiss this notification from server
                              final notifKey = n['id']?.toString() ?? '';
                              if (notifKey.isNotEmpty) {
                                NotificationService().dismissNotification(
                                  notifKey,
                                );
                              }

                              Navigator.pop(context); // Close bottom sheet
                              if (type == 'assignment') {
                                final taskId =
                                    n['task_id']?.toString() ??
                                    n['reference_id']?.toString();
                                if (taskId != null) {
                                  Navigator.push(
                                    parentContext,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => TaskDetailScreen(
                                            taskId: int.parse(taskId),
                                          ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    parentContext,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const AssignmentScreen(),
                                    ),
                                  );
                                }
                              } else if (n['screen'] == 'approval') {
                                Navigator.push(
                                  parentContext,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const MainPermitScreen(
                                          initialIndex: 1,
                                        ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  parentContext,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const MainPermitScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
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
                                    child: Icon(
                                      icon,
                                      color: iconColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF1F2937,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
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
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusCard() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    String statusLabel = "Belum Absen";
    Color statusColor = Colors.grey;
    String displayTime = "--:--";
    String btnText = "Absen Masuk";
    Color btnColor = Colors.blueAccent;
    IconData btnIcon = Icons.login;

    if (attendanceStatus == "SUDAH_MASUK") {
      statusLabel = "Sudah Masuk";
      statusColor = Colors.green;
      displayTime = _formatTime(timeIn);
      btnText = "Absen Pulang";
      btnColor = Colors.orange;
      btnIcon = Icons.logout;
    } else if (attendanceStatus == "SELESAI") {
      statusLabel = "Selesai";
      statusColor = Colors.blue;
      displayTime = _formatTime(timeOut);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Jam Kerja Hari ini",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF90A4AE),
                            ),
                          ),
                          if (isSwapped) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Tukar Shift",
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ],
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
                      if (isSwapped && swapPartnerName != null)
                        Text(
                          "Partner: $swapPartnerName",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
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

  String _formatTime(String time) {
    if (time == "-" || time.isEmpty) return "--:--";
    try {
      // Handle HH:mm:ss result from DB
      final parts = time.split(':');
      if (parts.length >= 2) {
        return "${parts[0]}:${parts[1]}";
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  String _formatDateIndo(String dateStr) {
    if (dateStr == "-" || dateStr.isEmpty) return "-";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
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
              String time = _formatTime(activity['time'] ?? "-");
              String date = _formatDateIndo(activity['date'] ?? "-");
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

  Widget _buildNewsBanner(BuildContext context) {
    if (isLoadingNews) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Berita Terbaru', action: 'Lihat Semua'),
        const SizedBox(height: 12),
        if (newsList.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                "Tidak ada berita saat ini",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newsList.length,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, index) {
                final news = newsList[index];
                return _buildNewsCard(context, news);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, News news) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: CachedNetworkImageProvider(news.coverPhoto),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  news.category,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                news.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
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
    final row1 = [
      {'title': 'Izin Kerja', 'icon': Icons.work_outline, 'color': Colors.blue},
      {'title': 'Rapat Pertemuan', 'icon': Icons.groups, 'color': Colors.amber},
      {
        'title': 'Inventaris Barang',
        'icon': Icons.inventory_2,
        'color': Colors.teal,
      },
      {'title': 'Penggajian', 'icon': Icons.payments, 'color': Colors.pink},
    ];

    final row2 = [
      {
        'title': 'Tukar Shift',
        'icon': Icons.swap_horiz,
        'color': Colors.indigo,
      },
      {'title': 'Penugasan', 'icon': Icons.assignment, 'color': Colors.orange},
    ];

    return Column(
      children: [
        Row(
          children:
              row1
                  .map((menu) => Expanded(child: _buildMenuCard(context, menu)))
                  .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              row2
                  .map((menu) => Expanded(child: _buildMenuCard(context, menu)))
                  .toList(),
        ),
      ],
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
            onPressed: action == 'Lihat Semua' ? onSeeAllNews : () {},
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

  Widget _buildEducationMenuGrid(BuildContext context) {
    final row1 = [
      {
        'title': 'Data Siswa',
        'icon': Icons.people_outline,
        'color': Colors.blue,
      },
      {
        'title': 'Data Guru',
        'icon': Icons.person_outline,
        'color': Colors.green,
      },
      {
        'title': 'Data Kelas',
        'icon': Icons.meeting_room_outlined,
        'color': Colors.orange,
      },
      {
        'title': 'Mata Pelajaran',
        'icon': Icons.book_outlined,
        'color': Colors.purple,
      },
    ];
    final row2 = [
      {
        'title': 'RPP',
        'subtitle': 'Rencana Pembelajaran',
        'icon': Icons.assignment_outlined,
        'color': Colors.indigo,
        'flex': 2,
      },
      {
        'title': 'Rekap Presensi',
        'icon': Icons.assignment_ind_outlined,
        'color': Colors.redAccent,
        'flex': 1,
      },
      {
        'title': 'Kalender Akademik',
        'icon': Icons.event_note_outlined,
        'color': Colors.teal,
        'flex': 1,
      },
    ];

    return Column(
      children: [
        _buildFullWidthMenuCard(context, {
          'title': 'Jadwal Mengajar',
          'subtitle': 'Lihat jadwal hari ini',
          'icon': Icons.calendar_today_rounded,
          'color': const Color(0xFF2563EB),
          'gradientColors': [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
          'textColor': Colors.white,
          'iconColor': Colors.white,
          'iconBgColor': Colors.white.withValues(alpha: 0.2),
        }),
        const SizedBox(height: 12),
        _buildFullWidthMenuCard(context, {
          'title': 'Input Penilaian Siswa',
          'subtitle': 'Input nilai akademik siswa',
          'icon': Icons.grade_rounded,
          'color': const Color(0xFF7C3AED),
          'gradientColors': [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
          'textColor': Colors.white,
          'iconColor': Colors.white,
          'iconBgColor': Colors.white.withValues(alpha: 0.2),
        }),
        const SizedBox(height: 12),
        Row(
          children:
              row1
                  .map((menu) => Expanded(child: _buildMenuCard(context, menu)))
                  .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children:
              row2.map((menu) {
                int flex = menu['flex'] as int? ?? 1;
                return Expanded(
                  flex: flex,
                  child: _buildMenuCard(context, menu),
                );
              }).toList(),
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
            'title': 'Setoran',
            'subtitle': 'Pantau hafalan baru santri',
            'icon': Icons.edit_note_rounded,
            'color': Colors.teal,
          }),
          const SizedBox(height: 12),
          _buildFullWidthMenuCard(context, {
            'title': 'Penilaian',
            'subtitle': 'Pantau penilaian santri',
            'icon': Icons.assignment_turned_in_rounded,
            'color': Colors.orangeAccent,
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
          'subtitle': 'Input penilaian santri',
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
            'subtitle': 'Input hafalan baru santri',
            'icon': Icons.edit_note_rounded,
            'color': Colors.teal,
          }),
        ],
      );
    }
  }

  Widget _buildKesantrianMenuGrid(BuildContext context) {
    final otherMenus = [
      {
        'title': 'Absensi Makan',
        'icon': Icons.restaurant_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Pelanggaran',
        'icon': Icons.gavel_rounded,
        'color': Colors.redAccent,
      },
      {'title': 'Kepulangan', 'icon': Icons.home_rounded, 'color': Colors.teal},
      {
        'title': 'Izin Santri',
        'icon': Icons.fact_check_rounded,
        'color': Colors.green,
      },
    ];

    return Column(
      children: [
        _buildFullWidthMenuCard(context, {
          'title': 'Absensi Asrama',
          'subtitle': 'Input absensi asrama santri',
          'icon': Icons.night_shelter_rounded,
          'color': Colors.blueGrey,
        }),
        const SizedBox(height: 12),
        Row(
          children:
              otherMenus
                  .map((menu) => Expanded(child: _buildMenuCard(context, menu)))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildKabidMenuGrid(BuildContext context) {
    final menus = [
      {
        'title': 'Data Presensi',
        'icon': Icons.calendar_today_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Rekap Absensi',
        'icon': Icons.analytics_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Absensi Manual',
        'icon': Icons.edit_calendar_rounded,
        'color': Colors.teal,
      },
      {
        'title': 'Approve Kas',
        'icon': Icons.payments_outlined,
        'color': Colors.indigo,
      },
    ];

    return Row(
      children:
          menus
              .map((menu) => Expanded(child: _buildMenuCard(context, menu)))
              .toList(),
    );
  }

  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> menu) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                const SizedBox(height: 8),
                Text(
                  menu['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthMenuCard(
    BuildContext context,
    Map<String, dynamic> menu,
  ) {
    final Color baseColor = menu['color'] as Color;
    final List<Color> gradientColors =
        menu['gradientColors'] as List<Color>? ??
        [baseColor.withValues(alpha: 0.1), Colors.white];
    final Color textColor =
        menu['textColor'] as Color? ?? const Color(0xFF1E293B);
    final Color subtitleColor =
        menu['textColor'] as Color? ?? const Color(0xFF64748B);
    final Color iconBgColor =
        menu['iconBgColor'] as Color? ?? baseColor.withValues(alpha: 0.2);
    final Color iconColor = menu['iconColor'] as Color? ?? baseColor;

    return Container(
      width: double.infinity,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (menu['gradientColors'] != null)
                    ? (menu['gradientColors'] as List<Color>)[0].withValues(
                      alpha: 0.2,
                    )
                    : Colors.black.withValues(alpha: 0.05),
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
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    menu['icon'] as IconData,
                    color: iconColor,
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
                          color: textColor,
                        ),
                      ),
                      if (menu['subtitle'] != null)
                        Text(
                          menu['subtitle'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: subtitleColor.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color:
                      (menu['textColor'] != null)
                          ? (menu['textColor'] as Color).withValues(alpha: 0.5)
                          : (menu['color'] as Color).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _proceedToSetoran(BuildContext context, TahfidzProvider provider) {
    if (!isKoordinator && (!provider.isHalaqohOpened || !provider.isAttendanceSubmitted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !provider.isHalaqohOpened
                ? 'Mohon buka halaqoh dulu'
                : 'Mohon absen santri dulu',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetoranTahfidzScreen()),
    );
  }

  void _handleMenuNavigation(BuildContext context, String title) {
    String navTitle = title.trim();
    if (navTitle == 'Absensi Tahfidz') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AbsensiTahfidzScreen()),
      );
    } else if (navTitle == 'Absensi Pengampu') {
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
    } else if (navTitle == 'Setoran') {
      final provider = Provider.of<TahfidzProvider>(context, listen: false);
      
      // Jika data belum di-load (misal baru login), load dulu sebentar
      if (provider.teacherId == null) {
         SharedPreferences.getInstance().then((prefs) {
           int? tid = prefs.getInt('userId');
           String? tname = prefs.getString('fullName');
           provider.fetchMyStudents(tid, teacherName: tname).then((_) {
              if (context.mounted) {
                _proceedToSetoran(context, provider);
              }
           });
         });
         return;
      }

      _proceedToSetoran(context, provider);
    } else if (navTitle == 'Penilaian') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PenilaianTahfidzScreen()),
      );
    } else if (navTitle == 'RPP') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RppScreen()),
      );
    } else if (navTitle == 'Jadwal Mengajar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TeachingScheduleScreen()),
      );
    } else if (navTitle == 'Input Penilaian Siswa') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudentGradingScreen()),
      );
    } else if (navTitle == 'Rekap Presensi') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AttendanceRecapScreen()),
      );
    } else if (navTitle == 'Data Kelas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ClassListScreen()),
      );
    } else if (navTitle == 'Mata Pelajaran') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubjectListScreen()),
      );
    } else if (navTitle == 'Data Siswa') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudentDataScreen()),
      );
    } else if (navTitle == 'Kalender Akademik') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AcademicCalendarScreen()),
      );
    } else if (navTitle == 'Data Guru') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TeacherDataScreen()),
      );
    } else if (navTitle == 'Izin Kerja') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainPermitScreen()),
      );
    } else if (navTitle == 'Rapat Pertemuan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MeetingListScreen()),
      );
    } else if (navTitle == 'Inventaris Barang') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InventoryCategoryScreen(),
        ),
      );
    } else if (navTitle == 'Penggajian') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PayrollHistoryScreen()),
      );
    } else if (navTitle == 'Tukar Shift') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShiftSwapScreen()),
      ).then((_) => onRefresh());
    } else if (navTitle == 'Penugasan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AssignmentScreen()),
      );
    } else if (navTitle == 'Data Presensi') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DataPresensiScreen()),
      );
    } else if (navTitle == 'Rekap Absensi') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RekapAbsensiScreen()),
      );
    } else if (navTitle == 'Absensi Manual') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AbsensiManualScreen()),
      );
    } else if (navTitle == 'Approve Kas') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Menu Approve Kas masih dalam pengembangan"),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (navTitle == 'Absensi Asrama') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AbsensiAsramaScreen()),
      );
    } else if (navTitle == 'Absensi Makan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AbsensiMakanScreen()),
      );
    } else if (navTitle == 'Pelanggaran') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PelanggaranScreen()),
      );
    } else if (navTitle == 'Kepulangan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KepulanganScreen()),
      );
    } else if (navTitle == 'Izin Santri') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IzinSantriScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Menu $title akan segera hadir')));
    }
  }
}
