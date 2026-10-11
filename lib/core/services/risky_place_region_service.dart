import 'package:flutter/services.dart';

import '../../data/models/risky_place.dart';
import '../../data/repositories/risky_place_alert_repository.dart';
import '../../data/repositories/risky_place_repository.dart';

class RiskyPlaceRegionService {
  RiskyPlaceRegionService._();

  static final RiskyPlaceRegionService instance = RiskyPlaceRegionService._();

  static const MethodChannel _channel = MethodChannel('mrm/risky_places');

  final RiskyPlaceRepository _placeRepository = RiskyPlaceRepository();

  final RiskyPlaceAlertRepository _alertRepository =
      RiskyPlaceAlertRepository();

  Future<void> startMonitoring(RiskyPlace place) async {
    final alerts = await _alertRepository.getForPlace(place.id);

    await _channel.invokeMethod('startMonitoring', {
      'id': place.id,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'radiusMeters': place.radiusMeters,
      'alerts': alerts.map((alert) {
        return {
          'daysOfWeek': alert.daysOfWeek,
          'fromTime': alert.fromTime,
          'toTime': alert.toTime,
        };
      }).toList(),
    });
  }

  Future<void> stopMonitoring(String placeId) async {
    await _channel.invokeMethod('stopMonitoring', {'id': placeId});
  }

  Future<void> stopAllMonitoring() async {
    await _channel.invokeMethod('stopAllMonitoring');
  }

  Future<void> syncAllPlaces() async {
    final places = await _placeRepository.getAll(userId: 'local-user');

    for (final place in places) {
      await startMonitoring(place);
    }
  }

  Future<String?> getPendingRegion() async {
    return _channel.invokeMethod<String>('getPendingRegion');
  }

  Future<String?> consumeTappedRiskyPlace() async {
    return _channel.invokeMethod<String>('consumeTappedRiskyPlace');
  }
}
