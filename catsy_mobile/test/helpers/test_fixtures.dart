import 'package:drift/drift.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';

/// Factory methods producing realistic Drift Companion objects for all tables.
///
/// Uses deterministic IDs so test assertions can reference known values.
class TestFixtures {
  TestFixtures._();

  static final _now = DateTime(2026, 3, 7, 12, 0, 0);

  // ── Categories ────────────────────────────────────────────────────────

  static CategoriesTableCompanion category({
    String id = 'cat-001',
    String name = 'Coffee',
    int sortOrder = 0,
  }) => CategoriesTableCompanion(
    id: Value(id),
    name: Value(name),
    sortOrder: Value(sortOrder),
    createdAt: Value(_now),
  );

  // ── Products ──────────────────────────────────────────────────────────

  static ProductsTableCompanion product({
    String id = 'prod-001',
    String name = 'Latte',
    double price = 150.0,
    String categoryId = 'cat-001',
    bool isAvailable = true,
  }) => ProductsTableCompanion(
    id: Value(id),
    name: Value(name),
    price: Value(price),
    categoryId: Value(categoryId),
    isAvailable: Value(isAvailable),
    createdAt: Value(_now),
    updatedAt: Value(_now),
  );

  // ── Orders ────────────────────────────────────────────────────────────

