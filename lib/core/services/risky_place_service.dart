import 'package:geolocator/geolocator.dart';

import '../../data/models/risky_place.dart';
import '../../data/models/risky_place_alert.dart';
import '../../data/repositories/risky_place_alert_repository.dart';
import '../../data/repositories/risky_place_notification_cooldown_repository.dart';
import '../../data/repositories/risky_place_repository.dart';

class RiskyPlaceService {
  RiskyPlaceService._();

  static final RiskyPlaceService instance = RiskyPlaceService._();

  final RiskyPlaceRepository _placeRepository = RiskyPlaceRepository();
  final RiskyPlaceAlertRepository _alertRepository =
      RiskyPlaceAlertRepository();
  final RiskyPlaceNotificationCooldownRepository _cooldownRepository =
      RiskyPlaceNotificationCooldownRepository();

  static const Duration _notificationCooldown = Duration(hours: 2);

  /// Returnerer det første risikostedet brukeren befinner seg
  /// innenfor og som har en aktiv varslingsperiode akkurat nå.
  ///
  /// Et sted returneres ikke dersom det allerede har utløst et
  /// varsel de siste to timene.
  Future<RiskyPlace?> findActiveRiskyPlace(
    Position position, {
    String userId = 'local-user',
  }) async {
    final places = await _placeRepository.getAll(userId: userId);

    final now = DateTime.now();

    for (final place in places) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.latitude,
        place.longitude,
      );

      if (distance > place.radiusMeters) {
        continue;
      }

      final alerts = await _alertRepository.getForPlace(place.id);

      var activeAlert = false;

      for (final alert in alerts) {
        if (_isAlertActive(alert, now)) {
          activeAlert = true;
          break;
        }
      }

      if (!activeAlert) {
        continue;
      }

      final lastNotifiedAt = await _cooldownRepository.getLastNotifiedAt(
        place.id,
      );

      if (lastNotifiedAt != null) {
        final cooldownExpiresAt = lastNotifiedAt.add(_notificationCooldown);

        if (now.isBefore(cooldownExpiresAt)) {
          continue;
        }
      }

      return place;
    }

    return null;
  }

  Future<void> recordNotification(RiskyPlace place) async {
    await _cooldownRepository.saveLastNotifiedAt(place.id, DateTime.now());
  }

  bool _isAlertActive(RiskyPlaceAlert alert, DateTime now) {
    final weekday = now.weekday;

    final activeDays = alert.daysOfWeek
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toSet();

    if (!activeDays.contains(weekday)) {
      return false;
    }

    final fromMinutes = _timeToMinutes(alert.fromTime);
    final toMinutes = _timeToMinutes(alert.toTime);

    if (fromMinutes == null || toMinutes == null) {
      return false;
    }

    final currentMinutes = now.hour * 60 + now.minute;

    // Vanlig periode, f.eks. 08:00–17:00.
    if (fromMinutes <= toMinutes) {
      return currentMinutes >= fromMinutes && currentMinutes <= toMinutes;
    }

    // Periode som går over midnatt, f.eks. 22:00–02:00.
    return currentMinutes >= fromMinutes || currentMinutes <= toMinutes;
  }

  int? _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return hour * 60 + minute;
  }
}
