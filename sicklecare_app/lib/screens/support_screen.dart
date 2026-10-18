import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../services/care_plan_service.dart';
import '../services/firestore_service.dart';
import '../widgets/section_card.dart';

class SupportScreen extends StatefulWidget {
  final bool crisisMode;
  const SupportScreen({super.key, this.crisisMode = false});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  List<EmergencyContact> _emergencyContacts = const [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  void _loadEmergencyContacts() {
    try {
      _emergencyContacts = CarePlanService.getEmergencyContacts();
    } catch (_) {
      _emergencyContacts = const [];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FirestoreService.submitSupportMessage(
        name: _name.text.trim(),
        email: _email.text.trim(),
        subject: _subject.text.trim(),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.messageSent)),
      );
    } catch (e) {
      debugPrint('Support message failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr(
            'Could not send your message. Please check your connection and try again.',
            'Impossible d\'envoyer ton message. Vérifie ta connexion puis réessaie.',
          )),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.crisisMode
            ? l.tr('Crisis mode', 'Mode crise')
            : l.supportTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (widget.crisisMode) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.tr('Red flags', 'Signes d’alerte'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...[
                    l.tr('Chest pain', 'Douleur thoracique'),
                    l.tr('Difficulty breathing', 'Difficulté à respirer'),
                    l.tr('High fever', 'Forte fièvre'),
                    l.tr('One-sided weakness or confusion',
                        'Faiblesse d’un côté ou confusion'),
                    l.tr('Severe pain not improving',
                        'Douleur sévère qui ne s’améliore pas'),
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                  Text(
                    l.tr(
                      'If any red flag is present, go to the nearest hospital now.',
                      'Si un signe d’alerte est présent, va immédiatement à l’hôpital le plus proche.',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.emergency,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 6),
                Text(l.emergencyText),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _call('112'),
                  icon: const Icon(Icons.call),
                  label: Text(l.callEmergency),
                ),
                if (_emergencyContacts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l.tr('Trusted contacts', 'Contacts de confiance'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final contact in _emergencyContacts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _call(contact.phone),
                          icon: const Icon(Icons.contact_phone_outlined),
                          label: Text(
                            l.tr('Call ${contact.displayName}',
                                'Appeler ${contact.displayName}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.contactTeam,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l.name),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.required : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l.email),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? l.validEmail : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _subject,
                    decoration: InputDecoration(labelText: l.subject),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _message,
                    decoration: InputDecoration(labelText: l.message),
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.required : null,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l.sendMessage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
