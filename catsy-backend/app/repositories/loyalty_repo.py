from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db

class LoyaltyRepository(IRepository):
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        return []

    def get_by_id(self, id: str) -> Optional[Any]:
        return None

    def create(self, dict_data: dict, user_id: Optional[str] = None) -> Any:
        return None

    def update(self, id: str, dict_data: dict, user_id: Optional[str] = None) -> Any:
        return None

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        return None

    def get_loyalty_status(self, user_id: str):
        db = get_db()
        stamps_res = db.table('loyalty_stamps').select("*").eq('user_id', user_id).eq('is_spent', False).execute()
        rewards_res = db.table('loyalty_rewards').select("*").eq('user_id', user_id).order('created_at', desc=True).execute()
        return {
            "unspent_count": len(stamps_res.data),
            "stamps": stamps_res.data,
            "rewards": rewards_res.data,
        }

    def get_unspent_stamps(self, user_id: str, limit: int = 9) -> List[Any]:
        db = get_db()
        stamps_res = db.table('loyalty_stamps').select("id").eq('user_id', user_id).eq('is_spent', False).limit(limit).execute()
        return stamps_res.data

    def create_reward(self, reward_data: dict) -> Any:
        db = get_db()
        reward_res = db.table('loyalty_rewards').insert(reward_data).execute()
        return reward_res.data

    def mark_stamps_spent(self, stamp_ids: List[str], reward_id: str):
        db = get_db()
        db.table('loyalty_stamps').update({
            "is_spent": True,
            "reward_id": reward_id,
        }).in_('id', stamp_ids).execute()

    def insert_stamps(self, stamps_data: List[dict]):
        db = get_db()
        db.table('loyalty_stamps').insert(stamps_data).execute()

    def get_reward_by_code(self, coupon_code: str):
        """Look up a reward by its coupon code (for staff redemption)."""
        db = get_db()
        res = db.table('loyalty_rewards').select("*").eq('coupon_code', coupon_code).execute()
        return res.data[0] if res.data else None

    def mark_reward_redeemed(self, reward_id: str, staff_id: str):
        """Mark a reward as redeemed — single-use enforcement."""
        db = get_db()
        res = db.table('loyalty_rewards').update({
            "status": "redeemed",
            "redeemed_by_staff_id": staff_id,
        }).eq('id', reward_id).execute()
        return res.data[0] if res.data else {"id": reward_id, "status": "redeemed"}
