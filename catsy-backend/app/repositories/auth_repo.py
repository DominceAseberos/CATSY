"""
Auth Repository.

Responsibility: ALL persistence operations for authentication-related data.
  - User authentication with Supabase Auth
  - Customer profile creation and lookup
  - User metadata management

Open/Closed: New auth-related operations can be added without modifying
the service layer or routers.
"""
from typing import Optional, Dict, Any
from app.database import supabase


class AuthRepository:
    """Data-access layer for authentication operations.

    Encapsulates all Supabase Auth interactions, keeping the service layer
    thin and testable.
    """

    def sign_in_with_password(self, email: str, password: str) -> Any:
        """Authenticate user with email and password.
        
        Args:
            email: User's email address.
            password: User's password.
            
        Returns:
            Supabase auth response with user and session.
        """
        return supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })

    def sign_up(self, email: str, password: str, user_data: dict) -> Any:
        """Register a new user with Supabase Auth.
        
        Args:
            email: User's email address.
            password: User's password.
            user_data: Metadata to store with the user (username, name, etc.)
            
        Returns:
            Supabase auth response with user.
        """
        return supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": user_data
            }
        })

    def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Fetch a customer record by user ID.
        
        Args:
            user_id: The Supabase auth user ID.
            
        Returns:
            Customer record dict or None if not found.
        """
        try:
            response = supabase.table("customers").select("*").eq("id", user_id).execute()
            return response.data[0] if response.data else None
        except Exception:
            return None

    def create_customer(self, user_id: str, email: str, username: str = "",
                        first_name: str = "", last_name: str = "", 
                        phone: str = "", role: str = "customer") -> bool:
        """Create a customer record in the database.
        
        Args:
            user_id: The Supabase auth user ID.
            email: User's email address.
            username: Optional username.
            first_name: Optional first name.
            last_name: Optional last name.
            phone: Optional phone number.
            role: User role (default: 'customer').
            
        Returns:
            True if successful, False otherwise.
        """
        try:
            supabase.table("customers").insert({
                "id": user_id,
                "email": email,
                "username": username,
                "first_name": first_name,
                "last_name": last_name,
                "phone": phone,
                "role": role
            }).execute()
            return True
        except Exception:
            return False

    def get_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Fetch a user profile from user_profiles table.
        
        Args:
            user_id: The user's ID.
            
        Returns:
            User profile dict or None if not found.
        """
        try:
            response = supabase.table("user_profiles").select("*").eq("id", user_id).execute()
            return response.data[0] if response.data else None
        except Exception:
            return None