from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db

class UserRepository(IRepository):
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        db = get_db()
        return db.table('users').select("*").range(offset, offset + limit - 1).execute().data

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        response = db.table('users').select("*").eq('id', id).execute()
        return response.data[0] if response.data else None

    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('users').insert(data).execute()
        return response.data

    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('users').update(data).eq('id', id).execute()
        return response.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('users').delete().eq('id', id).execute()
        return response.data
