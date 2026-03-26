"""Reports and Analytics Router (Phase 3)."""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from datetime import datetime, date, timedelta
from typing import Optional
from app.database import supabase
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/admin/reports", tags=["Admin Reports"])

@router.get("/sales")
@limiter.limit("30/minute")
def get_sales_report(
    request: Request,
    period: Optional[str] = Query(None, description="'today' or custom range"),
    from_date: Optional[str] = Query(None),
    to_date: Optional[str] = Query(None),
    user=Depends(get_current_user)
):
    """Aggregate sales total and breakdown by payment method."""
    try:
        # A simple query builder for order status = paid
        query = supabase.table("orders").select("*").eq("payment_status", "paid")
        
        # In a real app we'd filter using start/end timestamps. Supabase filtering:
        # We fetch all paid orders and do Python aggregation if dates aren't strictly passed, 
        # or we filter by date ranges. For simplicity and given standard Postgres PostgREST:
        if period == "today":
            today = date.today().isoformat()
            query = query.gte("created_at", f"{today}T00:00:00").lte("created_at", f"{today}T23:59:59")
        elif from_date and to_date:
            query = query.gte("created_at", f"{from_date}T00:00:00").lte("created_at", f"{to_date}T23:59:59")
            
        res = query.execute()
        orders = res.data or []
        
        total = sum(o.get("total_amount", 0) for o in orders)
        cash = sum(o.get("total_amount", 0) for o in orders if o.get("payment_method") == "Cash")
        gcash = sum(o.get("total_amount", 0) for o in orders if o.get("payment_method") == "GCash")
        maya = sum(o.get("total_amount", 0) for o in orders if o.get("payment_method") == "Maya")
        
        # Group by day for charts/tables
        daily = {}
        for o in orders:
            day = o["created_at"][:10]
            if day not in daily:
                daily[day] = {"date": day, "total": 0, "cash": 0, "gcash": 0, "maya": 0, "order_count": 0}
            daily[day]["total"] += o.get("total_amount", 0)
            daily[day]["order_count"] += 1
            pm = o.get("payment_method")
            if pm == "Cash": daily[day]["cash"] += o.get("total_amount", 0)
            elif pm == "GCash": daily[day]["gcash"] += o.get("total_amount", 0)
            elif pm == "Maya": daily[day]["maya"] += o.get("total_amount", 0)

        # Sort daily descending
        daily_list = sorted(daily.values(), key=lambda x: x["date"], reverse=True)
        
        return {
            "data": {
                "total": total,
                "cash": cash,
                "gcash": gcash,
                "maya": maya,
                "daily": daily_list,
                "total_orders": len(orders)
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/feedback")
@limiter.limit("30/minute")
def get_feedback_report(
    request: Request,
    limit: int = Query(50),
    user=Depends(get_current_user)
):
    try:
        res = supabase.table("user_feedback").select("*, auth.users(email)").order("created_at", desc=True).limit(limit).execute()
        return {"data": res.data or []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
