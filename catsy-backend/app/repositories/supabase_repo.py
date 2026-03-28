"""
Supabase Repository (Deprecated)
===============================

What:
    Formerly provided generic Supabase data access.

How:
    Deprecated in favor of domain-specific repositories for each table or feature.

When:
    Should not be used; replaced by injected repositories in routers and services.

What it does:
    - No longer provides any functionality
    - Raises NotImplementedError if instantiated
    - Serves as a migration note for legacy code
"""

class SupabaseRepository:
    def __init__(self):
        raise NotImplementedError("SupabaseRepository is deprecated. Use injected domain repositories.")
