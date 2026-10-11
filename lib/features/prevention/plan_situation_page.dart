import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/plan.dart';
import '../../data/repositories/plan_repository.dart';
import 'situation.dart';
import '../../data/models/reminder.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../core/services/notification_service.dart';

class PlanSituationPage extends StatefulWidget {
  final String situationText;
  final SituationCategory category;
  final Plan? existingPlan;
  final DateTime? initialDate;

  const PlanSituationPage({
    super.key,
    required this.situationText,
    required this.category,
    this.existingPlan,
    this.initialDate,
  });

  bool get isEditing => existingPlan != null;

  @override
  State<PlanSituationPage> createState() => _PlanSituationPageState();
}

class _PlanSituationPageState extends State<PlanSituationPage> {
  final PlanRepository _planRepository = PlanRepository();
  final ReminderRepository _reminderRepository = ReminderRepository();

  late final TextEditingController _situationController;

  final TextEditingController _noteController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _repeat = 'Ingen';
  int? _repeatCount;
  DateTime? _repeatUntil;
  final List<Reminder> _reminders = [];

  bool get _isGreen => widget.category == SituationCategory.green;

  @override
  void initState() {
    super.initState();

    final plan = widget.existingPlan;

    _situationController = TextEditingController(
      text: plan?.situationText ?? widget.situationText,
    );

    if (plan == null) {
      _selectedDate = widget.initialDate;
    }

    if (plan != null) {
      _selectedDate = plan.plannedDate;

      if (plan.plannedTime != null) {
        final timeParts = plan.plannedTime!.split(':');

        if (timeParts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.tryParse(timeParts[0]) ?? 0,
            minute: int.tryParse(timeParts[1]) ?? 0,
          );
        }
      }

      _repeat = plan.repeat;
      _repeatCount = plan.repeatCount;
      _repeatUntil = plan.repeatUntil;
      _noteController.text = plan.note ?? '';
    }

