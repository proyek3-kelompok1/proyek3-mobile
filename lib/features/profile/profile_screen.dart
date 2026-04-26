import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_api.dart';
import '../../core/services/notification_service.dart';
import '../auth/login_page.dart';
import 'edit_profile_screen.dart';
import '../../core/widgets/shimmer_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthApi _authApi = AuthApi();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getString('user_data');
    
    if (localData != null) {
      setState(() {
        _userData = jsonDecode(localData);
        _isLoading = false;
      });
    }

    // Ambil data terbaru dari API
    final apiData = await _authApi.getProfile();
    if (apiData != null) {
      setState(() {
        _userData = apiData;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final success = await _authApi.logout();
    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userData == null) {
      return const ShimmerList(itemCount: 5);
    }

    return SafeArea(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Profile",
                style: GoogleFonts.poppins(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: const Color(0xFF4A1059)
                ),
              ),
              const SizedBox(height: 20),
              
              // Profil Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ProfilePic(avatarUrl: _userData?['avatar']),
                    const SizedBox(height: 15),
                    Text(
                      _userData?['name'] ?? "User Name",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      _userData?['email'] ?? "email@example.com",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (_userData?['phone'] != null)
                      Text(
                        _userData!['phone'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF4A1059),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              ProfileMenu(
                text: "Edit Account",
                icon: Icons.person_outline,
                press: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(userData: _userData!),
                    ),
                  );
                  if (result == true) {
                    _loadUserData();
                  }
                },
              ),
              ProfileMenu(
                text: "Test Notification",
                icon: Icons.notifications_active_outlined,
                press: () {
                  NotificationService().showNotification(
                    title: "Halo dari DVPets! 🐾",
                    body: "Ini adalah notifikasi uji coba untuk memastikan sistem berjalan lancar.",
                  );
                },
              ),
              ProfileMenu(
                text: "Settings",
                icon: Icons.settings_outlined,
                press: () {},
              ),
              ProfileMenu(
                text: "Help Center",
                icon: Icons.help_outline,
                press: () {},
              ),
              ProfileMenu(
                text: "Log Out",
                icon: Icons.logout,
                press: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.text,
    required this.icon,
    this.press,
  });

  final String text;
  final IconData icon;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4A1059),
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFFF3EEFF),
          elevation: 0,
        ),
        onPressed: press,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A1059), size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4A1059),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF4A1059), size: 14),
          ],
        ),
      ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  final String? avatarUrl;
  const ProfilePic({super.key, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4A1059), width: 2),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFF3EEFF),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null 
                  ? const Icon(Icons.person, size: 80, color: Color(0xFF4A1059))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
