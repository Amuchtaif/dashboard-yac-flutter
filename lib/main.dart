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
import 'providers/quran_provider.dart';
import 'providers/app_status_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';
import 'config/api_config.dart';
import 'screens/maintenance_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  debugPrint("🔥 INITIALIZING FIREBASE...");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint("✅ FIREBASE CONNECTED!");
  } catch (e) {
    debugPrint("❌ FIREBASE INIT ERROR: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
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

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final int? loginTimestamp = prefs.getInt('login_timestamp');
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  bool isSessionValid = false;

  if (isLoggedIn && loginTimestamp != null) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - loginTimestamp;
    const sessionTimeout = 172800000;

    if (diff < sessionTimeout) {
      debugPrint("✅ SESSION VALID");
      isSessionValid = true;
      await PermissionService().loadFromCache();
      await prefs.setInt('login_timestamp', now);
    } else {
      debugPrint("❌ SESSION EXPIRED");
      await prefs.clear();
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

  String? maintenanceMessage;
  bool isMaintenance = false;

  try {
    final response = await http
        .get(Uri.parse("${ApiConfig.baseUrl}/app_status.php"))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'maintenance') {
        isMaintenance = true;
        maintenanceMessage = data['message'];
      }
    }
  } catch (e) {
    debugPrint("⚠️ Failed to check maintenance status: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TahfidzProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(
          create:
              (_) => AppStatusProvider(
                initialIsMaintenance: isMaintenance == true,
                initialMessage: maintenanceMessage,
              ),
        ),
      ],
      child: MyApp(
        isSessionValid: isSessionValid == true,
        isMaintenance: isMaintenance == true,
        maintenanceMessage: maintenanceMessage,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isSessionValid;
  final bool isMaintenance;
  final String? maintenanceMessage;

  const MyApp({
    super.key,
    this.isSessionValid = false,
    this.isMaintenance = false,
    this.maintenanceMessage,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCMMaintenanceListener();
  }

  void _setupFCMMaintenanceListener() {
    // Subscribe to maintenance topic
    FirebaseMessaging.instance.subscribeToTopic('maintenance');

    // Handle messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("FCM Message Received: ${message.data}");
      _handleMaintenanceMessage(message);
    });

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMaintenanceMessage(message);
    });
  }

  void _handleMaintenanceMessage(RemoteMessage message) {
    if (message.data['type'] == 'maintenance') {
      final bool isMaint = message.data['status'] == 'true' || message.data['status'] == '1';
      final String? msg = message.data['message'];

      if (mounted) {
        context.read<AppStatusProvider>().updateStatus(isMaint, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "MyApp Build - isMaintenance: ${widget.isMaintenance}, isSessionValid: ${widget.isSessionValid}",
    );
    return MaterialApp(
      title: 'Aplikasi YAC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Consumer<AppStatusProvider>(
          builder: (context, appStatus, _) {
            if (appStatus.isMaintenance) {
              return MaintenanceScreen(
                message:
                    appStatus.maintenanceMessage ??
                    "Sedang pemeliharaan sistem",
                isSessionValid: widget.isSessionValid,
              );
            }
            return child!;
          },
        );
      },
      home: widget.isSessionValid ? const DashboardScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
