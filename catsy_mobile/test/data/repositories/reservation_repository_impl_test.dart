import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/reservation_dao.dart';
import 'package:catsy_pos/data/local/database/daos/table_dao.dart';
import 'package:catsy_pos/data/repositories/reservation_repository_impl.dart';
import 'package:catsy_pos/domain/entities/reservation.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late ReservationDao reservationDao;
  late TableDao tableDao;
  late ReservationRepositoryImpl repo;

  setUp(() {
    db = createTestDatabase();
    reservationDao = db.reservationDao;
    tableDao = db.tableDao;
    repo = ReservationRepositoryImpl(
      reservationDao: reservationDao,
      tableDao: tableDao,
    );
  });

  tearDown(() => db.close());

  group('ReservationRepositoryImpl', () {
    group('approveReservation', () {
      test('sets reservation to approved and table to reserved', () async {
        // Arrange: create a table and a reservation linked to it
        await tableDao.upsertTable(
          TestFixtures.cafeTable(id: 'table-001', status: 'available'),
        );
        await reservationDao.insertReservation(
          TestFixtures.reservation(id: 'res-001', tableId: 'table-001'),
        );

        // Act
        final result = await repo.approveReservation('res-001', 'staff-001');

        // Assert — reservation approved
        expect(result.isRight(), isTrue);
        final reservation = await reservationDao.getReservationById('res-001');
        expect(reservation!.status, 'approved');
        expect(reservation.handledBy, 'staff-001');

        // Assert — table status changed to reserved
        final table = await tableDao.getTableById('table-001');
        expect(table!.status, 'reserved');
      });

      test('approves reservation without tableId (no table update)', () async {
        await reservationDao.insertReservation(
          TestFixtures.reservation(
            id: 'res-002',
            // No tableId
          ),
        );

        final result = await repo.approveReservation('res-002', 'staff-001');

        expect(result.isRight(), isTrue);
        final reservation = await reservationDao.getReservationById('res-002');
        expect(reservation!.status, 'approved');
      });
    });

    group('rejectReservation', () {
      test('sets reservation to rejected, table status unchanged', () async {
        // Arrange
        await tableDao.upsertTable(
          TestFixtures.cafeTable(id: 'table-001', status: 'available'),
        );
        await reservationDao.insertReservation(
          TestFixtures.reservation(id: 'res-001', tableId: 'table-001'),
        );

        // Act
        final result = await repo.rejectReservation(
          'res-001',
          'staff-001',
          'Fully booked',
        );

        // Assert — reservation rejected
        expect(result.isRight(), isTrue);
        final reservation = await reservationDao.getReservationById('res-001');
        expect(reservation!.status, 'rejected');
        expect(reservation.rejectionReason, 'Fully booked');

        // Assert — table status NOT changed
        final table = await tableDao.getTableById('table-001');
        expect(table!.status, 'available');
      });
    });

    group('createReservation', () {
      test('generates UUID when id is empty', () async {
        final now = DateTime.now();
        final reservation = Reservation(
          id: '', // empty — should be auto-generated
          customerName: 'Test Guest',
          customerPhone: '0917-111-2222',
          partySize: 4,
          reservationDate: DateTime(now.year, now.month, now.day),
          reservationTime: now.add(const Duration(hours: 1)),
          status: ReservationStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        final result = await repo.createReservation(reservation);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (created) {
          expect(created.id, isNotEmpty);
          expect(created.id, isNot(''));
          expect(created.customerName, 'Test Guest');
        });
      });
    });
  });
}
