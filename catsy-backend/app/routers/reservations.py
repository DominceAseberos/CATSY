"""
Reservations Router — Staff management of bookings & public availability.
[SOLID: SRP] This file ONLY handles HTTP Request/Response mapping and payload validation.
[SOLID: DIP] All database logic is injected via `Depends(get_reservation_repository)`.
[SOLID: OCP] To add new reservation features (e.g., SMS alerts), do NOT modify this file.
Create a new `ReservationService` and inject it alongside the repository.
"""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.dependencies import get_reservation_repository
from app.repositories.reservations_repo import ReservationRepository
from app.schemas import ReservationStatusUpdate
from pydantic import BaseModel
from typing import Optional

class ReservationCreate(BaseModel):
    first_name: str
    last_name: str
    email: Optional[str] = None
    phone: str
    guest_count: int
    reservation_time: str
    special_requests: Optional[str] = None

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

# --- Customer Endpoints ---
customer_router = APIRouter(prefix="/api/customer", tags=["Customer Reservations"])

@customer_router.get("/reservations")
@limiter.limit("100/minute")
def get_public_reservations(
    request: Request,
    repo: ReservationRepository = Depends(get_reservation_repository)
):
    """
    Public endpoint for frontend capacity calculation.
    [OCP] Returns lightweight payload. If more complex filtering is needed later, 
    add a query string parameter without breaking the native fetch behavior.
    """
    try:
        # Customers need to see pending/confirmed to know table limits
        return repo.get_all(limit=1000)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@customer_router.post("/reservations")
@limiter.limit("5/minute")
def register_customer_reservation(
    request: Request,
    reservation: ReservationCreate,
    repo: ReservationRepository = Depends(get_reservation_repository)
):
    """
    Guest and Customer reservation ingestion endpoint.
    [SRP] Validates the Pydantic model natively via FastAPI type hints.
    """
    try:
        data = reservation.model_dump() if hasattr(reservation, 'model_dump') else reservation.dict()
        data["status"] = "pending"
        return repo.create(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
