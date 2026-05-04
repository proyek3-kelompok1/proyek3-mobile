import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../models/message_model.dart';
import '../../core/services/consultation_api.dart';
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

class ChatPage extends StatefulWidget {
  final ConsultationModel? session;
  final DoctorModel? doctor;
  final bool isDoctor;

  const ChatPage({
    super.key,
    this.session,
    this.doctor,
    this.isDoctor = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];

  int? _consultationId;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;
  Timer? _statusPollTimer;
  Timer? _typingTimer;

  // Realtime state
  ConsultationModel? _liveSession;
  bool _isOtherTyping = false;

  @override
  void initState() {
    super.initState();
    _initConsultation();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    _statusPollTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_consultationId == null) return;
    // Notify server this user is typing (debounced)
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 800), () {
      if (_controller.text.trim().isNotEmpty) {
        ConsultationApi.sendTyping(_consultationId!);
      }
    });
  }

  Future<void> _initConsultation() async {
    try {
      if (widget.session != null) {
        _consultationId = widget.session!.id;
        _liveSession = widget.session;
      } else if (widget.doctor != null) {
        final consultation = await ConsultationApi.createConsultation(
          doctorId: widget.doctor!.id,
        );
        _consultationId = consultation.id;
        _liveSession = consultation;
      }

      if (_consultationId != null) {
        await _loadMessages();
        _startPolling();
        _startStatusPolling();
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _loadMessages();
    });
  }

  void _startStatusPolling() {
    // Poll online status + typing indicator every 3 seconds
    _statusPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_consultationId == null || !mounted) return;
      final session = await ConsultationApi.fetchConsultation(_consultationId!);
      if (session != null && mounted) {
        setState(() {
          _liveSession = session;
          _isOtherTyping = session.isTyping;
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    if (_consultationId == null) return;
    try {
      final msgs = await ConsultationApi.fetchMessages(_consultationId!);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(msgs);
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _consultationId == null || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    // Optimistic add
    final tempMsg = MessageModel(
      id: -1,
      senderType: widget.isDoctor ? 'doctor' : 'user',
      message: text,
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      await ConsultationApi.sendMessage(
        consultationId: _consultationId!,
        message: text,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        final sp = Provider.of<SettingsProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sp.translate('fail_send_chat').replaceAll('{error}', e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13131C) : const Color(0xFFF3EEFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(),
          if (_loading)
             Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                ),
              ),
            )
          else if (_error != null)
            Expanded(child: _buildError())
          else ...[
            Expanded(
              child: _messages.isEmpty
                   ? _buildEmptyChat()
                   : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildBubble(_messages[index]);
                      },
                    ),
            ),
            _buildInputBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final effectiveSession = _liveSession ?? widget.session;
    
    final title = widget.isDoctor
        ? (effectiveSession?.userName ?? sp.translate('patient'))
        : (effectiveSession?.doctorName != null
            ? "Dr. ${effectiveSession!.doctorName}"
            : (widget.doctor?.name != null
                ? "Dr. ${widget.doctor!.name}"
                : "Dr. ${effectiveSession?.userName ?? 'Dokter'}"));

    final bool isOnline = effectiveSession?.isOnline ?? widget.doctor?.isOnline ?? false;

    // Subtitle: mengetik > online > offline
    String subTitle;
    if (_isOtherTyping) {
      subTitle = sp.translate('typing') != 'typing' ? sp.translate('typing') : 'Sedang mengetik...';
    } else {
      subTitle = isOnline ? sp.translate('online') : sp.translate('offline');
    }

    final avatarUrl = widget.isDoctor
        ? effectiveSession?.userAvatar
        : (effectiveSession?.doctorAvatar ?? effectiveSession?.userAvatar ?? widget.doctor?.photoUrl);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _purple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
              child: const Icon(Icons.arrow_back_rounded, color: _white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _white.withOpacity(0.2),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person_rounded, color: _white, size: 20) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: _white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    subTitle,
                    key: ValueKey(subTitle),
                    style: GoogleFonts.poppins(
                      color: _isOtherTyping
                          ? Colors.greenAccent
                          : (isOnline ? Colors.greenAccent : _white.withOpacity(0.7)),
                      fontSize: 11,
                      fontWeight: (_isOtherTyping || isOnline) ? FontWeight.bold : FontWeight.normal,
                      fontStyle: _isOtherTyping ? FontStyle.italic : FontStyle.normal,
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

  Widget _buildEmptyChat() {
    final sp = Provider.of<SettingsProvider>(context);
    final isDark = sp.isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: _purple, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              sp.translate('start_consultation'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _purpleDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sp.translate('start_chat_desc').replaceAll('{name}', widget.doctor?.name ?? _liveSession?.doctorName ?? widget.session?.doctorName ?? "Dokter"),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.white70 : _grey600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final sp = Provider.of<SettingsProvider>(context);
    final isDark = sp.isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _purpleAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              sp.translate('fail_start_chat'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : _purpleDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? "",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: _grey600),
            ),
            const SizedBox(height: 16),
            Text(
              "⚠️ Fitur ini membutuhkan backend Laravel.\n"
              "Pastikan tabel 'consultations' & 'consultation_messages'\n"
              "sudah dibuat di database Laravel.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _grey600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(MessageModel msg) {
    final myRole = widget.isDoctor ? 'doctor' : 'user';
    final isMe = msg.senderType == myRole;
    final effectiveSession = _liveSession ?? widget.session;

    final otherAvatarUrl = widget.isDoctor
        ? effectiveSession?.userAvatar
        : (effectiveSession?.doctorAvatar ?? effectiveSession?.userAvatar ?? widget.doctor?.photoUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _purpleBg,
              backgroundImage: otherAvatarUrl != null ? NetworkImage(otherAvatarUrl) : null,
              child: otherAvatarUrl == null ? const Icon(Icons.person_rounded, color: _purple, size: 16) : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? Theme.of(context).primaryColor : Colors.black).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.message,
                    style: GoogleFonts.poppins(
                      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  if (msg.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(msg.createdAt!),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white.withOpacity(0.6)
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            msg.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: msg.isRead ? Colors.blueAccent : _white.withOpacity(0.6),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  Widget _buildInputBar() {
    final sp = Provider.of<SettingsProvider>(context);
    final isDark = sp.isDarkMode;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: sp.translate('type_message'),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: (isDark ? Colors.white : Theme.of(context).colorScheme.onSurface).withOpacity(0.5),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
