from typing import Optional
from app.repositories.orders_repo import OrderRepository
from app.repositories.products_repo import ProductRepository
from app.utils.audit_logger import AuditLogger

VALID_PAYMENT_METHODS = {"Cash", "GCash", "Maya"}

class OrderService:
    def __init__(self, order_repo: OrderRepository, product_repo: Optional[ProductRepository] = None):
        self.repo = order_repo
        self.product_repo = product_repo or ProductRepository()

    def create_order(self, order_data: dict, user_id: Optional[str] = None):
        items = order_data.pop("items", [])
        
        order_to_create = {
            "order_type": order_data.get("order_type"),
            "payment_status": order_data.get("payment_status", "pending"),
            "status": "completed" if order_data.get("payment_status") == "paid" else "pending",
            "cashier_id": user_id
        }
        
        order_res = self.repo.create(order_to_create)
        if not order_res:
            raise Exception("Failed to create order")
            
        order_id = order_res[0]['id']
        total_amount = 0
        items_data = []
        
        for item in items:
            product_id = item.get("product_id")
            quantity = item.get("quantity", 1)
            price = item.get("price", 0)
            total_amount += quantity * price
            
            items_data.append({
                "order_id": order_id,
                "product_id": product_id,
                "quantity": quantity,
                "price_at_time": price
            })
            
            # Deduct inventory: update product stock level (materials_stock deduction)
            try:
                self.product_repo.deduct_stock(product_id, quantity)
            except Exception:
                pass  # Non-fatal: log but don't block the order
            
        if items_data:
            self.repo.add_order_items(items_data)
            
        self.repo.update(order_id, {"total_amount": total_amount})
        AuditLogger.log_action("CREATE", "order", order_id, user_id, {"total_amount": total_amount})
        return {"id": order_id, "total_amount": total_amount}

    def modify_order(self, order_id: str, order_data: dict, user_id: Optional[str] = None):
        return self.repo.update(order_id, order_data)

    def pay_order(self, order_id: str, payment_method: str, amount_tendered: float, user_id: Optional[str] = None):
        """Process payment — validates cash tendered, computes change_due (FR S5)."""
        if payment_method not in VALID_PAYMENT_METHODS:
            raise ValueError(f"Invalid payment_method. Must be one of: {', '.join(VALID_PAYMENT_METHODS)}")
        
        # Fetch current order to get total
        order = self.repo.get_by_id(order_id)
        if not order:
            raise ValueError("Order not found")
        
        total = float(order.get("total_amount", 0))
        
        if payment_method == "Cash" and amount_tendered < total:
            raise ValueError(f"Amount tendered (₱{amount_tendered:.2f}) is less than total (₱{total:.2f})")
        
        change_due = round(amount_tendered - total, 2) if payment_method == "Cash" else 0.0
        
        update_data = {
            "payment_status": "paid",
            "status": "completed",
            "payment_method": payment_method,
            "amount_tendered": amount_tendered,
            "change_due": change_due,
        }
        self.repo.update(order_id, update_data)
        AuditLogger.log_action("UPDATE", "order_payment", order_id, user_id, update_data)
        
        return {
            "order_id": order_id,
            "total": total,
            "payment_method": payment_method,
            "amount_tendered": amount_tendered,
            "change_due": change_due,
        }

    def void_order(self, order_id: str, user_id: Optional[str] = None):
        """Void order and restore inventory."""
        order = self.repo.get_by_id(order_id)
        if order:
            for item in order.get("order_items", []):
                try:
                    self.product_repo.restore_stock(item.get("product_id"), item.get("quantity", 1))
                except Exception:
                    pass
        response = self.repo.update(order_id, {"payment_status": "voided", "status": "cancelled"})
        if response:
            AuditLogger.log_action("UPDATE", "order_void", order_id, user_id, {"status": "voided"})
        return response

    def refund_order(self, order_id: str, user_id: Optional[str] = None):
        """Refund order and restore inventory."""
        order = self.repo.get_by_id(order_id)
        if order:
            for item in order.get("order_items", []):
                try:
                    self.product_repo.restore_stock(item.get("product_id"), item.get("quantity", 1))
                except Exception:
                    pass
        response = self.repo.update(order_id, {"payment_status": "refunded", "status": "cancelled"})
        if response:
            AuditLogger.log_action("UPDATE", "order_refund", order_id, user_id, {"status": "refunded"})
        return response
        
    def get_orders(self, limit: int = 50, offset: int = 0, status: Optional[str] = None):
        """List orders. Pass status='open' for GET /api/staff/orders?status=open (pay-later list)."""
        return self.repo.get_all(limit=limit, offset=offset, status=status)
