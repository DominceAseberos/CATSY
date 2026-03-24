from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from .database import supabase

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="Catsy Coffee API Bridge")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# IMPORTANT: This allows your Web and Mobile apps to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with your specific domains
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "✅ Catsy API is online"}

# Example route for your classmates to fill in
@app.get("/api/coffee")
def get_coffee():
    return {"message": "Coffee list skeleton ready"}

# --- Authentication ---

@app.post("/admin/login")
@limiter.limit("5/minute")
async def admin_login(request: Request):
    data = await request.json()
    email = data.get("username") # We treat username as email for Supabase
    password = data.get("password")
    try:
        response = supabase.auth.sign_in_with_password({"email": email, "password": password})
        return {
            "user": response.user,
            "session": response.session,
            "access_token": response.session.access_token,
            "refresh_token": response.session.refresh_token
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

@app.post("/customer/login")
@limiter.limit("10/minute")
async def customer_login(request: Request):
    data = await request.json()
    email = data.get("username")
    password = data.get("password")
    try:
        response = supabase.auth.sign_in_with_password({"email": email, "password": password})
        return {
            "user": response.user,
            "session": response.session,
            "access_token": response.session.access_token
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

@app.post("/customer/signup")
@limiter.limit("3/minute")
async def customer_signup(request: Request):
    data = await request.json()
    email = data.get("email")
    password = data.get("password")
    try:
        response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "first_name": data.get("firstName"),
                    "last_name": data.get("lastName"),
                    "phone": data.get("phone")
                }
            }
        })
        return {"user": response.user, "status": "Confirm email if enabled"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# --- Customer Profile ---

@app.get("/customer/{customer_id}")
def get_customer_profile(customer_id: str, user=Depends(get_current_user)):
    # Simple fetch from customers view/table
    response = supabase.table('profiles').select("*").eq('id', customer_id).single().execute()
    return response.data

@app.put("/customer/update/{customer_id}")
def update_customer_profile(customer_id: str, data: dict, user=Depends(get_current_user)):
    response = supabase.table('profiles').update(data).eq('id', customer_id).execute()
    return response.data

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

from fastapi.responses import StreamingResponse
import asyncio

#This is the url
@app.get("/api/db-check")
@limiter.limit("5/minute")
def check_db(request: Request):
    try:
        response = supabase.table('products').select("*", count='exact').limit(1).execute()
        
        return {
            "status": "📡 Supabase Connected!",
            "data_preview": response.data,
            "count": response.count
        }
    except Exception as e:
        return {
            "status": "❌ Supabase Connection Failed",
            "error": str(e)
        }

from fastapi import Query
from typing import List
from app.repositories.supabase_repo import SupabaseRepository
from app.schemas import (
    ProductResponse, ProductCreate, ProductUpdate, 
    CategoryResponse, CategoryCreate, CategoryUpdate,
    ReservationStatusUpdate
)
from app.auth import get_current_user
from fastapi import Depends

@app.get("/products", response_model=List[ProductResponse])
@limiter.limit("30/minute")
def get_products(request: Request, limit: int = Query(100, ge=1, le=1000), offset: int = Query(0, ge=0)):
    try:
        return SupabaseRepository.get_products(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")

@app.get("/categories", response_model=List[CategoryResponse])
@limiter.limit("60/minute")
def get_categories(request: Request):
    try:
        return SupabaseRepository.get_categories()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")

# --- Admin Products ---

@app.get("/admin/products", response_model=List[ProductResponse])
@limiter.limit("20/minute")
def admin_get_products(request: Request, user=Depends(get_current_user)):
    return SupabaseRepository.get_products()

@app.post("/admin/products", response_model=List[ProductResponse])
@limiter.limit("10/minute")
def create_product(request: Request, product: ProductCreate, user=Depends(get_current_user)):
    return SupabaseRepository.create_product(product.dict(), user_id=str(user.id))

@app.put("/admin/products/{product_id}")
@limiter.limit("20/minute")
def update_product(request: Request, product_id: str, product: ProductUpdate, user=Depends(get_current_user)):
    data = product.dict(exclude_unset=True)
    return SupabaseRepository.update_product(product_id, data, user_id=str(user.id))

@app.delete("/admin/products/{product_id}")
@limiter.limit("10/minute")
def delete_product(request: Request, product_id: str, user=Depends(get_current_user)):
    return SupabaseRepository.delete_product(product_id, user_id=str(user.id))

# --- Admin Categories ---

@app.get("/admin/categories", response_model=List[CategoryResponse])
@limiter.limit("20/minute")
def admin_get_categories(request: Request, user=Depends(get_current_user)):
    return SupabaseRepository.get_categories()

@app.post("/admin/categories")
def create_category(request: Request, category: CategoryCreate, user=Depends(get_current_user)):
    return SupabaseRepository.create_category(category.dict(), user_id=str(user.id))

@app.put("/admin/categories/{category_id}")
def update_category(request: Request, category_id: str, category: CategoryUpdate, user=Depends(get_current_user)):
    data = category.dict(exclude_unset=True)
    return SupabaseRepository.update_category(category_id, data, user_id=str(user.id))

@app.delete("/admin/categories/{category_id}")
def delete_category(request: Request, category_id: str, user=Depends(get_current_user)):
    return SupabaseRepository.delete_category(category_id, user_id=str(user.id))

# --- Audit Logs ---

@app.get("/admin/audit-logs")
@limiter.limit("10/minute")
def get_audit_logs(
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user)
):
    """
    Staff-only endpoint to view the system audit trail.
    """
    try:
        # We use the generic supabase client here with filter
        response = supabase.table('audit_logs').select("*").order('created_at', desc=True).range(offset, offset + limit - 1).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")

@app.get("/api/staff/reservations")
@limiter.limit("100/minute")
def get_reservations(
    request: Request,
    limit: int = Query(50, ge=1, le=1000), 
    offset: int = Query(0, ge=0), 
    user=Depends(get_current_user)
):
    """
    Staff-only endpoint. Requires a valid JWT Bearer token supplied by the frontend.
    """
    try:
        return SupabaseRepository.get_reservations(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")

@app.patch("/api/staff/reservations/{reservation_id}")
@limiter.limit("20/minute")
def update_reservation_status(
    request: Request,
    reservation_id: str, 
    status_update: ReservationStatusUpdate, 
    user=Depends(get_current_user)
):
    return SupabaseRepository.update_reservation_status(reservation_id, status_update.status, user_id=str(user.id))

@app.get("/api/settings")
def get_settings():
    """
    Fetch system settings and merge with hardcoded UI defaults.
    """
    try:
        db_settings = SupabaseRepository.get_settings()
        defaults = {
            "theme": "dark",
            "maintenance_mode": False,
            "store_status": "open",
            "currency": "PHP",
            "is_open": True,
            "opening_time": "08:00",
            "closing_time": "22:00",
            "available_tables": 0,
            "total_tables": 0
        }
        return {**defaults, **db_settings}
    except Exception as e:
        return {"error": str(e)}

@app.patch("/api/admin/settings")
def update_settings(request: Request, settings_data: dict, user=Depends(get_current_user)):
    """
    Update system settings (Staff Only).
    """
    try:
        return SupabaseRepository.update_settings(settings_data, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- Loyalty ---

@app.get("/loyalty/status")
@limiter.limit("10/minute")
def get_loyalty_status(user=Depends(get_current_user)):
    """
    Get the current user's unspent stamps and rewards.
    """
    try:
        return SupabaseRepository.get_loyalty_status(str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/loyalty/claim")
@limiter.limit("5/minute")
async def claim_loyalty_reward(request: Request, user=Depends(get_current_user)):
    """
    Spend 9 stamps to claim a free drink reward.
    """
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

async def event_generator():
    """Simple SSE generator that sends a heartbeat ping to keep connection alive."""
    try:
        while True:
            # Yield a heartbeat comment to keep connection alive
            yield ": ping\n\n"
            await asyncio.sleep(15)
    except asyncio.CancelledError:
        pass

@app.get("/api/events/stream")
async def stream_events():
    return StreamingResponse(event_generator(), media_type="text/event-stream")