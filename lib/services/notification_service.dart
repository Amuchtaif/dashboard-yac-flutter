import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
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
  final Set<String> _processedIds = {};

  final StreamController<String?> _selectNotificationController =
      StreamController<String?>.broadcast();
  Stream<String?> get selectNotificationStream =>
      _selectNotificationController.stream;

  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // 2. Initialization
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_yac___white');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          'NotificationService: Local Notification Tapped with payload: ${response.payload}',
        );
        if (response.payload != null) {
          _selectNotificationController.add(response.payload);
        }
      },
    );

    // Request Permissions (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Load persistent processed IDs
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedIds =
        prefs.getStringList('shown_notification_ids') ?? [];
    _processedIds.addAll(savedIds);
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
    _selectNotificationController.close();
  }

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

  /// Public method to immediately refresh the badge count (e.g. after FCM arrives)
  Future<void> refreshBadge() async {
    try {
      final notifications = await getNotifications();
      if (!_unreadCountController.isClosed) {
        _unreadCountController.add(notifications.length);
      }
    } catch (e) {
      debugPrint('Error refreshing badge: $e');
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

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

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

  void _processNotifications(List<dynamic> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedIds =
        prefs.getStringList('shown_notification_ids') ?? [];
    _processedIds.addAll(savedIds);

    // Broadcast count for badge
    _unreadCountController.add(notifications.length);

    for (var note in notifications) {
      String id = note['id'].toString();
      String title = note['title'] ?? 'Notification';
      String body = note['body'] ?? '';
      String? payload = jsonEncode(note);

      // Unique identifying hash for title+body as fallback
      String contentHash = 'hash_${title.hashCode}_${body.hashCode}';

      // Deduplicate: Don't show again if already processed
      if (!_processedIds.contains(id) && !_processedIds.contains(contentHash)) {
        debugPrint(
          'NotificationService: Polling found NEW notification ID: $id',
        );
        showLocalNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );

        // Save to persistent storage
        _processedIds.add(id);
        _processedIds.add(contentHash);
        await prefs.setStringList(
          'shown_notification_ids',
          _processedIds.toList(),
        );
      }
    }
  }

  /// Dismiss a single notification by its key (e.g. "asn_5", "inc_3")
  Future<void> dismissNotification(String notificationKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId')?.toString();
      if (userId == null) return;

      final url =
          '${ApiConfig.baseUrl}/dismiss_notification.php?user_id=$userId&notification_key=${Uri.encodeComponent(notificationKey)}';
      await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      // Refresh badge count
      await refreshBadge();
    } catch (e) {
      debugPrint('Error dismissing notification: $e');
    }
  }

  Future<void> clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId')?.toString();
      if (userId == null) return;

      final url =
          '${ApiConfig.baseUrl}/delete_notifications.php?user_id=$userId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        debugPrint('NotificationService: All notifications cleared');
      }

      // Clear local processed IDs cache so badge resets
      _processedIds.clear();
      await prefs.remove('shown_notification_ids');

      // Broadcast 0 to reset the bell badge immediately
      if (!_unreadCountController.isClosed) {
        _unreadCountController.add(0);
      }
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Future<void> showLocalNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Content hash for cross-source deduplication (FCM vs polling)
    String contentHash = 'hash_${title.hashCode}_${body.hashCode}';

    // Shared deduplication check (by ID or content hash)
    if (_processedIds.contains(id) || _processedIds.contains(contentHash)) {
      debugPrint('NotificationService: Skipping already processed: $id');
      return;
    }
    _processedIds.add(id);
    _processedIds.add(contentHash);

    // Also save to prefs for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shown_notification_ids', _processedIds.toList());

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
          color: Color(0xFF1F3C88), // Blue Primary
          colorized: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
