import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/strings.dart';
import '../../widgets/section_card.dart';
import '../../services/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _heroTitle = TextEditingController();
  final _heroBody = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('content')
          .doc('home')
          .get();
      final d = doc.data() ?? {};
      _heroTitle.text = d['heroTitle'] ?? '';
      _heroBody.text = d['heroBody'] ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _saving = true);
    await FirestoreService.updateContent('home', {
      'heroTitle': _heroTitle.text.trim(),
      'heroBody': _heroBody.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.contentUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.adminTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.editHomeContent,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _heroTitle,
                        decoration: InputDecoration(labelText: l.heroTitle),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _heroBody,
                        decoration: InputDecoration(labelText: l.heroBody),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(l.save),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.recentMessages,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('contact_messages')
                            .orderBy('createdAt', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final docs = snap.data!.docs;
                          if (docs.isEmpty) return Text(l.noMessages);
                          return Column(
                            children: docs.map((d) {
                              final m = d.data();
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.mail_outline),
                                title: Text(m['subject'] ?? l.noSubject),
                                subtitle: Text(
                                    '${m['name'] ?? ''} · ${m['email'] ?? ''}\n${m['message'] ?? ''}'),
                                isThreeLine: true,
                              );
                            }).toList(),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
