"""Reservations router — staff management of bookings."""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.dependencies import get_reservation_repository
from app.repositories.reservations_repo import ReservationRepository
from app.schemas import ReservationStatusUpdate
from pydantic import BaseModel
from typing import Optional

class ReservationCreate(BaseModel):
    customer_name: str
    contact_info: Optional[str] = None
    guest_count: int
    reservation_time: str

from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/staff", tags=["Reservations"])


@router.get("/reservations")
@limiter.limit("100/minute")
def get_reservations(
    request: Request,
    limit: int = Query(50, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
    repo: ReservationRepository = Depends(get_reservation_repository)
):
    try:
        return repo.get_all(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reservations")
@limiter.limit("20/minute")
def create_reservation(
    request: Request,
    reservation: ReservationCreate,
    user=Depends(get_current_user),
    repo: ReservationRepository = Depends(get_reservation_repository)
):
    try:
        data = reservation.dict()
        data["status"] = "pending"
        data["created_by_staff"] = True
        return repo.create(data, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/reservations/{reservation_id}")
@limiter.limit("20/minute")
def update_reservation_status(
    request: Request,
    reservation_id: str,
    status_update: ReservationStatusUpdate,
    user=Depends(get_current_user),
    repo: ReservationRepository = Depends(get_reservation_repository)
):
    return repo.update(
        reservation_id, {"status": status_update.status}, user_id=str(user.id)
    )
