"""Admin Rewards router — CRUD for reward_items table.
Replaces the product_is_reward flag approach (spec violation fix, Phase 2->3 bridge).

Endpoints:
  GET    /api/admin/rewards         — List all reward items (with product info)
  POST   /api/admin/rewards         — Add a product as a reward item
  PATCH  /api/admin/rewards/:id     — Toggle is_active flag
  DELETE /api/admin/rewards/:id     — Remove a product from reward items
  GET    /api/rewards/active        — Public: list active rewards for loyalty claim picker
"""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from pydantic import BaseModel
from app.database import get_db
from app.repositories.rewards_repo import RewardItemsRepository
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)

admin_router = APIRouter(prefix="/api/admin/rewards", tags=["Admin Rewards"])
public_router = APIRouter(prefix="/api/rewards", tags=["Rewards"])


def get_rewards_repo() -> RewardItemsRepository:
    return RewardItemsRepository()


class RewardItemCreate(BaseModel):
    product_id: int


class RewardItemToggle(BaseModel):
    is_active: bool


# ── Admin endpoints (require auth) ────────────────────────────────────────────
"""
Admin endpoints (require auth):
CRUD operations for reward_items table, only accessible to admins.
"""

@admin_router.get("")
@limiter.limit("60/minute")
def list_reward_items(
    request: Request,
    user=Depends(get_current_user),
    repo: RewardItemsRepository = Depends(get_rewards_repo)
):
    """List all reward items with product info — admin panel product picker."""
    try:
        return repo.get_all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@admin_router.post("")
@limiter.limit("30/minute")
def add_reward_item(
    request: Request,
    data: RewardItemCreate,
    user=Depends(get_current_user),
    repo: RewardItemsRepository = Depends(get_rewards_repo)
):
    """Add a product to the reward_items table (admin action)."""
    try:
        return repo.create({"product_id": data.product_id, "is_active": True})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@admin_router.patch("/{reward_id}")
@limiter.limit("30/minute")
def toggle_reward_item(
    request: Request,
    reward_id: str,
    data: RewardItemToggle,
    user=Depends(get_current_user),
    repo: RewardItemsRepository = Depends(get_rewards_repo)
):
    """Enable or disable a reward item."""
    try:
        result = repo.toggle_active(reward_id, data.is_active)
        if not result:
            raise HTTPException(status_code=404, detail="Reward item not found")
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@admin_router.delete("/{reward_id}")
@limiter.limit("20/minute")
def remove_reward_item(
    request: Request,
    reward_id: str,
    user=Depends(get_current_user),
    repo: RewardItemsRepository = Depends(get_rewards_repo)
):
    """Remove a product from reward items."""
    try:
        return repo.delete(reward_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Public endpoint (no auth required — used by loyalty claim picker) ─────────
"""
Public endpoint (no auth required):
Returns active reward items for the loyalty claim picker.
"""

@public_router.get("/active")
@limiter.limit("60/minute")
def get_active_rewards(
    request: Request,
    repo: RewardItemsRepository = Depends(get_rewards_repo)
):
    """Public endpoint — returns list of active reward items for the claim reward modal.
    Used by LoyaltyPage.jsx to populate the reward picker dropdown.
    """
    try:
        return repo.get_active()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
