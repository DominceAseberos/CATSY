"""
SupabaseRepository — Data Access Layer (SRP, DIP).

All reads and writes go through this class.
`get_db()` is called per-method rather than using the module-level
singleton directly. This means tests can monkeypatch `app.database.supabase`
without modifying repository code (Dependency Inversion).
"""
import uuid
from typing import List, Optional
from app.database import get_db
from app.utils.audit_logger import AuditLogger


class SupabaseRepository:

    # ── Read operations ───────────────────────────────────────────────────────

    @staticmethod
    def get_products(limit: int = 100, offset: int = 0):
        db = get_db()
        query = db.table('products').select(
            "*, categories!products_category_id_fkey(name)"
        ).range(offset, offset + limit - 1)
        response = query.execute()

        formatted = []
        for item in response.data:
            category_data = item.get("categories")
            item["category"] = category_data.get("name") if category_data else "Uncategorized"
            formatted.append(item)
        return formatted

    @staticmethod
    def get_categories():
        db = get_db()
        return db.table('categories').select("*").execute().data

    @staticmethod
    def get_users(limit: int = 100, offset: int = 0):
        db = get_db()
        return db.table('users').select("*").range(offset, offset + limit - 1).execute().data

    @staticmethod
    def get_materials():
        db = get_db()
        return db.table('raw_materials_inventory').select("*").execute().data

    @staticmethod
    def get_reservations(limit: int = 50, offset: int = 0):
        db = get_db()
        return db.table('reservations').select("*").range(offset, offset + limit - 1).execute().data

    @staticmethod
    def get_settings():
        db = get_db()
        response = db.table('restaurant_settings').select("*").limit(1).execute()
        return response.data[0] if response.data else {}

    # ── Product mutations ─────────────────────────────────────────────────────

    @staticmethod
    def create_product(product_data: dict, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('products').insert(product_data).execute()
        if response.data:
            new_id = response.data[0].get('id') or response.data[0].get('product_id')
            AuditLogger.log_action("CREATE", "product", new_id, user_id, product_data)
        return response.data

    @staticmethod
    def update_product(product_id: str, product_data: dict, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('products').update(product_data).eq('id', product_id).execute()
        if not response.data:
            response = db.table('products').update(product_data).eq('product_id', product_id).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "product", product_id, user_id, product_data)
        return response.data

    @staticmethod
    def delete_product(product_id: str, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('products').delete().eq('id', product_id).execute()
        if not response.data:
            response = db.table('products').delete().eq('product_id', product_id).execute()
        if response.data:
            AuditLogger.log_action("DELETE", "product", product_id, user_id)
        return response.data

    # ── Category mutations ────────────────────────────────────────────────────

    @staticmethod
    def create_category(category_data: dict, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('categories').insert(category_data).execute()
        if response.data:
            AuditLogger.log_action("CREATE", "category", response.data[0].get('id'), user_id, category_data)
        return response.data

    @staticmethod
    def update_category(category_id: str, category_data: dict, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('categories').update(category_data).eq('id', category_id).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "category", category_id, user_id, category_data)
        return response.data

    @staticmethod
    def delete_category(category_id: str, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('categories').delete().eq('id', category_id).execute()
        if response.data:
            AuditLogger.log_action("DELETE", "category", category_id, user_id)
        return response.data

    # ── Reservation mutations ─────────────────────────────────────────────────

    @staticmethod
    def update_reservation_status(reservation_id: str, status: str, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('reservations').update({"status": status}).eq('id', reservation_id).execute()
        if response.data:
            AuditLogger.log_action("UPDATE_STATUS", "reservation", reservation_id, user_id, {"status": status})
        return response.data

    # ── Settings mutations ────────────────────────────────────────────────────

    @staticmethod
    def update_settings(settings_data: dict, user_id: Optional[str] = None):
        db = get_db()
        response = db.table('restaurant_settings').update(settings_data).eq('id', 1).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "settings", "1", user_id, settings_data)
        return response.data

    # ── Loyalty ───────────────────────────────────────────────────────────────

    @staticmethod
    def get_loyalty_status(user_id: str):
        db = get_db()
        stamps_res = db.table('loyalty_stamps').select("*").eq('user_id', user_id).eq('is_spent', False).execute()
        rewards_res = db.table('loyalty_rewards').select("*").eq('user_id', user_id).order('created_at', desc=True).execute()
        return {
            "unspent_count": len(stamps_res.data),
            "stamps": stamps_res.data,
            "rewards": rewards_res.data,
        }

    @staticmethod
    def claim_reward(user_id: str, reward_item: str):
        db = get_db()
        stamps_res = db.table('loyalty_stamps').select("id").eq('user_id', user_id).eq('is_spent', False).limit(9).execute()
        if len(stamps_res.data) < 9:
            raise ValueError("Insufficient stamps (need 9)")

        coupon_code = str(uuid.uuid4())[:8].upper()

        reward_res = db.table('loyalty_rewards').insert({
            "user_id": user_id,
            "coupon_code": coupon_code,
            "reward_item": reward_item,
            "status": "active",
        }).execute()

        if not reward_res.data:
            raise Exception("Failed to create reward")

        reward_id = reward_res.data[0]['id']
        stamp_ids = [s['id'] for s in stamps_res.data]

        db.table('loyalty_stamps').update({
            "is_spent": True,
            "reward_id": reward_id,
        }).in_('id', stamp_ids).execute()

        return reward_res.data[0]
