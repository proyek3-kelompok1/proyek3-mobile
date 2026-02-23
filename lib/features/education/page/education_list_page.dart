import 'package:flutter/material.dart';
import '../services/education_services.dart';
import '../../../models/education_model.dart';

class EducationListPage extends StatefulWidget {
  const EducationListPage({super.key});

  @override
  State<EducationListPage> createState() => _EducationListPageState();
}

class _EducationListPageState extends State<EducationListPage> {
  final EducationService _service = EducationService();
  late Future<List<Education>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchEducation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Education")),
      body: FutureBuilder<List<Education>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final list = snapshot.data!;

          if (list.isEmpty) {
            return const Center(child: Text("Belum ada data"));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final edu = list[index];

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior:
                    Clip.antiAlias, // penting supaya gambar ikut radius
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 GAMBAR FULL COVER
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.network(
                        edu.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image));
                        },
                      ),
                    ),

                    // 🔥 TEXT CONTENT
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            edu.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${edu.category} • ${edu.level ?? ''}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
