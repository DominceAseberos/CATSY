from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db

class OrderRepository(IRepository):
    def get_all(self, limit: int = 50, offset: int = 0) -> List[Any]:
        db = get_db()
        return db.table('orders').select("*, order_items(*)").range(offset, offset + limit - 1).order('created_at', desc=True).execute().data

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        response = db.table('orders').select("*, order_items(*)").eq('id', id).execute()
        return response.data[0] if response.data else None

    def create(self, dict_data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('orders').insert(dict_data).execute()
        return response.data

    def update(self, id: str, dict_data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('orders').update(dict_data).eq('id', id).execute()
        return response.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        # Avoid hard deleting orders, but implemented for interface completion
        db = get_db()
        response = db.table('orders').delete().eq('id', id).execute()
        return response.data

    def add_order_items(self, items_data: List[dict]):
        db = get_db()
        response = db.table('order_items').insert(items_data).execute()
        return response.data
