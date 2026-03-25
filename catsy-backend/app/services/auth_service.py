"""
AuthService — encapsulates all Supabase Auth interactions.
Keeps route handlers thin (SRP).
"""
from app.database import supabase


class AuthService:

    @staticmethod
    def admin_login(email: str, password: str) -> dict:
        response = supabase.auth.sign_in_with_password({"email": email, "password": password})
        
        user_dict = response.user.model_dump() if hasattr(response.user, 'model_dump') else response.user.__dict__
        meta = user_dict.get("user_metadata", {})
        app_meta = user_dict.get("app_metadata", {})
        
        role = meta.get("role") or app_meta.get("role")
        
        if not role:
            try:
                user_res = supabase.table("customers").select("*").eq("id", response.user.id).execute()
                if user_res.data:
                    row = user_res.data[0]
                    role = row.get("role")
                    user_dict.update(row)
            except Exception:
                pass
                
        if not role:
            role = "admin" if "admin" in email.lower() or "staff" in email.lower() else "admin"
        
        user_dict["role"] = role

        return {
            "user": user_dict,
            "session": response.session,
            "access_token": response.session.access_token,
            "refresh_token": response.session.refresh_token,
        }

    @staticmethod
    def customer_login(email: str, password: str) -> dict:
        response = supabase.auth.sign_in_with_password({"email": email, "password": password})
        
        user_dict = response.user.model_dump() if hasattr(response.user, 'model_dump') else response.user.__dict__
        meta = user_dict.get("user_metadata", {})
        app_meta = user_dict.get("app_metadata", {})
        
        role = meta.get("role") or app_meta.get("role")
        
        if not role:
            try:
                user_res = supabase.table("customers").select("*").eq("id", response.user.id).execute()
                if user_res.data:
                    row = user_res.data[0]
                    role = row.get("role")
                    user_dict.update(row)
                else:
                    # [LAZY-CREATE] If row is missing but user exists, try to recreate it from metadata
                    print(f"DEBUG: Customers row missing for {response.user.id}, attempting lazy create.")
                    supabase.table("customers").insert({
                        "id": response.user.id,
                        "email": email,
                        "username": meta.get("username", email.split('@')[0]),
                        "first_name": meta.get("first_name", ""),
                        "last_name": meta.get("last_name", ""),
                        "phone": meta.get("phone", ""),
                        "role": "customer"
                    }).execute()
                    role = "customer"
            except Exception as e:
                print(f"DEBUG: Customer DB lookup/lazy-create failed: {e}")
                pass
        
        # [SOLID: Robustness] Flatten user_metadata into top-level user_dict 
        # so frontend mapUserData can find fields if DB row is missing.
        for k, v in meta.items():
            if k not in user_dict or user_dict[k] is None:
                user_dict[k] = v
        for k, v in app_meta.items():
            if k not in user_dict or user_dict[k] is None:
                user_dict[k] = v
        
        # Add phone_number alias for extra safety with frontend bindings
        if "phone" in user_dict:
            user_dict["phone_number"] = user_dict["phone"]
                
        if not role:
            role = "admin" if "admin" in email.lower() or "staff" in email.lower() else "customer"
        
        user_dict["role"] = role

        return {
            "user": user_dict,
            "session": response.session,
            "access_token": response.session.access_token,
        }

    @staticmethod
    def customer_signup(email: str, password: str, username: str = "", first_name: str = "", last_name: str = "", phone: str = "") -> dict:
        response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "username": username,
                    "first_name": first_name,
                    "last_name": last_name,
                    "phone": phone,
                }
            }
        })
        
        # Explicitly create the database row if the application has no trigger
        if response.user:
            try:
                supabase.table("customers").insert({
                    "id": response.user.id,
                    "email": email,
                    "username": username,
                    "first_name": first_name,
                    "last_name": last_name,
                    "phone": phone,
                    "role": "customer"
                }).execute()
            except Exception as e:
                print(f"DEBUG: Customer DB Insert failed: {e}")
                pass

        return {"user": response.user, "status": "Confirm email if enabled"}
