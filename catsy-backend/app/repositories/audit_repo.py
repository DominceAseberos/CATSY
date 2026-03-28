"""
Audit Repository
================
What: Data-access layer for audit_logs table.
Why:  Moves DB query out of admin.py router, satisfying SRP.
"""
from typing import List
from app.database import get_db


class AuditRepository:
    def get_logs(self, limit: int = 100, offset: int = 0) -> List[dict]:
        """Return paginated audit log entries, newest first."""
        db = get_db()
        return (
            db.table("audit_logs")
            .select("*")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
            .data
        ) or []
