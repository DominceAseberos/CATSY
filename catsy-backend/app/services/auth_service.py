"""
Auth Service
============

What:
    Encapsulates all authentication and user profile business logic
    for both admin and customer login/signup flows.

How:
    Depends on AuthRepository for all data access. Resolves user roles
    from JWT metadata, app metadata, or the user_profiles DB table.
    Performs lazy customer record creation on first login.

When:
    Instantiated and injected by the auth router via get_auth_service().
    Called for every admin login, customer login, and customer signup request.

What it does:
    - Validates credentials and returns tokens via AuthRepository
    - Resolves user role from user_metadata, app_metadata, or DB row
    - Merges metadata fields into the user dict for frontend compatibility
    - Lazy-creates a customer record in the DB on first customer login
    - Inserts new customer records into the customers table on signup

What it does NOT do:
    - Does not validate JWTs directly (handled by app/auth.py)
    - Does not interact with Supabase Auth API directly (AuthRepository does)
    - Does not handle HTTP request/response — that is the router's responsibility
    - Does not enforce role-based access control on endpoints
"""
from typing import Optional
from app.repositories.auth_repo import AuthRepository


class AuthService:
    """Business logic layer for authentication flows.

    Depends on AuthRepository for all data access. Keeps routing
    logic and DB access cleanly separated.
    """

    def __init__(self, auth_repo: Optional[AuthRepository] = None):
        # Explicit default: safe for production.
        # Test callers should always pass a mock instead of relying on this default.
        self.repo = auth_repo if auth_repo is not None else AuthRepository()

    def _resolve_role(self, user_id: str, meta: dict, app_meta: dict) -> str:
        """Resolve the user's role from metadata or DB row.

        Resolution order: user_metadata → app_metadata → DB user_profiles row.
        Falls back to 'customer' — never derives role from email string.

        Args:
            user_id: The Supabase auth user UUID.
            meta: user_metadata dict from the JWT.
            app_meta: app_metadata dict from the JWT.

        Returns:
            Role string (e.g. 'admin', 'staff', 'customer').
        """
        role = meta.get("role") or app_meta.get("role")
        if role:
            return role

        user_row = self.repo.get_user_by_id(user_id)
        if user_row:
            return user_row.get("role", "customer")

        return "customer"

    @staticmethod
    def _flatten_metadata(user_dict: dict, meta: dict, app_meta: dict) -> dict:
        """Merge metadata fields into user_dict without overwriting existing keys.

        Args:
            user_dict: The base user dict to merge into.
            meta: user_metadata dict.
            app_meta: app_metadata dict.

        Returns:
            The merged user_dict.
        """
        for source in (meta, app_meta):
            for k, v in source.items():
                if k not in user_dict or user_dict[k] is None:
                    user_dict[k] = v
        return user_dict

    def admin_login(self, email: str, password: str) -> dict:
        """Authenticate an admin user and return tokens with resolved role.

        Args:
            email: Admin email address.
            password: Admin password.

        Returns:
            Dict containing user, session, access_token, and refresh_token.

        Raises:
            Exception: Propagated from Supabase Auth on invalid credentials.
        """
        response = self.repo.sign_in_with_password(email, password)
        user_dict = (
            response.user.model_dump()
            if hasattr(response.user, "model_dump")
            else response.user.__dict__
        )
        meta = user_dict.get("user_metadata", {})
        app_meta = user_dict.get("app_metadata", {})

        role = self._resolve_role(response.user.id, meta, app_meta)
        user_dict["role"] = role

        return {
            "user": user_dict,
            "session": response.session,
            "access_token": response.session.access_token,
            "refresh_token": response.session.refresh_token,
        }

    def customer_login(self, email: str, password: str) -> dict:
        """Authenticate a customer and lazy-create their profile if missing.

        If no user_profiles row exists for this user, one is created
        automatically using metadata from the JWT.

        Args:
            email: Customer email address.
            password: Customer password.

        Returns:
            Dict containing user, session, and access_token.

        Raises:
            Exception: Propagated from Supabase Auth on invalid credentials.
        """
        response = self.repo.sign_in_with_password(email, password)
        user_dict = (
            response.user.model_dump()
            if hasattr(response.user, "model_dump")
            else response.user.__dict__
        )
        meta = user_dict.get("user_metadata", {})
        app_meta = user_dict.get("app_metadata", {})

        user_row = self.repo.get_user_by_id(response.user.id)
        if user_row:
            user_dict.update(user_row)
        else:
            self.repo.create_customer(
                user_id=response.user.id,
                email=email,
                username=meta.get("username", email.split("@")[0]),
                first_name=meta.get("first_name", ""),
                last_name=meta.get("last_name", ""),
                phone=meta.get("phone", ""),
                role="customer",
            )

        self._flatten_metadata(user_dict, meta, app_meta)

        if "phone" in user_dict:
            user_dict["phone_number"] = user_dict["phone"]

        role = self._resolve_role(response.user.id, meta, app_meta)
        user_dict["role"] = role

        return {
            "user": user_dict,
            "session": response.session,
            "access_token": response.session.access_token,
        }

    def customer_signup(
        self,
        email: str,
        password: str,
        username: str = "",
        first_name: str = "",
        last_name: str = "",
        phone: str = "",
    ) -> dict:
        """Register a new customer via Supabase Auth and create their DB record.

        Args:
            email: New customer email address.
            password: New customer password.
            username: Optional display username.
            first_name: Customer first name.
            last_name: Customer last name.
            phone: Customer phone number.

        Returns:
            Dict containing user object and a status message.

        Raises:
            Exception: Propagated from Supabase Auth on signup failure.
        """
        user_data = {
            "username": username,
            "first_name": first_name,
            "last_name": last_name,
            "phone": phone,
        }
        response = self.repo.sign_up(email, password, user_data)

        if response.user:
            self.repo.create_customer(
                user_id=response.user.id,
                email=email,
                username=username,
                first_name=first_name,
                last_name=last_name,
                phone=phone,
                role="customer",
            )

        return {"user": response.user, "status": "Confirm email if enabled"}