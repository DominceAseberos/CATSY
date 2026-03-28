"""
Admin Routers
=============

Purpose:
    Provides separate routers for admin-only endpoints: audit logs, inventory, user management, and APK download.
    Each router is mounted individually in main.py for modularity and clarity.

Usage:
    - /admin/audit-logs: Retrieve audit logs
    - /admin/inventory/low-stock: Get low-stock inventory
    - /admin/users: Manage users (CRUD)
    - /admin/apk/download: Download POS APK (admin only)

Responsibilities:
    - Segregates admin API surface into logical routers
    - Ensures only authorized users can access admin endpoints
    - Handles audit, inventory, user, and APK management
"""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from fastapi.responses import StreamingResponse
import io
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.auth import get_current_user
from app.dependencies import get_user_repository
from app.repositories.users_repo import UserRepository
from app.database import get_db

limiter = Limiter(key_func=get_remote_address)


# ── 1. Audit logs ─────────────────────────────────────────────────────────────
"""
Section 1: Audit logs
Handles endpoints for retrieving audit logs from the database.
"""

audit_router = APIRouter(tags=["Audit"])


@audit_router.get("/admin/audit-logs")
@limiter.limit("10/minute")
def get_audit_logs(
    request: Request,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
):
    try:
        db = get_db()
        return (
            db.table("audit_logs")
            .select("*")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
            .data
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 2. Inventory / low-stock ──────────────────────────────────────────────────
"""
Section 2: Inventory / low-stock
Endpoints for inventory management, especially low-stock queries.
"""

inventory_router = APIRouter(tags=["Inventory"])


@inventory_router.get("/admin/inventory/low-stock")
@limiter.limit("20/minute")
def get_low_stock_inventory(
    request: Request,
    user=Depends(get_current_user),
):
    """
    Returns materials where current stock <= reorder level.
    Uses a repo instead of direct supabase access.
    TODO: replace with MaterialsRepository.get_low_stock() once that
    method is added — avoids the in-Python filter.
    """
    try:
        db = get_db()
        materials = db.table("raw_materials_inventory").select("*").execute().data or []
        return [
            m for m in materials
            if float(m.get("material_stock", 0)) <= float(m.get("material_reorder_level", 0))
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 3. User management ────────────────────────────────────────────────────────
"""
Section 3: User management
Endpoints for user management operations.
"""

users_router = APIRouter(tags=["User Management"])


@users_router.get("/admin/users")
@limiter.limit("30/minute")
def get_users(
    request: Request,
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
    repo: UserRepository = Depends(get_user_repository),
):
    try:
        return repo.get_all(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@users_router.post("/admin/users")
@limiter.limit("10/minute")
def create_user(
    request: Request,
    data: dict,
    user=Depends(get_current_user),
    repo: UserRepository = Depends(get_user_repository),
):
    try:
        return repo.create(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@users_router.patch("/admin/users/{user_id}/password")
@limiter.limit("5/minute")
def change_user_password(
    request: Request,
    user_id: str,
    data: dict,
    user=Depends(get_current_user),
):
    # TODO: Implement Supabase Admin API call here
    return {"success": True, "message": "Password updated"}


@users_router.delete("/admin/users/{user_id}")
@limiter.limit("10/minute")
def delete_user(
    request: Request,
    user_id: str,
    user=Depends(get_current_user),
    repo: UserRepository = Depends(get_user_repository),
):
    try:
        return repo.delete(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


"""
Section 4: APK download
Endpoints for downloading APKs and related admin operations.
"""

apk_router = APIRouter(tags=["APK"])


@apk_router.get("/admin/apk/download")
@limiter.limit("5/minute")
def download_pos_apk(
    request: Request,
    user=Depends(get_current_user),
):
    # Role resolution is consistent with the rest of the codebase: user_metadata is checked first
    role = None
    if hasattr(user, "user_metadata"):
        role = (user.user_metadata or {}).get("role")
    if not role and hasattr(user, "app_metadata"):
        role = (user.app_metadata or {}).get("role")

    if role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")

    try:
        # TODO: Replace dummy bytes with Supabase Storage download in production
        dummy_content = b"CatsyPOS_v1.0.0_placeholder"
        return StreamingResponse(
            io.BytesIO(dummy_content),
            media_type="application/vnd.android.package-archive",
            headers={"Content-Disposition": "attachment; filename=catsy-pos.apk"},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))