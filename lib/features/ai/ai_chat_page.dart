import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────
//  COLOUR PALETTE
// ──────────────────────────────────────────────────────────
const _purple = Color(0xFF4A3298);
const _purpleDark = Color(0xFF2E1D6B);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent = Color(0xFFB39DDB);
const _purpleBg = Color(0xFFF3EEFF);
const _white = Colors.white;
const _grey100 = Color(0xFFF5F5F5);
const _grey300 = Color(0xFFE0E0E0);
const _grey600 = Color(0xFF757575);

// ──────────────────────────────────────────────────────────
//  SIMPLE AI RESPONSES (offline / local)
// ──────────────────────────────────────────────────────────
final Map<String, String> _aiResponses = {
  'halo': 'Halo! 👋 Saya DVPets AI Assistant. Ada yang bisa saya bantu tentang hewan peliharaan Anda?',
  'hai': 'Hai! 😊 Saya siap membantu Anda tentang perawatan hewan peliharaan. Silakan bertanya!',
  'vaksin': '💉 Vaksinasi sangat penting untuk hewan peliharaan!\n\n'
      '🐱 Kucing: Vaksin pertama usia 6-8 minggu (Tricat/Tetracat)\n'
      '🐶 Anjing: Vaksin pertama usia 6-8 minggu (DHPPL)\n\n'
      'Pastikan jadwal vaksin teratur setiap tahun. Anda bisa booking vaksinasi melalui menu Booking!',
  'grooming': '✨ Tips Grooming:\n\n'
      '🐱 Kucing: Mandi 1-2x sebulan, sisir bulu 2-3x seminggu\n'
      '🐶 Anjing: Mandi 2-4x sebulan, potong kuku setiap 2 minggu\n\n'
      'Gunakan shampoo khusus hewan, jangan shampoo manusia!',
  'makan': '🍽️ Tips Makanan Hewan:\n\n'
      '• Berikan makanan sesuai usia dan berat badan\n'
      '• Sediakan air minum segar setiap hari\n'
      '• Hindari makanan manusia (cokelat, bawang, anggur)\n'
      '• Jadwal makan teratur 2-3x sehari',
  'sakit': '🏥 Tanda-tanda hewan sakit:\n\n'
      '• Tidak mau makan lebih dari 24 jam\n'
      '• Muntah atau diare berulang\n'
      '• Lesu dan tidak aktif\n'
      '• Demam (hidung kering & hangat)\n\n'
      'Segera konsultasi dengan dokter hewan jika menemukan gejala ini! Gunakan menu Consultation.',
  'kucing': '🐱 Tips Merawat Kucing:\n\n'
      '• Sediakan litter box bersih\n'
      '• Vaksinasi teratur\n'
      '• Sterilisasi usia 6+ bulan\n'
      '• Berikan mainan dan waktu bermain\n'
      '• Periksa kesehatan rutin ke dokter hewan',
  'anjing': '🐶 Tips Merawat Anjing:\n\n'
      '• Jalan-jalan teratur minimal 30 menit/hari\n'
      '• Vaksinasi dan obat cacing teratur\n'
      '• Latih perintah dasar (duduk, diam, kemari)\n'
      '• Sosialisasi sejak usia dini\n'
      '• Rawat gigi dan telinga secara rutin',
  'booking': '📅 Untuk booking layanan:\n\n'
      '1. Buka menu Booking di halaman Home\n'
      '2. Pilih layanan yang diinginkan\n'
      '3. Pilih dokter dan jadwal\n'
      '4. Isi data diri dan hewan\n'
      '5. Konfirmasi booking!\n\n'
      'Mudah dan cepat! 🚀',
  'konsultasi': '💬 Untuk konsultasi dengan dokter:\n\n'
      '1. Tap menu "Consultation" di halaman Home\n'
      '2. Pilih dokter yang tersedia\n'
      '3. Mulai chat dengan dokter\n\n'
      'Dokter kami siap membantu Anda! 👨‍⚕️',
};

String _getAiResponse(String input) {
  final lower = input.toLowerCase().trim();

  for (final entry in _aiResponses.entries) {
    if (lower.contains(entry.key)) {
      return entry.value;
    }
  }

  return '🤔 Terima kasih atas pertanyaannya!\n\n'
      'Saya adalah AI assistant untuk hewan peliharaan. '
      'Coba tanyakan tentang:\n\n'
      '• Vaksinasi\n'
      '• Grooming\n'
      '• Makanan hewan\n'
      '• Tanda hewan sakit\n'
      '• Tips kucing / anjing\n'
      '• Booking layanan\n'
      '• Konsultasi dokter\n\n'
      'Atau gunakan menu Consultation untuk bicara langsung dengan dokter hewan! 👨‍⚕️';
}

// ──────────────────────────────────────────────────────────
//  CHAT MESSAGE MODEL (local)
// ──────────────────────────────────────────────────────────
class _ChatMsg {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMsg({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

// ──────────────────────────────────────────────────────────
//  AI CHAT PAGE
// ──────────────────────────────────────────────────────────
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(_ChatMsg(
      text: 'Halo! 👋 Saya **DVPets AI Assistant**.\n\n'
          'Saya bisa membantu Anda tentang:\n'
          '🐾 Perawatan hewan peliharaan\n'
          '💉 Info vaksinasi\n'
          '✨ Tips grooming\n'
          '🏥 Tanda-tanda hewan sakit\n\n'
          'Silakan ketik pertanyaan Anda!',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMsg(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate AI thinking
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final response = _getAiResponse(text);
      setState(() {
        _messages.add(_ChatMsg(text: response, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    });
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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildQuickActions(),
          _buildInputBar(),
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
        bottom: 18,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: _white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DVPets AI",
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Online • Siap membantu",
                      style: GoogleFonts.poppins(
                        color: _white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMsg msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_purple, _purpleLight],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: _white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: (isUser ? _purple : Colors.black)
                        .withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.poppins(
                  color: isUser ? _white : _purpleDark,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_purple, _purpleLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.smart_toy_rounded, color: _white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + (i * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _purpleAccent.withOpacity(0.4 + (value * 0.6)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      '💉 Vaksinasi',
      '✨ Grooming',
      '🐱 Kucing',
      '🐶 Anjing',
      '🏥 Sakit',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  _controller.text = action.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                  _sendMessage();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _purpleAccent.withOpacity(0.4)),
                  ),
                  child: Text(
                    action,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _purpleDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
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
                hintText: "Ketik pertanyaan...",
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
              child: const Icon(Icons.send_rounded, color: _white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
