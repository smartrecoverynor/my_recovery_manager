import 'package:flutter/material.dart';

import '../../data/models/plan.dart';
import '../../data/repositories/plan_repository.dart';
import 'plan_situation_page.dart';
import 'situation.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final PlanRepository _planRepository = PlanRepository();

  List<Plan> _plans = [];
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

  Future<void> _editPlan(Plan plan) async {
    final category = plan.category == 'green'
        ? SituationCategory.green
        : SituationCategory.yellow;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanSituationPage(
          situationText: plan.situationText,
          category: category,
          existingPlan: plan,
        ),
      ),
    );

    _loadPlans();
  }

  Future<void> _deletePlan(Plan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Slett plan?'),
          content: Text('Vil du slette «${plan.situationText}»?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
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

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _planRepository.delete(plan.id);
      await _loadPlans();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke slette planen: $e'),
        ),
      );
    }
  }

  Future<void> _createNewPlan() async {
    final selectedCategory = await showModalBottomSheet<SituationCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hva ønsker du å planlegge?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  color: colors.surfaceContainerLow,
                  elevation: 0,
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: colors.tertiary,
                    ),
                    title: const Text(
                      'Risikosituasjon',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'En konkret situasjon du ønsker å forberede deg på.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop(SituationCategory.yellow);
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  color: colors.surfaceContainerLow,
                  elevation: 0,
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle_outline,
                      color: colors.primary,
                    ),
                    title: const Text(
                      'Forebyggende aktivitet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'En konkret aktivitet som støtter den ønskede endringen.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop(SituationCategory.green);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCategory == null || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanSituationPage(
          situationText: '',
          category: selectedCategory,
        ),
      ),
    );

    _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final activePlans = _plans.where((plan) {
      if (plan.plannedTime == null) {
        return !plan.plannedDate.isBefore(
          DateTime(now.year, now.month, now.day),
        );
      }

      final parts = plan.plannedTime!.split(':');

      if (parts.length != 2) {
        return !plan.plannedDate.isBefore(
          DateTime(now.year, now.month, now.day),
        );
      }

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) {
        return !plan.plannedDate.isBefore(
          DateTime(now.year, now.month, now.day),
        );
      }

      final plannedDateTime = DateTime(
        plan.plannedDate.year,
        plan.plannedDate.month,
        plan.plannedDate.day,
        hour,
        minute,
      );

      return !plannedDateTime.isBefore(now);
    }).toList();

    final riskPlans = activePlans
        .where((plan) => plan.category == 'yellow')
        .toList();

    final preventionPlans = activePlans
        .where((plan) => plan.category == 'green')
        .toList();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: const Text('Planlegging'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: colors.primary,
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadPlans,
            child: ListView(
              children: [
                Text(
                  'Planlegg situasjoner og aktiviteter',
                  style:
                  Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Forbered deg på situasjoner som kan bli '
                      'utfordrende, og planlegg aktiviteter som '
                      'støtter den ønskede endringen.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _createNewPlan,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Ny plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                _buildPlanSection(
                  title: 'Planlagte risikosituasjoner',
                  icon: Icons.warning_amber_rounded,
                  color: colors.tertiary,
                  plans: riskPlans,
                  emptyText: 'Ingen planlagte risikosituasjoner ennå.',
                ),

                const SizedBox(height: 28),

                _buildPlanSection(
                  title: 'Planlagte forebyggende aktiviteter',
                  icon: Icons.check_circle_outline,
                  color: colors.primary,
                  plans: preventionPlans,
                  emptyText: 'Ingen planlagte aktiviteter ennå.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Plan> plans,
    required String emptyText,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (plans.isEmpty)
          Text(
            emptyText,
            style: TextStyle(
              color: colors.onSurfaceVariant,
            ),
          )
        else
          ...plans.map(
                (plan) => _PlanCard(
              plan: plan,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatefulWidget {
  final Plan plan;
  final Color color;

  const _PlanCard({
    required this.plan,
    required this.color,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final plan = widget.plan;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _toggleExpanded,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        plan.situationText,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Icon(
                      plan.category == 'green'
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      color: widget.color,
                    ),

                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        final pageState = context
                            .findAncestorStateOfType<_PlanPageState>();

                        if (pageState == null) {
                          return;
                        }

                        if (value == 'edit') {
                          pageState._editPlan(plan);
                        } else if (value == 'delete') {
                          pageState._deletePlan(plan);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Rediger'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              const Text('Slett'),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      _formatDate(plan.plannedDate),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Icon(
                      Icons.access_time_outlined,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),

                    const SizedBox(width: 8),

                    if (plan.plannedTime != null)
                      Text(
                        plan.plannedTime!,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                    const Spacer(),

                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                if (plan.repeat != 'Ingen') ...[
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        plan.repeat,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],

                if (_expanded &&
                    plan.note != null &&
                    plan.note!.isNotEmpty) ...[
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colors.outlineVariant,
                        ),
                      ),
                    ),
                    child: Text(
                      plan.note!,
                      style: TextStyle(
                        height: 1.4,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}