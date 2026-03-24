from typing import List, Optional
from app.database import supabase
from app.utils.audit_logger import AuditLogger

class SupabaseRepository:
    """
    Abstractions for Supabase interactions.
    Encapsulates SRP (Single Responsibility) for data access.
    """
    
    @staticmethod
    def get_products(limit: int = 100, offset: int = 0):
        # Fetch products joined with categories
        query = supabase.table('products').select(
            "*, categories!products_category_id_fkey(name)"
        ).range(offset, offset + limit - 1)
        
        response = query.execute()
        
        # Transform data to include resolved category name
        formatted = []
        for item in response.data:
            category_data = item.get("categories")
            item["category"] = category_data.get("name") if category_data else "Uncategorized"
            formatted.append(item)
            
        return formatted

    @staticmethod
    def get_categories():
        response = supabase.table('categories').select("*").execute()
        return response.data

    @staticmethod
    def get_users(limit: int = 100, offset: int = 0):
        response = supabase.table('users').select("*").range(offset, offset + limit - 1).execute()
        return response.data

    @staticmethod
    def get_materials():
        response = supabase.table('raw_materials_inventory').select("*").execute()
        return response.data

    @staticmethod
    def get_reservations(limit: int = 50, offset: int = 0):
        response = supabase.table('reservations').select("*").range(offset, offset + limit - 1).execute()
        return response.data

    # --- Mutations with Audit Logging ---

    @staticmethod
    def create_product(product_data: dict, user_id: Optional[str] = None):
        response = supabase.table('products').insert(product_data).execute()
        if response.data:
            new_id = response.data[0].get('id') or response.data[0].get('product_id')
            AuditLogger.log_action(
                action="CREATE",
                entity_type="product",
                entity_id=new_id,
                user_id=user_id,
                details=product_data
            )
        return response.data

    @staticmethod
    def update_product(product_id: str, product_data: dict, user_id: Optional[str] = None):
        response = supabase.table('products').update(product_data).eq('id', product_id).execute()
        if not response.data:
            # Try with product_id just in case
            response = supabase.table('products').update(product_data).eq('product_id', product_id).execute()
            
        if response.data:
            AuditLogger.log_action(
                action="UPDATE",
                entity_type="product",
                entity_id=product_id,
                user_id=user_id,
                details=product_data
            )
        return response.data

    @staticmethod
    def delete_product(product_id: str, user_id: Optional[str] = None):
        response = supabase.table('products').delete().eq('id', product_id).execute()
        if not response.data:
             response = supabase.table('products').delete().eq('product_id', product_id).execute()
             
        if response.data:
            AuditLogger.log_action(
                action="DELETE",
                entity_type="product",
                entity_id=product_id,
                user_id=user_id
            )
        return response.data

    @staticmethod
    def create_category(category_data: dict, user_id: Optional[str] = None):
        response = supabase.table('categories').insert(category_data).execute()
        if response.data:
            AuditLogger.log_action(
                action="CREATE",
                entity_type="category",
                entity_id=response.data[0].get('id'),
                user_id=user_id,
                details=category_data
            )
        return response.data

    @staticmethod
    def update_category(category_id: str, category_data: dict, user_id: Optional[str] = None):
        response = supabase.table('categories').update(category_data).eq('id', category_id).execute()
        if response.data:
            AuditLogger.log_action(
                action="UPDATE",
                entity_type="category",
                entity_id=category_id,
                user_id=user_id,
                details=category_data
            )
        return response.data

    @staticmethod
    def delete_category(category_id: str, user_id: Optional[str] = None):
        response = supabase.table('categories').delete().eq('id', category_id).execute()
        if response.data:
            AuditLogger.log_action(
                action="DELETE",
                entity_type="category",
                entity_id=category_id,
                user_id=user_id
            )
        return response.data

    @staticmethod
    def update_reservation_status(reservation_id: str, status: str, user_id: Optional[str] = None):
        response = supabase.table('reservations').update({"status": status}).eq('id', reservation_id).execute()
        if response.data:
            AuditLogger.log_action(
                action="UPDATE_STATUS",
                entity_type="reservation",
                entity_id=reservation_id,
                user_id=user_id,
                details={"status": status}
            )
        return response.data

    @staticmethod
    def get_settings():
        response = supabase.table('restaurant_settings').select("*").limit(1).execute()
        if response.data:
            return response.data[0]
        return {}

    @staticmethod
    def update_settings(settings_data: dict, user_id: Optional[str] = None):
        response = supabase.table('restaurant_settings').update(settings_data).eq('id', 1).execute()
        if response.data:
            AuditLogger.log_action(
                action="UPDATE",
                entity_type="settings",
                entity_id="1",
                user_id=user_id,
                details=settings_data
            )
        return response.data

    # --- Loyalty Logic ---

    @staticmethod
    def get_loyalty_status(user_id: str):
        # 1. Fetch unspent stamps
        stamps_res = supabase.table('loyalty_stamps').select("*").eq('user_id', user_id).eq('is_spent', False).execute()
        
        # 2. Fetch rewards
        rewards_res = supabase.table('loyalty_rewards').select("*").eq('user_id', user_id).order('created_at', desc=True).execute()
        
        return {
            "unspent_count": len(stamps_res.data),
            "stamps": stamps_res.data,
            "rewards": rewards_res.data
        }

    @staticmethod
    def claim_reward(user_id: str, reward_item: str):
        # 1. Double check stamps
        stamps_res = supabase.table('loyalty_stamps').select("id").eq('user_id', user_id).eq('is_spent', False).limit(9).execute()
        if len(stamps_res.data) < 9:
            raise ValueError("Insufficient stamps (need 9)")
            
        import uuid
        coupon_code = str(uuid.uuid4())[:8].upper()
        
        # 2. Create Reward
        reward_res = supabase.table('loyalty_rewards').insert({
            "user_id": user_id,
            "coupon_code": coupon_code,
            "reward_item": reward_item,
            "status": "active"
        }).execute()
        
        if not reward_res.data:
            raise Exception("Failed to create reward")
            
        reward_id = reward_res.data[0]['id']
        stamp_ids = [s['id'] for s in stamps_res.data]
        
        # 3. Mark stamps as spent and link to reward
        supabase.table('loyalty_stamps').update({
            "is_spent": True,
            "reward_id": reward_id
        }).in_('id', stamp_ids).execute()
        
        return reward_res.data[0]
