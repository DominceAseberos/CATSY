"""
SupabaseRepository has been DEPRECATED as part of the SOLID Architecture Refactor.
Please use domain-specific repositories (e.g., OrderRepository, ProductRepository) 
and inject them into routers using `app.dependencies`.
"""

class SupabaseRepository:
    def __init__(self):
        raise NotImplementedError("SupabaseRepository is deprecated. Use injected domain repositories.")
