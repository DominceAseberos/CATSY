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

    def deduct_stock(self, product_id: int, quantity: int):
        """Deduct stock from materials linked to this product.
        Uses a raw RPC call or a direct materials table decrement.
        Non-fatal: callers should catch exceptions.
        """
        db = get_db()
        # Find linked material(s) for this product via product_materials join table
        links = db.table('product_materials').select("material_id, quantity_used").eq('product_id', product_id).execute()
        for link in (links.data or []):
            material_id = link.get('material_id')
            qty_used = float(link.get('quantity_used', 1)) * quantity
            # Fetch current stock
            mat = db.table('materials').select('material_stock').eq('material_id', material_id).execute()
            if mat.data:
                current = float(mat.data[0].get('material_stock', 0))
                new_stock = max(0, current - qty_used)
                db.table('materials').update({'material_stock': new_stock}).eq('material_id', material_id).execute()

    def restore_stock(self, product_id: int, quantity: int):
        """Restore stock to materials linked to this product (on void or refund)."""
        db = get_db()
        links = db.table('product_materials').select("material_id, quantity_used").eq('product_id', product_id).execute()
        for link in (links.data or []):
            material_id = link.get('material_id')
            qty_used = float(link.get('quantity_used', 1)) * quantity
            mat = db.table('materials').select('material_stock').eq('material_id', material_id).execute()
            if mat.data:
                current = float(mat.data[0].get('material_stock', 0))
                db.table('materials').update({'material_stock': current + qty_used}).eq('material_id', material_id).execute()
