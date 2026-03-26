"""CMS Content Router (Phase 3)."""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from pydantic import BaseModel
from typing import Optional
from app.database import supabase
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)

admin_router = APIRouter(prefix="/api/admin/cms", tags=["Admin CMS"])
public_router = APIRouter(prefix="/api/cms", tags=["Public CMS"])

class CMSCreate(BaseModel):
    type: str # 'banner' | 'announcement' | 'promo'
    title: str
    body: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool = True

class CMSUpdate(BaseModel):
    title: Optional[str] = None
    body: Optional[str] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None

@admin_router.get("")
@limiter.limit("60/minute")
def get_cms_items(
    request: Request,
    user=Depends(get_current_user)
):
    try:
        res = supabase.table("cms_content").select("*").order("created_at", desc=True).execute()
        return {"data": res.data or []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@admin_router.post("")
@limiter.limit("30/minute")
def create_cms_item(
    request: Request,
    data: CMSCreate,
    user=Depends(get_current_user)
):
    try:
        res = supabase.table("cms_content").insert(data.dict()).execute()
        return {"data": res.data[0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@admin_router.put("/{item_id}")
@limiter.limit("30/minute")
def update_cms_item(
    request: Request,
    item_id: str,
    data: CMSUpdate,
    user=Depends(get_current_user)
):
    try:
        update_data = {k: v for k, v in data.dict().items() if v is not None}
        res = supabase.table("cms_content").update(update_data).eq("id", item_id).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Item not found")
        return {"data": res.data[0]}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@admin_router.delete("/{item_id}")
@limiter.limit("20/minute")
def delete_cms_item(
    request: Request,
    item_id: str,
    user=Depends(get_current_user)
):
    try:
        res = supabase.table("cms_content").delete().eq("id", item_id).execute()
        return {"data": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@public_router.get("/active")
@limiter.limit("60/minute")
def get_public_cms(request: Request):
    """Returns all active CMS items for the customer portal."""
    try:
        res = supabase.table("cms_content").select("*").eq("is_active", True).order("created_at", desc=True).execute()
        return {"data": res.data or []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
