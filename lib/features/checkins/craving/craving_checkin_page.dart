import 'package:flutter/material.dart';

import 'package:my_recovery_manager/data/models/daily_checkin.dart';
import 'package:my_recovery_manager/data/repositories/daily_checkin_repository.dart';

import '../../../core/utils/app_day.dart';

class CravingCheckinPage extends StatefulWidget {
  const CravingCheckinPage({super.key});

  @override
  State<CravingCheckinPage> createState() => _CravingCheckinPageState();
}

class _CravingCheckinPageState extends State<CravingCheckinPage> {
  double _craving = 1;

  String get _cravingLabel {
    if (_craving == 1) {
      return 'Ingen';
    } else if (_craving == 5) {
      return 'Moderat';
    } else if (_craving == 10) {
      return 'Ekstrem';
    } else if (_craving < 5) {
      return 'Lav';
    } else {
      return 'Høy';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTodayCheckin();
  }

  Future<void> _loadTodayCheckin() async {
    final now = DateTime.now();
    final appDate = getAppDate(now);

    final repository = DailyCheckinRepository();

    final checkin = await repository.getByDate(
      userId: 'local-user',
      appDate: appDate,
    );

    if (!mounted) return;

    if (checkin != null && checkin.craving != null) {
      setState(() {
        _craving = checkin.craving!.toDouble();
      });
    }
  }

  Future<void> _saveCraving() async {
    final now = DateTime.now();
    final appDate = getAppDate(now);

    final repository = DailyCheckinRepository();

    final existingCheckin = await repository.getByDate(
      userId: 'local-user',
      appDate: appDate,
    );

    final checkin = DailyCheckin.create(
      id: existingCheckin?.id ?? now.microsecondsSinceEpoch.toString(),
      userId: 'local-user',
      dateTime: now,
      mood: existingCheckin?.mood,
      craving: _craving.round(),
      alcoholUnits: existingCheckin?.alcoholUnits ?? 0,
      journalText: existingCheckin?.journalText,
    );

    await repository.upsert(checkin);

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Craving'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Craving',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Marker hvor sterk lysten til å drikke har vært i dag.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),

              const SizedBox(height: 56),

              Center(
                child: Text(
                  _craving.round().toString(),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Center(
                child: Text(
                  _cravingLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Slider(
                value: _craving,
                min: 1,
                max: 10,
                divisions: 9,
                label: _craving.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _craving = value;
                  });
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '5',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '10',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ingen',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'Moderat',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'Ekstrem',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveCraving,
                  child: const Text(
                    'Lagre',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}