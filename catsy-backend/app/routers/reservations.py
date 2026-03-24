"""Reservations router — staff management of bookings."""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.repositories.supabase_repo import SupabaseRepository
from app.schemas import ReservationStatusUpdate
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/staff", tags=["Reservations"])


@router.get("/reservations")
@limiter.limit("100/minute")
def get_reservations(
    request: Request,
    limit: int = Query(50, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user)
):
    try:
        return SupabaseRepository.get_reservations(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/reservations/{reservation_id}")
@limiter.limit("20/minute")
def update_reservation_status(
    request: Request,
    reservation_id: str,
    status_update: ReservationStatusUpdate,
    user=Depends(get_current_user)
):
    return SupabaseRepository.update_reservation_status(
        reservation_id, status_update.status, user_id=str(user.id)
    )
