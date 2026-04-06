import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              const Text(
                "Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A1059)),
              ),

              const SizedBox(height: 20),
              const ProfilePic(),
              const SizedBox(height: 30),

              ProfileMenu(
                text: "My Account",
                icon: Icons.person_outline,
                press: () {},
              ),
              ProfileMenu(
                text: "Notifications",
                icon: Icons.notifications_none,
                press: () {},
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
                press: () {},
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4A1059),
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFFF3EEFF),
        ),
        onPressed: press,
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4A1059),
              size: 26,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF4A1059),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF4A1059), size: 16),
          ],
        ),
      ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  const ProfilePic({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundColor: Color(0xFFF3EEFF),
          child: Icon(Icons.person, size: 80, color: Color(0xFF4A1059)),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 40,
            width: 40,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                backgroundColor: const Color(0xFF4A1059),
              ),
              onPressed: () {},
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        )
      ],
    );
  }
}
