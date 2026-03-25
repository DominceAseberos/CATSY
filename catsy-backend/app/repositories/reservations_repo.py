from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db
from app.utils.audit_logger import AuditLogger

class ReservationRepository(IRepository):
    def get_all(self, limit: int = 50, offset: int = 0) -> List[Any]:
        db = get_db()
        return db.table('reservations').select("*").range(offset, offset + limit - 1).execute().data

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        response = db.table('reservations').select("*").eq('id', id).execute()
        return response.data[0] if response.data else None

    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('reservations').insert(data).execute()
        if response.data:
            AuditLogger.log_action("CREATE", "reservation", user_id=user_id, entity_id=response.data[0].get('id'), details=data)
        return response.data[0] if response.data else None

    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('reservations').update(data).eq('id', id).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "reservation", user_id=user_id, entity_id=id, details=data)
        return response.data[0] if response.data else None

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('reservations').delete().eq('id', id).execute()
        if response.data:
            AuditLogger.log_action("DELETE", "reservation", id, user_id)
        return response.data
