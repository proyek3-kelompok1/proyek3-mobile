import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_api.dart';
import '../../core/services/notification_service.dart';
import '../auth/login_page.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'help_center/help_center_screen.dart';
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

    const primaryColor = Color(0xFF4A1059);
    const secondaryColor = Color(0xFF8E24AA);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with Gradient & Depth
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x404A1059),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        children: [
                          Text(
                            "Profil Saya",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 140,
                  child: Hero(
                    tag: 'profile_pic',
                    child: ProfilePic(
                      avatarUrl: _userData?['avatar'],
                      borderColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 85),

            // User Info Section
            Column(
              children: [
                Text(
                  _userData?['name'] ?? "Pengguna",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userData?['email'] ?? "email@example.com",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
                if (_userData?['phone'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: primaryColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 14, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          _userData!['phone'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 40),

            // Menu Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Pengaturan Akun"),
                  const SizedBox(height: 15),
                  _buildMenuCard([
                    ProfileMenu(
                      text: "Edit Akun",
                      icon: Icons.person_rounded,
                      subtitle: "Ubah nama, email, dan lainnya",
                      onTap: () async {
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
                      text: "Pengaturan",
                      icon: Icons.settings_suggest_rounded,
                      subtitle: "Notifikasi, bahasa, dan keamanan",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Dukungan & Lainnya"),
                  const SizedBox(height: 15),
                  _buildMenuCard([
                    ProfileMenu(
                      text: "Pusat Bantuan",
                      icon: Icons.help_center_rounded,
                      subtitle: "FAQ dan kontak dukungan",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    ProfileMenu(
                      text: "Keluar",
                      icon: Icons.logout_rounded,
                      subtitle: "Keluar dari akun Anda",
                      isLogout: true,
                      onTap: _handleLogout,
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D3142).withOpacity(0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  indent: 70,
                  endIndent: 20,
                  color: Colors.grey[100],
                  thickness: 1,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.text,
    required this.icon,
    required this.subtitle,
    this.onTap,
    this.isLogout = false,
  });

  final String text;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLogout;

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? const Color(0xFFEA4335) : const Color(0xFF4A1059);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2D3142),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  final String? avatarUrl;
  final Color borderColor;

  const ProfilePic({
    super.key,
    this.avatarUrl,
    this.borderColor = const Color(0xFF4A1059),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: borderColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 65,
          backgroundColor: const Color(0xFFF3EEFF),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null 
              ? const Icon(Icons.person_rounded, size: 85, color: Color(0xFF4A1059))
              : null,
        ),
      ),
    );
  }
}
