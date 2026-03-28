"""
Reward Items Repository
======================

What:
    Manages the reward_items table, supporting loyalty reward management.

How:
    Implements a repository class to handle all Supabase queries for reward items, including active filtering and product association.

When:
    Used by admin endpoints for reward management and by public endpoints for listing available rewards.

What it does:
    - Retrieves all or only active reward items
    - Creates, updates, deletes, and toggles reward items
    - Associates rewards with products for loyalty claims
"""
from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db


class RewardItemsRepository(IRepository):
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        db = get_db()
        # Join with products to return full product details
        res = db.table('reward_items').select(
            "id, is_active, created_at, products(product_id, product_name, product_price, product_is_available)"
        ).order('created_at').execute()
        return res.data or []

    def get_active(self) -> List[Any]:
        """Returns only active reward items (for loyalty claim picker)."""
        db = get_db()
        res = db.table('reward_items').select(
            "id, is_active, products(product_id, product_name, product_price, product_is_available)"
        ).eq('is_active', True).execute()
        return res.data or []

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        res = db.table('reward_items').select("*").eq('id', id).execute()
        return res.data[0] if res.data else None

    def create(self, dict_data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        res = db.table('reward_items').insert(dict_data).execute()
        return res.data

    def update(self, id: str, dict_data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        res = db.table('reward_items').update(dict_data).eq('id', id).execute()
        return res.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        db = get_db()
        res = db.table('reward_items').delete().eq('id', id).execute()
        return res.data

    def toggle_active(self, id: str, is_active: bool) -> Any:
        db = get_db()
        res = db.table('reward_items').update({'is_active': is_active}).eq('id', id).execute()
        return res.data[0] if res.data else None
