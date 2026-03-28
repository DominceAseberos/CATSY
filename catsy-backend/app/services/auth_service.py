"""
AuthService — encapsulates all authentication business logic.
Keeps route handlers thin (SRP).
Uses AuthRepository for data access (DIP).
"""
from typing import Optional
from app.repositories.auth_repo import AuthRepository


class AuthService:
    """Service layer for authentication operations.
    
    Uses dependency injection to receive AuthRepository,
    following the Dependency Inversion Principle.
    """
    
    def __init__(self, auth_repo: Optional[AuthRepository] = None):
        self.repo = auth_repo or AuthRepository()

    def _admin_login_impl(self, email: str, password: str) -> dict:
        """Instance method implementation for admin login."""
        response = self.repo.sign_in_with_password(email, password)
        
        user_dict = response.user.model_dump() if hasattr(response.user, 'model_dump') else response.user.__dict__
        meta = user_dict.get("user_metadata", {})
        app_meta = user_dict.get("app_metadata", {})
        
        role = meta.get("role") or app_meta.get("role")
        
        if not role:
            user_row = self.repo.get_user_by_id(response.user.id)
            if user_row:
                role = user_row.get("role")
                user_dict.update(user_row)
                
        if not role:
            role = "admin" if "admin" in email.lower() or "staff" in email.lower() else "admin"
        
        user_dict["role"] = role

        return {
            "user": user_dict,
            "session": response.session,
            "access_token": response.session.access_token,
            "refresh_token": response.session.refresh_token,
        }

    def _customer_login_impl(self, email: str, password: str) -> dict:
        """Instance method implementation for customer login."""
        response = self.repo.sign_in_with_password(email, password)
        
        user_dict = response.user.model_dump() if hasattr(response.user, 'model_dump') else response.user.__dict__
        meta = user_dict.get("user_metadata", {})
        app_meta = user_dict.get("app_metadata", {})
        
        role = meta.get("role") or app_meta.get("role")
        
        if not role:
            user_row = self.repo.get_user_by_id(response.user.id)
            if user_row:
                role = user_row.get("role")
                user_dict.update(user_row)
            else:
                # [LAZY-CREATE] If row is missing but user exists, try to recreate it from metadata
                print(f"DEBUG: Customers row missing for {response.user.id}, attempting lazy create.")
                self.repo.create_customer(
                    user_id=response.user.id,
                    email=email,
                    username=meta.get("username", email.split('@')[0]),
                    first_name=meta.get("first_name", ""),
                    last_name=meta.get("last_name", ""),
                    phone=meta.get("phone", ""),
                    role="customer"
                )
                role = "customer"
        
        # [SOLID: Robustness] Flatten user_metadata into top-level user_dict 
        # so frontend mapUserData can find fields if DB row is missing.
        for k, v in meta.items():
            if k not in user_dict or user_dict[k] is None:
                user_dict[k] = v
        for k, v in app_meta.items():
            if k not in user_dict or user_dict[k] is None:
                user_dict[k] = v
        
        # Add phone_number alias for extra safety with frontend bindings
        if "phone" in user_dict:
            user_dict["phone_number"] = user_dict["phone"]
                
        if not role:
            role = "admin" if "admin" in email.lower() or "staff" in email.lower() else "customer"
        
        user_dict["role"] = role

        return {
            "user": user_dict,
            "session": response.session,
            "access_token": response.session.access_token,
        }

    def _customer_signup_impl(self, email: str, password: str, username: str = "", 
                               first_name: str = "", last_name: str = "", phone: str = "") -> dict:
        """Instance method implementation for customer signup."""
        user_data = {
            "username": username,
            "first_name": first_name,
            "last_name": last_name,
            "phone": phone,
        }
        
        response = self.repo.sign_up(email, password, user_data)
        
        # Explicitly create the database row if the application has no trigger
        if response.user:
            self.repo.create_customer(
                user_id=response.user.id,
                email=email,
                username=username,
                first_name=first_name,
                last_name=last_name,
                phone=phone,
                role="customer"
            )

        return {"user": response.user, "status": "Confirm email if enabled"}

    # Static methods for backward compatibility with existing routers
    @staticmethod
    def admin_login(email: str, password: str) -> dict:
        service = AuthService()
        return service._admin_login_impl(email, password)

    @staticmethod
    def customer_login(email: str, password: str) -> dict:
        service = AuthService()
        return service._customer_login_impl(email, password)

    @staticmethod
    def customer_signup(email: str, password: str, username: str = "", 
                        first_name: str = "", last_name: str = "", phone: str = "") -> dict:
        service = AuthService()
        return service._customer_signup_impl(email, password, username, first_name, last_name, phone)