"""Auth routes — login / signup."""
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.services.auth_service import AuthService
from app.auth import get_current_user
from fastapi import Depends

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(tags=["Auth"])


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

@router.post("/admin/login")
@limiter.limit("5/minute")
def admin_login(request: Request, body: LoginRequest):
    email = body.username or body.email
    try:
        return AuthService.admin_login(email, body.password)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/customer/login")
@limiter.limit("10/minute")
def customer_login(request: Request, body: LoginRequest):
    email = body.username or body.email
    try:
        return AuthService.customer_login(email, body.password)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/customer/signup")
@limiter.limit("3/minute")
def customer_signup(request: Request, body: SignupRequest):
    try:
        return AuthService.customer_signup(
            email=body.email,
            password=body.password,
            username=body.username,
            first_name=body.firstName,
            last_name=body.lastName,
            phone=body.phone,
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
