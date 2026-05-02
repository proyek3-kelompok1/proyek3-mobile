import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

const _purple = Color(0xFF4A1059);
const _purpleDark = Color(0xFF4A1059);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class QueuePage extends StatefulWidget {
  final String? bookingCode;
  const QueuePage({super.key, this.bookingCode});
  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final _codeController = TextEditingController();
  Map<String, dynamic>? myQueue;
  bool checkingQueue = false;
  bool loadingList = false;
  List<dynamic> queueList = [];
  Map<String, dynamic> stats = {};
  DateTime selectedDate = DateTime.now();
  String selectedService = "all";

  final serviceFilters = {
    "all": "Semua Layanan",
    "general": "Konsultasi Umum",
    "vaccination": "Vaksinasi",
    "grooming": "Grooming",
    "dental": "Perawatan Gigi",
    "surgery": "Operasi",
    "laboratory": "Laboratorium",
  };

  @override
  void initState() {
    super.initState();
    if (widget.bookingCode != null) {
      _codeController.text = widget.bookingCode!;
      _checkMyQueue();
    }
    _loadQueueList();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkMyQueue() async {
    if (_codeController.text.isEmpty) return;
    setState(() => checkingQueue = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.checkQueue),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: json.encode({"booking_code": _codeController.text}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() { myQueue = data['data']; checkingQueue = false; });
      } else {
        setState(() { myQueue = null; checkingQueue = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Kode booking tidak ditemukan"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (e) {
      setState(() { myQueue = null; checkingQueue = false; });
    }
  }

  Future<void> _loadQueueList() async {
    setState(() => loadingList = true);
    try {
      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      final url = "${ApiConstants.queueList}?date=$dateStr&service_type=$selectedService";
      final res = await http.get(Uri.parse(url), headers: {"Accept": "application/json"});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          queueList = data['data']?['bookings'] ?? [];
          stats = data['data']?['stats'] ?? {};
          loadingList = false;
        });
      } else {
        setState(() { queueList = []; stats = {}; loadingList = false; });
      }
    } catch (e) {
      debugPrint("Error loading queue: $e");
      setState(() { queueList = []; stats = {}; loadingList = false; });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'completed': return const Color(0xFF4CAF50);
      case 'cancelled': return Colors.red;
      default: return _grey600;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'Menunggu';
      case 'confirmed': return 'Dilayani';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Batal';
      default: return s;
    }
  }

  String _serviceLabel(String s) {
    const m = {'general': 'Umum', 'vaccination': 'Vaksinasi', 'grooming': 'Grooming', 'dental': 'Gigi', 'surgery': 'Operasi', 'laboratory': 'Lab', 'inpatient': 'Rawat', 'emergency': 'Darurat'};
    return m[s] ?? s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purpleBg,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(children: [
            _buildCheckSection(),
            if (myQueue != null) _buildMyQueueResult(),
            const SizedBox(height: 16),
            _buildQueueListSection(),
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_purpleDark, _purple, _purpleLight]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back_rounded, color: _white, size: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Info Antrian Klinik", style: GoogleFonts.poppins(color: _white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text("Pantau antrian real-time", style: GoogleFonts.poppins(color: _white.withOpacity(0.75), fontSize: 11)),
        ])),
        GestureDetector(
          onTap: _loadQueueList,
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.refresh_rounded, color: _white, size: 22)),
        ),
      ]),
    );
  }

  Widget _buildCheckSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _purple.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.search_rounded, color: _purple, size: 20),
          const SizedBox(width: 8),
          Text("Cek Antrian Saya", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _purple)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _codeController,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Masukkan kode booking...",
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: _grey600.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.confirmation_number_outlined, color: _purpleLight, size: 20),
                filled: true, fillColor: _purpleBg.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _grey300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _grey300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _purple, width: 1.5)),
              ),
              onFieldSubmitted: (_) => _checkMyQueue(),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: checkingQueue ? null : _checkMyQueue,
            style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: checkingQueue
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_white)))
                : Text("Cek", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildMyQueueResult() {
    final booking = myQueue!['booking'];
    final info = myQueue!['queue_info'];
    final position = info['current_position'];
    final waitMins = info['estimated_wait_minutes'] ?? 0;
    final serving = info['current_serving'];

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Color(0xFF4CAF50), borderRadius: BorderRadius.vertical(top: Radius.circular(17))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person_pin_rounded, color: _white, size: 18),
            const SizedBox(width: 8),
            Text("Antrian Anda", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _white)),
          ]),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.05), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17))),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(children: [
                Text("Nomor Antrian", style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
                Text("A${(booking['nomor_antrian'] ?? 0).toString().padLeft(3, '0')}", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: _purple)),
              ])),
              Container(width: 1, height: 60, color: _grey300),
              Expanded(child: Column(children: [
                Text("Posisi", style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
                Text(position != null ? "#$position" : "-", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF4CAF50))),
              ])),
            ]),
            const SizedBox(height: 12),
            const Divider(color: _grey300),
            const SizedBox(height: 8),
            Row(children: [
              _queueInfoChip(Icons.hourglass_top_rounded, "Estimasi", "$waitMins mnt", Colors.orange),
              const SizedBox(width: 12),
              _queueInfoChip(Icons.play_circle_rounded, "Dilayani", serving != null ? "A${serving.toString().padLeft(3, '0')}" : "-", Colors.blue),
              const SizedBox(width: 12),
              _queueInfoChip(Icons.people_rounded, "Total", "${info['total_in_queue'] ?? 0}", _purple),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: _purple, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text("${booking['nama_hewan']} (${booking['jenis_hewan']}) • ${booking['booking_time']}", style: GoogleFonts.poppins(fontSize: 11, color: _purpleDark))),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _queueInfoChip(IconData icon, String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: _grey600)),
      ]),
    ));
  }

  Widget _buildQueueListSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Filters
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _purple.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [
          Row(children: [
            Icon(Icons.access_time_rounded, size: 18, color: _purple),
            const SizedBox(width: 8),
            Text("Antrian Real-time", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _purple)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _purple, onPrimary: _white)), child: child!));
                if (picked != null) { setState(() => selectedDate = picked); _loadQueueList(); }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _purpleAccent.withOpacity(0.5))),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: _purple),
                  const SizedBox(width: 8),
                  Text("${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _purpleDark)),
                ]),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: _purpleBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _purpleAccent.withOpacity(0.5))),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: selectedService, isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _purple, size: 20),
                style: GoogleFonts.poppins(fontSize: 12, color: _purpleDark),
                dropdownColor: _white, borderRadius: BorderRadius.circular(12),
                items: serviceFilters.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: GoogleFonts.poppins(fontSize: 12)))).toList(),
                onChanged: (v) { setState(() => selectedService = v!); _loadQueueList(); },
              )),
            )),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      // Stats row
      if (stats.isNotEmpty) Row(children: [
        _statCard("Antrian", "${stats['total'] ?? 0}", _purple),
        const SizedBox(width: 8),
        _statCard("Menunggu", "${stats['waiting'] ?? 0}", Colors.orange),
        const SizedBox(width: 8),
        _statCard("Dilayani", "${stats['serving'] ?? 0}", Colors.blue),
        const SizedBox(width: 8),
        _statCard("Selesai", "${stats['completed'] ?? 0}", const Color(0xFF4CAF50)),
      ]),
      const SizedBox(height: 12),
      // Queue table
      Container(
        decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _purple.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _purple, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Expanded(flex: 2, child: Text("No.", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _white))),
              Expanded(flex: 3, child: Text("Kode", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _white))),
              Expanded(flex: 3, child: Text("Layanan", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _white))),
              Expanded(flex: 2, child: Text("Waktu", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _white))),
              Expanded(flex: 2, child: Text("Status", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _white))),
            ]),
          ),
          if (loadingList)
            Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_purple)))
          else if (queueList.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              Icon(Icons.inbox_rounded, size: 40, color: _purpleAccent.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text("Tidak ada antrian", style: GoogleFonts.poppins(fontSize: 12, color: _grey600)),
            ]))
          else
            ...queueList.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: i % 2 == 0 ? _white : _purpleBg.withOpacity(0.3),
                  border: Border(bottom: BorderSide(color: _grey300.withOpacity(0.5))),
                ),
                child: Row(children: [
                  Expanded(flex: 2, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text("A${(q['nomor_antrian'] ?? 0).toString().padLeft(3, '0')}", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _purple), textAlign: TextAlign.center),
                  )),
                  Expanded(flex: 3, child: Text(q['booking_code'] ?? '-', style: GoogleFonts.poppins(fontSize: 10, color: _purpleDark), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 3, child: Text(_serviceLabel(q['service_type'] ?? ''), style: GoogleFonts.poppins(fontSize: 10, color: _purpleDark))),
                  Expanded(flex: 2, child: Text(q['booking_time'] ?? '-', style: GoogleFonts.poppins(fontSize: 10, color: _purpleDark))),
                  Expanded(flex: 2, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _statusColor(q['status'] ?? '').withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(_statusLabel(q['status'] ?? ''), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: _statusColor(q['status'] ?? '')), textAlign: TextAlign.center),
                  )),
                ]),
              );
            }),
        ]),
      ),
    ]);
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: _grey600)),
      ]),
    ));
  }
}
