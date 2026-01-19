import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/features/reminders/domain/entities/reminder.dart';
import 'package:reminder/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:reminder/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:reminder/features/reminders/domain/usecases/get_location_name.dart';
import 'package:reminder/features/reminders/domain/usecases/get_reminders.dart';
import 'package:reminder/features/reminders/domain/usecases/toggle_done.dart';
import 'package:reminder/features/reminders/domain/usecases/upsert_reminder.dart';
import 'package:reminder/features/reminders/presentation/bloc/reminder_bloc.dart';
import 'package:reminder/features/reminders/presentation/pages/reminder_list_page.dart';
import 'package:reminder/core/services/notification_service.dart';

class _FakeNotificationService implements NotificationService {
  @override
  Future<void> cancelForReminder(String reminderId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleForReminder(Reminder reminder) async {}

  @override
  Future<void> showNowForReminder(Reminder reminder, {String? body}) async {}
}

class _InMemoryReminderRepository implements ReminderRepository {
  final List<Reminder> _items = <Reminder>[];

  @override
  Future<void> deleteReminder(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Reminder>> getReminders() async {
    return List<Reminder>.unmodifiable(_items);
  }

  @override
  Future<void> toggleDone(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    _items[idx] = _items[idx].copyWith(isDone: !_items[idx].isDone);
  }

  @override
  Future<void> upsertReminder(Reminder reminder) async {
    final idx = _items.indexWhere((e) => e.id == reminder.id);
    if (idx < 0) {
      _items.add(reminder);
    } else {
      _items[idx] = reminder;
    }
  }

  @override
  Future<String?> getLocationName({
    required double lat,
    required double lng,
    required String accessToken,
  }) async {
    return 'Test Location';
  }
}

void main() {
  testWidgets('ReminderListPage renders', (WidgetTester tester) async {
    final repo = _InMemoryReminderRepository();
    final notificationService = _FakeNotificationService();
    final bloc = ReminderBloc(
      getReminders: GetReminders(repo),
      upsertReminder: UpsertReminder(repo),
      deleteReminder: DeleteReminder(repo),
      toggleDone: ToggleDone(repo),
      notificationService: notificationService,
      getLocationName: GetLocationName(repo),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: ReminderListPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Reminder'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await bloc.close();
  });
}
