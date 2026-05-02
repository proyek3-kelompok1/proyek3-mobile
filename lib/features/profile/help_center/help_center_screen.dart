import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'terms_and_conditions_screen.dart';
import 'privacy_policy_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _allFaqs = [
    {
      "question": "Bagaimana cara booking?",
      "answer": "Pilih layanan yang Anda inginkan di halaman utama, pilih jadwal yang tersedia, lalu lakukan konfirmasi pembayaran."
    },
    {
      "question": "Apakah bisa membatalkan janji?",
      "answer": "Ya, pembatalan dapat dilakukan maksimal 24 jam sebelum jadwal melalui menu riwayat transaksi."
    },
    {
      "question": "Metode pembayaran apa saja?",
      "answer": "Kami mendukung berbagai metode pembayaran mulai dari Transfer Bank hingga E-Wallet (Gopay, OVO, Dana)."
    },
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4A1059);
    const secondaryColor = Color(0xFF8E24AA);
    const bgColor = Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Pusat Bantuan",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.support_agent_rounded,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: const Icon(
                              Icons.headset_mic_rounded,
                              size: 45,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Kami siap membantu Anda",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Butuh Bantuan Cepat?"),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.chat_rounded,
                          title: "WhatsApp",
                          subtitle: "Chat langsung",
                          color: const Color(0xFF25D366),
                          onTap: _launchWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.alternate_email_rounded,
                          title: "Email",
                          subtitle: "Kirim pesan",
                          color: const Color(0xFFEA4335),
                          onTap: _launchEmail,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader("Pertanyaan Umum"),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(
                          "Lihat Semua",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._allFaqs.map(
                    (faq) => _buildFAQItem(
                      faq['question']!,
                      faq['answer']!,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildSectionHeader("Hukum & Kebijakan"),
                  const SizedBox(height: 18),
                  _buildMenuCard([
                    _buildPolicyTile(
                      "Syarat & Ketentuan",
                      Icons.description_rounded,
                      "Aturan penggunaan aplikasi",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsAndConditionsScreen(),
                        ),
                      ),
                    ),
                    _buildPolicyTile(
                      "Kebijakan Privasi",
                      Icons.verified_user_rounded,
                      "Cara kami menjaga data Anda",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUrl = Uri.parse("https://wa.me/6283110050163");
    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka WhatsApp")),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'karinanaw2108@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Bantuan DV Pets App',
      }),
    );

    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka aplikasi Email")),
        );
      }
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A1059),
            ),
          ),
          iconColor: const Color(0xFF4A1059),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                answer,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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

  Widget _buildPolicyTile(String title, IconData icon, String subtitle, VoidCallback onTap) {
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
}