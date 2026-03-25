from app.database import supabase
import uuid
import sys

try:
    user_id = str(uuid.uuid4())
    print(f"ID: {user_id}")
    data = {
        "id": user_id,
        "email": f"test-{user_id[:4]}@test.com",
        "username": "tester",
        "first_name": "Test",
        "last_name": "User",
        "phone": "09123456789",
        "role": "customer"
    }
    print(f"Data: {data}")
    res = supabase.table("customers").insert(data).execute()
    print("SUCCESS:", res.data)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
