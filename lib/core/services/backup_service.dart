import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/reminder_repository.dart';
import 'data_deletion_service.dart';
import 'notification_service.dart';
import 'risky_place_region_service.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const int backupFormatVersion = 1;
  static const int databaseVersion = 17;

  static const String _fileExtension = '.mrmbackup';

  static const String _magic = 'MRM_BACKUP';

  // Argon2id parameters.
  //
  // Memory is measured in 1 kB blocks.
  static const int _argonMemory = 19 * 1024;
  static const int _argonParallelism = 1;
  static const int _argonIterations = 2;
  static const int _argonHashLength = 32;

  static const String _selectedActionsKey =
      'panic_button_selected_actions';

  static const String _selectedSupportCardsKey =
      'panic_button_selected_support_cards';

  static const String _supportCardsCountKey =
      'support_cards_count';

  static const String _deletedCardsKey =
      'support_cards_deleted';

  static const String _customCardsKey =
      'support_cards_custom';

  static const String _consequencesKey =
      'panic_button_consequences';

  static const String _permissiveThoughtsCustomKey =
      'permissive_thoughts_custom';

  static const String _permissiveThoughtsResponsesKey =
      'permissive_thoughts_responses';

  static const String _contactIdKey =
      'panic_button_call_friend_contact_id';

  static const String _imagePathKey =
      'panic_button_selected_image_path';

  static const List<String> _userPreferenceKeys = [
    _selectedActionsKey,
    _selectedSupportCardsKey,
    _supportCardsCountKey,
    _deletedCardsKey,
    _customCardsKey,
    _consequencesKey,
    _permissiveThoughtsCustomKey,
    _permissiveThoughtsResponsesKey,
    _contactIdKey,
  ];

  static const List<String> _backupTables = [
    'daily_checkins',
    'user_goals',
    'plans',
    'situations',
    'situation_experiences',
    'reminders',
    'risky_places',
    'risky_place_alerts',
    'risky_place_settings',
  ];

  /// Creates an encrypted MRM backup file.
  ///
  /// The returned file is stored in the application's documents directory.
  ///
  /// The backup password is never stored by MRM.
  Future<File> createBackup({
    required String password,
  }) async {
    _validatePassword(password);

    final db = await AppDatabase.database;
    final preferences = await SharedPreferences.getInstance();

    final databaseData = <String, dynamic>{};

    for (final table in _backupTables) {
      final rows = await db.query(table);

      databaseData[table] = rows
          .map(
            (row) => Map<String, dynamic>.from(row),
      )
          .toList();
    }

    final preferencesData = <String, dynamic>{};

    for (final key in _userPreferenceKeys) {
      final value = preferences.get(key);

      if (value != null) {
        preferencesData[key] = value;
      }
    }

    final imageData = await _readPanicButtonImage();

    final payload = <String, dynamic>{
      'backupVersion': backupFormatVersion,
      'databaseVersion': databaseVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'database': databaseData,
      'preferences': preferencesData,
      'files': {
        'panicButtonImage': imageData,
      },
    };

    final plainText = utf8.encode(
      jsonEncode(payload),
    );

    final encrypted = await _encrypt(
      plainText: plainText,
      password: password,
    );

    final envelope = <String, dynamic>{
      'magic': _magic,
      'backupVersion': backupFormatVersion,
      'encryption': {
        'algorithm': 'AES-256-GCM',
        'kdf': 'Argon2id',
        'argonMemory': _argonMemory,
        'argonParallelism': _argonParallelism,
        'argonIterations': _argonIterations,
        'argonHashLength': _argonHashLength,
        'salt': base64Encode(encrypted.salt),
        'nonce': base64Encode(encrypted.nonce),
      },
      'cipherText': base64Encode(encrypted.cipherText),
      'mac': base64Encode(encrypted.mac),
    };

    final directory = await getApplicationDocumentsDirectory();

    final timestamp = _timestampForFilename(
      DateTime.now(),
    );

    final file = File(
      '${directory.path}/MRM_backup_$timestamp$_fileExtension',
    );

    await file.writeAsString(
      jsonEncode(envelope),
      flush: true,
    );

    return file;
  }

  /// Restores a backup and replaces all current local user data.
  ///
  /// The backup is fully decrypted and validated before any current data is
  /// removed. A safety backup of the current data is created first, using the
  /// same password, so the restore can be reversed manually if necessary.
  Future<BackupRestoreResult> restoreBackup({
    required File file,
    required String password,
  }) async {
    _validatePassword(password);

    final payload = await _readBackupPayload(
      file: file,
      password: password,
    );

    // The destructive operation starts only after the backup has been
    // successfully decrypted and structurally validated.
    final safetyBackup = await createBackup(password: password);

    await DataDeletionService.instance.deleteAllUserData();

    try {
      final db = await AppDatabase.database;
      final database = payload['database'] as Map<String, dynamic>;

      await db.transaction((txn) async {
        for (final table in _backupTables) {
          final rows = database[table] as List<dynamic>;

          for (final row in rows) {
            final map = Map<String, dynamic>.from(row as Map);

            await txn.insert(
              table,
              map,
            );
          }
        }
      });

      await _restorePreferences(
        payload['preferences'] as Map<String, dynamic>?,
      );

      await _restorePanicButtonImage(
        payload['files'] as Map<String, dynamic>?,
      );

      await _rebuildLocalScheduling();
    } catch (e) {
      throw StateError(
        'Gjenoppretting av backup mislyktes. '
            'En sikkerhetskopi av de tidligere dataene ble opprettet: '
            '${safetyBackup.path}. Feil: $e',
      );
    }

    final database = payload['database'] as Map<String, dynamic>;
    final rowCounts = <String, int>{};

    for (final table in _backupTables) {
      rowCounts[table] =
          (database[table] as List<dynamic>).length;
    }

    return BackupRestoreResult(
      safetyBackup: safetyBackup,
      createdAt: payload['createdAt'] as String,
      databaseVersion: (payload['databaseVersion'] as num).toInt(),
      tableRowCounts: rowCounts,
    );
  }

  Future<Map<String, dynamic>> _readBackupPayload({
    required File file,
    required String password,
  }) async {
    final envelopeText = await file.readAsString();

    final decodedEnvelope = jsonDecode(envelopeText);

    if (decodedEnvelope is! Map<String, dynamic>) {
      throw const FormatException(
        'Backupfilen har et ugyldig format.',
      );
    }

    final envelope = decodedEnvelope;

    if (envelope['magic'] != _magic) {
      throw const FormatException(
        'Filen er ikke en gyldig MRM-backup.',
      );
    }

    final backupVersion = envelope['backupVersion'];

    if (backupVersion != backupFormatVersion) {
      throw FormatException(
        'Ukjent backupversjon: $backupVersion',
      );
    }

    final encryptionValue = envelope['encryption'];

    if (encryptionValue is! Map<String, dynamic>) {
      throw const FormatException(
        'Backupfilen mangler gyldig krypteringsinformasjon.',
      );
    }

    final encryption = encryptionValue;

    if (encryption['algorithm'] != 'AES-256-GCM' ||
        encryption['kdf'] != 'Argon2id') {
      throw const FormatException(
        'Backupfilen bruker en ukjent krypteringsmetode.',
      );
    }

    final saltValue = encryption['salt'];
    final nonceValue = encryption['nonce'];
    final cipherTextValue = envelope['cipherText'];
    final macValue = envelope['mac'];

    if (saltValue is! String ||
        nonceValue is! String ||
        cipherTextValue is! String ||
        macValue is! String) {
      throw const FormatException(
        'Backupfilen mangler nødvendige krypteringsdata.',
      );
    }

    final salt = base64Decode(saltValue);
    final nonce = base64Decode(nonceValue);
    final cipherText = base64Decode(cipherTextValue);
    final mac = base64Decode(macValue);

    final argon2id = Argon2id(
      memory: _argonMemory,
      parallelism: _argonParallelism,
      iterations: _argonIterations,
      hashLength: _argonHashLength,
    );

    final secretKey =
    await argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final aesGcm = AesGcm.with256bits();

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );

    final plainText = await aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    final decodedPayload = jsonDecode(utf8.decode(plainText));

    if (decodedPayload is! Map<String, dynamic>) {
      throw const FormatException(
        'Backupens innhold har et ugyldig format.',
      );
    }

    final payload = decodedPayload;

    if (payload['backupVersion'] != backupFormatVersion) {
      throw FormatException(
        'Backupens innholdsversjon er ikke støttet: '
            '${payload['backupVersion']}',
      );
    }

    final databaseVersionValue = payload['databaseVersion'];

    if (databaseVersionValue is! num) {
      throw const FormatException(
        'Backupen mangler gyldig databaseversjon.',
      );
    }

    final sourceDatabaseVersion = databaseVersionValue.toInt();

    if (sourceDatabaseVersion > databaseVersion) {
      throw FormatException(
        'Backupen krever en nyere databaseversjon '
            '($sourceDatabaseVersion) enn denne appen støtter '
            '($databaseVersion).',
      );
    }

    final databaseValue = payload['database'];

    if (databaseValue is! Map<String, dynamic>) {
      throw const FormatException(
        'Backupen mangler en gyldig database.',
      );
    }

    for (final table in _backupTables) {
      final rows = databaseValue[table];

      if (rows is! List<dynamic>) {
        throw FormatException(
          'Backupen mangler eller har ugyldige data for '
              'tabellen "$table".',
        );
      }

      for (final row in rows) {
        if (row is! Map) {
          throw FormatException(
            'Backupen inneholder en ugyldig rad i '
                'tabellen "$table".',
          );
        }
      }
    }

    final preferences = payload['preferences'];

    if (preferences != null &&
        preferences is! Map<String, dynamic>) {
      throw const FormatException(
        'Backupen inneholder ugyldige brukerinnstillinger.',
      );
    }

    final files = payload['files'];

    if (files != null && files is! Map<String, dynamic>) {
      throw const FormatException(
        'Backupen inneholder ugyldig filinformasjon.',
      );
    }

    _validatePanicButtonImageData(
      files as Map<String, dynamic>?,
    );

    if (payload['createdAt'] is! String) {
      throw const FormatException(
        'Backupen mangler opprettelsestidspunkt.',
      );
    }

    return payload;
  }

  Future<void> _restorePreferences(
      Map<String, dynamic>? preferencesData,
      ) async {
    if (preferencesData == null) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    for (final key in _userPreferenceKeys) {
      final value = preferencesData[key];

      if (value == null) {
        continue;
      }

      if (value is String) {
        await preferences.setString(key, value);
      } else if (value is bool) {
        await preferences.setBool(key, value);
      } else if (value is int) {
        await preferences.setInt(key, value);
      } else if (value is double) {
        await preferences.setDouble(key, value);
      } else if (value is List) {
        final strings = value.map((item) => item.toString()).toList();
        await preferences.setStringList(key, strings);
      } else {
        throw FormatException(
          'Ugyldig verdi for brukerinnstillingen "$key".',
        );
      }
    }
  }

  Future<void> _restorePanicButtonImage(
      Map<String, dynamic>? filesData,
      ) async {
    final imageData = filesData?['panicButtonImage'];

    if (imageData == null) {
      return;
    }

    if (imageData is! Map<String, dynamic>) {
      throw const FormatException(
        'Panic Button-bildet i backupen er ugyldig.',
      );
    }

    final extension = imageData['extension'] as String? ?? '';
    final encodedBytes = imageData['bytes'];

    if (encodedBytes is! String) {
      throw const FormatException(
        'Panic Button-bildet mangler data.',
      );
    }

    final bytes = base64Decode(encodedBytes);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = _timestampForFilename(DateTime.now());

    final file = File(
      '${directory.path}/panic_button_image_restore_$timestamp$extension',
    );

    await file.writeAsBytes(bytes, flush: true);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_imagePathKey, file.path);
  }

  void _validatePanicButtonImageData(
      Map<String, dynamic>? filesData,
      ) {
    final imageData = filesData?['panicButtonImage'];

    if (imageData == null) {
      return;
    }

    if (imageData is! Map<String, dynamic>) {
      throw const FormatException(
        'Panic Button-bildet i backupen er ugyldig.',
      );
    }

    final extension = imageData['extension'];
    final bytes = imageData['bytes'];

    if (extension is! String || bytes is! String) {
      throw const FormatException(
        'Panic Button-bildet i backupen mangler nødvendige data.',
      );
    }

    if (extension.isNotEmpty &&
        !RegExp(r'^\.[a-zA-Z0-9]{1,8}$').hasMatch(extension)) {
      throw const FormatException(
        'Panic Button-bildet har en ugyldig filendelse.',
      );
    }

    try {
      base64Decode(bytes);
    } on FormatException {
      throw const FormatException(
        'Panic Button-bildet inneholder ugyldige data.',
      );
    }
  }

  Future<void> _rebuildLocalScheduling() async {
    await NotificationService.instance.cancelAll();

    final planRepository = PlanRepository();
    final reminderRepository = ReminderRepository();

    final plans = await planRepository.getAll(
      userId: 'local-user',
    );

    for (final plan in plans) {
      final reminders = await reminderRepository.getForPlan(
        plan.id,
      );

      for (final reminder in reminders) {
        await NotificationService.instance.scheduleReminder(
          plan: plan,
          reminder: reminder,
        );
      }
    }

    await RiskyPlaceRegionService.instance.syncAllPlaces();
  }

  Future<_EncryptedBackup> _encrypt({
    required List<int> plainText,
    required String password,
  }) async {
    final argon2id = Argon2id(
      memory: _argonMemory,
      parallelism: _argonParallelism,
      iterations: _argonIterations,
      hashLength: _argonHashLength,
    );

    final salt = _randomBytes(16);

    final secretKey = await argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final aesGcm = AesGcm.with256bits();

    final secretBox = await aesGcm.encrypt(
      plainText,
      secretKey: secretKey,
    );

    return _EncryptedBackup(
      salt: salt,
      nonce: secretBox.nonce,
      cipherText: secretBox.cipherText,
      mac: secretBox.mac.bytes,
    );
  }

  Future<Map<String, dynamic>?> _readPanicButtonImage() async {
    final preferences = await SharedPreferences.getInstance();

    final imagePath = preferences.getString(_imagePathKey);

    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    final file = File(imagePath);

    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();

    final extension = _getFileExtension(imagePath);

    return {
      'extension': extension,
      'bytes': base64Encode(bytes),
    };
  }

  String _getFileExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex).toLowerCase();
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();

    return List<int>.generate(
      length,
          (_) => random.nextInt(256),
    );
  }

  void _validatePassword(String password) {
    if (password.length < 12) {
      throw ArgumentError(
        'Backup-passordet må inneholde minst 12 tegn.',
      );
    }
  }

  String _timestampForFilename(DateTime dateTime) {
    final local = dateTime.toLocal();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${local.year}'
        '${twoDigits(local.month)}'
        '${twoDigits(local.day)}_'
        '${twoDigits(local.hour)}'
        '${twoDigits(local.minute)}'
        '${twoDigits(local.second)}';
  }
}

class BackupRestoreResult {
  final File safetyBackup;
  final String createdAt;
  final int databaseVersion;
  final Map<String, int> tableRowCounts;

  const BackupRestoreResult({
    required this.safetyBackup,
    required this.createdAt,
    required this.databaseVersion,
    required this.tableRowCounts,
  });
}

class _EncryptedBackup {
  final List<int> salt;
  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;

  const _EncryptedBackup({
    required this.salt,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });
}