"""
Materials Repository
===================

What:
    Manages inventory data for raw materials and product recipes.

How:
    Implements a repository class with methods for CRUD operations on the `raw_materials_inventory` table and related recipe management.

When:
    Used by admin endpoints for inventory management, recipe editing, and material usage checks.

What it does:
    - Retrieves, creates, updates, and deletes materials
    - Checks if materials are in use in recipes
    - Manages product recipes and ingredient lists
    - Integrates with audit logging for traceability
"""
from typing import List, Optional, Any
from app.repositories.base import IRepository
from app.database import get_db
from app.utils.audit_logger import AuditLogger

class MaterialsRepository(IRepository):

        def get_low_stock(self) -> List[Any]:
            """Return materials where stock is at or below reorder level.
            Uses a Supabase RPC or a Python-side filter on the full list.
            Pure DB-side: uses lte filter on material_stock against material_reorder_level.
            Because Supabase PostgREST can't compare two columns directly without RPC,
            we fetch all and filter in-memory — but this lives in the repo, not the router.
            """
            db = get_db()
            materials = db.table("raw_materials_inventory").select("*").execute().data or []
            return [
                m for m in materials
                if float(m.get("material_stock", 0)) <= float(m.get("material_reorder_level", 0))
            ]
    def get_all(self, limit: int = 100, offset: int = 0) -> List[Any]:
        db = get_db()
        response = db.table('raw_materials_inventory').select("*").range(offset, offset + limit - 1).execute()
        return response.data or []

    def get_by_id(self, id: str) -> Optional[Any]:
        db = get_db()
        response = db.table('raw_materials_inventory').select("*").eq('material_id', id).execute()
        return response.data[0] if response.data else None

    def create(self, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('raw_materials_inventory').insert(data).execute()
        if response.data:
            new_id = response.data[0].get('material_id')
            AuditLogger.log_action("CREATE", "material", new_id, user_id, data)
        return response.data

    def update(self, id: str, data: dict, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('raw_materials_inventory').update(data).eq('material_id', id).execute()
        if response.data:
            AuditLogger.log_action("UPDATE", "material", id, user_id, data)
        return response.data

    def delete(self, id: str, user_id: Optional[str] = None) -> Any:
        db = get_db()
        response = db.table('raw_materials_inventory').delete().eq('material_id', id).execute()
        if response.data:
            AuditLogger.log_action("DELETE", "material", id, user_id)
        return response.data

    def check_in_use(self, material_id: int) -> bool:
        """Check if a material is used in any product recipe."""
        db = get_db()
        response = db.table('product_recipe').select("recipe_id").eq('material_id', material_id).limit(1).execute()
        return len(response.data) > 0

    def get_recipe(self, product_id: int) -> List[Any]:
        """Fetch ingredients for a specific product."""
        db = get_db()
        response = db.table('product_recipe')\
            .select("*, raw_materials_inventory!product_recipe_material_id_fkey(material_name, material_unit)")\
            .eq('product_id', product_id)\
            .execute()
        
        formatted = []
        for item in response.data:
            mat_data = item.get("raw_materials_inventory")
            if mat_data:
                item["material_name"] = mat_data.get("material_name")
                item["material_unit"] = mat_data.get("material_unit")
            formatted.append(item)
        return formatted

    def upsert_recipe(self, product_id: int, ingredients: List[dict]):
        """Replace existing recipe for a product with new ingredients."""
        db = get_db()
        # Delete existing
        db.table('product_recipe').delete().eq('product_id', product_id).execute()
        # Insert new
        if ingredients:
            for ing in ingredients:
                ing['product_id'] = product_id
            db.table('product_recipe').insert(ingredients).execute()
