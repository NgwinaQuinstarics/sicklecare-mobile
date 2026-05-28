import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── MODELS ──────────────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

class ChatMessage {
  final String      id;
  final String      text;
  final MessageRole role;
  final DateTime    time;
  final bool        isVoice;
  final String?     imagePath;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    DateTime? time,
    this.isVoice  = false,
    this.imagePath,
  }) : time = time ?? DateTime.now();

  // ── Firestore serialization ────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'text':      text,
        'role':      role == MessageRole.user ? 'user' : 'assistant',
        'timestamp': FieldValue.serverTimestamp(),
        'isVoice':   isVoice,
      };

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id:       doc.id,
      text:     d['text']    ?? '',
      role:     d['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      time:     (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVoice:  d['isVoice'] ?? false,
    );
  }
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
const _kChatBg     = Color(0xFFEEF2FF);  // WhatsApp-style chat background
const _kWhite      = Color(0xFFFFFFFF);
const _kWhite85    = Color(0xD9FFFFFF);
const _kWhite65    = Color(0xA6FFFFFF);
const _kGrey       = Color(0xFF90A4AE);
const _kGreyLight  = Color(0xFFECEFF1);
const _kTextDark   = Color(0xFF1A237E);
const _kShadowSm   = Color(0x10000000);
const _kShadowMd   = Color(0x16000000);
const _kGreen      = Color(0xFF00C853);
const _kCardBg     = Color(0xFFFFFFFF);
const _kRedTint10  = Color(0x1AE53935);

// ─── API ─────────────────────────────────────────────────────────────────────

