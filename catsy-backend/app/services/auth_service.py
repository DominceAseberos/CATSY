"""
AuthService — fixed version.

Changes:
  1. Removed all three static wrapper methods (admin_login, customer_login,
     customer_signup). Routers now instantiate the service normally via Depends().
  2. Removed dangerous 'admin in email.lower()' role fallback — unknown role
     now correctly defaults to 'customer'.
  3. Extracted _resolve_role() and _flatten_metadata() as small private helpers
     so _customer_login_impl no longer does five things at once.
"""
from typing import Optional
from app.repositories.auth_repo import AuthRepository


class AuthService:

    def __init__(self, auth_repo: Optional[AuthRepository] = None):
        self.repo = auth_repo or AuthRepository()

    # ── Private helpers ───────────────────────────────────────────────────────

    def _resolve_role(self, user_id: str, meta: dict, app_meta: dict) -> str:
        """
        Role resolution order: user_metadata → app_metadata → DB row.
        Falls back to 'customer' — never guesses from email string.
        """
        role = meta.get("role") or app_meta.get("role")
        if role:
            return role

        user_row = self.repo.get_user_by_id(user_id)
        if user_row:
            return user_row.get("role", "customer")

        return "customer"  # safe default — never derive from email

    @staticmethod
    def _flatten_metadata(user_dict: dict, meta: dict, app_meta: dict) -> dict:
        """Merge metadata fields into user_dict without overwriting existing keys."""
        for source in (meta, app_meta):
            for k, v in source.items():
                if k not in user_dict or user_dict[k] is None:
                    user_dict[k] = v
        return user_dict

    # ── Public methods ────────────────────────────────────────────────────────

    def admin_login(self, email: str, password: str) -> dict:
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
        response = self.repo.sign_in_with_password(email, password)
        user_dict = (
            response.user.model_dump()
            if hasattr(response.user, "model_dump")
            else response.user.__dict__
        )
        meta = user_dict.get("user_metadata", {})
        app_meta = user_dict.get("app_metadata", {})

        # Lazy-create customer row if missing
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

        # Phone alias for frontend compatibility
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