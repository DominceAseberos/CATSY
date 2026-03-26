from app.database import supabase
import uuid

try:
    user_id = str(uuid.uuid4())
    print(f"Attempting insert with ID: {user_id}")
    res = supabase.table("customers").insert({
        "id": user_id,
        "email": f"test-{user_id[:8]}@debug.com",
        "username": "tester",
        "first_name": "Test",
        "last_name": "User",
        "phone": "123",
        "role": "customer"
    }).execute()
    print("SUCCESS:", res.data)
except Exception as e:
    print(f"FAILED: {e}")
