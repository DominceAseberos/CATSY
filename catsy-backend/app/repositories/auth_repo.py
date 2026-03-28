"""
auth_repo.py — fixed version.

Changes:
  1. AuthRepository now only touches Supabase Auth API (sign_in, sign_up).
  2. Customer table persistence (get_user_by_id, create_customer) moved to
     CustomerRepository where it belongs — those methods operate on the
     'customers' table, not the Auth API.
  3. get_user_profile (user_profiles table) moved to UserRepository.

Migration note:
  AuthService imports AuthRepository for Auth API calls.
  AuthService imports CustomerRepository for customer row operations.
  No behaviour change — just correct separation.
"""
from typing import Any
from app.database import get_db


class AuthRepository:
    """
    Data-access layer for Supabase Auth API only.
    Does NOT touch any database tables directly.
    """

    def sign_in_with_password(self, email: str, password: str) -> Any:
        db = get_db()
        return db.auth.sign_in_with_password({"email": email, "password": password})

    def sign_up(self, email: str, password: str, user_data: dict) -> Any:
        db = get_db()
        return db.auth.sign_up({
            "email": email,
            "password": password,
            "options": {"data": user_data},
        })

