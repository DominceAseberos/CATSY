"""
Application-level constants and defaults.
Centralises all hardcoded configuration so route handlers stay thin.
"""

# Default values merged with live DB settings before returning to clients.
# Extend this dict when new settings fields are added — routes don't need to change.
DEFAULT_SETTINGS = {
    "theme": "dark",
    "maintenance_mode": False,
    "store_status": "open",
    "currency": "PHP",
    "is_open": True,
    "opening_time": "08:00",
    "closing_time": "22:00",
    "available_tables": 0,
    "total_tables": 0,
}
