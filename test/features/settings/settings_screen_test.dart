import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/settings/presentation/settings_screen.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

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

  Widget buildApp({required GiderRepository repository}) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        businessSettingsProvider.overrideWith((ref) async => settings),
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
}
