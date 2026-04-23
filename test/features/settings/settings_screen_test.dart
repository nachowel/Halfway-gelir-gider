import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/core/app_lock/app_lock_models.dart';
import 'package:gider/core/app_lock/app_lock_settings_store.dart';
import 'package:gider/core/app_lock/local_auth_unlock_service.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/settings/presentation/settings_screen.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

class _FakeUnlockService implements AppUnlockService {
  _FakeUnlockService({
    required this.available,
    AppUnlockAttemptResult? result,
    Future<AppUnlockAttemptResult>? resultFuture,
  }) : _result =
           resultFuture ??
           Future<AppUnlockAttemptResult>.value(
             result ??
                 const AppUnlockAttemptResult(AppUnlockAttemptStatus.failed),
           );

  final bool available;
  final Future<AppUnlockAttemptResult> _result;
  int authenticateCalls = 0;

  @override
  Future<AppUnlockAttemptResult> authenticate({
    required String localizedReason,
  }) async {
    authenticateCalls++;
    return _result;
  }

  @override
  Future<bool> isLocalAuthenticationAvailable() async => available;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppTheme.configure);

  const BusinessSettingsData settings = BusinessSettingsData(
    email: 'owner@example.com',
    businessName: 'Halfway Cafe',
    timezone: 'Europe/London',
    currency: 'GBP',
    weekStartsOn: 1,
    isBootstrapComplete: true,
  );

  Widget buildApp({
    required GiderRepository repository,
    AppLockSettingsStore? appLockStore,
    AppUnlockService? unlockService,
    bool appLockSupported = true,
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        businessSettingsProvider.overrideWith((ref) async => settings),
        appLockSupportedPlatformProvider.overrideWithValue(appLockSupported),
        appLockSettingsStoreProvider.overrideWithValue(
          appLockStore ?? InMemoryAppLockSettingsStore(),
        ),
        if (unlockService != null)
          appUnlockServiceProvider.overrideWithValue(unlockService),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsScreen()),
      ),
    );
  }

  testWidgets(
    'profile update sheet keeps a single primary action without ghost controls',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _MockGiderRepository repository = _MockGiderRepository();

      await tester.pumpWidget(buildApp(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Halfway Cafe').first);
      await tester.pumpAndSettle();

      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sign out sheet keeps visible secondary and primary actions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();

    await tester.pumpWidget(buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out').first);
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Sign out'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('app lock toggle stays off until device verification succeeds', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    final Completer<AppUnlockAttemptResult> prompt = Completer();
    final _FakeUnlockService unlockService = _FakeUnlockService(
      available: true,
      resultFuture: prompt.future,
    );

    await tester.pumpWidget(
      buildApp(repository: repository, unlockService: unlockService),
    );
    await tester.pumpAndSettle();

    Switch toggle = tester.widget(find.byKey(const Key('app-lock-toggle')));
    expect(toggle.value, isFalse);

    await tester.tap(find.byKey(const Key('app-lock-toggle')));
    await tester.pump();

    toggle = tester.widget(find.byKey(const Key('app-lock-toggle')));
    expect(toggle.value, isFalse);
    expect(unlockService.authenticateCalls, 1);

    prompt.complete(const AppUnlockAttemptResult.success());
    await tester.pumpAndSettle();

    toggle = tester.widget(find.byKey(const Key('app-lock-toggle')));
    expect(toggle.value, isTrue);
    expect(find.text('Lock timing'), findsOneWidget);
  });

  testWidgets('app lock auth cancel leaves setting off', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();
    final _FakeUnlockService unlockService = _FakeUnlockService(
      available: true,
      result: const AppUnlockAttemptResult(AppUnlockAttemptStatus.canceled),
    );

    await tester.pumpWidget(
      buildApp(repository: repository, unlockService: unlockService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('app-lock-toggle')));
    await tester.pumpAndSettle();

    final Switch toggle = tester.widget(
      find.byKey(const Key('app-lock-toggle')),
    );
    expect(toggle.value, isFalse);
    expect(find.text('Lock timing'), findsNothing);
  });

  testWidgets('web platform hides app lock settings', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockGiderRepository repository = _MockGiderRepository();

    await tester.pumpWidget(
      buildApp(repository: repository, appLockSupported: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('App Lock'), findsNothing);
    expect(find.byKey(const Key('app-lock-toggle')), findsNothing);
  });
}
