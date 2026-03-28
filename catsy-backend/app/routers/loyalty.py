"""
Loyalty Router
==============

Purpose:
    Provides endpoints for loyalty stamp status and reward claiming.
    Handles business logic for customer loyalty, including stamp crediting and reward redemption.

Usage:
    - GET /loyalty/status: Get current loyalty status for a user
    - POST /loyalty/claim: Claim a reward using unspent stamps

Responsibilities:
    - Validates and processes loyalty reward claims
    - Returns loyalty status and available rewards
    - Integrates with LoyaltyService for business logic
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


# ── Schemas (move to schemas.py) ──────────────────────────────────────────────
"""
Schemas (temporary):
StampCreditRequest and ClaimRequest are defined here for now. Move to schemas.py when splitting that file.
"""

class StampCreditRequest(BaseModel):
    customer_id: str
    eligible_product_count: int


class ClaimRequest(BaseModel):          # <-- replaces await request.json()
    reward_item: str


# ── Routes ────────────────────────────────────────────────────────────────────
"""
Routes:
Endpoints for loyalty status and reward claiming.
"""

@router.get("/status")
@limiter.limit("10/minute")
def get_loyalty_status(
    request: Request,
    user=Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
    try:
        return service.get_status(str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/claim")
@limiter.limit("5/minute")
def claim_loyalty_reward(
    request: Request,
    body: ClaimRequest,                 # <-- typed, validated by FastAPI
        body: ClaimRequest,  # Typed and validated by FastAPI
    user=Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service),
):
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
    try:
        return service.redeem_reward(redeem_data.coupon_code, staff_id=str(user.id))
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))