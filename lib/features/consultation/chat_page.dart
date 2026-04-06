import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/doctor_model.dart';
import '../../models/message_model.dart';
import '../../core/services/consultation_api.dart';

// ──────────────────────────────────────────────────────────
//  COLOUR PALETTE
// ──────────────────────────────────────────────────────────
const _purple = Color(0xFF4A3298);
const _purpleDark = Color(0xFF2E1D6B);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

class ChatPage extends StatefulWidget {
  final DoctorModel doctor;
  final String userName;
  final String userPhone;

  const ChatPage({
    super.key,
    required this.doctor,
    required this.userName,
    required this.userPhone,
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

  @override
  void initState() {
    super.initState();
    _initConsultation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initConsultation() async {
    try {
      final consultation = await ConsultationApi.createConsultation(
        doctorId: widget.doctor.id,
        userName: widget.userName,
        userPhone: widget.userPhone,
      );
      _consultationId = consultation.id;
      await _loadMessages();
      _startPolling();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    if (_consultationId == null) return;
    try {
      final msgs =
          await ConsultationApi.fetchMessages(_consultationId!);
      if (mounted) {
        setState(() => _messages
          ..clear()
          ..addAll(msgs));
      }
    } catch (_) {
      // Silent fail on polling
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _consultationId == null || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    // Optimistic add
    final tempMsg = MessageModel(
      id: -1,
      senderType: 'user',
      message: text,
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      await ConsultationApi.sendMessage(
        consultationId: _consultationId!,
        senderType: 'user',
        message: text,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim: $e"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
    return Scaffold(
      backgroundColor: _purpleBg,
      body: Column(
        children: [
          _buildHeader(),
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_purple),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purpleDark, _purple, _purpleLight],
        ),
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
              child: const Icon(Icons.arrow_back_rounded,
                  color: _white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Doctor photo
          CircleAvatar(
            radius: 20,
            backgroundColor: _white.withOpacity(0.2),
            backgroundImage: widget.doctor.photoUrl != null
                ? NetworkImage(widget.doctor.photoUrl!)
                : null,
            child: widget.doctor.photoUrl == null
                ? const Icon(Icons.person_rounded, color: _white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.doctor.specialization,
                  style: GoogleFonts.poppins(
                    color: _white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Online indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "Online",
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: _purple, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              "Mulai Konsultasi",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _purpleDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ketik pesan untuk memulai konsultasi\ndengan ${widget.doctor.name}",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _grey600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: _purpleAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              "Gagal memulai konsultasi",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _purpleDark,
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
    final isUser = msg.senderType == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _purpleBg,
              backgroundImage: widget.doctor.photoUrl != null
                  ? NetworkImage(widget.doctor.photoUrl!)
                  : null,
              child: widget.doctor.photoUrl == null
                  ? const Icon(Icons.person_rounded,
                      color: _purple, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _purple : _white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isUser ? _purple : Colors.black).withOpacity(0.08),
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
                      color: isUser ? _white : _purpleDark,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  if (msg.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(msg.createdAt!),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isUser
                            ? _white.withOpacity(0.6)
                            : _grey600.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
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
              style: GoogleFonts.poppins(fontSize: 14, color: _purpleDark),
              decoration: InputDecoration(
                hintText: "Ketik pesan...",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _grey600.withOpacity(0.5),
                ),
                filled: true,
                fillColor: _purpleBg.withOpacity(0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                gradient: const LinearGradient(
                  colors: [_purple, _purpleLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.3),
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
                        valueColor: AlwaysStoppedAnimation(_white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: _white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
