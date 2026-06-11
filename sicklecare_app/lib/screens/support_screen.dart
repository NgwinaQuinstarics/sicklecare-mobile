import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../services/firestore_service.dart';
import '../widgets/section_card.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FirestoreService.submitContactMessage(
        name: _name.text.trim(),
        email: _email.text.trim(),
        subject: _subject.text.trim(),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.messageSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.failed(e.toString()))),
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
      appBar: AppBar(title: Text(l.supportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
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