    if (plan != null) {
      _loadReminders();
    }
  }

  Future<void> _loadReminders() async {
    final plan = widget.existingPlan;

    if (plan == null) {
      return;
    }

    final reminders = await _reminderRepository.getForPlan(plan.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _reminders
        ..clear()
        ..addAll(reminders);
    });
  }

  @override
  void dispose() {
    _situationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = time;
    });
  }

  Future<void> _save() async {
    final situationText = _situationController.text.trim();

    if (situationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isGreen
                ? 'Skriv inn aktiviteten før du lagrer.'
                : 'Skriv inn risikosituasjonen før du lagrer.',
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final existingPlan = widget.existingPlan;

    final plan = Plan(
      id: existingPlan?.id ?? const Uuid().v4(),
      userId: existingPlan?.userId ?? 'local-user',
      situationText: situationText,
      category: _isGreen ? 'green' : 'yellow',
      plannedDate: _selectedDate!,
      plannedTime: _selectedTime?.format(context),
      repeat: _repeat,
      repeatCount: _repeatCount,
      repeatUntil: _repeatUntil,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: existingPlan?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _planRepository.save(plan);

      final oldReminders = await _reminderRepository.getForPlan(plan.id);

      for (final reminder in oldReminders) {
        await NotificationService.instance.cancelReminder(reminder);
      }

      await _reminderRepository.deleteForPlan(plan.id);

      for (final reminder in _reminders) {
        final savedReminder = Reminder(
          id: reminder.id,
          planId: plan.id,
          type: reminder.type,
          offsetMinutes: reminder.offsetMinutes,
          scheduledAt: reminder.scheduledAt,
          message: reminder.message,
          createdAt: reminder.createdAt,
          updatedAt: now,
        );

        await _reminderRepository.save(savedReminder);

        await NotificationService.instance.scheduleReminder(
          plan: plan,
          reminder: savedReminder,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke lagre planen: $e'),
        ),
      );
    }
  }

  String _formatDate() {
    if (_selectedDate == null) {
      return 'Velg dato';
    }

    final date = _selectedDate!;

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatTime() {
    if (_selectedTime == null) {
      return 'Velg tidspunkt';
    }

    return _selectedTime!.format(context);
  }

  Future<void> _selectRepeatUntil() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _repeatUntil ?? _selectedDate ?? now,
      firstDate: _selectedDate ?? now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _repeatUntil = date;
    });
  }

  String _formatRepeatUntil() {
    if (_repeatUntil == null) {
      return 'Velg dato';
    }

    final date = _repeatUntil!;

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final title = _isGreen
        ? 'Planlegg forebyggende aktivitet'
        : 'Planlegg risikosituasjon';

    final description = _isGreen
        ? 'Planlegg en konkret aktivitet som '
        'støtter den ønskede endringen.'
        : 'Forbered deg på en konkret '
        'risikosituasjon du vet kommer.';

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: Text(
          widget.isEditing
              ? 'Rediger plan'
              : _isGreen
              ? 'Planlegg aktivitet'
              : 'Planlegg risikosituasjon',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Rediger plan' : title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                _isGreen
                    ? 'Hva ønsker du å gjøre?'
                    : 'Hvilken situasjon ønsker du å forberede deg på?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _situationController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isGreen
                      ? 'For eksempel: Gå på trening etter jobb'
                      : 'For eksempel: Fest hos venner på lørdag',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: 1.5,
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isGreen
                      ? colors.primaryContainer.withValues(alpha: 0.65)
                      : colors.tertiaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isGreen
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      color: _isGreen
                          ? colors.primary
                          : colors.tertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isGreen
                            ? 'Dette er en konkret planlagt aktivitet.'
                            : 'Dette er en konkret planlagt risikosituasjon.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildSelectionTile(
                icon: Icons.calendar_today_outlined,
                title: 'Dato',
                value: _formatDate(),
                onTap: _selectDate,
              ),

              const SizedBox(height: 12),

              _buildSelectionTile(
                icon: Icons.access_time_outlined,
                title: 'Tidspunkt',
                value: _formatTime(),
                onTap: _selectTime,
              ),

              const SizedBox(height: 12),

              _buildRepeatSelector(),

              const SizedBox(height: 24),

              _buildReminderSection(),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              Text(
                'Notat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _isGreen
                      ? 'Eventuelle detaljer om aktiviteten'
                      : 'Hvordan ønsker du å forberede deg?',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: 1.5,
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    widget.isEditing ? 'Lagre endringer' : 'Lagre plan',
                    style: const TextStyle(
                      fontSize: 16,
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

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = value != 'Velg dato' && value != 'Velg tidspunkt';

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: colors.primary,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
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

  Widget _buildRepeatSelector() {
    final colors = Theme.of(context).colorScheme;
    final hasRepeat = _repeat != 'Ingen';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.repeat,
                size: 34,
                color: colors.primary,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _repeat,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: colors.onSurfaceVariant,
                    ),
                    dropdownColor: colors.surface,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Ingen',
                        child: Text('Ingen'),
                      ),
                      DropdownMenuItem(
                        value: 'Daglig',
                        child: Text('Daglig'),
                      ),
                      DropdownMenuItem(
                        value: 'Ukentlig',
                        child: Text('Ukentlig'),
                      ),
                      DropdownMenuItem(
                        value: 'Månedlig',
                        child: Text('Månedlig'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _repeat = value;

                        if (value == 'Ingen') {
                          _repeatCount = null;
                          _repeatUntil = null;
                        }
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        if (hasRepeat) ...[
          const SizedBox(height: 16),

          Text(
            'Slutt på gjentakelse',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Antall ganger'),
                  value: 'count',
                  groupValue: _repeatCount != null
                      ? 'count'
                      : _repeatUntil != null
                      ? 'date'
                      : null,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _repeatUntil = null;
                      _repeatCount ??= 1;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Til dato'),
                  value: 'date',
                  groupValue: _repeatUntil != null
                      ? 'date'
                      : _repeatCount != null
                      ? 'count'
                      : null,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _repeatCount = null;
                      _repeatUntil ??= _selectedDate;
                    });
                  },
                ),
              ),
            ],
          ),

          if (_repeatCount != null) ...[
            const SizedBox(height: 8),

            Text(
              'Antall forekomster',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border.all(
                  color: colors.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _repeatCount! > 1
                        ? () {
                      setState(() {
                        _repeatCount = _repeatCount! - 1;
                      });
                    }
                        : null,
                    icon: const Icon(Icons.remove),
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        '$_repeatCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: _repeatCount! < 99
                        ? () {
                      setState(() {
                        _repeatCount = _repeatCount! + 1;
                      });
                    }
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],

          if (_repeatUntil != null) ...[
            const SizedBox(height: 8),

            _buildSelectionTile(
              icon: Icons.event_outlined,
              title: 'Gjenta til',
              value: _formatRepeatUntil(),
              onTap: _selectRepeatUntil,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildReminderSection() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Påminnelser',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Få en påminnelse før planlagte situasjoner og aktiviteter.',
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 12),

        ..._reminders.map((reminder) => _buildReminderTile(reminder)),

        if (_reminders.length < 3)
          OutlinedButton.icon(
            onPressed: _showAddReminderDialog,
            icon: const Icon(Icons.add),
            label: const Text('Legg til påminnelse'),
          ),
      ],
    );
  }

  Widget _buildReminderTile(Reminder reminder) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: colors.primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reminderLabel(reminder),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),

                if (reminder.message != null &&
                    reminder.message!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    reminder.message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _reminders.removeWhere(
                      (item) => item.id == reminder.id,
                );
              });
            },
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  String _reminderLabel(Reminder reminder) {
    if (reminder.type == 'custom') {
      if (reminder.scheduledAt == null) {
        return 'Selvvalgt';
      }

      final date = reminder.scheduledAt!;

      final dateText =
          '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';

      final timeText =
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';

      return '$dateText kl. $timeText';
    }

    switch (reminder.offsetMinutes) {
      case 120:
        return '2 timer før';
      case 1440:
        return '1 dag før';
      case 2880:
        return '2 dager før';
      case 10080:
        return '1 uke før';
      default:
        return 'Påminnelse';
    }
  }

  Future<void> _showAddReminderDialog() async {
    String? selectedValue;
    DateTime? selectedDateTime;
    final messageController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colors = Theme.of(context).colorScheme;

            return AlertDialog(
              title: const Text('Legg til påminnelse'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('2 timer før'),
                    value: '120',
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedValue = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('1 dag før'),
                    value: '1440',
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedValue = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('2 dager før'),
                    value: '2880',
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedValue = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('1 uke før'),
                    value: '10080',
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedValue = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Selvvalgt'),
                    value: 'custom',
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedValue = value;
                      });
                    },
                  ),

                  if (selectedValue == 'custom')
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.event_outlined,
                        color: colors.primary,
                      ),
                      title: Text(
                        selectedDateTime == null
                            ? 'Velg dato og tidspunkt'
                            : _formatReminderDateTime(selectedDateTime!),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime ??
                              _selectedDate ??
                              DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(
                            DateTime.now().year + 5,
                          ),
                        );

                        if (date == null) {
                          return;
                        }

                        if (!dialogContext.mounted) {
                          return;
                        }

                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedDateTime != null
                              ? TimeOfDay(
                            hour: selectedDateTime!.hour,
                            minute: selectedDateTime!.minute,
                          )
                              : const TimeOfDay(
                            hour: 8,
                            minute: 0,
                          ),
                          initialEntryMode: TimePickerEntryMode.input,
                        );

                        if (time == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                    ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: messageController,
                    maxLength: 120,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Melding (valgfritt)',
                      hintText: 'Kort tekst til påminnelsen',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Avbryt'),
                ),
                FilledButton(
                  onPressed: selectedValue == null ||
                      (selectedValue == 'custom' &&
                          selectedDateTime == null)
                      ? null
                      : () {
                    Navigator.of(dialogContext).pop(selectedValue);
                  },
                  child: const Text('Legg til'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      messageController.dispose();
      return;
    }

    final now = DateTime.now();

    final reminder = Reminder(
      id: const Uuid().v4(),
      planId: widget.existingPlan?.id ?? '',
      type: result == 'custom' ? 'custom' : 'relative',
      offsetMinutes: result == 'custom' ? null : int.parse(result),
      scheduledAt: result == 'custom' ? selectedDateTime : null,
      message: messageController.text.trim().isEmpty
          ? null
          : messageController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    messageController.dispose();

    setState(() {
      _reminders.add(reminder);
    });
  }

  String _formatReminderDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}