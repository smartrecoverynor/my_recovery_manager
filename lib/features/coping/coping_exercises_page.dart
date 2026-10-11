import 'dart:async';

import 'package:flutter/material.dart';

class CopingExercisesPage extends StatelessWidget {
  const CopingExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Øvelser')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Øvelser',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Korte øvelser du kan bruke når du opplever '
                'sug, uro eller trenger å roe deg ned.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              _ExerciseCard(
                icon: Icons.waves_outlined,
                title: 'Urge surfing',
                description:
                    'Observer suget uten å handle på det. '
                    'En kort øvelse for å stå i ubehaget til det avtar.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UrgeSurfingPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _ExerciseCard(
                icon: Icons.air_outlined,
                title: 'Pust og ro',
                description:
                    'Bruk Box Breathing til å rette oppmerksomheten '
                    'mot pusten og finne et roligere tempo.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BoxBreathingPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _ExerciseCard(
                icon: Icons.visibility_outlined,
                title: '5–4–3–2–1 grounding',
                description:
                    'Bruk sansene til å flytte oppmerksomheten '
                    'til det som skjer akkurat nå.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FiveFourThreeTwoOnePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _ExerciseCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = colors.secondary;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.65),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Box Breathing
// ═══════════════════════════════════════════════════

class BoxBreathingPage extends StatefulWidget {
  const BoxBreathingPage({super.key});

