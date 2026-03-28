"""
Auth Repository
===============

What:
    Provides a data-access layer for all Supabase Auth API operations
    and customer record management required during authentication flows.

How:
    Wraps Supabase Auth API calls (sign in, sign up, get user) and
    directly accesses the customers and user_profiles tables for
    lazy record creation and role resolution during login.

When:
    Used exclusively by AuthService for all authentication flows —
    admin login, customer login, and customer signup. Not used by
    any other service or router directly.

What it does:
    - Signs in a user with email and password via Supabase Auth
    - Signs up a new user via Supabase Auth with metadata
    - Fetches a user profile row by user ID for role resolution
    - Creates a new customer record in the customers table on first login

What it does NOT do:
    - Does not validate JWTs (that is handled by app/auth.py)
    - Does not contain business logic or role enforcement
    - Does not interact with any table other than customers and user_profiles
"""
from typing import Any, Optional
from app.database import get_db


class AuthRepository:
    """Data-access layer for Supabase Auth API and customer record management.

    Keeps all authentication-related DB interactions isolated from
    service logic, consistent with the Repository pattern.
    """

    def sign_in_with_password(self, email: str, password: str) -> Any:
        """Authenticate a user with email and password via Supabase Auth.

        Args:
            email: The user's email address.
            password: The user's password.

        Returns:
            Supabase auth response containing user and session objects.
        """
        db = get_db()
        return db.auth.sign_in_with_password({"email": email, "password": password})

    def sign_up(self, email: str, password: str, user_data: dict) -> Any:
        """Register a new user via Supabase Auth with optional metadata.

        Args:
            email: The new user's email address.
            password: The new user's password.
            user_data: Dict of metadata (username, first_name, last_name, phone).

        Returns:
            Supabase auth response containing the new user object.
        """
        db = get_db()
        return db.auth.sign_up({
            "email": email,
            "password": password,
            "options": {"data": user_data},
        })

    def get_user_by_id(self, user_id: str) -> Optional[dict]:
        """Fetch a user profile row by user ID for role resolution.

        Checks the user_profiles table — used during login to resolve
        the user's role when it is not present in JWT metadata.

        Args:
            user_id: The Supabase auth user UUID.

        Returns:
            User profile dict if found, None otherwise.
        """
        db = get_db()
        res = db.table("user_profiles").select("*").eq("id", user_id).execute()
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
        """Create a new customer record in the customers table on first login.

        Called lazily during customer_login when no existing profile is found.

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