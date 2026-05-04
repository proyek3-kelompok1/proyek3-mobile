import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';

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

// ──────────────────────────────────────────────────────────
//  QUICK SUGGESTIONS
// ──────────────────────────────────────────────────────────
const _suggestions = [
  ('🐱', 'suggest_cat'),
  ('🐶', 'suggest_dog'),
  ('🐾', 'suggest_pet_fever'),
  ('🐰', 'suggest_rabbit'),
  ('💊', 'suggest_worm_med'),
  ('🧴', 'suggest_groom_tips'),
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
      imageUrl: json['image_url'],
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
  bool _isVisionSupported = true;

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

  Future<void> _deleteHistory() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(settingsProvider.translate('delete_history_title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(settingsProvider.translate('delete_history_confirm'),
          style: GoogleFonts.poppins(fontSize: 13, color: _grey600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(settingsProvider.translate('cancel'), style: GoogleFonts.poppins(color: _grey600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(settingsProvider.translate('delete'), style: GoogleFonts.poppins(color: _white, fontWeight: FontWeight.w600)),
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
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(settingsProvider.translate('history_deleted')),
            backgroundColor: _purple,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isVisionSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode Vision Terbatas (Sedang Maintenance)')),
      );
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (_) {}
  }

  void _showPickOptions() {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : _white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Text(sp.translate('send_photo_to_ai'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pickOption(Icons.camera_alt_rounded, sp.translate('camera_label'), ImageSource.camera, isDark),
                  _pickOption(Icons.photo_library_rounded, sp.translate('gallery_label'), ImageSource.gallery, isDark),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _pickOption(IconData icon, String label, ImageSource source, bool isDark) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); _pickImage(source); },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? _purple.withOpacity(0.2) : _purpleBg, shape: BoxShape.circle),
            child: Icon(icon, color: isDark ? Colors.white : _purple, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _sendMessage([String? prefilled]) async {
    final originalText = prefilled ?? _controller.text.trim();
    if (originalText.isEmpty && _selectedImage == null) return;

    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final isEnglish = sp.locale.languageCode == 'en';
    final textForAi = isEnglish ? "Please respond in English: $originalText" : originalText;

    String? base64Image;
    File? imageToDisplay = _selectedImage;
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    setState(() {
      _messages.add(_ChatMsg(text: originalText, isUser: true, imageFile: imageToDisplay));
      _isTyping = true;
      _showSuggestions = false;
      _selectedImage = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse(ApiConstants.aiChat),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'message': textForAi, 'image': base64Image}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _messages.add(_ChatMsg(text: data['message'], isUser: false));
          _isTyping = false;
          _isVisionSupported = data['provider'] != 'groq';
        });
      } else {
        _addError(sp.translate('chat_error_status').replaceAll('{code}', res.statusCode.toString()));
      }
    } catch (_) {
      _addError(sp.translate('connection_error'));
    }
    _scrollToBottom();
  }

  void _addError(String msg) => setState(() { _messages.add(_ChatMsg(text: msg, isUser: false)); _isTyping = false; });

  void _scrollToBottom() => Future.delayed(const Duration(milliseconds: 120), () {
    if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13131C) : const Color(0xFFF3EEFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, sp, isDark),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const ShimmerList(itemCount: 6)
                : _messages.isEmpty
                    ? _buildWelcome(sp)
                    : _buildMessageList(),
          ),
          if (_isTyping) _buildTyping(sp),
          if (_showSuggestions && !_isTyping) _buildSuggestionBar(sp),
          _buildActionButtons(sp),
          _buildInput(sp, context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, SettingsProvider sp, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13131C) : _purple,
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
            child: ClipOval(child: Image.asset('assets/icons/dokterpaw.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: _purple, size: 20))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('DokterPaw', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              Text(sp.translate('virtual_assistant'), style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(SettingsProvider sp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _purple.withOpacity(0.2), blurRadius: 20)]),
            child: ClipOval(child: Image.asset('assets/icons/dokterpaw.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40, color: _purple))),
          ),
          const SizedBox(height: 20),
          Text(sp.translate('welcome_virtual_clinic'), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(sp.translate('chatbot_desc'), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: _grey600, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _MessageTile(message: _messages[i]),
    );
  }

  Widget _buildTyping(SettingsProvider sp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Column(
          children: [
            const _ThinkingAnimation(),
            const SizedBox(height: 8),
            Text(
              sp.translate('analyzing'),
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00E676),
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildSuggestionBar(SettingsProvider sp) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (_, i) {
          final (emoji, key) = _suggestions[i];
          final text = sp.translate(key);
          return GestureDetector(
            onTap: () => _sendMessage(text),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _purple.withOpacity(0.1))),
              child: Row(children: [Text(emoji), const SizedBox(width: 6), Text(text, style: GoogleFonts.poppins(fontSize: 11))]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(SettingsProvider sp) {
    if (_messages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _miniActionBtn(Icons.refresh_rounded, sp.translate('refresh'), _loadChatHistory),
          const SizedBox(width: 8),
          _miniActionBtn(Icons.delete_outline_rounded, sp.translate('delete_chat'), _deleteHistory, color: Colors.red),
        ],
      ),
    );
  }

  Widget _miniActionBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: _purple.withOpacity(0.05))),
        child: Row(children: [Icon(icon, size: 12, color: color ?? _purpleLight), const SizedBox(width: 4), Text(label, style: GoogleFonts.poppins(fontSize: 9, color: color ?? _purpleLight))]),
      ),
    );
  }

  Widget _buildInput(SettingsProvider sp, BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding > 0 ? bottomPadding + 8 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, height: 80, width: 80, fit: BoxFit.cover)),
                  Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setState(() => _selectedImage = null), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)))),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(onPressed: _showPickOptions, icon: Icon(Icons.camera_alt_rounded, color: _isVisionSupported ? _purple : Colors.grey)),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: _purple.withOpacity(0.1))),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: InputDecoration(hintText: sp.translate('tell_pet_condition'), hintStyle: GoogleFonts.poppins(fontSize: 12, color: _grey600), border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendMessage(),
                child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Deleted duplicate _addError
}



class _ThinkingAnimation extends StatefulWidget {
  const _ThinkingAnimation();

  @override
  State<_ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<_ThinkingAnimation> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    ));

    _animations = _controllers.map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    )).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      _controllers[i].repeat(reverse: true);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _animations[i],
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(_animations[i].value),
              borderRadius: BorderRadius.circular(2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(_animations[i].value * 0.4),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                )
              ],
            ),
          );
        },
      )),
    );
  }
}

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
          if (!isUser) ...[
            Container(width: 28, height: 28, decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle), child: const Icon(Icons.pets, size: 14, color: Colors.white)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? _purple : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imageFile != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(message.imageFile!, width: 150))),
                  Text(message.text, style: GoogleFonts.poppins(fontSize: 13, color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
