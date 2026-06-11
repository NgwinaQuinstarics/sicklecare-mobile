import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tracker_entry.dart';

class TrackerProvider extends ChangeNotifier {
  final List<TrackerEntry> _entries = [];
  List<TrackerEntry> get entries => List.unmodifiable(_entries);

  TrackerProvider() {
    load();
  }

  Future<void> load() async {
    _entries.clear();
    final box = Hive.box('tracker');
    for (final v in box.values) {
      try {
        _entries.add(TrackerEntry.fromMap(Map<String, dynamic>.from(v as Map)));
      } catch (_) {}
    }
    _entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> add(TrackerEntry e) async {
    final box = Hive.box('tracker');
    await box.put(e.id, e.toMap());
    _entries.insert(0, e);
    notifyListeners();
    _syncToFirestore(e);
  }

  Future<void> remove(String id) async {
    await Hive.box('tracker').delete(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> _syncToFirestore(TrackerEntry e) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tracker_entries')
          .doc(e.id)
          .set(e.toMap());
    } catch (_) {}
  }
}
