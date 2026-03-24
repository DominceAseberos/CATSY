from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .database import supabase

app = FastAPI(title="Catsy Coffee API Bridge")

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
    # TODO: Classmate needs to implement the logic here
    # Example: response = supabase.table('coffee_items').select("*").execute()
    return {"message": "Coffee list skeleton ready"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

from fastapi.responses import StreamingResponse
import asyncio

#This is the url
@app.get("/api/db-check")
def check_db():
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
from app.repositories.supabase_repo import SupabaseRepository

@app.get("/products")
def get_products(limit: int = Query(100, ge=1, le=1000), offset: int = Query(0, ge=0)):
    try:
        return SupabaseRepository.get_products(limit=limit, offset=offset)
    except Exception as e:
        # Basic error handling for DB timeouts or connection issues
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")

@app.get("/categories")
def get_categories():
    try:
        return SupabaseRepository.get_categories()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")

@app.get("/api/settings")
def get_settings():
    # Return default settings or fetch from a settings table if it exists
    # For now, providing the defaults the UI expects to prevent crashing
    return {
        "theme": "dark",
        "maintenance_mode": False,
        "store_status": "open",
        "currency": "PHP"
    }

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