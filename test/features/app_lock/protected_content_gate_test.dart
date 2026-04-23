import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/router/route_access.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/core/app_lock/app_lock_controller.dart';
import 'package:gider/core/app_lock/app_lock_models.dart';
import 'package:gider/core/app_lock/app_lock_settings_store.dart';
import 'package:gider/core/app_lock/local_auth_unlock_service.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/app_lock/presentation/protected_content_gate.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTheme.configure();
    registerFallbackValue(const AppLocalizations(AppLocale.en));
  });

  testWidgets('locked state does not build protected subtree', (
    WidgetTester tester,
  ) async {
    int buildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authRoutingStatusProvider.overrideWithValue(
            AppAuthRoutingStatus.authenticated,
          ),
          appLockControllerProvider.overrideWith((ref) => _lockedController()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.globalDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProtectedContentGate(
            child: Builder(
              builder: (BuildContext context) {
                buildCount++;
                return const Text('Sensitive dashboard');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(buildCount, 0);
    expect(find.text('Sensitive dashboard'), findsNothing);
    expect(find.text('Unlock GIDER'), findsOneWidget);
  });

  test(
    'locked state stops protected fetch before repository resolves',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          authRoutingStatusProvider.overrideWithValue(
            AppAuthRoutingStatus.authenticated,
          ),
          appLockControllerProvider.overrideWith((ref) => _lockedController()),
          giderRepositoryProvider.overrideWith(
            (ref) =>
                throw StateError('Repository must not resolve while locked'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(dashboardSnapshotProvider.future),
        throwsA(isA<ProtectedAccessLockedException>()),
      );
    },
  );

  test('unlock allows protected fetch exactly once', () async {
    final _MockGiderRepository repository = _MockGiderRepository();
    when(
      () => repository.fetchDashboardSnapshot(any()),
    ).thenAnswer((_) async => _dashboardSnapshot);
    final AppLockController controller = AppLockController.preloaded(
      initialState: const AppLockState(
        isReady: true,
        config: AppLockConfig(
          enabled: true,
          timeout: AppLockTimeout.fiveMinutes,
        ),
        status: AppLockStatus.locked,
      ),
      settingsStore: InMemoryAppLockSettingsStore(),
      unlockService: const _FakeUnlockService(),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authRoutingStatusProvider.overrideWithValue(
          AppAuthRoutingStatus.authenticated,
        ),
        appLockControllerProvider.overrideWith((ref) => controller),
        giderRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await controller.unlock(localizedReason: 'verify');
    await container.read(dashboardSnapshotProvider.future);

    verify(() => repository.fetchDashboardSnapshot(any())).called(1);
  });
}

AppLockController _lockedController() {
  return AppLockController.preloaded(
    initialState: const AppLockState(
      isReady: true,
      config: AppLockConfig(enabled: true, timeout: AppLockTimeout.fiveMinutes),
      status: AppLockStatus.locked,
    ),
    settingsStore: InMemoryAppLockSettingsStore(),
    unlockService: const _FakeUnlockService(),
  );
}

const DashboardSnapshot _dashboardSnapshot = DashboardSnapshot(
  weekLabel: 'Mon 1 -> Sun 7 Apr',
  incomeMinor: 0,
  expenseMinor: 0,
  cashIncomeMinor: 0,
  cardIncomeMinor: 0,
  netDeltaMinor: 0,
  reservePlanner: ReservePlannerSnapshot.empty(),
  recentTransactions: <TransactionData>[],
  upcomingRecurring: <RecurringUiItem>[],
);

class _FakeUnlockService implements AppUnlockService {
  const _FakeUnlockService();

  @override
  Future<AppUnlockAttemptResult> authenticate({
    required String localizedReason,
  }) async {
    return const AppUnlockAttemptResult.success();
  }

  @override
  Future<bool> isLocalAuthenticationAvailable() async => true;
}
