import 'package:drift/drift.dart';
import 'package:catsy_pos/domain/entities/order.dart';
import 'package:catsy_pos/domain/entities/order_item.dart';
import 'package:catsy_pos/domain/models/cart_state.dart';
import 'package:catsy_pos/domain/models/payment_details.dart';
import 'package:catsy_pos/domain/repositories/order_repository.dart';
import 'package:catsy_pos/domain/enums/order_status.dart';
import 'package:catsy_pos/domain/enums/payment_status.dart';
import 'package:catsy_pos/domain/enums/order_type.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';
import 'package:catsy_pos/data/local/database/daos/order_dao.dart';
import 'package:catsy_pos/data/local/database/daos/inventory_dao.dart';
import 'package:catsy_pos/data/local/database/daos/transaction_dao.dart';
import 'package:catsy_pos/data/local/database/daos/receipt_dao.dart';
import 'package:uuid/uuid.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderDao _orderDao;
  final InventoryDao _inventoryDao;
  final TransactionDao _transactionDao;
  final ReceiptDao _receiptDao;
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  OrderRepositoryImpl(
    this._orderDao,
    this._inventoryDao,
    this._transactionDao,
    this._receiptDao,
    this._db,
  );

  @override
  Stream<List<Order>> watchActiveOrders() {
    return _orderDao.watchActiveOrders().map(
      (rows) => rows.map((r) => _mapOrder(r)).toList(),
    );
  }

  @override
  Future<Order> createOrder(CartState cart, PaymentDetails payment) async {
    return _db.transaction(() async {
      // 1. Generate Order Number
      final orderNumber = await _orderDao.generateOrderNumber();
      final now = DateTime.now();

      // 2. Create Order Entity
      // Note: We are using the generated ID for internal storage,
      final usedOrderId = orderNumber; // Using readable ID

      // Map CartItems to OrderItems
      final orderItems = <OrderItem>[];
      final orderItemCompanions = <OrderItemsTableCompanion>[];
      final addonCompanions = <OrderItemAddonsTableCompanion>[];

      for (final cartItem in cart.items) {
        final orderItemId = _uuid.v4();
        final itemTotal = cartItem.totalPrice;

        orderItems.add(
          OrderItem(
            id: orderItemId,
            orderId: usedOrderId,
            productId: cartItem.product.id,
            productName: cartItem.product.name,
            quantity: cartItem.quantity,
            unitPrice: cartItem.product.price,
            totalPrice: itemTotal,
            addons: cartItem.addons,
            specialInstructions: cartItem.notes,
          ),
        );

        orderItemCompanions.add(
          OrderItemsTableCompanion(
            id: Value(orderItemId),
            orderId: Value(usedOrderId),
            productId: Value(cartItem.product.id),
            productName: Value(cartItem.product.name),
            quantity: Value(cartItem.quantity),
            unitPrice: Value(cartItem.product.price),
            totalPrice: Value(itemTotal),
            specialInstructions: Value(cartItem.notes),
          ),
        );

        for (final addon in cartItem.addons) {
          addonCompanions.add(
            OrderItemAddonsTableCompanion(
              id: Value(_uuid.v4()),
              orderItemId: Value(orderItemId),
              addonId: Value(addon.id),
              addonName: Value(addon.name),
              price: Value(addon.price),
            ),
          );
        }
      }

      // 3. Insert Order
      final orderDTO = OrdersTableCompanion(
        id: Value(usedOrderId),
        tableId: Value(cart.tableId),
        staffId: const Value('current_staff_id'),
        customerId: Value(cart.customerId),
        orderType: Value(cart.orderType.name),
        status: const Value('completed'),
        paymentStatus: const Value('paid'),
        paymentMethod: Value(payment.method.name),
        subtotal: Value(cart.subtotal),
        tax: Value(cart.tax),
        discount: const Value(0.0),
        total: Value(cart.total),
        notes: Value(cart.notes),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await _orderDao.insertOrder(orderDTO);
      await _orderDao.insertOrderItems(orderItemCompanions);
      await _orderDao.insertOrderItemAddons(addonCompanions);

      // 4. Deduct Stock
      for (final item in orderItems) {
        await _inventoryDao.deductStock(item.productId, item.quantity);
      }

      // 5. Create Transaction Record
      await _transactionDao.insertTransaction(
        TransactionsTableCompanion(
          id: Value(_uuid.v4()),
          orderId: Value(usedOrderId),
          amount: Value(cart.total),
          paymentMethod: Value(payment.method.name),
          transactedAt: Value(now),
        ),
      );

      // 6. Generate Receipt
      final receiptNumber = await _receiptDao.generateReceiptNumber();
      await _receiptDao.insertReceipt(
        ReceiptsTableCompanion(
          id: Value(_uuid.v4()),
          orderId: Value(usedOrderId),
          receiptNumber: Value(receiptNumber),
          generatedAt: Value(now),
          content: const Value(''),
        ),
      );

      return Order(
        id: usedOrderId,
        tableId: cart.tableId,
        staffId: 'current_staff_id',
        customerId: cart.customerId,
        orderType: cart.orderType,
        status: OrderStatus.completed,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: payment.method,
        items: orderItems,
        subtotal: cart.subtotal,
        tax: cart.tax,
        discount: 0,
        total: cart.total,
        notes: cart.notes,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  Order _mapOrder(OrdersTableData r) {
    // Basic mapping, items need to be fetched separately if needed strictly,
    // but usually list view doesn't need items.
    // Use proper mapping logic.
    return Order(
      id: r.id,
      tableId: r.tableId,
      staffId: r.staffId,
      customerId: r.customerId,
      orderType: _parseOrderType(r.orderType),
      status: _parseOrderStatus(r.status),
      paymentStatus: _parsePaymentStatus(r.paymentStatus),
      // etc
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  OrderType _parseOrderType(String val) => OrderType.values.firstWhere(
    (e) => e.name == val,
    orElse: () => OrderType.dineIn,
  );
  OrderStatus _parseOrderStatus(String val) => OrderStatus.values.firstWhere(
    (e) => e.name == val,
    orElse: () => OrderStatus.pending,
  );
  PaymentStatus _parsePaymentStatus(String val) => PaymentStatus.values
      .firstWhere((e) => e.name == val, orElse: () => PaymentStatus.pending);
}
