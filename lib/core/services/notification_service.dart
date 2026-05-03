import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  final ValueNotifier<List<AppNotification>> notificationsNotifier = ValueNotifier([]);
  
  int get unreadCount => notificationsNotifier.value.where((n) => !n.isRead).length;

  Future<void> init() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = tzInfo.toString();
      // Beberapa device return "TimezoneInfo(Asia/Jakarta, ...)" bukan "Asia/Jakarta"
      if (timeZoneName.contains('/') && timeZoneName.contains('(')) {
        final match = RegExp(r'([\w]+/[\w]+)').firstMatch(timeZoneName);
        timeZoneName = match?.group(1) ?? 'Asia/Jakarta';
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback ke Asia/Jakarta jika gagal
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

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

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Got a message in foreground: ${message.messageId}");
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
        );
      }
    });

    // 5. Handle Notification Click when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked! ${message.data}");
    });

    // 6. Subscribe to Topics
    subscribeToTopic('education');
    subscribeToTopic('all_users');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print("Subscribed to topic: $topic");
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print("Unsubscribed from topic: $topic");
  }

  // Show immediate notification (Local)
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'dvpets_main_channel',
      'DVPets Notifications',
      channelDescription: 'Informasi dan notifikasi penting dari DVPets',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF4A1059),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      subText: 'DVPets Care',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Kabar Terbaru',
      ),
      playSound: true,
      enableVibration: true,
      ledColor: const Color(0xFF4A1059),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Notifikasi Baru DVPets',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details);

    // Add to internal list
    final newNotif = AppNotification(
      id: id.toString() + DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    
    final currentList = List<AppNotification>.from(notificationsNotifier.value);
    currentList.insert(0, newNotif);
    notificationsNotifier.value = currentList;
  }

  void markAsRead(String id) {
    final currentList = List<AppNotification>.from(notificationsNotifier.value);
    final index = currentList.indexWhere((n) => n.id == id);
    if (index != -1) {
      currentList[index].isRead = true;
      notificationsNotifier.value = currentList;
    }
  }

  void markAllAsRead() {
    final currentList = List<AppNotification>.from(notificationsNotifier.value);
    for (var n in currentList) {
      n.isRead = true;
    }
    notificationsNotifier.value = currentList;
  }

  void clearNotifications() {
    notificationsNotifier.value = [];
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
          'DVPets Reminders',
          channelDescription: 'Pengingat jadwal booking dan kesehatan anabul',
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFF4A1059),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          subText: 'DVPets Reminder',
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
