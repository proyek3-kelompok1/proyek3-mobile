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
                "Syarat & Ketentuan",
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
                          "Terakhir diperbarui: 27 April 2026",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Icon(Icons.verified_user_outlined, color: Colors.grey, size: 24),
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
