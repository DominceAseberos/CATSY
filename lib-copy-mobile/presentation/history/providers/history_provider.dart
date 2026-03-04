import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/providers.dart';
import '../../../data/local/database/app_database.dart';
import '../../../domain/models/daily_summary.dart';

// ── Filter Preset ─────────────────────────────────────────────────────────────

enum DatePreset { today, yesterday, thisWeek, custom }

extension DatePresetExt on DatePreset {
  String get label {
    switch (this) {
      case DatePreset.today:
        return 'Today';
      case DatePreset.yesterday:
        return 'Yesterday';
      case DatePreset.thisWeek:
        return 'This Week';
      case DatePreset.custom:
        return 'Custom';
    }
  }

  (DateTime, DateTime) get range {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (this) {
      case DatePreset.today:
        return (todayStart, todayStart.add(const Duration(days: 1)));
      case DatePreset.yesterday:
        final yStart = todayStart.subtract(const Duration(days: 1));
        return (yStart, todayStart);
      case DatePreset.thisWeek:
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return (weekStart, todayStart.add(const Duration(days: 1)));
      case DatePreset.custom:
        // Placeholder; overridden by setCustomRange.
        return (todayStart, todayStart.add(const Duration(days: 1)));
    }
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class HistoryState {
  final DatePreset preset;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String searchQuery;
  final bool isLoading;
  final List<OrdersTableData> orders;
  final bool hasMore;
  final int page;

  const HistoryState({
    required this.preset,
    required this.dateFrom,
    required this.dateTo,
    this.searchQuery = '',
    this.isLoading = false,
    this.orders = const [],
    this.hasMore = true,
    this.page = 0,
  });

  HistoryState copyWith({
    DatePreset? preset,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchQuery,
    bool? isLoading,
    List<OrdersTableData>? orders,
    bool? hasMore,
    int? page,
  }) {
    return HistoryState(
      preset: preset ?? this.preset,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HistoryNotifier extends Notifier<HistoryState> {
  static const _pageSize = 20;

  @override
  HistoryState build() {
    final (from, to) = DatePreset.today.range;
    final initial = HistoryState(
      preset: DatePreset.today,
      dateFrom: from,
      dateTo: to,
    );
    // Kick off the first load after the notifier is built.
    Future.microtask(() => _load(reset: true));
    return initial;
  }

  // ── Public API ──────────────────────────────────────────────────────

  void setPreset(DatePreset preset) {
    if (preset == DatePreset.custom) return;
    final (from, to) = preset.range;
    state = state.copyWith(
      preset: preset,
      dateFrom: from,
      dateTo: to,
      orders: [],
      page: 0,
      hasMore: true,
    );
    _load(reset: true);
  }

  void setCustomRange(DateTime from, DateTime to) {
    final toEndOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
    state = state.copyWith(
      preset: DatePreset.custom,
      dateFrom: from,
      dateTo: toEndOfDay,
      orders: [],
      page: 0,
      hasMore: true,
    );
    _load(reset: true);
  }

  void setSearch(String query) {
    state = state.copyWith(
      searchQuery: query,
      orders: [],
      page: 0,
      hasMore: true,
    );
    _load(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await _load(reset: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(orders: [], page: 0, hasMore: true);
    await _load(reset: true);
  }

  // ── Internal ─────────────────────────────────────────────────────────

  Future<void> _load({required bool reset}) async {
    state = state.copyWith(isLoading: true);
    final page = reset ? 0 : state.page;
    final dao = ref.read(orderDaoProvider);

    try {
      final rows = await dao.getCompletedOrders(
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
        limit: _pageSize,
        offset: page * _pageSize,
      );

      final combined = reset ? rows : [...state.orders, ...rows];
      state = state.copyWith(
        isLoading: false,
        orders: combined,
        hasMore: rows.length >= _pageSize,
        page: page + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final historyNotifierProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);

/// Daily summary for the currently selected filter date range.
final dailySummaryProvider = FutureProvider.autoDispose<DailySummary>((
  ref,
) async {
  final filter = ref.watch(historyNotifierProvider);
  final txDao = ref.watch(transactionDaoProvider);
  final orderDao = ref.watch(orderDaoProvider);

  final summary = await txDao.getDailySummary(filter.dateFrom);
  final byMethod = await txDao.getDailySummaryByPaymentMethod(filter.dateFrom);

  final orders = await orderDao.getCompletedOrders(
    dateFrom: filter.dateFrom,
    dateTo: filter.dateTo,
  );

  return DailySummary(
    totalSales: summary.totalSales,
    orderCount: orders.length,
    byPaymentMethod: byMethod,
  );
});
