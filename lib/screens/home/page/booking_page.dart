// ============================================================
//  booking_page.dart
//  Halaman Booking Antrian Klinik Hewan
// ============================================================
//
//  PANDUAN MEMBUAT DATA DINAMIS (dari API / database):
//
//  1. MODEL DOKTER  →  class Doctor (lihat bagian "MODELS")
//     Ganti list `_doctors` di _BookingPageState dengan data
//     dari API. Contoh:
//       Future<List<Doctor>> fetchDoctors() async { ... }
//     Lalu tampilkan dengan FutureBuilder.
//
//  2. FOTO DOKTER  →  NetworkImage('https://...')
//     Saat ini foto dokter menggunakan CircleAvatar dengan
//     inisial sebagai fallback.
//     Untuk foto dari server, ubah di _buildDoctorSelector():
//       backgroundImage: NetworkImage(doc.photoUrl),
//     Pastikan model Doctor.photoUrl sudah diisi URL dari API.
//     Untuk aset lokal: AssetImage(doc.photoUrl)
//
//  3. SLOT WAKTU  →  List<TimeSlot> _timeSlots
//     Ganti inisialisasi manual di initState() dengan:
//       fetchTimeSlots(doctorId: _doctors[i].id, date: ...)
//     Dipanggil ulang setiap kali dokter atau tanggal berubah.
//
//  4. TANGGAL  →  List<Map<String, String>> _dates
//     Bisa digenerate otomatis dari DateTime.now():
//       for (int i = 0; i < 5; i++) {
//         final d = DateTime.now().add(Duration(days: i));
//         _dates.add({'day': ..., 'date': ..., 'month': ...});
//       }
//
//  5. JENIS HEWAN  →  List<Map<String, String>> _petTypes
//     Bisa diambil dari API master data.
//
//  6. SUBMIT BOOKING  →  void _onBook()
//     Kirim data ke API di sini (lihat komentar di _onBook).
//     Nomor antrian dikembalikan dari response API.
//
// ============================================================

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  COLOR PALETTE
//  Ubah nilai di sini untuk mengganti tema warna seluruh halaman
// ─────────────────────────────────────────────────────────────
const Color _primary = Color(0xFF4A3298); // ungu utama
const Color _primaryDark = Color(0xFF3A2578); // hover / pressed state
const Color _primaryLight = Color(0xFFECE9F7); // background chip & badge
const Color _bg = Color(0xFFF6F5FB); // background halaman
const Color _surface = Colors.white;
const Color _textDark = Color(0xFF1A1340);
const Color _textMid = Color(0xFF6B6880);
const Color _textLight = Color(0xFFB2AECE);

// ─────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────

/// [DINAMIS] Data dokter — isi dari API / Firestore.
/// photoUrl bisa berupa URL dari server atau path aset lokal.
class Doctor {
  final String id; // ID unik (untuk request API)
  final String name;
  final String specialty;
  final String photoUrl; // [DINAMIS] URL foto dari server / aset lokal
  final double rating;
  final int queue; // [DINAMIS] jumlah antrian saat ini dari API

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.photoUrl,
    required this.rating,
    required this.queue,
  });
}

class TimeSlot {
  final String time;
  final bool isAvailable; // [DINAMIS] status dari API jadwal dokter
  bool isSelected;

  TimeSlot({
    required this.time,
    this.isAvailable = true,
    this.isSelected = false,
  });
}

