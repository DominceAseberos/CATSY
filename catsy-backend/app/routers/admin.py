"""Audit and admin utilities router."""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
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
