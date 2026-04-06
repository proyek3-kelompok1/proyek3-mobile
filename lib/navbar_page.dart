import 'package:flutter/material.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_screen.dart';
import 'navbar/curved_navigation_bar.dart';
import 'features/ai/ai_chat_page.dart';

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key});

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const AiChatPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

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
