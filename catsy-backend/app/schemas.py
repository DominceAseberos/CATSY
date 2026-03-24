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
