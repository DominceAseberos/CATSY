from typing import Optional
from app.repositories.orders_repo import OrderRepository
from app.utils.audit_logger import AuditLogger

class OrderService:
    def __init__(self, order_repo: OrderRepository):
        self.repo = order_repo

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
            
            # TODO: Deduct from inventory here via an injected Product/InventoryService or Repos
            # Example: self.inventory_service.deduct(product_id, quantity)
            
        if items_data:
            self.repo.add_order_items(items_data)
            
        # Update order total
        self.repo.update(order_id, {"total_amount": total_amount})
        
        AuditLogger.log_action("CREATE", "order", order_id, user_id, {"total_amount": total_amount})
        return {"id": order_id, "total_amount": total_amount}

    def modify_order(self, order_id: str, order_data: dict, user_id: Optional[str] = None):
        return self.repo.update(order_id, order_data)

    def pay_order(self, order_id: str, user_id: Optional[str] = None):
        response = self.repo.update(order_id, {"payment_status": "paid", "status": "completed"})
        if response:
            AuditLogger.log_action("UPDATE", "order_payment", order_id, user_id, {"status": "paid"})
        return response

    def void_order(self, order_id: str, user_id: Optional[str] = None):
        response = self.repo.update(order_id, {"payment_status": "voided", "status": "cancelled"})
        if response:
            AuditLogger.log_action("UPDATE", "order_void", order_id, user_id, {"status": "voided"})
        return response

    def refund_order(self, order_id: str, user_id: Optional[str] = None):
        response = self.repo.update(order_id, {"payment_status": "refunded", "status": "cancelled"})
        if response:
            AuditLogger.log_action("UPDATE", "order_refund", order_id, user_id, {"status": "refunded"})
        return response
        
    def get_orders(self, limit: int = 50, offset: int = 0):
        return self.repo.get_all(limit=limit, offset=offset)
