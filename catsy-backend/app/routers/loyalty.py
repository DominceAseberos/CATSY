"""Loyalty router — stamp tracking and reward redemption."""
from fastapi import APIRouter, HTTPException, Request, Depends
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.repositories.supabase_repo import SupabaseRepository
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/loyalty", tags=["Loyalty"])


@router.get("/status")
@limiter.limit("10/minute")
def get_loyalty_status(request: Request, user=Depends(get_current_user)):
    """Get the current user's unspent stamps and rewards."""
    try:
        return SupabaseRepository.get_loyalty_status(str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/claim")
@limiter.limit("5/minute")
async def claim_loyalty_reward(request: Request, user=Depends(get_current_user)):
    """Spend 9 stamps to claim a free drink reward."""
    try:
        data = await request.json()
        reward_item = data.get("reward_item")
        if not reward_item:
            raise HTTPException(status_code=400, detail="reward_item is required")
        return SupabaseRepository.claim_reward(str(user.id), reward_item)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
