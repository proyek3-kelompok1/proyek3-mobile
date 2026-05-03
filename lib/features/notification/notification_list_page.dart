import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/providers/settings_provider.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.isDarkMode;
    final theme = Theme.of(context);
    
    const primaryColor = Color(0xFF4A1059);
    final bgColor = isDark ? const Color(0xFF13131C) : const Color(0xFFF8F7FF);
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              settingsProvider.translate('notifications'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF13131C) : primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        actions: [
          IconButton(
            onPressed: () => notificationService.markAllAsRead(),
            icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
            tooltip: settingsProvider.translate('mark_all_read'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<List<AppNotification>>(
        valueListenable: notificationService.notificationsNotifier,
        builder: (context, notifications, child) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      height: 80,
                      opacity: const AlwaysStoppedAnimation(0.2),
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.notifications_off_outlined, 
                        size: 80, 
                        color: isDark ? Colors.white24 : Colors.grey[400]
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    settingsProvider.translate('no_notifications'),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Semua kabar terbaru akan muncul di sini",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final grouped = _groupNotifications(notifications);

          return ListView.builder(
            itemCount: grouped.length,
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemBuilder: (context, index) {
              final group = grouped[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      _getDateHeader(group.date, settingsProvider),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFB39DDB) : primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ...group.items.map((notif) => _NotificationCard(
                    notif: notif,
                    isDark: isDark,
                    cardColor: cardColor,
                    primaryColor: primaryColor,
                  )),
                  const SizedBox(height: 10),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<_NotificationGroup> _groupNotifications(List<AppNotification> notifications) {
    final Map<DateTime, List<AppNotification>> groups = {};
    for (var n in notifications) {
      final date = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      if (!groups.containsKey(date)) {
        groups[date] = [];
      }
      groups[date]!.add(n);
    }
    
    final sortedDates = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedDates.map((d) => _NotificationGroup(date: d, items: groups[d]!)).toList();
  }

  String _getDateHeader(DateTime date, SettingsProvider sp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return "HARI INI";
    if (date == yesterday) return "KEMARIN";
    return "${date.day}/${date.month}/${date.year}";
  }
}

class _NotificationGroup {
  final DateTime date;
  final List<AppNotification> items;
  _NotificationGroup({required this.date, required this.items});
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notif;
  final bool isDark;
  final Color cardColor;
  final Color primaryColor;

  const _NotificationCard({
    required this.notif,
    required this.isDark,
    required this.cardColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: notif.isRead 
            ? Colors.transparent 
            : (isDark ? const Color(0xFF4A1059).withOpacity(0.3) : primaryColor.withOpacity(0.1)),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Optional: Mark as read on tap if not already
            if (!notif.isRead) {
              NotificationService().markAsRead(notif.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading Icon/Logo
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notif.isRead 
                        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]) 
                        : (isDark ? primaryColor.withOpacity(0.2) : const Color(0xFFF3EEFF)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    height: 24,
                    width: 24,
                    color: notif.isRead 
                        ? (isDark ? Colors.white24 : Colors.grey[400]) 
                        : (isDark ? const Color(0xFFB39DDB) : primaryColor),
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.notifications_active_rounded,
                      color: notif.isRead 
                          ? (isDark ? Colors.white24 : Colors.grey[400]) 
                          : (isDark ? const Color(0xFFB39DDB) : primaryColor),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: GoogleFonts.poppins(
                                fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif.body,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(notif.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white24 : Colors.grey[400],
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

  String _formatTimestamp(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}

