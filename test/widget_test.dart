import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/entry/presentation/entry_screen.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';
import 'package:mocktail/mocktail.dart';

import 'support/localization_test_harness.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(_MockGiderRepository()),
        expenseCategoriesProvider.overrideWith(
          (ref) async => <CategoryData>[
            const CategoryData(
              id: 'expense-rent',
              type: CategoryType.expense,
              name: 'Rent',
              icon: Icons.home_rounded,
              tone: HiFiIconTileTone.expense,
              sortOrder: 0,
              isArchived: false,
              entryCount: 0,
              monthlyTotalMinor: 0,
            ),
          ],
        ),
        incomeCategoriesProvider.overrideWith(
          (ref) async => <CategoryData>[
            const CategoryData(
              id: 'income-card',
              type: CategoryType.income,
              name: 'Card Sales',
              icon: Icons.credit_card_rounded,
              tone: HiFiIconTileTone.income,
              sortOrder: 0,
              isArchived: false,
              entryCount: 0,
              monthlyTotalMinor: 0,
            ),
          ],
        ),
      ],
      child: buildLocalizedScaffoldTestApp(child: child),
    );
  }

  testWidgets('expense entry renders variant A structure', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(const EntryScreen(kind: EntryKind.expense)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('Vendor'), findsOneWidget);
    expect(find.text('Occurred on'), findsOneWidget);
    expect(find.text('Attachment'), findsOneWidget);
    expect(find.text('Save expense'), findsOneWidget);
  });

  testWidgets('income entry renders variant C structure', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(const EntryScreen(kind: EntryKind.income)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Income type'), findsOneWidget);
    expect(find.text('Choose income type'), findsOneWidget);
    expect(find.text('Occurred on'), findsOneWidget);
    expect(find.text('Attachment'), findsOneWidget);
    expect(find.text('Save income'), findsOneWidget);
  });
}
