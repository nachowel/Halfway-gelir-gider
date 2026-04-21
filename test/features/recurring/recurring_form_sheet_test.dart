import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/recurring/presentation/recurring_form_sheet.dart';
import 'package:gider/shared/hi_fi/hi_fi_filter_chip.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';
import 'package:mocktail/mocktail.dart';

class _MockGiderRepository extends Mock implements GiderRepository {}

class _FakeRecurringDraft extends Fake implements RecurringDraft {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTheme.configure();
    registerFallbackValue(_FakeRecurringDraft());
  });

  final List<CategoryData> expenseCategories = <CategoryData>[
    const CategoryData(
      id: 'cat-rent',
      type: CategoryType.expense,
      name: 'Housing',
      icon: Icons.home_rounded,
      tone: HiFiIconTileTone.expense,
      sortOrder: 0,
      isArchived: false,
      entryCount: 0,
      monthlyTotalMinor: 0,
    ),
  ];

  Widget buildSheet({
    required GiderRepository repository,
    RecurringExpenseData? existing,
  }) {
    return ProviderScope(
      overrides: <Override>[
        giderRepositoryProvider.overrideWithValue(repository),
        expenseCategoriesProvider.overrideWith(
          (ref) async => expenseCategories,
        ),
        recurringItemsProvider.overrideWith((ref) async => []),
        recurringSummaryProvider.overrideWith(
          (ref) async =>
              const RecurringSummarySnapshot(totalMinor: 0, paidMinor: 0),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showRecurringFormSheet(ctx, existing: existing),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('create mode calls createRecurringExpense with draft', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MockGiderRepository();
    when(
      () => repository.createRecurringExpense(any()),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildSheet(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Fill name
    await tester.enterText(find.byType(TextField).first, 'Gas bill');
    await tester.pumpAndSettle();

    // Fill amount
    final amountField = find.byType(TextField).at(1);
    await tester.enterText(amountField, '62.00');
    await tester.pumpAndSettle();

    // Select category
    await tester.tap(find.widgetWithText(HiFiFilterChip, 'Housing'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(Switch),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Add recurring'));
    await tester.pumpAndSettle();

    final result = verify(
      () => repository.createRecurringExpense(captureAny()),
    );
    result.called(1);
    final draft = result.captured.single as RecurringDraft;
    expect(draft.name, 'Gas bill');
    expect(draft.amountMinor, 6200);
    expect(draft.categoryId, 'cat-rent');
    expect(draft.frequency, RecurringFrequencyType.monthly);
    expect(draft.reserveEnabled, isTrue);
  });

  testWidgets(
    'edit mode preloads existing data and calls updateRecurringExpense',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final existing = RecurringExpenseData(
        id: 'rec-1',
        name: 'Rent',
        categoryId: 'cat-rent',
        categoryName: 'Housing',
        amountMinor: 85000,
        frequency: RecurringFrequencyType.monthly,
        nextDueOn: DateTime(2026, 5, 1),
        reminderDaysBefore: 3,
        reserveEnabled: false,
        isActive: true,
      );

      final repository = _MockGiderRepository();
      when(
        () => repository.updateRecurringExpense(
          id: any(named: 'id'),
          draft: any(named: 'draft'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSheet(repository: repository, existing: existing),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Name preloaded
      expect(find.text('Rent'), findsOneWidget);
      // Amount preloaded
      expect(find.text('850.00'), findsOneWidget);
      // Save button label is edit
      expect(find.text('Save changes'), findsOneWidget);
      // Remove button present
      expect(find.text('Remove'), findsOneWidget);

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      verify(
        () => repository.updateRecurringExpense(
          id: 'rec-1',
          draft: any(named: 'draft'),
        ),
      ).called(1);
      verifyNever(() => repository.createRecurringExpense(any()));
    },
  );

  testWidgets('Remove button calls deactivateRecurringExpense', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final existing = RecurringExpenseData(
      id: 'rec-del',
      name: 'Internet',
      categoryId: 'cat-rent',
      categoryName: 'Housing',
      amountMinor: 3800,
      frequency: RecurringFrequencyType.monthly,
      nextDueOn: DateTime(2026, 5, 1),
      reminderDaysBefore: 3,
      reserveEnabled: false,
      isActive: true,
    );

    final repository = _MockGiderRepository();
    when(
      () => repository.deactivateRecurringExpense(id: any(named: 'id')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildSheet(repository: repository, existing: existing),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    verify(
      () => repository.deactivateRecurringExpense(id: 'rec-del'),
    ).called(1);
    verifyNever(
      () => repository.updateRecurringExpense(
        id: any(named: 'id'),
        draft: any(named: 'draft'),
      ),
    );
  });

  testWidgets('validation blocks save when name or category missing', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MockGiderRepository();

    await tester.pumpWidget(buildSheet(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Try to save with no input
    await tester.tap(find.text('Add recurring'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name.'), findsOneWidget);
    expect(find.text('Enter an amount greater than £0.'), findsOneWidget);
    expect(find.text('Choose a category.'), findsOneWidget);
    verifyNever(() => repository.createRecurringExpense(any()));
  });
}
