"""
CMS Repository (Phase 3).

Responsibility: ALL persistence operations for the `cms_content` table.
  - Reading all entries (admin) and active entries (public)
  - Creating, updating, and deleting CMS items

Open/Closed: To add filtering by `type` or `start_date/end_date`, add a
new method here — routers and the public API surface remain unchanged.
"""
from typing import List, Optional, Dict, Any
from app.database import supabase


class CmsRepository:
    """Data-access layer for the `cms_content` table.

    Keeps all Supabase interactions isolated from HTTP routing logic,
    consistent with the Repository pattern used in orders_repo, rewards_repo, etc.
    """

    # ── Read ────────────────────────────────────────────────────────────────

    def get_all(self) -> List[dict]:
        """Return all CMS entries (admin view), newest first."""
        res = supabase.table("cms_content")\
            .select("*")\
            .order("created_at", desc=True)\
            .execute()
        return res.data or []

    def get_active(self) -> List[dict]:
        """Return only active CMS entries for the public customer portal."""
        res = supabase.table("cms_content")\
            .select("*")\
            .eq("is_active", True)\
            .order("created_at", desc=True)\
            .execute()
        return res.data or []

    def get_by_id(self, item_id: str) -> Optional[dict]:
        """Fetch a single CMS entry by primary key."""
        res = supabase.table("cms_content")\
            .select("*")\
            .eq("id", item_id)\
            .execute()
        return res.data[0] if res.data else None

    # ── Write ───────────────────────────────────────────────────────────────

    def create(self, data: Dict[str, Any]) -> dict:
        """Insert a new CMS entry. `data` is the validated Pydantic dict."""
        res = supabase.table("cms_content").insert(data).execute()
        return res.data[0]

    def update(self, item_id: str, data: Dict[str, Any]) -> Optional[dict]:
        """Partial update — only set fields that are provided (non-None)."""
        res = supabase.table("cms_content")\
            .update(data)\
            .eq("id", item_id)\
            .execute()
        return res.data[0] if res.data else None

    def delete(self, item_id: str) -> bool:
        """Hard-delete a CMS entry. Returns True on success."""
        supabase.table("cms_content").delete().eq("id", item_id).execute()
        return True
