import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../models/education_model.dart';
import '../../../core/providers/settings_provider.dart';
import '../services/education_services.dart';

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

class EducationDetailPage extends StatefulWidget {
  final Education education;

  const EducationDetailPage({
    super.key,
    required this.education,
  });

  @override
  State<EducationDetailPage> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState extends State<EducationDetailPage> {
  final EducationService _service = EducationService();

  @override
  void initState() {
    super.initState();
    // Memanggil API untuk menambah jumlah pembaca (view count)
    _service.incrementView(widget.education.id);
  }

  @override
  Widget build(BuildContext context) {
    final education = widget.education;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13131C) : _white,
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
                          color: _purple,
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
                        color: Colors.black.withOpacity(0.25),
                      ),
                  ),
                  // Play Button Overlay for Video
                  if (education.type == 'video' && education.videoUrl != null)
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(education.videoUrl!);
                          try {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } catch (e) {
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
                        Row(
                          children: [
                            _Badge(
                              text: settingsProvider.translate(education.category.toLowerCase().contains('tips') ? 'tips' : education.category.toLowerCase().contains('berita') ? 'news' : 'article'),
                              color: _purple,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              text: settingsProvider.translate(education.type.toLowerCase() == 'video' ? 'video' : 'article'),
                              color: _purpleLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                    color: isDark ? const Color(0xFF1E1E2C) : _purpleBg,
                    border: Border(
                      bottom: BorderSide(
                        color: _purpleAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _MetaChip(
                        icon: Icons.visibility_rounded,
                        text: settingsProvider.translate('times_read').replaceAll('{count}', education.view.toString()),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      if (education.readingTime != null)
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          text: education.readingTime!.replaceAll('menit', settingsProvider.translate('minutes_read')).replaceAll('min read', settingsProvider.translate('minutes_read')),
                          isDark: isDark,
                        ),
                      const Spacer(),
                      if (education.level != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? _purple.withOpacity(0.2) : _purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white12 : _purpleAccent.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.signal_cellular_alt_rounded,
                                  color: _purple, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                settingsProvider.translate(education.level!.toLowerCase().contains('pemula') ? 'beginner' : education.level!.toLowerCase().contains('menengah') ? 'intermediate' : 'advanced'),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : _purple,
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
                        color: isDark ? const Color(0xFF1E1E2C) : _purpleBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white12 : _purpleAccent.withOpacity(0.3),
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
                                color: isDark ? Colors.white70 : _grey600,
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
                        settingsProvider.translate('watch_on_youtube'),
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
                        settingsProvider.translate('article_content'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : _purpleDark,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    height: 1,
                    color: _purple.withOpacity(0.2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Text(
                    education.content,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.8,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: 0.2,
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
                        color: isDark ? const Color(0xFF1E1E2C) : _grey100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: _grey600, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            settingsProvider.translate('published_at').replaceAll('{date}', education.formattedDate!),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : _grey600,
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
  final bool isDark;

  const _MetaChip({required this.icon, required this.text, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isDark ? _purpleAccent : _purple, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.white70 : _purpleDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}