"""
Auth Router
===========

Purpose:
    Provides authentication endpoints for admin and customer login/signup.
    Integrates with AuthService for business logic and user validation.

Usage:
    - POST /admin/login: Admin login
    - POST /customer/login: Customer login
    - POST /customer/signup: Customer signup

Responsibilities:
    - Validates login/signup requests
    - Injects AuthService via dependency injection
    - Returns authentication tokens and user profiles
"""
from fastapi import APIRouter, HTTPException, Request, Depends
from app.schemas import LoginRequest, SignupRequest
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.services.auth_service import AuthService

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Auth"])


# ── Dependency ────────────────────────────────────────────────────────────────
"""
Dependency injection:
Provides get_auth_service() for injecting AuthService via Depends().
"""

def get_auth_service() -> AuthService:
    return AuthService()


# ── Routes ────────────────────────────────────────────────────────────────────
"""
Routes:
Authentication endpoints for admin and customer login/signup.
"""

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