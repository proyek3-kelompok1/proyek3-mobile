import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/pet_profile_api.dart';
import '../../models/pet_profile_model.dart';
import 'add_edit_pet_page.dart';
import 'pet_profile_detail_page.dart';

class PetProfileListPage extends StatefulWidget {
  const PetProfileListPage({super.key});

  @override
  State<PetProfileListPage> createState() => _PetProfileListPageState();
}

class _PetProfileListPageState extends State<PetProfileListPage> {
  List<PetProfileModel> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    final pets = await PetProfileApi.getProfiles();
    setState(() {
      _pets = pets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A1059);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Profil Anabul",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: purple))
          : _pets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada profil anabul.",
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEditPetPage()),
                          ).then((_) => _loadPets());
                        },
                        icon: const Icon(Icons.add),
                        label: Text("Tambah Anabul", style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPets,
                  color: purple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pets.length,
                    itemBuilder: (context, index) {
                      final pet = _pets[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PetProfileDetailPage(petId: pet.id)),
                          ).then((_) => _loadPets());
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: purple.withOpacity(0.1),
                                backgroundImage: pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
                                child: pet.photoUrl == null ? const Icon(Icons.pets, color: purple) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${pet.type} • ${pet.breed ?? 'Unknown'}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: pet.needsVaccine || pet.needsGrooming 
                                            ? Colors.orange.withOpacity(0.1) 
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        pet.healthStatus,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: pet.needsVaccine || pet.needsGrooming 
                                              ? Colors.orange[800] 
                                              : Colors.green[800],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _pets.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditPetPage()),
                ).then((_) => _loadPets());
              },
              backgroundColor: purple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
