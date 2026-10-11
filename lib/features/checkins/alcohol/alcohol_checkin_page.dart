import 'package:flutter/material.dart';

import '../../../core/widgets/info_icon.dart';
import '../../../core/widgets/success_celebration.dart';
import 'package:my_recovery_manager/data/models/daily_checkin.dart';
import 'package:my_recovery_manager/data/repositories/daily_checkin_repository.dart';
import '../../../core/utils/app_day.dart';

class AlcoholCheckinPage extends StatefulWidget {
  const AlcoholCheckinPage({super.key});

  @override
  State<AlcoholCheckinPage> createState() => _AlcoholCheckinPageState();
}

class _AlcoholCheckinPageState extends State<AlcoholCheckinPage> {
  int _units = 0;

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

    if (checkin != null) {
      setState(() {
        _units = checkin.alcoholUnits;
      });
    }
  }

  void _decreaseUnits() {
    if (_units > 0) {
      setState(() {
        _units--;
      });
    }
  }

  void _increaseUnits() {
    setState(() {
      _units++;
    });
  }

  Future<void> _saveCheckin() async {
    try {
      final now = DateTime.now();

      final checkin = DailyCheckin.create(
        id: now.microsecondsSinceEpoch.toString(),
        userId: 'local-user',
        dateTime: now,
        alcoholUnits: _units,
      );

      final repository = DailyCheckinRepository();

      await repository.upsert(checkin);

      if (!mounted) return;

      if (_units == 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return SuccessCelebration(
              onFinished: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
            );
          },
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      //fjernet feillogging

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke lagre registreringen: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alkohol'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alkohol',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Hvor mange alkoholenheter har du drukket i dag?',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),

              const SizedBox(height: 24),

              const Center(
                child: InfoIcon(
                  title: 'Hva er én alkoholenhet?',
                  message:
                  'Én alkoholenhet tilsvarer omtrent:\n\n'
                      '• 0,33 liter øl\n'
                      '• 12–14 cl vin\n'
                      '• 4 cl brennevin',
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCounterButton(
                    icon: Icons.remove,
                    onPressed: _decreaseUnits,
                  ),

                  const SizedBox(width: 32),

                  Column(
                    children: [
                      Text(
                        _units.toString(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        'alkoholenheter',
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 32),

                  _buildCounterButton(
                    icon: Icons.add,
                    onPressed: _increaseUnits,
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveCheckin,
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

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          size: 28,
        ),
      ),
    );
  }
}