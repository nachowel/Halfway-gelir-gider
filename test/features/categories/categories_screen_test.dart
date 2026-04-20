import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/categories/presentation/categories_screen.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';
import 'package:mocktail/mocktail.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppTheme.configure);

  Widget buildTestApp() {
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
              entryCount: 4,
              monthlyTotalMinor: 340000,
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
              entryCount: 8,
              monthlyTotalMinor: 248000,
            ),
          ],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: CategoriesScreen()),
      ),
    );
  }

  testWidgets('categories screen renders provider data and switches tabs', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Card Sales'), findsNothing);

    await tester.tap(find.text('Income · 1'));
    await tester.pumpAndSettle();

    expect(find.text('Card Sales'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
  });
}
