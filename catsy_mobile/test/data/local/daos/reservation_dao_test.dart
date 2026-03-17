import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/reservation_dao.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late ReservationDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = db.reservationDao;
  });

  tearDown(() => db.close());

  group('ReservationDao', () {
    group('insertReservation & getReservationById', () {
      test('inserts and retrieves a reservation', () async {
        await dao.insertReservation(TestFixtures.reservation());

        final result = await dao.getReservationById('res-001');

        expect(result, isNotNull);
        expect(result!.customerName, 'Juan Cruz');
        expect(result.status, 'pending');
        expect(result.partySize, 4);
      });

      test('returns null for non-existent ID', () async {
        final result = await dao.getReservationById('non-existent');
        expect(result, isNull);
      });
    });

    group('updateReservationStatus', () {
      test('approves with handledBy', () async {
        await dao.insertReservation(TestFixtures.reservation());

        await dao.updateReservationStatus(
          'res-001',
          'approved',
          handledBy: 'staff-001',
        );

        final r = await dao.getReservationById('res-001');
        expect(r!.status, 'approved');
        expect(r.handledBy, 'staff-001');
      });

      test('rejects with reason', () async {
        await dao.insertReservation(TestFixtures.reservation());

        await dao.updateReservationStatus(
          'res-001',
          'rejected',
          handledBy: 'staff-001',
          rejectionReason: 'Fully booked',
        );

        final r = await dao.getReservationById('res-001');
        expect(r!.status, 'rejected');
        expect(r.rejectionReason, 'Fully booked');
      });
    });

    group('getReservationsByDate', () {
      test('returns reservations for the given date', () async {
        final targetDate = DateTime(2026, 3, 7, 10, 0);
        // Use a date well outside the target day to avoid BETWEEN boundary issues
        final otherDate = DateTime(2026, 3, 10, 10, 0);

        await dao.insertReservation(
          TestFixtures.reservation(id: 'r1', reservationDate: targetDate),
        );
        await dao.insertReservation(
          TestFixtures.reservation(id: 'r2', reservationDate: otherDate),
        );

        final results = await dao.getReservationsByDate(targetDate);

        expect(results.length, 1);
        expect(results.first.id, 'r1');
      });
    });
  });
}
