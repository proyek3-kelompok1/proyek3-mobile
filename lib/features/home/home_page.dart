import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dvpets/features/education/page/education_list_page.dart';
import 'package:dvpets/features/education/page/education_detail_page.dart';
import 'package:dvpets/features/education/services/education_services.dart';
import 'package:dvpets/models/education_model.dart';
import 'package:dvpets/features/home/page/booking_page.dart';
import 'package:dvpets/features/consultation/doctor_list_page.dart';
import 'package:dvpets/core/services/booking_history_api.dart';
import 'package:dvpets/models/booking_model.dart';
import 'package:dvpets/models/consultation_model.dart';
import 'package:dvpets/core/services/consultation_api.dart';
import 'package:dvpets/features/booking/medical_record_page.dart';
import 'package:dvpets/features/booking/queue_list_page.dart';
import 'package:dvpets/features/booking/medical_record_list_page.dart';
import 'package:dvpets/core/services/notification_service.dart';
import 'package:dvpets/core/widgets/shimmer_loading.dart';
import 'package:dvpets/features/notification/notification_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../ai/ai_chat_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const HomeHeader(),
              const SizedBox(height: 20),
              const DiscountBanner(),
              const SizedBox(height: 20),
              const Categories(),
              const SizedBox(height: 25),
              const SpecialOffers(),
              const SizedBox(height: 25),
              const BookingHistory(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatefulWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        _userName = userData['name'] ?? "User";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settingsProvider.translate('halo').replaceAll('{name}', _userName),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  settingsProvider.translate('harimu_menyenangkan'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<List<AppNotification>>(
            valueListenable: NotificationService().notificationsNotifier,
            builder: (context, notifications, child) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              return IconBtnWithCounter(
                svgSrc: bellIcon,
                numOfitem: unreadCount,
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationListPage()),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class Categories extends StatelessWidget {
  const Categories({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final List<Map<String, dynamic>> categories = [
      {
        "icon": bookingIcon,
        "text": settingsProvider.translate('antrian'),
        "page": const BookingPage(),
      },
      {
        "icon": consultationIcon,
        "text": settingsProvider.translate('konsultasi'),
        "page": const DoctorListPage(),
        "isConsultation": true,
      },
      {
        "icon": rekamMedisIcon,
        "text": settingsProvider.translate('rekam_medis'),
        "page": const MedicalRecordListPage(),
      },
      {
        "icon": aiIcon,
        "text": settingsProvider.translate('dokter_paw'),
        "page": const AiChatPage(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          categories.length,
          (index) {
            final cat = categories[index];
            if (cat["isConsultation"] == true) {
              return FutureBuilder<List<ConsultationModel>>(
                future: ConsultationApi.fetchSessions(),
                builder: (context, snapshot) {
                  bool hasUnread = false;
                  if (snapshot.hasData) {
                    hasUnread = snapshot.data!.any((s) => s.unreadCount > 0);
                  }
                  return CategoryCard(
                    icon: cat["icon"],
                    text: cat["text"],
                    hasBadge: hasUnread,
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => cat["page"]),
                      ).then((_) => (context as Element).markNeedsBuild());
                    },
                  );
                },
              );
            }
            return CategoryCard(
              icon: cat["icon"],
              text: cat["text"],
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => cat["page"]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    Key? key,
    required this.icon,
    required this.text,
    required this.press,
    this.hasBadge = false,
  }) : super(key: key);

  final String icon, text;
  final GestureTapCallback press;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: press,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark 
                      ? theme.cardColor 
                      : const Color(0xFFFFECDF),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: SvgPicture.string(
                  icon,
                  colorFilter: theme.brightness == Brightness.dark 
                      ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) 
                      : null,
                ),
              ),
              if (hasBadge)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text, 
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class IconBtnWithCounter extends StatelessWidget {
  const IconBtnWithCounter({
    Key? key,
    required this.svgSrc,
    this.numOfitem = 0,
    required this.press,
  }) : super(key: key);

  final String svgSrc;
  final int numOfitem;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: press,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.1) 
                  : const Color(0xFF979797).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.string(
              svgSrc,
              colorFilter: Theme.of(context).brightness == Brightness.dark 
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) 
                  : null,
            ),
          ),
          if (numOfitem != 0)
            Positioned(
              top: -2,
              right: 0,
              child: Container(
                height: 18,
                width: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4848),
                  shape: BoxShape.circle,
                  border: Border.all(width: 1.5, color: Colors.white),
                ),
                child: Center(
                  child: Text(
                    "$numOfitem",
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DiscountBanner extends StatelessWidget {
  const DiscountBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
              color: const Color(0xFF4A1059),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A1059).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DVPets AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  settingsProvider.translate('konsultasi_cepat'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -5,
            bottom: -10,
            child: Image.asset(
              "assets/images/kucing.png",
              height: 130,
            ),
          ),
        ],
      ),
    );
  }
}

