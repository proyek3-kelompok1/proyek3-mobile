import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/home_page.dart';
import 'features/home/doctor_home_page.dart';
import 'features/profile/profile_screen.dart';
import 'navbar/curved_navigation_bar.dart';
import 'features/ai/ai_chat_page.dart';
import 'core/services/auth_api.dart';

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key});

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  int _selectedIndex = 0;
  bool _isDoctor = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
    // Sync FCM Token
    AuthApi().syncFcmToken();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDoctor = prefs.getString('user_role') == 'doctor';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages = [
      _isDoctor ? const DoctorHomePage() : const HomeScreen(),
      const AiChatPage(),
      const ProfileScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: CurvedNavigationBar(
          index: _selectedIndex,
          height: 65,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          color: isDark ? const Color(0xFF1E1E2C) : primary,
          buttonBackgroundColor: isDark ? const Color(0xFFC05DE3) : primary,
          animationDuration: const Duration(milliseconds: 300),
          items: const [
            Icon(Icons.home_rounded, size: 32, color: Colors.white),
            Icon(Icons.pets_rounded, size: 32, color: Colors.white), // DokterPaw icon!
            Icon(Icons.person_rounded, size: 32, color: Colors.white),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
