# ── Auth ─────────────────────────────────────────────────────────────────────

from typing import Optional
from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    password: str

class SignupRequest(BaseModel):
    email: str
    password: str
    username: str = ""
    firstName: str = ""
    lastName: str = ""
    phone: str = ""
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
    product_description: Optional[str] = None
    product_updated: Optional[str] = None

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
    payment_status: str  # 'unpaid' | 'paid' | 'voided' | 'refunded'
    payment_timing: str  # 'pay_now' | 'pay_later'
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
    order_type: Optional[str] = 'dine-in'
    payment_status: Optional[str] = 'unpaid'
    payment_method: Optional[str] = None
    total_amount: Optional[float] = 0
    created_at: Optional[str] = None
    order_items: Optional[List[dict]] = []

    class Config:
        from_attributes = True

class OrderResponse(BaseModel):
    """Full order record for staff/admin views (V2)."""
    id: str
    customer_id: Optional[str] = None
    status: str
    payment_status: str
    total_amount: float
    payment_method: Optional[str] = None
    amount_tendered: Optional[float] = None
    change_due: Optional[float] = None
    receipt_number: Optional[str] = None
    order_type: str
    payment_timing: str
    stamps_credited: bool = False
    refunded_at: Optional[str] = None
    refund_reason: Optional[str] = None
    created_at: str
    updated_at: str
    order_items: Optional[List[dict]] = []

    class Config:
        from_attributes = True

# ── User Profiles ─────────────────────────────────────────────────────────────

class UserProfileResponse(BaseModel):
    """V2 User Profile data."""
    id: str
    email: str
    role: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    contact: Optional[str] = None
    account_id: Optional[str] = None
    is_active: bool = True
    qr_code: Optional[str] = None
    excess_stamps: int = 0
    created_at: Optional[str] = None
    last_login: Optional[str] = None
    last_updated: Optional[str] = None

    class Config:
        from_attributes = True

# ── Settings ──────────────────────────────────────────────────────────────────

class SettingsResponse(BaseModel):
    """V2 Restaurant Settings."""
    is_open: bool
    opening_time: str
    closing_time: str
    total_seats: int
    updated_at: Optional[str] = None

    class Config:
        from_attributes = True


# ── Loyalty Redemption ────────────────────────────────────────────────────────

class RewardRedeemRequest(BaseModel):
    """Staff payload for POST /loyalty/staff/redeem — validates a coupon code."""
    coupon_code: str



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

