"""
AuthService — encapsulates all Supabase Auth interactions.
Keeps route handlers thin (SRP).
"""
from app.database import supabase


class AuthService:

    @staticmethod
    def admin_login(email: str, password: str) -> dict:
        response = supabase.auth.sign_in_with_password({"email": email, "password": password})
        return {
            "user": response.user,
            "session": response.session,
            "access_token": response.session.access_token,
            "refresh_token": response.session.refresh_token,
        }

    @staticmethod
    def customer_login(email: str, password: str) -> dict:
        response = supabase.auth.sign_in_with_password({"email": email, "password": password})
        return {
            "user": response.user,
            "session": response.session,
            "access_token": response.session.access_token,
        }

    @staticmethod
    def customer_signup(email: str, password: str, first_name: str = "", last_name: str = "", phone: str = "") -> dict:
        response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "first_name": first_name,
                    "last_name": last_name,
                    "phone": phone,
                }
            }
        })
        return {"user": response.user, "status": "Confirm email if enabled"}
