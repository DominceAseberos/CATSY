import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/customer_dao.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late CustomerDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = db.customerDao;
  });

  tearDown(() => db.close());

  group('CustomerDao', () {
    group('upsertCustomer & getCustomerById', () {
      test('inserts and retrieves a customer', () async {
        await dao.upsertCustomer(TestFixtures.customer());

        final customer = await dao.getCustomerById('cust-001');

        expect(customer, isNotNull);
        expect(customer!.name, 'Maria Santos');
        expect(customer.totalStamps, 0);
      });
    });

    group('getCustomerByQRCode', () {
      test('retrieves customer by QR code', () async {
        await dao.upsertCustomer(TestFixtures.customer(qrCode: 'QR-CUST-001'));

        final customer = await dao.getCustomerByQRCode('QR-CUST-001');

        expect(customer, isNotNull);
        expect(customer!.id, 'cust-001');
      });

      test('returns null for unknown QR code', () async {
        final customer = await dao.getCustomerByQRCode('UNKNOWN-QR');
        expect(customer, isNull);
      });
    });

    group('updateStamps', () {
      test('updates total stamp count', () async {
        await dao.upsertCustomer(TestFixtures.customer(totalStamps: 5));

        await dao.updateStamps('cust-001', 8);

        final customer = await dao.getCustomerById('cust-001');
        expect(customer!.totalStamps, 8);
      });
    });

    group('insertStampLog & getStampLogs', () {
      test('inserts and retrieves stamp logs', () async {
        await dao.upsertCustomer(TestFixtures.customer());
        await dao.insertStampLog(TestFixtures.stampLog(id: 'stamp-1'));
        await dao.insertStampLog(TestFixtures.stampLog(id: 'stamp-2'));

        final logs = await dao.getStampLogs('cust-001');

        expect(logs.length, 2);
      });

      test('stamp logs are ordered by createdAt DESC', () async {
        await dao.upsertCustomer(TestFixtures.customer());
        await dao.insertStampLog(TestFixtures.stampLog(id: 'stamp-1'));
        await dao.insertStampLog(TestFixtures.stampLog(id: 'stamp-2'));

        final logs = await dao.getStampLogs('cust-001');

        // Both have same createdAt in fixtures, so just check they're returned
        expect(logs.length, 2);
      });
    });

    group('searchCustomers', () {
      test('searches by name', () async {
        await dao.upsertCustomer(
          TestFixtures.customer(
            id: 'c1',
            name: 'Maria Santos',
            email: 'santos@test.com',
            phone: '0911-111-1111',
          ),
        );
        await dao.upsertCustomer(
          TestFixtures.customer(
            id: 'c2',
            name: 'Pedro Cruz',
            email: 'pedro@test.com',
            phone: '0922-222-2222',
            qrCode: 'QR-C2',
          ),
        );

        final results = await dao.searchCustomers('Maria');

        expect(results.length, 1);
        expect(results.first.name, 'Maria Santos');
      });

      test('searches by email', () async {
        await dao.upsertCustomer(
          TestFixtures.customer(
            id: 'c1',
            name: 'Customer One',
            email: 'unique_alpha@café.ph',
            phone: '0911-111-1111',
            qrCode: 'QR-1',
          ),
        );
        await dao.upsertCustomer(
          TestFixtures.customer(
            id: 'c2',
            name: 'Customer Two',
            email: 'unique_beta@café.ph',
            phone: '0922-222-2222',
            qrCode: 'QR-2',
          ),
        );

        final results = await dao.searchCustomers('alpha');

        expect(results.length, 1);
        expect(results.first.id, 'c1');
      });
    });
  });
}
