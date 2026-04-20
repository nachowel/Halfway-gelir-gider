import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/route_access.dart';
import '../../core/auth/session_controller.dart';
import '../../data/app_models.dart';
import '../../data/app_repository.dart';

final refreshKeyProvider = StateProvider<int>((ref) => 0);

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final giderRepositoryProvider = Provider<GiderRepository>(
  (ref) => GiderRepository(ref.watch(supabaseClientProvider)),
);

final sessionControllerProvider = Provider<SessionController>(
  (ref) => SessionController(ref.watch(supabaseClientProvider)),
);

final authStateProvider = StreamProvider<AppAuthUser?>(
  (ref) => ref.watch(sessionControllerProvider).authStateChanges(),
);

final authRoutingStatusProvider = Provider<AppAuthRoutingStatus>((ref) {
  final AsyncValue<AppAuthUser?> authState = ref.watch(authStateProvider);
  return authState.when(
    data: (AppAuthUser? user) => user == null
        ? AppAuthRoutingStatus.unauthenticated
        : AppAuthRoutingStatus.authenticated,
    loading: () => AppAuthRoutingStatus.loading,
    error: (_, __) => AppAuthRoutingStatus.unauthenticated,
  );
});

final businessSettingsBootstrapStatusProvider =
    Provider<BusinessSettingsBootstrapStatus>((ref) {
      final AppAuthRoutingStatus authStatus = ref.watch(
        authRoutingStatusProvider,
      );
      if (authStatus != AppAuthRoutingStatus.authenticated) {
        return BusinessSettingsBootstrapStatus.complete;
      }

      final AsyncValue<BusinessSettingsData> settingsState = ref.watch(
        businessSettingsProvider,
      );
      return settingsState.when(
        data: (BusinessSettingsData data) => data.isBootstrapComplete
            ? BusinessSettingsBootstrapStatus.complete
            : BusinessSettingsBootstrapStatus.required,
        loading: () => BusinessSettingsBootstrapStatus.loading,
        error: (_, __) => BusinessSettingsBootstrapStatus.error,
      );
    });

final businessSettingsProvider = FutureProvider<BusinessSettingsData>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref.watch(giderRepositoryProvider).fetchBusinessSettings();
});

final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref.watch(giderRepositoryProvider).fetchDashboardSnapshot();
});

final reportsSnapshotProvider = FutureProvider<ReportsSnapshot>((ref) async {
  ref.watch(refreshKeyProvider);
  return ref
      .watch(giderRepositoryProvider)
      .fetchReportsSnapshot(DateTime.now());
});

final recurringItemsProvider = FutureProvider<List<RecurringUiItem>>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref.watch(giderRepositoryProvider).fetchRecurringUiItems();
});

final recurringSummaryProvider = FutureProvider<RecurringSummarySnapshot>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref
      .watch(giderRepositoryProvider)
      .fetchRecurringSummary(DateTime.now());
});

final incomeCategoriesProvider = FutureProvider<List<CategoryData>>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref
      .watch(giderRepositoryProvider)
      .fetchCategories(CategoryType.income);
});

final expenseCategoriesProvider = FutureProvider<List<CategoryData>>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref
      .watch(giderRepositoryProvider)
      .fetchCategories(CategoryType.expense);
});

enum TransactionsFilter { thisWeek, all, expense, income, card, cash }

final transactionsProvider =
    FutureProvider.family<List<TransactionData>, TransactionsFilter>((
      ref,
      filter,
    ) async {
      ref.watch(refreshKeyProvider);
      final GiderRepository repository = ref.watch(giderRepositoryProvider);
      switch (filter) {
        case TransactionsFilter.thisWeek:
          final DateTime now = DateTime.now();
          final DateTime start = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1));
          final DateTime end = start.add(const Duration(days: 6));
          return repository.fetchTransactions(start: start, end: end);
        case TransactionsFilter.all:
          return repository.fetchTransactions();
        case TransactionsFilter.expense:
          return repository.fetchTransactions(type: TransactionType.expense);
        case TransactionsFilter.income:
          return repository.fetchTransactions(type: TransactionType.income);
        case TransactionsFilter.card:
          return repository.fetchTransactions(
            paymentMethod: PaymentMethodType.card,
          );
        case TransactionsFilter.cash:
          return repository.fetchTransactions(
            paymentMethod: PaymentMethodType.cash,
          );
      }
    });
