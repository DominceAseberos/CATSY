"""
Settings Repository
==================

What:
    Provides a repository interface for the restaurant_settings singleton table.

How:
    Implements a SingletonRepository base class, exposing only get and update methods, and integrates with audit logging.

When:
    Used by endpoints or services that need to read or update global restaurant settings.

What it does:
    - Retrieves the current settings row
    - Updates settings with audit tracking
    - Ensures only valid operations for singleton tables
"""
from abc import ABC, abstractmethod
from typing import Any, Optional
from app.database import get_db
from app.utils.audit_logger import AuditLogger


# ── New narrow base — use this instead of IRepository for singleton tables ───

class SingletonRepository(ABC):
    """
    Abstract base for tables that have exactly one row (e.g. restaurant_settings).
    Exposes only get() and update() — create/delete don't apply.
    """

    @abstractmethod
    def get(self) -> Any:
        pass

    @abstractmethod
    def update(self, data: dict, user_id: Optional[str] = None) -> Any:
        pass


# ── Implementation ────────────────────────────────────────────────────────────
"""
SettingsRepository implementation:
Implements SingletonRepository for restaurant_settings table.
"""

SETTINGS_ROW_ID = 1  # business rule lives here, not buried in a query
SETTINGS_ROW_ID = 1  # Business rule: singleton row ID is defined here, not buried in a query


class SettingsRepository(SingletonRepository):

    def get(self) -> dict:
        db = get_db()
        response = db.table("restaurant_settings").select("*").limit(1).execute()
        return response.data[0] if response.data else {}

    # Keep the old name so existing callers (routers, services) don't break
        # Legacy: Keep the old name so existing callers (routers, services) don't break
    def get_all(self) -> dict:
        return self.get()

    def get_by_id(self, id: str) -> dict:
        return self.get()

    def update(self, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = (
            db.table("restaurant_settings")
            .update(data)
            .eq("id", SETTINGS_ROW_ID)
            .execute()
        )
        if response.data:
            AuditLogger.log_action("UPDATE", "settings", str(SETTINGS_ROW_ID), user_id, data)
        return response.data
