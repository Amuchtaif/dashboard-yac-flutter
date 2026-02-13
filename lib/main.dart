import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/permission_service.dart';
import 'providers/tahfidz_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  debugPrint("🔥 INITIALIZING FIREBASE...");
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Define Android Notification Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  debugPrint("✅ FIREBASE CONNECTED!");

  // --- CEK SESI LOGIN (24 JAM) ---
  final prefs = await SharedPreferences.getInstance();
  final int? loginTimestamp = prefs.getInt('login_timestamp');
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  bool isSessionValid = false;

  if (isLoggedIn && loginTimestamp != null) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - loginTimestamp;
    // 24 Jam = 24 * 60 * 60 * 1000 = 86,400,000 ms
    const sessionTimeout = 86400000;

    if (diff < sessionTimeout) {
      debugPrint(
        "✅ SESSION VALID (Login: ${DateTime.fromMillisecondsSinceEpoch(loginTimestamp)})",
      );
      isSessionValid = true;
      // Initialize permission service
      await PermissionService().loadFromCache();
      // Sliding Expiration: Update timestamp agar session diperpanjang jika aktif
      await prefs.setInt('login_timestamp', now);
    } else {
      debugPrint(
        "❌ SESSION EXPIRED (Diff: ${diff}ms > ${sessionTimeout}ms). LOGOUT.",
      );
      await prefs.clear(); // Reset session
    }
  } else {
    debugPrint("ℹ️ NO ACTIVE SESSION");
    await prefs.clear();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TahfidzProvider())],
      child: MyApp(isSessionValid: isSessionValid),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isSessionValid;
  const MyApp({super.key, required this.isSessionValid});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi YAC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // Jika Sesi Valid -> Dashboard, Jika Tidak -> Login
      home: isSessionValid ? const DashboardScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
