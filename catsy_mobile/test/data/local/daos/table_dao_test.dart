import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/table_dao.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late TableDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = db.tableDao;
  });

  tearDown(() => db.close());

  group('TableDao', () {
    group('upsertTable & getTableById', () {
      test('inserts and retrieves a table', () async {
        await dao.upsertTable(TestFixtures.cafeTable());

        final table = await dao.getTableById('table-001');

        expect(table, isNotNull);
        expect(table!.label, 'Table 1');
        expect(table.status, 'available');
        expect(table.capacity, 4);
      });
    });

    group('updateTableStatus', () {
      test('changes table status', () async {
        await dao.upsertTable(TestFixtures.cafeTable());

        await dao.updateTableStatus('table-001', 'reserved');

        final table = await dao.getTableById('table-001');
        expect(table!.status, 'reserved');
      });
    });

    group('assignOrder', () {
      test('sets status to occupied and currentOrderId', () async {
        await dao.upsertTable(TestFixtures.cafeTable());

        await dao.assignOrder('table-001', 'order-001');

        final table = await dao.getTableById('table-001');
        expect(table!.status, 'occupied');
        expect(table.currentOrderId, 'order-001');
      });
    });

    group('clearTable', () {
      test('sets status to available', () async {
        await dao.upsertTable(
          TestFixtures.cafeTable(
            status: 'occupied',
            currentOrderId: 'order-001',
          ),
        );

        await dao.clearTable('table-001');

        final table = await dao.getTableById('table-001');
        expect(table!.status, 'available');
        expect(table.currentOrderId, 'order-001');
      });
    });

    group('deleteTable', () {
      test('removes table from database', () async {
        await dao.upsertTable(TestFixtures.cafeTable());

        await dao.deleteTable('table-001');

        final table = await dao.getTableById('table-001');
        expect(table, isNull);
      });
    });

    group('getAllTables', () {
      test('returns all tables', () async {
        await dao.upsertTable(TestFixtures.cafeTable(id: 't1', label: 'T1'));
        await dao.upsertTable(TestFixtures.cafeTable(id: 't2', label: 'T2'));
        await dao.upsertTable(TestFixtures.cafeTable(id: 't3', label: 'T3'));

        final tables = await dao.getAllTables();

        expect(tables.length, 3);
      });
    });
  });
}
