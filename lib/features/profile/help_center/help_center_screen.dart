import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            expandedHeight: 160.0, // diperkecil
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 80, 25, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo, Ada yang bisa\nkami bantu?",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("FAQ"),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Lihat Semua",
                          style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                  ..._allFaqs.map(
                    (faq) => _buildFAQItem(
                      faq['question']!,
                      faq['answer']!,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _buildSectionTitle("Butuh Bantuan Lebih Lanjut?"),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.chat_outlined,
                          title: "WhatsApp",
                          color: const Color(0xFF25D366),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.email_outlined,
                          title: "Email",
                          color: const Color(0xFFEA4335),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                   _buildSectionTitle("Hukum & Kebijakan"),
                  const SizedBox(height: 10),
                  _buildPolicyTile(
                    "Syarat & Ketentuan",
                    Icons.gavel_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsScreen(),
                      ),
                    ),
                  ),
                  _buildPolicyTile(
                    "Kebijakan Privasi",
                    Icons.security_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D3142),
        ),
      ),
    );
  }


  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A1059),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPolicyTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A1059).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4A1059), size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3142),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF4A1059)),
        onTap: onTap,
      ),
    );
  }
}