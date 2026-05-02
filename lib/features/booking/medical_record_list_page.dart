import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/medical_record_api.dart';
import '../../models/booking_model.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalRecordListPage extends StatefulWidget {
  const MedicalRecordListPage({super.key});

  @override
  State<MedicalRecordListPage> createState() => _MedicalRecordListPageState();
}

class _MedicalRecordListPageState extends State<MedicalRecordListPage> {
  late Future<List<MedicalRecordModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = MedicalRecordApi.fetchAllMedicalRecords();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A1059);
    const purpleBg = Color(0xFFF3EEFF);

    return Scaffold(
      backgroundColor: purpleBg,
      appBar: AppBar(
        title: Text(
          "Riwayat Medis",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<MedicalRecordModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerList(itemCount: 6);
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = MedicalRecordApi.fetchAllMedicalRecords();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return _MedicalRecordSimpleCard(record: records[index]);
              },
            ),
          );
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
            "Belum ada riwayat medis",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            "Hasil periksa dokter akan muncul di sini",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Gagal memuat data",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalRecordSimpleCard extends StatelessWidget {
  final MedicalRecordModel record;
  const _MedicalRecordSimpleCard({required this.record});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A1059);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medical_services_outlined, color: purple, size: 20),
          ),
          title: Text(
            record.namaHewan,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            "${record.tanggalPemeriksaan} • ${record.diagnosa}",
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            const Divider(),
            _buildDetailRow("Kode", record.kodeRekamMedis),
            _buildDetailRow("Dokter", record.dokter),
            _buildDetailRow("Diagnosis", record.diagnosa),
            if (record.tindakan != null) _buildDetailRow("Tindakan", record.tindakan!),
            if (record.resepObat != null) _buildDetailRow("Resep", record.resepObat!),
            if (record.catatanDokter != null) _buildDetailRow("Catatan", record.catatanDokter!),
            if (record.kunjunganBerikutnya != null)
              _buildDetailRow("Kembali", record.kunjunganBerikutnya!, color: Colors.orange),
            
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadPDF(context),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text("Download PDF", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPDF(BuildContext context) async {
    if (record.id == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final url = Uri.parse(ApiConstants.medicalRecordPdf(record.id!));
      
      // Karena ini download file, kita bisa buka di browser dengan token sebagai query param
      // atau jika backend mengizinkan auth via header, url_launcher butuh plugin tambahan untuk header.
      // Namun biasanya PDF download paling mudah via browser. 
      // Mari coba buka URL-nya. Jika butuh auth, kita bisa sertakan token di URL (jika backend support)
      // atau download via http client lalu simpan file.
      // Untuk kemudahan dan sesuai riwayat web, kita coba launchUrl.
      
      final downloadUrl = token != null 
          ? Uri.parse("${url.toString()}?token=$token") 
          : url;

      if (!await launchUrl(downloadUrl, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $downloadUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengunduh PDF: $e")),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
