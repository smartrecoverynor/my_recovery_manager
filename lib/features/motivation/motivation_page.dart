import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../recommendation/models/mrm_cra_assessment.dart';

class MotivationPage extends StatefulWidget {
  final MrmCraAssessment? assessment;

  const MotivationPage({super.key, this.assessment});

  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage> {
  double _importance = 5;
  double _confidence = 5;
  late final MrmCraAssessment _assessment;

  @override
  void initState() {
    super.initState();
    _assessment = widget.assessment ??
        MrmCraAssessment(
          auditInterpretationCategory:
              AuditInterpretationCategory.otherOrUnspecified,
        );

    _importance = (_assessment.motivationImportance ?? 5).toDouble();
    _confidence = (_assessment.motivationConfidence ?? 5).toDouble();
  }

  void _continue() {
    _assessment.motivationImportance = _importance.round();
    _assessment.motivationConfidence = _confidence.round();
    context.go('/recommendation-factors', extra: _assessment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartlegging'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Steg 2 av 5',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Motivasjon',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'De neste spørsmålene hjelper oss med å tilpasse appen til deg.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Hvor viktig er det for deg å endre alkoholbruken din?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _importance.round().toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Slider(
                value: _importance,
                min: 1,
                max: 10,
                divisions: 9,
                label: _importance.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _importance = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ikke viktig',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Svært viktig',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Hvis du bestemte deg for å endre alkoholbruken din, '
                'hvor stor tro har du på at du kan få det til?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _confidence.round().toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Slider(
                value: _confidence,
                min: 1,
                max: 10,
                divisions: 9,
                label: _confidence.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _confidence = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Svært liten tro',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Helt sikker',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Neste'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
