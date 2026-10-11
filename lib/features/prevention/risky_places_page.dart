import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/risky_place.dart';
import '../../data/models/risky_place_alert.dart';
import '../../data/repositories/risky_place_alert_repository.dart';
import '../../data/repositories/risky_place_repository.dart';
import '../../data/repositories/risky_place_settings_repository.dart';
import '../../core/services/risky_place_region_service.dart';

class RiskyPlacesPage extends StatefulWidget {
  const RiskyPlacesPage({super.key});

  @override
  State<RiskyPlacesPage> createState() => _RiskyPlacesPageState();
}

class _RiskyPlacesPageState extends State<RiskyPlacesPage> {
  final MapController _mapController = MapController();

  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  final RiskyPlaceRepository _riskyPlaceRepository = RiskyPlaceRepository();

  final RiskyPlaceAlertRepository _alertRepository =
  RiskyPlaceAlertRepository();

  final RiskyPlaceSettingsRepository _settingsRepository =
  RiskyPlaceSettingsRepository();

  Timer? _searchDebounce;

  List<_SearchResult> _searchResults = [];
  List<RiskyPlace> _savedPlaces = [];

  bool _isSearching = false;
  bool _isSelectingNewPlace = false;

  LatLng? _selectedPoint;

  double _radius = 250;

  String? _editingPlaceId;

  final List<_ReminderPeriod> _periods = [];

