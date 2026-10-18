import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/diary_table.dart';
import 'package:sport_log/models/diary/diary.dart';

import '../test_setup.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initConfig();
    await initDatabaseFactory();
  });

  setUp(AppDatabase.reset);

  group('setSynchronizedIfUnchanged', () {
    Future<void> unchanged(DiaryTable table, Diary diary) async {}
    Future<void> changed(DiaryTable table, Diary diary) =>
        table.updateSingle(diary..comments = 'changed');
    Future<void> deleted(DiaryTable table, Diary diary) =>
        table.deleteSingle(diary.id);

    for (final (status, changeName, change, expected) in [
      (SyncStatus.created, 'unchanged', unchanged, SyncStatus.synchronized),
      (SyncStatus.created, 'changed', changed, SyncStatus.updated),
      (SyncStatus.created, 'deleted', deleted, SyncStatus.updated),
      (SyncStatus.updated, 'unchanged', unchanged, SyncStatus.synchronized),
      (SyncStatus.updated, 'changed', changed, SyncStatus.updated),
      (SyncStatus.updated, 'deleted', deleted, SyncStatus.updated),
      (
        SyncStatus.updated,
        'synchronized by a pull',
        (DiaryTable table, Diary diary) => table.upsertMultiple([
          diary..comments = 'pulled',
        ], synchronized: true),
        SyncStatus.synchronized,
      ),
    ]) {
      test(
        '${status.name} record $changeName during push is ${expected.name}',
        () async {
          final table = DiaryTable();
          final diary = testDiary(1);
          await table.createSingle(diary);
          await table.setSyncStatus(diary, status);
          final pushed = (await table.getById(diary.id))!;
          await change(table, diary);

          await table.setSynchronizedIfUnchanged([pushed]);

          expect(await table.getSyncStatus(diary), expected);
        },
      );
    }

    test('record hard deleted during push is skipped', () async {
      final table = DiaryTable();
      final hardDeleted = testDiary(1);
      await table.createSingle(hardDeleted);
      final other = testDiary(2);
      await table.createSingle(other);
      await table.hardDeleteSingle(hardDeleted.id);

      await table.setSynchronizedIfUnchanged([hardDeleted, other]);

      expect(await table.getSyncStatus(hardDeleted), isNull);
      expect(await table.getSyncStatus(other), SyncStatus.synchronized);
    });

    test('record created during push stays created', () async {
      final table = DiaryTable();
      final pushed = testDiary(1);
      await table.createSingle(pushed);
      final created = testDiary(2);
      await table.createSingle(created);

      await table.setSynchronizedIfUnchanged([pushed]);

      expect(await table.getSyncStatus(created), SyncStatus.created);
    });
  });
}
