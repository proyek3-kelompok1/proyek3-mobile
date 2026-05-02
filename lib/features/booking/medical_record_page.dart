import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/booking_model.dart';

class MedicalRecordPage extends StatelessWidget {
  final List<MedicalRecordModel> medicalRecords;
  const MedicalRecordPage({super.key, required this.medicalRecords});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A1059);
    const purpleDark = Color(0xFF4A1059);
    const purpleBg = Color(0xFFF3EEFF);

    return Scaffold(
      backgroundColor: purpleBg,
      appBar: AppBar(
        title: Text(
          "Rekam Medis",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: purple,
        elevation: 0,
      ),
      body: medicalRecords.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medicalRecords.length,
              itemBuilder: (context, index) {
                return _MedicalRecordCard(record: medicalRecords[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Belum ada rekam medis",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  final MedicalRecordModel record;
  const _MedicalRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A1059);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: purple.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.kodeRekamMedis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: purple,
                      ),
                    ),
                    Text(
                      record.tanggalPemeriksaan,
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.pets, "Hewan", "${record.namaHewan} (${record.jenisHewan})"),
                _buildInfoRow(Icons.person, "Dokter", record.dokter),
                const Divider(height: 24),
                _buildSection("Diagnosis", record.diagnosa, Icons.healing),
                if (record.tindakan != null) _buildSection("Tindakan", record.tindakan!, Icons.medical_services),
                if (record.resepObat != null) _buildSection("Resep Obat", record.resepObat!, Icons.medication),
                if (record.catatanDokter != null) _buildSection("Catatan Dokter", record.catatanDokter!, Icons.note_alt),
                
                if (record.kunjunganBerikutnya != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.event_repeat, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        "Kunjungan Berikutnya: ${record.kunjunganBerikutnya}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF4A1059)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A1059),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
