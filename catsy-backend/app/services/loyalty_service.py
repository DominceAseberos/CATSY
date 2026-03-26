import uuid
from typing import Optional
from app.repositories.loyalty_repo import LoyaltyRepository

class LoyaltyService:
    def __init__(self, loyalty_repo: LoyaltyRepository):
        self.repo = loyalty_repo

    def get_status(self, user_id: str):
        return self.repo.get_loyalty_status(user_id)

    def claim_reward(self, user_id: str, reward_item: str):
        # Business logic: Check unspent stamps and create reward
        unspent_stamps = self.repo.get_unspent_stamps(user_id, limit=9)
        if len(unspent_stamps) < 9:
            raise ValueError("Insufficient stamps (need 9)")

        coupon_code = uuid.uuid4().hex[:8].upper()
        reward_data = {
            "user_id": user_id,
            "coupon_code": coupon_code,
            "reward_item": reward_item,
            "status": "active",
        }
        
        reward_res = self.repo.create_reward(reward_data)
        if not reward_res:
            raise Exception("Failed to create reward")
            
        reward_id = reward_res[0]['id']
        stamp_ids = [s['id'] for s in unspent_stamps]

        self.repo.mark_stamps_spent(stamp_ids, reward_id)
        
        return reward_res[0]

    def redeem_reward(self, coupon_code: str, staff_id: str):
        """Staff validates and redeems a coupon code in-store (FR S8/Phase 2.5).
        - Looks up the reward by coupon_code
        - Rejects if already redeemed
        - Marks as redeemed with staff_id for audit trail
        """
        reward = self.repo.get_reward_by_code(coupon_code)
        if not reward:
            raise ValueError(f"Coupon code '{coupon_code}' not found.")
        if reward.get("status") != "active":
            raise ValueError(f"Coupon code '{coupon_code}' has already been redeemed or is invalid.")
        return self.repo.mark_reward_redeemed(reward["id"], staff_id=staff_id)

    def credit_stamps(self, customer_id: str, count: int, staff_id: str):
        stamps_to_insert = [
            {"user_id": customer_id, "is_spent": False, "staff_id": staff_id}
            for _ in range(count)
        ]
        
        # Insert new stamps via repo
        try:
            self.repo.insert_stamps(stamps_to_insert)
        except Exception as e:
            raise Exception(f"Failed to credit stamps: {e}")
            
        return {"credited": count, "customer_id": customer_id}
