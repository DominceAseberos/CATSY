import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

url: str = os.environ.get("SUPABASE_URL") or ""
key: str = os.environ.get("SUPABASE_KEY") or ""

supabase: Client = create_client(url, key)


def get_db() -> Client:
    """
    Factory function that returns the Supabase client.
    Use this instead of importing `supabase` directly — it enables
    dependency injection so tests can swap the client for a mock.

    Production usage:
        db = get_db()
        db.table('products').select('*').execute()

    Test usage (pytest):
        monkeypatch.setattr('app.database.supabase', mock_client)
    """
    return supabase