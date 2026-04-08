import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/queue_api.dart';

const _purple = Color(0xFF4A3298);
const _purpleDark = Color(0xFF2E1D6B);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey100 = Color(0xFFF5F5F5);
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class QueueListPage extends StatefulWidget {
  final String? initialBookingCode;
  const QueueListPage({super.key, this.initialBookingCode});

  @override
  State<QueueListPage> createState() => _QueueListPageState();
}

class _QueueListPageState extends State<QueueListPage> with TickerProviderStateMixin {
  final _bookingCodeController = TextEditingController();
  Timer? _refreshTimer;
  late AnimationController _pulseController;

  DateTime _selectedDate = DateTime.now();
  String _serviceFilter = 'all';
  bool _loadingQueue = true;
  bool _checkingQueue = false;
  String? _lastUpdate;

  // Queue data
  List<Map<String, dynamic>> _queueList = [];
  Map<String, dynamic>? _currentServing;
  Map<String, dynamic> _queueStats = {
    'total': 0,
    'waiting': 0,
    'completed': 0,
    'serving': 0,
    'estimated_wait_minutes': 0,
  };

  // My queue result
  Map<String, dynamic>? _myQueueResult;
  String? _myQueueError;

  final Map<String, String> _serviceNames = {
    'general': 'Konsultasi Umum',
    'vaccination': 'Vaksinasi',
    'grooming': 'Grooming',
    'dental': 'Perawatan Gigi',
    'surgery': 'Operasi',
    'laboratory': 'Laboratorium',
    'inpatient': 'Rawat Inap',
    'emergency': 'Darurat',
    'vaksinasi': 'Vaksinasi',
    'konsultasi_umum': 'Konsultasi Umum',
    'perawatan_gigi': 'Perawatan Gigi',
    'pemeriksaan_darah': 'Pemeriksaan Darah',
    'sterilisasi': 'Sterilisasi',
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.initialBookingCode != null) {
      _bookingCodeController.text = widget.initialBookingCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkMyQueue();
      });
    }

    _loadQueueData();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadQueueData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _bookingCodeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _getServiceName(String type) {
    return _serviceNames[type] ?? type;
  }

  Future<void> _loadQueueData() async {
    try {
      final data = await QueueApi.fetchQueueData(
        date: _formatDate(_selectedDate),
        serviceType: _serviceFilter,
      );

      if (!mounted) return;

      setState(() {
        _loadingQueue = false;
        if (data['success'] == true) {
          _queueList = List<Map<String, dynamic>>.from(data['today_queue'] ?? []);
          _currentServing = data['current_queue'];
          _queueStats = Map<String, dynamic>.from(data['queue_stats'] ?? {});
        }
        final now = DateTime.now();
        _lastUpdate = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingQueue = false;
        _lastUpdate = "Error";
      });
    }
  }

  Future<void> _checkMyQueue() async {
    if (_bookingCodeController.text.trim().isEmpty) return;

    setState(() {
      _checkingQueue = true;
      _myQueueResult = null;
      _myQueueError = null;
    });

    try {
      final data = await QueueApi.checkMyQueue(
        bookingCode: _bookingCodeController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _checkingQueue = false;
        if (data['success'] == true) {
          _myQueueResult = data['data'];
        } else {
          _myQueueError = data['message'] ?? 'Kode booking tidak ditemukan';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingQueue = false;
        _myQueueError = 'Gagal memproses permintaan. Pastikan kode booking benar.';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple,
            onPrimary: _white,
            surface: _white,
            onSurface: _purpleDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadQueueData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purpleBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadQueueData,
              color: _purple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    _buildCheckQueueCard(),
                    if (_myQueueResult != null || _myQueueError != null) ...[
                      const SizedBox(height: 12),
                      _buildMyQueueResult(),
                    ],
                    const SizedBox(height: 16),
                    _buildRealtimeHeader(),
                    const SizedBox(height: 12),
                    _buildFilterRow(),
                    const SizedBox(height: 14),
                    _buildStatsRow(),
                    const SizedBox(height: 14),
                    _buildQueueTable(),
                    const SizedBox(height: 14),
                    _buildStatusLegend(),
                    const SizedBox(height: 14),
                    _buildInfoSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_list_numbered_rounded, color: _white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Info Antrian Klinik",
                      style: GoogleFonts.poppins(
                        color: _white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Pantau antrian real-time dan perkiraan waktu tunggu",
                  style: GoogleFonts.poppins(
                    color: _white.withOpacity(0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckQueueCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF03A9F4).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF03A9F4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _white, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Cek Antrian Saya",
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masukkan Kode Booking",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _purpleDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bookingCodeController,
                        style: GoogleFonts.poppins(fontSize: 14, color: _purpleDark),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: "Contoh: GRM20251229001",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _grey600.withOpacity(0.6),
                          ),
                          prefixIcon: const Icon(Icons.confirmation_number_outlined, color: _purpleLight, size: 20),
                          filled: true,
                          fillColor: _purpleBg.withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        ),
                        onFieldSubmitted: (_) => _checkMyQueue(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _checkingQueue ? null : _checkMyQueue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: _white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          shadowColor: _purple.withOpacity(0.4),
                        ),
                        child: _checkingQueue
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(_white),
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Kode booking dapat ditemukan di halaman konfirmasi pemesanan",
                  style: GoogleFonts.poppins(fontSize: 10, color: _grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQueueResult() {
    if (_myQueueError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _myQueueError!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    if (_myQueueResult == null) return const SizedBox();

    final booking = Map<String, dynamic>.from(_myQueueResult!['booking'] ?? {});
    final queueInfo = Map<String, dynamic>.from(_myQueueResult!['queue_info'] ?? {});

    String statusText = 'MENUNGGU';
    Color statusColor = const Color(0xFFFF9800);

    switch (booking['status']) {
      case 'confirmed':
        statusText = 'SEDANG DILAYANI';
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'completed':
        statusText = 'SELESAI';
        statusColor = _grey600;
        break;
      case 'cancelled':
        statusText = 'DIBATALKAN';
        statusColor = Colors.red;
        break;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_rounded, color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 8),
                Text(
                  "Informasi Antrian Anda",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _queueInfoRow("No. Antrian", "A${(booking['nomor_antrian'] ?? 0).toString().padLeft(3, '0')}"),
                      _queueInfoRow("Kode Booking", booking['booking_code'] ?? '-'),
                      _queueInfoRow("Hewan", booking['nama_hewan'] ?? '-'),
                      _queueInfoRow("Layanan", _getServiceName(booking['service_type'] ?? '')),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _queueInfoRow("Posisi Antrian", queueInfo['current_position'] != null ? "Ke-${queueInfo['current_position']}" : "-"),
                      _queueInfoRow("Sedang Dilayani", queueInfo['current_serving'] != null ? "A${queueInfo['current_serving'].toString().padLeft(3, '0')}" : "-"),
                      _queueInfoRow("Estimasi Tunggu", "${queueInfo['estimated_wait_minutes'] ?? 0} menit"),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status", style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _grey600)),
          const SizedBox(height: 1),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _purpleDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.access_time_filled_rounded, color: _purple, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Antrian Real-time",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _purpleDark,
            ),
          ),
        ),
        if (_lastUpdate != null)
          Text(
            _lastUpdate!,
            style: GoogleFonts.poppins(fontSize: 10, color: _grey600),
          ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            setState(() => _loadingQueue = true);
            _loadQueueData();
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.refresh_rounded, color: _purple, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _grey300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: _purple, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _purpleDark,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _purpleLight, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _grey300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _serviceFilter,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _purpleLight),
                style: GoogleFonts.poppins(fontSize: 13, color: _purpleDark),
                dropdownColor: _white,
                borderRadius: BorderRadius.circular(14),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('Semua', style: GoogleFonts.poppins(fontSize: 13))),
                  DropdownMenuItem(value: 'general', child: Text('Konsultasi', style: GoogleFonts.poppins(fontSize: 13))),
                  DropdownMenuItem(value: 'vaccination', child: Text('Vaksinasi', style: GoogleFonts.poppins(fontSize: 13))),
                  DropdownMenuItem(value: 'grooming', child: Text('Grooming', style: GoogleFonts.poppins(fontSize: 13))),
                  DropdownMenuItem(value: 'dental', child: Text('Gigi', style: GoogleFonts.poppins(fontSize: 13))),
                  DropdownMenuItem(value: 'surgery', child: Text('Operasi', style: GoogleFonts.poppins(fontSize: 13))),
                  DropdownMenuItem(value: 'laboratory', child: Text('Lab', style: GoogleFonts.poppins(fontSize: 13))),
                  DropdownMenuItem(value: 'emergency', child: Text('Darurat', style: GoogleFonts.poppins(fontSize: 13))),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _serviceFilter = v);
                    _loadQueueData();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        // Currently Serving
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_rounded, color: Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Sedang Dilayani",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_currentServing != null) ...[
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.6 + (_pulseController.value * 0.4),
                        child: Text(
                          "A${(_currentServing!['nomor_antrian'] ?? 0).toString().padLeft(3, '0')}",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      );
                    },
                  ),
                  Text(
                    _currentServing!['nama_hewan'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 11, color: _grey600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _getServiceName(_currentServing!['service_type'] ?? ''),
                    style: GoogleFonts.poppins(fontSize: 9, color: _grey600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    "-",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _grey300,
                    ),
                  ),
                  Text(
                    "Tidak ada antrian",
                    style: GoogleFonts.poppins(fontSize: 10, color: _grey600),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Queue Stats
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF03A9F4).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF03A9F4).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups_rounded, color: Color(0xFF03A9F4), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Info Antrian",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF01579B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "${_queueStats['total'] ?? 0}",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _purple,
                            ),
                          ),
                          Text(
                            "Total",
                            style: GoogleFonts.poppins(fontSize: 9, color: _grey600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "${_queueStats['estimated_wait_minutes'] ?? 0}",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                          Text(
                            "Menit",
                            style: GoogleFonts.poppins(fontSize: 9, color: _grey600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tunggu: ${_queueStats['waiting'] ?? 0}",
                      style: GoogleFonts.poppins(fontSize: 9, color: _grey600),
                    ),
                    Text(
                      "Selesai: ${_queueStats['completed'] ?? 0}",
                      style: GoogleFonts.poppins(fontSize: 9, color: _grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purpleAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: _purpleDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                _tableHeaderCell("No.", flex: 2),
                _tableHeaderCell("Layanan", flex: 3),
                _tableHeaderCell("Hewan", flex: 3),
                _tableHeaderCell("Waktu", flex: 2),
                _tableHeaderCell("Status", flex: 2),
              ],
            ),
          ),
          // Table Body
          if (_loadingQueue)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(_purple),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Memuat data antrian...",
                    style: GoogleFonts.poppins(fontSize: 11, color: _grey600),
                  ),
                ],
              ),
            )
          else if (_queueList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, color: _grey300, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "Tidak ada antrian untuk tanggal ini",
                    style: GoogleFonts.poppins(fontSize: 12, color: _grey600),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_queueList.length, (i) {
              final item = _queueList[i];
              final isCurrent = _currentServing != null &&
                  _currentServing!['id'] == item['id'];
              return _buildQueueRow(item, isCurrent, i);
            }),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildQueueRow(Map<String, dynamic> item, bool isCurrent, int index) {
    final status = item['status'] ?? 'pending';
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (status) {
      case 'confirmed':
        statusBgColor = const Color(0xFF4CAF50).withOpacity(0.15);
        statusTextColor = const Color(0xFF4CAF50);
        statusLabel = 'Dilayani';
        break;
      case 'completed':
        statusBgColor = _grey600.withOpacity(0.15);
        statusTextColor = _grey600;
        statusLabel = 'Selesai';
        break;
      case 'cancelled':
        statusBgColor = Colors.red.withOpacity(0.15);
        statusTextColor = Colors.red;
        statusLabel = 'Batal';
        break;
      default:
        statusBgColor = const Color(0xFFFF9800).withOpacity(0.15);
        statusTextColor = const Color(0xFFFF9800);
        statusLabel = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF4CAF50).withOpacity(0.08)
            : (index % 2 == 0 ? _white : _purpleBg.withOpacity(0.4)),
        border: Border(
          bottom: BorderSide(color: _grey300.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "A${(item['nomor_antrian'] ?? 0).toString().padLeft(3, '0')}",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? const Color(0xFF4CAF50) : _purpleDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF03A9F4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getServiceName(item['service_type'] ?? ''),
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w500, color: const Color(0xFF01579B)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item['nama_hewan'] ?? '-',
              style: GoogleFonts.poppins(fontSize: 11, color: _purpleDark),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['booking_time'] ?? '-',
              style: GoogleFonts.poppins(fontSize: 11, color: _grey600),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: statusTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Dilayani", const Color(0xFF4CAF50)),
        const SizedBox(width: 12),
        _legendItem("Menunggu", const Color(0xFFFF9800)),
        const SizedBox(width: 12),
        _legendItem("Selesai", _grey600),
        const SizedBox(width: 12),
        _legendItem("Batal", Colors.red),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 9, color: _grey600),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purpleBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _purple, size: 16),
              const SizedBox(width: 6),
              Text(
                "Informasi Penting",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            "Antrian diperbarui otomatis setiap 30 detik",
            "Datang 15 menit sebelum perkiraan waktu antrian Anda",
            "Perkiraan waktu tunggu dapat berubah tergantung kondisi",
            "Pastikan membawa hewan dalam carrier atau menggunakan tali",
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: GoogleFonts.poppins(fontSize: 10, color: _purpleDark, fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(fontSize: 10, color: _purpleDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
