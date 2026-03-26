"""
Reports Repository (Phase 3).

Responsibility: ALL data retrieval and aggregation for the reports domain.
  - Fetching paid orders with optional date filtering
  - Aggregating totals by payment method
  - Grouping by day for the breakdown table
  - Fetching customer feedback records

Open/Closed: New report types (e.g. product-level breakdown, staff
performance) can be added as new methods without modifying existing ones.
This router will NEVER contain date arithmetic or aggregation again.
"""
from datetime import date
from typing import List, Optional
from app.database import supabase


class ReportsRepository:
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
        """Fetch paid orders, optionally scoped to a date range.

        Args:
            period: 'today' shorthand, or None to use explicit from/to dates.
            from_date: ISO date string (YYYY-MM-DD).
            to_date: ISO date string (YYYY-MM-DD).

        Returns:
            List of raw order dicts from Supabase.
        """
        query = supabase.table("orders").select("*").eq("status", "served")
        if period == "today":
            today = date.today().isoformat()
            query = query.gte("created_at", f"{today}T00:00:00").lte("created_at", f"{today}T23:59:59")
        elif from_date and to_date:
            query = query.gte("created_at", f"{from_date}T00:00:00").lte("created_at", f"{to_date}T23:59:59")
        return query.execute().data or []

    def aggregate_sales(self, orders: List[dict]) -> dict:
        """
        Compute total, per-payment-method breakdown, daily rows, and order count.

        Pure function — only depends on the orders list, no I/O.
        This makes it trivially testable in isolation.
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
            if pm == "Cash":  daily[day]["cash"]  += o.get("total_amount", 0)
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
        """Return paginated feedback entries, newest first."""
        res = supabase.table("user_feedback")\
            .select("*")\
            .order("created_at", desc=True)\
            .limit(limit)\
            .execute()
        return res.data or []
