from app.database import supabase
try:
    # Try a select to see if we can get anything
    res = supabase.table("customers").select("*").limit(1).execute()
    print("Data:", res.data)
    
    # Try to insert a non-existent column to trigger a schema error
    res = supabase.table("customers").insert({"non_existent_column_for_debug": "value"}).execute()
except Exception as e:
    print(f"Error: {e}")
