"""
Time Slots Router (Phase 3).

Responsibility: HTTP request/response handling for `/api/admin/time-slots`.
  - Route declarations and rate limiting
  - Auth enforcement via `get_current_user`
  - Translating request data to repository calls
  - Shaping repository results into HTTP responses

What this file does NOT do (Open/Closed):
  - No Supabase queries — those live in `time_slots_repo.py`
  - No business schemas — those live in `schemas.py`
  - Adding a new time-slot feature means adding a route here and
    a method in `time_slots_repo.py` — this file never shrinks or locks.
"""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.auth import get_current_user
from app.schemas import TimeSlotCreate
from app.repositories.time_slots_repo import TimeSlotsRepository

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/admin/time-slots", tags=["Time Slots"])


def get_repo() -> TimeSlotsRepository:
    """Dependency factory — returns the repository instance.
    
    Using a factory function (rather than a global instance) follows the
    Dependency Inversion Principle and makes the repo swappable in tests.
    """
    return TimeSlotsRepository()


@router.get("")
@limiter.limit("60/minute")
def get_time_slots(
    request: Request,
    user=Depends(get_current_user),
    repo: TimeSlotsRepository = Depends(get_repo),
):
    """Admin: List all active time slots enriched with pending reservation counts."""
    try:
        slots = repo.get_active_slots()
        pending_counts = repo.get_pending_counts()
        for slot in slots:
            slot["pending_count"] = pending_counts.get(slot["time"], 0)
        return {"data": slots}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("")
@limiter.limit("30/minute")
def create_time_slot(
    request: Request,
    data: TimeSlotCreate,
    user=Depends(get_current_user),
    repo: TimeSlotsRepository = Depends(get_repo),
):
    """Admin: Create a new time slot, or re-activate a previously removed one."""
    try:
        existing = repo.get_by_time(data.time)
        if existing:
            if not existing.get("is_active"):
                updated = repo.set_active(existing["id"], True)
                return {"data": updated}
            raise HTTPException(status_code=400, detail="Time slot already exists.")
        created = repo.create(data.time)
        return {"data": created}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{slot_id}")
@limiter.limit("20/minute")
def delete_time_slot(
    request: Request,
    slot_id: str,
    user=Depends(get_current_user),
    repo: TimeSlotsRepository = Depends(get_repo),
):
    """Admin: Soft-delete a time slot (sets is_active=False)."""
    try:
        updated = repo.set_active(slot_id, False)
        if not updated:
            raise HTTPException(status_code=404, detail="Time slot not found.")
        return {"data": updated}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
