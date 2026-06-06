import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactStore {
  static const _keyName = 'emergency_contact_name';
  static const _keyPhone = 'emergency_contact_phone';
  static const _keyRelation = 'emergency_contact_relation';

  static Future<EmergencyContact?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_keyPhone)?.trim();
    if (phone == null || phone.isEmpty) return null;
    return EmergencyContact(
      name: prefs.getString(_keyName)?.trim() ?? '',
      phone: phone,
      relation: prefs.getString(_keyRelation)?.trim() ?? '',
    );
  }

  static Future<void> save(EmergencyContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, contact.name.trim());
    await prefs.setString(_keyPhone, contact.phone.trim());
    await prefs.setString(_keyRelation, contact.relation.trim());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyRelation);
  }
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  final String name;
  final String phone;
  final String relation;
}
