import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../widgets/app_drawer.dart';
import '../widgets/main_navigation.dart';

// ─── MODELS ──────────────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime time;
  final bool isVoice;
  final String? imagePath; // local file path for image bubbles
  ChatMessage({
    required this.text,
    required this.role,
    DateTime? time,
    this.isVoice = false,
    this.imagePath,
  }) : time = time ?? DateTime.now();
}

// ─── THEME ────────────────────────────────────────────────────────────────────

const _kRed        = Color(0xFFE53935);
const _kRedDark    = Color(0xFFC62828);
const _kRedLight   = Color(0xFFFFEBEE);
const _kRedBorder  = Color(0x40E53935);
const _kRedGlow    = Color(0x4DE53935);
const _kRedShadow  = Color(0x55E53935);
const _kBlue       = Color(0xFF1E40AF);
const _kBlueMid    = Color(0xFF2563EB);
const _kBlueShadow = Color(0x401E40AF);
const _kBlueBorder = Color(0x331E40AF);
const _kBg         = Color(0xFFF0F4FF);
const _kWhite      = Color(0xFFFFFFFF);
const _kWhite85    = Color(0xD9FFFFFF);
const _kWhite65    = Color(0xA6FFFFFF);
const _kWhite20    = Color(0x33FFFFFF);
const _kGrey       = Color(0xFF90A4AE);
const _kGreyLight  = Color(0xFFECEFF1);
const _kTextDark   = Color(0xFF1A237E);
const _kShadowSm   = Color(0x10000000);
const _kShadowMd   = Color(0x16000000);
const _kGreen      = Color(0xFF00C853);
const _kCardBg     = Color(0xFFFFFFFF);

// ─── API ─────────────────────────────────────────────────────────────────────
final String _kGroqKey = dotenv.env['GROQ_API_KEY'] ?? '';// 🔑 console.groq.com → FREE

const _kSystemPrompt =
    'You are Sika, a warm and compassionate AI support companion for SickleCare Cameroon — '
    'a health app for people living with sickle cell disease (SCD) in Cameroon. '
    'Listen deeply and respond with genuine empathy and warmth. '
    'Provide comfort, encouragement and emotional support. '
    'Share practical SCD wellness guidance: hydration, avoiding cold, rest, nutrition. '
    'Detect the user language (French or English) and reply in the SAME language. '
    'Remind users you are not a replacement for their doctor when relevant. '
    'NEVER prescribe medication, suggest dosages, or diagnose conditions. '
    'If the user shares an image, describe what you observe and relate it to SCD wellness if relevant. '
    'Tone: Warm, caring — like a knowledgeable friend who truly understands SCD. '
    'End with gentle encouragement. Keep responses concise for mobile.';

