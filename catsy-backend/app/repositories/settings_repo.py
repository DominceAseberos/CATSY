"""
Settings Repository
==================

What:
    Provides the data-access layer for the restaurant_settings singleton
    table, which holds a single row of global restaurant configuration.

How:
    Implements the SingletonRepository abstract base class, exposing only
    get() and update() since create and delete do not apply to a singleton.
    Integrates with AuditLogger to track all settings changes.

When:
    Used by the settings router whenever global restaurant configuration
    needs to be read or updated — such as opening hours, store status,
    seat count, or currency settings.

What it does:
    - Retrieves the single restaurant_settings row
    - Updates settings fields with full audit trail logging
    - Exposes legacy aliases (get_all, get_by_id) for backward compatibility
      with existing router callers without breaking them

What it does NOT do:
    - Does not create or delete the settings row (singleton pattern)
    - Does not contain business logic or HTTP request/response handling
    - Does not merge default values — that responsibility belongs to config.py
      and is handled by the settings router before returning to the client
"""
from abc import ABC, abstractmethod
from typing import Any, Optional
from app.database import get_db
from app.utils.audit_logger import AuditLogger


# ── Abstract base for singleton tables ───────────────────────────────────────

class SingletonRepository(ABC):
    """Abstract base for tables that have exactly one row.

    Exposes only get() and update() — create and delete do not apply
    to singleton configuration tables like restaurant_settings.
    """

    @abstractmethod
    def get(self) -> Any:
        pass

    @abstractmethod
    def update(self, data: dict, user_id: Optional[str] = None) -> Any:
        pass


# ── Business rule constant ────────────────────────────────────────────────────

# The singleton row ID is defined here as a named constant so it is never
# buried in a query string and can be updated in one place if needed.
SETTINGS_ROW_ID = 1


# ── Implementation ────────────────────────────────────────────────────────────

class SettingsRepository(SingletonRepository):
    """Data-access layer for the restaurant_settings singleton table.

    Implements SingletonRepository. Legacy aliases get_all() and get_by_id()
    are kept for backward compatibility with existing router callers.
    """

    def get(self) -> dict:
        """Fetch the single restaurant_settings row.

        Returns:
            Settings dict if the row exists, empty dict otherwise.
        """
        db = get_db()
        response = db.table("restaurant_settings").select("*").limit(1).execute()
        return response.data[0] if response.data else {}

    def get_all(self) -> dict:
        """Legacy alias for get(). Kept for backward compatibility with routers."""
        return self.get()

    def get_by_id(self, id: str) -> dict:
        """Legacy alias for get(). Kept for backward compatibility with routers."""
        return self.get()

    def update(self, data: dict, user_id: Optional[str] = None) -> Any:
        """Update the singleton settings row and log the change to the audit log.

        Args:
            data: Dict of settings fields to update.
            user_id: ID of the staff member performing the update (for audit).

        Returns:
            Updated record data from Supabase.
        """
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