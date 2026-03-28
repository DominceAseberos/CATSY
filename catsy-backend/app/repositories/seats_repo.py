"""
Seats Repository (Phase 3).

Responsibility: ALL persistence and seat-status mapping for the cafe tables
and reservations domains.
  - Fetching all cafe tables
  - Fetching today's active reservations
  - Producing the enriched seat-map response (table + reservation overlay)

Open/Closed: To add new seat statuses (e.g. 'cleaning', 'maintenance'),
or change the reservation matching strategy (e.g. by time window instead
of explicit FK), modify or add a method here without touching the router.
"""
from datetime import date
from typing import List
from app.database import get_db


class SeatsRepository:
    """Data-access layer for the Seat Overview feature.

    Merges two tables — `cafe_tables` and `reservations` — into a single
    enriched seat-map list. Keeps the router free from JOIN/merge logic.
    """

    # ── Read ────────────────────────────────────────────────────────────────

    def get_all_tables(self) -> List[dict]:
        """Return all registered cafe tables."""
        db = get_db()
        res = db.table("cafe_tables").select("*").execute()
        return res.data or []

    def get_todays_reservations(self) -> List[dict]:
        """Return confirmed/pending reservations for today only."""
        db = get_db()
        today = date.today().isoformat()
        res = db.table("reservations")\
            .select("*")\
            .in_("status", ["confirmed", "pending"])\
            .gte("reservation_time", f"{today}T00:00:00")\
            .lte("reservation_time", f"{today}T23:59:59")\
            .execute()
        return res.data or []

    # ── Aggregation ──────────────────────────────────────────────────────────

    def build_seat_map(self, tables: List[dict], reservations: List[dict]) -> List[dict]:
        """
        Merge tables with today's reservations into the seat-map format.

        Pure function — depends only on its arguments, no I/O.
        Easy to unit-test: pass fixtures for tables and reservations.

        Returns a list of seat dicts with keys:
            id, seat_number, status, capacity, reservation (or None)
        """
        seats = []
        for t in tables:
            seat: dict = {
                "id":          t["table_id"],
                "seat_number": t["table_number"],
                "status":      t.get("status", "available").lower(),
                "capacity":    t.get("capacity", 2),
                "reservation": None,
            }
            for r in reservations:
                if r.get("table_id") == t["table_id"]:
                    seat["status"] = "reserved"
                    seat["reservation"] = {
                        "customer_name": f"{r.get('first_name', '')} {r.get('last_name', '')}".strip(),
                        "time_slot":     r.get("reservation_time"),
                        "guest_count":   r.get("guest_count", 0),
                    }
                    break
            seats.append(seat)
        return seats