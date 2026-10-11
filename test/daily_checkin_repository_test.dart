
import 'package:flutter_test/flutter_test.dart';

import 'package:my_recovery_manager/data/models/daily_checkin.dart';
import 'package:my_recovery_manager/data/repositories/daily_checkin_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('DailyCheckin kan lagres og hentes igjen', () async {
    final repository = DailyCheckinRepository();

    final checkin = DailyCheckin.create(
      id: 'test-1',
      userId: 'test-user',
      dateTime: DateTime(2026, 8, 9, 10, 0),
      mood: 4,
      craving: 6,
      alcoholUnits: 2,
      journalText: 'Testregistrering',
    );

    await repository.save(checkin);

    final result = await repository.getByDate(
      userId: 'test-user',
      appDate: checkin.appDate,
    );

    expect(result, isNotNull);
    expect(result!.id, 'test-1');
    expect(result.userId, 'test-user');
    expect(result.mood, 4);
    expect(result.craving, 6);
    expect(result.alcoholUnits, 2);
    expect(result.journalText, 'Testregistrering');
  });
}
