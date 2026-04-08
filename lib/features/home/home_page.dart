import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dvpets/features/education/page/education_list_page.dart';
import 'package:dvpets/features/education/page/education_detail_page.dart';
import 'package:dvpets/features/education/services/education_services.dart';
import 'package:dvpets/models/education_model.dart';
import 'package:dvpets/core/constants/api_constants.dart';
import 'package:dvpets/features/home/page/booking_page.dart';
import 'package:dvpets/features/consultation/doctor_list_page.dart';
import 'package:dvpets/core/services/booking_history_api.dart';
import 'package:dvpets/models/booking_model.dart';
import 'package:dvpets/features/booking/queue_list_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              HomeHeader(),
              DiscountBanner(),
              Categories(),
              SpecialOffers(),
              SizedBox(height: 20),
              BookingHistory(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: SearchField()),
          const SizedBox(width: 16),
          IconBtnWithCounter(
            // numOfitem: 3,
            svgSrc: aiIcon,
            press: () {},
          ),
          const SizedBox(width: 8),
          IconBtnWithCounter(svgSrc: bellIcon, numOfitem: 3, press: () {}),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      child: TextFormField(
        onChanged: (value) {},
        decoration: InputDecoration(
          filled: true,
          hintStyle: const TextStyle(color: Color(0xFF757575)),
          fillColor: const Color(0xFF979797).withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          hintText: "Search",
          prefixIcon: const Icon(Icons.search),
        ),
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
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF979797).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.string(svgSrc),
          ),
          if (numOfitem != 0)
            Positioned(
              top: -3,
              right: 0,
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4848),
                  shape: BoxShape.circle,
                  border: Border.all(width: 1.5, color: Colors.white),
                ),
                child: Center(
                  child: Text(
                    "$numOfitem",
                    style: const TextStyle(
                      fontSize: 12,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF4A1059),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC05DE3).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DVPets",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Konsultasi hewan\npeliharaan Anda dengan\ncepat dan mudah.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: -15,
            child: Image.asset(
              "assets/images/kucing.png",
              height: 160,
            ),
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
    List<Map<String, dynamic>> categories = [
      {"icon": bookingIcon, "text": "Booking", "page": const BookingPage()},
      {
        "icon": consultationIcon,
        "text": "Consultation",
        "page": const DoctorListPage(),
      },
      {
        "icon": vaccineIcon,
        "text": "Vaccine",
        // "page": const VaccinePage(),
      },
      {
        "icon": groomingIcon,
        "text": "Grooming",
        // "page": const GroomingPage(),
      },
      {
        "icon": petShopIcon,
        "text": "Pet Shop",
        // "page": const PetShopPage(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          categories.length,
          (index) => CategoryCard(
            icon: categories[index]["icon"],
            text: categories[index]["text"],
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => categories[index]["page"],
                ),
              );
            },
          ),
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
  }) : super(key: key);

  final String icon, text;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECDF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.string(icon),
          ),
          const SizedBox(height: 4),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class SpecialOffers extends StatefulWidget {
  const SpecialOffers({super.key});

  @override
  State<SpecialOffers> createState() => _SpecialOffersState();
}

class _SpecialOffersState extends State<SpecialOffers> {
  final EducationService _service = EducationService();
  late Future<List<Education>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchEducation();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Education>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final list = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(
                title: "Education",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EducationListPage(),
                    ),
                  );
                },
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(list.length, (index) {
                    final edu = list[index];

                    return SpecialOfferCard(
                      image: edu.thumbnailUrl,
                      category: edu.title,
                      viewCount: edu.view,
                      press: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EducationDetailPage(education: edu),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ],
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
    required this.viewCount,
    required this.press,
  }) : super(key: key);

  final String category, image;
  final int viewCount;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: GestureDetector(
        onTap: press,
        child: SizedBox(
          width: 242,
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF3EEFF),
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Color(0xFF4A3298), size: 40),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.black38,
                        Colors.black26,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "$viewCount kali dilihat",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({Key? key, required this.title, required this.press})
    : super(key: key);

  final String title;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: press,
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text("See more"),
        ),
      ],
    );
  }
}

