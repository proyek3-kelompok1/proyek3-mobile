import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/doctor_model.dart';
import '../../../models/services_model.dart';
import '../../../core/services/doctor_api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/booking_api.dart';

// ──────────────────────────────────────────────────────────
//  COLOUR PALETTE  (purple + white dominant)
// ──────────────────────────────────────────────────────────
const _purple      = Color(0xFF4A3298);
const _purpleDark   = Color(0xFF2E1D6B);
const _purpleLight  = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg     = Color(0xFFF3EEFF);
const _white        = Colors.white;
const _grey100      = Color(0xFFF5F5F5);
const _grey300      = Color(0xFFE0E0E0);
const _grey600      = Color(0xFF757575);

// ──────────────────────────────────────────────────────────
//  BOOKING PAGE  (main entry)
// ──────────────────────────────────────────────────────────
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with TickerProviderStateMixin {
  // ── data ───────────────────────────────────────────────
  List<DoctorModel> doctors = [];
  List<ServiceModel> services = [];

  DoctorModel? selectedDoctor;
  ServiceModel? selectedService;

  final namaPemilik = TextEditingController();
  final email = TextEditingController();
  final telepon = TextEditingController();
  final namaHewan = TextEditingController();
  final umur = TextEditingController();

  String jenisHewan = "Kucing";
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTime = "09:00";
  bool loading = true;
  bool submitting = false;

  final times = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00"];

  // ── stepper ────────────────────────────────────────────
  int _currentStep = 0;
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    namaPemilik.dispose();
    email.dispose();
    telepon.dispose();
    namaHewan.dispose();
    umur.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final d = await DoctorApi.fetchDoctors();
      final s = await ServiceApi.fetchServices();
      if (d.isEmpty || s.isEmpty) throw Exception("Data kosong");
      setState(() {
        doctors = d;
        services = s;
        selectedDoctor = doctors.first;
        selectedService = services.first;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD: $e");
      setState(() => loading = false);
    }
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> submit() async {
    if (!(_formKeys[_currentStep].currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    try {
      final booking = await BookingApi.createBooking(
        namaPemilik: namaPemilik.text,
        email: email.text,
        telepon: telepon.text,
        namaHewan: namaHewan.text,
        jenisHewan: jenisHewan,
        umur: int.parse(umur.text),
        serviceId: selectedService!.id,
        doctorId: selectedDoctor!.id,
        bookingDate:
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
        bookingTime: selectedTime,
      );
      setState(() => submitting = false);
      if (!mounted) return;
      _showSuccessSheet(booking);
    } catch (e) {
      setState(() => submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking gagal: $e"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessSheet(dynamic booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(booking: booking),
    );
  }

  // ──────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: _purpleBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(_purple),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Memuat data...",
                style: GoogleFonts.poppins(
                  color: _purple,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _purpleBg,
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────
          _buildHeader(),
          // ── STEP INDICATOR ────────────────────────────
          _buildStepIndicator(),
          // ── FORM PAGES ────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          // ── BOTTOM BUTTONS ────────────────────────────
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Booking Layanan",
                      style: GoogleFonts.poppins(
                        color: _white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Jadwalkan kunjungan untuk hewan Anda",
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
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  STEP INDICATOR
  // ──────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final labels = ["Data Pemilik", "Data Hewan", "Jadwal"];
    final icons = [
      Icons.person_rounded,
      Icons.pets_rounded,
      Icons.schedule_rounded,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: isActive ? _purple : _grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: isCurrent ? 44 : 36,
                      height: isCurrent ? 44 : 36,
                      decoration: BoxDecoration(
                        color: isActive ? _purple : _white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? _purple : _grey300,
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: _purple.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        icons[i],
                        color: isActive ? _white : _grey600,
                        size: isCurrent ? 22 : 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? _purple : _grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  STEP 1 – Data Pemilik
  // ──────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Form(
        key: _formKeys[0],
        child: _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.person_outline_rounded, "Informasi Pemilik"),
              const SizedBox(height: 18),
              _StyledTextField(
                controller: namaPemilik,
                label: "Nama Lengkap",
                hint: "Masukkan nama Anda",
                icon: Icons.badge_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              _StyledTextField(
                controller: email,
                label: "Email",
                hint: "contoh@email.com",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Email wajib diisi";
                  if (!v.contains('@')) return "Email tidak valid";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _StyledTextField(
                controller: telepon,
                label: "Nomor Telepon",
                hint: "08xxxxxxxxxx",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Telepon wajib diisi" : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  STEP 2 – Data Hewan
  // ──────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Form(
        key: _formKeys[1],
        child: _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.pets_rounded, "Informasi Hewan"),
              const SizedBox(height: 18),
              _StyledTextField(
                controller: namaHewan,
                label: "Nama Hewan",
                hint: "Nama panggilan hewan",
                icon: Icons.cruelty_free_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Nama hewan wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              // Jenis Hewan chips
              Text(
                "Jenis Hewan",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _purpleDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ["Kucing", "Anjing"].map((j) {
                  final isSelected = jenisHewan == j;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: j == "Kucing" ? 8 : 0,
                        left: j == "Anjing" ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => jenisHewan = j),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _purple
                                : _white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? _purple : _grey300,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _purple.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                j == "Kucing"
                                    ? Icons.cruelty_free
                                    : Icons.pets,
                                color: isSelected ? _white : _grey600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                j,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? _white : _purpleDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _StyledTextField(
                controller: umur,
                label: "Umur (tahun)",
                hint: "Contoh: 2",
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Umur wajib diisi" : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  STEP 3 – Jadwal & Layanan
  // ──────────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Form(
        key: _formKeys[2],
        child: Column(
          children: [
            // ── Service & Doctor ────────────────────────
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                      Icons.medical_services_outlined, "Pilih Layanan"),
                  const SizedBox(height: 14),
                  _StyledDropdown<ServiceModel>(
                    label: "Layanan",
                    value: selectedService,
                    items: services
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.name,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedService = v),
                    icon: Icons.local_hospital_outlined,
                  ),
                  const SizedBox(height: 14),
                  _StyledDropdown<DoctorModel>(
                    label: "Dokter",
                    value: selectedDoctor,
                    items: doctors
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.name,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDoctor = v),
                    icon: Icons.person_search_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Date Picker ─────────────────────────────
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(Icons.date_range_rounded, "Pilih Tanggal"),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _purpleBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _purpleAccent, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: _purple, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            "${selectedDate.day.toString().padLeft(2, '0')} / "
                            "${selectedDate.month.toString().padLeft(2, '0')} / "
                            "${selectedDate.year}",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _purpleDark,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded,
                              color: _purpleLight, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Time Slots ──────────────────────────────
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(Icons.schedule_rounded, "Pilih Waktu"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: times.map((t) {
                      final isSelected = selectedTime == t;
                      return GestureDetector(
                        onTap: () => setState(() => selectedTime = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _purple : _white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _purple : _grey300,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _purple.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.poppins(
                              color: isSelected ? _white : _purpleDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  DATE PICKER
  // ──────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _purple,
              onPrimary: _white,
              surface: _white,
              onSurface: _purpleDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _purple),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // ──────────────────────────────────────────────────────
  //  BOTTOM BUTTONS
  // ──────────────────────────────────────────────────────
  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: Text(
                  "Kembali",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: _purple, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 14),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: submitting
                  ? null
                  : (_currentStep < 2 ? _nextStep : submit),
              icon: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(_white),
                      ),
                    )
                  : Icon(
                      _currentStep < 2
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_rounded,
                      size: 20,
                    ),
              label: Text(
                submitting
                    ? "Memproses..."
                    : (_currentStep < 2 ? "Lanjutkan" : "Booking Sekarang"),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: _white,
                disabledBackgroundColor: _purpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 4,
                shadowColor: _purple.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  //  HELPER: section title
  // ──────────────────────────────────────────────────────
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _purpleBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _purple, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _purpleDark,
          ),
        ),
      ],
    );
  }
}

// ================================================================
//  GLASS CARD
// ================================================================
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purpleAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ================================================================
//  STYLED TEXT FIELD
// ================================================================
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _purpleDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14, color: _purpleDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: _grey600.withOpacity(0.6),
            ),
            prefixIcon: Icon(icon, color: _purpleLight, size: 20),
            filled: true,
            fillColor: _purpleBg.withOpacity(0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _purple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
//  STYLED DROPDOWN
// ================================================================
class _StyledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData icon;

  const _StyledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _purpleDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _purpleBg.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _grey300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _purple),
              style: GoogleFonts.poppins(fontSize: 14, color: _purpleDark),
              dropdownColor: _white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
//  SUCCESS BOTTOM SHEET
// ================================================================
class _SuccessSheet extends StatelessWidget {
  final dynamic booking;

  const _SuccessSheet({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: _grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Success illustration
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_purple.withOpacity(0.1), _purpleAccent.withOpacity(0.15)],
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: _white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Booking Berhasil! 🎉",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _purpleDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Hewan Anda sudah terjadwalkan",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _grey600,
            ),
          ),
          const SizedBox(height: 24),

          // Booking details card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _purpleBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _purpleAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _detailRow(Icons.confirmation_number_outlined,
                    "Nomor Antrian", "${booking.nomorAntrian}"),
                const Divider(height: 20, color: _purpleAccent),
                _detailRow(Icons.calendar_today_rounded, "Tanggal",
                    booking.bookingDate),
                const Divider(height: 20, color: _purpleAccent),
                _detailRow(
                    Icons.schedule_rounded, "Waktu", booking.bookingTime),
                if (booking.bookingCode != null &&
                    booking.bookingCode.isNotEmpty) ...[
                  const Divider(height: 20, color: _purpleAccent),
                  _detailRow(Icons.qr_code_rounded, "Kode Booking",
                      booking.bookingCode),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: _purple.withOpacity(0.4),
                ),
                child: Text(
                  "Selesai",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _purple, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _grey600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _purpleDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
