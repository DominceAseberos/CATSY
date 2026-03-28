"""
AuthRepository
==============

Purpose:
    Provides a data-access layer for Supabase Auth API operations (sign in, sign up).
    Does not interact with application database tables directly.

Usage:
    - Use sign_in_with_password() for authentication
    - Use sign_up() for user registration

Responsibilities:
    - Encapsulates all Supabase Auth API calls
    - Keeps authentication logic separate from customer/user table operations
    - Used by AuthService for all authentication flows
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

