import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4A1059);
    const secondaryColor = Color(0xFF8E24AA);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Kebijakan Privasi",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    1,
                    "Informasi yang Kami Kumpulkan",
                    "Kami mengumpulkan informasi yang Anda berikan secara langsung kepada kami, seperti saat Anda membuat akun, melakukan booking, atau menghubungi layanan pelanggan. Ini termasuk nama, alamat email, nomor telepon, dan informasi hewan peliharaan Anda.",
                  ),
                  _buildSection(
                    2,
                    "Penggunaan Informasi",
                    "Kami menggunakan informasi tersebut untuk memproses booking Anda, memberikan layanan konsultasi, mengelola akun Anda, dan mengirimkan informasi penting terkait layanan kami.",
                  ),
                  _buildSection(
                    3,
                    "Keamanan Data",
                    "Kami menerapkan langkah-langkah keamanan teknis dan organisasional yang tepat untuk melindungi data pribadi Anda dari akses, penggunaan, atau pengungkapan yang tidak sah.",
                  ),
                  _buildSection(
                    4,
                    "Berbagi Informasi",
                    "Kami tidak menjual atau menyewakan informasi pribadi Anda kepada pihak ketiga. Kami hanya berbagi informasi dengan dokter hewan atau mitra layanan yang diperlukan untuk memenuhi kebutuhan medis hewan Anda.",
                  ),
                  _buildSection(
                    5,
                    "Hak Anda",
                    "Anda memiliki hak untuk mengakses, memperbarui, atau meminta penghapusan data pribadi Anda kapan saja melalui pengaturan akun atau dengan menghubungi kami.",
                  ),
                  _buildSection(
                    6,
                    "Cookies",
                    "Aplikasi kami dapat menggunakan cookies dan teknologi serupa untuk meningkatkan pengalaman pengguna dan menganalisis penggunaan aplikasi.",
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Terakhir diperbarui: 27 April 2026",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Icon(Icons.security_outlined, color: Colors.grey, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(int index, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A1059).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  index.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A1059),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
