import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_model.dart';

class ReminderLocalDataSource {
  const ReminderLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _storageKeyV2 = 'reminder.reminders.v2';
  static const _storageKeyV1 = 'reminder.reminders.v1';

  List<ReminderModel> _decodeReminders(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <ReminderModel>[];
    }

    return decoded
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(ReminderModel.fromJson)
        .toList();
  }

  Future<List<ReminderModel>> getReminders() async {
    // Get raw string data from shared preferences
    final rawV2 = _prefs.getString(_storageKeyV2);
    if (rawV2 != null && rawV2.trim().isNotEmpty) {
      return _decodeReminders(rawV2);
    }

    final rawV1 = _prefs.getString(_storageKeyV1);
    if (rawV1 == null || rawV1.trim().isEmpty) {
      return <ReminderModel>[];
    }

    final migrated = _decodeReminders(rawV1);
    await saveReminders(migrated);
    return migrated;
  }

  Future<void> saveReminders(List<ReminderModel> reminders) async {
    final encoded = jsonEncode(reminders.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKeyV2, encoded);
  }
}
