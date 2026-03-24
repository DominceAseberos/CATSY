"""Settings router — read and update restaurant configuration."""
from fastapi import APIRouter, HTTPException, Request, Depends
from app.repositories.supabase_repo import SupabaseRepository
from app.config import DEFAULT_SETTINGS
from app.auth import get_current_user

router = APIRouter(tags=["Settings"])


@router.get("/api/settings")
def get_settings():
    """Fetch live settings merged with safe defaults (OCP — add defaults to config.py, not here)."""
    try:
        db_settings = SupabaseRepository.get_settings()
        return {**DEFAULT_SETTINGS, **db_settings}
    except Exception as e:
        return {"error": str(e)}


@router.patch("/api/admin/settings")
def update_settings(settings_data: dict, user=Depends(get_current_user)):
    """Update system settings — staff only."""
    try:
        return SupabaseRepository.update_settings(settings_data, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
