import 'package:flutter/material.dart';

import '../../core/utils/app_day.dart';
import '../../data/models/daily_checkin.dart';
import '../../data/models/plan.dart';
import '../../data/repositories/daily_checkin_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/utils/plan_occurrence_helper.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final DailyCheckinRepository _checkinRepository =
  DailyCheckinRepository();

  final PlanRepository _planRepository = PlanRepository();

  late DateTime _today;
  late DateTime _selectedDate;
  late DateTime _minimumDate;

  DailyCheckin? _checkin;
  List<Plan> _plans = [];

  int _historicalAlcoholUnits = 0;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditingHistoricalAlcohol = false;

  bool get _isToday => _selectedDate == _today;

  @override
  void initState() {
    super.initState();

    _today = getAppDate(DateTime.now());

    // Etterregistrering kan gjøres tre måneder tilbake.
    _minimumDate = DateTime(_today.year, _today.month - 3, _today.day);

    _selectedDate = _today;

    _loadSelectedDate();
  }

  Future<void> _loadSelectedDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final checkin = await _checkinRepository.getByDate(
        userId: 'local-user',
        appDate: _selectedDate,
      );

      List<Plan> plans = [];

      if (_isToday) {
        final allPlans = await _planRepository.getAll(
          userId: 'local-user',
        );

        final todayPlans = <Plan>[];

        for (final plan in allPlans) {
          final occurrences = PlanOccurrenceHelper.getOccurrences(plan);

          for (final occurrence in occurrences) {
            if (occurrence.year == _today.year &&
                occurrence.month == _today.month &&
                occurrence.day == _today.day) {
              todayPlans.add(_planForOccurrence(plan, occurrence));
            }
          }
        }

        todayPlans.sort((a, b) {
          if (a.plannedTime == null && b.plannedTime == null) {
            return 0;
          }

          if (a.plannedTime == null) {
            return 1;
          }

          if (b.plannedTime == null) {
            return -1;
          }

          return a.plannedTime!.compareTo(b.plannedTime!);
        });

        plans = todayPlans;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _checkin = checkin;
        _plans = plans;
        _historicalAlcoholUnits = checkin?.alcoholUnits ?? 0;
        _isEditingHistoricalAlcohol = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke hente informasjonen: $e'),
        ),
      );
    }
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

  Future<void> _goToPreviousDay() async {
    if (_selectedDate == _minimumDate) {
      return;
    }

    final previousDate =
    _selectedDate.subtract(const Duration(days: 1));

    setState(() {
      _selectedDate = previousDate;
      _isEditingHistoricalAlcohol = false;
    });

    await _loadSelectedDate();
  }

  Future<void> _goToNextDay() async {
    if (_selectedDate == _today) {
      return;
    }

    final nextDate = _selectedDate.add(const Duration(days: 1));

    setState(() {
      _selectedDate = nextDate;
      _isEditingHistoricalAlcohol = false;
    });

    await _loadSelectedDate();
  }

  Future<void> _saveHistoricalAlcohol() async {
    if (_isToday || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existingCheckin = await _checkinRepository.getByDate(
        userId: 'local-user',
        appDate: _selectedDate,
      );

      final now = DateTime.now();

      final checkin = DailyCheckin(
        id: existingCheckin?.id ??
            now.microsecondsSinceEpoch.toString(),
        userId: 'local-user',
        appDate: _selectedDate,
        mood: existingCheckin?.mood,
        craving: existingCheckin?.craving,
        alcoholUnits: _historicalAlcoholUnits,
        journalText: existingCheckin?.journalText,
        createdAt: existingCheckin?.createdAt ?? now,
        updatedAt: now,
      );

      await _checkinRepository.upsert(checkin);

      if (!mounted) {
        return;
      }

      setState(() {
        _checkin = checkin;
        _historicalAlcoholUnits = checkin.alcoholUnits;
        _isEditingHistoricalAlcohol = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alkoholenheter er lagret.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke lagre registreringen: $e'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'januar',
      'februar',
      'mars',
      'april',
      'mai',
      'juni',
      'juli',
      'august',
      'september',
      'oktober',
      'november',
      'desember',
    ];

    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }

  String _buildMoodText() {
    final mood = _checkin?.mood;

    if (mood == null) {
      return 'Ikke registrert';
    }

    switch (mood) {
      case 1:
        return 'Veldig dårlig';
      case 2:
        return 'Dårlig';
      case 3:
        return 'Nøytral';
      case 4:
        return 'Bra';
      case 5:
        return 'Veldig bra';
      default:
        return 'Ikke registrert';
    }
  }

  String _buildCravingText() {
    final craving = _checkin?.craving;

    if (craving == null) {
      return 'Ikke registrert';
    }

    if (craving == 1) {
      return '1 – Ingen';
    }

    if (craving == 5) {
      return '5 – Moderat';
    }

    if (craving == 10) {
      return '10 – Ekstrem';
    }

    if (craving < 5) {
      return '$craving – Lav';
    }

    return '$craving – Høy';
  }

  void _changeHistoricalUnits(int change) {
    if (_isToday) {
      return;
    }

    setState(() {
      _historicalAlcoholUnits = (_historicalAlcoholUnits + change).clamp(
        0,
        999,
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('I dag'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadSelectedDate,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildDateNavigation(),

            const SizedBox(height: 28),

            if (_isToday)
              _buildTodayContent()
            else
              _buildHistoricalContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigation() {
    final colors = Theme.of(context).colorScheme;

    final canGoPrevious = _selectedDate.isAfter(_minimumDate);
    final canGoNext = _selectedDate.isBefore(_today);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: canGoPrevious ? _goToPreviousDay : null,
            icon: const Icon(
              Icons.chevron_left,
              size: 32,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _isToday ? 'I dag' : 'Historisk registrering',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(_selectedDate),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canGoNext ? _goToNextDay : null,
            icon: const Icon(
              Icons.chevron_right,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayContent() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_plans.isNotEmpty) ...[
          Text(
            'Planlagt i dag',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dine planlagte situasjoner og aktiviteter for i dag.',
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ..._plans.map(_buildPlanCard),
          const SizedBox(height: 28),
          Divider(
            color: colors.outlineVariant,
          ),
          const SizedBox(height: 28),
        ],
        Text(
          'Dagens registreringer',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        _buildItem(
          title: 'Alkohol',
          value: _checkin == null
              ? 'Ikke registrert'
              : '${_checkin!.alcoholUnits} enheter',
        ),
        _buildItem(
          title: 'Humør',
          value: _buildMoodText(),
        ),
        _buildItem(
          title: 'Craving',
          value: _buildCravingText(),
        ),
        _buildItem(
          title: 'Dagbok',
          value: _checkin?.journalText?.isNotEmpty == true
              ? 'Registrert'
              : 'Ikke registrert',
        ),
        const SizedBox(height: 8),
        Text(
          'Dagens registreringer gjøres via dagens check-in.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (_plans.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Ingen planer for i dag.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoricalContent() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registreringer',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        _buildHistoricalAlcoholItem(),
        _buildItem(
          title: 'Humør',
          value: _buildMoodText(),
        ),
        _buildItem(
          title: 'Craving',
          value: _buildCravingText(),
        ),
        _buildItem(
          title: 'Dagbok',
          value: _checkin?.journalText?.isNotEmpty == true
              ? 'Registrert'
              : 'Ikke registrert',
        ),
      ],
    );
  }

  Widget _buildHistoricalAlcoholItem() {
    final colors = Theme.of(context).colorScheme;
    final isRegistered = _checkin != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alkohol',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (!_isEditingHistoricalAlcohol)
                  IconButton(
                    tooltip: isRegistered
                        ? 'Rediger alkohol'
                        : 'Registrer alkohol',
                    onPressed: () {
                      setState(() {
                        _historicalAlcoholUnits =
                            _checkin?.alcoholUnits ?? 0;
                        _isEditingHistoricalAlcohol = true;
                      });
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 21,
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Ferdig',
                    onPressed: _saveHistoricalAlcohol,
                    icon: const Icon(
                      Icons.check,
                      size: 22,
                    ),
                  ),
              ],
            ),
            if (!_isEditingHistoricalAlcohol) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isRegistered
                      ? '${_checkin!.alcoholUnits} enheter'
                      : 'Ikke registrert',
                  style: TextStyle(
                    fontSize: 16,
                    color: isRegistered
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitButton(
                    icon: Icons.remove,
                    onPressed: _historicalAlcoholUnits > 0
                        ? () => _changeHistoricalUnits(-1)
                        : null,
                  ),
                  const SizedBox(width: 28),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '$_historicalAlcoholUnits',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  _buildUnitButton(
                    icon: Icons.add,
                    onPressed: () => _changeHistoricalUnits(1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'alkoholenheter',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                  _isSaving ? null : _saveHistoricalAlcohol,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Lagre',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 28,
      padding: const EdgeInsets.all(14),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    final colors = Theme.of(context).colorScheme;
    final isGreen = plan.category == 'green';

    final color = isGreen ? colors.primary : colors.tertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPlanDetails(plan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isGreen
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.situationText,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 17,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        if (plan.plannedTime != null)
                          Text(
                            plan.plannedTime!,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        if (plan.repeat != 'Ingen') ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.repeat,
                            size: 17,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            plan.repeat,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanDetails(Plan plan) {
    final colors = Theme.of(context).colorScheme;
    final isGreen = plan.category == 'green';

    final color = isGreen ? colors.primary : colors.tertiary;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24,
            ),
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
                      color: color,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isGreen
                          ? 'Forebyggende aktivitet'
                          : 'Risikosituasjon',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
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
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    if (plan.plannedTime != null)
                      Text(
                        plan.plannedTime!,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.onSurface,
                        ),
                      ),
                  ],
                ),
                if (plan.repeat != 'Ingen') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: colors.onSurfaceVariant,
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
                  const SizedBox(height: 18),
                  Text(
                    'Notat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.note!,
                    style: TextStyle(
                      height: 1.4,
                      color: colors.onSurfaceVariant,
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

  Widget _buildItem({
    required String title,
    required String value,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}