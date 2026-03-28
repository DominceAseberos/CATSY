    def get_by_user_id(self, user_id: str) -> Optional[dict]:
        db = get_db()
        res = db.table("customers").select("*").eq("id", user_id).execute()
        return res.data[0] if res.data else None

    def create_customer(
        self, user_id: str, email: str, username: str = "",
        first_name: str = "", last_name: str = "",
        phone: str = "", role: str = "customer"
    ) -> bool:
        try:
            get_db().table("customers").insert({
                "id": user_id, "email": email, "username": username,
                "first_name": first_name, "last_name": last_name,
                "phone": phone, "role": role,
            }).execute()
            return True
        except Exception:
            return False
"""
Customer Repository.

Responsibility: ALL persistence operations for customer-specific data.
  - Fetching customer orders
  - Searching members for loyalty stamp crediting

Open/Closed: New customer-related queries can be added as new methods
without modifying existing ones or the router.
"""
from typing import List, Optional
from app.database import get_db


class CustomerRepository:
    """Data-access layer for customer-specific operations.

    Keeps all Supabase interactions isolated from HTTP routing logic,
    consistent with the Repository pattern.
    """

    def get_customer_orders(
        self,
        customer_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[dict]:
        """Return purchase history for a specific customer.
        
        Args:
            customer_id: The authenticated user's ID.
            limit: Max number of orders to return.
            offset: Pagination offset.
            
        Returns:
            List of order dicts with order_items included.
        """
        db = get_db()
        orders = db.table('orders') \
            .select("id, order_type, payment_status, payment_method, total_amount, created_at, order_items(*)") \
            .eq('customer_id', customer_id) \
            .order('created_at', desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()
        return orders.data or []

    def search_members(
        self,
        search: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[dict]:
        """Search customers by name or email for loyalty stamp crediting.
        
        Args:
            search: Optional search string for name/email filtering.
            limit: Max number of results.
            offset: Pagination offset.
            
        Returns:
            List of user profile dicts with id, name, email, qr_code, stamps.
        """
        db = get_db()
        query = db.table('user_profiles').select(
            "id, first_name, last_name, email, qr_code, excess_stamps"
        )
        if search:
            query = query.or_(
                f"first_name.ilike.%{search}%,last_name.ilike.%{search}%,email.ilike.%{search}%"
            )
        result = query.order('last_name').range(offset, offset + limit - 1).execute()
        return result.data or []