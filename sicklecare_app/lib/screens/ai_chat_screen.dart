import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n/strings.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/tracker_provider.dart';
import '../services/ai_service.dart';
import '../services/alarm_service.dart';

const _kChatKey = 'sika_chat';
final ImageProvider _kSikaLogo =
    ResizeImage(const AssetImage('assets/logo.png'), width: 200);

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
  bool _adviceRequested = false;
  bool _loadingAdvice = false;
  String? _dailyAdvice;

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
    if (!_adviceRequested) {
      _adviceRequested = true;
      _loadDailyAdvice();
    }
  }

  ChatMessage _intro() => ChatMessage(
      role: 'assistant', content: context.l10n.aiIntro, time: DateTime.now());

  void _persist() => _box.put(_kChatKey, _msgs.map((m) => m.toMap()).toList());

  Future<void> _send([String? preset]) async {
    final textValue = (preset ?? _ctl.text).trim();
    if (textValue.isEmpty || _loading) return;
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }

    setState(() {
      _msgs.add(
          ChatMessage(role: 'user', content: textValue, time: DateTime.now()));
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
      healthContext: _buildHealthContext(),
    );

    if (!mounted) return;
    setState(() {
      _msgs.add(
          ChatMessage(role: 'assistant', content: reply, time: DateTime.now()));
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
      listenOptions: SpeechListenOptions(localeId: l.fr ? 'fr_FR' : 'en_US'),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _ctl.text = r.recognizedWords);
        _ctl.selection = TextSelection.collapsed(offset: _ctl.text.length);
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

  Future<void> _loadDailyAdvice({bool refresh = false}) async {
    final key = 'sika_daily_advice_${_dateKey(DateTime.now())}';
    if (!refresh) {
      final stored = _box.get(key);
      if (stored is String && stored.trim().isNotEmpty) {
        setState(() => _dailyAdvice = stored);
        await AlarmService.instance.scheduleDailyHealthAdvice(stored);
        return;
      }
    }

    if (mounted) setState(() => _loadingAdvice = true);
    final advice = await AIService.dailyAdvice(_buildHealthContext());
    if (!mounted) return;
    setState(() {
      _dailyAdvice = advice;
      _loadingAdvice = false;
    });
    await _box.put(key, advice);
    await AlarmService.instance.scheduleDailyHealthAdvice(advice);
  }

  String _buildHealthContext() {
    final auth = context.read<AuthProvider>();
    final tracker = context.read<TrackerProvider>();
    final reminders = context.read<ReminderProvider>();
    final entries = tracker.entries;
    final now = DateTime.now();

    bool sameDay(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;
    final todayEntries = entries.where((e) => sameDay(e.date)).toList();
    final todayMl = todayEntries.fold<int>(0, (sum, e) => sum + e.hydrationMl);
    final latest = entries.isEmpty ? null : entries.first;
    final last7 = entries
        .where((e) => now.difference(e.date).inDays < 7)
        .toList(growable: false);
    final avgPain = last7.isEmpty
        ? null
        : last7.fold<double>(0, (sum, e) => sum + e.painLevel) / last7.length;
    final maxPain = last7.isEmpty
        ? null
        : last7.map((e) => e.painLevel).reduce((a, b) => a > b ? a : b);
    final activeReminders =
        reminders.items.where((r) => r.enabled).map((r) => r.title).toList();
    final profile = auth.profile ?? const <String, dynamic>{};
    final genotype = (profile['genotype'] ?? '').toString().trim();
    final name =
        ((profile['name'] ?? auth.user?.displayName) ?? '').toString().trim();
    final hydrationInterval = reminders.hydrationIntervalMinutes;
    final riskFlags = <String>[
      if ((latest?.painLevel ?? 0) >= 8) 'high pain',
      if (todayMl == 0) 'today hydration: none',
      if ((maxPain ?? 0) >= 8) 'high pain this week',
    ];

    return [
      'Date: ${_dateKey(now)}',
      if (name.isNotEmpty) 'Name: $name',
      if (genotype.isNotEmpty) 'Genotype: $genotype',
      'Today hydration: $todayMl ml',
      if (latest != null) ...[
        'Latest pain: ${latest.painLevel}/10',
        'Latest mood: ${latest.mood}',
        if (latest.notes.trim().isNotEmpty) 'Latest notes: ${latest.notes}',
      ],
      if (avgPain != null)
        '7-day average pain: ${avgPain.toStringAsFixed(1)}/10',
      if (maxPain != null) '7-day highest pain: $maxPain/10',
      if (hydrationInterval != null)
        'Hydration reminder interval: every $hydrationInterval minutes',
      if (activeReminders.isNotEmpty)
        'Active reminders: ${activeReminders.take(8).join(', ')}',
      if (riskFlags.isNotEmpty) 'Risk flags: ${riskFlags.join(', ')}',
    ].join('\n');
  }

  String _dateKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
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

  Future<void> _shareDoctorSummary() async {
    final l = context.l10n;
    final recentQuestions = _msgs
        .where((m) => m.role == 'user')
        .toList(growable: false)
        .reversed
        .take(5)
        .map((m) => '- ${m.content}')
        .toList()
        .reversed
        .join('\n');
    final summary = [
      l.tr('SickleCare summary for doctor', 'Résumé SickleCare pour médecin'),
      l.tr('Generated: ${DateTime.now()}', 'Généré : ${DateTime.now()}'),
      '',
      l.tr('Health snapshot', 'Résumé santé'),
      _buildHealthContext(),
      if (recentQuestions.isNotEmpty) ...[
        '',
        l.tr('Recent patient questions', 'Questions récentes du patient'),
        recentQuestions,
      ],
      '',
      l.tr(
        'This summary is patient-entered app data and is not a diagnosis.',
        'Ce résumé contient des données saisies par le patient et n’est pas un diagnostic.',
      ),
    ].join('\n');
    await Share.share(
      summary,
      subject: l.tr('SickleCare doctor summary', 'Résumé médecin SickleCare'),
    );
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
    final l = context.l10n;
    final showWelcome = _msgs.length <= 1 && !_loading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF008069),
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: _kSikaLogo),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sika',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l.tr('online', 'en ligne'),
                    style: const TextStyle(
                      color: Color(0xFFD9FDD3),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) {
              if (v == 'chat') {
                _clearChat();
              } else if (v == 'history') {
                _clearHistory();
              } else if (v == 'doctor') {
                _shareDoctorSummary();
              } else {
                _about();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'doctor',
                  child: _menuRow(Icons.ios_share_outlined,
                      l.tr('Share with doctor', 'Partager au médecin'))),
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
      body: _WhatsAppBackground(
        child: Column(
          children: [
            Expanded(
              child: showWelcome
                  ? _Welcome(
                      intro: _msgs.isNotEmpty ? _msgs.first.content : l.aiIntro,
                      dailyAdvice: _dailyAdvice,
                      loadingAdvice: _loadingAdvice,
                      onRefreshAdvice: () => _loadDailyAdvice(refresh: true),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      itemCount: _msgs.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_loading && i == _msgs.length) {
                          return const _AssistantTypingRow();
                        }
                        final m = _msgs[i];
                        final isUser = m.role == 'user';
                        return _WhatsAppBubble(
                          message: m,
                          isUser: isUser,
                          speakText: m.content,
                          readAloudLabel: l.readAloud,
                          onSpeak: isUser ? null : () => _speak(m.content),
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
            _WhatsAppComposer(
              controller: _ctl,
              enabled: !_loading,
              listening: _listening,
              hint: _listening ? l.listening : l.askAnything,
              onMic: _toggleMic,
              onSend: () => _send(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuRow(IconData i, String t) => Row(
        children: [Icon(i, size: 20), const SizedBox(width: 12), Text(t)],
      );
}

class _WhatsAppBackground extends StatelessWidget {
  final Widget child;
  const _WhatsAppBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B141A) : const Color(0xFFEFEAE2),
      ),
      child: child,
    );
  }
}

class _Welcome extends StatelessWidget {
  final String intro;
  final String? dailyAdvice;
  final bool loadingAdvice;
  final VoidCallback onRefreshAdvice;
  const _Welcome({
    required this.intro,
    required this.dailyAdvice,
    required this.loadingAdvice,
    required this.onRefreshAdvice,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 44, backgroundImage: _kSikaLogo),
            const SizedBox(height: 16),
            Text(
              'Sika',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              intro,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      color: const Color(0xFF008069)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.tr("Today's advice", "Conseil du jour"),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l.retry,
                              visualDensity: VisualDensity.compact,
                              onPressed: loadingAdvice ? null : onRefreshAdvice,
                              icon: const Icon(Icons.refresh, size: 18),
                            ),
                          ],
                        ),
                        if (loadingAdvice)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              color: Color(0xFF008069),
                            ),
                          )
                        else
                          Text(
                            dailyAdvice ??
                                l.tr(
                                  'Log a check-in today so Sika can personalize your advice.',
                                  "Enregistre un check-in aujourd'hui pour personnaliser le conseil de Sika.",
                                ),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF8696A0)
                                  : const Color(0xFF667781),
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final VoidCallback? onSpeak;
  final String speakText;
  final String readAloudLabel;

  const _WhatsAppBubble({
    required this.message,
    required this.isUser,
    this.onSpeak,
    required this.speakText,
    required this.readAloudLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userBg = isDark ? const Color(0xFF005C4B) : const Color(0xFFE7FFDB);
    final botBg = isDark ? const Color(0xFF202C33) : const Color(0xFFFFFFFF);
    final textCol = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21);
    final timeCol = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topRight: Radius.circular(2),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(2),
          );

    final timeStr = _formatTime(message.time);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? userBg : botBg,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                message.content,
                style: TextStyle(
                  color: textCol,
                  fontSize: 15.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isUser && onSpeak != null) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onSpeak,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.volume_up_outlined,
                                size: 14, color: timeCol),
                            const SizedBox(width: 3),
                            Text(
                              readAloudLabel,
                              style: TextStyle(fontSize: 10, color: timeCol),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: timeCol,
                      fontSize: 11,
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all,
                      size: 16,
                      color: Color(0xFF53BDEB), // Blue double checkmarks
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hr = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '$hr:$mn';
  }
}

class _WhatsAppComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final bool enabled;
  final bool listening;
  final String hint;

  const _WhatsAppComposer({
    required this.controller,
    required this.onSend,
    required this.onMic,
    required this.enabled,
    required this.listening,
    required this.hint,
  });

  @override
  State<_WhatsAppComposer> createState() => _WhatsAppComposerState();
}

class _WhatsAppComposerState extends State<_WhatsAppComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateTextState);
  }

  void _updateTextState() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTextState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? const Color(0xFF2A3942) : const Color(0xFFFFFFFF);
    final buttonBg = const Color(0xFF008069);
    final iconColor =
        isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      color: isDark ? const Color(0xFF0B141A) : const Color(0xFFF0F2F5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.sentiment_satisfied_alt_outlined,
                        color: iconColor),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => widget.onSend(),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: TextStyle(color: iconColor, fontSize: 15),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.enabled
                ? (_hasText ? widget.onSend : widget.onMic)
                : null,
            child: CircleAvatar(
              radius: 23,
              backgroundColor: buttonBg,
              child: Icon(
                _hasText
                    ? Icons.send
                    : (widget.listening ? Icons.stop : Icons.mic),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantTypingRow extends StatelessWidget {
  const _AssistantTypingRow();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final botBg = isDark ? const Color(0xFF202C33) : const Color(0xFFFFFFFF);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: botBg,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
        child: const _TypingDots(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
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
                  child: CircleAvatar(radius: 3.5, backgroundColor: dotColor),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
