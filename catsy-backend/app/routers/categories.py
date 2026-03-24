"""Categories router."""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import List
from app.repositories.supabase_repo import SupabaseRepository
from app.schemas import CategoryResponse, CategoryCreate, CategoryUpdate
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Categories"])


@router.get("/categories", response_model=List[CategoryResponse])
@limiter.limit("60/minute")
def get_categories(request: Request):
    try:
        return SupabaseRepository.get_categories()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/admin/categories")
@limiter.limit("20/minute")
def admin_get_categories(request: Request, user=Depends(get_current_user)):
    return SupabaseRepository.get_categories()


@router.post("/admin/categories")
def create_category(request: Request, category: CategoryCreate, user=Depends(get_current_user)):
    return SupabaseRepository.create_category(category.dict(), user_id=str(user.id))


@router.put("/admin/categories/{category_id}")
def update_category(request: Request, category_id: str, category: CategoryUpdate, user=Depends(get_current_user)):
    return SupabaseRepository.update_category(category_id, category.dict(exclude_unset=True), user_id=str(user.id))


@router.delete("/admin/categories/{category_id}")
def delete_category(request: Request, category_id: str, user=Depends(get_current_user)):
    return SupabaseRepository.delete_category(category_id, user_id=str(user.id))
