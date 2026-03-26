"""
Time Slots Repository (Phase 3).

Responsibility: ALL persistence operations for the `time_slots` table.
  - Fetching active slots
  - Computing pending reservation counts
  - Creating, re-activating, and soft-deleting slots

Open/Closed: To add new read projections (e.g. slots with capacity info),
add a new method here — no router changes required.
"""
from typing import List, Optional
from app.database import supabase


class TimeSlotsRepository:
    """Data-access layer for the `time_slots` table.

    Extends the Repository pattern used throughout this codebase.
    All Supabase queries are isolated here so that the router only
    handles HTTP concerns (request/response translation, auth).
    """

    # ── Read ────────────────────────────────────────────────────────────────

    def get_active_slots(self) -> List[dict]:
        """Return all active slots ordered by creation time."""
        res = supabase.table("time_slots")\
            .select("*")\
            .eq("is_active", True)\
            .order("created_at")\
            .execute()
        return res.data or []

    def get_pending_counts(self) -> dict:
        """
        Return a mapping of time_string → count of pending reservations.

        Intentionally kept as a separate method so callers can decide whether
        to enrich slots with this data (Open/Closed: callers can add new
        enrichment strategies without touching this class).
        """
        res = supabase.table("reservations")\
            .select("reservation_time")\
            .eq("status", "pending")\
            .execute()
        reservations = res.data or []
        counts: dict = {}
        for r in reservations:
            t = r.get("reservation_time")
            counts[t] = counts.get(t, 0) + 1
        return counts

    def get_by_time(self, time: str) -> Optional[dict]:
        """Lookup a slot (active or inactive) by its time string."""
        res = supabase.table("time_slots").select("*").eq("time", time).execute()
        return res.data[0] if res.data else None

    # ── Write ───────────────────────────────────────────────────────────────

    def create(self, time: str) -> dict:
        """Insert a brand-new slot record."""
        res = supabase.table("time_slots").insert({"time": time}).execute()
        return res.data[0]

    def set_active(self, slot_id: str, is_active: bool) -> Optional[dict]:
        """Reactivate or soft-delete a slot by toggling `is_active`."""
        res = supabase.table("time_slots")\
            .update({"is_active": is_active})\
            .eq("id", slot_id)\
            .execute()
        return res.data[0] if res.data else None
