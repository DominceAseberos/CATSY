import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/customer.dart';

import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/dashboard/screens/dashboard_screen.dart';
import '../../presentation/reservation/screens/reservation_screen.dart';
import '../../presentation/table_management/screens/table_management_screen.dart';
import '../../presentation/order/screens/product_catalog_screen.dart';
import '../../presentation/order/screens/order_builder_screen.dart';
import '../../presentation/order/screens/order_summary_screen.dart';
import '../../presentation/order/screens/payment_screen.dart';
import '../../presentation/loyalty/screens/qr_scanner_screen.dart';
import '../../presentation/loyalty/screens/customer_search_screen.dart';
import '../../presentation/loyalty/screens/stamp_result_screen.dart';
import '../../presentation/reward/screens/claim_reward_screen.dart';
import '../../presentation/history/screens/order_history_screen.dart';
import '../../presentation/history/screens/transaction_detail_screen.dart';
import '../../presentation/inventory/screens/stock_overview_screen.dart';
import '../../presentation/receipt/screens/receipt_preview_screen.dart';
import 'route_names.dart';

/// GoRouter configuration for the entire CATSY POS app.
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Secure storage instance for session token checks.
  static const _storage = FlutterSecureStorage();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    // ── Auth Guard ──────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) async {
      final token = await _storage.read(key: 'auth_token');
      final isLoggedIn = token != null && token.isNotEmpty;
      final loc = state.matchedLocation;

      // Allow splash screen always
      if (loc == '/splash') return null;

      // Not logged in → force to login
      if (!isLoggedIn && loc != '/login') return '/login';

      // Already logged in → skip login screen
      if (isLoggedIn && loc == '/login') return '/dashboard';

      // Otherwise, allow navigation
      return null;
    },

    routes: [
      // ── Splash ───────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Dashboard ──────────────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      // ── Reservations ───────────────────────────────────────────────
      GoRoute(
        path: '/reservations',
        name: RouteNames.reservations,
        builder: (context, state) => const ReservationScreen(),
      ),

      // ── Table Management ───────────────────────────────────────────
      GoRoute(
        path: '/table-management',
        name: RouteNames.tableManagement,
        builder: (context, state) => const TableManagementScreen(),
      ),

      // ── Order Flow ─────────────────────────────────────────────────
      GoRoute(
        path: '/product-catalog',
        name: RouteNames.productCatalog,
        builder: (context, state) => const ProductCatalogScreen(),
      ),
      GoRoute(
        path: '/order-builder',
        name: RouteNames.orderBuilder,
        builder: (context, state) => const OrderBuilderScreen(),
      ),
      GoRoute(
        path: '/order-summary',
        name: RouteNames.orderSummary,
        builder: (context, state) => const OrderSummaryScreen(),
      ),
      GoRoute(
        path: '/payment',
        name: RouteNames.payment,
        builder: (context, state) => const PaymentScreen(),
      ),

      // ── Loyalty ────────────────────────────────────────────────────
      GoRoute(
        path: '/qr-scanner',
        name: RouteNames.qrScanner,
        builder: (context, state) {
          final order = state.extra as Order;
          return QrScannerScreen(order: order);
        },
      ),
      GoRoute(
        path: '/customer-search',
        name: RouteNames.customerSearch,
        builder: (context, state) => const CustomerSearchScreen(),
      ),
      GoRoute(
        path: '/stamp-result',
        name: RouteNames.stampResult,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return StampResultScreen(
            customer: extras['customer'] as Customer,
            order: extras['order'] as Order,
          );
        },
      ),
      /* Using Map for multiple args */

      // ── Reward ─────────────────────────────────────────────────────
      GoRoute(
        path: '/claim-reward',
        name: RouteNames.claimReward,
        builder: (context, state) => const ClaimRewardScreen(),
      ),

      // ── History ────────────────────────────────────────────────────
      GoRoute(
        path: '/order-history',
        name: RouteNames.orderHistory,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/transaction-detail',
        name: RouteNames.transactionDetail,
        builder: (context, state) {
          final orderId = state.extra as String;
          return TransactionDetailScreen(orderId: orderId);
        },
      ),

      // ── Inventory ──────────────────────────────────────────────────
      GoRoute(
        path: '/stock-overview',
        name: RouteNames.stockOverview,
        builder: (context, state) => const StockOverviewScreen(),
      ),

      // ── Receipt ────────────────────────────────────────────────────
      GoRoute(
        path: '/receipt-preview',
        name: RouteNames.receiptPreview,
        builder: (context, state) {
          final orderId = state.extra as String;
          return ReceiptPreviewScreen(orderId: orderId);
        },
      ),
    ],

    // ── Error / 404 ──────────────────────────────────────────────────
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
