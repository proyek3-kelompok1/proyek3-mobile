import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/consultation_api.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../models/consultation_model.dart';
import '../consultation/chat_page.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../education/page/education_list_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  String _doctorName = "Dokter";
  List<ConsultationModel> _allConsultations = [];
  List<ConsultationModel> _filteredConsultations = [];
  Map<int, String> _chatLabels = {};
  List<int> _archivedConsultationIds = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
    _loadLabelsAndArchived();
    _fetchConsultations();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadLabelsAndArchived() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load labels
    final String? labelsJson = prefs.getString('chat_labels');
    if (labelsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(labelsJson);
      setState(() {
        _chatLabels = decoded.map((key, value) => MapEntry(int.parse(key), value.toString()));
      });
    }

    // Load archived IDs (previously called hidden_consultations)
    final List<String>? archivedList = prefs.getStringList('hidden_consultations');
    if (archivedList != null) {
      setState(() {
        _archivedConsultationIds = archivedList.map((e) => int.parse(e)).toList();
      });
    }
  }

  Future<void> _saveLabel(int id, String label) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (label.isEmpty) {
        _chatLabels.remove(id);
      } else {
        _chatLabels[id] = label;
      }
    });
    final Map<String, String> toSave = _chatLabels.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('chat_labels', jsonEncode(toSave));
  }

  Future<void> _archiveConsultation(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _archivedConsultationIds.add(id);
      });
      await prefs.setStringList('hidden_consultations', _archivedConsultationIds.map((e) => e.toString()).toList());
      
      if (mounted) {
        final sp = Provider.of<SettingsProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sp.translate('consultation_archived'))),
        );
      }
      _fetchConsultations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e")),
        );
      }
    }
  }

  Future<void> _unarchiveConsultation(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _archivedConsultationIds.remove(id);
      });
      await prefs.setStringList('hidden_consultations', _archivedConsultationIds.map((e) => e.toString()).toList());
      
      if (mounted) {
        final sp = Provider.of<SettingsProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sp.translate('consultation_unarchived'))),
        );
      }
      _fetchConsultations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e")),
        );
      }
    }
  }

  void _showLabelDialog(int id, String currentLabel) {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final controller = TextEditingController(text: currentLabel);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sp.translate('give_label'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: sp.translate('label_hint')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(sp.translate('cancel'))),
          ElevatedButton(
            onPressed: () {
              _saveLabel(id, controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A1059)),
            child: Text(sp.translate('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showArchiveConfirm(int id) {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sp.translate('archive')),
        content: Text("${sp.translate('archive')} chat ini?"), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(sp.translate('cancel'))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _archiveConsultation(id);
            },
            child: Text(sp.translate('archive'), style: const TextStyle(color: Color(0xFF4A1059), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredConsultations = _allConsultations.where((c) {
        return c.userName.toLowerCase().contains(query) ||
               (c.lastMessage?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _fetchConsultations() async {
    setState(() => _isLoading = true);
    try {
      final data = await ConsultationApi.fetchSessions();
      // Sort by updatedAt descending (newest first)
      data.sort((a, b) {
        if (a.updatedAt == null) return 1;
        if (b.updatedAt == null) return -1;
        return b.updatedAt!.compareTo(a.updatedAt!);
      });
      
      setState(() {
        // Current View: All minus archived
        _allConsultations = data.where((c) => !_archivedConsultationIds.contains(c.id)).toList();
        _filteredConsultations = _allConsultations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching: $e");
    }
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final primary = Theme.of(context).primaryColor;
    final primaryDark = Theme.of(context).colorScheme.secondary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            _buildHeader(primaryDark, primary, settingsProvider),
            Expanded(
              child: TabBarView(
                children: [
                  _buildConsultationBody(settingsProvider),
                  const EducationListPage(isDoctorView: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationBody(SettingsProvider settingsProvider) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).primaryColor;
    final isDark = settingsProvider.isDarkMode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: isDark ? Colors.white38 : Colors.grey[400], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(color: onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: settingsProvider.translate('search_patient'),
                      hintStyle: GoogleFonts.poppins(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settingsProvider.translate('consultation_list'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              // Archive Button
              IconButton(
                onPressed: () => _showArchiveBottomSheet(settingsProvider),
                icon: Icon(Icons.archive_outlined, color: primary),
                tooltip: settingsProvider.translate('archive_list'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchConsultations,
            child: _isLoading 
              ? const ShimmerList(itemCount: 6)
              : _filteredConsultations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredConsultations.length,
                      itemBuilder: (context, index) {
                        final session = _filteredConsultations[index];
                        return _buildConsultationCard(session, primary, settingsProvider);
                      },
                    ),
          ),
        ),
      ],
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.archive_rounded, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      sp.translate('archive_list'),
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<ConsultationModel>>(
                  future: ConsultationApi.fetchSessions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final archived = snapshot.data?.where((c) => _archivedConsultationIds.contains(c.id)).toList() ?? [];
                    if (archived.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.archive_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(sp.translate('no_archived_chats'), style: GoogleFonts.poppins(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: archived.length,
                      itemBuilder: (context, index) {
                        final session = archived[index];
                        return _buildConsultationCard(session, Theme.of(context).primaryColor, sp, isArchivedView: true);
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

  Widget _buildHeader(Color dark, Color primary, SettingsProvider sp) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 15,
        left: 24,
        right: 24,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
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
                    sp.translate('welcome_doctor').replaceAll('{name}', ''),
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "$_doctorName",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelPadding: const EdgeInsets.only(bottom: 10),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: sp.translate('konsultasi')),
              Tab(text: sp.translate('education_title')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationModel session, Color primary, SettingsProvider sp, {bool isArchivedView = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(sp.isDarkMode ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: sp.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isArchivedView) return; // Optional: disable chat in archive view unless unarchived
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(session: session, isDoctor: true),
              ),
            ).then((_) => _fetchConsultations());
          },
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(sp.translate('give_label')),
                    onTap: () {
                      Navigator.pop(context);
                      _showLabelDialog(session.id, _chatLabels[session.id] ?? "");
                    },
                  ),
                  ListTile(
                    leading: Icon(isArchivedView ? Icons.unarchive_outlined : Icons.archive_outlined, color: isArchivedView ? Colors.green : Colors.red),
                    title: Text(isArchivedView ? sp.translate('unarchive') : sp.translate('archive'), style: TextStyle(color: isArchivedView ? Colors.green : Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      if (isArchivedView) {
                        _unarchiveConsultation(session.id);
                        Navigator.pop(context); // Close bottom sheet
                      } else {
                        _showArchiveConfirm(session.id);
                      }
                    },
                  ),
                ],
              ),
            );
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
                          Row(
                            children: [
                              Text(
                                session.userName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (_chatLabels.containsKey(session.id))
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _chatLabels[session.id]!,
                                    style: GoogleFonts.poppins(fontSize: 10, color: primary, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
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
                                color: session.unreadCount > 0 ? onSurface : onSurface.withOpacity(0.6),
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
            decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum ada konsultasi",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
