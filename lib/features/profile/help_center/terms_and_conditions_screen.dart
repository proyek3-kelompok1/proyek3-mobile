import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4A1059);
    const secondaryColor = Color(0xFF8E24AA);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
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
                "Syarat & Ketentuan",
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
                child: Center(
                  child: Icon(
                    Icons.gavel_rounded,
                    size: 90,
                    color: Colors.white.withOpacity(0.15),
                  ),
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
                  _buildSection(
                    1,
                    "Penerimaan Ketentuan",
                    "Dengan menggunakan aplikasi DVPets, Anda setuju untuk terikat oleh Syarat & Ketentuan ini. Jika Anda tidak menyetujui bagian apa pun dari ketentuan ini, Anda tidak diperbolehkan menggunakan layanan kami.",
                  ),
                  _buildSection(
                    2,
                    "Layanan Kami",
                    "DVPets menyediakan platform untuk booking layanan kesehatan hewan, konsultasi dokter hewan, dan manajemen rekam medis hewan peliharaan Anda.",
                  ),
                  _buildSection(
                    3,
                    "Akun Pengguna",
                    "Anda bertanggung jawab untuk menjaga kerahasiaan informasi akun dan kata sandi Anda. Anda setuju untuk bertanggung jawab atas semua aktivitas yang terjadi di bawah akun Anda.",
                  ),
                  _buildSection(
                    4,
                    "Kebijakan Pembatalan",
                    "Pembatalan janji temu dapat dilakukan melalui aplikasi paling lambat 24 jam sebelum waktu yang dijadwalkan. Pembatalan yang dilakukan kurang dari 24 jam mungkin akan dikenakan biaya administrasi.",
                  ),
                  _buildSection(
                    5,
                    "Batasan Tanggung Jawab",
                    "DVPets tidak bertanggung jawab atas kerugian atau kerusakan yang timbul dari penggunaan layanan kami, kecuali jika diwajibkan oleh hukum yang berlaku.",
                  ),
                  _buildSection(
                    6,
                    "Perubahan Ketentuan",
                    "Kami berhak untuk mengubah Syarat & Ketentuan ini kapan saja. Perubahan akan berlaku segera setelah dipublikasikan di aplikasi.",
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Terakhir diperbarui: 30 April 2026",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: primaryColor, size: 28),
                        ),
                      ],
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

  Widget _buildSection(int index, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A1059), Color(0xFF8E24AA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A1059).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.8,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
