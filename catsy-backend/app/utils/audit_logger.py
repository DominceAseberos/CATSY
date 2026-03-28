"""
AuditLogger — fixed version.

Changes:
  1. Parameter order corrected: entity_id now comes before user_id to match
     every call site in the codebase (categories_repo, products_repo, etc.)
  2. Uses get_db() factory instead of importing supabase directly — testable.
  3. Removed manual datetime.utcnow() — let the DB column default handle it.
"""
from typing import Optional, Dict, Any
from app.database import get_db
import logging

logger = logging.getLogger(__name__)


class AuditLogger:

    @staticmethod
    def log_action(
        action: str,
        entity_type: str,
        entity_id: Optional[str],        # <-- was user_id (swapped)
        user_id: Optional[str] = None,   # <-- was entity_id (swapped)
        details: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None,
    ):
        """
        Record a security-sensitive action into the audit_logs table.

        Args:
            action:      Verb — "CREATE", "UPDATE", "DELETE"
            entity_type: Domain noun — "product", "order", "reservation", …
            entity_id:   PK of the affected row (now correctly third param)
            user_id:     Auth user who performed the action (now correctly fourth)
            details:     Arbitrary payload dict stored as JSONB
            ip_address:  Optional caller IP
        """
        try:
            db = get_db()
            payload = {
                "action": action,
                "entity_type": entity_type,
                "entity_id": str(entity_id) if entity_id else None,
                "user_id": user_id,
                "details": details or {},
                "ip_address": ip_address,
                # created_at intentionally omitted — DB column default handles it
            }
            db.table("audit_logs").insert(payload).execute()

        except Exception as e:
            logger.error(f"Audit logging failed: {e}")
            logger.info(
                f"AUDIT: action={action} entity_type={entity_type} "
                f"entity_id={entity_id} user_id={user_id}"
            )
