import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

const _purple = Color(0xFF4A3298);
const _purpleDark = Color(0xFF2E1D6B);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class BookingHistoryPage extends StatefulWidget {
  final String? initialEmail;
  const BookingHistoryPage({super.key, this.initialEmail});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final _emailController = TextEditingController();
  List<dynamic> bookings = [];
  bool loading = false;
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _search();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_emailController.text.isEmpty) return;
    setState(() { loading = true; hasSearched = true; });
    try {
      final res = await http.get(
        Uri.parse("${ApiConstants.bookingHistory}?email=${_emailController.text}"),
        headers: {"Accept": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() { bookings = data['data'] ?? []; loading = false; });
      } else {
        setState(() { bookings = []; loading = false; });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() { bookings = []; loading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'completed': return const Color(0xFF4CAF50);
      case 'cancelled': return Colors.red;
      default: return _grey600;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Menunggu';
      case 'confirmed': return 'Dilayani';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_top_rounded;
      case 'confirmed': return Icons.play_circle_rounded;
      case 'completed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purpleBg,
      body: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_purpleDark, _purple, _purpleLight]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_rounded, color: _white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Riwayat Booking", style: GoogleFonts.poppins(color: _white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text("Cek status pemesanan Anda", style: GoogleFonts.poppins(color: _white.withOpacity(0.75), fontSize: 11)),
            ])),
          ]),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Masukkan Email", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _purpleDark)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "contoh@email.com",
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: _grey600.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.email_outlined, color: _purpleLight, size: 20),
                      filled: true, fillColor: _purpleBg.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _grey300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _grey300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _purple, width: 1.5)),
                    ),
                    onFieldSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: loading ? null : _search,
                  style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_white)))
                      : const Icon(Icons.search_rounded, size: 22),
                ),
              ]),
            ]),
          ),
        ),
        // Results
        Expanded(
          child: loading
              ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_purple)))
              : !hasSearched
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history_rounded, size: 64, color: _purpleAccent.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text("Masukkan email untuk melihat\nriwayat booking", style: GoogleFonts.poppins(fontSize: 13, color: _grey600), textAlign: TextAlign.center),
                    ]))
                  : bookings.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.inbox_rounded, size: 64, color: _purpleAccent.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text("Tidak ada riwayat booking", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _grey600)),
                          Text("untuk email ini", style: GoogleFonts.poppins(fontSize: 12, color: _grey600)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: bookings.length,
                          itemBuilder: (_, i) => _buildBookingCard(bookings[i]),
                        ),
        ),
      ]),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final status = b['status'] ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor(status).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header with status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          ),
          child: Row(children: [
            Icon(_statusIcon(status), color: _statusColor(status), size: 18),
            const SizedBox(width: 8),
            Text(_statusLabel(status), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(status))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text("A${(b['nomor_antrian'] ?? 0).toString().padLeft(3, '0')}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _purple)),
            ),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Kode Booking", style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
                Text(b['booking_code'] ?? '-', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _purple)),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("Layanan", style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
                Text(b['service_name'] ?? '-', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _purpleDark)),
              ])),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1, color: _grey300),
            const SizedBox(height: 10),
            Row(children: [
              _infoChip(Icons.pets_rounded, "${b['nama_hewan'] ?? '-'} (${b['jenis_hewan'] ?? '-'})"),
              const Spacer(),
              _infoChip(Icons.calendar_today_rounded, b['booking_date'] ?? '-'),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _infoChip(Icons.person_rounded, b['doctor_name'] ?? '-'),
              const Spacer(),
              _infoChip(Icons.schedule_rounded, b['booking_time'] ?? '-'),
            ]),
            if (b['total_price'] != null && b['total_price'] > 0) ...[
              const SizedBox(height: 10),
              Row(children: [
                Text("Total:", style: GoogleFonts.poppins(fontSize: 12, color: _grey600)),
                const Spacer(),
                Text("Rp ${_formatNumber(b['total_price'])}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _purple)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: _purpleLight),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.poppins(fontSize: 11, color: _purpleDark)),
    ]);
  }

  String _formatNumber(dynamic n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
