import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/doctor_model.dart';
import '../../../models/services_model.dart';
import '../../../core/services/doctor_api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/booking_api.dart';
import '../../../features/booking/booking_success_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/widgets/shimmer_loading.dart';

const _purple = Color(0xFF4A3298);
const _purpleDark = Color(0xFF2E1D6B);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey100 = Color(0xFFF5F5F5);
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with TickerProviderStateMixin {
  List<DoctorModel> doctors = [];
  List<ServiceModel> services = [];
  DoctorModel? selectedDoctor;
  ServiceModel? selectedService;

  final namaPemilik = TextEditingController();
  final email = TextEditingController();
  final telepon = TextEditingController();
  final alamat = TextEditingController();
  final namaHewan = TextEditingController();
  final umur = TextEditingController();
  final ras = TextEditingController();
  final ciriWarna = TextEditingController();
  final catatan = TextEditingController();

  String jenisHewan = "Kucing";
  String jenisKelamin = "Jantan";
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTime = "09:00";
  bool loading = true;
  bool submitting = false;
  String selectedCategory = "Semua";

  final times = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00"];
  final categories = ["Semua", "Umum", "Vaksinasi", "Grooming", "Perawatan Gigi", "Laboratorium", "Darurat"];

  int _currentStep = 0;
  late final PageController _pageController;

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    namaPemilik.dispose();
    email.dispose();
    telepon.dispose();
    alamat.dispose();
    namaHewan.dispose();
    umur.dispose();
    ras.dispose();
    ciriWarna.dispose();
    catatan.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final d = await DoctorApi.fetchDoctors();
      final s = await ServiceApi.fetchServices();
      setState(() {
        doctors = d;
        services = s;
        if (doctors.isNotEmpty) selectedDoctor = doctors.first;
      });

      // Autofill User Data
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        setState(() {
          namaPemilik.text = userData['name'] ?? "";
          email.text = userData['email'] ?? "";
          telepon.text = userData['phone'] ?? "";
        });
      }

      setState(() => loading = false);
    } catch (e) {
      debugPrint("ERROR LOAD: $e");
      setState(() => loading = false);
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Pilih layanan terlebih dahulu"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
      _goToStep(1);
    } else if (_currentStep == 1) {
      if (_formKeys[1].currentState?.validate() ?? false) _goToStep(2);
    } else if (_currentStep == 2) {
      if (_formKeys[2].currentState?.validate() ?? false) submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  Future<void> submit() async {
    setState(() => submitting = true);
    try {
      final booking = await BookingApi.createBooking(
        namaPemilik: namaPemilik.text,
        email: email.text,
        telepon: telepon.text,
        alamat: alamat.text,
        namaHewan: namaHewan.text,
        jenisHewan: jenisHewan,
        jenisKelamin: jenisKelamin,
        ras: ras.text,
        umur: int.parse(umur.text),
        ciriWarna: ciriWarna.text,
        serviceId: selectedService!.id,
        serviceType: selectedService!.serviceType,
        doctorId: selectedDoctor!.id,
        bookingDate: "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
        bookingTime: selectedTime,
        catatan: catatan.text.isNotEmpty ? catatan.text : null,
      );
      setState(() => submitting = false);
      if (!mounted) return;
      // Navigate to standalone success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(booking: booking),
        ),
      );
    } catch (e) {
      setState(() => submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Booking gagal: $e"),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  IconData _serviceIcon(String type) {
    switch (type) {
      case 'grooming': return Icons.content_cut_rounded;
      case 'vaksinasi': case 'vaccination': return Icons.vaccines_rounded;
      case 'konsultasi_umum': case 'general': return Icons.medical_services_rounded;
      case 'perawatan_gigi': case 'dental': return Icons.mood_rounded;
      case 'pemeriksaan_darah': case 'laboratory': return Icons.bloodtype_rounded;
      case 'sterilisasi': case 'surgery': return Icons.healing_rounded;
      case 'inpatient': return Icons.local_hotel_rounded;
      case 'emergency': return Icons.emergency_rounded;
      default: return Icons.medical_services_rounded;
    }
  }

  Color _categoryColor(String type) {
    switch (type) {
      case 'grooming': return const Color(0xFF4CAF50);
      case 'vaksinasi': case 'vaccination': return const Color(0xFFFF9800);
      case 'perawatan_gigi': case 'dental': return const Color(0xFFE91E63);
      case 'pemeriksaan_darah': case 'laboratory': return const Color(0xFF2196F3);
      case 'emergency': return const Color(0xFFF44336);
      default: return _purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: _purpleBg,
        appBar: AppBar(
          title: Text("Booking Layanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _purple,
          elevation: 0,
        ),
        body: const ShimmerList(itemCount: 8),
      );
    }
    return Scaffold(
      backgroundColor: _purpleBg,
      body: Column(children: [
        _buildHeader(),
        _buildStepIndicator(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildStep1(), _buildStep2(), _buildStep3()],
          ),
        ),
        _buildBottomButtons(),
      ]),
    );
  }

  Widget _buildHeader() {
    final titles = ["Pilih Layanan", "Dokter & Jadwal", "Data Pemilik & Hewan"];
    final subtitles = ["Pilih layanan untuk hewan Anda", "Tentukan dokter dan jadwal kunjungan", "Lengkapi data pemilik dan hewan"];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_purpleDark, _purple, _purpleLight]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            if (_currentStep == 0) {
              Navigator.pop(context);
            } else {
              _prevStep();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_rounded, color: _white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titles[_currentStep], style: GoogleFonts.poppins(color: _white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitles[_currentStep], style: GoogleFonts.poppins(color: _white.withOpacity(0.75), fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ["Layanan", "Jadwal", "Data"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: List.generate(3, (i) {
        final isActive = i <= _currentStep;
        final isCurrent = i == _currentStep;
        return Expanded(child: Row(children: [
          if (i > 0) Expanded(child: Container(height: 2.5, decoration: BoxDecoration(color: isActive ? _purple : _grey300, borderRadius: BorderRadius.circular(2)))),
          Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: isCurrent ? 38 : 30, height: isCurrent ? 38 : 30,
              decoration: BoxDecoration(
                color: isActive ? _purple : _white, shape: BoxShape.circle,
                border: Border.all(color: isActive ? _purple : _grey300, width: 2),
                boxShadow: isCurrent ? [BoxShadow(color: _purple.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))] : [],
              ),
              child: Center(child: Text("${i + 1}", style: GoogleFonts.poppins(color: isActive ? _white : _grey600, fontSize: isCurrent ? 14 : 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: GoogleFonts.poppins(fontSize: 9, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, color: isActive ? _purple : _grey600)),
          ]),
        ]));
      })),
    );
  }

  // ── STEP 1: Pilih Layanan ──
  Widget _buildStep1() {
    final filtered = selectedCategory == "Semua"
        ? services
        : services.where((s) => s.serviceTypeLabel.toLowerCase().contains(selectedCategory.toLowerCase())).toList();
    return Column(children: [
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final isActive = selectedCategory == categories[i];
            return GestureDetector(
              onTap: () => setState(() => selectedCategory = categories[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? _purple : _white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? _purple : _grey300),
                ),
                alignment: Alignment.center,
                child: Text(categories[i], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? _white : _grey600)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Text("Tidak ada layanan", style: GoogleFonts.poppins(color: _grey600)))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildServiceCard(filtered[i]),
              ),
      ),
    ]);
  }

  Widget _buildServiceCard(ServiceModel svc) {
    final isSelected = selectedService?.id == svc.id;
    return GestureDetector(
      onTap: () => _showServiceDetail(svc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? _purple : _grey300, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: (isSelected ? _purple : Colors.black).withOpacity(isSelected ? 0.12 : 0.04), blurRadius: isSelected ? 12 : 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(_serviceIcon(svc.serviceType), color: _purple, size: 26),
            ),
            const SizedBox(height: 10),
            Text(svc.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _purpleDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Expanded(child: Text(svc.description, style: GoogleFonts.poppins(fontSize: 10, color: _grey600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _categoryColor(svc.serviceType).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(svc.serviceTypeLabel, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: _categoryColor(svc.serviceType))),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text(svc.formattedPrice, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _purple)),
              const Spacer(),
              Text(svc.formattedDuration, style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showServiceDetail(ServiceModel svc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 48, height: 4, decoration: BoxDecoration(color: _grey300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: Text(svc.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _purpleDark))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: _grey600)),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(_serviceIcon(svc.serviceType), color: _purple, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(svc.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _purpleDark)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: _categoryColor(svc.serviceType).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(svc.serviceTypeLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _categoryColor(svc.serviceType))),
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),
                Text(svc.description, style: GoogleFonts.poppins(fontSize: 13, color: _grey600)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _infoBox("Harga:", svc.formattedPrice)),
                  const SizedBox(width: 12),
                  Expanded(child: _infoBox("Durasi:", svc.formattedDuration)),
                ]),
                const SizedBox(height: 16),
                Text("Detail Layanan", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _purple)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(14)),
                  child: Text(svc.details.isNotEmpty ? svc.details : svc.description, style: GoogleFonts.poppins(fontSize: 12, color: _purpleDark, height: 1.6)),
                ),
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: _grey600, side: const BorderSide(color: _grey300), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text("Tutup", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () { setState(() => selectedService = svc); Navigator.pop(context); _goToStep(1); },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text("Booking Layanan", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3, shadowColor: _purple.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _purpleAccent.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: _grey600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _purple)),
      ]),
    );
  }

  // ── STEP 2: Dokter & Jadwal ──
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Form(key: _formKeys[1], child: Column(children: [
        _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.person_search_rounded, "Pilih Dokter"),
          const SizedBox(height: 6),
          Text("Dokter yang tersedia disesuaikan dengan layanan yang dipilih", style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
          const SizedBox(height: 12),
          _StyledDropdown<DoctorModel>(
            label: "Pilih Dokter",
            value: selectedDoctor,
            items: doctors.map((e) => DropdownMenuItem(value: e, child: Text("drh. ${e.name} - ${e.specialization}", style: GoogleFonts.poppins(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => selectedDoctor = v),
            icon: Icons.person_search_outlined,
          ),
          if (selectedDoctor != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _purpleAccent.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, color: _purple, size: 16),
                  const SizedBox(width: 6),
                  Text("Info Dokter", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _purple)),
                ]),
                const SizedBox(height: 8),
                Text("drh. ${selectedDoctor!.name}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _purpleDark)),
                const SizedBox(height: 4),
                Text("Spesialisasi: ${selectedDoctor!.specialization}", style: GoogleFonts.poppins(fontSize: 12, color: _grey600)),
                if (selectedDoctor!.schedule != null)
                  Text("Jadwal: ${selectedDoctor!.schedule}", style: GoogleFonts.poppins(fontSize: 12, color: _grey600, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
        ])),
        const SizedBox(height: 14),
        _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.date_range_rounded, "Tanggal Kunjungan"),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _purpleAccent)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: _purple, size: 20),
                const SizedBox(width: 12),
                Text("${selectedDate.day.toString().padLeft(2, '0')} / ${selectedDate.month.toString().padLeft(2, '0')} / ${selectedDate.year}", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _purpleDark)),
                const Spacer(),
                const Icon(Icons.edit_calendar_rounded, color: _purpleLight, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text("Minimal booking untuk besok hari", style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange.shade700)),
        ])),
        const SizedBox(height: 14),
        _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.schedule_rounded, "Waktu Kunjungan"),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: times.map((t) {
            final isSelected = selectedTime == t;
            return GestureDetector(
              onTap: () => setState(() => selectedTime = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _purple : _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? _purple : _grey300, width: 1.5),
                  boxShadow: isSelected ? [BoxShadow(color: _purple.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: Text(t, style: GoogleFonts.poppins(color: isSelected ? _white : _purpleDark, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            );
          }).toList()),
        ])),
      ])),
    );
  }

  // ── STEP 3: Data Pemilik & Hewan ──
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Form(key: _formKeys[2], child: Column(children: [
        // Keterangan wajib isi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.red.shade400, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text.rich(
              TextSpan(children: [
                TextSpan(text: "Kolom bertanda ", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                TextSpan(text: "* ", style: GoogleFonts.poppins(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w700)),
                TextSpan(text: "wajib diisi", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.person_outline_rounded, "Data Pemilik"),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: namaPemilik, label: "Nama Lengkap", hint: "Masukkan nama Anda",
            icon: Icons.badge_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? "Nama wajib diisi" : null,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: email, label: "Email", hint: "contoh@email.com",
            icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, isRequired: true,
            validator: (v) { if (v == null || v.isEmpty) return "Email wajib diisi"; if (!v.contains('@')) return "Email tidak valid"; return null; },
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: telepon, label: "Nomor Telepon", hint: "08xxxxxxxxxx",
            icon: Icons.phone_outlined, keyboardType: TextInputType.phone, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? "Telepon wajib diisi" : null,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: alamat, label: "Alamat", hint: "Masukkan alamat lengkap Anda",
            icon: Icons.location_on_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? "Alamat wajib diisi" : null,
          ),
        ])),
        const SizedBox(height: 14),
        _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.pets_rounded, "Data Hewan Peliharaan"),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: namaHewan, label: "Nama Hewan", hint: "Nama panggilan",
            icon: Icons.cruelty_free_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? "Nama hewan wajib diisi" : null,
          ),
          const SizedBox(height: 14),
          // Jenis Hewan
          _RequiredLabel(label: "Jenis Hewan"),
          const SizedBox(height: 8),
          Row(children: ["Kucing", "Anjing"].map((j) {
            final isSel = jenisHewan == j;
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: j == "Kucing" ? 6 : 0, left: j == "Anjing" ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => jenisHewan = j),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? _purple : _white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? _purple : _grey300, width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(j == "Kucing" ? Icons.cruelty_free : Icons.pets, color: isSel ? _white : _grey600, size: 18),
                    const SizedBox(width: 6),
                    Text(j, style: GoogleFonts.poppins(color: isSel ? _white : _purpleDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 14),
          // Jenis Kelamin
          _RequiredLabel(label: "Jenis Kelamin"),
          const SizedBox(height: 8),
          Row(children: ["Jantan", "Betina"].map((k) {
            final isSel = jenisKelamin == k;
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: k == "Jantan" ? 6 : 0, left: k == "Betina" ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => jenisKelamin = k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? _purple : _white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? _purple : _grey300, width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(k == "Jantan" ? Icons.male_rounded : Icons.female_rounded, color: isSel ? _white : _grey600, size: 20),
                    const SizedBox(width: 6),
                    Text(k, style: GoogleFonts.poppins(color: isSel ? _white : _purpleDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: ras, label: "Ras", hint: "Contoh: Persia, Poodle",
            icon: Icons.category_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? "Ras wajib diisi" : null,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: umur, label: "Umur (bulan)", hint: "Contoh: 12",
            icon: Icons.cake_outlined, keyboardType: TextInputType.number, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? "Umur wajib diisi" : null,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: ciriWarna, label: "Ciri / Warna", hint: "Contoh: Putih dengan bercak hitam",
            icon: Icons.palette_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? "Ciri/warna wajib diisi" : null,
          ),
        ])),
        const SizedBox(height: 14),
        _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.note_alt_outlined, "Catatan Tambahan"),
          const SizedBox(height: 6),
          Text("Opsional — tidak wajib diisi", style: GoogleFonts.poppins(fontSize: 11, color: _grey600, fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          TextFormField(
            controller: catatan,
            maxLines: 3,
            maxLength: 500,
            style: GoogleFonts.poppins(fontSize: 13, color: _purpleDark),
            decoration: InputDecoration(
              hintText: "Tuliskan keluhan atau catatan khusus...",
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: _grey600.withOpacity(0.6)),
              filled: true, fillColor: _purpleBg.withOpacity(0.5),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _grey300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _grey300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _purple, width: 1.5)),
            ),
          ),
        ])),
        const SizedBox(height: 14),
        // Ringkasan Pemesanan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_purple.withOpacity(0.08), _purpleAccent.withOpacity(0.12)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _purpleAccent.withOpacity(0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.receipt_long_rounded, color: _purple, size: 18),
              const SizedBox(width: 8),
              Text("Ringkasan Pemesanan", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _purple)),
            ]),
            const Divider(height: 20, color: _purpleAccent),
            _summaryRow("Layanan", selectedService?.name ?? "-"),
            _summaryRow("Dokter", "drh. ${selectedDoctor?.name ?? '-'}"),
            _summaryRow("Tanggal", "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"),
            _summaryRow("Waktu", selectedTime),
            const Divider(height: 16, color: _purpleAccent),
            Row(children: [
              Text("Biaya:", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _purpleDark)),
              const Spacer(),
              Text(selectedService?.formattedPrice ?? "-", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _purple)),
            ]),
          ]),
        ),
      ])),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text("$label:", style: GoogleFonts.poppins(fontSize: 12, color: _grey600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _purpleDark), textAlign: TextAlign.end)),
      ]),
    );
  }



  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _purple, onPrimary: _white, surface: _white, onSurface: _purpleDark), textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: _purple))), child: child!),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(color: _white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))]),
      child: Row(children: [
        if (_currentStep > 0) Expanded(child: OutlinedButton.icon(
          onPressed: _prevStep,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text("Kembali", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(foregroundColor: _purple, side: const BorderSide(color: _purple, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        )),
        if (_currentStep > 0) const SizedBox(width: 14),
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: ElevatedButton.icon(
            onPressed: submitting ? null : _nextStep,
            icon: submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(_white)))
                : Icon(_currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded, size: 18),
            label: Text(
              submitting ? "Memproses..." : (_currentStep == 0 ? "Selanjutnya" : _currentStep == 1 ? "Selanjutnya" : "Konfirmasi Pemesanan"),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _white, disabledBackgroundColor: _purpleAccent, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3, shadowColor: _purple.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _purple, size: 20)),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _purpleDark)),
    ]);
  }
}

