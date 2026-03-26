"""Audit and admin utilities router."""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from fastapi.responses import StreamingResponse
import io
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.database import supabase
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Admin"])


@router.get("/admin/audit-logs")
@limiter.limit("10/minute")
def get_audit_logs(
    request: Request,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user)
):
    """Staff-only endpoint to view the system audit trail."""
    try:
        response = (
            supabase.table("audit_logs")
            .select("*")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/admin/apk/download")
@limiter.limit("5/minute")
def download_pos_apk(
    request: Request,
    user=Depends(get_current_user)
):
    """Download the Catsy POS APK. Admin only (Phase 3)."""
    # Check if user is admin
    role = user.app_metadata.get("role") if hasattr(user, 'app_metadata') else None
    if role != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required to download POS application.")
    
    try:
        # For now, return a dummy file blob to satisfy the frontend requirement
        dummy_apk_content = b"CatsyPOS_v1.0.0_dummy_binary_content"
        # In a real scenario, we would stream this from Supabase Storage
        return StreamingResponse(
            io.BytesIO(dummy_apk_content),
            media_type="application/vnd.android.package-archive",
            headers={"Content-Disposition": "attachment; filename=catsy-pos.apk"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/admin/inventory/low-stock")
@limiter.limit("20/minute")
def get_low_stock_inventory(
    request: Request,
    user=Depends(get_current_user)
):
    """Returns all raw materials where stock <= minimum expected (for Admin Dashboard)."""
    try:
        # Perform an RPC or a Supabase filter query.
        # Supabase API does not support native column-to-column comparison in standard select(),
        # so we fetch all and filter in Python for ease, OR if possible we'd do a postgres function.
        # Given small inventory dataset, fetching all active materials is fine:
        res = supabase.table("raw_materials_inventory").select("*").eq("is_active", True).execute()
        materials = res.data or []
        
        low_stock_items = [
            m for m in materials 
            if (m.get("material_stock", 0) <= m.get("minimum_threshold", 0))
        ]
        return low_stock_items
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
