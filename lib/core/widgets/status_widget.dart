import 'package:flutter/material.dart';

import '../../core/utils/app_day.dart';
import '../../data/models/daily_checkin.dart';
import '../../data/models/user_goal.dart';
import '../../data/repositories/daily_checkin_repository.dart';
import '../../data/repositories/user_goal_repository.dart';

class StatusWidget extends StatefulWidget {
  const StatusWidget({super.key});

  @override
  State<StatusWidget> createState() => _StatusWidgetState();
}

class _StatusWidgetState extends State<StatusWidget>
    with WidgetsBindingObserver {
  static const int _statusLookbackMonths = 3;

  final UserGoalRepository _goalRepository = UserGoalRepository();
  final DailyCheckinRepository _checkinRepository = DailyCheckinRepository();

  UserGoal? _activeGoal;

  int _soberDays = 0;
  int _weeklyUnits = 0;
  int _daysOverDailyLimit = 0;
  int _alcoholFreeDays = 0;

  bool _isLoading = true;
  bool _expanded = false;

  DateTime? _lastLoadedAppDate;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _loadStatus(force: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatus(force: true);
    }
  }

  Future<void> refresh() async {
    await _loadStatus(force: true);
  }

  Future<void> _loadStatus({bool force = false}) async {
    final appDate = getAppDate(DateTime.now());

    if (!force &&
        _lastLoadedAppDate != null &&
        _sameDate(_lastLoadedAppDate!, appDate) &&
        !_isLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Hent alltid aktivt mål på nytt.
      final goal = await _goalRepository.getActive(userId: 'local-user');

      // Hent siste 7 dager for moderasjonsstatus.
      final recentCheckins = await _loadRecentCheckins(
        appDate: appDate,
        days: 7,
      );

      final weeklyUnits = recentCheckins.fold<int>(
        0,
        (sum, checkin) => sum + checkin.alcoholUnits,
      );

      final daysOverDailyLimit = _calculateDaysOverDailyLimit(
        recentCheckins,
        goal,
      );

      final alcoholFreeDays = recentCheckins
          .where((checkin) => checkin.alcoholUnits == 0)
          .length;

      // Ved avholdenhet søker vi separat bakover for å finne
      // sammenhengende streak.
      final soberDays = goal?.goalType == UserGoalType.abstinence
          ? await _calculateSoberDays(appDate)
          : 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _activeGoal = goal;
        _weeklyUnits = weeklyUnits;
        _daysOverDailyLimit = daysOverDailyLimit;
        _alcoholFreeDays = alcoholFreeDays;
        _soberDays = soberDays;
        _lastLoadedAppDate = appDate;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<DailyCheckin>> _loadRecentCheckins({
    required DateTime appDate,
    required int days,
  }) async {
    final checkins = <DailyCheckin>[];

    for (int i = 0; i < days; i++) {
      final date = appDate.subtract(Duration(days: i));

      final checkin = await _checkinRepository.getByDate(
        userId: 'local-user',
        appDate: date,
      );

      if (checkin != null) {
        checkins.add(checkin);
      }
    }

    return checkins;
  }

  Future<int> _calculateSoberDays(DateTime appDate) async {
    int count = 0;

    // Tre kalendermåneder bakover.
    final earliestDate = DateTime(
      appDate.year,
      appDate.month - _statusLookbackMonths,
      appDate.day,
    );

    // Dagens dag skal ikke bryte streaken dersom den ikke er registrert.
    // Hvis i dag er registrert, teller vi den på vanlig måte.
    DateTime startDate = appDate;

    final todayCheckin = await _checkinRepository.getByDate(
      userId: 'local-user',
      appDate: appDate,
    );

    if (todayCheckin == null) {
      startDate = appDate.subtract(const Duration(days: 1));
    }

    for (
      DateTime date = startDate;
      !date.isBefore(earliestDate);
      date = date.subtract(const Duration(days: 1))
    ) {
      final checkin = await _checkinRepository.getByDate(
        userId: 'local-user',
        appDate: date,
      );

      // Manglende registrering på en tidligere dag bryter streaken.
      if (checkin == null) {
        break;
      }

      // En dag med registrert alkohol bryter streaken.
      if (checkin.alcoholUnits != 0) {
        break;
      }

      // Registrert 0 enheter = alkoholfri dag.
      count++;
    }

    return count;
  }

  int _calculateDaysOverDailyLimit(
    List<DailyCheckin> checkins,
    UserGoal? goal,
  ) {
    if (goal?.goalType != UserGoalType.moderation || goal?.dailyLimit == null) {
      return 0;
    }

    return checkins
        .where((checkin) => checkin.alcoholUnits > goal!.dailyLimit!)
        .length;
  }

  String _goalTypeLabel(UserGoal goal) {
    switch (goal.goalType) {
      case UserGoalType.abstinence:
        return 'Avholdenhet';

      case UserGoalType.moderation:
        return 'Moderasjon';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading(context);
    }

    final goal = _activeGoal;

    if (goal == null) {
      return _buildNoGoalStatus(context);
    }

    return _buildCard(
      context,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Din status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                _goalTypeLabel(goal),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          switch (goal.goalType) {
            UserGoalType.abstinence => _buildAbstinenceStatus(context),
            UserGoalType.moderation => _buildModerationStatus(context),
          },
        ],
      ),
    );
  }

  Widget _buildAbstinenceStatus(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMetricIcon(context, Icons.local_fire_department_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alkoholfrie dager',
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Nåværende streak',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurface.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$_soberDays',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),

        if (_expanded) ...[
          const SizedBox(height: 22),
          _buildDivider(context),
          const SizedBox(height: 18),

          _buildDetailRow(context, 'Nåværende streak', '$_soberDays dager'),

          const SizedBox(height: 12),

          _buildDetailRow(
            context,
            'Registrerte alkoholfrie dager siste 7 dager',
            '$_alcoholFreeDays',
          ),
        ],

        const SizedBox(height: 20),
        _buildDetailsButton(context),
      ],
    );
  }

  Widget _buildModerationStatus(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final goal = _activeGoal!;

    final weeklyLimit = goal.weeklyLimit;

    String statusText;
    Color statusColor;

    if (weeklyLimit == null || weeklyLimit == 0) {
      statusText = 'Ukesmål ikke satt';
      statusColor = colors.onSurface.withValues(alpha: 0.55);
    } else {
      final percentage = _weeklyUnits / weeklyLimit;

      if (percentage > 1) {
        statusText = 'Utenfor';
        statusColor = const Color(0xFFC95C5C);
      } else if (percentage >= 0.8) {
        statusText = 'I nærheten';
        statusColor = const Color(0xFFC28A38);
      } else {
        statusText = 'Innenfor';
        statusColor = const Color(0xFF4D927B);
      }
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMetricIcon(context, Icons.local_bar_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Denne uken',
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'alkoholenheter',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurface.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              weeklyLimit == null
                  ? '$_weeklyUnits'
                  : '$_weeklyUnits / $weeklyLimit',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),

        if (_expanded) ...[
          const SizedBox(height: 22),
          _buildDivider(context),
          const SizedBox(height: 18),

          _buildDetailRow(
            context,
            'Alkoholenheter siste 7 dager',
            weeklyLimit == null
                ? '$_weeklyUnits'
                : '$_weeklyUnits / $weeklyLimit',
          ),

          const SizedBox(height: 12),

          _buildDetailRow(
            context,
            'Dager over dagsgrense',
            '$_daysOverDailyLimit',
          ),

          const SizedBox(height: 12),

          _buildDetailRow(context, 'Alkoholfrie dager', '$_alcoholFreeDays'),
        ],

        const SizedBox(height: 20),
        _buildDetailsButton(context),
      ],
    );
  }

  Widget _buildNoGoalStatus(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Din status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Du har ikke valgt et aktivt mål ennå.',
            style: TextStyle(
              fontSize: 15,
              color: colors.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return _buildCard(
      context,
      child: const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12383B)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF236A6D)
              : const Color(0xFFDCEEEF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.12 : 0.045,
            ),
            blurRadius: isDark ? 12 : 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMetricIcon(BuildContext context, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: colors.primary, size: 22),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _expanded ? 'Se mindre' : 'Se detaljer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: colors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _sameDate(DateTime a, DateTime b) {
    final dateA = _dateOnly(a);
    final dateB = _dateOnly(b);

    return dateA == dateB;
  }
}
