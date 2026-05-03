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
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';

const _purple = Color(0xFF4A1059);
const _purpleDark = Color(0xFF4A1059);
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
        final sp = Provider.of<SettingsProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sp.translate('select_service_first')),
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
    final sp = Provider.of<SettingsProvider>(context);
    final isDark = sp.isDarkMode;

    if (loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF13131C) : _purpleBg,
        appBar: AppBar(
          title: Text(sp.translate('booking_service_title'),
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _purple,
          elevation: 0,
        ),
        body: const ShimmerList(itemCount: 8),
      );
    }
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13131C) : _purpleBg,
      body: Column(
        children: [
          _buildHeader(sp),
          _buildStepIndicator(sp),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(sp),
                _buildStep2(sp),
                _buildStep3(sp),
              ],
            ),
          ),
          _buildBottomButtons(sp),
        ],
      ),
    );
  }

  Widget _buildHeader(SettingsProvider sp) {
    final titles = [sp.translate('step_service'), sp.translate('step_schedule'), sp.translate('step_data')];
    final subtitles = [sp.translate('step_service_desc'), sp.translate('step_schedule_desc'), sp.translate('step_data_desc')];
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

  Widget _buildStepIndicator(SettingsProvider sp) {
    final labels = [sp.translate('label_service'), sp.translate('label_schedule'), sp.translate('label_data')];
    final isDark = sp.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: List.generate(3, (i) {
        final isActive = i <= _currentStep;
        final isCurrent = i == _currentStep;
        return Expanded(child: Row(children: [
          if (i > 0) Expanded(child: Container(height: 2.5, decoration: BoxDecoration(color: isActive ? _purple : (isDark ? Colors.white24 : _grey300), borderRadius: BorderRadius.circular(2)))),
          Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: isCurrent ? 38 : 30, height: isCurrent ? 38 : 30,
              decoration: BoxDecoration(
                color: isActive ? _purple : (isDark ? const Color(0xFF1E1E2C) : _white), shape: BoxShape.circle,
                border: Border.all(color: isActive ? _purple : (isDark ? Colors.white24 : _grey300), width: 2),
                boxShadow: isCurrent ? [BoxShadow(color: _purple.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))] : [],
              ),
              child: Center(child: Text("${i + 1}", style: GoogleFonts.poppins(color: isActive ? _white : (isDark ? Colors.white70 : _grey600), fontSize: isCurrent ? 14 : 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: GoogleFonts.poppins(fontSize: 9, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, color: isActive ? _purple : (isDark ? Colors.white54 : _grey600))),
          ]),
        ]));
      })),
    );
  }

  // ── STEP 1: Pilih Layanan ──
  Widget _buildStep1(SettingsProvider sp) {
    final isDark = sp.isDarkMode;
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
                  color: isActive ? _purple : (isDark ? const Color(0xFF1E1E2C) : _white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? _purple : (isDark ? Colors.white24 : _grey300)),
                ),
                alignment: Alignment.center,
                child: Text(categories[i], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? _white : (isDark ? Colors.white70 : _grey600))),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Text(sp.translate('no_service_found'), style: GoogleFonts.poppins(color: isDark ? Colors.white54 : _grey600)))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildServiceCard(filtered[i], sp),
              ),
      ),
    ]);
  }

  Widget _buildServiceCard(ServiceModel svc, SettingsProvider sp) {
    final isSelected = selectedService?.id == svc.id;
    final isDark = sp.isDarkMode;
    return GestureDetector(
      onTap: () => _showServiceDetail(svc, sp),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? _purple : (isDark ? Colors.white12 : _grey300), width: isSelected ? 2 : 1),
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
            Text(svc.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : _purpleDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Expanded(child: Text(svc.description, style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white54 : _grey600), maxLines: 2, overflow: TextOverflow.ellipsis)),
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
              Text(svc.formattedDuration, style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white38 : _grey600)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showServiceDetail(ServiceModel svc, SettingsProvider sp) {
    final isDark = sp.isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF13131C) : _white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 48, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : _grey300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: Text(svc.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : _purpleDark))),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : _grey600)),
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
                    Text(svc.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _purpleDark)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: _categoryColor(svc.serviceType).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(svc.serviceTypeLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _categoryColor(svc.serviceType))),
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),
                Text(svc.description, style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white70 : _grey600)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _infoBox(sp.translate('price_label') + ":", svc.formattedPrice, isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _infoBox(sp.translate('duration_label') + ":", svc.formattedDuration, isDark)),
                ]),
                const SizedBox(height: 16),
                Text(sp.translate('service_detail_title'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? _purpleAccent : _purple)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: isDark ? _purple.withOpacity(0.1) : _purpleBg, borderRadius: BorderRadius.circular(14)),
                  child: Text(svc.details.isNotEmpty ? svc.details : svc.description, style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : _purpleDark, height: 1.6)),
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
                  style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.white70 : _grey600, side: BorderSide(color: isDark ? Colors.white12 : _grey300), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(sp.translate('close_btn'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () { setState(() => selectedService = svc); Navigator.pop(context); _goToStep(1); },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(sp.translate('booking_service_title'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3, shadowColor: _purple.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? _purple.withOpacity(0.1) : _purpleBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _purpleAccent.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: isDark ? Colors.white54 : _grey600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? _purpleAccent : _purple)),
      ]),
    );
  }

  // ── STEP 2: Dokter & Jadwal ──
  Widget _buildStep2(SettingsProvider sp) {
    final isDark = sp.isDarkMode;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Form(key: _formKeys[1], child: Column(children: [
        _GlassCard(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.person_search_rounded, sp.translate('step_schedule'), isDark),
          const SizedBox(height: 6),
          Text(sp.translate('available_doctors_hint'), style: GoogleFonts.poppins(fontSize: 10, color: isDark ? Colors.white54 : _grey600)),
          const SizedBox(height: 12),
          _StyledDropdown<DoctorModel>(
            label: sp.translate('step_schedule'),
            value: selectedDoctor,
            items: doctors.map((e) => DropdownMenuItem(value: e, child: Text("drh. ${e.name} - ${e.specialization}", style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white : Colors.black)))).toList(),
            onChanged: (v) => setState(() => selectedDoctor = v),
            icon: Icons.person_search_outlined,
            isDark: isDark,
          ),
          if (selectedDoctor != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: isDark ? _purple.withOpacity(0.1) : _purpleBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _purpleAccent.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, color: isDark ? _purpleAccent : _purple, size: 16),
                  const SizedBox(width: 6),
                  Text("Info Dokter", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? _purpleAccent : _purple)),
                ]),
                const SizedBox(height: 8),
                Text("drh. ${selectedDoctor!.name}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _purpleDark)),
                const SizedBox(height: 4),
                Text("Spesialisasi: ${selectedDoctor!.specialization}", style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : _grey600)),
                if (selectedDoctor!.schedule != null)
                  Text("Jadwal: ${selectedDoctor!.schedule}", style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white54 : _grey600, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
        ])),
        const SizedBox(height: 14),
        _GlassCard(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.date_range_rounded, sp.translate('visit_date_label'), isDark),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: isDark ? _purple.withOpacity(0.1) : _purpleBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _purpleAccent)),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, color: isDark ? _purpleAccent : _purple, size: 20),
                const SizedBox(width: 12),
                Text("${selectedDate.day.toString().padLeft(2, '0')} / ${selectedDate.month.toString().padLeft(2, '0')} / ${selectedDate.year}", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _purpleDark)),
                const Spacer(),
                Icon(Icons.edit_calendar_rounded, color: isDark ? Colors.white38 : _purpleLight, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(sp.translate('min_booking_hint'), style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange.shade700)),
        ])),
        const SizedBox(height: 14),
        _GlassCard(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.schedule_rounded, sp.translate('visit_time_label'), isDark),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: times.map((t) {
            final isSelected = selectedTime == t;
            return GestureDetector(
              onTap: () => setState(() => selectedTime = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _purple : (isDark ? const Color(0xFF1E1E2C) : _white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? _purple : (isDark ? Colors.white12 : _grey300), width: 1.5),
                  boxShadow: isSelected ? [BoxShadow(color: _purple.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: Text(t, style: GoogleFonts.poppins(color: isSelected ? _white : (isDark ? Colors.white : _purpleDark), fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            );
          }).toList()),
        ])),
      ])),
    );
  }

  // ── STEP 3: Data Pemilik & Hewan ──
  Widget _buildStep3(SettingsProvider sp) {
    final isDark = sp.isDarkMode;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Form(key: _formKeys[2], child: Column(children: [
        // Keterangan wajib isi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.red.shade400, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text.rich(
              TextSpan(children: [
                TextSpan(text: sp.translate('required_fields_hint').split('*')[0], style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                TextSpan(text: "* ", style: GoogleFonts.poppins(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w700)),
                TextSpan(text: sp.translate('required_fields_hint').split('*')[1], style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        _GlassCard(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.person_outline_rounded, sp.translate('owner_data_title'), isDark),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: namaPemilik, label: sp.translate('full_name_label'), hint: sp.translate('enter_name_hint'),
            icon: Icons.badge_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? sp.translate('name_req') : null,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: email, label: "Email", hint: "contoh@email.com",
            icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, isRequired: true,
            validator: (v) { if (v == null || v.isEmpty) return sp.translate('email_req'); if (!v.contains('@')) return "Email tidak valid"; return null; },
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: telepon, label: sp.translate('phone_label'), hint: "08xxxxxxxxxx",
            icon: Icons.phone_outlined, keyboardType: TextInputType.phone, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? sp.translate('phone_req') : null,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: alamat, label: sp.translate('address_label'), hint: "Masukkan alamat lengkap Anda",
            icon: Icons.location_on_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? sp.translate('address_req') : null,
            isDark: isDark,
          ),
        ])),
        const SizedBox(height: 14),
        _GlassCard(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.pets_rounded, sp.translate('pet_data_title'), isDark),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: namaHewan, label: sp.translate('pet_name_label'), hint: sp.translate('pet_name_label'),
            icon: Icons.cruelty_free_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? sp.translate('pet_name_req') : null,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          // Jenis Hewan
          _RequiredLabel(label: sp.translate('pet_type_label'), isDark: isDark),
          const SizedBox(height: 8),
          Row(children: [sp.translate('cat_label'), sp.translate('dog_label')].map((j) {
            final isSel = jenisHewan == (j == sp.translate('cat_label') ? "Kucing" : "Anjing");
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: j == sp.translate('cat_label') ? 6 : 0, left: j == sp.translate('dog_label') ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => jenisHewan = (j == sp.translate('cat_label') ? "Kucing" : "Anjing")),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? _purple : (isDark ? const Color(0xFF1E1E2C) : _white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? _purple : (isDark ? Colors.white12 : _grey300), width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(j == sp.translate('cat_label') ? Icons.cruelty_free : Icons.pets, color: isSel ? _white : _grey600, size: 18),
                    const SizedBox(width: 6),
                    Text(j, style: GoogleFonts.poppins(color: isSel ? _white : (isDark ? Colors.white : _purpleDark), fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 14),
          // Jenis Kelamin
          _RequiredLabel(label: sp.translate('pet_gender_label'), isDark: isDark),
          const SizedBox(height: 8),
          Row(children: [sp.translate('male_label'), sp.translate('female_label')].map((k) {
            final isSel = jenisKelamin == (k == sp.translate('male_label') ? "Jantan" : "Betina");
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: k == sp.translate('male_label') ? 6 : 0, left: k == sp.translate('female_label') ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => jenisKelamin = (k == sp.translate('male_label') ? "Jantan" : "Betina")),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? _purple : (isDark ? const Color(0xFF1E1E2C) : _white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? _purple : (isDark ? Colors.white12 : _grey300), width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(k == sp.translate('male_label') ? Icons.male_rounded : Icons.female_rounded, color: isSel ? _white : _grey600, size: 20),
                    const SizedBox(width: 6),
                    Text(k, style: GoogleFonts.poppins(color: isSel ? _white : (isDark ? Colors.white : _purpleDark), fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: ras, label: "Ras", hint: "Contoh: Persia, Poodle",
            icon: Icons.category_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? sp.translate('ras_req') : null,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: umur, label: "Umur (bulan)", hint: "Contoh: 12",
            icon: Icons.cake_outlined, keyboardType: TextInputType.number, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? sp.translate('age_req') : null,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _StyledTextField(
            controller: ciriWarna, label: "Ciri / Warna", hint: "Contoh: Putih dengan bercak hitam",
            icon: Icons.palette_outlined, isRequired: true,
            validator: (v) => (v == null || v.isEmpty) ? sp.translate('color_req') : null,
            isDark: isDark,
          ),
        ])),
        const SizedBox(height: 14),
        _GlassCard(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.note_alt_outlined, sp.translate('additional_notes_label'), isDark),
          const SizedBox(height: 6),
          Text(sp.translate('optional_hint'), style: GoogleFonts.poppins(fontSize: 11, color: isDark ? Colors.white38 : _grey600, fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          TextFormField(
            controller: catatan,
            maxLines: 3,
            maxLength: 500,
            style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white : _purpleDark),
            decoration: InputDecoration(
              hintText: sp.translate('complaint_hint'),
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white24 : _grey600.withOpacity(0.6)),
              filled: true, fillColor: isDark ? _purple.withOpacity(0.1) : _purpleBg.withOpacity(0.5),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : _grey300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : _grey300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _purple, width: 1.5)),
              counterStyle: GoogleFonts.poppins(color: isDark ? Colors.white38 : _grey600),
            ),
          ),
        ])),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isDark ? [_purple.withOpacity(0.2), _purpleAccent.withOpacity(0.05)] : [_purple.withOpacity(0.08), _purpleAccent.withOpacity(0.12)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _purpleAccent.withOpacity(0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.receipt_long_rounded, color: isDark ? _purpleAccent : _purple, size: 18),
              const SizedBox(width: 8),
              Text(sp.translate('booking_summary_title'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? _purpleAccent : _purple)),
            ]),
            const Divider(height: 20, color: _purpleAccent),
            _summaryRow(sp.translate('label_service'), selectedService?.name ?? "-", isDark),
            _summaryRow(sp.translate('step_schedule').split('&')[0].trim(), "drh. ${selectedDoctor?.name ?? '-'}", isDark),
            _summaryRow(sp.translate('visit_date_label').split(' ')[0], "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}", isDark),
            _summaryRow(sp.translate('visit_time_label').split(' ')[0], selectedTime, isDark),
            const Divider(height: 16, color: _purpleAccent),
            Row(children: [
              Text(sp.translate('fee_label') + ":", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _purpleDark)),
              const Spacer(),
              Text(selectedService?.formattedPrice ?? "-", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? _purpleAccent : _purple)),
            ]),
          ]),
        ),
      ])),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text("$label:", style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white54 : _grey600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _purpleDark), textAlign: TextAlign.end)),
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

  Widget _buildBottomButtons(SettingsProvider sp) {
    final isDark = sp.isDarkMode;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2C) : _white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: (isDark ? Colors.black : _purple).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))]),
      child: Row(children: [
        if (_currentStep > 0) Expanded(child: OutlinedButton.icon(
          onPressed: _prevStep,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(sp.translate('back_btn'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(foregroundColor: isDark ? _purpleAccent : _purple, side: BorderSide(color: isDark ? _purpleAccent : _purple, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
              submitting ? "Memproses..." : (_currentStep < 2 ? sp.translate('next_btn') : sp.translate('book_now_btn')),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _white, disabledBackgroundColor: _purpleAccent, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 3, shadowColor: _purple.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(IconData icon, String title, bool isDark) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? _purple.withOpacity(0.15) : _purpleBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isDark ? _purpleAccent : _purple, size: 20)),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : _purpleDark)),
    ]);
  }
}

