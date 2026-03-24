from fastapi import Header, HTTPException, Depends
from app.database import supabase

def get_current_user(authorization: str = Header(None)):
    """
    Validates the Supabase JWT by sending it directly to Supabase Auth.
    Ensures that only logged-in users or staff can access protected endpoints.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    
    token = authorization.split(" ")[1]
    
    try:
        user_res = supabase.auth.get_user(token)
        if not user_res.user:
            raise Exception("Invalid token")
        return user_res.user
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Unauthorized: {str(e)}")
