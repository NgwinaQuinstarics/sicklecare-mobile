import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tracker_entry.dart';

class TrackerProvider extends ChangeNotifier {
  final List<TrackerEntry> _entries = [];
  int _pendingSyncCount = 0;
  bool _syncing = false;

  List<TrackerEntry> get entries => List.unmodifiable(_entries);
  int get pendingSyncCount => _pendingSyncCount;

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
    _pendingSyncCount = _countPendingSync(box);
    notifyListeners();
    unawaited(syncPending());
  }

  Future<void> add(TrackerEntry e) async {
    final box = Hive.box('tracker');
    await box.put(e.id, {
      ...e.toMap(),
      'synced': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _entries.insert(0, e);
    _pendingSyncCount = _countPendingSync(box);
    notifyListeners();
    unawaited(_syncToFirestore(e));
  }

  Future<void> remove(String id) async {
    await Hive.box('tracker').delete(id);
    _entries.removeWhere((e) => e.id == id);
    _pendingSyncCount = _countPendingSync(Hive.box('tracker'));
    notifyListeners();
  }

  Future<void> syncPending() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _syncing) return;
    _syncing = true;
    try {
      final box = Hive.box('tracker');
      final pending = <TrackerEntry>[];
      for (final value in box.values) {
        if (value is! Map || value['synced'] == true) continue;
        try {
          pending.add(TrackerEntry.fromMap(Map<String, dynamic>.from(value)));
        } catch (_) {}
      }
      for (final entry in pending) {
        await _syncToFirestore(entry);
      }
    } finally {
      _syncing = false;
      _refreshPendingSyncCount();
    }
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
      await _markSynced(e);
    } catch (_) {}
  }

  Future<void> _markSynced(TrackerEntry e) async {
    final box = Hive.box('tracker');
    final raw = box.get(e.id);
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{...e.toMap()};
    data['synced'] = true;
    data['syncedAt'] = DateTime.now().toIso8601String();
    await box.put(e.id, data);
    _refreshPendingSyncCount();
  }

  void _refreshPendingSyncCount() {
    final next = _countPendingSync(Hive.box('tracker'));
    if (next == _pendingSyncCount) return;
    _pendingSyncCount = next;
    notifyListeners();
  }

  int _countPendingSync(Box box) {
    var count = 0;
    for (final value in box.values) {
      if (value is Map && value['synced'] != true) {
        count++;
      }
    }
    return count;
  }
}
