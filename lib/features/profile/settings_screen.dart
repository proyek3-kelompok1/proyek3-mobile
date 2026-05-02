import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = "Bahasa Indonesia";

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A1059), Color(0xFF8E24AA)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Color(0x304A1059),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Pengaturan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Preferensi Umum"),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: "Notifikasi",
                subtitle: "Update status booking & promo",
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
              _buildSwitchTile(
                icon: Icons.dark_mode_rounded,
                title: "Mode Gelap",
                subtitle: "Tampilan gelap yang nyaman",
                value: _darkMode,
                onChanged: (val) => setState(() => _darkMode = val),
              ),
              _buildActionTile(
                icon: Icons.translate_rounded,
                title: "Bahasa Aplikasi",
                subtitle: _selectedLanguage,
                onTap: _showLanguagePicker,
              ),
            ]),

            const SizedBox(height: 30),

            _buildSectionHeader("Keamanan & Akun"),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.lock_person_rounded,
                title: "Ubah Kata Sandi",
                subtitle: "Perbarui keamanan akun Anda",
                onTap: () {},
              ),
              // _buildActionTile(
              //   icon: Icons.phonelink_lock_rounded,
              //   title: "Verifikasi Dua Langkah",
              //   subtitle: "Keamanan ekstra untuk login",
              //   onTap: () {},
              // ),
            ]),

            const SizedBox(height: 30),

            _buildSectionHeader("Tentang Kami"),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.star_outline_rounded,
                title: "Beri Rating",
                subtitle: "Bantu kami menjadi lebih baik",
                onTap: () {},
              ),
              // _buildActionTile(
              //   icon: Icons.info_outline_rounded,
              //   title: "Versi Aplikasi",
              //   subtitle: "v2.1.0 (Stable Build)",
              //   onTap: () {},
              // ),
            ]),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D3142).withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A1059).withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF4A1059), size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12, 
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF4A1059),
              activeTrackColor: const Color(0xFF4A1059).withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A1059).withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: const Color(0xFF4A1059), size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12, 
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Pilih Bahasa",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 25),
              _buildLanguageOption("Bahasa Indonesia", "id"),
              _buildLanguageOption("English (US)", "us"),
              _buildLanguageOption("English (UK)", "uk"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String lang, String code) {
    bool isSelected = _selectedLanguage == lang;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4A1059).withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? const Color(0xFF4A1059).withOpacity(0.2) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          lang,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF4A1059) : const Color(0xFF2D3142),
          ),
        ),
        trailing: isSelected 
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4A1059), size: 22)
            : null,
        onTap: () {
          setState(() => _selectedLanguage = lang);
          Navigator.pop(context);
        },
      ),
    );
  }
}
