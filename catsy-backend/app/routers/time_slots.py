"""Time Slots router for Reservation Management (Phase 3)."""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from pydantic import BaseModel
from app.database import supabase
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/admin/time-slots", tags=["Time Slots"])


class TimeSlotCreate(BaseModel):
    time: str


@router.get("")
@limiter.limit("60/minute")
def get_time_slots(
    request: Request,
    user=Depends(get_current_user)
):
    """Admin: Get all time slots with pending reservation count (Phase 3)."""
    try:
        # Fetch active slots
        res = supabase.table("time_slots").select("*").eq("is_active", True).order("created_at").execute()
        slots = res.data or []
        
        # Count pending reservations per slot
        # Ideally an RPC or aggregate, but doing Python-side for simplicity given low volume
        reserve_res = supabase.table("reservations").select("reservation_time").eq("status", "pending").execute()
        reservations = reserve_res.data or []
        
        pending_counts = {}
        for r in reservations:
            t = r.get("reservation_time")
            pending_counts[t] = pending_counts.get(t, 0) + 1
            
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
    user=Depends(get_current_user)
):
    """Admin: Create or re-activate a time slot."""
    try:
        # We do an upsert or check existing
        existing = supabase.table("time_slots").select("*").eq("time", data.time).execute()
        if existing.data:
            rec = existing.data[0]
            if not rec.get("is_active"):
                res = supabase.table("time_slots").update({"is_active": True}).eq("id", rec["id"]).execute()
                return {"data": res.data[0]}
            else:
                raise HTTPException(status_code=400, detail="Time slot already exists.")
        
        res = supabase.table("time_slots").insert({"time": data.time}).execute()
        return {"data": res.data[0]}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{slot_id}")
@limiter.limit("20/minute")
def delete_time_slot(
    request: Request,
    slot_id: str,
    user=Depends(get_current_user)
):
    """Admin: Remove a time slot."""
    try:
        res = supabase.table("time_slots").update({"is_active": False}).eq("id", slot_id).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Time slot not found.")
        return {"data": res.data[0]}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
