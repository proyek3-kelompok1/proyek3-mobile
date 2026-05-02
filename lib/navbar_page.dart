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

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.white,
        color: const Color(0xFF4A1059),
        buttonBackgroundColor: const Color(0xFF4A1059),
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.smart_toy_rounded, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
