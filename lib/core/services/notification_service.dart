import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).toString();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2. Local Notifications Setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click
      },
    );

    // 3. Request Permissions
    if (Platform.isIOS) {
      await _fcm.requestPermission();
    }
  }

  // Show immediate notification (Local)
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dvpets_channel',
      'DV Pets Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details);
  }

  // Schedule notification (e.g. for booking)
  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dvpets_reminders',
          'DV Pets Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Get FCM Token
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  // Background message handler
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }
}
