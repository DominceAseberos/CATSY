"""
Reports Router (Phase 3).

Responsibility: HTTP request/response handling for `/api/admin/reports`.
  - Route declarations and rate limiting
  - Auth enforcement via `get_current_user`
  - Parsing date-range query parameters and passing to the repository
  - Shaping aggregated results into HTTP responses

What this file does NOT do (Open/Closed):
  - No Supabase queries — those live in `reports_repo.py`
  - No date arithmetic, grouping, or aggregation — all in `reports_repo.py`
  - Adding a new report type (e.g. product breakdown, staff report) means a
    new route here and a new method in the repo. Zero changes to existing routes.
"""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import Optional
from app.auth import get_current_user
from app.repositories.reports_repo import ReportsRepository

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/admin/reports", tags=["Admin Reports"])


def get_repo() -> ReportsRepository:
    """Dependency factory — returns the repository instance."""
    return ReportsRepository()


@router.get("/sales")
@limiter.limit("30/minute")
def get_sales_report(
    request: Request,
    period: Optional[str] = Query(None, description="'today' or leave blank for all-time"),
    from_date: Optional[str] = Query(None, description="ISO date YYYY-MM-DD (requires to_date)"),
    to_date: Optional[str] = Query(None, description="ISO date YYYY-MM-DD (requires from_date)"),
    user=Depends(get_current_user),
    repo: ReportsRepository = Depends(get_repo),
):
    """Admin: Aggregate sales total and payment-method breakdown for a given date range."""
    try:
        orders = repo.get_paid_orders(period=period, from_date=from_date, to_date=to_date)
        summary = repo.aggregate_sales(orders)
        return {"data": summary}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/feedback")
@limiter.limit("30/minute")
def get_feedback_report(
    request: Request,
    limit: int = Query(50, ge=1, le=500),
    user=Depends(get_current_user),
    repo: ReportsRepository = Depends(get_repo),
):
    """Admin: Return paginated customer feedback entries."""
    try:
        return {"data": repo.get_feedback(limit=limit)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
