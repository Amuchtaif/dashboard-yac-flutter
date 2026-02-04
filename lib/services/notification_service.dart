import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotificationService {
  // 1. Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _timer;
  final List<String> _localNotificationIds = [];

  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // 2. Initialization
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_yac___white');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request Permissions (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // 3. Polling Logic
  void startPolling() {
    debugPrint('NotificationService: startPolling called');
    // Prevent multiple timers
    if (_timer != null && _timer!.isActive) return;

    // Fetch immediately
    _fetchNotifications();

    // Start timer (every 30 seconds)
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchNotifications();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _unreadCountController.close();
  }

  // 4. Fetch API
  // 4. Fetch API
  Future<void> _fetchNotifications() async {
    try {
      debugPrint('NotificationService: Calling getNotifications...');
      final notifications = await getNotifications();
      debugPrint(
        'NotificationService: Await complete. Received ${notifications.length} items.',
      );
      debugPrint(
        'NotificationService: Got ${notifications.length} notifications. Processing...',
      );
      _processNotifications(notifications);
    } catch (e, stackTrace) {
      debugPrint('Error polling notifications: $e\n$stackTrace');
    }
  }

  // Public method for UI
  Future<List<dynamic>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdInt = prefs.getInt('userId');
      final userId = userIdInt?.toString();

      debugPrint('NotificationService: Fetching for UserId: $userId');

      if (userId == null) return [];

      final url = '${ApiConfig.baseUrl}/get_notifications.php?user_id=$userId';

      debugPrint('NotificationService: Request URL: $url');

      final response = await http.get(Uri.parse(url));

      debugPrint('NotificationService: Response Code: ${response.statusCode}');
      debugPrint('NotificationService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final rawData = data['data'];
          debugPrint(
            'NotificationService: Data type is ${rawData.runtimeType}',
          );
          if (rawData is List) {
            debugPrint(
              'NotificationService: Valid list found, returning ${rawData.length} items...',
            );
            return List<dynamic>.from(rawData);
          } else {
            debugPrint('NotificationService: Data is NOT a list!');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    return [];
  }

  void _processNotifications(List<dynamic> notifications) {
    // Broadcast count for badge
    debugPrint(
      'NotificationService: Broadcasting unread count: ${notifications.length}',
    );
    _unreadCountController.add(notifications.length);

    for (var note in notifications) {
      String id = note['id'].toString();
      String title = note['title'] ?? 'Notification';
      String body = note['body'] ?? '';

      // Check if ID is new
      if (!_localNotificationIds.contains(id)) {
        _localNotificationIds.add(id);

        // 5. Trigger Local Notification
        debugPrint(
          'NotificationService: Triggering local notification for ID: $id',
        );
        showLocalNotification(
          id: id.hashCode, // Use unique int ID
          title: title,
          body: body,
        );
      }
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel', // Match main.dart & Manifest
          'High Importance Notifications', // Match main.dart
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/ic_stat_yac___white',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