class SpecialOffers extends StatelessWidget {
  const SpecialOffers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title: settingsProvider.translate('edukasi'),
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EducationListPage()),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        const EducationListHome(),
      ],
    );
  }
}

class EducationListHome extends StatefulWidget {
  const EducationListHome({super.key});

  @override
  State<EducationListHome> createState() => _EducationListHomeState();
}

class _EducationListHomeState extends State<EducationListHome> {
  late Future<List<Education>> _future;

  @override
  void initState() {
    super.initState();
    _future = EducationService().fetchEducation();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Education>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 20),
                SizedBox(width: 280, child: ShimmerCard(height: 160)),
                SizedBox(width: 15),
                SizedBox(width: 280, child: ShimmerCard(height: 160)),
              ],
            ),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();

        // Urutkan ID terbesar (terbaru) di paling kiri
        list.sort((a, b) => b.id.compareTo(a.id));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(
                list.length > 5 ? 5 : list.length,
                (index) => SpecialOfferCard(
                  image: list[index].thumbnailUrl,
                  category: list[index].title,
                  numOfBrands: list[index].view,
                  isVideo: list[index].videoUrl != null && list[index].videoUrl!.isNotEmpty,
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EducationDetailPage(education: list[index]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        );
      },
    );
  }
}

class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({
    Key? key,
    required this.category,
    required this.image,
    required this.numOfBrands,
    required this.isVideo,
    required this.press,
  }) : super(key: key);

  final String category, image;
  final int numOfBrands;
  final bool isVideo;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: GestureDetector(
        onTap: press,
        child: SizedBox(
          width: 280,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.network(image, width: 280, height: 160, fit: BoxFit.cover),
                // Lapisan Gelap Merata di seluruh card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                // Judul & View di Pojok Kiri Atas
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            "$numOfBrands views",
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Logo Play Hitam di Tengah (Cuma kalau Video)
                if (isVideo)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 34),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    Key? key,
    required this.title,
    required this.press,
  }) : super(key: key);

  final String title;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        GestureDetector(
          onTap: press,
          child: Text(
            Provider.of<SettingsProvider>(context).translate('lihat_semua'),
            style: const TextStyle(color: Color(0xFFBBBBBB), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class BookingHistory extends StatefulWidget {
  const BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  late Future<List<BookingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = BookingHistoryApi.fetchActiveBookings();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return FutureBuilder<List<BookingModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(width: double.infinity, child: ShimmerCard(height: 120)),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();

        final latest = list.first;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                title: settingsProvider.translate('riwayat_booking'),
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QueueListPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QueueListPage()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A1059).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4A1059)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latest.serviceName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              latest.bookingCode,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (latest.status?.toLowerCase() == 'selesai' || latest.status?.toLowerCase() == 'complete' || latest.status?.toLowerCase() == 'finished')
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (latest.status?.toLowerCase() == 'selesai' || latest.status?.toLowerCase() == 'finished' || latest.status?.toLowerCase() == 'complete') 
                              ? 'COMPLETE' 
                              : (latest.status?.toUpperCase() ?? 'PENDING'),
                          style: TextStyle(
                            color: (latest.status?.toLowerCase() == 'selesai' || latest.status?.toLowerCase() == 'complete' || latest.status?.toLowerCase() == 'finished')
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const aiIcon = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 5.5C13.1046 5.5 14 4.60457 14 3.5C14 2.39543 13.1046 1.5 12 1.5C10.8954 1.5 10 2.39543 10 3.5C10 4.60457 10.8954 5.5 12 5.5Z" fill="#FF7643"/>
<path d="M6 9.5C7.10457 9.5 8 8.60457 8 7.5C8 6.39543 7.10457 5.5 6 5.5C4.89543 5.5 4 6.39543 4 7.5C4 8.60457 4.89543 9.5 6 9.5Z" fill="#FF7643"/>
<path d="M18 9.5C19.1046 9.5 20 8.60457 20 7.5C20 6.39543 19.1046 5.5 18 5.5C16.8954 5.5 16 6.39543 16 7.5C16 8.60457 16.8954 9.5 18 9.5Z" fill="#FF7643"/>
<path d="M12 10.5C9.23858 10.5 7 12.7386 7 15.5C7 18.2614 9.23858 20.5 12 20.5C14.7614 20.5 17 18.2614 17 15.5C17 12.7386 14.7614 10.5 12 10.5Z" fill="#FF7643"/>
</svg>
''';

const bellIcon =
    '''<svg width="15" height="20" viewBox="0 0 15 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M13.9645 15.8912C13.9645 16.1628 13.7495 16.3832 13.4844 16.3832H9.22765H9.21987H1.51477C1.2505 16.3832 1.03633 16.1628 1.03633 15.8912V10.7327C1.03633 7.08053 3.93546 4.10885 7.50043 4.10885C11.0645 4.10885 13.9645 7.08053 13.9645 10.7327V15.8912ZM7.50043 18.9381C6.77414 18.9381 6.18343 18.3327 6.18343 17.5885C6.18343 17.5398 6.18602 17.492 6.19034 17.4442H8.81052C8.81484 17.492 8.81743 17.5398 8.81743 17.5885C8.81743 18.3327 8.22586 18.9381 7.50043 18.9381ZM9.12488 3.2292C9.35805 2.89469 9.49537 2.48673 9.49537 2.04425C9.49537 0.915044 8.6024 0 7.50043 0C6.39847 0 5.5055 0.915044 5.5055 2.04425C5.5055 2.48673 5.64281 2.89469 5.87512 3.2292C2.51828 3.99204 0 7.06549 0 10.7327V15.8912C0 16.7478 0.679659 17.4442 1.51477 17.4442H5.15142C5.14883 17.492 5.1471 17.5398 5.1471 17.5885C5.1471 18.9186 6.20243 20 7.50043 20C8.79843 20 9.8529 18.9186 9.8529 17.5885C9.8529 17.5398 9.85117 17.492 9.84858 17.4442H13.4844C14.3203 17.4442 15 16.7478 15 15.8912V10.7327C15 7.06549 12.4826 3.99204 9.12488 3.2292Z" fill="#626262"/>
</svg>''';

const bookingIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7 2V5M17 2V5M3 9H21M5 5H19C20.1046 5 21 5.89543 21 7V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7C3 5.89543 3.89543 5 5 5Z"
stroke="#FF7643" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const consultationIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="7" r="4" stroke="#FF7643" stroke-width="2"/>
<path d="M5 21C5 17.134 8.13401 14 12 14C15.866 14 19 17.134 19 21" stroke="#FF7643" stroke-width="2" stroke-linecap="round"/>
<path d="M11 17H13M12 16V18" stroke="#FF7643" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const rekamMedisIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9 5H7C5.89543 5 5 5.89543 5 7V19C5 20.1046 5.89543 21 7 21H17C18.1046 21 19 20.1046 19 19V7C19 5.89543 18.1046 5 17 5H15M9 5C9 6.10457 9.89543 7 11 7H13C14.1046 7 15 6.10457 15 5M9 5C9 3.89543 9.89543 3 11 3H13C14.1046 3 15 3.89543 15 5"
stroke="#FF7643" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M9 12H15M9 16H12" stroke="#FF7643" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';