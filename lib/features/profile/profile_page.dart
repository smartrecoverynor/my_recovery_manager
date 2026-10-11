import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/backup_service.dart';
import '../../data/models/user_goal.dart';
import '../../data/repositories/user_goal_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserGoalRepository _goalRepository = UserGoalRepository();

  UserGoal? _activeGoal;
  bool _isLoading = true;
  bool _isBackupBusy = false;

  @override
  void initState() {
    super.initState();
    _loadActiveGoal();
  }

  Future<void> _loadActiveGoal() async {
    try {
      final goal = await _goalRepository.getActive(userId: 'local-user');

      if (!mounted) {
        return;
      }

      setState(() {
        _activeGoal = goal;
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

  String _goalDescription() {
    final goal = _activeGoal;

    if (goal == null) {
      return 'Du har ikke valgt et aktivt mål.';
    }

    switch (goal.goalType) {
      case UserGoalType.abstinence:
        return 'Målet ditt er å slutte helt å drikke alkohol.';

      case UserGoalType.moderation:
        final daily = goal.dailyLimit;
        final weekly = goal.weeklyLimit;
        final alcoholFreeDays = goal.alcoholFreeDays;

        final details = <String>[];

        if (daily != null) {
          details.add('$daily enheter per dag');
        }

        if (weekly != null) {
          details.add('$weekly enheter per uke');
        }

        if (alcoholFreeDays != null) {
          details.add('$alcoholFreeDays alkoholfrie dager');
        }

        if (details.isEmpty) {
          return 'Du har valgt moderasjon.';
        }

        return details.join(' · ');
    }
  }

  Future<void> _openGoalSelection() async {
    await context.push('/goal-selection', extra: false);

    if (!mounted) {
      return;
    }

    await _loadActiveGoal();
  }

  Future<void> _createBackup() async {
    if (_isBackupBusy) {
      return;
    }

    final password = await _showPasswordDialog(
      title: 'Opprett sikkerhetskopi',
      description:
      'Velg et passord på minst 12 tegn. Passordet brukes til å '
          'kryptere sikkerhetskopien og lagres ikke av MRM.',
      confirmLabel: 'Opprett',
    );

    if (password == null || password.isEmpty) {
      return;
    }

    setState(() {
      _isBackupBusy = true;
    });

    try {
      final file = await BackupService.instance.createBackup(
        password: password,
      );

      final bytes = await file.readAsBytes();

      if (!mounted) {
        return;
      }

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Lagre sikkerhetskopi',
        fileName: file.uri.pathSegments.last,
        bytes: bytes,
        mimeType: 'application/octet-stream',
        type: FileType.custom,
        allowedExtensions: ['mrmbackup'],
      );

      if (!mounted) {
        return;
      }

      if (savedUri == null) {
        await _showBackupNotExportedDialog();
        return;
      }

      await _showBackupCreatedDialog(
        fileName: file.uri.pathSegments.last,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      await _showErrorDialog(
        'Kunne ikke opprette sikkerhetskopien.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackupBusy = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_isBackupBusy) {
      return;
    }

    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mrmbackup'],
    );

    if (files.isEmpty || files.first.path == null) {
      return;
    }

    final selectedFile = files.first;
    final file = File(selectedFile.path!);

    if (!mounted) {
      return;
    }

    final confirmed = await _showRestoreWarningDialog(
      fileName: selectedFile.name,
    );

    if (!confirmed || !mounted) {
      return;
    }

    final password = await _showPasswordDialog(
      title: 'Passord for sikkerhetskopien',
      description:
      'Skriv inn passordet som ble brukt da sikkerhetskopien ble opprettet.',
      confirmLabel: 'Gjenopprett',
    );

    if (password == null || password.isEmpty) {
      return;
    }

    setState(() {
      _isBackupBusy = true;
    });

    try {
      final restoreResult = await BackupService.instance.restoreBackup(
        file: file,
        password: password,
      );

      if (!mounted) {
        return;
      }

      await _showRestoreCompletedDialog(restoreResult);
    } catch (error) {
      if (!mounted) {
        return;
      }

      await _showErrorDialog(
        'Kunne ikke gjenopprette sikkerhetskopien.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackupBusy = false;
        });
      }
    }
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String description,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    bool obscureText = true;
    String? validationError;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final colors = Theme.of(context).colorScheme;

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: obscureText,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Passord',
                      errorText: validationError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                    onChanged: (_) {
                      if (validationError != null) {
                        setState(() {
                          validationError = null;
                        });
                      }
                    },
                    onSubmitted: (_) {
                      final value = controller.text.trim();

                      if (value.length < 12) {
                        setState(() {
                          validationError =
                          'Passordet må inneholde minst 12 tegn.';
                        });
                        return;
                      }

                      Navigator.of(dialogContext).pop(value);
                    },
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
                  onPressed: () {
                    final value = controller.text.trim();

                    if (value.length < 12) {
                      setState(() {
                        validationError =
                        'Passordet må inneholde minst 12 tegn.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    return password;
  }

  Future<bool> _showRestoreWarningDialog({
    required String fileName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Gjenopprett sikkerhetskopi?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Du har valgt:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fileName,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gjenoppretting erstatter dataene som nå ligger lokalt i MRM.',
                style: TextStyle(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'MRM oppretter automatisk en sikkerhetskopi av dagens data '
                    'før gjenopprettingen starter.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dette kan ikke angres direkte.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Gjenopprett'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showBackupCreatedDialog({
    required String fileName,
  }) async {
    final colors = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sikkerhetskopi lagret'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Den krypterte sikkerhetskopien er lagret.',
                style: TextStyle(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ta vare på både sikkerhetskopifilen og passordet. '
                    'Passordet kan ikke gjenopprettes av MRM.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBackupNotExportedDialog() async {
    final colors = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sikkerhetskopi ikke lagret'),
          content: Text(
            'Sikkerhetskopien ble opprettet, men ble ikke lagret '
                'til valgt plassering. Du kan opprette en ny sikkerhetskopi '
                'når som helst.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRestoreCompletedDialog(
      BackupRestoreResult result,
      ) async {
    final colors = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Gjenoppretting fullført'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sikkerhetskopien er gjenopprettet.',
                style: TextStyle(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'MRM opprettet først en sikkerhetskopi av dataene som '
                    'lå på enheten før gjenopprettingen.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sikkerhetskopien er lagret her:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.safetyBackup.path,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog(
      String title,
      Object error,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: const Text(
            'Kontroller at filen er en gyldig MRM-sikkerhetskopi '
                'og at passordet er riktig.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Profil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Her kan du administrere innstillinger og mål.',
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: colors.outlineVariant,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primary.withValues(alpha: 0.10),
                  child: Icon(
                    Icons.flag_outlined,
                    color: colors.primary,
                  ),
                ),
                title: Text(
                  'Mål',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _isLoading
                      ? Text(
                    'Laster mål ...',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                      : Text(
                    _goalDescription(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
                onTap: _isLoading ? null : _openGoalSelection,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: colors.outlineVariant,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primary.withValues(alpha: 0.10),
                  child: Icon(
                    Icons.person_outline,
                    color: colors.primary,
                  ),
                ),
                title: Text(
                  'Personopplysninger',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Profilinformasjon kommer her.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
                onTap: () {
                  context.push('/profile-setup');
                },
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Sikkerhetskopiering og data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MRM lagrer brukerdata lokalt på enheten. '
                  'Du kan lage en kryptert sikkerhetskopi for bruk ved '
                  'bytte eller reinstallasjon av enhet.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: colors.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                      colors.primary.withValues(alpha: 0.10),
                      child: Icon(
                        Icons.backup_outlined,
                        color: colors.primary,
                      ),
                    ),
                    title: Text(
                      'Opprett sikkerhetskopi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Lag en kryptert sikkerhetskopi av lokale data.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: _isBackupBusy
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(
                      Icons.chevron_right,
                      color: colors.onSurfaceVariant,
                    ),
                    onTap: _isBackupBusy ? null : _createBackup,
                  ),
                  Divider(
                    height: 1,
                    indent: 18,
                    endIndent: 18,
                    color: colors.outlineVariant,
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                      colors.secondary.withValues(alpha: 0.10),
                      child: Icon(
                        Icons.restore_outlined,
                        color: colors.secondary,
                      ),
                    ),
                    title: Text(
                      'Gjenopprett sikkerhetskopi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Erstatt lokale data med data fra en sikkerhetskopi.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colors.onSurfaceVariant,
                    ),
                    onTap: _isBackupBusy ? null : _restoreBackup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: colors.outlineVariant,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                  colors.onSurfaceVariant.withValues(alpha: 0.10),
                  child: Icon(
                    Icons.merge_type_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  'Slå sammen med eksisterende data',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Kommer når sammenslåing av sikkerhetskopier er ferdig implementert.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.lock_outline,
                  color: colors.onSurfaceVariant,
                ),
                onTap: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}