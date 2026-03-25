from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db
from app.utils.audit_logger import AuditLogger

class ProductRepository(IRepository):
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        db = get_db()
        query = db.table('products').select(
            "*, categories!products_category_id_fkey(name)"
        ).range(offset, offset + limit - 1)
        response = query.execute()

        formatted = []
        for item in response.data:
            category_data = item.get("categories")
            item["category"] = category_data.get("name") if category_data else "Uncategorized"
            formatted.append(item)
        return formatted

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        response = db.table('products').select("*").eq('id', id).execute()
        return response.data[0] if response.data else None

    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('products').insert(data).execute()
        if response.data:
            new_id = response.data[0].get('id') or response.data[0].get('product_id')
            AuditLogger.log_action("CREATE", "product", new_id, user_id, data)
        return response.data

    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('products').update(data).eq('id', id).execute()
        if not response.data:
            response = db.table('products').update(data).eq('product_id', id).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "product", id, user_id, data)
        return response.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('products').delete().eq('id', id).execute()
        if not response.data:
            response = db.table('products').delete().eq('product_id', id).execute()
        if response.data:
            AuditLogger.log_action("DELETE", "product", id, user_id)
        return response.data