String get _kGroqKey => dotenv.env['GROQ_API_KEY'] ?? '';

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
  "I'm in pain today ",
  "What triggers a crisis?",
  "How much water daily? ",
  "I feel anxious ",
  "Foods to avoid? ",
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
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages   = <ChatMessage>[];

  // Firebase
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? get _uid => _auth.currentUser?.uid;
  CollectionReference? get _msgCol => _uid == null
      ? null
      : _firestore.collection('chats').doc(_uid).collection('messages');

  bool   _loading       = false;
  bool   _showChips     = true;
  bool   _isListening   = false;
  bool   _firestoreReady = false;
  String _voiceDraft    = '';

  String? _pendingImagePath;
  String? _pendingImageB64;

  final _speech = stt.SpeechToText();
  bool  _speechAvailable = false;

  final _picker = ImagePicker();

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
    _loadMessages();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => dev.log('Speech error: $e', name: 'SupportScreen'),
    );
    setState(() {});
  }

  // ── Load messages from Firestore ───────────────────────────────────────────

  Future<void> _loadMessages() async {
    if (_msgCol == null) {
      // Not logged in — use local welcome only
      _addWelcome();
      setState(() => _firestoreReady = true);
      return;
    }

    try {
      final snap = await _msgCol!
          .orderBy('timestamp', descending: false)
          .limit(100)
          .get();

      if (snap.docs.isEmpty) {
        // First time — add welcome and save it
        _addWelcome();
        await _saveToFirestore(_messages.first);
      } else {
        setState(() {
          _messages.addAll(snap.docs.map(ChatMessage.fromFirestore));
          _showChips = _messages.length <= 1;
        });
      }
    } catch (e) {
      dev.log('Load messages error: $e', name: 'SupportScreen');
      _addWelcome();
    }

    setState(() => _firestoreReady = true);
    _scrollToBottom();
  }

  void _addWelcome() {
    _messages.add(ChatMessage(
      id:   'welcome',
      text: "Hi there! I'm Sika  — your SickleCare companion.\n\n"
            "I'm here to listen, comfort, and guide you through life "
            "with sickle cell disease.\n\nShare what you're feeling — "
            "type, use your voice 🎙️, or send a photo 📷. 💙\n\n"
            "⚠️ I am not a medical doctor. Always consult your healthcare "
            "provider for medical decisions.",
      role: MessageRole.assistant,
    ));
  }

  // ── Save single message to Firestore ──────────────────────────────────────

  Future<void> _saveToFirestore(ChatMessage msg) async {
    if (_msgCol == null) return;
    try {
      await _msgCol!.add(msg.toFirestore());
    } catch (e) {
      dev.log('Save message error: $e', name: 'SupportScreen');
    }
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

 Future<void> _toggleVoice() async {
  if (_isListening) {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_voiceDraft.trim().isNotEmpty) {
      final text = _voiceDraft.trim();
      _voiceDraft = '';
      _send(text, isVoice: true);
    }
  } else {
    if (!_speechAvailable) return;

    setState(() {
      _isListening = true;
      _voiceDraft = '';
    });

    await _speech.listen(
      onResult: (r) => setState(() {
        _voiceDraft = r.recognizedWords;
      }),

      // DEPRECATED USAGE
      listenOptions: stt.SpeechListenOptions(
        localeId: 'en_US', 
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }
}

  // ── Image Picker ───────────────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  _imgTile(Icons.camera_alt_rounded, 'Camera',
                      () => _pickImage(ImageSource.camera)),
                  _imgTile(Icons.photo_library_rounded, 'Gallery',
                      () => _pickImage(ImageSource.gallery)),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgTile(IconData icon, String label, VoidCallback onTap) =>
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
                    end: Alignment.bottomRight),
                boxShadow: [
                  BoxShadow(color: _kRedGlow, blurRadius: 12, offset: Offset(0, 4))
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
    Navigator.pop(context);
    final picked = await _picker.pickImage(
        source: source, imageQuality: 75, maxWidth: 1024);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pendingImagePath = picked.path;
      _pendingImageB64  = base64Encode(bytes);
    });
  }

  // ── Groq API + Firestore Save ──────────────────────────────────────────────

  Future<void> _send(String text, {bool isVoice = false}) async {
    final trimmed  = text.trim();
    final hasText  = trimmed.isNotEmpty;
    final hasImage = _pendingImageB64 != null;
    if ((!hasText && !hasImage) || _loading) return;

    final imgPathSnap = _pendingImagePath;
    final imgB64Snap  = _pendingImageB64;

    final userMsg = ChatMessage(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      text:      hasText ? trimmed : '📷 Photo',
      role:      MessageRole.user,
      isVoice:   isVoice,
      imagePath: imgPathSnap,
    );

    setState(() {
      _messages.add(userMsg);
      _loading          = true;
      _showChips        = false;
      _pendingImagePath = null;
      _pendingImageB64  = null;
    });
    _textCtrl.clear();
    _scrollToBottom();

    // Persist user message
    await _saveToFirestore(userMsg);

    try {
      final useVision = imgB64Snap != null;
      final model     = useVision
          ? 'meta-llama/llama-4-scout-17b-16e-instruct'
          : 'llama-3.3-70b-versatile';

      dynamic userContent;
      if (useVision) {
        userContent = [
          {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$imgB64Snap'}},
          {'type': 'text', 'text': hasText ? trimmed : 'Please look at this image and respond helpfully in the context of sickle cell disease wellness.'},
        ];
      } else {
        userContent = trimmed;
      }

      // Send last 10 messages as context
      final start   = (_messages.length - 10).clamp(0, _messages.length);
      final history = _messages.sublist(start, _messages.length - 1).map((m) => {
            'role':    m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.text,
          }).toList();

      final msgs = [
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
        final reply = jsonDecode(res.body)['choices'][0]['message']['content'] as String;
        final sikaMsg = ChatMessage(
          id:   DateTime.now().millisecondsSinceEpoch.toString(),
          text: reply,
          role: MessageRole.assistant,
        );
        setState(() => _messages.add(sikaMsg));
        // Persist Sika reply
        await _saveToFirestore(sikaMsg);
      } else {
        final errMsg = jsonDecode(res.body)['error']?['message'] ?? 'Error';
        _addError(errMsg);
      }
    } on Exception catch (e) {
      _addError('$e');
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _addError(String detail) {
    final errMsg = ChatMessage(
      id:   DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Couldn't reach Sika right now.\n$detail\n\nCheck your connection and try again. ",
      role: MessageRole.assistant,
    );
    setState(() => _messages.add(errMsg));
  }

  // ── Clear chat ─────────────────────────────────────────────────────────────

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear Chat'),
        content: const Text('This will delete all messages with Sika. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: _kWhite)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (_msgCol != null) {
      final snap = await _msgCol!.get();
      for (final doc in snap.docs) { await doc.reference.delete(); }
    }
    setState(() {
      _messages.clear();
      _showChips = true;
    });
    _addWelcome();
    if (_msgCol != null) await _saveToFirestore(_messages.first);
  }

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
      backgroundColor: _kChatBg,
      appBar: _buildAppBar(),
      body: !_firestoreReady
          ? const Center(child: CircularProgressIndicator(color: _kBlue))
          : SafeArea(
              child: Column(
                children: [
                  _buildDisclaimerBanner(),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Pulsing logo avatar
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                final alpha = (_pulseAnim.value * 0.7 * 255).round();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.fromARGB(alpha, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kWhite,
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Text('🩸',
                                    style: TextStyle(fontSize: 17))),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sika · SickleCare AI',
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
                      Text('Online · Not a medical doctor',
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: _kWhite85)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _kWhite),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'clear') _clearChat();
              if (v == 'info') _showInfo();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'info',
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 10),
                    Text('About Sika'),
                  ])),
              const PopupMenuItem(
                  value: 'clear',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Clear Chat',
                        style: TextStyle(color: Colors.red)),
                  ])),
            ],
          ),
        ],
      );

  // ── Disclaimer Banner ──────────────────────────────────────────────────────

  Widget _buildDisclaimerBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFFFFF3E0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE65100), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sika is an AI companion, not a medical doctor. '
                'Always consult your healthcare provider for medical decisions.',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFFE65100),
                    height: 1.4),
              ),
            ),
          ],
        ),
      );

  // ── Message List ───────────────────────────────────────────────────────────

  Widget _buildList() => ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
        itemCount: _messages.length + (_loading ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _messages.length) return _typingBubble();
          // Date separator
          final msg  = _messages[i];
          final prev = i > 0 ? _messages[i - 1] : null;
          final showDate = prev == null ||
              !_sameDay(prev.time, msg.time);
          return Column(
            children: [
              if (showDate) _dateSeparator(msg.time),
              _bubble(msg),
            ],
          );
        },
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dateSeparator(DateTime t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(t),
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _kTextDark,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );

  String _formatDate(DateTime t) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(t.year, t.month, t.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${t.day}/${t.month}/${t.year}';
  }

  Widget _bubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(isUser ? 20 * (1 - v) : -20 * (1 - v), 0),
            child: child),
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Sika logo avatar
            if (!isUser) ...[
              Container(
                width: 32, height: 32,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kWhite,
                  boxShadow: [
                    BoxShadow(
                        color: _kRedGlow,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child:
                              Text('🩸', style: TextStyle(fontSize: 14))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Bubble
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  // WhatsApp style: green-tint for user, white for Sika
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [_kBlueMid, _kBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser ? null : _kCardBg,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      isUser ? _kBlueShadow : _kShadowSm,
                      blurRadius: 8,
                      offset:     const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sika name tag
                    if (!isUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('Sika',
                            style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kRed)),
                      ),

                    // Voice badge
                    if (isUser && msg.isVoice)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mic,
                                color: _kWhite85, size: 11),
                            const SizedBox(width: 3),
                            Text('Voice',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10, color: _kWhite65)),
                          ],
                        ),
                      ),

                    // Image
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
                      const SizedBox(height: 6),
                    ],

                    // Text
                    if (msg.text != '📷 Photo' || msg.imagePath == null)
                      Text(
                        msg.text,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          height: 1.55,
                          color: isUser ? _kWhite : _kTextDark,
                        ),
                      ),

                    // Timestamp row (WhatsApp style)
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUser && msg.imagePath != null)
                            const Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: Icon(Icons.image_rounded,
                                  size: 10, color: _kWhite65),
                            ),
                          Text(
                            _fmt(msg.time),
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color:
                                    isUser ? _kWhite65 : _kGrey),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.done_all,
                                size: 12, color: _kWhite65),
                          ],
                        ],
                      ),
                    ),
                  ],
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
        padding: const EdgeInsets.only(bottom: 6, left: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _kWhite),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child:
                              Text('🩸', style: TextStyle(fontSize: 14)))),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(18),
                  topRight:    Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft:  Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                      color: _kShadowSm,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    3,
                    (i) => _TypingDot(
                        delay: Duration(milliseconds: i * 200))),
              ),
            ),
          ],
        ),
      );

  // ── Voice Overlay ──────────────────────────────────────────────────────────

  Widget _buildVoiceOverlay() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEBEE), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kRedBorder),
          boxShadow: const [
            BoxShadow(color: _kRedGlow, blurRadius: 14, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _micAnim,
              builder: (_, __) => Transform.scale(
                scale: _micAnim.value,
                child: Container(
                  width: 42, height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [_kRed, _kRedDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: _kRedShadow,
                          blurRadius: 14,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.mic, color: _kWhite, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Listening...',
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kRed)),
                  const SizedBox(height: 2),
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
                width: 34, height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kRedLight,
                  border: Border.all(color: _kRedBorder),
                ),
                child: const Icon(Icons.stop_rounded, color: _kRed, size: 17),
              ),
            ),
          ],
        ),
      );

  // ── Pending Image Preview ──────────────────────────────────────────────────

  Widget _buildImagePreview() => Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_pendingImagePath!),
                      width: 72, height: 72, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 2, right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _pendingImagePath = null;
                      _pendingImageB64  = null;
                    }),
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _kRed),
                      child: const Icon(Icons.close,
                          color: _kWhite, size: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Photo ready — add a message or tap send ↗',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: _kGrey, height: 1.5)),
            ),
          ],
        ),
      );

  // ── Suggestion Chips ───────────────────────────────────────────────────────

  Widget _buildChips() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 5, top: 4),
            child: Text('Quick questions',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _kGrey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _kSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _send(_kSuggestions[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kRedBorder),
                    boxShadow: const [
                      BoxShadow(
                          color: _kShadowSm,
                          blurRadius: 4,
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
          const SizedBox(height: 6),
        ],
      );

  // ── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInput() => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        decoration: const BoxDecoration(
          color: _kCardBg,
          boxShadow: [
            BoxShadow(color: _kShadowMd, blurRadius: 16, offset: Offset(0, -3))
          ],
        ),
        child: Row(
          children: [
            // Mic
            GestureDetector(
              onTap: _speechAvailable ? _toggleVoice : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? _kRed : _kRedLight,
                  border: Border.all(color: _kRedBorder),
                  boxShadow: _isListening
                      ? const [
                          BoxShadow(
                              color: _kRedShadow,
                              blurRadius: 10,
                              offset: Offset(0, 3))
                        ]
                      : [],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? _kWhite : _kRed,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Image
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pendingImagePath != null ? _kRedTint10 : _kBg,
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
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _kBlueBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: _kTextDark),
                        decoration: InputDecoration(
                          hintText: 'Share how you\'re feeling...',
                          hintStyle: GoogleFonts.dmSans(
                              fontSize: 14, color: _kGrey),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send
            GestureDetector(
              onTap: () => _send(_textCtrl.text),
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
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ],
                ),
                child:
                    const Icon(Icons.send_rounded, color: _kWhite, size: 18),
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
                    width: 54, height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kWhite,
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
                                    style: TextStyle(fontSize: 24)))),
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
                      Text('AI Companion · SickleCare Cameroon',
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
                '📷 Tap the photo icon to share an image.\n'
                '💬 Your chat history is saved automatically.',
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: _kTextDark, height: 1.65),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0x40E65100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ Sika is NOT a medical doctor. She provides '
                        'emotional support and general wellness information only. '
                        'Always consult your healthcare provider for medical decisions.',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFFE65100),
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