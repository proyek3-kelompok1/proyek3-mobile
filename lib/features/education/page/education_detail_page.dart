import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/education_model.dart';

// ──────────────────────────────────────────────────────────
//  COLOUR PALETTE  (purple + white dominant)
// ──────────────────────────────────────────────────────────
const _purple = Color(0xFF4A1059);
const _purpleDark = Color(0xFF4A1059);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey100 = Color(0xFFF5F5F5);
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class EducationDetailPage extends StatelessWidget {
  final Education education;

  const EducationDetailPage({
    super.key,
    required this.education,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: CustomScrollView(
        slivers: [
          // ── HERO IMAGE + APPBAR ──────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: _purple,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: _white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail image
                  Image.network(
                    education.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_purpleDark, _purple, _purpleLight],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.article_rounded,
                              color: _white, size: 60),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Play Button Overlay for Video
                  if (education.type == 'video' && education.videoUrl != null)
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(education.videoUrl!);
                          try {
                            // Coba buka di aplikasi luar (YouTube App)
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            // Fallback kalau gagal, buka di browser biasa
                            await launchUrl(url);
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  // Title and meta on image
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Row(
                          children: [
                            _Badge(
                              text: education.category,
                              color: _purple,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              text: education.type,
                              color: _purpleLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Title
                        Text(
                          education.title,
                          style: GoogleFonts.poppins(
                            color: _white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CONTENT ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Meta info bar ──────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: _purpleBg,
                    border: Border(
                      bottom: BorderSide(
                        color: _purpleAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // View count
                      _MetaChip(
                        icon: Icons.visibility_rounded,
                        text: "${education.view} kali dibaca",
                      ),
                      const SizedBox(width: 16),
                      // Reading time
                      if (education.readingTime != null)
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          text: education.readingTime!,
                        ),
                      const Spacer(),
                      // Level
                      if (education.level != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _purpleAccent.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.signal_cellular_alt_rounded,
                                  color: _purple, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                education.level!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Description ────────────────────────────
                if (education.description != null &&
                    education.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _purpleBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _purpleAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline_rounded,
                                color: _purple, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              education.description!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _grey600,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Video Button ────────────────────────────
                if (education.type == 'video' && education.videoUrl != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(education.videoUrl!);
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                      label: Text(
                        "Tonton Video di YouTube",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                // ── Main content ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _purple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Konten Artikel",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _purpleDark,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _purple.withOpacity(0.3),
                          _purpleAccent.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Text(
                    education.content,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFF333333),
                      height: 1.8,
                    ),
                  ),
                ),

                // ── Date footer ────────────────────────────
                if (education.formattedDate != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _grey100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: _grey600, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Dipublikasikan: ${education.formattedDate}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  BADGE WIDGET
// ================================================================
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: _white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ================================================================
//  META CHIP WIDGET
// ================================================================
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _purple, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _purpleDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}