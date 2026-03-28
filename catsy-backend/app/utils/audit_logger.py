"""
AuditLogger
===========

Purpose:
    Provides a static interface for logging security-sensitive actions to the audit_logs table.
    Used throughout the codebase to record CREATE, UPDATE, DELETE, and other critical events.

Usage:
    AuditLogger.log_action(action, entity_type, entity_id, user_id, details, ip_address)

Responsibilities:
    - Ensures all critical actions are recorded for auditing and compliance
    - Handles DB interaction and error logging for audit events
    - Keeps audit logic isolated from business logic
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
        entity_id: Optional[str],
        user_id: Optional[str] = None,
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
                # created_at intentionally omitted: handled by DB column default
            }
            db.table("audit_logs").insert(payload).execute()

        except Exception as e:
            logger.error(f"Audit logging failed: {e}")
            logger.info(
                f"AUDIT: action={action} entity_type={entity_type} "
                f"entity_id={entity_id} user_id={user_id}"
            )
