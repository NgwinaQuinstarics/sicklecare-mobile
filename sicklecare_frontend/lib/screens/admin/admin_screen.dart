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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _heroTitle.dispose();
    _heroBody.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loadErrorMessage = context.l10n.tr(
      'Could not load admin content. Check your connection and permissions.',
      'Impossible de charger le contenu administrateur. Vérifie ta connexion et tes autorisations.',
    );
    try {
      final doc = await FirebaseFirestore.instance
          .collection('content')
          .doc('home')
          .get();
      final d = doc.data() ?? {};
      _heroTitle.text = d['heroTitle'] ?? '';
      _heroBody.text = d['heroBody'] ?? '';
    } catch (error) {
      debugPrint('Failed to load admin content: $error');
      if (mounted) _loadError = loadErrorMessage;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _saving = true);
    try {
      await FirestoreService.updateContent('home', {
        'heroTitle': _heroTitle.text.trim(),
        'heroBody': _heroBody.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.contentUpdated)),
        );
      }
    } catch (error) {
      debugPrint('Failed to save admin content: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.tr(
              'Content could not be saved. Check your admin access and try again.',
              'Le contenu n’a pas pu être enregistré. Vérifie ton accès administrateur et réessaie.',
            )),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.adminTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _loadError = null;
                            });
                            _load();
                          },
                          child: Text(l.tr('Retry', 'Réessayer')),
                        ),
                      ],
                    ),
                  ),
                )
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
                            .collection('support_messages')
                            .orderBy('createdAt', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (_, snap) {
                          if (snap.hasError) {
                            debugPrint(
                              'Failed to load support messages: ${snap.error}',
                            );
                            return Text(l.tr(
                              'Support messages could not be loaded.',
                              'Impossible de charger les messages d’assistance.',
                            ));
                          }
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
