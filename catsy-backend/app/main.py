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
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Domain routers — each owns its own slice of the API surface
from app.routers import auth, products, categories, loyalty, reservations, settings, admin, orders

# --- App setup ---------------------------------------------------------------

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="Catsy Coffee API",
    description="Secure FastAPI bridge → Supabase backend",
    version="2.0.0",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Replace with specific domains in production
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Mount routers -----------------------------------------------------------

app.include_router(auth.router)
app.include_router(products.router)
app.include_router(categories.router)
app.include_router(loyalty.router)
app.include_router(reservations.router)
app.include_router(settings.router)
app.include_router(admin.router)
app.include_router(orders.router)

# --- Utility endpoints -------------------------------------------------------

@app.get("/", tags=["Health"])
def health_check():
    return {"status": "✅ Catsy API is online", "version": "2.0.0"}


# --- Server-Sent Events ------------------------------------------------------

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


# --- Dev entry point ---------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)