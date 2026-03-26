"""Loyalty router — stamp tracking and reward redemption."""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.dependencies import get_loyalty_service
from app.services.loyalty_service import LoyaltyService
from app.schemas import RewardRedeemRequest
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/loyalty", tags=["Loyalty"])


from pydantic import BaseModel

class StampCreditRequest(BaseModel):
    customer_id: str
    eligible_product_count: int

@router.get("/status")
@limiter.limit("10/minute")
def get_loyalty_status(request: Request, user=Depends(get_current_user), service: LoyaltyService = Depends(get_loyalty_service)):
    """Get the current user's unspent stamps and rewards."""
    try:
        return service.get_status(str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/claim")
@limiter.limit("5/minute")
async def claim_loyalty_reward(request: Request, user=Depends(get_current_user), service: LoyaltyService = Depends(get_loyalty_service)):
    """Spend 9 stamps to claim a free drink reward."""
    try:
        data = await request.json()
        reward_item = data.get("reward_item")
        if not reward_item:
            raise HTTPException(status_code=400, detail="reward_item is required")
        return service.claim_reward(str(user.id), reward_item)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/staff/credit")
@limiter.limit("50/minute")
def credit_stamps(request: Request, credit_data: StampCreditRequest, user=Depends(get_current_user), service: LoyaltyService = Depends(get_loyalty_service)):
    """Staff endpoint to credit stamps to a customer after order payment."""
    try:
        if credit_data.eligible_product_count <= 0:
            return {"message": "No eligible products"}
        return service.credit_stamps(
            customer_id=credit_data.customer_id,
            count=credit_data.eligible_product_count,
            staff_id=str(user.id)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/staff/redeem")
@limiter.limit("30/minute")
def redeem_reward(
    request: Request,
    redeem_data: RewardRedeemRequest,
    user=Depends(get_current_user),
    service: LoyaltyService = Depends(get_loyalty_service)
):
    """Staff endpoint — validate and mark a reward coupon as redeemed (FR S8).
    Requires staff JWT. Returns error if code is invalid or already used.
    """
    try:
        return service.redeem_reward(redeem_data.coupon_code, staff_id=str(user.id))
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
