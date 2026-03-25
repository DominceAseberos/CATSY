"""Categories router."""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import List
from app.dependencies import get_category_repository
from app.repositories.categories_repo import CategoryRepository
from app.schemas import CategoryResponse, CategoryCreate, CategoryUpdate
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Categories"])


@router.get("/categories", response_model=List[CategoryResponse])
@limiter.limit("60/minute")
def get_categories(request: Request, repo: CategoryRepository = Depends(get_category_repository)):
    try:
        return repo.get_all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/admin/categories")
@limiter.limit("20/minute")
def admin_get_categories(request: Request, user=Depends(get_current_user), repo: CategoryRepository = Depends(get_category_repository)):
    return repo.get_all()


@router.post("/admin/categories")
def create_category(request: Request, category: CategoryCreate, user=Depends(get_current_user), repo: CategoryRepository = Depends(get_category_repository)):
    return repo.create(category.dict(), user_id=str(user.id))


@router.put("/admin/categories/{category_id}")
def update_category(request: Request, category_id: str, category: CategoryUpdate, user=Depends(get_current_user), repo: CategoryRepository = Depends(get_category_repository)):
    return repo.update(category_id, category.dict(exclude_unset=True), user_id=str(user.id))


@router.delete("/admin/categories/{category_id}")
def delete_category(request: Request, category_id: str, user=Depends(get_current_user), repo: CategoryRepository = Depends(get_category_repository)):
    return repo.delete(category_id, user_id=str(user.id))