const _purpleHome = Color(0xFF4A3298);
const _purpleDarkHome = Color(0xFF2E1D6B);
const _purpleLightHome = Color(0xFF7C5CBF);
const _purpleBgHome = Color(0xFFF3EEFF);
const _grey600Home = Color(0xFF757575);
const _grey300Home = Color(0xFFE0E0E0);

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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  int _daysUntil(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return date.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookingModel>>(
      future: _future,
      builder: (context, snapshot) {
        // Don't show section at all if loading or error or empty
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Riwayat Booking",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(_purpleHome),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SectionTitle(
                  title: "Riwayat Booking",
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QueueListPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _purpleBgHome,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _purpleLightHome.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_note_rounded, color: _grey300Home, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        "Belum ada booking aktif",
                        style: GoogleFonts.poppins(fontSize: 13, color: _grey600Home, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Booking sekarang untuk hewan peliharaan Anda",
                        style: GoogleFonts.poppins(fontSize: 11, color: _grey600Home),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(
                title: "Riwayat Booking",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QueueListPage()),
                  );
                },
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(bookings.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: _BookingCard(
                        booking: bookings[index],
                        daysUntil: _daysUntil(bookings[index].bookingDate),
                        formatDate: _formatDate,
                        formatNumber: _formatNumber,
                      ),
                    );
                  }),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final int daysUntil;
  final String Function(String) formatDate;
  final String Function(int) formatNumber;

  const _BookingCard({
    required this.booking,
    required this.daysUntil,
    required this.formatDate,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = daysUntil == 0;
    final isTomorrow = daysUntil == 1;

    String urgencyText;
    Color urgencyColor;
    if (isToday) {
      urgencyText = 'HARI INI';
      urgencyColor = const Color(0xFFF44336);
    } else if (isTomorrow) {
      urgencyText = 'BESOK';
      urgencyColor = const Color(0xFFFF9800);
    } else {
      urgencyText = '$daysUntil HARI LAGI';
      urgencyColor = _purpleHome;
    }

    // Status badge
    String statusText;
    Color statusColor;
    switch (booking.status) {
      case 'confirmed':
        statusText = 'Dikonfirmasi';
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'completed':
        statusText = 'Selesai';
        statusColor = _grey600Home;
        break;
      case 'cancelled':
        statusText = 'Dibatalkan';
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusText = 'Menunggu';
        statusColor = const Color(0xFFFF9800);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QueueListPage(initialBookingCode: booking.bookingCode),
          ),
        );
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isToday
                ? const Color(0xFFF44336).withOpacity(0.3)
                : _purpleLightHome.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: (isToday ? const Color(0xFFF44336) : _purpleHome)
                  .withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Queue number + urgency badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'A${booking.nomorAntrian.toString().padLeft(3, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    urgencyText,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: urgencyColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service name
            Text(
              booking.serviceName,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _purpleDarkHome,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Doctor
            Row(
              children: [
                const Icon(Icons.person_rounded, color: _purpleLightHome, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.doctorName,
                    style: GoogleFonts.poppins(fontSize: 11, color: _grey600Home),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date + Time row
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: _purpleLightHome, size: 12),
                const SizedBox(width: 4),
                Text(
                  formatDate(booking.bookingDate),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _purpleDarkHome,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_rounded, color: _purpleLightHome, size: 12),
                const SizedBox(width: 4),
                Text(
                  booking.bookingTime,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _purpleDarkHome,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom row: status + price
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Rp ${formatNumber(booking.totalPrice)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _purpleHome,
                  ),
                ),
              ],
            ),

            // Pet info
            if (booking.namaHewan != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pets_rounded, color: _purpleLightHome, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.namaHewan} (${booking.jenisHewan ?? ""})',
                    style: GoogleFonts.poppins(fontSize: 10, color: _grey600Home),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// const billIcon =
//     '''<svg width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg">
// <path fill-rule="evenodd" clip-rule="evenodd" d="M16.2149 12.2832C16.2149 12.6547 15.9099 12.9547 15.5347 12.9547H6.46532C6.08894 12.9547 5.78625 12.6547 5.78625 12.2832C5.78625 11.9116 6.08894 11.6116 6.46532 11.6116H15.5347C15.9099 11.6116 16.2149 11.9116 16.2149 12.2832ZM16.2149 7.24678C16.2149 7.61835 15.9099 7.9183 15.5347 7.9183H6.46532C6.08894 7.9183 5.78625 7.61835 5.78625 7.24678C5.78625 6.87521 6.08894 6.57527 6.46532 6.57527H15.5347C15.9099 6.57527 16.2149 6.87521 16.2149 7.24678ZM20.6396 17.7806L17.8757 20.3973L14.901 17.5825C14.6368 17.3341 14.2219 17.333 13.9589 17.5837L10.9921 20.3973L8.02412 17.5837C7.7611 17.333 7.34505 17.333 7.0809 17.5837L4.11409 20.3973L1.3604 17.7818V4.0291C1.3604 2.54841 2.5825 1.34303 4.08121 1.34303H17.9188C19.4186 1.34303 20.6396 2.54841 20.6396 4.0291V17.7806ZM17.9188 0H4.08121C1.83088 0 0 1.8075 0 4.0291V17.9978C0 18.0112 0.00680202 18.0235 0.00793569 18.0369C-0.00113367 18.2238 0.0623519 18.4119 0.208595 18.5518L3.64248 21.812C3.90663 22.0616 4.32268 22.0627 4.5857 21.812L7.55251 18.9983L10.5205 21.812C10.7835 22.0627 11.1984 22.0627 11.4625 21.812L14.4305 18.9983L17.4052 21.8131C17.5367 21.9373 17.7057 22 17.8757 22C18.0446 22 18.2147 21.9373 18.3462 21.8131L21.7903 18.5529C21.9376 18.413 22.0011 18.2238 21.9921 18.0369C21.9932 18.0224 22 18.0112 22 17.9978V4.0291C22 1.8075 20.1691 0 17.9188 0Z" fill="#FF7643"/>
// </svg>
// ''';

// const flashIcon =
//     '''<svg width="19" height="22" viewBox="0 0 19 22" fill="none" xmlns="http://www.w3.org/2000/svg">
// <path fill-rule="evenodd" clip-rule="evenodd" d="M8.77515 20.8036V13.4372C8.77515 12.8219 8.26702 12.3207 7.64317 12.3207L1.25313 12.4037L10.2248 1.19586V8.56224C10.2248 9.17757 10.733 9.67877 11.3568 9.67877L17.7469 9.59575L8.77515 20.8036ZM18.8789 9.11013C18.6758 8.69299 18.2571 8.43357 17.7879 8.43357H11.4873V1.19586C11.4873 0.681174 11.1696 0.239128 10.6772 0.0689514C10.1859 -0.101226 9.65675 0.0502734 9.33062 0.449774L0.266324 11.6265C-0.0271929 11.9876 -0.0818985 12.4722 0.121144 12.8893C0.324186 13.3064 0.742894 13.5659 1.2121 13.5659H7.51271V20.8036C7.51271 21.3183 7.83043 21.7603 8.32278 21.9305C8.45744 21.9772 8.59525 22 8.73097 22C9.08866 22 9.43267 21.8412 9.66938 21.5497L18.7337 10.374C19.0272 10.0119 19.0819 9.52831 18.8789 9.11013Z" fill="#FF7643"/>
// </svg>
// ''';

// const gameIcon =
//     '''<svg width="25" height="18" viewBox="0 0 25 18" fill="none" xmlns="http://www.w3.org/2000/svg">
// <path fill-rule="evenodd" clip-rule="evenodd" d="M20.8058 11.3855C20.8058 12.5827 19.8412 13.5542 18.6504 13.5542C17.4607 13.5542 16.4951 12.5827 16.4951 11.3855C16.4951 10.1884 17.4607 9.21687 18.6504 9.21687C19.8412 9.21687 20.8058 10.1884 20.8058 11.3855ZM8.59145 11.3855C8.59145 11.7455 8.30156 12.0361 7.94485 12.0361H6.8133V13.1747C6.8133 13.5336 6.52448 13.8253 6.1667 13.8253C5.80891 13.8253 5.5201 13.5336 5.5201 13.1747V12.0361H4.38854C4.03076 12.0361 3.74194 11.7455 3.74194 11.3855C3.74194 11.0255 4.03076 10.7349 4.38854 10.7349H5.5201V9.59639C5.5201 9.23639 5.80891 8.94578 6.1667 8.94578C6.52448 8.94578 6.8133 9.23639 6.8133 9.59639V10.7349H7.94485C8.30156 10.7349 8.59145 11.0255 8.59145 11.3855ZM23.6066 12.4493C23.2111 14.5084 21.5655 16.1718 19.5104 16.5882C17.6536 16.9655 15.786 16.3551 14.5197 14.9563C14.1447 14.542 13.6511 14.3133 13.1306 14.3133H11.8697C11.3503 14.3133 10.8578 14.541 10.4838 14.9552C9.48161 16.0634 8.05585 16.6988 6.57406 16.6988C5.09011 16.6988 3.66435 16.0634 2.66535 14.9563C1.65126 13.834 1.17385 12.3788 1.31826 10.8586C1.57475 8.17482 3.99627 6.07229 6.83162 6.07229H18.4284C20.0094 6.07229 21.4944 6.77711 22.5031 8.00675C23.5107 9.2353 23.9127 10.8542 23.6066 12.4493ZM23.4999 7.1794C22.2455 5.64831 20.3973 4.77108 18.4284 4.77108H13.1478V0.650602C13.1478 0.290602 12.8579 0 12.5012 0C12.1435 0 11.8546 0.290602 11.8546 0.650602V4.77108H6.83162C3.33781 4.77108 0.350514 7.38976 0.0315236 10.7339C-0.148447 12.6239 0.446426 14.4347 1.7073 15.8313C2.95201 17.2095 4.72585 18 6.57406 18C8.41903 18 10.1929 17.2095 11.4408 15.8313C11.513 15.75 11.6671 15.6145 11.8697 15.6145H13.1306C13.3354 15.6145 13.4884 15.75 13.5627 15.8324C14.8322 17.2345 16.5835 18 18.4241 18C18.8681 18 19.3175 17.9555 19.7669 17.8645C22.3296 17.344 24.3825 15.2675 24.8761 12.6954C25.2555 10.7187 24.7543 8.70723 23.4999 7.1794Z" fill="#FF7643"/>
// </svg>
// ''';

// const giftIcon =
//     '''<svg width="19" height="22" viewBox="0 0 19 22" fill="none" xmlns="http://www.w3.org/2000/svg">
// <path fill-rule="evenodd" clip-rule="evenodd" d="M17.7359 13.1041H10.1321V7.58517L12.3791 9.79773C12.5023 9.92019 12.6635 9.98038 12.8257 9.98038C12.9869 9.98038 13.1491 9.92019 13.2724 9.79773C13.52 9.55592 13.52 9.16156 13.2724 8.91872L11.0338 6.71239H15.2076C16.6013 6.71239 17.7359 7.83009 17.7359 9.20308V13.1041ZM17.7359 18.2484C17.7359 19.6214 16.6013 20.7391 15.2076 20.7391H10.1321V14.3484H17.7359V18.2484ZM10.1321 3.35308C10.1321 2.18973 11.0918 1.2443 12.2716 1.2443C13.4504 1.2443 14.4101 2.18973 14.4101 3.35308C14.4101 4.51436 13.4504 5.45979 12.2716 5.45979H10.1321V3.35308ZM8.86793 5.45979H6.72943C5.54957 5.45979 4.58988 4.51436 4.58988 3.35308C4.58988 2.18973 5.54957 1.2443 6.72943 1.2443C7.90824 1.2443 8.86793 2.18973 8.86793 3.35308V5.45979ZM8.86793 13.1041H1.26414V9.20308C1.26414 7.83009 2.3987 6.71239 3.79242 6.71239H7.96723L5.7276 8.91872C5.48109 9.16156 5.48109 9.55592 5.7276 9.79773C5.97411 10.0416 6.37442 10.0416 6.62198 9.79773L8.86793 7.58517V13.1041ZM8.86793 20.7391H3.79242C2.3987 20.7391 1.26414 19.6214 1.26414 18.2484V14.3484H8.86793V20.7391ZM15.2076 5.46809H14.9095C15.3877 4.89004 15.6743 4.15425 15.6743 3.35308C15.6743 1.50375 14.1478 0 12.2716 0C11.1297 0 10.1184 0.556253 9.5 1.40827C8.88268 0.556253 7.87032 0 6.72943 0C4.85218 0 3.32574 1.50375 3.32574 3.35308C3.32574 4.15425 3.61228 4.89004 4.09054 5.46809H3.79242C1.70132 5.46809 0 7.14307 0 9.20308V18.2484C0 20.3084 1.70132 21.9844 3.79242 21.9844H9.35884C9.40414 21.9938 9.45154 22 9.5 22C9.54951 22 9.59586 21.9938 9.64116 21.9844H15.2076C17.2987 21.9844 19 20.3084 19 18.2484V9.20308C19 7.14307 17.2987 5.46809 15.2076 5.46809Z" fill="#FF7643"/>
// </svg>
// ''';

// const discoverIcon =
//     '''<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
// <path fill-rule="evenodd" clip-rule="evenodd" d="M15.481 15.1013C15.9771 14.8149 16.6122 14.9851 16.8986 15.4811C17.185 15.9772 17.0149 16.6123 16.5188 16.8987C16.0227 17.1851 15.3876 17.015 15.1012 16.5189C14.8148 16.0228 14.985 15.3877 15.481 15.1013ZM17.7272 18.9918L10.0163 19.4546L14.2726 13.0082L21.9835 12.5454L17.7272 18.9918ZM23.1527 11.2269L13.8876 11.783C13.6907 11.7948 13.5127 11.8976 13.4041 12.0622L8.28988 19.8079C8.16037 20.0049 8.15326 20.2583 8.27104 20.4623C8.38883 20.6663 8.61179 20.7868 8.84715 20.7731L18.1123 20.217C18.2104 20.2106 18.304 20.1818 18.3867 20.134C18.4694 20.0863 18.5412 20.0197 18.5958 19.9379L23.7099 12.1921C23.8395 11.9951 23.8466 11.7417 23.7288 11.5377C23.611 11.3337 23.388 11.2132 23.1527 11.2269ZM20.8773 24.4478C16.2184 27.1376 10.2414 25.5354 7.55208 20.8774C4.86279 16.2194 6.46366 10.242 11.1226 7.55217C15.7814 4.86236 21.7585 6.46465 24.4477 11.1226C27.137 15.7806 25.5362 21.758 20.8773 24.4478ZM10.4999 6.47372C5.24698 9.50651 3.44085 16.2471 6.47363 21.5C9.50642 26.7529 16.247 28.5591 21.4999 25.5263C26.7528 22.4935 28.559 15.7529 25.5262 10.5C22.4934 5.24707 15.7528 3.44094 10.4999 6.47372Z" fill="#FF7643"/>
// </svg>
// ''';

const aiIcon = '''
<svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="6" y="8" width="12" height="8" rx="2" stroke="#4A3298" stroke-width="2"/>
<circle cx="9" cy="12" r="1.5" fill="#4A3298"/>
<circle cx="15" cy="12" r="1.5" fill="#4A3298"/>
<path d="M12 4V6" stroke="#4A3298" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const bellIcon =
    '''<svg width="15" height="20" viewBox="0 0 15 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M13.9645 15.8912C13.9645 16.1628 13.7495 16.3832 13.4844 16.3832H9.22765H9.21987H1.51477C1.2505 16.3832 1.03633 16.1628 1.03633 15.8912V10.7327C1.03633 7.08053 3.93546 4.10885 7.50043 4.10885C11.0645 4.10885 13.9645 7.08053 13.9645 10.7327V15.8912ZM7.50043 18.9381C6.77414 18.9381 6.18343 18.3327 6.18343 17.5885C6.18343 17.5398 6.18602 17.492 6.19034 17.4442H8.81052C8.81484 17.492 8.81743 17.5398 8.81743 17.5885C8.81743 18.3327 8.22586 18.9381 7.50043 18.9381ZM9.12488 3.2292C9.35805 2.89469 9.49537 2.48673 9.49537 2.04425C9.49537 0.915044 8.6024 0 7.50043 0C6.39847 0 5.5055 0.915044 5.5055 2.04425C5.5055 2.48673 5.64281 2.89469 5.87512 3.2292C2.51828 3.99204 0 7.06549 0 10.7327V15.8912C0 16.7478 0.679659 17.4442 1.51477 17.4442H5.15142C5.14883 17.492 5.1471 17.5398 5.1471 17.5885C5.1471 18.9186 6.20243 20 7.50043 20C8.79843 20 9.8529 18.9186 9.8529 17.5885C9.8529 17.5398 9.85117 17.492 9.84858 17.4442H13.4844C14.3203 17.4442 15 16.7478 15 15.8912V10.7327C15 7.06549 12.4826 3.99204 9.12488 3.2292Z" fill="#626262"/>
</svg>
''';

const bookingIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7 2V5M17 2V5M3 9H21M5 5H19C20.1046 5 21 5.89543 21 7V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7C3 5.89543 3.89543 5 5 5Z"
stroke="#FF7643" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const consultationIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9 12H15M12 9V15M12 21C16.9706 21 21 16.9706 21 12C21 7.02944 16.9706 3 12 3C7.02944 3 3 7.02944 3 12C3 16.9706 7.02944 21 12 21Z"
stroke="#FF7643" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const vaccineIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4 20L20 4M14 6L18 10M6 14L10 18"
stroke="#FF7643" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const groomingIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="6" cy="6" r="3" stroke="#FF7643" stroke-width="2"/>
<circle cx="18" cy="6" r="3" stroke="#FF7643" stroke-width="2"/>
<path d="M8 8L16 16M16 8L8 16" stroke="#FF7643" stroke-width="2"/>
</svg>
''';

const petShopIcon = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="6" cy="10" r="2" fill="#FF7643"/>
<circle cx="12" cy="7" r="2" fill="#FF7643"/>
<circle cx="18" cy="10" r="2" fill="#FF7643"/>
<path d="M8 16C8 14 10 13 12 13C14 13 16 14 16 16C16 18 14 19 12 19C10 19 8 18 8 16Z" fill="#FF7643"/>
</svg>
''';
