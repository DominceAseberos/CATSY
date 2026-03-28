"""
Loyalty Router
==============

What:
    Provides all HTTP endpoints for the loyalty stamp and reward system,
    including status checks, reward claiming, stamp crediting, and redemption.

How:
    Delegates all business logic to LoyaltyService via dependency injection.
    Uses Pydantic models for request validation and slowapi for rate limiting.

When:
    Called by authenticated customers checking their stamp balance or
    claiming rewards, and by authenticated staff crediting stamps or
    redeeming coupon codes at the counter.

What it does:
    - GET  /loyalty/status         — Returns stamp count and reward history for the current user
    - POST /loyalty/claim          — Claims a reward using 9 unspent stamps
    - POST /loyalty/staff/credit   — Staff credits stamps to a customer after a qualifying purchase
    - POST /loyalty/staff/redeem   — Staff validates and redeems a customer coupon code in-store

What it does NOT do:
    - Does not contain loyalty business logic (stamp counts, coupon generation) — that lives in LoyaltyService
    - Does not access the database directly — all data access goes through LoyaltyRepository
    - Does not define Pydantic schemas used outside this router — those belong in schemas.py
"""
from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.dependencies import get_loyalty_service
from app.services.loyalty_service import LoyaltyService
from app.schemas import RewardRedeemRequest
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/loyalty", tags=["Loyalty"])


# ── Schemas ───────────────────────────────────────────────────────────────────

class StampCreditRequest(BaseModel):
    """Payload for POST /loyalty/staff/credit — staff credits stamps to a customer."""
    customer_id: str
    eligible_product_count: int


class ClaimRequest(BaseModel):
    """Payload for POST /loyalty/claim — customer selects a reward item to claim."""
    reward_item: str


# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("/status")
@limiter.limit("10/minute")
def get_loyalty_status(
    request: Request,
    user=Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    """Return current stamp count and reward history for the authenticated user."""
    try:
        return service.get_status(str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/claim")
@limiter.limit("5/minute")
def claim_loyalty_reward(
    request: Request,
    body: ClaimRequest,
    user=Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    """Claim a loyalty reward using 9 unspent stamps.

    Raises 400 if the user does not have enough stamps.
    """
    try:
        return service.claim_reward(str(user.id), body.reward_item)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/staff/credit")
@limiter.limit("50/minute")
def credit_stamps(
    request: Request,
    credit_data: StampCreditRequest,
    user=Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    """Credit loyalty stamps to a customer after a qualifying purchase.

    Only processes if eligible_product_count is greater than zero.
    """
    try:
        if credit_data.eligible_product_count <= 0:
            return {"message": "No eligible products"}
        return service.credit_stamps(
            customer_id=credit_data.customer_id,
            count=credit_data.eligible_product_count,
            staff_id=str(user.id),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/staff/redeem")
@limiter.limit("30/minute")
def redeem_reward(
    request: Request,
    redeem_data: RewardRedeemRequest,
    user=Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    """Validate and redeem a customer coupon code in-store.

    Raises 400 if the coupon is invalid or already redeemed.
    """
    try:
        return service.redeem_reward(redeem_data.coupon_code, staff_id=str(user.id))
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))