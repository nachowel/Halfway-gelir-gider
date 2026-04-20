import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/shell/app_shell.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/shared/hi_fi/hi_fi_fab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    AppTheme.configure();
    return MaterialApp(theme: AppTheme.light(), home: child);
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
}
