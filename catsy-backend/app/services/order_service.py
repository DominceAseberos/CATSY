"""
OrderService — fixed version.

Changes:
  1. ProductRepository is now always injected — no silent self-construction.
     Callers that don't pass one will get a clear TypeError instead of a
     hidden internal instance that can't be mocked in tests.
  2. Duplicated stock-restore block extracted to _restore_items_stock().
  3. Order status strings centralised as module-level constants.
"""
from typing import Optional
from app.repositories.orders_repo import OrderRepository
from app.repositories.products_repo import ProductRepository
from app.utils.audit_logger import AuditLogger

# ── Status constants — change once, applies everywhere ────────────────────────
STATUS_PENDING = "pending"
STATUS_COMPLETED = "completed"
STATUS_CANCELLED = "cancelled"
PAYMENT_UNPAID = "unpaid"
PAYMENT_PAID = "paid"
PAYMENT_VOIDED = "voided"
PAYMENT_REFUNDED = "refunded"

VALID_PAYMENT_METHODS = {"Cash", "GCash", "Maya"}


class OrderService:

    def __init__(self, order_repo: OrderRepository, product_repo: ProductRepository):
        # Both repos required — no silent fallback construction
        self.repo = order_repo
        self.product_repo = product_repo

    # ── Private helpers ───────────────────────────────────────────────────────

    def _restore_items_stock(self, order: dict) -> None:
        """Restore inventory for every item in an order. Non-fatal."""
        for item in order.get("order_items", []):
            try:
                self.product_repo.restore_stock(
                    item.get("product_id"), item.get("quantity", 1)
                )
            except Exception:
                pass  # log in production; never block void/refund

    # ── Public methods ────────────────────────────────────────────────────────

    def create_order(self, order_data: dict, user_id: Optional[str] = None) -> dict:
        items = order_data.pop("items", [])
        order_to_create = {
            "order_type": order_data.get("order_type"),
            "payment_status": order_data.get("payment_status", PAYMENT_UNPAID),
            "status": (
                STATUS_COMPLETED
                if order_data.get("payment_status") == PAYMENT_PAID
                else STATUS_PENDING
            ),
            "cashier_id": user_id,
        }

        order_res = self.repo.create(order_to_create)
        if not order_res:
            raise Exception("Failed to create order")

        order_id = order_res[0]["id"]
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
                "price_at_time": price,
            })
            try:
                self.product_repo.deduct_stock(product_id, quantity)
            except Exception:
                pass

        if items_data:
            self.repo.add_order_items(items_data)

        self.repo.update(order_id, {"total_amount": total_amount})
        AuditLogger.log_action("CREATE", "order", order_id, user_id, {"total_amount": total_amount})
        return {"id": order_id, "total_amount": total_amount}

    def modify_order(self, order_id: str, order_data: dict, user_id: Optional[str] = None):
        return self.repo.update(order_id, order_data)

    def pay_order(
        self,
        order_id: str,
        payment_method: str,
        amount_tendered: float,
        user_id: Optional[str] = None,
    ) -> dict:
        if payment_method not in VALID_PAYMENT_METHODS:
            raise ValueError(
                f"Invalid payment_method. Must be one of: {', '.join(VALID_PAYMENT_METHODS)}"
            )

        order = self.repo.get_by_id(order_id)
        if not order:
            raise ValueError("Order not found")

        total = float(order.get("total_amount", 0))
        if payment_method == "Cash" and amount_tendered < total:
            raise ValueError(
                f"Amount tendered (₱{amount_tendered:.2f}) is less than total (₱{total:.2f})"
            )

        change_due = round(amount_tendered - total, 2) if payment_method == "Cash" else 0.0
        update_data = {
            "payment_status": PAYMENT_PAID,
            "status": STATUS_COMPLETED,
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
        order = self.repo.get_by_id(order_id)
        if order:
            self._restore_items_stock(order)  # <-- no more duplication
        response = self.repo.update(
            order_id, {"payment_status": PAYMENT_VOIDED, "status": STATUS_CANCELLED}
        )
        if response:
            AuditLogger.log_action("UPDATE", "order_void", order_id, user_id, {"status": PAYMENT_VOIDED})
        return response

    def refund_order(self, order_id: str, user_id: Optional[str] = None):
        order = self.repo.get_by_id(order_id)
        if order:
            self._restore_items_stock(order)  # <-- same helper, not a copy
        response = self.repo.update(
            order_id, {"payment_status": PAYMENT_REFUNDED, "status": STATUS_CANCELLED}
        )
        if response:
            AuditLogger.log_action("UPDATE", "order_refund", order_id, user_id, {"status": PAYMENT_REFUNDED})
        return response

    def get_orders(self, limit: int = 50, offset: int = 0, status: Optional[str] = None):
        return self.repo.get_all(limit=limit, offset=offset, status=status)