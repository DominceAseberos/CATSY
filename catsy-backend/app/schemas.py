"""
Pydantic DTOs — field names match the actual Supabase column names.
Use `alias` when the API response key differs from the DB column.
"""
from pydantic import BaseModel, Field
from typing import Optional


# ── Categories ──────────────────────────────────────────────────────────────

class CategoryResponse(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    created_at: Optional[str] = None
    linked_product_id: Optional[int] = None

    class Config:
        from_attributes = True


class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None


# ── Products ─────────────────────────────────────────────────────────────────

class ProductResponse(BaseModel):
    """Mirrors the actual `products` table column names exactly."""
    product_id: int
    category_id: Optional[int] = None
    category: Optional[str] = "Uncategorized"   # resolved via join in repo
    product_name: str
    product_price: float
    product_is_eligible: bool = False
    product_is_featured: bool = False
    product_is_available: bool = True
    product_is_reward: bool = False

    class Config:
        from_attributes = True


class ProductCreate(BaseModel):
    category_id: Optional[int] = None
    product_name: str
    product_price: float
    product_is_eligible: bool = False
    product_is_featured: bool = False
    product_is_available: bool = True
    product_is_reward: bool = False


class ProductUpdate(BaseModel):
    category_id: Optional[int] = None
    product_name: Optional[str] = None
    product_price: Optional[float] = None
    product_is_eligible: Optional[bool] = None
    product_is_featured: Optional[bool] = None
    product_is_available: Optional[bool] = None
    product_is_reward: Optional[bool] = None


# ── Reservations ─────────────────────────────────────────────────────────────

class ReservationStatusUpdate(BaseModel):
    status: str
# ── Orders ───────────────────────────────────────────────────────────────────

from typing import List

class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int
    price: float

class OrderCreate(BaseModel):
    order_type: str  # 'dine-in' or 'take-out'
    payment_status: str  # 'paid' or 'pending'
    items: List[OrderItemCreate]

class OrderUpdate(BaseModel):
    order_type: Optional[str] = None
    items: Optional[List[OrderItemCreate]] = None

class OrderPaymentStatusUpdate(BaseModel):
    payment_status: str # 'paid', 'voided', 'refunded'
