"""Customer-specific API routes — authenticated customer portal endpoints.

Tasks implemented here:
  Task 6 (Phase 2): GET /api/staff/members?search= — Staff member search
  Task 8 (Phase 2): GET /api/customer/orders       — Customer purchase history
"""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import Optional
from app.dependencies import get_customer_repository
from app.repositories.customer_repo import CustomerRepository
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)

# ── Customer Order History (FR C8) ────────────────────────────────────────────

customer_router = APIRouter(prefix="/api/customer", tags=["Customer"])


@customer_router.get("/orders")
@limiter.limit("60/minute")
def get_customer_orders(
    request: Request,
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
    repo: CustomerRepository = Depends(get_customer_repository)
):
    """Return purchase history for the authenticated customer (FR C8).
    Filtered server-side to the authenticated user's orders only.
    """
    try:
        return repo.get_customer_orders(str(user.id), limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Staff Member Search (FR S?) ───────────────────────────────────────────────

staff_router = APIRouter(prefix="/api/staff", tags=["Staff"])


@staff_router.get("/members")
@limiter.limit("60/minute")
def search_members(
    request: Request,
    search: Optional[str] = Query(None, description="Search by name or email"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
    repo: CustomerRepository = Depends(get_customer_repository)
):
    """Search customers by name or email — Staff use for loyalty stamp crediting (Phase 2).
    Requires staff JWT. Returns id, name, email, stamp_count, qr_id.
    """
    try:
        return repo.search_members(search=search, limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))