import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'alarm_service.dart';

class PrivacyDataService {
  PrivacyDataService._();

  static const _boxNames = ['app_cache', 'tracker', 'reminders'];

  static Future<File> createLocalDataExport() async {
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'app': 'SickleCare',
      'exportedAt': now.toIso8601String(),
      'format': 'sicklecare.local-data.v1',
      'boxes': {
        for (final name in _boxNames) name: _boxSnapshot(name),
      },
    };
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      'sicklecare_export_${_stamp(now)}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  static Future<void> shareLocalDataExport() async {
    final file = await createLocalDataExport();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'SickleCare local data export',
    );
  }

  static Future<void> deleteLocalHealthData() async {
    await AlarmService.instance.cancelAll();
    await Hive.box('tracker').clear();
    await Hive.box('reminders').clear();
    await Hive.box('app_cache').deleteAll([
      'emergency_contacts',
      'hydration_interval_minutes',
      'hydration_start_minutes',
      'reminder_schedule_schema_version',
      'reminder_audit_log',
      'sika_chat',
      'user_groq_api_key',
      'user_openai_api_key',
    ]);
  }

  static Map<String, dynamic> _boxSnapshot(String name) {
    final box = Hive.box(name);
    return {
      for (final key in box.keys) key.toString(): _jsonSafe(box.get(key)),
    };
  }

  static dynamic _jsonSafe(dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return value.toString();
  }

  static String _stamp(DateTime now) =>
      '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
}
