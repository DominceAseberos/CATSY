from datetime import datetime
from typing import Optional, Dict, Any
from ..database import supabase
import logging

logger = logging.getLogger(__name__)

class AuditLogger:
    @staticmethod
    def log_action(
        action: str,
        entity_type: str,
        user_id: Optional[str] = None,
        entity_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None
    ):
        """
        Record a security-sensitive action into the audit_logs table.
        """
        try:
            payload = {
                "action": action,
                "entity_type": entity_type,
                "user_id": user_id,
                "entity_id": str(entity_id) if entity_id else None,
                "details": details or {},
                "ip_address": ip_address,
                "created_at": datetime.utcnow().isoformat()
            }
            
            # Using Supabase client directly for bypass/system logging
            supabase.table("audit_logs").insert(payload).execute()
            
        except Exception as e:
            # Fallback to standard logging if DB logging fails
            logger.error(f"Audit Logging Failed: {str(e)}")
            logger.info(f"AUDIT: Action={action}, Entity={entity_type}, ID={entity_id}, User={user_id}")
