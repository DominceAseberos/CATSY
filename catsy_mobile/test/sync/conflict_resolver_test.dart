import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/sync/conflict_resolver.dart';

void main() {
  late ConflictResolver resolver;

  setUp(() {
    // Use noLog variant — no DAO needed for pure logic tests
    resolver = const ConflictResolver.noLog();
  });

  group('ConflictResolver', () {
    group('Delete-wins strategy', () {
      test('returns null when remote has deleted=true', () async {
        final result = await resolver.resolve(
          targetTable: 'customers',
          entityId: 'c-001',
          local: {
            'id': 'c-001',
            'name': 'Maria',
            'updated_at': '2026-03-07T12:00:00Z',
          },
          remote: {
            'id': 'c-001',
            'deleted': true,
            'updated_at': '2026-03-07T13:00:00Z',
          },
        );

        expect(result, isNull, reason: 'Delete-wins should return null');
      });
    });

    group('Last-Writer-Wins (LWW) strategy', () {
      test('local wins when local is newer', () async {
        final result = await resolver.resolve(
          targetTable: 'customers',
          entityId: 'c-001',
          local: {
            'id': 'c-001',
            'name': 'Maria Updated',
            'updated_at': '2026-03-07T14:00:00Z',
          },
          remote: {
            'id': 'c-001',
            'name': 'Maria Old',
            'updated_at': '2026-03-07T12:00:00Z',
          },
        );

        expect(result!['name'], 'Maria Updated');
      });

      test('remote wins when remote is newer', () async {
        final result = await resolver.resolve(
          targetTable: 'customers',
          entityId: 'c-001',
          local: {
            'id': 'c-001',
            'name': 'Maria Local',
            'updated_at': '2026-03-07T12:00:00Z',
          },
          remote: {
            'id': 'c-001',
            'name': 'Maria Remote',
            'updated_at': '2026-03-07T15:00:00Z',
          },
        );

        expect(result!['name'], 'Maria Remote');
      });

      test('remote wins when both timestamps are null', () async {
        final result = await resolver.resolve(
          targetTable: 'customers',
          entityId: 'c-001',
          local: {'id': 'c-001', 'name': 'Local'},
          remote: {'id': 'c-001', 'name': 'Remote'},
        );

        expect(result!['name'], 'Remote');
      });

      test('remote wins when local timestamp is null', () async {
        final result = await resolver.resolve(
          targetTable: 'customers',
          entityId: 'c-001',
          local: {'id': 'c-001', 'name': 'Local'},
          remote: {
            'id': 'c-001',
            'name': 'Remote',
            'updated_at': '2026-03-07T12:00:00Z',
          },
        );

        expect(result!['name'], 'Remote');
      });

      test('local wins when remote timestamp is null', () async {
        final result = await resolver.resolve(
          targetTable: 'customers',
          entityId: 'c-001',
          local: {
            'id': 'c-001',
            'name': 'Local',
            'updated_at': '2026-03-07T12:00:00Z',
          },
          remote: {'id': 'c-001', 'name': 'Remote'},
        );

        expect(result!['name'], 'Local');
      });
    });

    group('Order merge strategy', () {
      test('uses newer record as base for orders', () async {
        final result = await resolver.resolve(
          targetTable: 'orders',
          entityId: 'o-001',
          local: {
            'id': 'o-001',
            'status': 'pending',
            'payment_status': 'pending',
            'updated_at': '2026-03-07T12:00:00Z',
          },
          remote: {
            'id': 'o-001',
            'status': 'completed',
            'payment_status': 'paid',
            'updated_at': '2026-03-07T14:00:00Z',
          },
        );

        expect(result!['status'], 'completed');
        expect(result['payment_status'], 'paid');
      });

      test('preserves local notes when remote has none', () async {
        final result = await resolver.resolve(
          targetTable: 'orders',
          entityId: 'o-001',
          local: {
            'id': 'o-001',
            'status': 'pending',
            'notes': 'Extra napkins please',
            'updated_at': '2026-03-07T12:00:00Z',
          },
          remote: {
            'id': 'o-001',
            'status': 'completed',
            'notes': null,
            'updated_at': '2026-03-07T14:00:00Z',
          },
        );

        // Remote wins (newer) but local notes are preserved
        expect(result!['notes'], 'Extra napkins please');
        expect(result['status'], 'completed');
      });

      test('uses remote notes when remote has them', () async {
        final result = await resolver.resolve(
          targetTable: 'orders',
          entityId: 'o-001',
          local: {
            'id': 'o-001',
            'notes': 'Local notes',
            'updated_at': '2026-03-07T12:00:00Z',
          },
          remote: {
            'id': 'o-001',
            'notes': 'Remote notes',
            'updated_at': '2026-03-07T14:00:00Z',
          },
        );

        // Remote wins (newer) and has notes, so remote notes used
        expect(result!['notes'], 'Remote notes');
      });
    });

    group('Delete-wins takes priority over order merge', () {
      test('delete-wins even for orders table', () async {
        final result = await resolver.resolve(
          targetTable: 'orders',
          entityId: 'o-001',
          local: {
            'id': 'o-001',
            'status': 'pending',
            'updated_at': '2026-03-07T15:00:00Z',
          },
          remote: {
            'id': 'o-001',
            'deleted': true,
            'updated_at': '2026-03-07T14:00:00Z',
          },
        );

        expect(
          result,
          isNull,
          reason: 'Delete-wins should take precedence even for orders',
        );
      });
    });
  });
}
