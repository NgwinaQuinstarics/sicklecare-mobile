import 'package:hive/hive.dart';

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  String get displayName => name.trim().isEmpty ? phone.trim() : name.trim();

  String get detail {
    final rel = relationship.trim();
    final number = phone.trim();
    if (rel.isEmpty) return number;
    return '$rel · $number';
  }

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'phone': phone.trim(),
        'relationship': relationship.trim(),
      };

  static EmergencyContact? tryFrom(dynamic value) {
    if (value is! Map) return null;
    final phone = (value['phone'] ?? '').toString().trim();
    if (phone.isEmpty) return null;
    return EmergencyContact(
      name: (value['name'] ?? '').toString().trim(),
      phone: phone,
      relationship: (value['relationship'] ?? '').toString().trim(),
    );
  }
}

class CarePlanService {
  CarePlanService._();

  static const _contactsKey = 'emergency_contacts';

  static Box get _box => Hive.box('app_cache');

  static List<EmergencyContact> getEmergencyContacts() {
    final raw = _box.get(_contactsKey);
    if (raw is! List) return const [];
    return raw
        .map(EmergencyContact.tryFrom)
        .whereType<EmergencyContact>()
        .toList(growable: false);
  }

  static Future<void> saveEmergencyContacts(
    List<EmergencyContact> contacts,
  ) async {
    final clean = contacts
        .where((contact) => contact.phone.trim().isNotEmpty)
        .map((contact) => contact.toMap())
        .toList(growable: false);
    await _box.put(_contactsKey, clean);
  }
}
