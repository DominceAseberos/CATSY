"""
User Repository
===============

What:
    Handles all database operations for user profiles stored in the
    user_profiles table, including CRUD and profile lookups.

How:
    Implements the IRepository base class to enforce a consistent CRUD
    interface, using Supabase queries abstracted away from routing logic.

When:
    Used by admin endpoints or services that need to manage or retrieve
    user profile data — such as listing all users, fetching a profile
    by ID or email, or deleting a user account.

What it does:
    - Retrieves all user profiles with pagination
    - Fetches a single profile by user ID or email
    - Fetches a full profile for an authenticated user
    - Creates, updates, and deletes user profile records
    - Centralizes all user_profiles table access for maintainability

What it does NOT do:
    - Does not interact with Supabase Auth directly (use AuthRepository)
    - Does not handle JWT validation or session management
    - Does not contain business logic or HTTP request/response handling
"""
from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db


class UserRepository(IRepository):
    """Data-access layer for the user_profiles table.

    Keeps all Supabase interactions isolated from HTTP routing logic,
    consistent with the Repository pattern used across the codebase.
    """

    def get_profile(self, user_id: str) -> Optional[dict]:
        """Fetch a full user profile for an authenticated user.

        Args:
            user_id: The Supabase auth user UUID.

        Returns:
            User profile dict if found, None otherwise.
        """
        db = get_db()
        res = db.table("user_profiles").select("*").eq("id", user_id).execute()
        return res.data[0] if res.data else None

    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        """Return all user profiles with pagination.

        Args:
            limit: Max number of records to return.
            offset: Pagination offset.

        Returns:
            List of user profile dicts.
        """
        db = get_db()
        return db.table('user_profiles').select("*").range(offset, offset + limit - 1).execute().data

    def get_by_id(self, id: str) -> Optional[Any]:
        """Fetch a single user profile by primary key.

        Args:
            id: The user UUID.

        Returns:
            User profile dict if found, None otherwise.
        """
        db = get_db()
        response = db.table('user_profiles').select("*").eq('id', id).execute()
        return response.data[0] if response.data else None

    def get_by_email(self, email: str) -> Optional[Any]:
        """Fetch a user profile by email address.

        Args:
            email: The user's email address.

        Returns:
            User profile dict if found, None otherwise.
        """
        db = get_db()
        response = db.table('user_profiles').select("*").eq('email', email).execute()
        return response.data[0] if response.data else None

    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        """Insert a new user profile record.

        Args:
            data: Dict of user profile fields to insert.
            user_id: Optional ID of the actor performing the action (for audit).

        Returns:
            Inserted record data from Supabase.
        """
        db = get_db()
        response = db.table('user_profiles').insert(data).execute()
        return response.data

    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        """Update an existing user profile by ID.

        Args:
            id: The user UUID to update.
            data: Dict of fields to update.
            user_id: Optional ID of the actor performing the action (for audit).

        Returns:
            Updated record data from Supabase.
        """
        db = get_db()
        response = db.table('user_profiles').update(data).eq('id', id).execute()
        return response.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        """Delete a user profile by ID.

        Args:
            id: The user UUID to delete.
            user_id: Optional ID of the actor performing the action (for audit).

        Returns:
            Deleted record data from Supabase.
        """
        db = get_db()
        response = db.table('user_profiles').delete().eq('id', id).execute()
        return response.data