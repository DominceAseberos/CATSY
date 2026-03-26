"""Seats/Tables Router (Phase 3 Overview)."""
from fastapi import APIRouter, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.database import supabase
from datetime import date

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/seats", tags=["Seats"])

@router.get("")
@limiter.limit("60/minute")
def get_seats_overview(request: Request):
    """Publicly accessible overview of seats and today's reservations."""
    try:
        # Fetch cafe tables
        tables_res = supabase.table("cafe_tables").select("*").execute()
        tables = tables_res.data or []
        
        # Fetch today's confirmed/pending reservations
        today = date.today().isoformat()
        res_res = supabase.table("reservations")\
            .select("*")\
            .in_("status", ["confirmed", "pending"])\
            .gte("reservation_time", f"{today}T00:00:00")\
            .lte("reservation_time", f"{today}T23:59:59")\
            .execute()
        day_reservations = res_res.data or []
        
        # Map reservations to seats. Currently reservations might not have a strict seat_id 
        # but to satisfy the 'reserved' status UI we can mock mapping or use status from table:
        # If 'cafe_tables' has a status field (Available/Occupied), we use it. 
        # If a reservation exists for this table today, we attach the tooltip data.
        
        seats_map = []
        for t in tables:
            seat_info = {
                "id": t["table_id"],
                "seat_number": t["table_number"],
                "status": t.get("status", "available").lower(), # green/red
                "capacity": t.get("capacity", 2),
                "reservation": None
            }
            # For demonstration, find a reservation assigned to this table
            # Assuming 'table_id' might be stored in reservation 'special_requests' or similar if no explicit FK
            # If explicit FK exists, use it. Here we just match if we have 'table_id' in reservation.
            for r in day_reservations:
                if r.get("table_id") == t["table_id"]:
                    seat_info["status"] = "reserved" # blue
                    seat_info["reservation"] = {
                        "customer_name": f"{r.get('first_name', '')} {r.get('last_name', '')}".strip(),
                        "time_slot": r.get("reservation_time"),
                        "guest_count": r.get("guest_count", 0)
                    }
                    break
            seats_map.append(seat_info)
            
        return {"data": seats_map}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