  static OrdersTableCompanion order({
    String id = 'order-001',
    String staffId = 'staff-001',
    String? tableId,
    String? customerId,
    String orderType = 'dineIn',
    String status = 'pending',
    String paymentStatus = 'pending',
    String? paymentMethod,
    double subtotal = 300.0,
    double tax = 0.0,
    double discount = 0.0,
    double total = 300.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OrdersTableCompanion(
    id: Value(id),
    staffId: Value(staffId),
    tableId: tableId != null ? Value(tableId) : const Value.absent(),
    customerId: customerId != null ? Value(customerId) : const Value.absent(),
    orderType: Value(orderType),
    status: Value(status),
    paymentStatus: Value(paymentStatus),
    paymentMethod: paymentMethod != null
        ? Value(paymentMethod)
        : const Value.absent(),
    subtotal: Value(subtotal),
    tax: Value(tax),
    discount: Value(discount),
    total: Value(total),
    createdAt: Value(createdAt ?? _now),
    updatedAt: Value(updatedAt ?? _now),
  );

  // ── Order Items ───────────────────────────────────────────────────────

  static OrderItemsTableCompanion orderItem({
    String id = 'oi-001',
    String orderId = 'order-001',
    String productId = 'prod-001',
    String productName = 'Latte',
    int quantity = 2,
    double unitPrice = 150.0,
    double totalPrice = 300.0,
  }) => OrderItemsTableCompanion(
    id: Value(id),
    orderId: Value(orderId),
    productId: Value(productId),
    productName: Value(productName),
    quantity: Value(quantity),
    unitPrice: Value(unitPrice),
    totalPrice: Value(totalPrice),
  );

  // ── Order Item Addons ─────────────────────────────────────────────────

  static OrderItemAddonsTableCompanion orderItemAddon({
    String id = 'oia-001',
    String orderItemId = 'oi-001',
    String addonId = 'addon-001',
    String addonName = 'Extra Shot',
    double price = 30.0,
  }) => OrderItemAddonsTableCompanion(
    id: Value(id),
    orderItemId: Value(orderItemId),
    addonId: Value(addonId),
    addonName: Value(addonName),
    price: Value(price),
  );

  // ── Inventory ─────────────────────────────────────────────────────────

  static InventoryTableCompanion inventoryItem({
    String id = 'inv-001',
    String productId = 'prod-001',
    String productName = 'Latte',
    int currentStock = 50,
    int minStock = 10,
    String unit = 'pcs',
  }) => InventoryTableCompanion(
    id: Value(id),
    productId: Value(productId),
    productName: Value(productName),
    currentStock: Value(currentStock),
    minStock: Value(minStock),
    unit: Value(unit),
    lastRestocked: Value(_now),
  );

  // ── Customers ─────────────────────────────────────────────────────────

  static CustomersTableCompanion customer({
    String id = 'cust-001',
    String name = 'Maria Santos',
    String? email = 'maria@example.com',
    String? phone = '0912-345-6789',
    String? qrCode = 'QR-CUST-001',
    int totalStamps = 0,
    int rewardsRedeemed = 0,
  }) => CustomersTableCompanion(
    id: Value(id),
    name: Value(name),
    email: email != null ? Value(email) : const Value.absent(),
    phone: phone != null ? Value(phone) : const Value.absent(),
    qrCode: qrCode != null ? Value(qrCode) : const Value.absent(),
    totalStamps: Value(totalStamps),
    rewardsRedeemed: Value(rewardsRedeemed),
    createdAt: Value(_now),
    updatedAt: Value(_now),
  );

  // ── Loyalty Stamps ────────────────────────────────────────────────────

  static LoyaltyStampsTableCompanion stampLog({
    String id = 'stamp-001',
    String customerId = 'cust-001',
    String orderId = 'order-001',
    String staffId = 'staff-001',
    int stampsAdded = 1,
  }) => LoyaltyStampsTableCompanion(
    id: Value(id),
    customerId: Value(customerId),
    orderId: Value(orderId),
    staffId: Value(staffId),
    stampsAdded: Value(stampsAdded),
    createdAt: Value(_now),
  );

  // ── Reservations ──────────────────────────────────────────────────────

  static ReservationsTableCompanion reservation({
    String id = 'res-001',
    String customerName = 'Juan Cruz',
    String? customerPhone = '0917-111-2222',
    String? tableId,
    int partySize = 4,
    DateTime? reservationDate,
    DateTime? reservationTime,
    String status = 'pending',
    String? notes,
  }) => ReservationsTableCompanion(
    id: Value(id),
    customerName: Value(customerName),
    customerPhone: customerPhone != null
        ? Value(customerPhone)
        : const Value.absent(),
    tableId: tableId != null ? Value(tableId) : const Value.absent(),
    partySize: Value(partySize),
    reservationDate: Value(reservationDate ?? _now),
    reservationTime: Value(
      reservationTime ?? _now.add(const Duration(hours: 2)),
    ),
    status: Value(status),
    notes: notes != null ? Value(notes) : const Value.absent(),
    createdAt: Value(_now),
    updatedAt: Value(_now),
  );

  // ── Cafe Tables ───────────────────────────────────────────────────────

  static CafeTablesTableCompanion cafeTable({
    String id = 'table-001',
    String label = 'Table 1',
    int capacity = 4,
    String status = 'available',
    String? currentOrderId,
  }) => CafeTablesTableCompanion(
    id: Value(id),
    label: Value(label),
    capacity: Value(capacity),
    status: Value(status),
    currentOrderId: currentOrderId != null
        ? Value(currentOrderId)
        : const Value.absent(),
  );

  // ── Rewards ───────────────────────────────────────────────────────────

  static RewardsTableCompanion reward({
    String id = 'reward-001',
    String name = 'Free Coffee',
    String? description = 'One free coffee of any size',
    int stampsRequired = 10,
    bool isActive = true,
    String? code = 'REWARD-ABC123',
    String? customerId,
    bool isClaimed = false,
    String? claimedByStaffId,
    DateTime? claimedAt,
  }) => RewardsTableCompanion(
    id: Value(id),
    name: Value(name),
    description: description != null
        ? Value(description)
        : const Value.absent(),
    stampsRequired: Value(stampsRequired),
    isActive: Value(isActive),
    createdAt: Value(_now),
    code: code != null ? Value(code) : const Value.absent(),
    customerId: customerId != null ? Value(customerId) : const Value.absent(),
    isClaimed: Value(isClaimed),
    claimedByStaffId: claimedByStaffId != null
        ? Value(claimedByStaffId)
        : const Value.absent(),
    claimedAt: claimedAt != null ? Value(claimedAt) : const Value.absent(),
  );

  // ── Sync Queue ────────────────────────────────────────────────────────

  static SyncQueueTableCompanion syncQueueEntry({
    String id = 'sq-001',
    String targetTable = 'orders',
    String entityId = 'order-001',
    String action = 'INSERT',
    String payload = '{"id":"order-001"}',
    String status = 'pending',
    int priority = 0,
    int retryCount = 0,
    DateTime? createdAt,
    DateTime? lastAttempt,
  }) => SyncQueueTableCompanion(
    id: Value(id),
    targetTable: Value(targetTable),
    entityId: Value(entityId),
    action: Value(action),
    payload: Value(payload),
    status: Value(status),
    priority: Value(priority),
    retryCount: Value(retryCount),
    createdAt: Value(createdAt ?? _now),
    lastAttempt: lastAttempt != null
        ? Value(lastAttempt)
        : const Value.absent(),
  );
}
