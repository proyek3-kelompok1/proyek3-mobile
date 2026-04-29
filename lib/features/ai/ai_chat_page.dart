import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/shimmer_loading.dart';

// ──────────────────────────────────────────────────────────
//  PALETTE
// ──────────────────────────────────────────────────────────
const _purple      = Color(0xFF4A1059);
const _purpleDark  = Color(0xFF4A1059);
const _purpleLight = Color(0xFF7C5CBF);
const _purpleAccent= Color(0xFFB39DDB);
const _purpleBg    = Color(0xFFF3EEFF);
const _white       = Colors.white;
const _grey600     = Color(0xFF757575);
const _teal        = Color(0xFF00B4A6);
const _amber       = Color(0xFFFFB347);

// ──────────────────────────────────────────────────────────
//  QUICK SUGGESTIONS  ← tampilin di bawah chat
// ──────────────────────────────────────────────────────────
const _suggestions = [
  ('🐱', 'Kucing saya tidak mau makan dan lemas'),
  ('🐶', 'Anjing saya muntah dan diare sejak tadi pagi'),
  ('🐾', 'Hewan saya demam dan batuk sudah 2 hari'),
  ('🐰', 'Kelinci saya ada luka dan terlihat lesu'),
  ('💊', 'Cara pemberian obat cacing yang benar?'),
  ('🧴', 'Tips merawat bulu hewan agar tidak rontok'),
];

// ──────────────────────────────────────────────────────────
//  MODEL
// ──────────────────────────────────────────────────────────
class _ChatMsg {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? imageUrl;
  final File? imageFile;

  _ChatMsg({
    required this.text,
    required this.isUser,
    DateTime? time,
    this.imageUrl,
    this.imageFile,
  }) : time = time ?? DateTime.now();

  factory _ChatMsg.fromJson(Map<String, dynamic> json) {
    String timeStr = json['created_at'] ?? '';
    DateTime parsedTime;
    
    try {
      if (timeStr.contains('T') || timeStr.contains('Z')) {
        parsedTime = DateTime.parse(timeStr).toLocal();
      } else {
        parsedTime = DateTime.parse("${timeStr.replaceFirst(' ', 'T')}Z").toLocal();
      }
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return _ChatMsg(
      text: json['message'] ?? '',
      isUser: json['is_user'] == 1 || json['is_user'] == true,
      time: parsedTime,
      imageUrl: json['image_url'], // Support jika ada url gambar dari history
    );
  }
}

// ──────────────────────────────────────────────────────────
//  PAGE
// ──────────────────────────────────────────────────────────
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  final _controller       = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isTyping          = false;
  bool _isLoadingHistory  = true;
  bool _showSuggestions   = true;
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isVisionSupported = true; // Akan diupdate dari respon server

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Load history
  Future<void> _loadChatHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final token = await _token();
      if (token == null) { setState(() => _isLoadingHistory = false); return; }

      final res = await http.get(
        Uri.parse(ApiConstants.aiHistory),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _messages
            ..clear()
            ..addAll(data.map((m) => _ChatMsg.fromJson(m)));
          _isLoadingHistory  = false;
          _showSuggestions   = _messages.isEmpty;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (_) {
      setState(() => _isLoadingHistory = false);
    }
  }

