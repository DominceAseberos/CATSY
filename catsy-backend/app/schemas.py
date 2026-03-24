from pydantic import BaseModel
from typing import Optional

class CategoryResponse(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool

class ProductResponse(BaseModel):
    product_id: int
    category_id: Optional[int] = None
    category: Optional[str] = "Uncategorized"
    name: str
    description: Optional[str] = None
    base_price: float
    image_url: Optional[str] = None
    is_available: bool
    is_popular: bool

    class Config:
        from_attributes = True

class ProductCreate(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    base_price: float
    image_url: Optional[str] = None
    is_available: bool = True
    is_popular: bool = False

class ProductUpdate(BaseModel):
    category_id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    base_price: Optional[float] = None
    image_url: Optional[str] = None
    is_available: Optional[bool] = None
    is_popular: Optional[bool] = None

class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool = True

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None

class ReservationStatusUpdate(BaseModel):
    status: str