const _kSuggestions = [
  "I'm in pain today 😔",
  "What triggers a crisis?",
  "How much water daily? 💧",
  "I feel anxious 😟",
  "Foods to avoid? 🍎",
  "Comment gérer la douleur?",
];

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with TickerProviderStateMixin {
  final _textCtrl    = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _messages    = <ChatMessage>[];

  bool _loading     = false;
  bool _showChips   = true;
  bool _isListening = false;
  String _voiceDraft = '';

  // Pending image (chosen but not yet sent)
  String? _pendingImagePath;
  String? _pendingImageB64;

  // Speech
  final _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  // Image picker
  final _picker = ImagePicker();

  // Animations
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;
  late final AnimationController _micCtrl;
  late final Animation<double>   _micAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _micCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _micAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _micCtrl, curve: Curves.easeInOut));

    _initSpeech();

    _messages.add(ChatMessage(
      text: "Hi there! I'm Sika 🩸 — your SickleCare companion.\n\n"
            "I'm here to listen, comfort, and support you through life "
            "with sickle cell disease.\n\nShare what you're feeling — "
            "by typing, using your voice 🎙️, or sending a photo 📷. 💙",
      role: MessageRole.assistant,
    ));
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => dev.log('Speech error: $e', name: 'SupportScreen'),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    _micCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  // ── Voice ──────────────────────────────────────────────────────────────────

  void _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_voiceDraft.trim().isNotEmpty) {
        _send(_voiceDraft.trim(), isVoice: true);
        _voiceDraft = '';
      }
    } else {
      if (!_speechAvailable) return;
      setState(() {
        _isListening = true;
        _voiceDraft  = '';
      });
      await _speech.listen(
        onResult: (r) => setState(() => _voiceDraft = r.recognizedWords),
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  // ── Image Picker ───────────────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _kGreyLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              Text('Send a photo to Sika',
                  style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _imageSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 68, height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kRed, _kRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: _kRedGlow, blurRadius: 12, offset: Offset(0, 4))
                ],
              ),
              child: Icon(icon, color: _kWhite, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark)),
          ],
        ),
      );

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // close sheet first
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pendingImagePath = picked.path;
      _pendingImageB64  = base64Encode(bytes);
    });
  }

  // ── Groq API ───────────────────────────────────────────────────────────────

  Future<void> _send(String text, {bool isVoice = false}) async {
    final trimmed  = text.trim();
    final hasText  = trimmed.isNotEmpty;
    final hasImage = _pendingImageB64 != null;

    if ((!hasText && !hasImage) || _loading) return;

    final imgPathSnap = _pendingImagePath;
    final imgB64Snap  = _pendingImageB64;

    setState(() {
      _messages.add(ChatMessage(
        text:      hasText ? trimmed : '📷 Photo',
        role:      MessageRole.user,
        isVoice:   isVoice,
        imagePath: imgPathSnap,
      ));
      _loading          = true;
      _showChips        = false;
      _pendingImagePath = null;
      _pendingImageB64  = null;
    });
    _textCtrl.clear();
    _scrollToBottom();

    try {
      // Use vision model when image is present
      final useVision = imgB64Snap != null;
      final model = useVision
          ? 'meta-llama/llama-4-scout-17b-16e-instruct'
          : 'llama-3.3-70b-versatile';

      // Build user content (multimodal if vision)
      dynamic userContent;
      if (useVision) {
        userContent = [
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$imgB64Snap'},
          },
          {
            'type': 'text',
            'text': hasText
                ? trimmed
                : 'Please look at this image and respond helpfully in the context of sickle cell disease wellness.',
          },
        ];
      } else {
        userContent = trimmed;
      }

      // History: last 10 text-only messages for context
      final start =
          (_messages.length - 1 - 10).clamp(0, _messages.length - 1);
      final history = <Map<String, dynamic>>[];
      for (int i = start; i < _messages.length - 1; i++) {
        final m = _messages[i];
        history.add({
          'role':    m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.text,
        });
      }

      final msgs = <Map<String, dynamic>>[
        {'role': 'system', 'content': _kSystemPrompt},
        ...history,
        {'role': 'user', 'content': userContent},
      ];

      final res = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type':  'application/json',
              'Authorization': 'Bearer $_kGroqKey',
            },
            body: jsonEncode({
              'model':       model,
              'messages':    msgs,
              'max_tokens':  1024,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 45));

      dev.log('Groq status: ${res.statusCode}', name: 'SupportScreen');

      if (res.statusCode == 200) {
        final reply = jsonDecode(
            res.body)['choices'][0]['message']['content'] as String;
        setState(() => _messages
            .add(ChatMessage(text: reply, role: MessageRole.assistant)));
      } else {
        final errMsg =
            jsonDecode(res.body)['error']?['message'] ?? 'Error';
        _addError(errMsg);
      }
    } on Exception catch (e) {
      _addError('$e');
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _addError(String detail) => _messages.add(ChatMessage(
      text: "Couldn't reach Sika right now.\n$detail\n\n"
            "Please check your connection and try again. 💙",
      role: MessageRole.assistant));

  void _scrollToBottom() =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOut,
          );
        }
      });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: const AppDrawer(),
      appBar: _buildAppBar(),
      bottomNavigationBar: MainNavigation(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeroBanner(),
            Expanded(child: _buildList()),
            if (_isListening) _buildVoiceOverlay(),
            if (_pendingImagePath != null) _buildImagePreview(),
            if (_showChips && !_isListening) _buildChips(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: _kWhite, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                final alpha = (_pulseAnim.value * 0.7 * 255).round();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.fromARGB(alpha, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _kWhite20),
                      child: Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            width: 26, height: 26,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text(
                                '🩸', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sika · SickleCare',
                    style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kWhite)),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _kGreen),
                    ),
                    const SizedBox(width: 5),
                    Text('Online · SCD Companion',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: _kWhite85)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: _kWhite, size: 20),
            onPressed: _showInfo,
          ),
        ],
      );

  // ── Hero Banner ────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFCDD2), Color(0xFFBBDEFB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kWhite,
                boxShadow: [
                  BoxShadow(
                      color: _kRedGlow, blurRadius: 12, offset: Offset(0, 4))
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                        child:
                            Text('🩸', style: TextStyle(fontSize: 20))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You are not alone',
                      style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark)),
                  const SizedBox(height: 2),
                  Text('Type, speak 🎙️ or send a photo 📷',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _kGrey)),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Message List ───────────────────────────────────────────────────────────

  Widget _buildList() => ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
        itemCount: _messages.length + (_loading ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _messages.length) return _typingBubble();
          return _bubble(_messages[i]);
        },
      );

  Widget _bubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 14 * (1 - v)), child: child),
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 34, height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_kRed, _kRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: _kRedGlow,
                        blurRadius: 8,
                        offset: Offset(0, 3))
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('🩸',
                              style: TextStyle(fontSize: 15))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [_kBlueMid, _kBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser ? null : _kCardBg,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(20),
                    topRight:    const Radius.circular(20),
                    bottomLeft:  Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      isUser ? _kBlueShadow : _kShadowSm,
                      blurRadius: 14,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sika label
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kRed),
                              ),
                              const SizedBox(width: 5),
                              Text('Sika',
                                  style: GoogleFonts.sora(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _kRed)),
                            ],
                          ),
                        ),

                      // Voice badge
                      if (isUser && msg.isVoice)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mic,
                                  color: _kWhite85, size: 12),
                              const SizedBox(width: 4),
                              Text('Voice message',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: _kWhite65)),
                            ],
                          ),
                        ),

                      // Image thumbnail
                      if (msg.imagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(msg.imagePath!),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Text (hide placeholder when image only)
                      if (msg.text != '📷 Photo' || msg.imagePath == null)
                        Text(
                          msg.text,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            height: 1.6,
                            color: isUser ? _kWhite : _kTextDark,
                          ),
                        ),

                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isUser && msg.imagePath != null)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.image_rounded,
                                    size: 11, color: _kWhite65),
                              ),
                            Text(
                              _fmt(msg.time),
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: isUser ? _kWhite65 : _kGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // ── Typing Indicator ───────────────────────────────────────────────────────

  Widget _typingBubble() => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kRed, _kRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: _kRedGlow,
                      blurRadius: 8,
                      offset: Offset(0, 3))
                ],
              ),
              child: const Center(
                  child: Text('🩸', style: TextStyle(fontSize: 15))),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(20),
                  topRight:    Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft:  Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                      color: _kShadowSm,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3,
                    (i) => _TypingDot(
                        delay: Duration(milliseconds: i * 200))),
              ),
            ),
          ],
        ),
      );

  // ── Voice Overlay ──────────────────────────────────────────────────────────

  Widget _buildVoiceOverlay() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEBEE), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kRedBorder),
          boxShadow: const [
            BoxShadow(
                color: _kRedGlow, blurRadius: 16, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _micAnim,
              builder: (_, __) => Transform.scale(
                scale: _micAnim.value,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_kRed, _kRedDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: _kRedShadow,
                          blurRadius: 16,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.mic, color: _kWhite, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Listening...',
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kRed)),
                  const SizedBox(height: 3),
                  Text(
                    _voiceDraft.isEmpty
                        ? 'Speak now — Sika is listening 🎙️'
                        : _voiceDraft,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: _kTextDark,
                        fontStyle: _voiceDraft.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleVoice,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kRedLight,
                  border: Border.all(color: _kRedBorder),
                ),
                child: const Icon(Icons.stop_rounded,
                    color: _kRed, size: 18),
              ),
            ),
          ],
        ),
      );

  // ── Pending Image Preview ──────────────────────────────────────────────────

  Widget _buildImagePreview() => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_pendingImagePath!),
                    width: 80, height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 3, right: 3,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _pendingImagePath = null;
                      _pendingImageB64  = null;
                    }),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _kRed),
                      child: const Icon(Icons.close,
                          color: _kWhite, size: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Photo ready — add a message or tap send ↗',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kGrey, height: 1.5),
              ),
            ),
          ],
        ),
      );

  // ── Suggestion Chips ───────────────────────────────────────────────────────

  Widget _buildChips() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
            child: Text('Quick questions',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _kGrey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _kSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _send(_kSuggestions[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _kRedBorder),
                    boxShadow: const [
                      BoxShadow(
                          color: _kShadowSm,
                          blurRadius: 6,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Text(_kSuggestions[i],
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _kTextDark,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      );

  // ── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInput() => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: const BoxDecoration(
          color: _kCardBg,
          boxShadow: [
            BoxShadow(
                color: _kShadowMd,
                blurRadius: 18,
                offset: Offset(0, -4))
          ],
        ),
        child: Row(
          children: [
            // ── Mic button ─────────────────────────────────────────────────
            GestureDetector(
              onTap: _speechAvailable ? _toggleVoice : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? _kRed : _kRedLight,
                  border: Border.all(color: _kRedBorder),
                  boxShadow: _isListening
                      ? const [
                          BoxShadow(
                              color: _kRedShadow,
                              blurRadius: 12,
                              offset: Offset(0, 3))
                        ]
                      : [],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? _kWhite : _kRed,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Image button ───────────────────────────────────────────────
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pendingImagePath != null
                      ? _kRed.withValues(alpha: 0.1)
                      : _kBg,
                  border: Border.all(
                    color: _pendingImagePath != null
                        ? _kRedBorder
                        : _kBlueBorder,
                  ),
                ),
                child: Icon(
                  _pendingImagePath != null
                      ? Icons.image_rounded
                      : Icons.add_photo_alternate_rounded,
                  color: _pendingImagePath != null ? _kRed : _kBlue,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Text field ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _kBlueBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: null,
                        textCapitalization:
                            TextCapitalization.sentences,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: _kTextDark),
                        decoration: InputDecoration(
                          hintText: 'Share how you\'re feeling...',
                          hintStyle: GoogleFonts.dmSans(
                              fontSize: 14, color: _kGrey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 13),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Send button ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => _send(_textCtrl.text),
              child: Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_kRed, _kRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: _kRedShadow,
                        blurRadius: 14,
                        offset: Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: _kWhite, size: 19),
              ),
            ),
          ],
        ),
      );

  // ── Info Sheet ─────────────────────────────────────────────────────────────

  void _showInfo() => showModalBottomSheet(
        context: context,
        backgroundColor: _kCardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _kGreyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_kRed, _kRedDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: _kRedGlow,
                            blurRadius: 10,
                            offset: Offset(0, 3))
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset('assets/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Text('🩸',
                                    style: TextStyle(fontSize: 22)))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About Sika',
                          style: GoogleFonts.sora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      Text('AI Support Companion · SickleCare Cameroon',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: _kGrey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Sika supports people living with sickle cell disease with '
                'empathy, wellness guidance, and encouragement — '
                'in English and French.\n\n'
                '🎙️ Tap the mic to speak.\n'
                '📷 Tap the photo icon to share an image.',
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: _kTextDark, height: 1.65),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kRedLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kRedBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: _kRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sika is not a medical doctor. Always consult your '
                        'healthcare provider for medical decisions.',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: _kRedDark,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─── TYPING DOT ──────────────────────────────────────────────────────────────

class _TypingDot extends StatefulWidget {
  final Duration delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: 8, height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromARGB(
              (_anim.value * 255).round().clamp(0, 255),
              229, 57, 53,
            ),
          ),
        ),
      );
}
