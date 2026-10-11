import 'package:flutter/material.dart';

import 'package:my_recovery_manager/data/models/daily_checkin.dart';
import 'package:my_recovery_manager/data/repositories/daily_checkin_repository.dart';

import '../../../core/utils/app_day.dart';

class JournalCheckinPage extends StatefulWidget {
  const JournalCheckinPage({super.key});

  @override
  State<JournalCheckinPage> createState() => _JournalCheckinPageState();
}

class _JournalCheckinPageState extends State<JournalCheckinPage> {
  final TextEditingController _journalController =
  TextEditingController();

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

    if (checkin != null && checkin.journalText != null) {
      _journalController.text = checkin.journalText!;
    }
  }

  Future<void> _saveJournal() async {
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
      mood: existingCheckin?.mood,
      craving: existingCheckin?.craving,
      alcoholUnits: existingCheckin?.alcoholUnits ?? 0,
      journalText: _journalController.text,
    );

    await repository.upsert(checkin);

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dagbok'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dagbok',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Skriv gjerne noen ord om dagen din.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: TextField(
                  controller: _journalController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Hvordan har dagen vært?',
                    hintStyle: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.45),
                    ),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colors.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colors.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    color: colors.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveJournal,
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