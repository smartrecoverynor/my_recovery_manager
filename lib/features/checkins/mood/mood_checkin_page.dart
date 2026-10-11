import 'package:flutter/material.dart';

import 'package:my_recovery_manager/data/models/daily_checkin.dart';
import 'package:my_recovery_manager/data/repositories/daily_checkin_repository.dart';

import '../../../core/utils/app_day.dart';

class MoodCheckinPage extends StatefulWidget {
  const MoodCheckinPage({super.key});

  @override
  State<MoodCheckinPage> createState() => _MoodCheckinPageState();
}

class _MoodCheckinPageState extends State<MoodCheckinPage> {
  int? _selectedMood;

  final List<_MoodOption> _moods = const [
    _MoodOption(
      value: 1,
      label: 'Veldig dårlig',
      color: Color(0xFFE9272F),
      expression: MoodExpression.veryBad,
    ),
    _MoodOption(
      value: 2,
      label: 'Dårlig',
      color: Color(0xFFF59A23),
      expression: MoodExpression.bad,
    ),
    _MoodOption(
      value: 3,
      label: 'Nøytral',
      color: Color(0xFFFFE500),
      expression: MoodExpression.neutral,
    ),
    _MoodOption(
      value: 4,
      label: 'Bra',
      color: Color(0xFFB5D82A),
      expression: MoodExpression.good,
    ),
    _MoodOption(
      value: 5,
      label: 'Veldig bra',
      color: Color(0xFF31B54A),
      expression: MoodExpression.veryGood,
    ),
  ];

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

    if (checkin != null && checkin.mood != null) {
      setState(() {
        _selectedMood = checkin.mood;
      });
    }
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) return;

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
      mood: _selectedMood,
      craving: existingCheckin?.craving,
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
        title: const Text('Humør'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hvordan har du det i dag?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Velg det alternativet som best beskriver '
                    'hvordan du har det akkurat nå.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood.value;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood.value;
                      });
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colors.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: CustomPaint(
                            painter: _MoodFacePainter(
                              color: mood.color,
                              expression: mood.expression,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${mood.value}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 48),

              Center(
                child: Text(
                  _selectedMood == null
                      ? 'Velg humør'
                      : _moods[_selectedMood! - 1].label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _selectedMood == null ? null : _saveMood,
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

class _MoodOption {
  final int value;
  final String label;
  final Color color;
  final MoodExpression expression;

  const _MoodOption({
    required this.value,
    required this.label,
    required this.color,
    required this.expression,
  });
}

enum MoodExpression {
  veryGood,
  good,
  neutral,
  bad,
  veryBad,
}

class _MoodFacePainter extends CustomPainter {
  final Color color;
  final MoodExpression expression;

  const _MoodFacePainter({
    required this.color,
    required this.expression,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius,
      facePaint,
    );

    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final eyeY = center.dy - radius * 0.25;
    final eyeX = radius * 0.35;
    final eyeRadius = radius * 0.09;

    canvas.drawCircle(
      Offset(center.dx - eyeX, eyeY),
      eyeRadius,
      eyePaint,
    );

    canvas.drawCircle(
      Offset(center.dx + eyeX, eyeY),
      eyeRadius,
      eyePaint,
    );

    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();

    switch (expression) {
      case MoodExpression.veryGood:
        mouthPath.moveTo(
          center.dx - radius * 0.48,
          center.dy + radius * 0.05,
        );

        mouthPath.quadraticBezierTo(
          center.dx,
          center.dy + radius * 0.75,
          center.dx + radius * 0.48,
          center.dy + radius * 0.05,
        );
        break;

      case MoodExpression.good:
        mouthPath.moveTo(
          center.dx - radius * 0.45,
          center.dy + radius * 0.15,
        );

        mouthPath.quadraticBezierTo(
          center.dx,
          center.dy + radius * 0.55,
          center.dx + radius * 0.45,
          center.dy + radius * 0.15,
        );
        break;

      case MoodExpression.neutral:
        canvas.drawLine(
          Offset(
            center.dx - radius * 0.38,
            center.dy + radius * 0.30,
          ),
          Offset(
            center.dx + radius * 0.38,
            center.dy + radius * 0.30,
          ),
          mouthPaint,
        );
        return;

      case MoodExpression.bad:
        mouthPath.moveTo(
          center.dx - radius * 0.45,
          center.dy + radius * 0.40,
        );

        mouthPath.quadraticBezierTo(
          center.dx,
          center.dy + radius * 0.05,
          center.dx + radius * 0.45,
          center.dy + radius * 0.40,
        );
        break;

      case MoodExpression.veryBad:
        mouthPath.moveTo(
          center.dx - radius * 0.45,
          center.dy + radius * 0.50,
        );

        mouthPath.quadraticBezierTo(
          center.dx,
          center.dy + radius * 0.05,
          center.dx + radius * 0.45,
          center.dy + radius * 0.50,
        );
        break;
    }

    canvas.drawPath(
      mouthPath,
      mouthPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _MoodFacePainter oldDelegate,
      ) {
    return oldDelegate.color != color ||
        oldDelegate.expression != expression;
  }
}