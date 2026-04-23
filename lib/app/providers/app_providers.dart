import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/route_access.dart';
import '../../core/app_lock/app_lock_controller.dart';
import '../../core/app_lock/app_lock_models.dart';
import '../../core/app_lock/app_lock_settings_store.dart';
import '../../core/app_lock/local_auth_unlock_service.dart';
import '../../core/app_lock/secure_window_controller.dart';
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

final appLockSupportedPlatformProvider = Provider<bool>((ref) => !kIsWeb);

final appLockSettingsStoreProvider = Provider<AppLockSettingsStore>(
  (ref) => const SharedPreferencesAppLockSettingsStore(),
);

final appUnlockServiceProvider = Provider<AppUnlockService>((ref) {
  if (!ref.watch(appLockSupportedPlatformProvider)) {
    return const UnsupportedAppUnlockService();
  }
  return LocalAuthUnlockService();
});

final appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
      if (!ref.watch(appLockSupportedPlatformProvider)) {
        return AppLockController.preloaded(
          initialState: const AppLockState(
            isReady: true,
            config: AppLockConfig.disabled(),
            status: AppLockStatus.disabled,
          ),
          settingsStore: InMemoryAppLockSettingsStore(),
          unlockService: const UnsupportedAppUnlockService(),
        );
      }
      return AppLockController(
        settingsStore: ref.watch(appLockSettingsStoreProvider),
        unlockService: ref.watch(appUnlockServiceProvider),
      );
    });

final secureWindowControllerProvider = Provider<SecureWindowController>((ref) {
  if (!ref.watch(appLockSupportedPlatformProvider)) {
    return const NoopSecureWindowController();
  }
  return defaultSecureWindowController();
});

final appLockAllowsProtectedAccessProvider = Provider<bool>((ref) {
  final AppAuthRoutingStatus authStatus = ref.watch(authRoutingStatusProvider);
  if (authStatus != AppAuthRoutingStatus.authenticated) {
    return true;
  }
  return ref.watch(appLockControllerProvider).allowsProtectedAccess;
});

final protectedGiderRepositoryProvider = Provider<GiderRepository>((ref) {
  if (!ref.watch(appLockAllowsProtectedAccessProvider)) {
    throw const ProtectedAccessLockedException();
  }
  return ref.watch(giderRepositoryProvider);
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
    loading: () => AppAuthRoutingStatus.unknown,
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
  return ref
      .watch(protectedGiderRepositoryProvider)
      .fetchDashboardSnapshot(strings);
});

final reportsServiceProvider = Provider<MonthlyReportsService>(
  (ref) => MonthlyReportsService(),
);

final selectedReportsMonthProvider = StateProvider<DateTime>((ref) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final reportsDatasetProvider = FutureProvider<MonthlyReportsDataset>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  final DateTime selectedMonth = ref.watch(selectedReportsMonthProvider);
  return ref
      .watch(protectedGiderRepositoryProvider)
      .fetchMonthlyReportsDataset(selectedMonth, trendMonthCount: 6);
});

final reportsSnapshotProvider = FutureProvider<MonthlyReportsViewModel>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  final AppLocalizations strings = ref.watch(appLocalizationsProvider);
  final MonthlyReportsDataset dataset = await ref.watch(
    reportsDatasetProvider.future,
  );
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
          .watch(protectedGiderRepositoryProvider)
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
          .watch(protectedGiderRepositoryProvider)
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
          .watch(protectedGiderRepositoryProvider)
          .fetchNetProfitDetail(query, strings);
    });

final recurringItemsProvider = FutureProvider<List<RecurringUiItem>>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  final AppLocalizations strings = ref.watch(appLocalizationsProvider);
  return ref
      .watch(protectedGiderRepositoryProvider)
      .fetchRecurringUiItems(strings);
});

final recurringSummaryProvider = FutureProvider<RecurringSummarySnapshot>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref
      .watch(protectedGiderRepositoryProvider)
      .fetchRecurringSummary(DateTime.now());
});

final incomeCategoriesProvider = FutureProvider<List<CategoryData>>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref
      .watch(protectedGiderRepositoryProvider)
      .fetchCategories(CategoryType.income);
});

final expenseCategoriesProvider = FutureProvider<List<CategoryData>>((
  ref,
) async {
  ref.watch(refreshKeyProvider);
  return ref
      .watch(protectedGiderRepositoryProvider)
      .fetchCategories(CategoryType.expense);
});

class SuppliersQuery {
  const SuppliersQuery({this.expenseCategoryId, this.includeArchived = false});

  final String? expenseCategoryId;
  final bool includeArchived;

  @override
  bool operator ==(Object other) =>
      other is SuppliersQuery &&
      other.expenseCategoryId == expenseCategoryId &&
      other.includeArchived == includeArchived;

  @override
  int get hashCode => Object.hash(expenseCategoryId, includeArchived);
}

final suppliersProvider =
    FutureProvider.family<List<SupplierData>, SuppliersQuery>((
      ref,
      query,
    ) async {
      ref.watch(refreshKeyProvider);
      return ref
          .watch(protectedGiderRepositoryProvider)
          .fetchSuppliers(
            expenseCategoryId: query.expenseCategoryId,
            includeArchived: query.includeArchived,
          );
    });

final activeSuppliersProvider = FutureProvider<List<SupplierData>>((ref) async {
  ref.watch(refreshKeyProvider);
  return ref.watch(protectedGiderRepositoryProvider).fetchSuppliers();
});

enum TransactionsFilter { thisWeek, all, expense, income, card, cash }

final transactionsProvider =
    FutureProvider.family<List<TransactionData>, TransactionsFilter>((
      ref,
      filter,
    ) async {
      ref.watch(refreshKeyProvider);
      final GiderRepository repository = ref.watch(
        protectedGiderRepositoryProvider,
      );
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
