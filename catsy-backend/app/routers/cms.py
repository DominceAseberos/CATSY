"""
CMS Router (Phase 3).

Responsibility: HTTP request/response handling for `/api/admin/cms` (admin)
and `/api/cms` (public customer portal).
  - Route declarations and rate limiting
  - Auth enforcement via `get_current_user` (admin routes only)
  - Translating request payloads to repository calls
  - Shaping repository results into HTTP responses

What this file does NOT do (Open/Closed):
  - No Supabase queries — those live in `cms_repo.py`
  - No Pydantic schema definitions — those live in `schemas.py`
  - Adding a new CMS feature (e.g. scheduling, image upload) means a new
    route here and a method in `cms_repo.py` — this file never locks you in.
"""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.auth import get_current_user
from app.schemas import CMSCreate, CMSUpdate
from app.repositories.cms_repo import CmsRepository

limiter = Limiter(key_func=get_remote_address)

admin_router = APIRouter(prefix="/api/admin/cms", tags=["Admin CMS"])
public_router = APIRouter(prefix="/api/cms", tags=["Public CMS"])


def get_repo() -> CmsRepository:
    """Dependency factory — returns the repository instance.

    Swappable in tests. Follows the Dependency Inversion Principle.
    """
    return CmsRepository()


# ── Admin Routes ──────────────────────────────────────────────────────────────

@admin_router.get("")
@limiter.limit("60/minute")
def get_cms_items(
    request: Request,
    user=Depends(get_current_user),
    repo: CmsRepository = Depends(get_repo),
):
    """Admin: List all CMS entries (active and inactive)."""
    try:
        return {"data": repo.get_all()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@admin_router.post("")
@limiter.limit("30/minute")
def create_cms_item(
    request: Request,
    data: CMSCreate,
    user=Depends(get_current_user),
    repo: CmsRepository = Depends(get_repo),
):
    """Admin: Create a new banner, announcement, or promo entry."""
    try:
        return {"data": repo.create(data.dict())}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@admin_router.put("/{item_id}")
@limiter.limit("30/minute")
def update_cms_item(
    request: Request,
    item_id: str,
    data: CMSUpdate,
    user=Depends(get_current_user),
    repo: CmsRepository = Depends(get_repo),
):
    """Admin: Partially update an existing CMS entry (only provided fields are changed)."""
    try:
        # Strip None values so the repo only updates what was passed
        update_payload = {k: v for k, v in data.dict().items() if v is not None}
        updated = repo.update(item_id, update_payload)
        if not updated:
            raise HTTPException(status_code=404, detail="Item not found.")
        return {"data": updated}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@admin_router.delete("/{item_id}")
@limiter.limit("20/minute")
def delete_cms_item(
    request: Request,
    item_id: str,
    user=Depends(get_current_user),
    repo: CmsRepository = Depends(get_repo),
):
    """Admin: Delete a CMS entry."""
    try:
        repo.delete(item_id)
        return {"data": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Public Routes ─────────────────────────────────────────────────────────────

@public_router.get("/active")
@limiter.limit("60/minute")
def get_public_cms(
    request: Request,
    repo: CmsRepository = Depends(get_repo),
):
    """Public: Return active CMS entries for the customer portal. No auth required."""
    try:
        return {"data": repo.get_active()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
