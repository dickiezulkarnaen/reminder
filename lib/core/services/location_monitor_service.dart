import 'dart:async';

import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../features/reminders/domain/entities/reminder.dart';
import '../constants/app_constants.dart';
import 'notification_service.dart';

class LocationMonitorService {
  LocationMonitorService({
    required NotificationService notificationService,
    this.radiusMeters = 100,
    this.cooldown = const Duration(minutes: 10),
  }) : _notificationService = notificationService;

  final NotificationService _notificationService;
  final double radiusMeters;
  final Duration cooldown;

  StreamSubscription<Position>? _sub;
  List<Reminder> _reminders = const [];

  // Avoid notification spam in foreground session.
  final Map<String, DateTime> _lastNotifiedAtById = <String, DateTime>{};

  void updateReminders(List<Reminder> reminders) {
    _reminders = reminders;
  }

  Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // iOS requires "Always" permission for background location updates.
    if (Platform.isIOS && permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> start() async {
    if (_sub != null) return;

    final ok = await ensurePermission();
    if (!ok) return;

    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        // Keeps location updates while app is backgrounded (paused).
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Reminder is checking your location',
          notificationText: 'To notify you when you arrive at saved places.',
          enableWakeLock: true,
        ),
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      );
    }

    _sub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _onPosition(Position position) async {
    final now = DateTime.now();

    final candidates = _reminders.where((r) {
      if (r.isDone) return false;
      if (r.type != ReminderType.location) return false;
      return r.latitude != null && r.longitude != null;
    });

    for (final reminder in candidates) {
      final lastAt = _lastNotifiedAtById[reminder.id];
      if (lastAt != null && now.difference(lastAt) < cooldown) {
        continue;
      }

      final d = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        reminder.latitude!,
        reminder.longitude!,
      );

      if (d <= radiusMeters) {
        _lastNotifiedAtById[reminder.id] = now;

        final place = reminder.locationLabel?.trim();
        final body = (place != null && place.isNotEmpty)
            ? 'You are near $place'
            : 'You arrived within ${radiusMeters.toStringAsFixed(0)}m';

        await _notificationService.showNowForReminder(reminder, body: body);
      }
    }
  }
}
