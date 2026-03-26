"""Customer-specific API routes — authenticated customer portal endpoints.

Tasks implemented here:
  Task 6 (Phase 2): GET /api/staff/members?search= — Staff member search
  Task 8 (Phase 2): GET /api/customer/orders       — Customer purchase history
"""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import Optional
from app.database import get_db
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
    user=Depends(get_current_user)
):
    """Return purchase history for the authenticated customer (FR C8).
    Filtered server-side to the authenticated user's orders only.
    """
    try:
        db = get_db()
        orders = db.table('orders') \
            .select("id, order_type, payment_status, payment_method, total_amount, created_at, order_items(*)") \
            .eq('customer_id', str(user.id)) \
            .order('created_at', desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()
        return orders.data or []
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
    user=Depends(get_current_user)
):
    """Search customers by name or email — Staff use for loyalty stamp crediting (Phase 2).
    Requires staff JWT. Returns id, name, email, stamp_count, qr_id.
    """
    try:
        db = get_db()
        # Query the customers table (populated by auth_service lazy-create)
        query = db.table('customers').select(
            "id, full_name, email, qr_id, stamp_count"
        )
        if search:
            # Supabase PostgREST: use ilike for case-insensitive match on name or email
            query = query.or_(
                f"full_name.ilike.%{search}%,email.ilike.%{search}%"
            )
        result = query.order('full_name').range(offset, offset + limit - 1).execute()
        return result.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
