import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/shell/app_shell.dart';
import 'package:gider/shared/hi_fi/hi_fi_fab.dart';
import '../../support/localization_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      child: buildLocalizedTestApp(home: child),
    );
  }

  testWidgets('app shell keeps nav and fab inside centered mobile shell', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(
        const AppShell(
          currentLocation: '/summary',
          child: Center(child: Text('Summary body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Summary body'), findsOneWidget);
    expect(find.byType(HiFiFab), findsOneWidget);
    expect(find.byKey(const Key('bottom-nav')), findsOneWidget);

    final Size navSize = tester.getSize(find.byKey(const Key('bottom-nav')));
    expect(navSize.width, lessThan(430));
    expect(navSize.width, greaterThan(380));
  });

  testWidgets('app shell hides fab while an overlay is active', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildLocalizedTestApp(
          home: const AppShell(
            currentLocation: '/summary',
            child: Center(child: Text('Summary body')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HiFiFab), findsOneWidget);

    container.read(overlayCoordinatorProvider.notifier).push();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(find.byType(HiFiFab), findsNothing);

    container.read(overlayCoordinatorProvider.notifier).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(find.byType(HiFiFab), findsOneWidget);
  });
}
