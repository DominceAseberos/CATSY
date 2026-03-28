"""
LoyaltyRepository — fixed version.

Changes:
  1. No longer inherits IRepository — loyalty needs none of the five base
     methods (get_all, get_by_id, create, update, delete all returned None/[]).
  2. Only the methods that are actually implemented are kept.
     This is the Interface Segregation fix — depend only on what you use.
"""
from typing import List, Any
from app.database import get_db


class LoyaltyRepository:
    """Data-access layer for loyalty stamps and rewards."""

    def get_loyalty_status(self, user_id: str) -> dict:
        db = get_db()
        stamps_res = (
            db.table("loyalty_stamps")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_spent", False)
            .execute()
        )
        rewards_res = (
            db.table("loyalty_rewards")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return {
            "unspent_count": len(stamps_res.data),
            "stamps": stamps_res.data,
            "rewards": rewards_res.data,
        }

    def get_unspent_stamps(self, user_id: str, limit: int = 9) -> List[Any]:
        db = get_db()
        res = (
            db.table("loyalty_stamps")
            .select("id")
            .eq("user_id", user_id)
            .eq("is_spent", False)
            .limit(limit)
            .execute()
        )
        return res.data

    def create_reward(self, reward_data: dict) -> Any:
        db = get_db()
        return db.table("loyalty_rewards").insert(reward_data).execute().data

    def mark_stamps_spent(self, stamp_ids: List[str], reward_id: str) -> None:
        db = get_db()
        db.table("loyalty_stamps").update(
            {"is_spent": True, "reward_id": reward_id}
        ).in_("id", stamp_ids).execute()

    def insert_stamps(self, stamps_data: List[dict]) -> None:
        db = get_db()
        db.table("loyalty_stamps").insert(stamps_data).execute()

    def get_reward_by_code(self, coupon_code: str) -> Any:
        db = get_db()
        res = (
            db.table("loyalty_rewards")
            .select("*")
            .eq("coupon_code", coupon_code)
            .execute()
        )
        return res.data[0] if res.data else None

    def mark_reward_redeemed(self, reward_id: str, staff_id: str) -> Any:
        db = get_db()
        res = (
            db.table("loyalty_rewards")
            .update({"status": "redeemed", "redeemed_by_staff_id": staff_id})
            .eq("id", reward_id)
            .execute()
        )
        return res.data[0] if res.data else {"id": reward_id, "status": "redeemed"}