  // ── Delete history
  Future<void> _deleteHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Riwayat Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Semua riwayat percakapan akan dihapus permanen. Yakin?',
          style: GoogleFonts.poppins(fontSize: 13, color: _grey600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: _grey600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: GoogleFonts.poppins(color: _white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _messages.clear();
      _showSuggestions = true;
    });

    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse(ApiConstants.aiDeleteHistory),
        headers: {
          'Authorization': 'Bearer $token', 
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Riwayat chat berhasil dihapus ✨', style: GoogleFonts.poppins()),
            backgroundColor: _purple,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error Delete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menghapus riwayat di server', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isVisionSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur gambar tidak tersedia dalam mode Groq')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Text('Kirim Foto ke DokterPaw',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _purpleDark)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickOption(Icons.camera_alt_rounded, 'Kamera', ImageSource.camera),
                _pickOption(Icons.photo_library_rounded, 'Galeri', ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _purpleBg,
              shape: BoxShape.circle,
              border: Border.all(color: _purple.withOpacity(0.1)),
            ),
            child: Icon(icon, color: _purple, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _purpleDark)),
        ],
      ),
    );
  }

  // ── Send message
  Future<void> _sendMessage([String? prefilled]) async {
    final text = prefilled ?? _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    String? base64Image;
    File? imageToDisplay = _selectedImage;
    
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    setState(() {
      _messages.add(_ChatMsg(
        text: text, 
        isUser: true,
        imageFile: imageToDisplay,
      ));
      _isTyping        = true;
      _showSuggestions = false;
      _selectedImage   = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse(ApiConstants.aiChat),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': text,
          'image': base64Image,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        if (data['provider'] == 'groq') {
          setState(() => _isVisionSupported = false);
        } else {
          setState(() => _isVisionSupported = true);
        }

        setState(() {
          _messages.add(_ChatMsg(text: data['message'], isUser: false));
          _isTyping = false;
        });
      } else {
        _addError('Terjadi kesalahan (${res.statusCode}). Coba lagi ya!');
      }
    } catch (_) {
      _addError('Koneksi terputus. Pastikan server aktif dan coba lagi.');
    }
    _scrollToBottom();
  }

  void _addError(String msg) => setState(() {
    _messages.add(_ChatMsg(text: msg, isUser: false));
    _isTyping = false;
  });

  void _scrollToBottom() => Future.delayed(const Duration(milliseconds: 120), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ────────────────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purpleBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const ShimmerList(itemCount: 6)
                : _messages.isEmpty
                    ? _buildWelcome()
                    : _buildMessageList(),
          ),
          if (_isTyping) _buildTyping(),
          if (_showSuggestions && !_isTyping) _buildSuggestionBar(),
          _buildActionButtons(),
          _buildInput(),
        ],
      ),
    );
  }

  // ── Action Buttons (Refresh & Clear)
  Widget _buildActionButtons() {
    if (_messages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _miniActionBtn(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            onTap: _loadChatHistory,
          ),
          const SizedBox(width: 8),
          _miniActionBtn(
            icon: Icons.delete_outline_rounded,
            label: 'Hapus Chat',
            color: Colors.red.withOpacity(0.7),
            onTap: _deleteHistory,
          ),
        ],
      ),
    );
  }

  Widget _miniActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _purple.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? _purpleLight),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color ?? _purpleLight,
                )),
          ],
        ),
      ),
    );
  }

  // ── AppBar — branded, veterinary clinic style
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, 
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 75,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A1059), Color(0xFF4A1059)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x404A3298),
              blurRadius: 15,
              offset: Offset(0, 5),
            )
          ],
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _white,
                shape: BoxShape.circle,
                border: Border.all(color: _white.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/dokterpaw.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.pets, color: _purple, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DokterPaw',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF69F0AE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Assisten Virtual DVPets',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, color: _white, size: 28),
          ),
        ),
      ],
    );
  }

  // ── Welcome state
  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        children: [
          // Ilustrasi
          // Logo Tengah DokterPaw
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icons/dokterpaw.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.pets, size: 42, color: _purple),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Selamat Datang di Klinik Virtual DVPets',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w700, color: _purpleDark)),
          const SizedBox(height: 6),
          Text('Ceritakan kondisi hewan kesayanganmu.\n DokterPaw siap membantu diagnosa & memberikan saran.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5, color: _grey600, height: 1.6)),
          const SizedBox(height: 20),
          // Statistik kecil
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statBadge('35+', 'Jenis Penyakit'),
              const SizedBox(width: 12),
              _statBadge('74.68%', 'Akurasi Diagnosis'),
              const SizedBox(width: 12),
              _statBadge('Cepat', 'Konsultasi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withOpacity(0.15)),
        boxShadow: [BoxShadow(
          color: _purple.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value,
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700, color: _purple)),
          Text(label,
            style: GoogleFonts.poppins(fontSize: 9.5, color: _grey600)),
        ],
      ),
    );
  }

  // ── Message list
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _MessageTile(message: _messages[i]),
    );
  }

  // ── Typing indicator
  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _avatar(false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _Dot(delay: 0),
              const SizedBox(width: 4),
              _Dot(delay: 200),
              const SizedBox(width: 4),
              _Dot(delay: 400),
              const SizedBox(width: 8),
              Text('Sedang menganalisa...',
                style: GoogleFonts.poppins(
                  fontSize: 11, fontStyle: FontStyle.italic, color: _grey600)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Suggestion chips bar (horizontal scroll)
  Widget _buildSuggestionBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 6),
          child: Text('Coba tanyakan:',
            style: GoogleFonts.poppins(
              fontSize: 11.5, fontWeight: FontWeight.w600,
              color: _purpleLight, letterSpacing: 0.3)),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _suggestions.length,
            itemBuilder: (_, i) {
              final (emoji, text) = _suggestions[i];
              return GestureDetector(
                onTap: () => _sendMessage(text),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _purple.withOpacity(0.25), width: 1),
                    boxShadow: [BoxShadow(
                      color: _purple.withOpacity(0.07),
                      blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(text,
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: _purpleDark,
                          fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Input bar
  Widget _buildInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 90,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover, width: 74, height: 74),
                  ),
                ),
                Positioned(
                  right: 4, top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(
              color: _purple.withOpacity(0.12),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _showPickOptions,
                icon: Icon(
                  Icons.camera_alt_rounded,
                  color: _isVisionSupported ? _purple : Colors.grey.shade400,
                ),
                tooltip: _isVisionSupported ? 'Kirim Gambar' : 'Mode Vision Terbatas',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.poppins(fontSize: 14),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan kondisi hewan kamu...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: _grey600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: _white, size: 20),
                  onPressed: () => _sendMessage(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar(bool isUser) {
    if (isUser) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: _purpleDark,
        child: Icon(Icons.person, size: 16, color: _white),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: Image.asset(
          'assets/icons/dokterpaw.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.pets, size: 16, color: _purple),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  ANIMATED DOT
// ──────────────────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}
class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.delay > 0) {
      _ctrl.stop();
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _ctrl.repeat(reverse: true);
      });
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 7, height: 7,
      decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
    ),
  );
}

// ──────────────────────────────────────────────────────────
//  MESSAGE TILE
// ──────────────────────────────────────────────────────────
class _MessageTile extends StatelessWidget {
  final _ChatMsg message;
  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_buildAvatar(false), const SizedBox(width: 8)],
          Flexible(child: _buildBubble(isUser)),
          if (isUser) ...[const SizedBox(width: 8), _buildAvatar(true)],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    if (isUser) {
      return Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: _purpleAccent,
          shape: BoxShape.circle,
          border: Border.all(color: _white, width: 2),
        ),
        child: const Icon(Icons.person_rounded, size: 14, color: _white),
      );
    }
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: _white, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/dokterpaw.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.pets, size: 14, color: _purple),
        ),
      ),
    );
  }

  Widget _buildBubble(bool isUser) {
    final lines = message.text.split('\n');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? _purple : _white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.imageFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(message.imageFile!, width: 200, fit: BoxFit.cover),
              ),
            ),
          ...lines.map((l) => _renderLine(l, isUser)),
          const SizedBox(height: 3),
          Text(
            '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: isUser ? _white.withOpacity(0.55) : _grey600),
          ),
        ],
      ),
    );
  }

  Widget _renderLine(String line, bool isUser) {
    final t = line.trim();
    if (t.isEmpty) return const SizedBox(height: 4);

    final isNumbered  = RegExp(r'^\d+\.').hasMatch(t);
    final isDashItem  = t.startsWith('- ') || t.startsWith('• ');

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        left: (isNumbered || isDashItem) ? 6 : 0),
      child: Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          height: 1.55,
          color: isUser ? _white : Colors.black87,
          fontWeight: isNumbered ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}
