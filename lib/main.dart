import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'core/providers/settings_provider.dart';
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
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MyApp(isLoggedIn: token != null),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: settingsProvider.themeMode,
      locale: settingsProvider.locale,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4A1059),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A1059),
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4A1059),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A1059),
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn ? const NavBarPage() : const LoginPage(),
    );
  }
}
