import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/sync_queue_dao.dart';
import 'package:catsy_pos/sync/sync_queue_manager.dart';

import '../helpers/mocks.dart';
import '../helpers/test_database.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late SyncQueueDao dao;
  late MockApiClient mockApi;
  late MockSyncStatusNotifier mockStatusNotifier;
  late SyncQueueManager manager;

  setUp(() {
    db = createTestDatabase();
    dao = db.syncQueueDao;
    mockApi = MockApiClient();
    mockStatusNotifier = MockSyncStatusNotifier();
    manager = SyncQueueManager(
      dao: dao,
      api: mockApi,
      statusNotifier: mockStatusNotifier,
    );
  });

  tearDown(() => db.close());

  group('SyncQueueManager', () {
    group('processQueue — priority ordering', () {
      test('processes high-priority items before normal-priority', () async {
        final callOrder = <String>[];

        // Insert a normal-priority item first
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-normal',
            targetTable: 'customers',
            priority: 0,
            payload: jsonEncode({'id': 'cust-001'}),
          ),
        );
        // Insert a high-priority item second
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-high',
            targetTable: 'orders',
            priority: 1,
            payload: jsonEncode({'id': 'order-001'}),
          ),
        );

        when(
          () => mockApi.post(
            any(),
            any(),
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).thenAnswer((inv) async {
          final path = inv.positionalArguments[0] as String;
          callOrder.add(path);
          return {'ok': true};
        });

        await manager.processQueue();

        expect(callOrder.length, 2);
        // High-priority (orders) should be processed first
        expect(callOrder[0], '/api/v1/orders');
        expect(callOrder[1], '/api/v1/customers');
      });
    });

    group('processQueue — SocketException handling', () {
      test('marks item for retry on network error', () async {
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-net',
            targetTable: 'orders',
            payload: jsonEncode({'id': 'order-001'}),
          ),
        );

        when(
          () => mockApi.post(
            any(),
            any(),
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).thenThrow(const SocketException('Connection refused'));

        await manager.processQueue();

        final pending = await dao.getPendingByPriority();
        expect(pending.length, 1);
        expect(pending.first.retryCount, 1); // retried
        expect(pending.first.status, 'pending'); // stays pending
      });
    });

    group('processQueue — HTTP 4xx', () {
      test('marks item as failed on 4xx error', () async {
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-4xx',
            targetTable: 'orders',
            payload: jsonEncode({'id': 'order-001'}),
          ),
        );

        when(
          () => mockApi.post(
            any(),
            any(),
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).thenThrow(const ServerFailure(message: 'HTTP 400: Bad Request'));
        when(() => mockStatusNotifier.incrementFailedAlert()).thenReturn(null);

        await manager.processQueue();

        final pending = await dao.getPendingByPriority();
        expect(pending, isEmpty);

        final failed = await dao.getFailedItems();
        expect(failed.length, 1);
        expect(failed.first.status, 'failed');
      });
    });

    group('processQueue — HTTP 5xx', () {
      test('marks item for retry on 5xx error', () async {
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-5xx',
            targetTable: 'orders',
            payload: jsonEncode({'id': 'order-001'}),
          ),
        );

        when(
          () => mockApi.post(
            any(),
            any(),
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).thenThrow(
          const ServerFailure(message: 'HTTP 500: Internal Server Error'),
        );

        await manager.processQueue();

        final pending = await dao.getPendingByPriority();
        expect(pending.length, 1);
        expect(pending.first.retryCount, 1);
        expect(pending.first.status, 'pending');
      });
    });

    group('processQueue — max retries exhausted', () {
      test('marks item as failed after max retries', () async {
        // Insert item already at max retries (5)
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-max',
            targetTable: 'orders',
            retryCount: 5,
            payload: jsonEncode({'id': 'order-001'}),
          ),
        );

        when(() => mockStatusNotifier.incrementFailedAlert()).thenReturn(null);

        await manager.processQueue();

        final failed = await dao.getFailedItems();
        expect(failed.length, 1);
        expect(failed.first.status, 'failed');

        verify(() => mockStatusNotifier.incrementFailedAlert()).called(1);
      });
    });

    group('processQueue — successful sync', () {
      test('marks item as synced on success', () async {
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-ok',
            targetTable: 'orders',
            payload: jsonEncode({'id': 'order-001'}),
          ),
        );

        when(
          () => mockApi.post(
            any(),
            any(),
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).thenAnswer((_) async => {'ok': true});

        await manager.processQueue();

        final pending = await dao.getPendingByPriority();
        expect(pending, isEmpty);
      });
    });

    group('processQueue — action routing', () {
      test('routes UPDATE action to PUT', () async {
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-upd',
            targetTable: 'orders',
            entityId: 'order-001',
            action: 'UPDATE',
            payload: jsonEncode({'id': 'order-001', 'status': 'completed'}),
          ),
        );

        when(
          () => mockApi.put(
            any(),
            any(),
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).thenAnswer((_) async => {'ok': true});

        await manager.processQueue();

        verify(
          () => mockApi.put(
            '/api/v1/orders/order-001',
            any(),
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).called(1);
      });

      test('routes DELETE action to DELETE', () async {
        await dao.enqueue(
          TestFixtures.syncQueueEntry(
            id: 'sq-del',
            targetTable: 'orders',
            entityId: 'order-001',
            action: 'DELETE',
            payload: jsonEncode({'id': 'order-001'}),
          ),
        );

        when(
          () => mockApi.delete(any(), extraHeaders: any(named: 'extraHeaders')),
        ).thenAnswer((_) async => {'ok': true});

        await manager.processQueue();

        verify(
          () => mockApi.delete(
            '/api/v1/orders/order-001',
            extraHeaders: any(named: 'extraHeaders'),
          ),
        ).called(1);
      });
    });

    group('processQueue — empty queue', () {
      test('does nothing when queue is empty', () async {
        await manager.processQueue();

        // No API calls should have been made
        verifyNever(() => mockApi.post(any(), any()));
        verifyNever(() => mockApi.put(any(), any()));
        verifyNever(() => mockApi.delete(any()));
      });
    });

    group('SyncPriority', () {
      test('orders table gets high priority', () {
        expect(SyncPriority.forTable('orders'), SyncPriority.high);
      });

      test('inventory table gets high priority', () {
        expect(SyncPriority.forTable('inventory'), SyncPriority.high);
      });

      test('other tables get normal priority', () {
        expect(SyncPriority.forTable('customers'), SyncPriority.normal);
        expect(SyncPriority.forTable('reservations'), SyncPriority.normal);
      });
    });
  });
}
