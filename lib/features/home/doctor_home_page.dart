import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/consultation_api.dart';
import '../../models/consultation_model.dart';
import '../consultation/chat_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  String _doctorName = "Dokter";
  late Future<List<ConsultationModel>> _consultationsFuture;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
    _consultationsFuture = ConsultationApi.fetchSessions();
  }

  Future<void> _loadDoctorName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _doctorName = prefs.getString('user_name') ?? "Dokter";
    });
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C63FF);
    const primaryDark = Color(0xFF4A1059);
    const bg = Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(primaryDark, primary),
          _buildStatsRow(primary),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pesan Terbaru",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Lihat Semua",
                  style: GoogleFonts.poppins(fontSize: 12, color: primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _consultationsFuture = ConsultationApi.fetchSessions();
                });
              },
              child: FutureBuilder<List<ConsultationModel>>(
                future: _consultationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  final sessions = snapshot.data ?? [];
                  if (sessions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _buildConsultationCard(session, primary);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color dark, Color primary) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 30,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [dark, primary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selamat Datang kembali,",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "Dr. $_doctorName",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Cari pasien...",
                      hintStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                      border: InputBorder.none,
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

  Widget _buildStatsRow(Color primary) {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildStatCard("Total Pasien", "12", Icons.people_outline, primary),
            const SizedBox(width: 15),
            _buildStatCard("Konsultasi", "5", Icons.chat_bubble_outline, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 15),
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationModel session, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(session: session, isDoctor: true),
              ),
            ).then((_) => setState(() {
              _consultationsFuture = ConsultationApi.fetchSessions();
            }));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primary.withOpacity(0.1),
                      backgroundImage: session.userAvatar != null ? NetworkImage(session.userAvatar!) : null,
                      child: session.userAvatar == null ? Icon(Icons.person, color: primary, size: 30) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: session.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            session.userName,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (session.updatedAt != null)
                            Text(
                              _formatTime(session.updatedAt!),
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (session.lastMessage != null) ...[
                            _buildStatusTicks(session.lastMessageStatus),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              session.lastMessage ?? "Mulai percakapan...",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: session.unreadCount > 0 ? Colors.black87 : Colors.grey,
                                fontWeight: session.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (session.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                session.unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildStatusTicks(String? status) {
    if (status == 'read') {
      return const Icon(Icons.done_all, color: Colors.blue, size: 16);
    } else if (status == 'sent') {
      return const Icon(Icons.done, color: Colors.grey, size: 16);
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum ada konsultasi",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          const SizedBox(height: 5),
          Text(
            "Pesan dari pasien akan muncul di sini",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
