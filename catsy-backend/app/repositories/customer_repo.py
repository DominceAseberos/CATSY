"""
Customer Repository
==================

What:
    Handles all persistence operations for customer-specific data, including
    customer record creation, order history retrieval, and member searches.

How:
    Uses a repository pattern to abstract all Supabase database access,
    keeping data logic completely separate from API routing and services.

When:
    Invoked by routers or services whenever customer data is needed —
    such as fetching order history, searching members for loyalty crediting,
    or creating a new customer record after signup.

What it does:
    - Creates new customer records in the customers table
    - Fetches a customer record by user ID
    - Retrieves paginated order history for a specific customer
    - Searches members by name or email for staff loyalty features
    - Provides a single, consistent point for all customer data access

What it does NOT do:
    - Does not handle authentication or JWT validation
    - Does not contain business logic or HTTP request/response handling
    - Does not interact with loyalty_stamps or loyalty_rewards tables directly
"""
from typing import List, Optional
from app.database import get_db


class CustomerRepository:
    """Data-access layer for customer-specific operations.

    Keeps all Supabase interactions isolated from HTTP routing logic,
    consistent with the Repository pattern used across the codebase.
    """

    def get_by_user_id(self, user_id: str) -> Optional[dict]:
        """Fetch a customer record by their auth user ID.

        Args:
            user_id: The Supabase auth user UUID.

        Returns:
            Customer dict if found, None otherwise.
        """
        db = get_db()
        res = db.table("customers").select("*").eq("id", user_id).execute()
        return res.data[0] if res.data else None

    def create_customer(
        self,
        user_id: str,
        email: str,
        username: str = "",
        first_name: str = "",
        last_name: str = "",
        phone: str = "",
        role: str = "customer"
    ) -> bool:
        """Insert a new customer record into the customers table.

        Args:
            user_id: The Supabase auth user UUID (used as primary key).
            email: Customer email address.
            username: Optional display username.
            first_name: Customer first name.
            last_name: Customer last name.
            phone: Customer phone number.
            role: User role, defaults to 'customer'.

        Returns:
            True on success, False if the insert fails.
        """
        try:
            get_db().table("customers").insert({
                "id": user_id,
                "email": email,
                "username": username,
                "first_name": first_name,
                "last_name": last_name,
                "phone": phone,
                "role": role,
            }).execute()
            return True
        except Exception:
            return False

    def get_customer_orders(
        self,
        customer_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[dict]:
        """Return paginated purchase history for a specific customer.

        Args:
            customer_id: The authenticated user's ID.
            limit: Max number of orders to return.
            offset: Pagination offset.

        Returns:
            List of order dicts with nested order_items included.
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
            search: Optional search string matched against first name,
                    last name, and email via case-insensitive ILIKE.
            limit: Max number of results to return.
            offset: Pagination offset.

        Returns:
            List of user profile dicts with id, name, email, qr_code, excess_stamps.
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