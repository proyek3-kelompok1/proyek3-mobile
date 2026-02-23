import 'package:flutter/material.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_screen.dart';
import 'navbar/curved_navigation_bar.dart';
import 'features/home/page/booking_page.dart';
import 'features/home/page/services_page.dart';

class NavBarPage extends StatefulWidget {
  const NavBarPage({super.key});

  @override
  State<NavBarPage> createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    // const BookingPage(), ServicesPage(),
    const BookingPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.white,
        color: const Color(0xFF4A3298),
        buttonBackgroundColor: const Color(0xFF4A3298),
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.calendar_month, size: 30, color: Colors.white),
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