  @override
  State<BoxBreathingPage> createState() => _BoxBreathingPageState();
}

class _BoxBreathingPageState extends State<BoxBreathingPage>
    with SingleTickerProviderStateMixin {
  static const int _phaseDuration = 4;

  static const List<_BreathingPhase> _phases = [
    _BreathingPhase(name: 'Pust inn', instruction: 'Rolig inn gjennom nesen'),
    _BreathingPhase(name: 'Hold', instruction: 'Hold pusten rolig'),
    _BreathingPhase(name: 'Pust ut', instruction: 'Rolig ut gjennom munnen'),
    _BreathingPhase(name: 'Hold', instruction: 'Vent rolig før neste pust'),
  ];

  Timer? _timer;
  late final AnimationController _animationController;

  int _phaseIndex = 0;
  int _secondsRemaining = _phaseDuration;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _phaseDuration),
    );

    _animationController.value = 0.0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _start() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _startPhaseAnimation();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;

      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _nextPhase();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;

    _animationController.stop();

    setState(() {
      _isRunning = false;
    });
  }

  void _startPhaseAnimation() {
    if (!_isRunning) return;

    if (_phaseIndex == 0) {
      // Pust inn: jevn vekst over 4 sekunder.
      _animationController.forward(from: 0.0);
    } else if (_phaseIndex == 2) {
      // Pust ut: jevn sammentrekning over 4 sekunder.
      _animationController.reverse(from: 1.0);
    } else {
      // Hold: boksen står stille.
      _animationController.stop();
    }
  }

  void _nextPhase() {
    final nextIndex = (_phaseIndex + 1) % _phases.length;

    setState(() {
      _phaseIndex = nextIndex;
      _secondsRemaining = _phaseDuration;
    });

    _startPhaseAnimation();
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;

    _animationController.stop();
    _animationController.value = 0.0;

    setState(() {
      _phaseIndex = 0;
      _secondsRemaining = _phaseDuration;
      _isRunning = false;
    });
  }

  void _exit() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_phaseIndex];
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pust og ro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              const Text(
                'Box breathing',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Følg boksen og la pusten være rolig og jevn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final scale = 0.72 + (_animationController.value * 0.28);

                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: colors.secondary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_secondsRemaining',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              phase.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Text(
                phase.instruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Nullstill'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isRunning ? _pause : _start,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: colors.primary,
                      ),
                      child: Text(_isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextButton(onPressed: _exit, child: const Text('Avslutt')),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingPhase {
  final String name;
  final String instruction;

  const _BreathingPhase({required this.name, required this.instruction});
}

class FiveFourThreeTwoOnePage extends StatefulWidget {
  const FiveFourThreeTwoOnePage({super.key});

  @override
  State<FiveFourThreeTwoOnePage> createState() =>
      _FiveFourThreeTwoOnePageState();
}

class _FiveFourThreeTwoOnePageState extends State<FiveFourThreeTwoOnePage> {
  int _currentStep = 0;

  static const List<_GroundingStep> _steps = [
    _GroundingStep(
      title: 'Kjenn kontakten med underlaget',
      text:
          'Legg merke til kontakten mellom føttene dine og underlaget. '
          'Kjenn vekten din. Kjenn at du blir støttet. '
          'Du trenger ikke endre noe. Bare legg merke til det.',
      icon: Icons.accessibility_new_outlined,
    ),
    _GroundingStep(
      title: 'Observer pusten',
      text:
          'Legg merke til pusten din i et par sykluser. '
          'Kjenn hvordan luften strømmer inn ... og ut. '
          'Du trenger ikke endre pusten. Bare observer den.',
      icon: Icons.air_outlined,
    ),
    _GroundingStep(
      title: '5 ting du kan se',
      text:
          'Se deg rundt. Finn fem ting du kan se. '
          'Det kan være store eller små ting, farger eller former. '
          'Benevn tingene du ser stille for deg selv; "Jeg ser..." ',
      icon: Icons.visibility_outlined,
    ),
    _GroundingStep(
      title: '4 ting du kan høre',
      text:
          'Lytt. Legg merke til fire ting du kan høre. '
          'Det kan være lyder i rommet, utenfor, eller helt svake '
          'lyder i bakgrunnen.',
      icon: Icons.hearing_outlined,
    ),
    _GroundingStep(
      title: '3 ting du kan føle',
      text:
          'Legg merke til tre ting du kan føle. '
          'Det kan være kontakten med klærne dine, temperaturen i luften, '
          'underlaget mot kroppen eller andre fysiske sanseinntrykk.',
      icon: Icons.touch_app_outlined,
    ),
    _GroundingStep(
      title: '2 ting du kan lukte',
      text:
          'Legg merke til to ting du kan lukte. '
          'Det kan være en tydelig lukt eller noe helt svakt i bakgrunnen. '
          'Hvis du ikke kjenner en spesifikk lukt, kan du bare legge merke '
          'til luften du puster inn.',
      icon: Icons.air_outlined,
    ),
    _GroundingStep(
      title: '1 ting du kan smake',
      text:
          'Legg merke til én ting du kan smake. '
          'Det kan være smaken i munnen akkurat nå, '
          'rester av mat eller drikke, eller bare en nøytral smak.',
      icon: Icons.restaurant_outlined,
    ),
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const _GroundingCompletePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('54321 Grounding')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colors.secondary),
              ),

              const SizedBox(height: 36),

              Text(
                '${_currentStep + 1} av ${_steps.length}',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                step.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.secondary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            step.icon,
                            size: 72,
                            color: colors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        step.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextStep,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                  ),
                  child: Text(
                    _currentStep == _steps.length - 1 ? 'Ferdig' : 'Neste',
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

class _GroundingStep {
  final String title;
  final String text;
  final IconData icon;

  const _GroundingStep({
    required this.title,
    required this.text,
    required this.icon,
  });
}

class _GroundingCompletePage extends StatelessWidget {
  const _GroundingCompletePage();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('54321 Grounding')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.secondary, width: 2),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: 76,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 36),

              Text(
                'Bra jobbet!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Du har nå fullført 54321 grounding.\n\n'
                'Ta et øyeblikk og legg merke til hvordan '
                'du føler deg akkurat nå.\n\n'
                'Du kan komme tilbake til denne øvelsen når som helst.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: colors.onSurface,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                  ),
                  child: const Text('Tilbake til øvelser'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Urge surfing
// ═══════════════════════════════════════════════════

class UrgeSurfingPage extends StatefulWidget {
  const UrgeSurfingPage({super.key});

  @override
  State<UrgeSurfingPage> createState() => _UrgeSurfingPageState();
}

class _UrgeSurfingPageState extends State<UrgeSurfingPage> {
  int _currentStep = 0;

  static const List<_UrgeSurfingStep> _steps = [
    _UrgeSurfingStep(
      title: 'Stopp opp',
      text:
          'Du trenger ikke gjøre noe akkurat nå. '
          'Legg merke til at suget er der.',
    ),
    _UrgeSurfingStep(
      title: 'Legg merke til pusten',
      text:
          'Ta noen rolige pust. Ikke prøv å få suget '
          'til å forsvinne. Bare legg merke til pusten.',
    ),
    _UrgeSurfingStep(
      title: 'Observer suget',
      text:
          'Legg merke til hvordan suget kjennes i kroppen. '
          'Hvor sitter det? Er det trykk, uro, varme eller spenning?',
    ),
    _UrgeSurfingStep(
      title: 'Se på suget som en bølge',
      text:
          'Et sug endrer seg over tid. Legg merke til '
          'hvordan følelsen beveger seg og forandrer seg '
          'uten at du trenger å handle på den.',
    ),
    _UrgeSurfingStep(
      title: 'La bølgen passere',
      text:
          'Fortsett å observere. Du trenger ikke bestemme '
          'deg for resten av dagen. Bare gi deg selv litt tid.',
    ),
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Urge surfing')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                borderRadius: BorderRadius.circular(10),
                minHeight: 8,
              ),
              const SizedBox(height: 36),
              Text(
                'Steg ${_currentStep + 1} av ${_steps.length}',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                step.text,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextStep,
                  child: Text(isLastStep ? 'Ferdig' : 'Neste'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrgeSurfingStep {
  final String title;
  final String text;

  const _UrgeSurfingStep({required this.title, required this.text});
}
