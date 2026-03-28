"""
Catsy Coffee API — main entry point.

Responsibilities of this file (and ONLY these):
  1. Create the FastAPI application instance
  2. Configure middleware (CORS, rate limiting)
  3. Mount domain routers
  4. Expose a health-check endpoint
  5. SSE event stream for real-time UI updates

All business logic lives in app/routers/ and app/services/.
"""
import asyncio
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Domain routers — each owns its own slice of the API surface
from app.routers import auth, products, categories, loyalty, reservations, settings, orders, customer, rewards, cms, reports, seats, materials
from app.routers.admin import audit_router, inventory_router, users_router, apk_router

"""
Application setup: Initializes FastAPI app, configures rate limiting, and sets up exception handlers.
"""

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="Catsy Coffee API",
    description="Secure FastAPI bridge → Supabase backend",
    version="2.0.0",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


"""
CORS configuration:
- Reads allowed origins from the ALLOWED_ORIGINS environment variable (comma-separated).
- Example: ALLOWED_ORIGINS=http://localhost:5173,https://yourapp.com
- Defaults to http://localhost:5173 if not set.
"""
_raw = os.environ.get("ALLOWED_ORIGINS", "http://localhost:5173")
ALLOWED_ORIGINS = [o.strip() for o in _raw.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

"""
Mount routers: Registers all API routers with the FastAPI application instance.
Routers are grouped by domain and phase.
"""

app.include_router(auth.router)
app.include_router(products.router)
app.include_router(categories.router)
app.include_router(loyalty.router)
app.include_router(reservations.router)
app.include_router(reservations.customer_router)
app.include_router(settings.router)
app.include_router(audit_router)
app.include_router(inventory_router)
app.include_router(users_router)
"""
Domain routers: Each router module owns its own slice of the API surface.
Routers are imported and mounted below.
"""
app.include_router(apk_router)
app.include_router(orders.router)
app.include_router(customer.customer_router)  # Handles GET /api/customer/orders
app.include_router(customer.staff_router)     # Handles GET /api/staff/members?search=
app.include_router(rewards.admin_router)      # Admin CRUD endpoints for reward_items
app.include_router(rewards.public_router)     # Public endpoint for GET /api/rewards/active

"""
Phase 3 routers: Additional features (CMS, reports, seats, etc.)
"""
app.include_router(cms.admin_router)
app.include_router(cms.public_router)
app.include_router(reports.router)
app.include_router(seats.router)

"""
Materials routers: Registers both the main materials router and the new recipe router.
"""
app.include_router(materials.router)
app.include_router(materials.recipe_router)

"""
Utility endpoints: Health check and other non-domain-specific endpoints.
"""

@app.get("/", tags=["Health"])
def health_check():
    return {"status": "✅ Catsy API is online", "version": "2.0.0"}


"""
Server-Sent Events (SSE): Provides a real-time event stream for UI updates.
"""

async def _event_generator():
    """Heartbeat ping — keeps the SSE connection alive every 15 s."""
    try:
        while True:
            yield ": ping\n\n"
            await asyncio.sleep(15)
    except asyncio.CancelledError:
        pass


@app.get("/api/events/stream", tags=["Realtime"])
async def stream_events():
    return StreamingResponse(_event_generator(), media_type="text/event-stream")


"""
Development entry point: Allows running the app with `python main.py` for local development.
"""

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)