from app.database import supabase

def check_table(table_name):
    try:
        res = supabase.table(table_name).select("*").limit(1).execute()
        print(f"Table '{table_name}' exists. Data: {res.data}")
    except Exception as e:
        print(f"Table '{table_name}' check failed: {e}")

check_table('users')
check_table('customers')
