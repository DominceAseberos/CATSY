"""
Seats Router (Phase 3).

Responsibility: HTTP request/response handling for the GET `/api/seats` endpoint.
  - Route declaration and rate limiting
  - Delegating data fetching + seat-map assembly to the repository
  - Returning the enriched seat-map response

What this file does NOT do (Open/Closed):
  - No Supabase queries — those live in `seats_repo.py`
  - No seat-map merging or mapping logic — in `seats_repo.build_seat_map()`
  - Adding a new seat-related endpoint (e.g. PATCH status, GET by zone) means
    a new route here and a new method in `seats_repo.py` — zero lock-in.
"""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.repositories.seats_repo import SeatsRepository

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/seats", tags=["Seats"])


def get_repo() -> SeatsRepository:
    """Dependency factory — returns the repository instance.

    Swappable in tests following the Dependency Inversion Principle.
    """
    return SeatsRepository()


@router.get("")
@limiter.limit("60/minute")
def get_seats_overview(
    request: Request,
    repo: SeatsRepository = Depends(get_repo),
):
    """Public: Return a live seat map enriched with today's reservation data.

    Available to all users — no auth required since this information is
    displayed in the public café area view.
    """
    try:
        tables = repo.get_all_tables()
        reservations = repo.get_todays_reservations()
        seat_map = repo.build_seat_map(tables, reservations)
        return {"data": seat_map}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
