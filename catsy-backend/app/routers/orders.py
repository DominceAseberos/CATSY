"""Orders router — Staff management of orders (dine-in/take-out, pay-now/pay-later)."""
from fastapi import APIRouter, HTTPException, Request, Depends, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.dependencies import get_order_service
from app.services.order_service import OrderService
from app.schemas import OrderCreate, OrderUpdate, OrderPaymentStatusUpdate
from app.auth import get_current_user

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/api/staff/orders", tags=["Orders"])

@router.post("")
@limiter.limit("50/minute")
def create_order(request: Request, order: OrderCreate, user=Depends(get_current_user), service: OrderService = Depends(get_order_service)):
    try:
        return service.create_order(order.dict(), user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{order_id}")
@limiter.limit("20/minute")
def modify_order(request: Request, order_id: str, order: OrderUpdate, user=Depends(get_current_user), service: OrderService = Depends(get_order_service)):
    try:
        return service.modify_order(order_id, order.dict(exclude_unset=True), user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{order_id}/pay")
@limiter.limit("20/minute")
def pay_order(request: Request, order_id: str, user=Depends(get_current_user), service: OrderService = Depends(get_order_service)):
    try:
        return service.pay_order(order_id, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{order_id}/void")
@limiter.limit("10/minute")
def void_order(request: Request, order_id: str, user=Depends(get_current_user), service: OrderService = Depends(get_order_service)):
    try:
        return service.void_order(order_id, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{order_id}/refund")
@limiter.limit("10/minute")
def refund_order(request: Request, order_id: str, user=Depends(get_current_user), service: OrderService = Depends(get_order_service)):
    try:
        return service.refund_order(order_id, user_id=str(user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("")
@limiter.limit("100/minute")
def get_orders(
    request: Request,
    limit: int = Query(50, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    user=Depends(get_current_user),
    service: OrderService = Depends(get_order_service)
):
    try:
        return service.get_orders(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
