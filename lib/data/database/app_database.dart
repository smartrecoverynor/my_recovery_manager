import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'database_key_service.dart';

class AppDatabase {
  static Database? _database;
  static Database? _testDatabase;

  static Future<Database> get database async {
    if (_testDatabase != null) {
      return _testDatabase!;
    }

    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static void setDatabaseForTesting(Database? database) {
    _testDatabase = database;
  }

  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'my_recovery_manager.db');

    final databaseKey = await DatabaseKeyService.getOrCreateKey();

    return openDatabase(
      path,
      password: databaseKey,
      version: 17,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_checkins (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            app_date TEXT NOT NULL,
            mood INTEGER,
            craving INTEGER,
            alcohol_units INTEGER NOT NULL,
            journal_text TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(user_id, app_date)
          )
        ''');

        await db.execute('''
          CREATE TABLE user_goals (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            goal_type TEXT NOT NULL,
            weekly_limit INTEGER,
            daily_limit INTEGER,
            alcohol_free_days INTEGER,
            valid_from TEXT NOT NULL,
            valid_to TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_user_goals_user_dates '
          'ON user_goals(user_id, valid_from, valid_to)',
        );

        await db.execute('''
          CREATE TABLE plans (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            situation_text TEXT NOT NULL,
            category TEXT NOT NULL,
            planned_date TEXT NOT NULL,
            planned_time TEXT,
            repeat_type TEXT NOT NULL,
            repeat_count INTEGER,
            repeat_until TEXT,
            note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE situations (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            text TEXT NOT NULL,
            category TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE situation_experiences (
            id TEXT PRIMARY KEY,
            situation_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            what_worked TEXT,
            what_did_not_work TEXT,
            learning TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            plan_id TEXT NOT NULL,
            type TEXT NOT NULL,
            offset_minutes INTEGER,
            scheduled_at TEXT,
            message TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await _createRiskyPlaceTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS '
            'idx_daily_checkins_user_date '
            'ON daily_checkins(user_id, app_date)',
          );
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE plans (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              situation_text TEXT NOT NULL,
              category TEXT NOT NULL,
              planned_date TEXT NOT NULL,
              planned_time TEXT NOT NULL,
              repeat_type TEXT NOT NULL,
              repeat_count INTEGER,
              repeat_until TEXT,
              note TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE situations (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              text TEXT NOT NULL,
              category TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE situation_experiences (
              id TEXT PRIMARY KEY,
              situation_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              what_worked TEXT,
              what_did_not_work TEXT,
              learning TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 6) {
          await db.execute('ALTER TABLE plans ADD COLUMN repeat_count INTEGER');

          await db.execute('ALTER TABLE plans ADD COLUMN repeat_until TEXT');
        }

        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE plans_new (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              situation_text TEXT NOT NULL,
              category TEXT NOT NULL,
              planned_date TEXT NOT NULL,
              planned_time TEXT,
              repeat_type TEXT NOT NULL,
              repeat_count INTEGER,
              repeat_until TEXT,
              note TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            INSERT INTO plans_new (
              id,
              user_id,
              situation_text,
              category,
              planned_date,
              planned_time,
              repeat_type,
              repeat_count,
              repeat_until,
              note,
              created_at,
              updated_at
            )
            SELECT
              id,
              user_id,
              situation_text,
              category,
              planned_date,
              planned_time,
              repeat_type,
              repeat_count,
              repeat_until,
              note,
              created_at,
              updated_at
            FROM plans
          ''');

          await db.execute('DROP TABLE plans');

          await db.execute('ALTER TABLE plans_new RENAME TO plans');
        }

        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE reminders (
              id TEXT PRIMARY KEY,
              plan_id TEXT NOT NULL,
              type TEXT NOT NULL,
              offset_minutes INTEGER,
              scheduled_at TEXT,
              message TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE risky_places (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              name TEXT NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              radius_meters REAL NOT NULL,
              note TEXT,
              days_of_week TEXT,
              from_time TEXT,
              to_time TEXT,
              last_notification_at TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE risky_place_alerts (
              id TEXT PRIMARY KEY,
              risky_place_id TEXT NOT NULL,
              days_of_week TEXT NOT NULL,
              from_time TEXT NOT NULL,
              to_time TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 11) {
          await db.execute('ALTER TABLE risky_places ADD COLUMN note TEXT');
        }

        if (oldVersion < 12) {
          await db.execute('''
            CREATE TABLE risky_place_settings (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              enabled INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 13) {
          await db.execute('''
            CREATE TABLE risky_place_notification_cooldowns (
              id TEXT PRIMARY KEY,
              risky_place_id TEXT NOT NULL,
              last_notified_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 14) {
          await _createRiskyPlaceTables(db);
        }

        if (oldVersion < 15) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_goals (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              goal_type TEXT NOT NULL,
              weekly_limit INTEGER,
              daily_limit INTEGER,
              alcohol_free_days INTEGER,
              valid_from TEXT NOT NULL,
              valid_to TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_user_goals_user_dates '
            'ON user_goals(user_id, valid_from, valid_to)',
          );
        }

        if (oldVersion < 16) {
          await db.execute(
            'ALTER TABLE risky_place_settings '
            'ADD COLUMN global_instruction TEXT',
          );
        }

        if (oldVersion < 17) {
          await db.execute('''
    CREATE TABLE risky_place_notification_cooldowns_new (
      id TEXT PRIMARY KEY,
      risky_place_id TEXT NOT NULL UNIQUE,
      last_notified_at TEXT NOT NULL
    )
  ''');

          await db.execute('''
    INSERT INTO risky_place_notification_cooldowns_new (
      id,
      risky_place_id,
      last_notified_at
    )
    SELECT
      risky_place_id,
      risky_place_id,
      last_notified_at
    FROM risky_place_notification_cooldowns
  ''');

          await db.execute('DROP TABLE risky_place_notification_cooldowns');

          await db.execute(
            'ALTER TABLE risky_place_notification_cooldowns_new '
            'RENAME TO risky_place_notification_cooldowns',
          );
        }
      },
    );
  }

  static Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'my_recovery_manager.db');

    final database = _database;

    _database = null;

    if (database != null && database.isOpen) {
      await database.close();
    }

    await databaseFactory.deleteDatabase(path);

    await DatabaseKeyService.deleteKey();
  }

  static Future<void> _createRiskyPlaceTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS risky_places (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL,
        note TEXT,
        days_of_week TEXT,
        from_time TEXT,
        to_time TEXT,
        last_notification_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS risky_place_alerts (
        id TEXT PRIMARY KEY,
        risky_place_id TEXT NOT NULL,
        days_of_week TEXT NOT NULL,
        from_time TEXT NOT NULL,
        to_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS risky_place_settings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        global_instruction TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS risky_place_notification_cooldowns (
    id TEXT PRIMARY KEY,
    risky_place_id TEXT NOT NULL UNIQUE,
    last_notified_at TEXT NOT NULL
  )
''');
  }
}
