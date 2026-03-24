"""Products router — CRUD for products managed by admin staff."""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import List
from app.repositories.supabase_repo import SupabaseRepository
from app.schemas import ProductResponse, ProductCreate, ProductUpdate
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Products"])


@router.get("/products", response_model=List[ProductResponse])
@limiter.limit("30/minute")
def get_products(request: Request, limit: int = Query(100, ge=1, le=1000), offset: int = Query(0, ge=0)):
    try:
        return SupabaseRepository.get_products(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/admin/products", response_model=List[ProductResponse])
@limiter.limit("20/minute")
def admin_get_products(request: Request, user=Depends(get_current_user)):
    return SupabaseRepository.get_products()


@router.post("/admin/products")
@limiter.limit("10/minute")
def create_product(request: Request, product: ProductCreate, user=Depends(get_current_user)):
    return SupabaseRepository.create_product(product.dict(), user_id=str(user.id))


@router.put("/admin/products/{product_id}")
@limiter.limit("20/minute")
def update_product(request: Request, product_id: str, product: ProductUpdate, user=Depends(get_current_user)):
    return SupabaseRepository.update_product(product_id, product.dict(exclude_unset=True), user_id=str(user.id))


@router.delete("/admin/products/{product_id}")
@limiter.limit("10/minute")
def delete_product(request: Request, product_id: str, user=Depends(get_current_user)):
    return SupabaseRepository.delete_product(product_id, user_id=str(user.id))