// ─────────────────────────────────────────────────────────────
//  BOOKING PAGE
// ─────────────────────────────────────────────────────────────

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with TickerProviderStateMixin {
  // ── [DINAMIS] Ganti dengan fetch dari API dokter ──────────
  final List<Doctor> _doctors = const [
    Doctor(
      id: 'doc_001',
      name: 'Dr. Anisa Putri',
      specialty: 'Umum & Vaksinasi',
      // [DINAMIS] Ganti ke URL dari API:
      // photoUrl: 'https://yourapi.com/doctors/anisa.jpg',
      // Atau aset lokal: 'assets/images/doctor_anisa.jpg'
      photoUrl: 'assets/images/doctor_anisa.jpg',
      rating: 4.9,
      queue: 3,
    ),
    Doctor(
      id: 'doc_002',
      name: 'Dr. Budi Santoso',
      specialty: 'Bedah & Ortopedi',
      photoUrl: 'assets/images/doctor_budi.jpg',
      rating: 4.8,
      queue: 6,
    ),
    Doctor(
      id: 'doc_003',
      name: 'Dr. Clara Wijaya',
      specialty: 'Dermatologi Hewan',
      photoUrl: 'assets/images/doctor_clara.jpg',
      rating: 4.7,
      queue: 2,
    ),
  ];

  // ── [DINAMIS] Ganti dengan data dari API master hewan ─────
  final List<Map<String, String>> _petTypes = [
    {'emoji': '🐕', 'label': 'Anjing'},
    {'emoji': '🐈', 'label': 'Kucing'},
    {'emoji': '🐹', 'label': 'Hamster'},
    {'emoji': '🐇', 'label': 'Kelinci'},
    {'emoji': '🦜', 'label': 'Burung'},
  ];

  // ── [DINAMIS] Generate dari DateTime.now() atau API ───────
  final List<Map<String, String>> _dates = [
    {'day': 'Sen', 'date': '17', 'month': 'Feb'},
    {'day': 'Sel', 'date': '18', 'month': 'Feb'},
    {'day': 'Rab', 'date': '19', 'month': 'Feb'},
    {'day': 'Kam', 'date': '20', 'month': 'Feb'},
    {'day': 'Jum', 'date': '21', 'month': 'Feb'},
  ];

  // ── State ─────────────────────────────────────────────────
  int _selectedDoctorIndex = 0;
  int _selectedDateIndex = 0;
  int _selectedPetType = 0;
  String _selectedTimeSlot = '';
  String _petName = '';

  final _petNameController = TextEditingController();
  final _notesController = TextEditingController();

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── [DINAMIS] Ganti dengan fetch dari API ─────────────────
  // Panggil ulang fetchTimeSlots() setiap kali
  // _selectedDoctorIndex atau _selectedDateIndex berubah.
  late List<TimeSlot> _timeSlots;

  @override
  void initState() {
    super.initState();

    // TODO: Ganti blok ini dengan panggilan API:
    // _loadTimeSlots();
    _timeSlots = [
      TimeSlot(time: '08:00'),
      TimeSlot(time: '08:30'),
      TimeSlot(time: '09:00', isAvailable: false),
      TimeSlot(time: '09:30'),
      TimeSlot(time: '10:00'),
      TimeSlot(time: '10:30', isAvailable: false),
      TimeSlot(time: '11:00'),
      TimeSlot(time: '11:30'),
      TimeSlot(time: '13:00'),
      TimeSlot(time: '13:30', isAvailable: false),
      TimeSlot(time: '14:00'),
      TimeSlot(time: '14:30'),
    ];

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _petNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _sectionLabel('Pilih Dokter'),
                    const SizedBox(height: 12),
                    _buildDoctorSelector(),
                    const SizedBox(height: 28),
                    _sectionLabel('Jenis Hewan Peliharaan'),
                    const SizedBox(height: 12),
                    _buildPetTypeSelector(),
                    const SizedBox(height: 28),
                    _sectionLabel('Nama Hewan'),
                    const SizedBox(height: 12),
                    _buildPetNameField(),
                    const SizedBox(height: 28),
                    _sectionLabel('Pilih Tanggal'),
                    const SizedBox(height: 12),
                    _buildDateSelector(),
                    const SizedBox(height: 28),
                    _sectionLabel('Pilih Jam'),
                    const SizedBox(height: 12),
                    _buildTimeGrid(),
                    const SizedBox(height: 28),
                    _sectionLabel('Catatan (Opsional)'),
                    const SizedBox(height: 12),
                    _buildNotesField(),
                    const SizedBox(height: 28),
                    _buildQueueInfoCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SLIVER APP BAR
  // ─────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: _primary,
      elevation: 0,

      // ── Tombol Kembali ─────────────────────────────────────
      // Jika BookingPage dibuka via Navigator.push() → pop kembali.
      // Jika dibuka dari BottomNavigationBar (tidak ada history),
      // Navigator.canPop() akan false sehingga tidak crash.
      automaticallyImplyLeading: false,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null, // tidak tampilkan tombol back jika dari BottomNav

      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            // TODO: Navigasi ke halaman notifikasi
            // Navigator.pushNamed(context, '/notifications');
          },
        ),
        const SizedBox(width: 8),
      ],

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A3298), Color(0xFF5C3FBB)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -15,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.055),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 55,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              // Title content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Booking Antrian',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.white.withOpacity(0.65),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PetCare Veterinary Clinic',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.78),
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
        // title: const Text(
        //   'Booking Antrian',
        //   style: TextStyle(
        //     color: Colors.white,
        //     fontWeight: FontWeight.w600,
        //     fontSize: 17,
        //   ),
        // ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DOCTOR SELECTOR
  // ─────────────────────────────────────────────────────────

  Widget _buildDoctorSelector() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _doctors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final doc = _doctors[i];
          final selected = _selectedDoctorIndex == i;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDoctorIndex = i;
              _selectedTimeSlot = '';
              // TODO: Panggil ulang fetchTimeSlots(doctorId: doc.id)
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOut,
              width: 210,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? _primary : _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? _primary : const Color(0xFFE0DCF0),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _primary.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // ── Foto Dokter ───────────────────────────
                  // [DINAMIS] Untuk foto dari server, ubah ke:
                  //   backgroundImage: NetworkImage(doc.photoUrl),
                  // Untuk aset lokal:
                  //   backgroundImage: AssetImage(doc.photoUrl),
                  // Contoh dengan error handler:
                  //   backgroundImage: NetworkImage(doc.photoUrl),
                  //   onBackgroundImageError: (_, __) {},
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: selected
                        ? Colors.white.withOpacity(0.18)
                        : _primaryLight,
                    // Uncomment salah satu baris ini saat foto tersedia:
                    // backgroundImage: NetworkImage(doc.photoUrl),
                    // backgroundImage: AssetImage(doc.photoUrl),
                    child: Text(
                      // Fallback: inisial nama (hapus saat foto sudah ada)
                      _getInitials(doc.name),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          doc.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : _textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          doc.specialty,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white.withOpacity(0.72)
                                : _textMid,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: selected
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${doc.rating}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : _textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withOpacity(0.18)
                                    : _primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${doc.queue} antri',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: selected ? Colors.white : _primary,
                                ),
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
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PET TYPE SELECTOR
  // ─────────────────────────────────────────────────────────

  Widget _buildPetTypeSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _petTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = _selectedPetType == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedPetType = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _primary : _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? _primary : const Color(0xFFE0DCF0),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _primary.withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                '${_petTypes[i]['emoji']} ${_petTypes[i]['label']}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _textMid,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PET NAME FIELD
  // ─────────────────────────────────────────────────────────

  Widget _buildPetNameField() {
    return _card(
      child: TextField(
        controller: _petNameController,
        onChanged: (v) => setState(() => _petName = v),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _textDark,
        ),
        decoration: InputDecoration(
          hintText: 'Contoh: Buddy, Luna, Milo...',
          hintStyle: const TextStyle(color: _textLight, fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🐾', style: TextStyle(fontSize: 16)),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DATE SELECTOR
  // ─────────────────────────────────────────────────────────

  Widget _buildDateSelector() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = _dates[i];
          final selected = _selectedDateIndex == i;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDateIndex = i;
              _selectedTimeSlot = '';
              // TODO: Panggil ulang fetchTimeSlots(date: _dates[i])
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 58,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A3298), Color(0xFF5C3FBB)],
                      )
                    : null,
                color: selected ? null : _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? _primary : const Color(0xFFE0DCF0),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _primary.withOpacity(0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    d['day']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white.withOpacity(0.78)
                          : _textMid,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    d['date']!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _textDark,
                    ),
                  ),
                  Text(
                    d['month']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? Colors.white.withOpacity(0.78)
                          : _textMid,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TIME GRID
  // ─────────────────────────────────────────────────────────

  Widget _buildTimeGrid() {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _legendDot(_primaryLight, _primary, 'Tersedia'),
              const SizedBox(width: 16),
              _legendDot(
                const Color(0xFFF3F4F6),
                const Color(0xFFD1D5DB),
                'Penuh',
              ),
              const SizedBox(width: 16),
              _legendDot(_primary, Colors.white, 'Dipilih'),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, i) {
              final slot = _timeSlots[i];
              final selected = _selectedTimeSlot == slot.time;
              return GestureDetector(
                onTap: slot.isAvailable
                    ? () => setState(() => _selectedTimeSlot = slot.time)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF4A3298), Color(0xFF5C3FBB)],
                          )
                        : null,
                    color: selected
                        ? null
                        : slot.isAvailable
                        ? _primaryLight
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _primary.withOpacity(0.28),
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      slot.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : slot.isAvailable
                            ? _primary
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color bg, Color border, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: _textMid)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  NOTES FIELD
  // ─────────────────────────────────────────────────────────

  Widget _buildNotesField() {
    return _card(
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: _textDark),
        decoration: const InputDecoration(
          hintText: 'Jelaskan keluhan hewan peliharaan Anda...',
          hintStyle: TextStyle(color: _textLight, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  QUEUE SUMMARY CARD
  // ─────────────────────────────────────────────────────────

  Widget _buildQueueInfoCard() {
    final bool complete = _petName.isNotEmpty && _selectedTimeSlot.isNotEmpty;

    if (!complete) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: const [
            Text('⚠️', style: TextStyle(fontSize: 18)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lengkapi nama hewan, pilih tanggal, dan jam untuk melihat ringkasan booking.',
                style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      );
    }

    final doc = _doctors[_selectedDoctorIndex];
    final dateStr =
        '${_dates[_selectedDateIndex]['day']}, '
        '${_dates[_selectedDateIndex]['date']} '
        '${_dates[_selectedDateIndex]['month']} 2026';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A3298), Color(0xFF3C2880)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ringkasan Booking',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Antrian #${doc.queue + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          _summaryRow(
            '${_petTypes[_selectedPetType]['emoji']!} Hewan',
            _petName,
          ),
          const SizedBox(height: 10),
          _summaryRow('👩‍⚕️ Dokter', doc.name),
          const SizedBox(height: 10),
          _summaryRow('📅 Tanggal', dateStr),
          const SizedBox(height: 10),
          _summaryRow('🕐 Jam', _selectedTimeSlot),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.62),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BOTTOM BAR
  // ─────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final bool canBook = _petName.isNotEmpty && _selectedTimeSlot.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: canBook ? _onBook : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canBook ? _primary : const Color(0xFFE0DCF0),
            foregroundColor: canBook ? Colors.white : _textLight,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 19,
                color: canBook ? Colors.white : _textLight,
              ),
              const SizedBox(width: 10),
              Text(
                canBook
                    ? 'Konfirmasi Booking · $_selectedTimeSlot'
                    : 'Lengkapi Data Booking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: canBook ? Colors.white : _textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _textDark,
      letterSpacing: -0.2,
    ),
  );

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0DCF0), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  /// Ambil inisial dari nama dokter (fallback saat foto belum tersedia)
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 3) return parts[1][0] + parts[2][0]; // skip "Dr."
    return parts.last[0];
  }

  // ─────────────────────────────────────────────────────────
  //  ON BOOK  ←  [DINAMIS] Kirim ke API di sini
  // ─────────────────────────────────────────────────────────

  void _onBook() {
    final doc = _doctors[_selectedDoctorIndex];
    final dateStr =
        '${_dates[_selectedDateIndex]['day']}, '
        '${_dates[_selectedDateIndex]['date']} '
        '${_dates[_selectedDateIndex]['month']} 2026';

    // TODO: Kirim request POST ke API:
    // final response = await BookingService.create(
    //   doctorId : doc.id,
    //   petName  : _petName,
    //   petType  : _petTypes[_selectedPetType]['label']!,
    //   date     : _dates[_selectedDateIndex],
    //   time     : _selectedTimeSlot,
    //   notes    : _notesController.text,
    // );
    // final queueNumber = response.queueNumber;  // dari server

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuccessSheet(
        petEmoji: _petTypes[_selectedPetType]['emoji']!,
        petName: _petName,
        doctor: doc,
        date: dateStr,
        time: _selectedTimeSlot,
        queueNumber:
            doc.queue + 1, // [DINAMIS] ganti dengan response.queueNumber
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUCCESS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final String petEmoji;
  final String petName;
  final Doctor doctor;
  final String date;
  final String time;
  final int queueNumber;

  const _SuccessSheet({
    required this.petEmoji,
    required this.petName,
    required this.doctor,
    required this.date,
    required this.time,
    required this.queueNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A3298), Color(0xFF5C3FBB)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A3298).withOpacity(0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Booking Berhasil! 🎉',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1340),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nomor antrian Anda',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '#$queueNumber',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: _primary,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _infoRow('$petEmoji', petName),
          const SizedBox(height: 9),
          _infoRow('👩‍⚕️', doctor.name),
          const SizedBox(height: 9),
          _infoRow('📅', '$date  •  $time'),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigasi ke halaman status antrian:
                // Navigator.pushNamed(context, '/queue-status',
                //   arguments: {'queueNumber': queueNumber});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Lihat Status Antrian',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(
                fontSize: 14,
                color: _primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
