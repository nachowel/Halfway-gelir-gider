import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/features/entry/presentation/entry_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    AppTheme.configure();
    return MaterialApp(theme: AppTheme.light(), home: child);
  }

  testWidgets('expense entry renders variant A structure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(const EntryScreen(kind: EntryKind.expense)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('Vendor'), findsOneWidget);
    expect(find.text('Occurred on'), findsOneWidget);
    expect(find.text('Attachment'), findsOneWidget);
    expect(find.text('Gideri kaydet'), findsOneWidget);
  });

  testWidgets('income entry renders variant C structure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(const EntryScreen(kind: EntryKind.income)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Source platform'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Occurred on'), findsOneWidget);
    expect(find.text('Attachment'), findsOneWidget);
    expect(find.text('Geliri kaydet'), findsOneWidget);
  });
}
