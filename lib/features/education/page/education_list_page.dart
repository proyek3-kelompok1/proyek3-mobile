import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/education_services.dart';
import '../../../models/education_model.dart';
import 'education_detail_page.dart';
import '../../../core/widgets/shimmer_loading.dart';

// ──────────────────────────────────────────────────────────
//  COLOUR PALETTE
// ──────────────────────────────────────────────────────────
const _purple = Color(0xFF4A3298);
const _purpleDark = Color(0xFF2E1D6B);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class EducationListPage extends StatefulWidget {
  const EducationListPage({super.key});

  @override
  State<EducationListPage> createState() => _EducationListPageState();
}

class _EducationListPageState extends State<EducationListPage> {
  final EducationService _service = EducationService();
  late Future<List<Education>> _future;
  List<Education> _allEducation = [];
  List<Education> _filteredEducation = [];
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _future = _service.fetchEducation();
    });
    _future.then((list) {
      setState(() {
        _allEducation = list;
        _filteredEducation = list;
      });
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEducation = _allEducation;
      } else {
        _filteredEducation = _allEducation
            .where((edu) =>
                edu.title.toLowerCase().contains(query.toLowerCase()) ||
                (edu.description?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purpleBg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────
          _buildHeader(context),
          // ── CONTENT ─────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Education>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerList(itemCount: 6);
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: _purpleAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            "Gagal memuat data",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _purpleDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final list = _filteredEducation;
                
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final edu = list[index];
                    return _EducationCard(
                      education: edu,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EducationDetailPage(education: edu),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purpleDark, _purple, _purpleLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: _white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edukasi",
                      style: GoogleFonts.poppins(
                        color: _white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Pelajari lebih lanjut tentang hewan peliharaan",
                      style: GoogleFonts.poppins(
                        color: _white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Cari tutorial atau video...",
                hintStyle: GoogleFonts.poppins(color: _grey600, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _purple),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  EDUCATION CARD
// ================================================================
class _EducationCard extends StatelessWidget {
  final Education education;
  final VoidCallback onTap;

  const _EducationCard({required this.education, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ─────────────────────────────────
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        education.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: _purpleBg,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: _purpleAccent, size: 40),
                            ),
                          );
                        },
                      ),
                      // Play icon overlay for video
                      if (education.type == 'video')
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      // Gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badges on image
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            _SmallBadge(
                              text: education.category,
                              color: _purple,
                            ),
                            const SizedBox(width: 6),
                            _SmallBadge(
                              text: education.type,
                              color: _purpleLight,
                            ),
                          ],
                        ),
                      ),
                      // View count on image
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility_rounded,
                                  color: _white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                "${education.view}",
                                style: GoogleFonts.poppins(
                                  color: _white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      education.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _purpleDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (education.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        education.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _grey600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (education.level != null) ...[
                          Icon(Icons.signal_cellular_alt_rounded,
                              color: _purpleLight, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            education.level!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _grey600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (education.readingTime != null) ...[
                          Icon(Icons.schedule_rounded,
                              color: _purpleLight, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            education.readingTime!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _grey600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _purpleBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Baca",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: _purple, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
//  SMALL BADGE
// ================================================================
class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: _white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}