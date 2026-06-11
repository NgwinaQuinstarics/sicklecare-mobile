import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n/strings.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

const _kChatKey = 'sika_chat';
final ImageProvider _kSikaLogo =
    ResizeImage(const AssetImage('assets/AppIcon.png'), width: 200);

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _msgs = [];
  bool _loading = false;
  bool _loaded = false;

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;
  bool _listening = false;

  Box get _box => Hive.box('app_cache');

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {
      _speechReady = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final stored = _box.get(_kChatKey);
    if (stored is List) {
      for (final m in stored) {
        try {
          _msgs.add(ChatMessage.fromMap(Map<String, dynamic>.from(m as Map)));
        } catch (_) {}
      }
    }
    if (_msgs.isEmpty) _msgs.add(_intro());
  }

  ChatMessage _intro() => ChatMessage(
      role: 'assistant', content: context.l10n.aiIntro, time: DateTime.now());

  void _persist() =>
      _box.put(_kChatKey, _msgs.map((m) => m.toMap()).toList());

  Future<void> _send([String? preset]) async {
    final textValue = (preset ?? _ctl.text).trim();
    if (textValue.isEmpty || _loading) return;
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }

    setState(() {
      _msgs.add(ChatMessage(
          role: 'user', content: textValue, time: DateTime.now()));
      _loading = true;
      _ctl.clear();
    });
    _persist();
    _scrollToEnd();

    final history =
        _msgs.map((m) => {'role': m.role, 'content': m.content}).toList();
    final reply = await AIService.ask(
      textValue,
      history:
          history.length > 1 ? history.sublist(0, history.length - 1) : null,
    );

    if (!mounted) return;
    setState(() {
      _msgs.add(ChatMessage(
          role: 'assistant', content: reply, time: DateTime.now()));
      _loading = false;
    });
    _persist();
    _scrollToEnd();
  }

  Future<void> _toggleMic() async {
    final l = context.l10n;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) return;
    }
    if (!mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions:
          SpeechListenOptions(localeId: l.fr ? 'fr_FR' : 'en_US'),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _ctl.text = r.recognizedWords);
        _ctl.selection =
            TextSelection.collapsed(offset: _ctl.text.length);
      },
    );
  }

  Future<void> _speak(String text) async {
    final fr = context.l10n.fr;
    try {
      await _tts.stop();
      await _tts.setLanguage(fr ? 'fr-FR' : 'en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _clearChat() {
    setState(() => _msgs
      ..clear()
      ..add(_intro()));
    _persist();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.chatCleared)));
  }

  Future<void> _clearHistory() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.clearHistory),
        content: Text(l.fr
            ? "Supprimer tout l'historique de conversation ?"
            : 'Delete all conversation history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _box.delete(_kChatKey);
    setState(() => _msgs
      ..clear()
      ..add(_intro()));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.historyCleared)));
    }
  }

  void _about() {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundImage: _kSikaLogo),
            const SizedBox(width: 10),
            Expanded(child: Text(l.aboutSikaTitle)),
          ],
        ),
        content: SingleChildScrollView(child: Text(l.aboutSikaBody)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.fr ? 'Fermer' : 'Close')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
    final showWelcome = _msgs.length <= 1 && !_loading;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundImage: _kSikaLogo),
            const SizedBox(width: 10),
            const Text('Sika'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'chat') {
                _clearChat();
              } else if (v == 'history') {
                _clearHistory();
              } else {
                _about();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'chat',
                  child: _menuRow(Icons.delete_sweep_outlined, l.clearChat)),
              PopupMenuItem(
                  value: 'history',
                  child: _menuRow(Icons.history, l.clearHistory)),
              PopupMenuItem(
                  value: 'about', child: _menuRow(Icons.info_outline, l.about)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: showWelcome
                ? _Welcome(
                    intro: _msgs.isNotEmpty ? _msgs.first.content : l.aiIntro)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                    itemCount: _msgs.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_loading && i == _msgs.length) {
                        return const _AssistantRow(child: _TypingDots());
                      }
                      final m = _msgs[i];
                      if (m.role == 'user') {
                        return _UserBubble(text: m.content);
                      }
                      return _AssistantRow(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              m.content,
                              style: TextStyle(
                                  color: cs.onSurface, height: 1.4),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _speak(m.content),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.volume_up_outlined,
                                        size: 16, color: cs.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(l.readAloud,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (showWelcome)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: l.aiSuggestions
                    .map((s) => ActionChip(
                          label: Text(s),
                          onPressed: () => _send(s),
                        ))
                    .toList(),
              ),
            ),
          _Composer(
            controller: _ctl,
            enabled: !_loading,
            listening: _listening,
            hint: _listening ? l.listening : l.askAnything,
            onMic: _toggleMic,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData i, String t) => Row(
        children: [Icon(i, size: 20), const SizedBox(width: 12), Text(t)],
      );
}

class _Welcome extends StatelessWidget {
  final String intro;
  const _Welcome({required this.intro});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 44, backgroundImage: _kSikaLogo),
            const SizedBox(height: 16),
            Text('Sika',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(intro,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .8),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: TextStyle(color: cs.onPrimary, height: 1.35)),
      ),
    );
  }
}

class _AssistantRow extends StatelessWidget {
  final Widget child;
  const _AssistantRow({required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, backgroundImage: _kSikaLogo),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final bool enabled;
  final bool listening;
  final String hint;
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onMic,
    required this.enabled,
    required this.listening,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  suffixIcon: IconButton(
                    tooltip: 'Voice',
                    onPressed: onMic,
                    icon: Icon(listening ? Icons.mic : Icons.mic_none,
                        color: listening ? cs.primary : cs.onSurfaceVariant),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: cs.primary, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 42,
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.2) % 1.0;
              final o =
                  t < 0.5 ? 0.3 + 0.7 * (t * 2) : 0.3 + 0.7 * ((1 - t) * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: o.clamp(0.3, 1.0),
                  child: CircleAvatar(
                      radius: 3.5, backgroundColor: cs.onSurfaceVariant),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
