"""
Reports Repository
==================

What:
    Provides all data retrieval and aggregation logic for the admin
    reports domain, including sales summaries and customer feedback.

How:
    Uses direct Supabase queries for fetching raw order and feedback data,
    then performs pure in-memory aggregation (totals, grouping, sorting)
    without any additional I/O, making aggregation logic easily testable.

When:
    Called exclusively by the reports router when an admin requests
    a sales report or feedback listing. Not used by any other service.

What it does:
    - Fetches paid (completed) orders with optional date range filtering
    - Aggregates order totals by payment method (Cash, GCash, Maya)
    - Groups daily sales into a breakdown table sorted newest-first
    - Returns paginated customer feedback entries newest-first

What it does NOT do:
    - Does not handle HTTP requests or responses — that is the router's job
    - Does not perform date arithmetic outside of ISO string construction
    - Does not write or mutate any data — purely read and aggregate
    - Does not interact with any table other than orders and user_feedback
"""
from datetime import date
from typing import List, Optional

from app.repositories.base import IReadRepository
from app.database import get_db


class ReportsRepository(IReadRepository):
        def get_by_id(self, id: str):
            """Not implemented: ReportsRepository does not support get_by_id."""
            raise NotImplementedError("ReportsRepository does not support get_by_id.")
    """Data-access and aggregation layer for admin analytics.

    All business logic (grouping, summing, sorting) lives here.
    The router is responsible only for HTTP request parsing and response shaping.
    """

    # ── Sales ────────────────────────────────────────────────────────────────

    def get_paid_orders(
        self,
        period: Optional[str] = None,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
    ) -> List[dict]:
        """Fetch completed orders, optionally scoped to a date range.

        Filters on status='completed' to match the value set by OrderService
        when an order is successfully paid.

        Args:
            period: 'today' shorthand, or None to use explicit from/to dates.
            from_date: ISO date string (YYYY-MM-DD). Requires to_date.
            to_date: ISO date string (YYYY-MM-DD). Requires from_date.

        Returns:
            List of raw order dicts from Supabase.
        """
        db = get_db()
        query = db.table("orders").select("*").eq("status", "completed")
        if period == "today":
            today = date.today().isoformat()
            query = query.gte("created_at", f"{today}T00:00:00").lte("created_at", f"{today}T23:59:59")
        elif from_date and to_date:
            query = query.gte("created_at", f"{from_date}T00:00:00").lte("created_at", f"{to_date}T23:59:59")
        return query.execute().data or []

    def aggregate_sales(self, orders: List[dict]) -> dict:
        """Compute total, per-payment-method breakdown, daily rows, and order count.

        Pure function — depends only on the orders list, no I/O.
        This makes it trivially unit-testable in isolation.

        Args:
            orders: List of raw order dicts from get_paid_orders().

        Returns:
            Dict with total, cash, gcash, maya, daily breakdown list,
            and total_orders count.
        """
        total = sum(o.get("total_amount", 0) for o in orders)
        cash  = sum(o.get("total_amount", 0) for o in orders if o.get("payment_method") == "Cash")
        gcash = sum(o.get("total_amount", 0) for o in orders if o.get("payment_method") == "GCash")
        maya  = sum(o.get("total_amount", 0) for o in orders if o.get("payment_method") == "Maya")

        daily: dict = {}
        for o in orders:
            day = o["created_at"][:10]
            if day not in daily:
                daily[day] = {"date": day, "total": 0, "cash": 0, "gcash": 0, "maya": 0, "order_count": 0}
            daily[day]["total"]       += o.get("total_amount", 0)
            daily[day]["order_count"] += 1
            pm = o.get("payment_method")
            if pm == "Cash":    daily[day]["cash"]  += o.get("total_amount", 0)
            elif pm == "GCash": daily[day]["gcash"] += o.get("total_amount", 0)
            elif pm == "Maya":  daily[day]["maya"]  += o.get("total_amount", 0)

        return {
            "total": total,
            "cash": cash,
            "gcash": gcash,
            "maya": maya,
            "daily": sorted(daily.values(), key=lambda x: x["date"], reverse=True),
            "total_orders": len(orders),
        }

    # ── Feedback ─────────────────────────────────────────────────────────────

    def get_feedback(self, limit: int = 50) -> List[dict]:
        """Return paginated customer feedback entries, newest first.

        Args:
            limit: Maximum number of feedback entries to return.

        Returns:
            List of feedback dicts from the user_feedback table.
        """
        db = get_db()
        res = db.table("user_feedback")\
            .select("*")\
            .order("created_at", desc=True)\
            .limit(limit)\
            .execute()
        return res.data or []