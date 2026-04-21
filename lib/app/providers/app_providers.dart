import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/route_access.dart';
import '../../core/auth/session_controller.dart';
import '../../data/app_models.dart';
import '../../data/app_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/local/outbox_repository.dart';
import '../../data/sync/conflict_policy.dart';
import '../../data/sync/sync_engine.dart';
import '../../data/sync/sync_service.dart';
import '../../features/expense_detail/domain/expense_detail_models.dart';
import '../../features/income_detail/domain/income_detail_models.dart';
import '../../features/net_profit_detail/domain/net_profit_detail_models.dart';
import '../../features/reports/domain/monthly_reports_models.dart';
import '../../features/reports/domain/monthly_reports_service.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_locale_storage.dart';
import '../../l10n/app_localizations.dart';

final refreshKeyProvider = StateProvider<int>((ref) => 0);

final appLocaleStorageProvider = Provider<AppLocaleStorage>(
  (ref) => InMemoryAppLocaleStorage(),
);

final appLocaleProvider = StateNotifierProvider<AppLocaleController, AppLocale>(
  (ref) => AppLocaleController(ref.watch(appLocaleStorageProvider)),
);

final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => AppLocalizations(ref.watch(appLocaleProvider)),
);

final overlayCoordinatorProvider =
    StateNotifierProvider<OverlayCoordinator, int>(
      (ref) => OverlayCoordinator(),
    );

final isOverlayOpenProvider = Provider<bool>(
  (ref) => ref.watch(overlayCoordinatorProvider) > 0,
);

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final outboxRepositoryProvider = Provider<OutboxRepository>(
  (ref) => OutboxRepository(ref.watch(appDatabaseProvider)),
);

final syncConflictPolicyProvider = Provider<SyncConflictPolicy>(
  (ref) => const SyncConflictPolicy(),
);

final connectivityProbeProvider = Provider<ConnectivityProbe>(
  (ref) => ConnectivityPlusProbe(),
);

final transactionSyncGatewayProvider = Provider<TransactionSyncGateway>(
  (ref) => SupabaseTransactionSyncGateway(ref.watch(supabaseClientProvider)),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    outboxRepository: ref.watch(outboxRepositoryProvider),
    transactionGateway: ref.watch(transactionSyncGatewayProvider),
    conflictPolicy: ref.watch(syncConflictPolicyProvider),
  ),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    engine: ref.watch(syncEngineProvider),
    connectivityProbe: ref.watch(connectivityProbeProvider),
  ),
);

final giderRepositoryProvider = Provider<GiderRepository>((ref) {
  // Web has no drift/sqlite backend in this build, so skip the local
  // outbox + sync layer and talk to Supabase directly. Native targets
  // keep the full offline-first pipeline.
  if (kIsWeb) {
    return GiderRepository(
      ref.watch(supabaseClientProvider),
      syncConflictPolicy: ref.watch(syncConflictPolicyProvider),
    );
  }
  return GiderRepository(
    ref.watch(supabaseClientProvider),
    outboxRepository: ref.watch(outboxRepositoryProvider),
    connectivityProbe: ref.watch(connectivityProbeProvider),
    syncService: ref.watch(syncServiceProvider),
    syncConflictPolicy: ref.watch(syncConflictPolicyProvider),
  );
});

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
  final AppLocalizations strings = ref.watch(appLocalizationsProvider);
  return ref.watch(giderRepositoryProvider).fetchDashboardSnapshot(strings);
});

final reportsServiceProvider = Provider<MonthlyReportsService>(
  (ref) => MonthlyReportsService(),
);

final selectedReportsMonthProvider = StateProvider<DateTime>((ref) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final reportsSnapshotProvider = FutureProvider<MonthlyReportsViewModel>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  final AppLocalizations strings = ref.watch(appLocalizationsProvider);
  final DateTime selectedMonth = ref.watch(selectedReportsMonthProvider);
  final MonthlyReportsDataset dataset = await ref
      .watch(giderRepositoryProvider)
      .fetchMonthlyReportsDataset(selectedMonth, trendMonthCount: 6);
  return ref.watch(reportsServiceProvider).buildViewModel(dataset, strings);
});

final incomeDetailProvider =
    FutureProvider.family<IncomeDetailViewModel, IncomeDetailQuery>((
      ref,
      query,
    ) async {
      ref.watch(refreshKeyProvider);
      final AppLocalizations strings = ref.watch(appLocalizationsProvider);
      return ref
          .watch(giderRepositoryProvider)
          .fetchIncomeDetail(query, strings);
    });

final expenseDetailProvider =
    FutureProvider.family<ExpenseDetailViewModel, ExpenseDetailQuery>((
      ref,
      query,
    ) async {
      ref.watch(refreshKeyProvider);
      final AppLocalizations strings = ref.watch(appLocalizationsProvider);
      return ref
          .watch(giderRepositoryProvider)
          .fetchExpenseDetail(query, strings);
    });

final netProfitDetailProvider =
    FutureProvider.family<NetProfitDetailViewModel, NetProfitDetailQuery>((
      ref,
      query,
    ) async {
      ref.watch(refreshKeyProvider);
      final AppLocalizations strings = ref.watch(appLocalizationsProvider);
      return ref
          .watch(giderRepositoryProvider)
          .fetchNetProfitDetail(query, strings);
    });

final recurringItemsProvider = FutureProvider<List<RecurringUiItem>>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  final AppLocalizations strings = ref.watch(appLocalizationsProvider);
  return ref.watch(giderRepositoryProvider).fetchRecurringUiItems(strings);
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

class OverlayCoordinator extends StateNotifier<int> {
  OverlayCoordinator() : super(0);

  void push() => state = state + 1;

  void pop() {
    if (state == 0) {
      return;
    }
    state = state - 1;
  }
}

class AppLocaleController extends StateNotifier<AppLocale> {
  AppLocaleController(this._storage) : super(_storage.load()) {
    Intl.defaultLocale = state.intlTag;
  }

  final AppLocaleStorage _storage;

  Future<void> setLocale(AppLocale locale) async {
    if (locale == state) {
      return;
    }
    state = locale;
    Intl.defaultLocale = locale.intlTag;
    await _storage.save(locale);
  }
}
