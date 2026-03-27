from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db
from app.utils.audit_logger import AuditLogger

class SettingsRepository(IRepository):
    def get_all(self, limit: int = 1, offset: int = 0) -> List[Any]:
        db = get_db()
        response = db.table('restaurant_settings').select("*").limit(1).execute()
        return response.data[0] if response.data else {}

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        response = db.table('restaurant_settings').select("*").limit(1).execute()
        return response.data[0] if response.data else {}

    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        raise NotImplementedError("Settings are typically a singleton record")

    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('restaurant_settings').update(data).eq('id', 1).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "settings", "1", user_id, data)
        return response.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        raise NotImplementedError("Settings cannot be deleted")