// ── Reusable Widgets ──
class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, this.isDark = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2C) : _white.withOpacity(0.92), borderRadius: BorderRadius.circular(20), border: Border.all(color: _purpleAccent.withOpacity(0.3)), boxShadow: [BoxShadow(color: (isDark ? Colors.black : _purple).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))]),
      child: child,
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _RequiredLabel({required this.label, this.isDark = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : _purpleDark)),
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
  final bool isDark;
  const _StyledTextField({required this.controller, required this.label, required this.hint, required this.icon, this.keyboardType = TextInputType.text, this.validator, this.isRequired = false, this.isDark = false});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : _purpleDark)),
        if (isRequired) Text(" *", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
      ]),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType, validator: validator,
        style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : _purpleDark),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white24 : _grey600.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: isDark ? _purpleAccent : _purpleLight, size: 20),
          filled: true, fillColor: isDark ? _purple.withOpacity(0.1) : _purpleBg.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : _grey300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : _grey300)),
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
  final bool isDark;
  const _StyledDropdown({required this.label, required this.value, required this.items, required this.onChanged, required this.icon, this.isDark = false});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : _purpleDark)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: isDark ? _purple.withOpacity(0.1) : _purpleBg.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white12 : _grey300)),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          value: value, items: items, onChanged: onChanged, isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? _purpleAccent : _purple),
          style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : _purpleDark),
          dropdownColor: isDark ? const Color(0xFF1E1E2C) : _white,
          borderRadius: BorderRadius.circular(14),
        )),
      ),
    ]);
  }
}
