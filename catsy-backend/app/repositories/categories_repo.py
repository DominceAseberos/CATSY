from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db
from app.utils.audit_logger import AuditLogger

class CategoryRepository(IRepository):
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        db = get_db()
        return db.table('categories').select("*").range(offset, offset + limit - 1).execute().data

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        response = db.table('categories').select("*").eq('id', id).execute()
        return response.data[0] if response.data else None

    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('categories').insert(data).execute()
        if response.data:
            AuditLogger.log_action("CREATE", "category", response.data[0].get('id'), user_id, data)
        return response.data

    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('categories').update(data).eq('id', id).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "category", id, user_id, data)
        return response.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('categories').delete().eq('id', id).execute()
        if response.data:
            AuditLogger.log_action("DELETE", "category", id, user_id)
        return response.data
