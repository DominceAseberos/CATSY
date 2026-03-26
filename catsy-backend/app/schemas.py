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
    """Used for legacy void/refund status updates."""
    payment_status: str  # 'voided', 'refunded'

class OrderPayRequest(BaseModel):
    """Payload for POST /api/staff/orders/:id/pay (FR S5)."""
    payment_method: str  # 'Cash' | 'GCash' | 'Maya'
    amount_tendered: float

class PaymentReceiptResponse(BaseModel):
    """Response envelope returned after a successful payment (FR S5)."""
    order_id: str
    total: float
    payment_method: str
    amount_tendered: float
    change_due: float


# ── Customer Order History ────────────────────────────────────────────────────

class CustomerOrderResponse(BaseModel):
    """Compact order record for GET /api/customer/orders."""
    id: str
    order_type: Optional[str] = None
    payment_status: Optional[str] = None
    payment_method: Optional[str] = None
    total_amount: Optional[float] = None
    created_at: Optional[str] = None
    order_items: Optional[List[dict]] = []

    class Config:
        from_attributes = True


# ── Loyalty Redemption ────────────────────────────────────────────────────────

class RewardRedeemRequest(BaseModel):
    """Staff payload for POST /loyalty/staff/redeem — validates a coupon code."""
    coupon_code: str


# ── Phase 3: Time Slots ───────────────────────────────────────────────────────

class TimeSlotCreate(BaseModel):
    """Admin payload for POST /api/admin/time-slots."""
    time: str


# ── Phase 3: CMS ──────────────────────────────────────────────────────────────

class CMSCreate(BaseModel):
    """Admin payload for POST /api/admin/cms."""
    type: str  # 'banner' | 'announcement' | 'promo'
    title: str
    body: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool = True


class CMSUpdate(BaseModel):
    """Admin payload for PUT /api/admin/cms/:id — all fields optional (partial update)."""
    title: Optional[str] = None
    body: Optional[str] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None

# ── Phase 3: Materials & Inventory ──────────────────────────────────────────

class MaterialCreate(BaseModel):
    material_name: str
    material_unit: str = "unit"
    material_stock: float = 0
    material_reorder_level: float = 0
    cost_per_unit: float = 0

class MaterialUpdate(BaseModel):
    material_name: Optional[str] = None
    material_unit: Optional[str] = None
    material_stock: Optional[float] = None
    material_reorder_level: Optional[float] = None
    cost_per_unit: Optional[float] = None

class IngredientItem(BaseModel):
    material_id: int
    quantity_required: float

class RecipeUpsert(BaseModel):
    ingredients: List[IngredientItem]

