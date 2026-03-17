import 'package:flutter_test/flutter_test.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/reward_dao.dart';

import '../../../helpers/test_database.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late AppDatabase db;
  late RewardDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = db.rewardDao;
  });

  tearDown(() => db.close());

  group('RewardDao', () {
    group('insertReward & getAllRewards', () {
      test('inserts and retrieves a reward', () async {
        await dao.insertReward(TestFixtures.reward());

        final rewards = await dao.getAllRewards();

        expect(rewards.length, 1);
        expect(rewards.first.name, 'Free Coffee');
        expect(rewards.first.stampsRequired, 10);
      });
    });

    group('getRewardByCode', () {
      test('looks up reward by claim code', () async {
        await dao.insertReward(TestFixtures.reward(code: 'REWARD-ABC123'));

        final reward = await dao.getRewardByCode('REWARD-ABC123');

        expect(reward, isNotNull);
        expect(reward!.id, 'reward-001');
      });

      test('returns null for unknown code', () async {
        final reward = await dao.getRewardByCode('UNKNOWN-CODE');
        expect(reward, isNull);
      });
    });

    group('getActiveRewards', () {
      test('returns only active rewards', () async {
        await dao.insertReward(
          TestFixtures.reward(id: 'r1', isActive: true, code: 'CODE-1'),
        );
        await dao.insertReward(
          TestFixtures.reward(id: 'r2', isActive: false, code: 'CODE-2'),
        );

        final active = await dao.getActiveRewards();

        expect(active.length, 1);
        expect(active.first.id, 'r1');
      });
    });

    group('markRewardClaimed', () {
      test('sets isClaimed, claimedByStaffId, and claimedAt', () async {
        await dao.insertReward(TestFixtures.reward());

        await dao.markRewardClaimed('reward-001', 'staff-001');

        final reward = await dao.getRewardById('reward-001');
        expect(reward, isNotNull);
        expect(reward!.isClaimed, isTrue);
        expect(reward.claimedByStaffId, 'staff-001');
        expect(reward.claimedAt, isNotNull);
      });

      test(
        'claiming already-claimed reward updates fields (idempotent)',
        () async {
          await dao.insertReward(TestFixtures.reward());
          await dao.markRewardClaimed('reward-001', 'staff-001');
          await dao.markRewardClaimed('reward-001', 'staff-002');

          final reward = await dao.getRewardById('reward-001');
          expect(reward!.isClaimed, isTrue);
          expect(reward.claimedByStaffId, 'staff-002');
        },
      );
    });

    group('markRewardInactive', () {
      test('sets isActive to false', () async {
        await dao.insertReward(TestFixtures.reward(isActive: true));

        await dao.markRewardInactive('reward-001');

        final reward = await dao.getRewardById('reward-001');
        expect(reward!.isActive, isFalse);
      });
    });
  });
}
