import asyncio
from app.database import supabase

try:
    res = supabase.table("customers").select("*").limit(1).execute()
    print("Schema keys:", res.data[0].keys() if res.data else "No data")
except Exception as e:
    print("Error:", e)
