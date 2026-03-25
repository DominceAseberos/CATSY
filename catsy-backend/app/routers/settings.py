"""Settings router — read and update restaurant configuration."""
from fastapi import APIRouter, HTTPException, Request, Depends
from app.dependencies import get_settings_repository
from app.repositories.settings_repo import SettingsRepository
from app.config import DEFAULT_SETTINGS
from app.auth import get_current_user

router = APIRouter(tags=["Settings"])


@router.get("/api/settings")
def get_settings(repo: SettingsRepository = Depends(get_settings_repository)):
    """Fetch live settings merged with safe defaults (OCP — add defaults to config.py, not here)."""
    try:
        db_settings = repo.get_all()
        return {**DEFAULT_SETTINGS, **db_settings}
    except Exception as e:
        return {"error": str(e)}


@router.patch("/api/admin/settings")
def update_settings(settings_data: dict, user=Depends(get_current_user), repo: SettingsRepository = Depends(get_settings_repository)):
    """Update system settings — staff only."""
    try:
        return repo.update("1", settings_data, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
