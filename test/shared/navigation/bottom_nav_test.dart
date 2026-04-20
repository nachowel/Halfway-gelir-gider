import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/shared/navigation/bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    AppTheme.configure();
    return MaterialApp(theme: AppTheme.light(), home: child);
  }

  testWidgets('bottom nav calls back with tapped item index', (
    WidgetTester tester,
  ) async {
    int? tappedIndex;

    await tester.pumpWidget(
      buildTestApp(
        Scaffold(
          body: BottomNav(
            items: const <BottomNavItem>[
              BottomNavItem(icon: Icons.home_rounded, label: 'Ozet'),
              BottomNavItem(icon: Icons.list_alt_rounded, label: 'Islemler'),
              BottomNavItem(
                icon: Icons.insert_chart_outlined_rounded,
                label: 'Raporlar',
              ),
              BottomNavItem(icon: Icons.settings_outlined, label: 'Ayarlar'),
            ],
            currentIndex: 1,
            onTap: (int index) => tappedIndex = index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Raporlar'));
    await tester.pumpAndSettle();

    expect(tappedIndex, 2);
  });

  testWidgets('bottom nav exposes selected semantics for active item', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: BottomNav(
              items: const <BottomNavItem>[
                BottomNavItem(icon: Icons.home_rounded, label: 'Ozet'),
                BottomNavItem(icon: Icons.list_alt_rounded, label: 'Islemler'),
              ],
              currentIndex: 1,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectedNode = tester.getSemantics(
        find.byKey(const Key('bottom-nav-item-1')),
      );
      expect(selectedNode.hasFlag(SemanticsFlag.isSelected), isTrue);
    } finally {
      semantics.dispose();
    }
  });
}
