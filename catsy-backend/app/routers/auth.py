"""Auth routes — login / signup."""
from fastapi import APIRouter, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.services.auth_service import AuthService
from app.auth import get_current_user
from fastapi import Depends

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Auth"])


@router.post("/admin/login")
@limiter.limit("5/minute")
async def admin_login(request: Request):
    data = await request.json()
    email = data.get("username") or data.get("email")
    password = data.get("password")
    try:
        return AuthService.admin_login(email, password)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/customer/login")
@limiter.limit("10/minute")
async def customer_login(request: Request):
    data = await request.json()
    email = data.get("username") or data.get("email")
    password = data.get("password")
    try:
        return AuthService.customer_login(email, password)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/customer/signup")
@limiter.limit("3/minute")
async def customer_signup(request: Request):
    data = await request.json()
    try:
        return AuthService.customer_signup(
            email=data.get("email"),
            password=data.get("password"),
            first_name=data.get("firstName", ""),
            last_name=data.get("lastName", ""),
            phone=data.get("phone", ""),
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
