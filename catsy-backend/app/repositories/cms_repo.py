"""
CMS Repository
==============

What:
    Manages all persistence operations for the `cms_content` table, including reading, creating, updating, and deleting CMS items.

How:
    Implements a repository pattern to isolate Supabase database interactions from HTTP routing logic. Provides methods for both admin and public content access.

When:
    Used whenever CMS content needs to be managed or retrieved, such as for admin dashboards or public customer portals.

What it does:
    - Retrieves all or only active CMS entries
    - Fetches entries by ID
    - Creates, updates, and deletes CMS items
    - Centralizes all CMS data access logic for maintainability
"""
from typing import List, Optional, Dict, Any
from app.database import get_db


class CmsRepository:
    """Data-access layer for the `cms_content` table.

    Keeps all Supabase interactions isolated from HTTP routing logic,
    consistent with the Repository pattern used in orders_repo, rewards_repo, etc.
    """

    """
    Read methods:
    Methods for retrieving CMS entries from the database.
    """

    def get_all(self) -> List[dict]:
        """Return all CMS entries (admin view), newest first."""
        db = get_db()
        res = db.table("cms_content")\
            .select("*")\
            .order("created_at", desc=True)\
            .execute()
        return res.data or []

    def get_active(self) -> List[dict]:
        """Return only active CMS entries for the public customer portal."""
        db = get_db()
        res = db.table("cms_content")\
            .select("*")\
            .eq("is_active", True)\
            .order("created_at", desc=True)\
            .execute()
        return res.data or []

    def get_by_id(self, item_id: str) -> Optional[dict]:
        """Fetch a single CMS entry by primary key."""
        db = get_db()
        res = db.table("cms_content")\
            .select("*")\
            .eq("id", item_id)\
            .execute()
        return res.data[0] if res.data else None

    """
    Write methods:
    Methods for creating, updating, and deleting CMS entries.
    """

    def create(self, data: Dict[str, Any]) -> dict:
        """Insert a new CMS entry. `data` is the validated Pydantic dict."""
        db = get_db()
        res = db.table("cms_content").insert(data).execute()
        return res.data[0]

    def update(self, item_id: str, data: Dict[str, Any]) -> Optional[dict]:
        """Partial update — only set fields that are provided (non-None)."""
        db = get_db()
        res = db.table("cms_content")\
            .update(data)\
            .eq("id", item_id)\
            .execute()
        return res.data[0] if res.data else None

    def delete(self, item_id: str) -> bool:
        """Hard-delete a CMS entry. Returns True on success."""
        db = get_db()
        db.table("cms_content").delete().eq("id", item_id).execute()
        return True