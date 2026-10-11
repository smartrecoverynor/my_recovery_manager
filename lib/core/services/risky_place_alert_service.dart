import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/models/risky_place.dart';
import '../../data/repositories/risky_place_repository.dart';
import '../../data/repositories/risky_place_settings_repository.dart';

class RiskyPlaceAlertService {
  RiskyPlaceAlertService._();

  static final RiskyPlaceAlertService instance = RiskyPlaceAlertService._();

  final RiskyPlaceRepository _placeRepository = RiskyPlaceRepository();

  final RiskyPlaceSettingsRepository _settingsRepository =
      RiskyPlaceSettingsRepository();

  RiskyPlace? _pendingPlace;

  RiskyPlace? get pendingPlace => _pendingPlace;

  bool get hasPendingAlert => _pendingPlace != null;

  void setPendingAlert(RiskyPlace place) {
    _pendingPlace = place;
  }

  Future<void> loadPendingRegion(String regionId) async {
    final places = await _placeRepository.getAll(userId: 'local-user');

    for (final place in places) {
      if (place.id == regionId) {
        _pendingPlace = place;
        return;
      }
    }
  }

  void clearPendingAlert() {
    _pendingPlace = null;
  }

  Future<void> showPendingAlert() async {
    final place = _pendingPlace;

    if (place == null) {
      return;
    }

    final context = rootNavigatorKey.currentContext;

    if (context == null) {
      return;
    }

    final instruction = await _settingsRepository.getGlobalInstruction();

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Risikofylt sted'),
          content: Text('Du er nå ved ${place.name}.'),
          actions: [
            TextButton(
              onPressed: () async {
                if (instruction == null || instruction.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingen beskjed er registrert.'),
                    ),
                  );
                  return;
                }

                await showDialog<void>(
                  context: dialogContext,
                  builder: (messageContext) {
                    return AlertDialog(
                      title: const Text('Din beskjed'),
                      content: Text(instruction),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(messageContext).pop();
                          },
                          child: const Text('Tilbake'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Vis beskjed'),
            ),
            FilledButton(onPressed: null, child: const Text('Gå til coping')),
            TextButton(
              onPressed: () {
                clearPendingAlert();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Lukk'),
            ),
          ],
        );
      },
    );
  }
}
