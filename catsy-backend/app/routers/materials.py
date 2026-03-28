from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import List, Optional
from app.auth import get_current_user
from app.repositories.materials_repo import MaterialsRepository
from app.schemas import MaterialCreate, MaterialUpdate, RecipeUpsert

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/admin/materials", tags=["Inventory Management"])

def get_repo() -> MaterialsRepository:
    return MaterialsRepository()

@router.get("")
@limiter.limit("50/minute")
def get_materials(
    request: Request,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_repo)
):
    """Admin: Fetch all raw materials."""
    try:
        return repo.get_all(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("")
@limiter.limit("10/minute")
def create_material(
    request: Request,
    material: MaterialCreate,
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_repo)
):
    """Admin: Create a new raw material."""
    try:
        return repo.create(material.model_dump(), user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{material_id}")
@limiter.limit("20/minute")
def update_material(
    request: Request,
    material_id: str,
    material: MaterialUpdate,
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_repo)
):
    """Admin: Update an existing raw material."""
    try:
        data = material.model_dump(exclude_unset=True)
        return repo.update(material_id, data, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{material_id}")
@limiter.limit("10/minute")
def delete_material(
    request: Request,
    material_id: str,
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_repo)
):
    """Admin: Delete a raw material (if not in use)."""
    try:
        if repo.check_in_use(int(material_id)):
            raise HTTPException(status_code=400, detail="Cannot delete material as it is being used in one or more product recipes.")
        return repo.delete(material_id, user_id=str(user.id))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{material_id}/in-use")
@limiter.limit("20/minute")
def check_material_in_use(
    request: Request,
    material_id: str,
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_repo)
):
    """Admin: Check if a material is used in any product recipe."""
    try:
        in_use = repo.check_in_use(int(material_id))
        return {"in_use": in_use}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

"""
Product Recipes:
Endpoints for managing product recipes (admin only).
"""


"""
Product Recipes (separate router):
Moved to a separate router to avoid route conflicts with materials endpoints.
"""
recipe_router = APIRouter(prefix="/api/admin/recipes", tags=["Product Recipes"])

@recipe_router.get("/products/{product_id}/recipe")
@limiter.limit("30/minute")
def get_product_recipe(
    request: Request,
    product_id: int,
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_repo)
):
    """Admin: Get ingredients for a product."""
    try:
        return repo.get_recipe(product_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@recipe_router.put("/products/{product_id}/recipe")
@limiter.limit("10/minute")
def update_product_recipe(
    request: Request,
    product_id: int,
    recipe: RecipeUpsert,
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_repo)
):
    """Admin: Update/Replace ingredients for a product."""
    try:
        ingredients = [ing.model_dump() for ing in recipe.ingredients]
        repo.upsert_recipe(product_id, ingredients)
        return {"status": "success", "message": "Recipe updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
