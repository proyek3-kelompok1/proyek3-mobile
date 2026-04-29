import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'navbar_page.dart';
import 'features/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp();
  
  // 2. Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  
  // 3. Handle background messages
  FirebaseMessaging.onBackgroundMessage(NotificationService.handleBackgroundMessage);

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4A1059),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn ? const NavBarPage() : const LoginPage(),
    );
  }
}
