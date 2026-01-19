enum ReminderType {
  time,
  location;

  static ReminderType fromJson(String? value) {
    final v = value?.trim();
    return switch (v) {
      'location' || 'ReminderType.location' => ReminderType.location,
      'time' || 'ReminderType.time' => ReminderType.time,
      _ => ReminderType.time,
    };
  }
}