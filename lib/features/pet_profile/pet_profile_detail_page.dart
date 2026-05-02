import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/pet_profile_api.dart';
import '../../models/pet_profile_model.dart';

class PetProfileDetailPage extends StatefulWidget {
  final int petId;
  const PetProfileDetailPage({super.key, required this.petId});

  @override
  State<PetProfileDetailPage> createState() => _PetProfileDetailPageState();
}

class _PetProfileDetailPageState extends State<PetProfileDetailPage> {
  PetProfileModel? _pet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  Future<void> _loadPet() async {
    final pet = await PetProfileApi.getProfileDetail(widget.petId);
    setState(() {
      _pet = pet;
      _isLoading = false;
    });
  }

  Future<void> _deletePet() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Profil", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus profil anabul ini?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await PetProfileApi.deleteProfile(widget.petId);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A1059);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: purple)));
    }

    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Anabul")),
        body: const Center(child: Text("Data tidak ditemukan")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Detail Anabul", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deletePet,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: purple.withOpacity(0.1),
                    backgroundImage: _pet!.photoUrl != null ? NetworkImage(_pet!.photoUrl!) : null,
                    child: _pet!.photoUrl == null ? const Icon(Icons.pets, size: 50, color: purple) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _pet!.name,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${_pet!.type} • ${_pet!.breed ?? 'Tidak diketahui'}",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoBadge("Umur", _pet!.ageFormatted),
                      const SizedBox(width: 16),
                      _buildInfoBadge("Berat", _pet!.weightKg != null ? "${_pet!.weightKg} Kg" : "-"),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Smart Recommendations
            if (_pet!.smartRecommendations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          "Smart Insights",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._pet!.smartRecommendations.map((rec) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

            // Health History
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Catatan Kesehatan",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _pet!.healthHistoryNotes != null && _pet!.healthHistoryNotes!.isNotEmpty
                          ? _pet!.healthHistoryNotes!
                          : "Belum ada catatan kesehatan.",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A1059))),
        ],
      ),
    );
  }
}
