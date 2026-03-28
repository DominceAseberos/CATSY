"""
Admin Routers
=============

What:
    Provides all admin-only API endpoints grouped into four separate routers:
    audit logs, low-stock inventory, user management, and APK download.

How:
    Each logical group is its own APIRouter instance so they can be mounted
    individually in main.py. Auth is enforced on every endpoint via
    get_current_user(). User management delegates to UserRepository via
    dependency injection. Audit logs and inventory currently query Supabase
    directly pending dedicated repository methods (see TODOs below).

When:
    Mounted at application startup via main.py. Called by admin panel
    clients for operational tasks — reviewing audit trails, checking stock
    levels, managing user accounts, and downloading the POS APK.

What it does:
    - GET  /admin/audit-logs              — Returns paginated audit log entries
    - GET  /admin/inventory/low-stock     — Returns materials at or below reorder level
    - GET  /admin/users                   — Lists all user profiles
    - POST /admin/users                   — Creates a new user profile
    - PATCH /admin/users/{id}/password    — Updates a user password (stub — see TODO)
    - DELETE /admin/users/{id}            — Deletes a user profile
    - GET  /admin/apk/download            — Streams the POS APK file (admin role only)

What it does NOT do:
    - Does not contain business logic — routing and auth enforcement only
    - Does not expose any endpoints without authentication
    - Does not perform soft deletes — user deletion is hard delete via UserRepository

TODO:
    - audit_router: Move DB query into a dedicated AuditRepository.get_logs() method
    - inventory_router: Move low-stock filter into MaterialsRepository.get_low_stock()
    - apk_router: Replace dummy bytes with real Supabase Storage download
    - users_router PATCH password: Implement Supabase Admin API call
"""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from pydantic import BaseModel
from fastapi.responses import StreamingResponse
import io
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.auth import get_current_user
from app.dependencies import get_user_repository, get_audit_repository, get_materials_repository
from app.repositories.users_repo import UserRepository
from app.repositories.audit_repo import AuditRepository
from app.repositories.materials_repo import MaterialsRepository

limiter = Limiter(key_func=get_remote_address)


# ── 1. Audit logs ─────────────────────────────────────────────────────────────

audit_router = APIRouter(tags=["Audit"])


@audit_router.get("/admin/audit-logs")
@limiter.limit("10/minute")
def get_audit_logs(
    request: Request,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
    repo: AuditRepository = Depends(get_audit_repository),
):
    """Admin: Return paginated audit log entries, newest first."""
    try:
        return repo.get_logs(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 2. Inventory / low-stock ──────────────────────────────────────────────────

inventory_router = APIRouter(tags=["Inventory"])


@inventory_router.get("/admin/inventory/low-stock")
@limiter.limit("20/minute")
def get_low_stock_inventory(
    request: Request,
    user=Depends(get_current_user),
    repo: MaterialsRepository = Depends(get_materials_repository),
):
    """Admin: Return materials where current stock is at or below reorder level."""
    try:
        return repo.get_low_stock()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 3. User management ────────────────────────────────────────────────────────

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
    """Admin: Return a paginated list of all user profiles."""
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
    """Admin: Create a new user profile record."""
    try:
        return repo.create(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



class PasswordChangeRequest(BaseModel):
    new_password: str

@users_router.patch("/admin/users/{user_id}/password")
@limiter.limit("5/minute")
def change_user_password(
    request: Request,
    user_id: str,
    data: PasswordChangeRequest,
    user=Depends(get_current_user),
):
    """Admin: Update a user password via the Supabase Auth Admin API."""
    try:
        db = get_db()
        db.auth.admin.update_user_by_id(
            user_id,
            {"password": data.new_password}
        )
        return {"success": True, "message": "Password updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@users_router.delete("/admin/users/{user_id}")
@limiter.limit("10/minute")
def delete_user(
    request: Request,
    user_id: str,
    user=Depends(get_current_user),
    repo: UserRepository = Depends(get_user_repository),
):
    """Admin: Hard-delete a user profile by ID."""
    try:
        return repo.delete(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 4. APK download ───────────────────────────────────────────────────────────

apk_router = APIRouter(tags=["APK"])


@apk_router.get("/admin/apk/download")
@limiter.limit("5/minute")
def download_pos_apk(
    request: Request,
    user=Depends(get_current_user),
):
    """Admin: Stream the Catsy POS APK from Supabase Storage."""
    role = None
    if hasattr(user, "user_metadata"):
        role = (user.user_metadata or {}).get("role")
    if not role and hasattr(user, "app_metadata"):
        role = (user.app_metadata or {}).get("role")
    if role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")

    # ── APK not yet available ─────────────────────────────────────────────
    raise HTTPException(
        status_code=503,
        detail="APK not yet available. Check back later."
    )

    # ── Uncomment when APK is uploaded to Supabase Storage ────────────────
    # try:
    #     db = get_db()
    #     file_bytes: bytes = db.storage.from_("apk-releases").download("catsy-pos.apk")
    #     return StreamingResponse(
    #         io.BytesIO(file_bytes),
    #         media_type="application/vnd.android.package-archive",
    #         headers={"Content-Disposition": "attachment; filename=catsy-pos.apk"},
    #     )
    # except Exception as e:
    #     raise HTTPException(status_code=500, detail=f"APK download failed: {str(e)}")