  String? _globalInstruction;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
    _loadGlobalInstruction();
  }

  Future<void> _loadGlobalInstruction() async {
    final instruction = await _settingsRepository.getGlobalInstruction();

    if (!mounted) {
      return;
    }

    setState(() {
      _globalInstruction = instruction;
    });
  }

  Future<void> _showGlobalInstructionDialog() async {
    final controller = TextEditingController(text: _globalInstruction ?? '');

    var instruction = _globalInstruction ?? '';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Din instruksjon ved risikofylte steder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Når du nærmer deg et sted du har registrert '
                        'som risikofylt, kan du få en påminnelse med '
                        'en kort instruksjon til deg selv.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Skriv en kort instruksjon du ønsker å se '
                        'i slike situasjoner.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLength: 100,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                      'F.eks. Gå bort fra stedet og kontakt en venn.',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        instruction = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Gjør dette senere'),
                ),
                FilledButton(
                  onPressed: instruction.trim().isEmpty
                      ? null
                      : () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Lagre instruksjon'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == true) {
      final value = instruction.trim();

      await _settingsRepository.saveGlobalInstruction(value);

      if (!mounted) {
        return;
      }

      setState(() {
        _globalInstruction = value;
      });
    } else {
      if (!mounted) {
        return;
      }

      setState(() {});
    }
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final places = await _riskyPlaceRepository.getAll(userId: 'local-user');

      if (!mounted) {
        return;
      }

      setState(() {
        _savedPlaces = places;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke laste lagrede steder: $e')),
      );
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'no',
        'accept-language': 'no',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'My Recovery Manager/1.0'},
      );

      if (response.statusCode != 200) {
        throw Exception('Søket mislyktes');
      }

      final data = jsonDecode(response.body) as List<dynamic>;

      final results = data.map((item) {
        final result = item as Map<String, dynamic>;

        return _SearchResult(
          displayName: result['display_name'] as String,
          latitude: double.parse(result['lat'] as String),
          longitude: double.parse(result['lon'] as String),
        );
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke søke etter stedet.')),
      );
    }
  }

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.latitude, result.longitude);

    _mapController.move(point, 15);

    setState(() {
      _selectedPoint = point;
      _searchResults = [];
      _searchController.text = result.displayName.split(',').first;
    });
  }

  void _selectMapPoint(TapPosition tapPosition, LatLng point) {
    if (!_isSelectingNewPlace) {
      return;
    }

    setState(() {
      _selectedPoint = point;
      _searchResults = [];
      _searchController.clear();
      _isSelectingNewPlace = false;
      _editingPlaceId = null;
      _nameController.clear();
      _noteController.clear();
      _periods.clear();
      _radius = 250;
    });
  }

  void _startNewPlaceSelection() {
    setState(() {
      _isSelectingNewPlace = true;
      _selectedPoint = null;
      _editingPlaceId = null;

      _nameController.clear();
      _noteController.clear();
      _searchResults = [];
      _searchController.clear();

      _periods.clear();
      _radius = 250;
    });
  }

  Future<void> _locateMe() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posisjonstjenester er slått av.')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tilgang til posisjon ble avslått.')),
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posisjonstilgang er avslått i innstillingene.'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    if (!mounted) return;

    _mapController.move(
      LatLng(position.latitude, position.longitude),
      14,
    );
  }

  Future<void> _selectSavedPlace(RiskyPlace place) async {
    final point = LatLng(place.latitude, place.longitude);

    _mapController.move(point, 15);

    final alerts = await _alertRepository.getForPlace(place.id);

    if (!mounted) {
      return;
    }

    await _showSavedPlaceDialog(place, alerts);
  }

  Future<void> _showSavedPlaceDialog(
      RiskyPlace place,
      List<RiskyPlaceAlert> alerts,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Text(place.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risikosone',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Radius: '
                      '${place.radiusMeters.round()} m',
                ),
                if (place.note != null && place.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Notater',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(place.note!),
                ],
                const SizedBox(height: 20),
                Text(
                  'Varslinger',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (alerts.isEmpty)
                  Text(
                    'Ingen varslingsperioder.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else
                  ...alerts.map((alert) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAlertDays(alert.daysOfWeek),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            '${alert.fromTime} – '
                                '${alert.toTime}',
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Lukk'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await _editSavedPlace(place, alerts);
              },
              child: const Text('Rediger'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);

                final confirmed = await _confirmDelete(place);

                if (!confirmed || !mounted) {
                  return;
                }

                navigator.pop();

                await _deleteSavedPlace(place);
              },
              child: Text(
                'Slett',
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editSavedPlace(
      RiskyPlace place,
      List<RiskyPlaceAlert> alerts,
      ) async {
    final periods = alerts.map((alert) {
      final days = List<bool>.filled(7, false);

      for (final value in alert.daysOfWeek.split(',')) {
        final day = int.tryParse(value);

        if (day != null && day >= 1 && day <= 7) {
          days[day - 1] = true;
        }
      }

      final fromParts = alert.fromTime.split(':');

      final toParts = alert.toTime.split(':');

      final fromTime = TimeOfDay(
        hour: int.parse(fromParts[0]),
        minute: int.parse(fromParts[1]),
      );

      final toTime = TimeOfDay(
        hour: int.parse(toParts[0]),
        minute: int.parse(toParts[1]),
      );

      return _ReminderPeriod(
        days: days,
        fromTime: fromTime,
        toTime: toTime,
      );
    }).toList();

    setState(() {
      _isSelectingNewPlace = false;
      _editingPlaceId = place.id;

      _selectedPoint = LatLng(place.latitude, place.longitude);

      _radius = place.radiusMeters;

      _nameController.text = place.name;
      _noteController.text = place.note ?? '';

      _searchResults = [];
      _searchController.text = place.name;

      _periods
        ..clear()
        ..addAll(periods);
    });
  }

  Future<bool> _confirmDelete(RiskyPlace place) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Slett risikofylt sted?'),
          content: Text('Vil du slette "${place.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Slett'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deleteSavedPlace(RiskyPlace place) async {
    try {
      await RiskyPlaceRegionService.instance.stopMonitoring(place.id);

      await _riskyPlaceRepository.delete(place.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _savedPlaces.removeWhere((item) => item.id == place.id);

        if (_editingPlaceId == place.id) {
          _editingPlaceId = null;
          _selectedPoint = null;
          _nameController.clear();
          _periods.clear();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Risikofylt sted er slettet.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Kunne ikke slette stedet: $e')),
      );
    }
  }

  Future<void> _addPeriod() async {
    final period = await _showPeriodDialog();

    if (period == null || !mounted) {
      return;
    }

    setState(() {
      _periods.add(period);
    });
  }

  Future<_ReminderPeriod?> _showPeriodDialog({
    _ReminderPeriod? initial,
  }) async {
    final selectedDays = List<bool>.from(
      initial?.days ?? List<bool>.filled(7, true),
    );

    TimeOfDay fromTime =
        initial?.fromTime ?? const TimeOfDay(hour: 18, minute: 0);

    TimeOfDay toTime =
        initial?.toTime ?? const TimeOfDay(hour: 3, minute: 0);

    return showDialog<_ReminderPeriod>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = Theme.of(context).colorScheme;

            return AlertDialog(
              title: const Text('Varslingsperiode'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktive dager',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(7, (index) {
                        const labels = [
                          'Man',
                          'Tir',
                          'Ons',
                          'Tor',
                          'Fre',
                          'Lør',
                          'Søn',
                        ];

                        return FilterChip(
                          label: Text(labels[index]),
                          selected: selectedDays[index],
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedDays[index] = selected;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fra'),
                      trailing: Text(
                        fromTime.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: fromTime,
                          initialEntryMode: TimePickerEntryMode.input,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            fromTime = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Til'),
                      trailing: Text(
                        toTime.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: toTime,
                          initialEntryMode: TimePickerEntryMode.input,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            toTime = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tidsperioden kan gå over midnatt, '
                          'for eksempel 18:00–03:00.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Avbryt'),
                ),
                FilledButton(
                  onPressed: selectedDays.contains(true)
                      ? () {
                    Navigator.of(dialogContext).pop(
                      _ReminderPeriod(
                        days: selectedDays,
                        fromTime: fromTime,
                        toTime: toTime,
                      ),
                    );
                  }
                      : null,
                  child: const Text('Legg til'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removePeriod(int index) {
    setState(() {
      _periods.removeAt(index);
    });
  }

  String _formatDays(List<bool> days) {
    const labels = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    final selected = <String>[];

    for (var i = 0; i < days.length; i++) {
      if (days[i]) {
        selected.add(labels[i]);
      }
    }

    if (selected.length == 7) {
      return 'Alle dager';
    }

    if (selected.length == 5 &&
        days[0] &&
        days[1] &&
        days[2] &&
        days[3] &&
        days[4]) {
      return 'Man–fre';
    }

    if (selected.length == 2 && days[5] && days[6]) {
      return 'Lør–søn';
    }

    return selected.join(', ');
  }

  String _formatAlertDays(String daysOfWeek) {
    const labels = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    final days = daysOfWeek.split(',').map(int.parse).toSet();

    if (days.length == 7) {
      return 'Alle dager';
    }

    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Man–fre';
    }

    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Lør–søn';
    }

    return days
        .where((day) => day >= 1 && day <= 7)
        .map((day) => labels[day - 1])
        .join(', ');
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<bool> _showLocationPermissionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tillatelse til posisjon'),
          content: const Text(
            'For at MRM skal kunne varsle deg når du kommer til '
                'et risikosted, må appen kunne bruke posisjonen din '
                'også når appen ikke er åpen.\n\n'
                'Posisjonen brukes til å oppdage når du befinner deg '
                'i nærheten av et risikosted du selv har registrert. '
                'Den brukes ikke til reklame eller sporing av '
                'bevegelsene dine.\n\n'
                'Du kan når som helst endre tillatelsen i innstillingene '
                'på telefonen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Ikke nå'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Fortsett'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _saveRiskyPlace() async {
    if (_selectedPoint == null) {
      return;
    }

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gi stedet et navn før du lagrer.')),
      );
      return;
    }

    if (_periods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Legg til minst én varslingsperiode.'),
        ),
      );
      return;
    }

    final permission = await Geolocator.checkPermission();

    if (!mounted) {
      return;
    }

    if (permission != LocationPermission.always) {
      final locationPermissionAccepted =
      await _showLocationPermissionDialog();

      if (!locationPermissionAccepted || !mounted) {
        return;
      }
    }

    final now = DateTime.now();

    if (_editingPlaceId == null && _savedPlaces.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du kan maks registrere 20 risikosteder.'),
        ),
      );
      return;
    }

    final placeId = _editingPlaceId ?? const Uuid().v4();

    final existingPlace = _editingPlaceId == null
        ? null
        : _savedPlaces
        .where((place) => place.id == _editingPlaceId)
        .firstOrNull;

    final riskyPlace = RiskyPlace(
      id: placeId,
      userId: existingPlace?.userId ?? 'local-user',
      name: name,
      latitude: _selectedPoint!.latitude,
      longitude: _selectedPoint!.longitude,
      radiusMeters: _radius,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: existingPlace?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _riskyPlaceRepository.save(riskyPlace);

      if (existingPlace != null) {
        await RiskyPlaceRegionService.instance.stopMonitoring(
          existingPlace.id,
        );
      }

      await _alertRepository.deleteForPlace(riskyPlace.id);

      for (final period in _periods) {
        final days = <int>[];

        for (var i = 0; i < period.days.length; i++) {
          if (period.days[i]) {
            days.add(i + 1);
          }
        }

        final alert = RiskyPlaceAlert(
          id: const Uuid().v4(),
          riskyPlaceId: riskyPlace.id,
          daysOfWeek: days.join(','),
          fromTime: _formatTime(period.fromTime),
          toTime: _formatTime(period.toTime),
          createdAt: now,
          updatedAt: now,
        );

        await _alertRepository.save(alert);
      }

      // VIKTIG:
      // Regionmonitorering startes først
      // etter at alle varslingsperioder
      // er lagret.
      await RiskyPlaceRegionService.instance.startMonitoring(riskyPlace);

      if (!mounted) {
        return;
      }

      await _loadSavedPlaces();

      if (!mounted) {
        return;
      }

      setState(() {
        _editingPlaceId = null;
        _isSelectingNewPlace = false;
        _selectedPoint = null;
        _nameController.clear();
        _searchController.clear();
        _periods.clear();
        _radius = 250;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingPlace == null
                ? 'Risikofylt sted er lagret.'
                : 'Risikofylt sted er oppdatert.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Kunne ikke lagre stedet: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risikofylte steder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {},
          ),
          PopupMenuButton<String>(
            tooltip: 'Innstillinger',
            onSelected: (value) {
              if (value == 'instruction') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }

                  _showGlobalInstructionDialog();
                });
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'instruction',
                child: Text('Min instruksjon'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(59.9139, 10.7522),
              initialZoom: 12,
              onTap: _selectMapPoint,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'no.smartrecovery.my_recovery_manager',
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),

              // Lagrede risikosoner
              if (_savedPlaces.isNotEmpty)
                CircleLayer(
                  circles: _savedPlaces.map((place) {
                    return CircleMarker(
                      point: LatLng(place.latitude, place.longitude),
                      radius: place.radiusMeters,
                      useRadiusInMeter: true,
                      color: colors.primary.withValues(alpha: 0.12),
                      borderColor: colors.primary,
                      borderStrokeWidth: 2,
                    );
                  }).toList(),
                ),

              // Pinner for lagrede steder
              if (_savedPlaces.isNotEmpty)
                MarkerLayer(
                  markers: _savedPlaces.map((place) {
                    return Marker(
                      point: LatLng(place.latitude, place.longitude),
                      width: 45,
                      height: 45,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _selectSavedPlace(place);
                        },
                        child: Icon(
                          Icons.location_pin,
                          size: 45,
                          color: colors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Nytt/valgt sted
              if (_selectedPoint != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedPoint!,
                      radius: _radius,
                      useRadiusInMeter: true,
                      color: colors.error.withValues(alpha: 0.15),
                      borderColor: colors.error,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_pin,
                        size: 50,
                        color: colors.error,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(12),
                  color: colors.surfaceContainerLow,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Zoom inn',
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final center = _mapController.camera.center;

                          final zoom = _mapController.camera.zoom;

                          _mapController.move(center, zoom + 0.5);
                        },
                      ),
                      Divider(
                        height: 1,
                        color: colors.outlineVariant,
                      ),
                      IconButton(
                        tooltip: 'Zoom ut',
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          final center = _mapController.camera.center;

                          final zoom = _mapController.camera.zoom;

                          _mapController.move(center, zoom - 0.5);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(12),
                  color: colors.surfaceContainerLow,
                  child: IconButton(
                    tooltip: 'Finn min posisjon',
                    icon: const Icon(Icons.my_location),
                    onPressed: _locateMe,
                  ),
                ),
              ],
            ),
          ),

          // Søk og knapp for nytt sted
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(12),
                  color: colors.surfaceContainerLow,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      _searchDebounce?.cancel();

                      final query = value.trim();

                      if (query.isNotEmpty) {
                        _search(query);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Søk etter sted eller adresse',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                          : null,
                      filled: true,
                      fillColor: colors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _savedPlaces.length >= 20
                      ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Du kan maks registrere 20 risikosteder. '
                                'Slett et risikosted om du ønsker å legge til et nytt.',
                            style: TextStyle(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : ElevatedButton.icon(
                    onPressed: _startNewPlaceSelection,
                    icon: Icon(
                      _isSelectingNewPlace
                          ? Icons.touch_app
                          : Icons.add_location_alt_outlined,
                    ),
                    label: Text(
                      _isSelectingNewPlace
                          ? 'Trykk på kartet for å plassere'
                          : 'Marker nytt sted',
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outlineVariant,
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colors.outlineVariant,
                      ),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];

                        return ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: colors.primary,
                          ),
                          title: Text(
                            result.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Panel for nytt eller redigert sted
          if (_selectedPoint != null)
            Positioned.fill(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(18),
                  color: colors.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _editingPlaceId == null
                                      ? 'Nytt risikofylt sted'
                                      : 'Rediger risikofylt sted',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Avbryt',
                                onPressed: () {
                                  setState(() {
                                    _selectedPoint = null;
                                    _editingPlaceId = null;
                                    _nameController.clear();
                                    _searchController.clear();
                                    _searchResults = [];
                                    _periods.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Navn på sted',
                              hintText: 'F.eks. baren på hjørnet',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notater',
                              hintText: 'Eventuelle notater om stedet',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Risikosone',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Velg hvor stort område du '
                                'vil bli varslet innenfor.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Radius',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                '${_radius.round()} m',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            value: _radius,
                            label: '${_radius.round()} m',
                            onChanged: (value) {
                              setState(() {
                                _radius = value;
                              });
                            },
                          ),
                          Divider(color: colors.outlineVariant),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Varsling',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addPeriod,
                                icon: const Icon(Icons.add),
                                label: const Text('Legg til'),
                              ),
                            ],
                          ),
                          if (_periods.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Ingen varslingsperioder er lagt til.',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ..._periods.asMap().entries.map((entry) {
                            final index = entry.key;
                            final period = entry.value;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  _formatDays(period.days),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  '${period.fromTime.format(context)}'
                                      ' – '
                                      '${period.toTime.format(context)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Rediger varslingsperiode',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                      ),
                                      onPressed: () async {
                                        final updatedPeriod =
                                        await _showPeriodDialog(
                                          initial: period,
                                        );

                                        if (updatedPeriod == null ||
                                            !mounted) {
                                          return;
                                        }

                                        setState(() {
                                          _periods[index] = updatedPeriod;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Slett varslingsperiode',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                      ),
                                      onPressed: () =>
                                          _removePeriod(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveRiskyPlace,
                              child: Text(
                                _editingPlaceId == null
                                    ? 'Lagre risikofylt sted'
                                    : 'Lagre endringer',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderPeriod {
  final List<bool> days;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;

  const _ReminderPeriod({
    required this.days,
    required this.fromTime,
    required this.toTime,
  });
}

class _SearchResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const _SearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}