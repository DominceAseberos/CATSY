"""
Auth router — fixed version.

Changes:
  1. AuthService injected via Depends() — no more static method calls.
  2. LoginRequest / SignupRequest moved here temporarily; move to schemas.py
     once you split that file.
"""
from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.services.auth_service import AuthService

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Auth"])


# ── Schemas (move to schemas.py when splitting that file) ─────────────────────

class LoginRequest(BaseModel):
    username: str = None
    email: str = None
    password: str


class SignupRequest(BaseModel):
    email: str
    password: str
    username: str = ""
    firstName: str = ""
    lastName: str = ""
    phone: str = ""


# ── Dependency ────────────────────────────────────────────────────────────────

def get_auth_service() -> AuthService:
    return AuthService()


# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/admin/login")
@limiter.limit("5/minute")
def admin_login(
    request: Request,
    body: LoginRequest,
    service: AuthService = Depends(get_auth_service),
):
    email = body.username or body.email
    try:
        return service.admin_login(email, body.password)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/customer/login")
@limiter.limit("10/minute")
def customer_login(
    request: Request,
    body: LoginRequest,
    service: AuthService = Depends(get_auth_service),
):
    email = body.username or body.email
    try:
        return service.customer_login(email, body.password)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/customer/signup")
@limiter.limit("3/minute")
def customer_signup(
    request: Request,
    body: SignupRequest,
    service: AuthService = Depends(get_auth_service),
):
    try:
        return service.customer_signup(
            email=body.email,
            password=body.password,
            username=body.username,
            first_name=body.firstName,
            last_name=body.lastName,
            phone=body.phone,
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))