import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/sync_queue_dao.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late SyncQueueDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = db.syncQueueDao;
  });

  tearDown(() => db.close());

  group('SyncQueueDao', () {
    group('enqueue & getPendingByPriority', () {
      test('enqueues and retrieves pending items', () async {
        await dao.enqueue(TestFixtures.syncQueueEntry());

        final pending = await dao.getPendingByPriority();

        expect(pending.length, 1);
        expect(pending.first.id, 'sq-001');
        expect(pending.first.status, 'pending');
      });

      test('orders by priority DESC then createdAt ASC', () async {
        final now = DateTime.now();
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-1',
            priority: 0,
            targetTable: 'customers',
            createdAt: now,
          ),
        );
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-2',
            priority: 1,
            targetTable: 'orders',
            createdAt: now.add(const Duration(seconds: 1)),
          ),
        );
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-3',
            priority: 1,
            targetTable: 'inventory',
            createdAt: now,
          ),
        );

        final pending = await dao.getPendingByPriority();

        expect(pending.length, 3);
        // Priority 1 items first, ordered by createdAt ASC
        expect(pending[0].id, 'sq-3'); // priority=1, earlier time
        expect(pending[1].id, 'sq-2'); // priority=1, later time
        expect(pending[2].id, 'sq-1'); // priority=0
      });
    });

    group('markSynced', () {
      test('changes status to synced', () async {
        await dao.enqueue(TestFixtures.syncQueueEntry());

        await dao.markSynced('sq-001');

        final pending = await dao.getPendingByPriority();
        expect(pending, isEmpty);
      });
    });

    group('markRetry', () {
      test('increments retryCount and keeps status as pending', () async {
        await dao.enqueue(TestFixtures.syncQueueEntry(retryCount: 0));

        await dao.markRetry('sq-001');

        final pending = await dao.getPendingByPriority();
        expect(pending.length, 1);
        expect(pending.first.retryCount, 1);
        expect(pending.first.status, 'pending');
        expect(pending.first.lastAttempt, isNotNull);
      });
    });

    group('markFailed', () {
      test('changes status to failed and increments retryCount', () async {
        await dao.enqueue(TestFixtures.syncQueueEntry(retryCount: 2));

        await dao.markFailed('sq-001');

        final pending = await dao.getPendingByPriority();
        expect(pending, isEmpty); // No longer pending

        final failed = await dao.getFailedItems();
        expect(failed.length, 1);
        expect(failed.first.retryCount, 3);
        expect(failed.first.status, 'failed');
      });
    });

    group('resetFailed', () {
      test('resets all failed items to pending with retryCount=0', () async {
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-1',
            status: 'failed',
            retryCount: 5,
          ),
        );
        // markFailed first to set status
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-2',
            status: 'failed',
            retryCount: 3,
          ),
        );

        await dao.resetFailed();

        final pending = await dao.getPendingByPriority();
        expect(pending.length, 2);
        for (final item in pending) {
          expect(item.status, 'pending');
          expect(item.retryCount, 0);
        }
      });
    });

    group('logConflict & getRecentConflicts', () {
      test('logs and retrieves conflict entries', () async {
        await dao.logConflict(
          targetTable: 'orders',
          entityId: 'order-001',
          localJson: '{"status":"pending"}',
          remoteJson: '{"status":"completed"}',
          winner: 'remote',
        );

        final conflicts = await dao.getRecentConflicts();

        expect(conflicts.length, 1);
        expect(conflicts.first.targetTable, 'orders');
        expect(conflicts.first.winner, 'remote');
      });

      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          await dao.logConflict(
            targetTable: 'orders',
            entityId: 'order-$i',
            localJson: '{}',
            remoteJson: '{}',
            winner: 'local',
          );
        }

        final conflicts = await dao.getRecentConflicts(limit: 3);
        expect(conflicts.length, 3);
      });
    });

    group('pendingCount', () {
      test('returns count of pending items', () async {
        await dao.enqueue(TestFixtures.syncQueueEntry(id: 'sq-1'));
        await dao.enqueue(TestFixtures.syncQueueEntry(id: 'sq-2'));
        await dao.enqueue(
          TestFixtures.syncQueueEntry(id: 'sq-3', status: 'synced'),
        );

        final count = await dao.pendingCount();
        expect(count, 2);
      });
    });
  });
}
