import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/plan.dart';
import '../../data/repositories/plan_repository.dart';
import '../prevention/plan_situation_page.dart';
import '../prevention/situation.dart';
import '../../data/utils/plan_occurrence_helper.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final PlanRepository _planRepository = PlanRepository();

  List<Plan> _plans = [];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _planRepository.getAll(userId: 'local-user');

      if (!mounted) {
        return;
      }

      setState(() {
        _plans = plans;
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
      ).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke hente planene: $e'),
        ),
      );
    }
  }

  List<Plan> _plansForDay(DateTime day) {
    final result = <Plan>[];

    for (final plan in _plans) {
      final occurrences = PlanOccurrenceHelper.getOccurrences(plan);

      for (final occurrence in occurrences) {
        if (isSameDay(occurrence, day)) {
          result.add(_planForOccurrence(plan, occurrence));
        }
      }
    }

    return result;
  }

  Plan _planForOccurrence(Plan plan, DateTime date) {
    return Plan(
      id: plan.id,
      userId: plan.userId,
      situationText: plan.situationText,
      category: plan.category,
      plannedDate: date,
      plannedTime: plan.plannedTime,
      repeat: plan.repeat,
      repeatCount: plan.repeatCount,
      repeatUntil: plan.repeatUntil,
      note: plan.note,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    );
  }

  Future<void> _createNewPlan() async {
    final category = await showModalBottomSheet<SituationCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hva ønsker du å planlegge?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade700,
                    ),
                    title: const Text(
                      'Risikosituasjon',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'En konkret situasjon du ønsker å forberede deg på.',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.of(context).pop(
                        SituationCategory.yellow,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    title: const Text(
                      'Forebyggende aktivitet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'En konkret aktivitet som støtter den ønskede endringen.',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.of(context).pop(
                        SituationCategory.green,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (category == null || !mounted) {
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PlanSituationPage(
          situationText: '',
          category: category,
          initialDate: _selectedDay,
        ),
      ),
    );

    if (saved == true) {
      await _loadPlans();
    }
  }

  void _showPlan(Plan plan) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final isGreen = plan.category == 'green';
        final colors = Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isGreen
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      color: isGreen
                          ? Colors.green
                          : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isGreen
                            ? 'Forebyggende aktivitet'
                            : 'Risikosituasjon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isGreen
                              ? Colors.green
                              : Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  plan.situationText,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                if (plan.plannedTime != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 20,
                        color: colors.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        plan.plannedTime!,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
                if (plan.repeat != 'Ingen') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 20,
                        color: colors.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        plan.repeat,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
                if (plan.note != null && plan.note!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    plan.note!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: colors.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlans = _plansForDay(_selectedDay);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          TableCalendar<Plan>(
            locale: 'nb_NO',
            firstDay: DateTime(
              DateTime.now().year - 1,
            ),
            lastDay: DateTime(
              DateTime.now().year + 5,
            ),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Måned',
            },
            eventLoader: _plansForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              markersMaxCount: 3,
            ),
            calendarBuilders: CalendarBuilders<Plan>(
              markerBuilder: (context, day, plans) {
                if (plans.isEmpty) {
                  return null;
                }

                final hasRisk = plans.any(
                      (plan) => plan.category == 'yellow',
                );

                final hasPrevention = plans.any(
                      (plan) => plan.category == 'green',
                );

                Color markerColor;

                if (hasRisk && hasPrevention) {
                  markerColor = colors.onSurface;
                } else if (hasRisk) {
                  markerColor = Colors.amber.shade700;
                } else {
                  markerColor = Colors.green;
                }

                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: markerColor,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedPlans.isEmpty
                ? _buildEmptyDay()
                : ListView(
              padding: const EdgeInsets.all(16),
              children: selectedPlans
                  .map(_buildPlanTile)
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPlan,
        icon: const Icon(Icons.add),
        label: const Text('Ny plan'),
      ),
    );
  }

  Widget _buildEmptyDay() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: colors.onSurface.withValues(
                alpha: 0.35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ingen planer denne dagen.',
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTile(Plan plan) {
    final isGreen = plan.category == 'green';
    final color = isGreen
        ? Colors.green
        : Colors.amber.shade700;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _showPlan(plan),
        leading: Icon(
          isGreen
              ? Icons.check_circle_outline
              : Icons.warning_amber_rounded,
          color: color,
        ),
        title: Text(
          plan.situationText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        subtitle: plan.plannedTime != null
            ? Text(
          plan.plannedTime!,
          style: TextStyle(
            color: colors.onSurface.withValues(
              alpha: 0.65,
            ),
          ),
        )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: colors.onSurface.withValues(
            alpha: 0.55,
          ),
        ),
      ),
    );
  }
}