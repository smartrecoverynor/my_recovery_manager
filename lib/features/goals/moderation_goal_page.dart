import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/onboarding_service.dart';
import '../../core/widgets/assessment_header.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/user_goal.dart';
import '../../data/repositories/user_goal_repository.dart';
import 'widgets/goal_counter.dart';

class ModerationGoalPage extends StatefulWidget {
  const ModerationGoalPage({super.key});

  @override
  State<ModerationGoalPage> createState() => _ModerationGoalPageState();
}

class _ModerationGoalPageState extends State<ModerationGoalPage> {
  int weeklyLimit = 10;
  int dailyLimit = 2;
  int alcoholFreeDays = 4;

  bool _isLoading = true;
  bool _isSaving = false;

  final UserGoalRepository _repository = UserGoalRepository();

  @override
  void initState() {
    super.initState();
    _loadCurrentGoal();
  }

  Future<void> _loadCurrentGoal() async {
    try {
      final goal = await _repository.getActive(userId: 'local-user');

      if (!mounted) {
        return;
      }

      if (goal != null && goal.goalType == UserGoalType.moderation) {
        setState(() {
          weeklyLimit = goal.weeklyLimit ?? 10;
          dailyLimit = goal.dailyLimit ?? 2;
          alcoholFreeDays = goal.alcoholFreeDays ?? 4;
          _isLoading = false;
        });

        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke laste målet: $e')));
    }
  }

  Future<void> _saveGoal() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final appDate = DateTime(now.year, now.month, now.day);

    final goal = UserGoal.create(
      id: now.microsecondsSinceEpoch.toString(),
      userId: 'local-user',
      goalType: UserGoalType.moderation,
      weeklyLimit: weeklyLimit,
      dailyLimit: dailyLimit,
      alcoholFreeDays: alcoholFreeDays,
      validFrom: appDate,
    );

    try {
      await _repository.setActiveGoal(goal);
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mål')),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AssessmentHeader(
                      step: 'Steg 5 av 5',
                      title: 'Definer moderasjonsmål',
                      description:
                          'Du har valgt å jobbe mot kontrollert alkoholbruk.\n\n'
                          'For å kunne følge utviklingen din trenger vi å vite '
                          'hvordan du ønsker at moderasjon skal se ut.',
                    ),
                    const SizedBox(height: 24),
                    GoalCounter(
                      title: 'Maks alkoholenheter per uke',
                      value: weeklyLimit,
                      onIncrement: () {
                        if (weeklyLimit < 30) {
                          setState(() {
                            weeklyLimit++;
                          });
                        }
                      },
                      onDecrement: () {
                        if (weeklyLimit > 0) {
                          setState(() {
                            weeklyLimit--;
                          });
                        }
                      },
                    ),
                    GoalCounter(
                      title: 'Maks alkoholenheter per dag',
                      value: dailyLimit,
                      onIncrement: () {
                        if (dailyLimit < 10) {
                          setState(() {
                            dailyLimit++;
                          });
                        }
                      },
                      onDecrement: () {
                        if (dailyLimit > 0) {
                          setState(() {
                            dailyLimit--;
                          });
                        }
                      },
                    ),
                    GoalCounter(
                      title: 'Alkoholfrie dager per uke',
                      value: alcoholFreeDays,
                      onIncrement: () {
                        if (alcoholFreeDays < 7) {
                          setState(() {
                            alcoholFreeDays++;
                          });
                        }
                      },
                      onDecrement: () {
                        if (alcoholFreeDays > 0) {
                          setState(() {
                            alcoholFreeDays--;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Start',
                      onPressed: _isSaving ? null : _saveGoal,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
