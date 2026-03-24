from app.database import supabase

class SupabaseRepository:
    """
    Abstractions for Supabase interactions.
    Encapsulates SRP (Single Responsibility) for data access.
    """
    
    @staticmethod
    def get_products(limit: int = 100, offset: int = 0):
        # Fetch products joined with categories
        query = supabase.table('products').select(
            "*, categories!products_category_id_fkey(name)"
        ).range(offset, offset + limit - 1)
        
        response = query.execute()
        
        # Transform data to include resolved category name
        formatted = []
        for item in response.data:
            category_data = item.get("categories")
            item["category"] = category_data.get("name") if category_data else "Uncategorized"
            formatted.append(item)
            
        return formatted

    @staticmethod
    def get_categories():
        response = supabase.table('categories').select("*").execute()
        return response.data

    @staticmethod
    def get_users(limit: int = 100, offset: int = 0):
        response = supabase.table('users').select("*").range(offset, offset + limit - 1).execute()
        return response.data

    @staticmethod
    def get_materials():
        response = supabase.table('raw_materials_inventory').select("*").execute()
        return response.data

    @staticmethod
    def get_reservations(limit: int = 50, offset: int = 0):
        response = supabase.table('reservations').select("*").range(offset, offset + limit - 1).execute()
        return response.data
