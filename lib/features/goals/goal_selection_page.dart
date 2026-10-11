import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/onboarding_service.dart';
import '../../core/utils/app_day.dart';
import '../../data/models/user_goal.dart';
import '../../data/repositories/user_goal_repository.dart';

enum GoalType { abstinence, moderation, decideLater }

class GoalSelectionPage extends StatefulWidget {
  final bool assessmentCompleted;

  const GoalSelectionPage({super.key, required this.assessmentCompleted});

  @override
  State<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage> {
  final UserGoalRepository _goalRepository = UserGoalRepository();
  final Uuid _uuid = const Uuid();

  GoalType? _selectedGoal;
  bool _isSaving = false;

  Future<void> _continue() async {
    final selectedGoal = _selectedGoal;

    if (selectedGoal == null || _isSaving) {
      return;
    }

    switch (selectedGoal) {
      case GoalType.abstinence:
        final confirmed = await _confirmAbstinenceSafety();

        if (!confirmed || !mounted) {
          return;
        }

        await _saveAbstinenceGoal();

      case GoalType.moderation:
        if (!mounted) {
          return;
        }

        context.go('/moderation-goal');

      case GoalType.decideLater:
        await _decideLater();
    }
  }

  Future<bool> _confirmAbstinenceSafety() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Viktig informasjon om alkoholstopp'),
          content: const SingleChildScrollView(
            child: Text(
              'Hvis du drikker mye eller ofte, kan kroppen ha utviklet '
              'fysisk avhengighet. Å slutte brått kan da føre til '
              'alvorlige abstinenssymptomer.\n\n'
              'Hvis du opplever skjelvinger, svetting, uro, kvalme eller '
              'andre abstinenssymptomer når du reduserer alkoholinntaket, '
              'bør du kontakte helsepersonell før du slutter brått. '
              'Ved alvorlige symptomer, som kramper eller forvirring, '
              'må du søke akutt medisinsk hjelp.\n\n'
              'Du bestemmer selv målet ditt, men det er viktig at '
              'avslutningen skjer på en trygg måte.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Tilbake'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Jeg forstår, fortsett'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _saveAbstinenceGoal() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final appDate = getAppDate(DateTime.now());
      final now = DateTime.now();

      final goal = UserGoal(
        id: _uuid.v4(),
        userId: 'local-user',
        goalType: UserGoalType.abstinence,
        weeklyLimit: null,
        dailyLimit: null,
        alcoholFreeDays: null,
        validFrom: appDate,
        validTo: null,
        createdAt: now,
        updatedAt: now,
      );

      await _goalRepository.setActiveGoal(goal);
      await OnboardingService.markCompleted();

      if (!mounted) {
        return;
      }

      context.go('/dashboard');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke lagre målet: $e')));
    }
  }

  Future<void> _decideLater() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _goalRepository.clearActiveGoal(userId: 'local-user');
      await OnboardingService.markCompleted();

      if (!mounted) {
        return;
      }

      context.go('/dashboard');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke oppdatere målinnstillingen: $e')),
      );
    }
  }

  Widget _goalCard({
    required GoalType goalType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedGoal == goalType;
    final primaryColor = colors.primary;

    return GestureDetector(
      onTap: _isSaving
          ? null
          : () {
              setState(() {
                _selectedGoal = goalType;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.10)
              : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : colors.outline.withValues(alpha: 0.7),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected
                  ? primaryColor
                  : colors.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colors.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? primaryColor
                  : colors.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Velg mål')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hva ønsker du å oppnå?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Du kan endre målet ditt senere.',
                style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              _goalCard(
                goalType: GoalType.abstinence,
                title: 'Avholdenhet',
                description: 'Jeg ønsker å slutte helt å drikke alkohol.',
                icon: Icons.block_outlined,
              ),
              const SizedBox(height: 14),
              _goalCard(
                goalType: GoalType.moderation,
                title: 'Moderasjon',
                description:
                    'Jeg ønsker å redusere alkoholinntaket og sette egne grenser.',
                icon: Icons.tune_outlined,
              ),
              const SizedBox(height: 14),
              _goalCard(
                goalType: GoalType.decideLater,
                title: 'Bestem senere',
                description:
                    'Jeg vil utforske appen først og bestemme mål senere.',
                icon: Icons.schedule_outlined,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedGoal == null || _isSaving
                      ? null
                      : _continue,
                  child: _isSaving
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? colors.onPrimary : Colors.white,
                          ),
                        )
                      : const Text('Fortsett'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