// ── Reusable Widgets ──
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _white.withOpacity(0.92), borderRadius: BorderRadius.circular(20), border: Border.all(color: _purpleAccent.withOpacity(0.3)), boxShadow: [BoxShadow(color: _purple.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))]),
      child: child,
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  final String label;
  const _RequiredLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _purpleDark)),
      Text(" *", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
    ]);
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isRequired;
  const _StyledTextField({required this.controller, required this.label, required this.hint, required this.icon, this.keyboardType = TextInputType.text, this.validator, this.isRequired = false});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _purpleDark)),
        if (isRequired) Text(" *", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
      ]),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType, validator: validator,
        style: GoogleFonts.poppins(fontSize: 14, color: _purpleDark),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.poppins(fontSize: 13, color: _grey600.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: _purpleLight, size: 20),
          filled: true, fillColor: _purpleBg.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _grey300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _grey300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _purple, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
        ),
      ),
    ]);
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData icon;
  const _StyledDropdown({required this.label, required this.value, required this.items, required this.onChanged, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _purpleDark)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: _purpleBg.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: _grey300)),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          value: value, items: items, onChanged: onChanged, isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _purple),
          style: GoogleFonts.poppins(fontSize: 14, color: _purpleDark), dropdownColor: _white, borderRadius: BorderRadius.circular(14),
        )),
      ),
    ]);
  }
}
