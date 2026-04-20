import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/shared/widgets/app_button.dart';
import 'package:gider/shared/widgets/app_card.dart';
import 'package:gider/shared/widgets/app_chip.dart';
import 'package:gider/shared/widgets/app_input.dart';
import 'package:gider/shared/widgets/app_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    AppTheme.configure();
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('app button shows loading state and blocks tap', (
    WidgetTester tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      buildTestApp(
        Center(
          child: AppButton(
            label: 'Save',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('app card forwards tap interaction', (WidgetTester tester) async {
    var taps = 0;

    await tester.pumpWidget(
      buildTestApp(
        Center(
          child: AppCard(onTap: () => taps++, child: const Text('Card body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Card body'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('app input renders label and error text', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildTestApp(
        Padding(
          padding: const EdgeInsets.all(24),
          child: AppInput(
            controller: controller,
            label: 'Business name',
            errorText: 'Required field',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Business name'), findsOneWidget);
    expect(find.text('Required field'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('app chip reports selected semantics and tap callback', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      var taps = 0;

      await tester.pumpWidget(
        buildTestApp(
          Center(
            child: AppChip(
              label: 'This week',
              selected: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectedNode = tester.getSemantics(find.text('This week'));
      expect(selectedNode.hasFlag(SemanticsFlag.isSelected), isTrue);

      await tester.tap(find.text('This week'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('app sheet renders shared handle and content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        Align(
          alignment: Alignment.bottomCenter,
          child: AppSheet(child: const Text('Sheet content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-sheet-handle')), findsOneWidget);
    expect(find.text('Sheet content'), findsOneWidget);
  });
}
