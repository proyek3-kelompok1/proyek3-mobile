import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/doctor_model.dart';
import '../../core/services/doctor_api.dart';
import '../../models/consultation_model.dart';
import '../../core/services/consultation_api.dart';
import 'chat_page.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';

// ──────────────────────────────────────────────────────────
//  COLOUR PALETTE
// ──────────────────────────────────────────────────────────
const _purple = Color(0xFF4A1059);
const _purpleDark = Color(0xFF4A1059);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> with SingleTickerProviderStateMixin {
  late Future<List<DoctorModel>> _doctorFuture;
  late Future<List<ConsultationModel>> _chatFuture;
  late TabController _tabController;
  List<int> _archivedChatIds = [];
  int _unreadCount = 0;
  int _archivedUnreadCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _doctorFuture = DoctorApi.fetchDoctors();
    _chatFuture = ConsultationApi.fetchSessions();
    _loadArchived();
    _calculateUnread();
    // Auto-refresh active consultations every 8 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _refreshChats();
    });
  }

  Future<void> _loadArchived() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? archivedList = prefs.getStringList('user_archived_consultations');
    if (archivedList != null) {
      setState(() {
        _archivedChatIds = archivedList.map((e) => int.parse(e)).toList();
      });
    }
  }

  Future<void> _calculateUnread() async {
    try {
      final sessions = await ConsultationApi.fetchSessions();
      int count = 0;
      int archivedCount = 0;
      for (var s in sessions) {
        if (!_archivedChatIds.contains(s.id)) {
          count += s.unreadCount;
        } else {
          archivedCount += s.unreadCount;
        }
      }
      setState(() {
        _unreadCount = count;
        _archivedUnreadCount = archivedCount;
      });
    } catch (_) {}
  }

  Future<void> _archiveChat(int id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _archivedChatIds.add(id);
    });
    await prefs.setStringList('user_archived_consultations', _archivedChatIds.map((e) => e.toString()).toList());
    _refreshChats();
  }

  Future<void> _unarchiveChat(int id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _archivedChatIds.remove(id);
    });
    await prefs.setStringList('user_archived_consultations', _archivedChatIds.map((e) => e.toString()).toList());
    _refreshChats();
  }

  void _refreshChats() {
    setState(() {
      _chatFuture = ConsultationApi.fetchSessions();
    });
    _calculateUnread();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context, settingsProvider),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDoctorList(settingsProvider, theme),
                _buildActiveChats(settingsProvider, theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SettingsProvider sp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131C) : _purple,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: _white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sp.translate('consultation_title'),
                      style: GoogleFonts.poppins(
                        color: _white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      sp.translate('ready_to_help'),
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showArchiveBottomSheet(sp),
                icon: Stack(
                  children: [
                    const Icon(Icons.archive_outlined, color: Colors.white),
                    if (_archivedUnreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: _purple, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: sp.translate('archive_list'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            indicatorColor: isDark ? const Color(0xFFC05DE3) : Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelPadding: const EdgeInsets.only(bottom: 12),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(text: sp.translate('cari_dokter')),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sp.translate('active_consultation')),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          _unreadCount > 9 ? "9+" : "$_unreadCount",
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList(SettingsProvider settingsProvider, ThemeData theme) {
    return FutureBuilder<List<DoctorModel>>(
      future: _doctorFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerList(itemCount: 6);
        }
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString(), settingsProvider, theme);
        
        final doctors = snapshot.data!;
        if (doctors.isEmpty) return _buildEmptyState(settingsProvider.translate('no_doctor_available'), theme);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 24),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _DoctorCard(
              doctor: doctors[index],
              onTap: () => _showStartChatDialog(doctors[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveChats(SettingsProvider sp, ThemeData theme, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async => _refreshChats(),
      child: FutureBuilder<List<ConsultationModel>>(
        future: _chatFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerList(itemCount: 6);
          }
          final sessions = snapshot.data?.where((c) => !_archivedChatIds.contains(c.id)).toList() ?? [];
          if (sessions.isEmpty) return _buildEmptyState(sp.translate('start_chat_now'), theme);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 24),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildConsultationCard(session, isDark, sp);
            },
          );
        },
      ),
    );
  }

  void _showArchiveBottomSheet(SettingsProvider sp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(sp.translate('archive_list'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<ConsultationModel>>(
                  future: ConsultationApi.fetchSessions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final archived = snapshot.data?.where((c) => _archivedChatIds.contains(c.id)).toList() ?? [];
                    if (archived.isEmpty) return Center(child: Text(sp.translate('no_archived_chats')));
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: archived.length,
                      itemBuilder: (context, index) {
                        return _buildConsultationCard(archived[index], Theme.of(context).brightness == Brightness.dark, sp, isArchived: true);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationModel session, bool isDark, SettingsProvider sp, {bool isArchived = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isArchived) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatPage(session: session, isDoctor: false)),
            ).then((_) => _refreshChats());
          },
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, color: isArchived ? Colors.green : Colors.red),
                    title: Text(isArchived ? sp.translate('unarchive') : sp.translate('archive'), style: TextStyle(color: isArchived ? Colors.green : Colors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isArchived) {
                        _unarchiveChat(session.id);
                        Navigator.pop(context); 
                      } else {
                        _archiveChat(session.id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _purple.withOpacity(0.1),
                      backgroundImage: session.userAvatar != null ? NetworkImage(session.userAvatar!) : null,
                      child: session.userAvatar == null ? const Icon(Icons.person, color: _purple) : null,
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 12, height: 12,
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
                          Text("Dr. ${session.userName}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                          if (session.updatedAt != null)
                            Text(_formatTime(session.updatedAt!), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.lastMessage ?? sp.translate('start_chat_now'),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12, 
                                color: session.unreadCount > 0 ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: session.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (session.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                session.unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) { return ''; }
  }

  Widget _buildErrorState(String error, SettingsProvider sp, ThemeData theme) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: _purpleAccent, size: 48),
      const SizedBox(height: 12),
      Text(sp.translate('retry'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
      Text(error, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
    ]));
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_off_rounded, color: _purpleAccent, size: 60),
      const SizedBox(height: 16),
      Text(message, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
    ]));
  }

  void _showStartChatDialog(DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          padding: EdgeInsets.only(top: 16, left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 4, decoration: BoxDecoration(color: _grey300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: _purpleBg, backgroundImage: doctor.photoUrl != null ? NetworkImage(doctor.photoUrl!) : null, child: doctor.photoUrl == null ? const Icon(Icons.person_rounded, color: _purple, size: 24) : null),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doctor.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface)),
                    Text(doctor.specialization, style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6))),
                  ])),
                ],
              ),
              const SizedBox(height: 20),
              Text(Provider.of<SettingsProvider>(context, listen: false).translate('consultation_confirm').replaceAll('{name}', doctor.name), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatPage(doctor: doctor, isDoctor: false)),
                    ).then((_) {
                      _refreshChats();
                      // Switch to active consultations tab
                      _tabController.animateTo(1);
                    });
                  },
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: Text(Provider.of<SettingsProvider>(context, listen: false).translate('start_consultation'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                      image: doctor.photoUrl != null ? DecorationImage(image: NetworkImage(doctor.photoUrl!), fit: BoxFit.cover) : null,
                    ),
                    child: doctor.photoUrl == null ? Icon(Icons.person_rounded, color: theme.primaryColor, size: 32) : null,
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: doctor.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doctor.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                Text(doctor.specialization, style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (doctor.schedule != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _purple.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.schedule_rounded, color: _purple, size: 12),
                            const SizedBox(width: 4),
                            Flexible(child: Text(doctor.schedule!, style: GoogleFonts.poppins(fontSize: 10, color: _purple, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ])),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: _purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.chat_rounded, color: _white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
